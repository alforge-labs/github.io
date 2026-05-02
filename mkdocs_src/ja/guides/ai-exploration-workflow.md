# AI 駆動の戦略探索ワークフロー

Claude Code・Codex などの AI コーディングエージェントを「頭脳」として AlphaForge と組み合わせると、戦略の **着想 → 実装 → バックテスト → 最適化 → 検証 → 運用調整** を自律的に進められます。

!!! info "前提"
    本ページのコマンド例とフローは `alpha-trade` モノレポ（`alpha-forge` + `alpha-strategies` の組み合わせ）における運用パターンです。**バイナリ版** ユーザーは `op run --env-file=...` などの内部コマンドを `forge` に読み替えてください。

## なぜ AI エージェント × AlphaForge か

AlphaForge は **すべての設定・戦略・実行が JSON / YAML / CLI で完結する** ように設計されています。これにより：

- AI エージェントが戦略 JSON を **生成・編集・検証** できる
- バックテスト・最適化の結果が **構造化データで返る** ため、エージェントが解析・改善案を出せる
- スラッシュコマンドで **同じワークフロー** を冪等に何度でも回せる
- レートリミットや人間の作業時間に依存せず、**夜間に自律探索** を回せる

結果として、人間は「方向性の指示」「合否判定」に集中し、面倒な探索とパラメータ調整は AI に任せるという分業が可能になります。

## 手動フローとの使い分け

| 目的 | 推奨フロー |
|------|-----------|
| AlphaForge の全ステップを理解したい | [エンドツーエンド戦略開発ワークフロー](end-to-end-workflow.md)（手動 CLI） |
| 新しい指標・銘柄の組み合わせを素早く探索したい | 本ページ（AI 駆動の自律探索） |
| すでに有望な戦略があり、詰めたい | Step 3 の [`/grid-tune`](#step-3-grid-tune) から始める |
| 実運用中の戦略の乖離を監視したい | Step 4 の [`/tune-live-strategies`](#step-4-tune-live-strategies) |

## 推奨コーディングエージェント

2026 年 4 月時点で alpha-forge と相性の良いエージェントの比較：

| エージェント | 強み | レート/料金（目安） | スラッシュコマンド対応 |
|------------|------|------------------|----------------------|
| **Claude Code**（推奨） | ファイル編集の精度、長時間タスク、Sonnet/Opus の使い分け | サブスクリプション or API 従量 | ✅ `.claude/commands/*.md` をネイティブサポート |
| **Codex CLI** | 高い基礎性能、OpenAI モデル | API 従量（GPT-5 等） | △ 設定経由でカスタムプロンプト |
| **Cursor** | IDE 統合、対話的に効率良い | サブスクリプション | △ Composer / Rules で代替 |
| **Aider** | OSS、複数モデルに対応、git 統合 | モデル料金のみ | △ `/<command>` 風 alias は手動設定 |

本ページでは **Claude Code** を前提に書きます。他エージェントを使う場合は `.claude/commands/*.md` の手順を読み込ませて同等のフローを実行できます。

---

## 全体フロー

```
準備: /update-market-data でデータを最新化
  ↓
起点を決める（3 つの探索シナリオから選択）
  ↓
Step 1: /explore-strategies（または /explore-strategies-loop）
  └─ 銘柄×指標を組み合わせてバックテスト→最適化→WFT を自動実行
     初期フィルタ: Sharpe ≥ 1.0 かつ MaxDD ≤ 25%
  ↓
Step 2: /analyze-exploration
  └─ 全探索ログを集計し、次に深掘りすべき候補を recommendations.yaml に出力
  ↓
Step 3: /grid-tune
  └─ 有望な戦略を網羅的グリッドサーチで詰める + WFT 再検証
  ↓
Step 4: /tune-live-strategies
  └─ 実運用後の乖離分析・再チューニング
```

---

## 準備: ヒストリカルデータ取得

探索を始める前に、対象銘柄のデータが最新化されているか確認します。

```bash
# 保存済みデータの一括差分更新（バイナリ版では forge data update <SYMBOL>）
> /update-market-data
```

`/update-market-data` は `forge data list` で登録済みシンボルを確認し、各シンボルに対して `forge data update` を実行します。新しい銘柄を追加する場合は先に `forge data fetch <SYMBOL>` を手動実行してください。

---

## 3 つの探索シナリオ

AI エージェント × AlphaForge の使い方は、**起点となる材料** で大きく 3 つに分類できます。

### シナリオ 1: 既存戦略・指標の組み合わせ

**起点**: 手元の戦略 JSON、`forge indicator list` の指標カタログ

**典型フロー**:

1. Claude Code に「`forge strategy show multi_asset_hmm_bb_rsi_v1_qqq` の戦略をベースに、MACD を追加した派生版を作って」と指示
2. AI が JSON を編集して `multi_asset_hmm_bb_rsi_macd_v1_qqq.json` を生成
3. `forge strategy validate` → `forge strategy save` → `forge backtest run`
4. 結果を見て、Sharpe が改善していれば `forge optimize run` で詰める

**ポイント**: `/explore-strategies` を使えば、AI に組み合わせ選定からレポートまで完全に任せられます。

### シナリオ 2: TradingView Pine Script を起点とした応用

**起点**: TradingView の公開戦略・インジケータ（`.pine` ファイル）

**典型フロー**:

1. TradingView で気になる戦略を見つけたら、Pine Script をローカルに保存（`tv_<name>.pine`）
2. **インポート**: `forge pine import tv_<name>.pine --id imported_v1`
3. AI に「この戦略の `parameters` と `indicators` を分かりやすく整理して、`optimizer_config` を追加して」と指示
4. AI が JSON を整形・補強し、最適化対象を明示
5. `forge backtest run` → `forge optimize run` で AlphaForge 流に検証
6. 良ければ `forge pine generate` で逆方向に書き戻し、TradingView でも動作確認

**ポイント**: Pine Script のロジックを **JSON ベース** に持ち込むことで、最適化・WFT・Monte Carlo など AlphaForge の解析機能をすべて使えるようになります。

### シナリオ 3: 投資掲示板・論文を起点としたインターネット探索

**起点**: X (旧 Twitter)、Reddit `/r/algotrading`、SSRN の論文、QuantConnect・QuantStart の記事

**典型フロー**:

1. Claude Code に **URL や論文 PDF を渡して** 「この戦略の核心ロジックを抽出して、`indicators` と `entry_conditions` のリストにして」と指示
2. AI が記事を要約し、戦略 JSON のドラフトを生成
3. `forge strategy validate` で論理エラーをチェック → 修正
4. `forge backtest signal-count` でシグナル件数を確認（条件が厳しすぎないか）
5. `forge backtest run` → 結果に応じて `forge optimize run`
6. 元記事の主張する結果と実バックテスト結果を比較（**多くの場合、再現できない**）

**ポイント**: 論文の戦略は「データ期間」「銘柄」「取引コスト」が異なると再現性がないことが多い。AI が「論文の主張」と「実バックテスト結果」のギャップを **冷静に評価** することで、フィルタリング機能を果たします。

---

## Step 1: 探索フェーズ（`/explore-strategies` / `/explore-strategies-loop`） {#step-1-explore}

**目的**: `goals.yaml` で指定した目標指標（例: Sharpe ≥ 1.5）を満たす戦略を **未試行の指標×銘柄組み合わせ** から探す。

### 実行ステップ（要約）

1. **事前確認**: `data/explorer/goals.yaml`、`explored_log.md`、既存戦略 JSON を読み、未試行の組み合わせを把握
2. **戦略生成**: 未試行の指標×銘柄を 1 つ選び、戦略 JSON を生成して `data/strategies/<name>.json` に保存
3. **登録 → 検証**: `forge strategy save` → `forge strategy validate` で論理整合性を確認（失敗時はロールバック）
4. **シグナル件数チェック**: `forge backtest signal-count <SYMBOL> --strategy <name> --json`　`entry_signal_days = 0` ならスキップ
5. **バックテスト**: `forge backtest run <SYMBOL> --strategy <name> --json`
6. **初期フィルタ通過時のみ最適化**: `Sharpe ≥ 1.0 && MaxDD ≤ 25%` を満たせば `forge optimize run` + `forge optimize walk-forward --windows 5`
7. **合否記録**: `explored_log.md` と `reports/YYYY-MM-DD.md` に追記。不合格は戦略 JSON / DB エントリ / 結果 JSON を全削除（冪等性確保）

```
> /explore-strategies       # 1 サイクル実行
> /explore-strategies-loop  # レートリミットまたは全組み合わせ消化まで連続実行
```

### 合否基準

| フェーズ | 基準 |
|---------|------|
| 初期フィルタ | Sharpe ≥ 1.0 **かつ** MaxDD ≤ 25% |
| WFT 最終合格 | WFT 全ウィンドウ平均 Sharpe ≥ `goals.yaml` の `target_metrics.sharpe_ratio` |

### 冪等性のポイント

`explored_log.md` がチェックポイントになるため、何度実行しても同じ組み合わせを重複探索しません。中断・再開は安全です。

### ループ運用とレートリミット対策

`/explore-strategies-loop` はレートリミット到達まで繰り返し自動実行します。

| エージェント | 主な制限 | 対策 |
|------------|---------|------|
| Claude Code | 5 時間ウィンドウのトークン制限（プラン依存） | 夜間 → 朝 → 昼で 3 ウィンドウに分けて回す |
| Codex | RPM / TPM（モデル別） | 並列度を下げて 1 イテレーション直列化 |
| Cursor | 月 / 日のリクエスト制限 | Composer Agent は重いので戦略生成に絞る |

!!! warning "並列実行は非推奨"
    `/explore-strategies-loop` は `explored_log.md` を共有するため **直列実行が前提** です。並列化する場合は、別の `goals.yaml`（別銘柄セット）を別ディレクトリに用意し、それぞれ別エージェントで回してください。

---

## Step 2: 分析・絞り込み（`/analyze-exploration`） {#step-2-analyze}

**目的**: 過去のすべての探索ログを集計・分析し、次に試すべき組み合わせを **科学的に推薦** する。

```
> /analyze-exploration
```

### 処理内容

1. `explored_log.md` + `reports/*.md` を全読み込み
2. **銘柄別パフォーマンス表**（試行数、最高/平均 Sharpe、最低 MaxDD、合格数）を生成
3. **指標組み合わせ別パフォーマンス表**（試行回数、平均/最高 Sharpe、合格率）を生成
4. **未試行組み合わせのスコアリング**（0–10 点）：
    - 類似指標の既存平均 Sharpe（+0–4）
    - 銘柄の試行回数の少なさ（+0–2）
    - 指標の新規性（+0–2）
    - 直前ランの推奨候補にあったか（+2）
5. 分析レポートを `data/explorer/analysis/YYYY-MM-DD_HH-MM.md` に保存
6. **`recommendations.yaml` に上位 5 件を出力**（次の `/explore-strategies` が参照）

### 出力例（recommendations.yaml）

```yaml
candidates:
  - rank: 1
    asset: QQQ
    indicators: [HMM, BBANDS, RSI, MACD]
    score: 8.5
    rationale: "HMM × BBANDS の平均 Sharpe が高く、QQQ は試行少。MACD 追加で新規性 +"
    basis_sharpe: 1.32
    basis_maxdd: 18.4
    variant_of: multi_asset_hmm_bb_rsi_v1_qqq
```

---

## Step 3: 精密チューニング（`/grid-tune`） {#step-3-grid-tune}

**目的**: Step 1 で合格した戦略について、`optimizer_config.param_ranges` を **Cartesian Grid に展開して網羅探索**、合格すれば自動で `<name>_optimized` として保存。

```
> /grid-tune <strategy_name> <SYMBOL>
```

### 実行ステップ

1. 戦略確認: `forge strategy show <strategy_name>` で `param_ranges` の存在と Grid 総数を確認
2. シグナル件数チェック（必須）: `forge backtest signal-count`
3. ベースライン取得: `forge backtest run` で元戦略の Sharpe を控える
4. **Grid 網羅探索**: `forge optimize grid <symbol> --strategy <name> --metric sharpe_ratio --top-k 20 --chunk-size 100 --max-memory-mb 4096 --min-trades 30 --save --save-format csv --yes`
5. Top-20 レビュー（過学習の疑い、上位 trial の近傍集中を確認）
6. ベスト適用: `forge optimize grid ... --top-k 1 --apply --yes`
7. **WFT 検証**: `forge optimize walk-forward <symbol> --strategy <name>_optimized --windows 5`
8. **合否判定**: WFT 全ウィンドウ平均 Sharpe が **元戦略の Sharpe を超えていれば合格**
    - 合格 → `forge journal verdict <name>_optimized <run_id> pass`
    - 不合格 → `forge strategy delete <name>_optimized --force` + 元戦略の Journal に `note` 追加

### メモリ・OOM の目安

- 1 シンボル × 5 年分 × 1,000 通り Grid → `--chunk-size 100 --max-memory-mb 4096` で OOM なく完走
- それ以上 → `--chunk-size 50 --max-memory-mb 2048` などに下げる
- `param_ranges` の `step` を粗くして総数を絞ることも有効

---

## Step 4: 実運用監視（`/tune-live-strategies`） {#step-4-tune-live-strategies}

**目的**: 実運用中の戦略について、ライブ成績がバックテストから乖離しているものを検出し、**自動的に再最適化** する。

```
> /tune-live-strategies
```

### 実行ステップ

1. **乖離検出**: `forge live list` → 各戦略 ID で `forge live compare <strategy_id>` を実行し、`goals.yaml` の `live_tuning.sharpe_drift_threshold` を超えたものを抽出
2. **再最適化**: 乖離が大きい戦略ごとに：
    - `forge optimize run <SYMBOL> --strategy <name> --metric sharpe_ratio --save`
    - `forge optimize walk-forward <SYMBOL> --strategy <name> --windows 5`
3. **採用判定**: WFT の全ウィンドウ平均 Sharpe が **改善している場合のみ** `<name>_optimized.json` を更新。改悪なら現状維持
4. レポートを `data/explorer/reports/tuning-YYYY-MM-DD.md` に追記

週次の定期実行か、乖離が気になったときの手動実行で十分です。乖離が連続 N 週続く場合は戦略の根本見直し（指標差し替え、別シナリオへの転換）を検討してください。

---

## キーファイルの役割

```text
alpha-strategies/data/explorer/
├── goals.yaml                         # 目標指標と探索範囲を定義
├── explored_log.md                    # 全試行の冪等チェックポイント（重複防止）
├── reports/
│   ├── YYYY-MM-DD.md                  # /explore-strategies の日次レポート
│   └── tuning-YYYY-MM-DD.md          # /tune-live-strategies のレポート
└── analysis/
    └── YYYY-MM-DD_HH-MM.md           # /analyze-exploration の出力
```

**`goals.yaml`**: 目標 Sharpe・MaxDD・探索対象の銘柄・指標セット・`strategies_per_run` などを定義します。すべてのスラッシュコマンドがこのファイルを参照します。

**`explored_log.md`**: 試行済みの組み合わせを記録するチェックポイント。このファイルが存在する限り、同じ組み合わせが重複して探索されることはありません。

**`recommendations.yaml`**: `/analyze-exploration` が生成する次回推奨候補。`/explore-strategies` はこのファイルを読み、スコアの高い組み合わせを優先的に選択します。

---

## なぜ最適化後に WFT を実施するか

各ステップで **Walk-Forward Test（WFT）** を必須としているのは、過学習（オーバーフィッティング）を防ぐためです。

In-Sample データ（最適化に使った期間）だけで評価すると、パラメータがそのデータに過適合している可能性があります。WFT は：

1. 全期間を複数ウィンドウに分割
2. 各ウィンドウで「最適化 → Out-of-Sample 検証」を実施
3. **OOS 期間での平均 Sharpe** を最終評価に使う

これにより「過去データには強いが将来には機能しない」戦略を弾く設計になっています。

---

## ワンサイクル実例（探索 → 最適化 → 検証 → 運用）

「QQQ で HMM × BB × RSI に MACD を加えるアイデア」を検証 → 採用するまでの実例です。

```bash
# 1. アイデアを記録（任意、後でリンク可能）
forge idea add "QQQ HMM×BB×RSI に MACD を追加" \
  --type improvement --tag hmm --tag qqq

# 2. /explore-strategies で 1 サイクル試す（Claude Code 内）
> /explore-strategies
# → 戦略 JSON 自動生成、validate、signal-count、backtest を実施
# → Sharpe=0.95 で pre-filter 落ち（Sharpe ≥ 1.0 が条件）

# 3. 派生版で再挑戦（パラメータを変えてみる、AI に依頼）
> 上記戦略の HMM の n_components を 2 に減らして再試行して
# → AI が修正版 JSON を生成・登録 → backtest（Sharpe=1.18 で pre-filter 通過）
# → 自動で optimize run + walk-forward 実行
# → WFT 平均 Sharpe=1.32 で合格

# 4. /grid-tune で網羅最適化
> /grid-tune multi_asset_hmm_bb_rsi_macd_v1_qqq QQQ
# → Grid Top-1 → apply → WFT 検証で 1.45 達成
# → forge journal verdict pass で記録

# 5. 過学習ロバスト性チェック
forge optimize sensitivity \
  /path/to/data/results/optimize_multi_asset_hmm_bb_rsi_macd_v1_qqq_optimized_20260415_103021.json
# → overall_robustness_score=0.82（合格）

# 6. ジャーナルに最終承認を記録
forge journal verdict multi_asset_hmm_bb_rsi_macd_v1_qqq_optimized <run_id> pass
forge journal note multi_asset_hmm_bb_rsi_macd_v1_qqq_optimized "OOS pass + sensitivity 0.82。本番投入候補。"

# 7. TradingView 用 Pine Script を生成
forge pine generate --strategy multi_asset_hmm_bb_rsi_macd_v1_qqq_optimized --with-training-data

# 8. ライブ運用開始（VPS に発注エンジンを配置、本ドキュメント範囲外）

# 9. 1 週間後、ライブ成績を比較
forge live import-events multi_asset_hmm_bb_rsi_macd_v1_qqq_optimized
forge live compare multi_asset_hmm_bb_rsi_macd_v1_qqq_optimized

# 10. 乖離が大きければ /tune-live-strategies で自動再チューニング
> /tune-live-strategies
```

このフロー全体のうち、**人間が判断するのは 3 箇所だけ** です：

1. アイデアの方向性（HMM × BB × RSI に MACD を加える）
2. Grid-tune の Top-20 レビュー（過学習の疑いを確認）
3. ライブ運用開始の意思決定

それ以外は全部 AI が自動で進めます。

---

## 関連ドキュメント

- [エンドツーエンド戦略開発ワークフロー](end-to-end-workflow.md) — 手動 CLI による全ステップの詳細
- [はじめに](../getting-started.md) — 初回バックテストまでのチュートリアル
- [CLI リファレンス](../cli-reference/index.md) — `forge` コマンドの全パラメータ
- [戦略テンプレート](../templates.md) — HMM × BB × RSI 等の同梱戦略

---

<!-- 同期元: `alpha-trade/.claude/commands/{explore-strategies,explore-strategies-loop,analyze-exploration,grid-tune,tune-live-strategies,update-market-data}.md` のスラッシュコマンド定義。エージェント比較は 2026 年 4 月時点。 -->
