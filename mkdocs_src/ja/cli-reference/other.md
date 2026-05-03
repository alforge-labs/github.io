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
| [idea](#idea) | `add` `list` `show` `status` `link` `tag` `note` `search` `dashboard` | 投資アイデアの記録・追跡 |
| [altdata](#altdata) | `fetch` `list` `info` | 代替データ（センチメント等）の管理 |
| [pairs](#pairs) | `scan` `scan-all` `build` | ペアトレード（コインテグレーション） |
| [dashboard](#dashboard) | （単一コマンド） | Web ダッシュボードの起動 |
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
| `recommend` | 次の探索候補を `recommendations.yaml` へ出力 |
| `coverage` | パラメータカバレッジ（YAML）の更新・参照 |

### forge explore run

バックテスト → 最適化 → ウォークフォワードテスト（WFT）→ coverage 更新 → DB 登録を 1 コマンドで完結させます。  
エージェントの `/explore-strategies` スキルから内部的に呼び出されます。

```bash
forge explore run <SYMBOL> --strategy <NAME> --goal <GOAL> [--no-cleanup] [--dry-run] [--json] [--db <PATH>]
```

| オプション | 説明 | デフォルト |
|-----------|------|-----------|
| `--strategy` | 戦略名（必須） | — |
| `--goal` | ゴール名（`goals.yaml` の `pre_filter` / `target_metrics` を適用） | `default` |
| `--no-cleanup` | 不合格時もファイル・DB エントリを削除しない（デバッグ用） | off |
| `--dry-run` | 実行予定ステップを表示して終了（実際の処理は行わない） | off |
| `--json` | 結果を JSON 形式で標準出力する | off |
| `--db` | 探索 DB のパス（省略時は `forge.yaml` のデフォルトパス） | — |

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
  "cleanup_done": true
}
```

| フィールド | 説明 |
|-----------|------|
| `passed` | WFT が `target_metrics` を満たした場合 `true` |
| `skip_reason` | スキップ・失敗理由（`no_signals` / `pre_filter_failed` / `wft_failed` / `dry_run` / `null`） |
| `cleanup_done` | 不合格時に戦略 JSON / 結果 JSON が削除済みの場合 `true` |

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

### forge idea dashboard

`forge dashboard` と同等の Web ダッシュボードを起動します。

```bash
forge idea dashboard [--port 8000] [--no-open]
```

詳細は [`forge dashboard`](#dashboard) を参照。

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

## dashboard

Web ダッシュボードを起動します（FastAPI + uvicorn）。エクイティカーブ・ドローダウン・モンテカルロ・WFO 結果などをブラウザで閲覧可能。

### 構文

```bash
forge dashboard [--port 8000] [--host 127.0.0.1] [--no-open]
```

### オプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--port` | int | `8000` | バインドポート |
| `--host` | オプション | `127.0.0.1` | バインドホスト |
| `--no-open` | フラグ | false | ブラウザを自動で開かない |

サンプル出力：

```text
ダッシュボードを起動中: http://127.0.0.1:8000  (Ctrl+C で停止)
```

`fastapi` / `uvicorn` 未インストール時は案内メッセージを出して終了します（`forge.yaml` セットアップ後の `uv sync` で同梱されます）。

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

<!-- 同期元: `alpha-forge/src/alpha_forge/commands/{license,login,init,pine,indicator,idea,altdata,pairs,dashboard,docs}.py` の Click decorator。alpha-forge 側で引数追加・コマンド変更があった場合、本ページも追従更新が必要。 -->
