# その他コマンド

[コアコマンド](index.md) 以外の補助・管理用コマンドを 1 ページにまとめています。10 グループ × 約 29 サブコマンドが対象です。詳細パラメータの完全なリストは `forge <group> <subcommand> --help` でも確認できます。

!!! info "サンプル出力について"
    本ページの出力例は `alpha-forge` のソースから読み取ったフォーマットを元にしたサンプルです。実際の数値はデータと環境によって異なります。

## グループ早見表

| グループ | サブコマンド | 主な用途 |
|---------|-------------|----------|
| [license](#license) | `activate` `deactivate` `status` | ライセンスキーの認証・解除・状態確認 |
| [login と logout](#login-logout) | `login` `logout` | Whop アカウント認証 |
| [init](#init) | （単一コマンド） | 作業ディレクトリの初期化 |
| [pine](#pine) | `generate` `preview` `import` | TradingView Pine Script の生成・取り込み |
| [indicator](#indicator) | `list` `show` | 対応テクニカル指標の参照 |
| [idea](#idea) | `add` `list` `show` `status` `link` `tag` `note` `search` | 投資アイデアの記録・追跡 |
| [altdata](#altdata) | `fetch` `list` `info` | 代替データ（センチメント等）の管理 |
| [pairs](#pairs) | `scan` `scan-all` `build` | ペアトレード（コインテグレーション） |
| [ml](#ml) | `dataset build` `dataset feature-sets` `train` `models` `walk-forward` | ML データセット・モデル学習・walk-forward 検証（issue #512 Phase 1-2, 4） |

| [docs](#docs) | `list` `show` | 同梱ドキュメント参照 |

---

## license

ライセンスキーの認証・解除・状態確認を行います。詳しいインストール手順は [はじめに](../getting-started.md) を参照。

### forge license activate

ライセンスキーを認証します。

```bash
forge license activate <KEY>
```

| 名前 | 種別 | 説明 |
|------|------|------|
| `KEY` | 引数（必須） | ライセンスキー（購入完了メールに記載） |

成功すると認証情報が `~/.forge/license.json` にキャッシュされます。

### forge license deactivate

このマシンのライセンスを解除します。

```bash
forge license deactivate
```

別マシンへ移行する際に使用してください。

### forge license status

現在のライセンス状態を表示します。

```bash
forge license status
```

サンプル出力：

```text
ライセンスキー  : 1A2B3C4D...
最終検証        : 2026-04-12 09:30 UTC (3日前)
フィンガープリント: 一致
キャッシュ      : 有効（3日以内）
```

未登録時は `[AlphaForge] ライセンス未登録` と表示されます。

---

## login と logout

Whop アカウントによる認証コマンド。

### forge login

```bash
forge login
```

ブラウザが自動で開き、Whop で認証フローを実行します。引数・オプションなし。

### forge logout

```bash
forge logout
```

ログアウトしてローカルの認証情報を削除します。引数・オプションなし。

---

## init

作業ディレクトリを初期化します。`forge.yaml`、データディレクトリ、ドキュメント、AI アシスタント統合ファイルを作成。

### 構文

```bash
forge init [OPTIONS]
```

### オプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--force` / `-f` | フラグ | false | 既存ファイルを確認なしで上書き |
| `--no-claude` | フラグ | false | AI アシスタント統合ファイルのセットアップをスキップ |

### 作成されるディレクトリ

- `data/historical/`、`data/strategies/`、`data/results/`、`data/journal/`、`data/ideas/`、`output/pinescript/`

### インストールされる AI 統合ファイル

| 出力先 | 内容 |
|--------|------|
| `.claude/skills/` | Claude Code スキル（forge-backtest, forge-analyze, forge-data） |
| `.claude/commands/` | Claude Code スラッシュコマンド（explore-strategies, grid-tune 他 4 件） |
| `.agents/skills/` | Codex スキル（explore-strategies, grid-tune 他 4 件） |

### サンプル出力

```text
AlphaForge: 作業ディレクトリを初期化します...

[1/4] 設定ファイル
  ✓ forge.yaml

[2/4] データディレクトリ
  ✓ data/historical/
  ✓ data/strategies/
  - 既存: data/results/
  ...

[3/4] ドキュメントファイル
  ✓ docs/quick-start.ja.md
  ✓ docs/user-guide.ja.md
  ...

[4/4] AI アシスタント統合ファイル
  ✓ .claude/skills/forge-backtest/SKILL.md
  ✓ .claude/commands/explore-strategies.md
  ✓ .claude/commands/grid-tune.md
  ✓ .agents/skills/explore-strategies/SKILL.md
  ✓ .agents/skills/grid-tune/SKILL.md
  ...

完了: 26 件を作成, 0 件をスキップ

次のステップ:
  1. forge.yaml を編集して設定をカスタマイズしてください
  2. 以下を ~/.zshrc / ~/.bashrc に追加してください:
     export FORGE_CONFIG=/path/to/forge.yaml
```

---

## explore {#explore}

戦略探索パイプラインの状態管理と一括実行を行います。AI エージェント（`/explore-strategies`）から利用されるコマンド群です。

| サブコマンド | 説明 |
|-------------|------|
| `run` | バックテスト→最適化→WFT→DB登録を一気通貫実行（**メインコマンド**） |
| `index` | `explored_log.md` から `exploration_index.yaml` を生成 |
| `import` | 既存 Markdown ログを探索 DB へ投入 |
| `log` | 探索試行を DB に手動記録 |
| `status` | ゴールに対する網羅状況マップを表示 |
| `result` | 探索 DB に保存された最新試行の詳細を表示 |
| `health` | 直近 N 件の試行から連続失敗・scaffold 固定化を検出（無人運転の品質ゲート） |
| `recommend` | 次の探索候補を `recommendations.yaml` へ出力 |
| `coverage` | パラメータカバレッジ（YAML）の更新・参照 |

### forge explore run

バリデーション → データ自動取得 → バックテスト → 最適化 → ウォークフォワードテスト（WFT）→ coverage 更新 → DB 登録を 1 コマンドで完結させます。不合格時は exit code 1 を返します（`--dry-run` / `--pre-check` 時を除く）。  
エージェントの `/explore-strategies` スキルから内部的に呼び出されます。

```bash
forge explore run <SYMBOL> --strategy <NAME> --goal <GOAL> [--no-cleanup] [--dry-run] [--pre-check] [--json] [--db <PATH>]
```

| オプション | 説明 | デフォルト |
|-----------|------|-----------|
| `--strategy` | 戦略名（必須） | — |
| `--goal` | ゴール名（`goals.yaml` の `pre_filter` / `target_metrics` を適用） | `default` |
| `--no-cleanup` | 不合格時もファイル・DB エントリを削除しない（デバッグ用） | off |
| `--dry-run` | 実行予定ステップを表示して終了（実際の処理は行わない） | off |
| `--pre-check` | バックテスト（デフォルトパラメータ）のみ実行し、最適化/WFT はスキップする（#321） | off |
| `--json` | 結果を JSON 形式で標準出力する（**非推奨**: `forge explore result show <id> --json` を使用してください） | off |
| `--db` | 探索 DB のパス（省略時は `forge.yaml` のデフォルトパス） | — |

#### `--pre-check` の使い方

戦略設計段階のスクリーニングに使用します。最適化・WFT は実行されません。

```bash
forge explore run SPY --strategy my_rsi_v1 --pre-check
forge explore run SPY --strategy my_rsi_v1 --pre-check --json
```

`--pre-check` 実行時のテキスト出力例:

```
📊 Pre-check (バックテスト・デフォルトパラメータ)
  Sharpe:     0.821
  MaxDD:      19.9%
  Trades:     24 ⚠️ 少ない（WFT 窓に対して不十分な可能性）
  Signals:    31
  Pre-filter: FAIL ❌

→ 最適化・WFT はスキップされます。
```

#### 出力 JSON の例

```json
{
  "symbol": "SPY",
  "strategy_id": "spy_hmm_rsi_v3",
  "passed": false,
  "backtest": {
    "sharpe": 0.82,
    "max_dd": 19.9,
    "trades": 42
  },
  "pre_filter_pass": true,
  "wft_avg_sharpe": 1.12,
  "wft_target": 1.5,
  "skip_reason": "wft_failed",
  "cleanup_done": true,
  "entry_signals": 31
}
```

| フィールド | 説明 |
|-----------|------|
| `passed` | WFT が `target_metrics` を満たした場合 `true` |
| `skip_reason` | スキップ・失敗理由（`validation_failed` / `no_signals` / `pre_filter_failed` / `wft_failed` / `pre_check_only` / `dry_run` / `null`） |
| `cleanup_done` | 不合格時に戦略 JSON / 結果 JSON が削除済みの場合 `true` |
| `entry_signals` | エントリーシグナルが立った日数（`--pre-check` 時に設定、後方互換で `null` になる場合あり） |

### forge explore result show

探索 DB に保存されている最新の探索結果を表示します。`forge explore run` 不合格時の詳細確認に使用します。

```bash
forge explore result show <STRATEGY_ID> [--goal <GOAL>] [--json] [--db <PATH>]
```

| オプション | 説明 | デフォルト |
|-----------|------|-----------|
| `--goal` | ゴール名で絞り込む | — |
| `--json` | 結果を JSON 形式で標準出力する | off |
| `--db` | 探索 DB のパス（省略時は `forge.yaml` のデフォルトパス） | — |

#### 使用例

```bash
# 最新結果を人間可読形式で表示
forge explore result show gc_bb_hmm_rsi_v1

# ゴール絞り込みで JSON 出力（wft_diagnostics など診断情報を含む）
forge explore result show gc_bb_hmm_rsi_v1 --goal commodities --json
```

`forge explore run` が exit code 1 を返した場合の詳細確認フロー:

```bash
FORGE_CONFIG=forge.yaml forge explore run GC=F --strategy gc_bb_hmm_rsi_v1 --goal commodities
# exit code 1 → DB から詳細を取得
FORGE_CONFIG=forge.yaml forge explore result show gc_bb_hmm_rsi_v1 --goal commodities --json
```

`--json` 出力には `wft_diagnostics`・`pre_filter_diagnostics`・`opt_metrics` フィールドが含まれます。

#### pre_filter_diagnostics の構造（issue #409）

`skip_reason: "pre_filter_failed"` のとき、`pre_filter_diagnostics` には各基準について
`{value, threshold, passed, gap}` の構造化情報が格納されます。自律探索エージェントが
「どの基準がどれだけ不足したか」を機械的に判断するために使用します。

```json
{
  "pre_filter_diagnostics": {
    "sharpe_ratio":      {"value": 0.716, "threshold": 1.0,  "passed": false, "gap": -0.284},
    "max_drawdown":      {"value": 1.66,  "threshold": 25.0, "passed": true,  "gap": 23.34},
    "trades":            {"value": 16,    "threshold": 30,   "passed": false, "gap": -14},
    "monthly_volume_usd":{"value": null,  "threshold": 0.0,  "passed": null,  "note": "未チェック"},
    "verdict": "failed",
    "failed_criteria": ["sharpe_ratio", "trades"]
  }
}
```

| フィールド | 説明 |
|-----------|------|
| `value` | バックテストでの実測値（`monthly_volume_usd` は現状計算しないため `null`） |
| `threshold` | goals.yaml の `pre_filter` セクションから解決した閾値 |
| `passed` | 基準を満たしているかどうか（`null` の場合は未チェック） |
| `gap` | 「実測値 − 閾値」（max_drawdown のみ「閾値 − 実測値」）。負なら不足量、正なら余裕量 |
| `verdict` | 全基準合格時 `"passed"`、いずれか不合格なら `"failed"` |
| `failed_criteria` | 不合格となった基準名のリスト（評価順: `sharpe_ratio` → `max_drawdown` → `trades`） |

### forge explore health

直近 N 件の試行を集計して連続失敗・scaffold 固定化を自動検出します（issue #408）。
無人運転（`/explore-strategies --runs 0`）の各イテレーション開始前に呼び出し、
全敗ループや scaffold バグの早期検知に使用します。

```bash
forge explore health --goal <GOAL> [--last N] [--strict] [--json] [--db <PATH>]
```

| オプション | 説明 | デフォルト |
|-----------|------|-----------|
| `--goal` | 集計対象のゴール名 | `default` |
| `--last` | 分析対象とする直近件数 | `5` |
| `--strict` | `escalation: true` のとき終了コード `1` を返す（無人運転ループ停止用、`warning: true` のみのときは `0`） | off |
| `--json` | 結果を JSON 形式で標準出力する | off |
| `--db` | 探索 DB のパス（省略時は `forge.yaml` のデフォルトパス） | — |

#### 出力 JSON の例

```json
{
  "goal": "default",
  "last_n": 5,
  "pass_rate": 0.0,
  "failure_breakdown": {"pre_filter_failed": 3, "no_signals": 2},
  "scaffold_transformation_rate": 1.0,
  "most_common_combo": "ATR+BB+RSI",
  "same_combo_streak": 5,
  "escalation": true,
  "warning": false,
  "escalation_type": "scaffold_degradation",
  "recommended_actions": [
    "直近 5 件の合格率が 0% です。goals.yaml の pre_filter 閾値・対象銘柄・候補指標が現実的か再点検してください。",
    "直近すべての試行で scaffold が指標を変換しています。`alpha_forge.strategy.scaffold` の指標フィルタを点検してください（参考: alpha-forge issue #399, #400）。"
  ]
}
```

| フィールド | 説明 |
|-----------|------|
| `last_n` | 実際に集計対象となった件数（DB 件数 < `--last` の場合は実件数） |
| `pass_rate` | `passed=True` の比率（0.0〜1.0） |
| `failure_breakdown` | `skip_reason` 別の失敗件数 |
| `scaffold_transformation_rate` | scaffold で指標が変換された試行の比率（ATR 自動追加のみは除外） |
| `same_combo_streak` | 直近で連続して同一 `indicator_combo` だった件数 |
| `escalation` | `pass_rate==0` かつ scaffold バグ起因（`scaffold_transformation_rate>=0.5` もしくは中間域）のとき `true`。loop 即停止対象（issue #467） |
| `warning` | `pass_rate==0` かつ `same_combo_streak==last_n` で `scaffold_transformation_rate<=0.1` のとき `true`。`agent_selection_bias` のみ。loop は続行可能（exit 0）で、エージェントは次のランで他指標を選んで自動解消する（issue #467） |
| `escalation_type` | 原因種別（issue #436 / #467）。`"scaffold_degradation"`（escalation） / `"agent_selection_bias"`（warning） / `null` |
| `recommended_actions` | 検出された問題に対する人間向けの推奨アクション |

#### エスカレーション判定

DB 件数が `--last` に満たない場合は観測のみ（`escalation: false` / `warning: false` 固定）でブロックしません。
`--last` 件以上の履歴がある場合のみ、以下のいずれかを返します。

- 合格率 `0%` かつ scaffold 変換率 `>=50%` → `escalation: true` / `escalation_type: "scaffold_degradation"`（即停止）
- 合格率 `0%` かつ直近 N 件すべての `indicator_combo` が同一：
  - scaffold 変換率 `<=10%` → `warning: true` / `escalation: false` / `escalation_type: "agent_selection_bias"`（エージェント側の選択バイアス、issue #467 で warning に格下げ。`--strict` でも exit 0）
  - 中間域（10% < 変換率 < 50%）→ 保守的に `escalation: true` / `"scaffold_degradation"` に倒す

#### 無人運転スキルでの使用例

```bash
# /explore-strategies の各ラン冒頭で実行
FORGE_CONFIG=forge.yaml forge explore health \
  --goal default --last 5 --strict --json
# exit code 1 → recommended_actions を提示してループ停止
```

---

## pine

戦略 JSON と TradingView Pine Script v6 を相互変換します。

!!! warning "[有料プランのみ] Pine Script エクスポート"
    `forge pine generate` と `forge pine preview` は**有料プラン（Lifetime / Annual / Monthly）でのみ利用できます**。Free プランで実行すると赤枠 Panel と購入ページ URL（[https://alforgelabs.com/en/index.html#pricing](https://alforgelabs.com/en/index.html#pricing)）が表示され、終了コード `1` で完全停止します。ファイル出力も標準出力もされません。`forge pine import`（インポート機能）は対象外で、Free でも継続利用できます。詳しくは [フリーミアム制限ガイド](../guides/freemium-limits.md) を参照してください。

### forge pine generate `[有料プランのみ]`

戦略定義から Pine Script を生成し、`config.pinescript.output_path / <strategy_id>.pine` に保存します。**有料プラン限定**。

```bash
forge pine generate --strategy <ID> [--with-training-data]
```

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--strategy` | 必須 | - | 戦略名 |
| `--with-training-data` | フラグ | false | HMM インジケータがある場合、学習済みパラメータを Pine Script に埋め込む（データを自動フェッチ） |

サンプル出力（有料プラン）：

```text
✅ Pine Script が保存されました: output/pinescript/spy_sma_v1.pine
```

サンプル出力（Free プラン・ハードブロック）：

```text
╭─────────────── 🔒 有料プラン限定機能 ───────────────╮
│ Pine Script エクスポートは有料プラン（Lifetime /    │
│ Annual / Monthly）のみ利用できます。                │
│ TradingView でのシームレスな運用を行うには…         │
│ アップグレード: https://alforgelabs.com/en/...      │
╰────────────────────────────────────────────────────╯
```

### forge pine preview `[有料プランのみ]`

戦略定義から生成される Pine Script を標準出力でプレビューします（ファイル保存しない）。**有料プラン限定**。

```bash
forge pine preview --strategy <ID>
```

### forge pine import

Pine Script (`.pine`) をパースして戦略定義として取り込みます。

```bash
forge pine import <PINE_FILE> --id <STRATEGY_ID>
```

| 名前 | 種別 | 説明 |
|------|------|------|
| `PINE_FILE` | 引数（必須、ファイル必須） | `.pine` ファイルパス |
| `--id` | 必須 | 保存する戦略 ID |

パース失敗時は `エラー: Pine Script のパースに失敗しました - <details>` を出して標準エラーへ。

---

## indicator

`alpha-forge` がサポートするテクニカル指標 30+ のカタログ・詳細を参照します。

### forge indicator list

対応指標の一覧を表示します。`FILTER_NAME` 指定で部分一致絞り込み（大文字小文字を区別しない）。

```bash
forge indicator list [FILTER_NAME] [--detail]
```

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `FILTER_NAME` | 引数（任意） | - | 指標名のフィルタ |
| `--detail` | フラグ | false | 各指標のパラメータ・デフォルト値・説明を表示 |

サンプル出力：

```text
利用可能なインジケーター一覧（35件）:

  [トレンド]      SMA  EMA  WMA  HMA  TEMA  MACD  ADX  SUPERTREND
  [モメンタム]    RSI  STOCH  CCI  WILLR  ROC
  [ボラティリティ] ATR  BBANDS  KELTNER
  [出来高]        OBV  VWAP  CMF
  [レジーム]      HMM
  [その他]        EXPR  ALTDATA

詳細: forge indicator show <TYPE>
```

### forge indicator show

指定指標の詳細（説明・パラメータ・出力・使用例）を表示します。

```bash
forge indicator show <INDICATOR_TYPE>
```

| 名前 | 種別 | 説明 |
|------|------|------|
| `INDICATOR_TYPE` | 引数（必須） | 指標名（大文字小文字を区別しない） |

サンプル出力：

```text
SMA — Simple Moving Average

カテゴリー: トレンド

パラメーター:
  名前                 型       デフォルト              説明
  length              int      14                    期間
  source              str      close                 ソース列

出力: スカラー時系列

使用例 (JSON):
  {"id": "sma_20", "type": "SMA", "params": {"length": 20}, "source": "close"}
```

未知の指標名を指定すると `エラー: '<TYPE>' は認識されないインジケーターです。` を出して終了コード `1`。

---

## idea

投資アイデアの記録・タグ付け・検索を行うコマンドグループ。`config.ideas.ideas_path` 配下の `ideas.json` で管理します。

### forge idea add

新しいアイデアを追加します。

```bash
forge idea add <TITLE> --type <new_strategy|improvement> [OPTIONS]
```

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `TITLE` | 引数（必須） | - | アイデアのタイトル |
| `--type` | 必須（choice） | - | `new_strategy` / `improvement` |
| `--desc` | オプション | `""` | 詳細説明 |
| `--tag` | 複数指定可 | - | タグ |

出力: `追加しました: [<idea_id>] <title>`

### forge idea list

アイデア一覧を表示します。

```bash
forge idea list [--status <STATUS>] [--tag <TAG>] [--strategy <ID>]
```

| 名前 | 種別 | 説明 |
|------|------|------|
| `--status` | choice | `backlog` / `in_progress` / `tested` / `archived` |
| `--tag` | 複数指定可 | タグ AND フィルタ |
| `--strategy` | オプション | 戦略 ID フィルタ |

### forge idea show

アイデアの詳細を表示します。

```bash
forge idea show <IDEA_ID>
```

存在しない場合は `見つかりません: <id>` を出して終了コード `1`。

### forge idea status

アイデアのステータスを更新します。

```bash
forge idea status <IDEA_ID> <backlog|in_progress|tested|archived>
```

出力: `ステータスを更新しました: <title> → <status>`

### forge idea link

アイデアに戦略または実行記録をリンクします。

```bash
forge idea link <IDEA_ID> --strategy <ID> [--run <RUN_ID>] [--note <TEXT>]
```

| 名前 | 種別 | 説明 |
|------|------|------|
| `--strategy` | 必須 | リンク先の戦略 ID |
| `--run` | オプション | リンク先の `run_id`（指定すれば run と紐付け） |
| `--note` | オプション | リンクへのメモ |

### forge idea tag

アイデアのタグを追加・削除します（`--add` と `--remove` は同時指定可、両方未指定はエラー）。

```bash
forge idea tag <IDEA_ID> [--add <TAG>] [--remove <TAG>]
```

### forge idea note

アイデアにメモを追加します。

```bash
forge idea note <IDEA_ID> <TEXT>
```

### forge idea search

アイデアを全文検索します。

```bash
forge idea search [QUERY] [--status <STATUS>] [--tag <TAG>]
```

| 名前 | 種別 | 説明 |
|------|------|------|
| `QUERY` | 引数（任意） | 検索クエリ（タイトル・説明・メモを対象） |
| `--status` | choice | ステータスフィルタ |
| `--tag` | 複数指定可 | タグフィルタ |

---

## altdata

代替データ（センチメント、マクロ指標等）の取得・管理。`config.data.alt_storage_path` 配下に保存され、戦略 JSON では `ALTDATA` 指標タイプで参照できます。

### forge altdata fetch

```bash
forge altdata fetch <SOURCE_KEY> --start <YYYY-MM-DD> --end <YYYY-MM-DD>
```

| 名前 | 種別 | 説明 |
|------|------|------|
| `SOURCE_KEY` | 引数（必須） | データソースキー（プロバイダー固有） |
| `--start` | 必須 | 取得開始日 |
| `--end` | 必須 | 取得終了日 |

出力: `✅ <SOURCE_KEY>: <N>行を保存しました`。プロバイダー未登録時は `ClickException`。

### forge altdata list

```bash
forge altdata list
```

サンプル出力：

```text
保存済み代替データ件数: 2
SOURCE_KEY                INTERVAL   ROWS         START           END
fear_greed_index          1d          1525   2020-01-01   2025-12-31
vix_termstructure         1d          1530   2020-01-01   2025-12-31
```

### forge altdata info

```bash
forge altdata info <SOURCE_KEY>
```

ソースキー、時間足、行数、開始日・終了日、カラム、ファイルパス、ファイルサイズを表示。データ未取得時は `ClickException`。

---

## pairs

ペアトレード戦略のためのコインテグレーション検定とスプレッド構築。`statsmodels` ベースの Engle–Granger 検定を使用。

### forge pairs scan

2 銘柄のコインテグレーション検定を実行します。

```bash
forge pairs scan <SYM_A> <SYM_B> [OPTIONS]
```

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `SYM_A`, `SYM_B` | 引数（必須） | - | 検定対象の 2 銘柄 |
| `--method` | choice | `engle_granger` | コインテグレーション検定手法 |
| `--pvalue` | float | `0.05` | コインテグレーションと判定する p 値閾値 |
| `--interval` | オプション | `1d` | 時間足 |

サンプル出力：

```text
✅ コインテグレーションあり
  ペア      : SPY / QQQ
  p_value    : 0.012345
  閾値      : 0.05
  検定統計量: -3.5421
  臨界値 5%: -2.8623
```

### forge pairs scan-all

ウォッチリスト内の全ペアをスキャンします（最大 20 件まで表示）。

```bash
forge pairs scan-all --symbols-file <FILE> [--pvalue 0.05] [--interval 1d]
```

| 名前 | 種別 | 説明 |
|------|------|------|
| `--symbols-file` | 必須（ファイル） | 銘柄リスト（行ごと 1 銘柄、`#` コメント可） |
| `--pvalue` | float | p 値閾値（デフォルト 0.05） |

### forge pairs build

スプレッド系列を計算し、`alt_data` ストアに保存します（戦略 JSON から `ALTDATA` で参照可能）。

```bash
forge pairs build --sym-a <SYM> --sym-b <SYM> [OPTIONS]
```

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--sym-a` | 必須 | - | 銘柄 A（従属変数） |
| `--sym-b` | 必須 | - | 銘柄 B（独立変数） |
| `--interval` | オプション | `1d` | 時間足 |
| `--log-prices` / `--no-log-prices` | フラグ | `--log-prices` | 対数価格でスプレッドを計算 |
| `--output-id` | オプション | `<A>_<B>_spread` | 保存する `source_key` |

サンプル出力：

```text
ヘッジ比率を推定中... (SPY / QQQ)
  ヘッジ比率: 0.823145
  OU 半減期 : 12.4 日
  データ点数: 1530

✅ スプレッドを保存しました: source_key='SPY_QQQ_spread'
   戦略 JSON での参照方法:
   {"id": "spread", "type": "ALTDATA", "params": {"source_key": "SPY_QQQ_spread", "column": "spread"}}
```

平均回帰がない場合、半減期は `N/A (平均回帰なし)` と表示されます。

---

## ml

機械学習モデル用のデータセット作成・モデル学習・walk-forward 検証コマンド群です（issue #512 Phase 1-2, 4）。学習済み joblib モデルは既存の `ML_SIGNAL` 指標から `model_path` 指定で推論に利用できます。

### forge ml dataset build

保存済み OHLCV から特徴量行列と将来リターンラベルを結合した parquet データセットを生成します。

```bash
forge ml dataset build EURUSD=X --feature-set default_v1 --label binary:24:0.005 --interval 1h
forge ml dataset build EURUSD=X --label ternary:24:0.005
forge ml dataset build EURUSD=X --label regression:5
forge ml dataset build EURUSD=X --label binary:24:0.005 --json
```

**主なオプション**

| オプション | 説明 | 既定値 |
|-----------|------|-------|
| `--feature-set` | 組み込み feature set 名（`forge ml dataset feature-sets` で一覧） | `default_v1` |
| `--label` | ラベル仕様文字列（必須） | — |
| `--interval` | 時間足（OHLCV ロード時に使用） | `1d` |
| `--out` | 出力 parquet パス | `<storage_path>/../ml_datasets/<symbol>_<feature_set>_<label_type>_<interval>.parquet` |
| `--keep-nan` | NaN を含む行を残す | False（除外） |
| `--json` | サマリを JSON 出力 | False |

**ラベル仕様文字列**

- `binary:<forward_n>:<threshold_pct>` … forward_n バー後リターンが閾値を超えると 1
- `ternary:<forward_n>:<threshold_pct>` … +閾値超 → 1、−閾値未満 → −1、それ以外 → 0
- `regression:<forward_n>` … forward_n バー後の単純リターンをそのままラベル化

parquet ファイルにはシンボル・タイムフレーム・特徴量列名・ラベル設定がメタデータとして同梱されるため、Phase 2 の学習側はファイル単独で再現可能な学習が行えます。

### forge ml dataset feature-sets

利用可能な組み込み feature set を一覧表示します。

```bash
forge ml dataset feature-sets
```

### forge ml train

Phase 1 で生成したデータセット parquet からモデルを学習し、joblib + metrics.json を保存します（issue #512 Phase 2）。

```bash
forge ml train <DATASET.parquet> [OPTIONS]
```

**主なオプション**

| オプション | 説明 | 既定値 |
|-----------|------|-------|
| `--model` | モデル種別（`forge ml models` で一覧） | `logistic_regression` |
| `--test-ratio` | 末尾から test に回す比率（時系列順保持） | `0.2` |
| `--random-state` | 乱数シード | `42` |
| `--params` | モデル追加パラメータの JSON 文字列 | — |
| `--out` | 出力 joblib パス | `<storage_path>/../ml_models/<dataset_stem>_<model>.joblib` |
| `--json` | サマリを JSON 出力 | False |

**サポートモデル**

| モデル名 | タスク | 備考 |
|----------|-------|------|
| `logistic_regression` | 分類 | StandardScaler + LogisticRegression パイプライン |
| `random_forest_classifier` | 分類 | sklearn |
| `gradient_boosting_classifier` | 分類 | sklearn |
| `xgboost_classifier` | 分類 | optional（`uv add xgboost` が必要） |
| `linear_regression` | 回帰 | StandardScaler + LinearRegression |
| `random_forest_regressor` | 回帰 | sklearn |
| `gradient_boosting_regressor` | 回帰 | sklearn |
| `xgboost_regressor` | 回帰 | optional（`uv add xgboost` が必要） |

**評価メトリクス**

- 分類: accuracy / precision / recall / f1 / auc（二値分類時のみ）。weighted 平均を採用。
- 回帰: mse / mae / rmse / r2

**保存形式**

- モデル本体: joblib（scikit-learn 互換 API。`predict` / `predict_proba` をそのまま `ML_SIGNAL` 指標から呼べる）
- メトリクス: `<model>.joblib.metrics.json`（`model_type` / `task` / `feature_columns` / `n_train` / `n_test` / `train_metrics` / `test_metrics` / `config` / `trained_at` を格納）

### forge ml models

利用可能なモデル種別（分類 + 回帰）を一覧表示します。

```bash
forge ml models
```

### forge ml walk-forward

ML データセット parquet を N ウィンドウに分割し、各ウィンドウで独立に学習・評価して時系列安定性を検証します（issue #512 Phase 4）。モデル本体は保存しません（最終モデルは `forge ml train` で別途学習）。

```bash
forge ml walk-forward <DATASET.parquet> [OPTIONS]
```

**主なオプション**

| オプション | 説明 | 既定値 |
|-----------|------|-------|
| `--model` | モデル種別（`forge ml models` で一覧） | `logistic_regression` |
| `--n-splits` | ウィンドウ数 | `5` |
| `--train-ratio` | 各ウィンドウ内の学習比率 | `0.7` |
| `--random-state` | 乱数シード | `42` |
| `--params` | モデル追加パラメータの JSON 文字列 | — |
| `--out` | レポート JSON 出力先 | `<storage_path>/../ml_models/<dataset_stem>_<model>.walkforward.json` |
| `--json` | サマリを JSON 出力 | False |

**レポート JSON の主要フィールド**

- `model_type` / `task` / `n_splits` / `train_ratio`
- `windows[]`: 各ウィンドウの `fold` / `train_start` / `train_end` / `test_start` / `test_end` / `n_train` / `n_test` / `train_metrics` / `test_metrics`
- `aggregate_train_metrics` / `aggregate_test_metrics`: 各ウィンドウの単純平均
- `dataset`: 元データセットの symbol / interval / feature_set / label_type

**戦略 JSON の WFT との関係**

- `forge ml walk-forward`: **ML モデル単体** の時系列安定性検証
- `forge optimize walk-forward`: **戦略 JSON 全体**（ML_SIGNAL 指標を含む場合もあり）の WFT
- ML 補強戦略の真価は最終的に `forge optimize walk-forward` で計測。本コマンドはその前段で「学習可能なシグナルか」を選別するために使用する。

---

## docs

`alpha-forge` に同梱されているドキュメント・スキル・コマンド参考資料を参照します。

### forge docs list

```bash
forge docs list
```

利用可能な同梱ドキュメントの一覧を表示します。`✓` / `✗` でファイル存在を表します。

### forge docs show

```bash
forge docs show <NAME>
```

| 名前 | 種別 | 説明 |
|------|------|------|
| `NAME` | 引数（必須） | ドキュメント名（`forge docs list` で確認） |

ドキュメントの内容を標準出力に表示します。未知の名前を指定すると利用可能リストとともにエラー表示し、終了コード `1`。

---

## 共通の挙動

- **`FORGE_CONFIG`**: すべてのパス（戦略・データ・ジャーナル・アイデア・代替データ・出力先）は `FORGE_CONFIG` が指す `forge.yaml` で決まります
- **終了コード**: 成功 `0`、`click.UsageError` / 引数違反 `2`、`click.ClickException` `1`、`SystemExit(1)` で個別エラー
- **国際化**: すべてのコマンドは日本語と英語の両方の `--help` テキストを持ちます（`alpha_forge.i18n.L` 経由）

---

<!-- 同期元: `alpha-forge/src/alpha_forge/commands/{license,login,init,pine,indicator,idea,altdata,pairs,docs}.py` の Click decorator。alpha-forge 側で引数追加・コマンド変更があった場合、本ページも追従更新が必要。 -->
