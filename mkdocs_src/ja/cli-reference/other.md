# その他コマンド

[コアコマンド](index.md) 以外の補助・管理用コマンドを 1 ページにまとめています。10 グループ × 約 29 サブコマンドが対象です。詳細パラメータの完全なリストは `forge <group> <subcommand> --help` でも確認できます。

!!! info "サンプル出力について"
    本ページの出力例は `alpha-forge` のソースから読み取ったフォーマットを元にしたサンプルです。実際の数値はデータと環境によって異なります。

## グループ早見表

| グループ | サブコマンド | 主な用途 |
|---------|-------------|----------|
| [auth](#auth) | `login` `logout` `status` `check op` | Whop OAuth 認証と認証状態の確認 |
| [init](#init) | （単一コマンド） | 作業ディレクトリの初期化 |
| [pine](#pine) | `generate` `preview` `import` `verify` | TradingView Pine Script の生成・取り込み・MCP 検証 |
| [tv](#tv) | `chart` `inspect` | TradingView MCP（チャートスナップショット・任意ツール呼び出し） |
| [indicator](#indicator) | `list` `show` | 対応テクニカル指標の参照 |
| [idea](#idea) | `add` `list` `show` `status` `link` `tag` `note` `search` | 投資アイデアの記録・追跡 |
| [altdata](#altdata) | `fetch` `list` `info` | 代替データ（センチメント等）の管理 |
| [pairs](#pairs) | `scan` `scan-all` `build` | ペアトレード（コインテグレーション） |
| [ml](#ml) | `dataset build` `dataset feature-sets` `train` `models` `walk-forward` | ML データセット・モデル学習・walk-forward 検証（issue #512 Phase 1-2, 4） |

| [docs](#docs) | `list` `show` | 同梱ドキュメント参照 |

---

## auth

Whop OAuth 2.0 PKCE による認証コマンド群。サブコマンドはすべて `forge auth <subcommand>` で実行します。詳しい初回セットアップは [はじめに](../getting-started.md) を参照。

### forge auth login

ブラウザを開いて Whop で認証します。

```bash
forge auth login
```

ブラウザが自動で開き、Whop の OAuth 認証フローを実行します。引数・オプションなし。成功すると認証情報が `$XDG_CONFIG_HOME/forge/credentials.json`（未設定時 `~/.config/forge/credentials.json`）にキャッシュされます。

### forge auth logout

ログアウトして認証情報を削除します。

```bash
forge auth logout
```

`credentials.json` を削除します。引数・オプションなし。Whop マイページのメンバーシップ自体は影響を受けません。

### forge auth status

現在の認証状態を表示します。

```bash
forge auth status
```

サンプル出力：

```text
ユーザー ID      : user_abc123
アクセストークン: 2026-04-12 12:30 UTC（あと 45 分）
最終検証        : 2026-04-12 11:45 UTC（13 分前）
プラン          : annual
```

未認証時は次のように案内します：

```text
[AlphaForge] ログイン情報がありません。
  実行: forge auth login
```

開発スキップ環境変数（`ALPHA_FORGE_DEV_SKIP_LICENSE=1`）が有効な場合は `[AlphaForge] 開発スキップ中（EULA/認証は未完了）` を表示します。

### forge auth check op

1Password CLI（`op`）のセッション有効性を検証します。`.env.op` を併用するチームの CI フックで使用するためのもの（issue #411）。詳細は実装コメントを参照。

```bash
forge auth check op [--json]
```

セッション有効時に exit code `0`、無効時に exit code `2` を返します。

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

### forge pine verify

戦略から生成した Pine Script を **TradingView MCP server** で検証します（issue #523）。コンパイルチェックに加えて、Strategy Tester の集計値や個別トレードを alpha-forge のバックテスト結果と突き合わせて差異を検出できます。

```bash
forge pine verify --strategy <ID> [--check-mode <MODE>] [--mcp-server <CMD>] [--mcp-server-flavor <tradesdontlie|vinicius>] [OPTIONS]
```

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--strategy` | 必須 | - | 戦略名 |
| `--check-mode` | choice | `compile_only` | `compile_only` / `metrics` / `signal` / `regime` |
| `--mcp-server` | オプション | - | MCP サーバーコマンド（省略時 `forge.yaml` の `tv_mcp.pine_verify.endpoint`） |
| `--mcp-server-flavor` | choice | `tradesdontlie` | `vinicius` は `oviniciusramosp/tradingview-mcp` フォーク。metrics/signal モードでは推奨 |
| `--mock` | フラグ | false | Mock MCP クライアント（PoC・CI 用） |
| `--symbol` / `--interval` | オプション | - | TV シンボル / インターバル（metrics / signal モードで必須） |
| `--auto-backtest` | フラグ | false | alpha-forge バックテストを内部で実行して比較する |
| `--backtest-result` | オプション | - | 比較対象 alpha-forge バックテスト結果（JSON パスまたは `run_id`） |
| `--metric-tolerance` | float | `0.10` | metrics モードの相対差許容（10%） |
| `--match-tolerance-seconds` | int | `60` | signal モードのトレード時刻許容差（秒） |
| `--min-match-rate` | float | `0.95` | signal モードの最低トレード一致率 |
| `--output` | ファイル | - | レポート Markdown 出力先 |

**check-mode**

| モード | 用途 |
|--------|------|
| `compile_only` | Pine Script の構文・コンパイルだけを検証（`tradesdontlie` で十分） |
| `metrics` | TV Strategy Tester の総合メトリクス（PF・勝率・トレード数等）と alpha-forge のメトリクスを比較。**`vinicius` 推奨**（`tradesdontlie` の `data_get_strategy_results` バグ回避） |
| `signal` | tradesdontlie: TV のトレードリストと alpha-forge の `trades` を時刻ベースで突合し一致率を算出。<br>vinicius: 時刻情報を返さないため **count-based 比較**（トレード件数のみで合否判定）に自動切替（issue #580） |
| `regime` | Phase 1.5c-γ 以降。HMM 状態列の比較（実装中） |

**実行例**

```bash
# コンパイル検証のみ（最速）
forge pine verify --strategy spy_sma_v1 --mcp-server "node /opt/tv-mcp/server.js"

# Strategy Tester 集計の比較（vinicius 推奨）
forge pine verify --strategy spy_sma_v1 \
  --check-mode metrics \
  --symbol SPY --interval D \
  --mcp-server-flavor vinicius \
  --auto-backtest \
  --output reports/verify_spy.md
```

検証ガイドの詳細は [TradingView との Pine Script 連携](../guides/tradingview-pine-integration.md) を参照してください。

---

## tv

TradingView MCP server を介したチャート取得・任意ツール呼び出しを行うコマンドグループ（issue #523）。

### forge tv chart

TradingView チャートのスナップショット PNG を取得します（Phase 1.5d）。

```bash
forge tv chart <SYMBOL> [--interval D] [--width W] [--height H] [--theme light|dark] [--output <PNG>] [--mcp-server <CMD>]
```

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `SYMBOL` | 引数（必須） | - | TV シンボル |
| `--interval` | オプション | `D` | タイムフレーム（`1`, `5`, `60`, `D`, `W`, `M`） |
| `--width` / `--height` | int | `forge.yaml` の `tv_mcp.chart_snapshot` | 画像サイズ |
| `--theme` | choice | `forge.yaml` 既定 | `light` / `dark` |
| `--output` | ファイル | - | 出力 PNG パス。省略時はキャッシュパスのみ表示 |
| `--mcp-server` | オプション | - | MCP サーバー（省略時 `tv_mcp.chart_snapshot.endpoint`） |
| `--mock` | フラグ | false | Mock MCP（CI 用） |
| `--no-cache` | フラグ | false | キャッシュを無視 |
| `--md-output` | ファイル | - | Markdown ファイルに画像リンクを追記（`--output` 必須） |
| `--md-alt` | オプション | - | Markdown 画像 alt（既定: `SYMBOL Interval`） |

実行例：

```bash
forge tv chart SPY --interval D --output charts/spy_d.png \
  --mcp-server "python /opt/tv-mcp-chart/server.py"
```

### forge tv inspect

任意の MCP tool を呼び出して JSON でレスポンスを表示します（Phase 1.5c-α）。新しい MCP server の挙動確認や、サポートされているツール一覧の探索に使います。

```bash
forge tv inspect <TOOL_NAME> [--server-type pine|chart] [--mcp-server <CMD>] [--arg key=value ...] [--args-json '{...}'] [--output <JSON>] [--pretty|--compact]
```

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `TOOL_NAME` | 引数（必須） | - | 呼び出す MCP tool 名 |
| `--server-type` | choice | `pine` | endpoint 既定値の選択（`pine` = `tv_mcp.pine_verify`、`chart` = `tv_mcp.chart_snapshot`） |
| `--mcp-server` | オプション | - | 直接サーバーコマンドを指定 |
| `--mock` | フラグ | false | 固定 Mock レスポンス（CI 用） |
| `--arg` | 複数指定可 | - | tool 引数 `key=value`（値は JSON として解釈試行） |
| `--args-json` | オプション | - | tool 引数を JSON オブジェクトで指定（`--arg` と排他） |
| `--output` | ファイル | - | JSON 出力先 |
| `--pretty` / `--compact` | フラグ | `--pretty` | 整形 / 1 行 JSON |

実行例：

```bash
# tool 一覧（実装に依存）
forge tv inspect list_tools --server-type pine \
  --mcp-server "node /opt/tv-mcp/server.js"

# data_get_ohlcv を試す
forge tv inspect data_get_ohlcv \
  --arg symbol=SPY --arg interval=D --arg bars=10
```

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
- `triple_barrier:<max_holding>:<atr_mult_up>:<atr_mult_down>:<atr_window>` … López de Prado triple-barrier（issue #520、3 値）。各バーで ATR ベースの上下バリアを設置し、max_holding バーまでの間で先に当たったものでラベル付け（上 → 1、下 → −1、timeout → 0）。ボラティリティ適応的で固定閾値より regime ロバスト
- `triple_barrier_sym:<max_holding>:<atr_mult>:<atr_window>` … triple_barrier の対称版 shorthand（up=down=`atr_mult`）。**新規 dataset の既定推奨**は `triple_barrier_sym:24:1.5:14`（issue #538）
- `triple_barrier_vol:<max_holding>:<vol_mult>:<atr_window>` … barrier scale を ATR の代わりに `rolling_std(returns, atr_window) × close` で計算する volatility-adaptive 版（issue #538）。低ボラ局面で barrier も自動的に縮む
- `triple_barrier_balanced:<max_holding>:<target_long_share>:<atr_window>` … 二分探索で対称 atr_mult を調整して long クラス比率を target に合わせる rebalance mode（issue #538）。例: `target_long_share=0.33` で 3 クラスをほぼ均等にしたい場合

> **issue #538 の背景**: 非対称比 `2.0:1.0` だと SL ヒット側（−1）が分布の半数以上を占める偏向が起きやすい（issue #520 検証で −1 が 64% に集中）。新規 dataset は `triple_barrier_sym:24:1.5:14` を出発点にすると、proba dispersion（issue #537）の screening を通りやすくなります。

parquet ファイルにはシンボル・タイムフレーム・特徴量列名・ラベル設定がメタデータとして同梱されるため、Phase 2 の学習側はファイル単独で再現可能な学習が行えます。

### forge ml dataset feature-sets

利用可能な組み込み feature set を一覧表示します。

```bash
forge ml dataset feature-sets
```

**組み込み feature set**

| 名前 | 用途 | 内容 |
|---|---|---|
| `default_v1` | 株式・先物等 Volume が有効な銘柄 | LAG(close 1/2/5/10) + PCT_CHANGE(close 1/5) + ROLLING_MEAN/STD/MIN/MAX(20) + PCT_CHANGE(volume 1) |
| `default_v1_fx` | **FX 銘柄**（issue #518） | `default_v1` から `PCT_CHANGE(volume)` を除いたもの。yfinance 系 FX は Volume が常に 0 のため、`default_v1` を使うと `dropna` で全行が消えるバグを回避 |
| `mtf_v1` | **複数タイムフレーム表現**（issue #520） | 短期 lag (1, 6, 24, 48, 120) + 複数 window の rolling 統計 (5, 20, 120, 480) + ボラレジーム + 高安レンジ。Volume を含まないので FX でも使える。`triple_barrier` ラベルとの組合せ推奨 |

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

**確率校正（`--calibration`、issue #519）**

`gradient_boosting_classifier` 等の確率出力は素のままだと特定領域に偏ることがあり、`ml_long_prob >= 0.6` のような閾値が機能しなくなることがあります（issue #512 検証で確認）。`--calibration` オプションで分類モデルの `predict_proba` 出力を校正できます。

| 値 | 説明 |
|---|---|
| `none`（既定） | 校正なし |
| `sigmoid` | Platt scaling（少サンプル向け） |
| `isotonic` | 等浸透回帰（多サンプル向け） |

```bash
forge ml train ds.parquet --model random_forest_classifier --calibration isotonic
```

回帰モデルに指定した場合は warning 出力 + 無視（base model のまま）。校正された joblib も `ML_SIGNAL` / `ML_SIGNAL_WFT` 指標からそのまま推論可能（scikit-learn 互換 API）。

**保存形式**

- モデル本体: joblib（scikit-learn 互換 API。`predict` / `predict_proba` をそのまま `ML_SIGNAL` 指標から呼べる）
- メトリクス: `<model>.joblib.metrics.json`（`model_type` / `task` / `feature_columns` / `n_train` / `n_test` / `train_metrics` / `test_metrics` / `config`（`calibration` 含む）/ `trained_at` を格納）

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

**proba dispersion メトリクス（分類タスクのみ、issue #537）**

`aggregate_test_metrics` および各 `windows[].test_metrics` には、accuracy/precision/recall/f1 に加えて `predict_proba` の分布メトリクスが含まれます。これは「accuracy/spread は基準を満たすが proba 値が低位レンジに集中して entry 閾値で実質ほぼ False になる」モデルを screening 段階で検出するためのものです。

| キー | 内容 |
|---|---|
| `proba_max` | 各 fold の正クラス確率の最大値（fold 平均） |
| `proba_p90` / `proba_p95` | 90 / 95 パーセンタイル（fold 平均） |
| `proba_above_055` | 正クラス確率 >= 0.55 の比率（fold 平均、0.0–1.0） |
| `proba_above_060` | 同 >= 0.60 の比率 |

テキスト出力でも集計直下に 1 行表示されます:

```text
proba_dispersion: max=0.568 p90=0.412 p95=0.456 share>=0.55=0.54% share>=0.60=0.12%
```

**読み方の目安**: `share>=0.55` が極小（数 % 以下）の場合、entry 条件で `ml_long_prob >= 0.55` を使うとフィルタが事実上機能しません。閾値を 0.45–0.50 に下げる、`--calibration` で校正する、ラベル仕様を変える（例: `triple_barrier` の barrier 比対称化）などを検討してください。回帰タスクではこれらのキーは出力されません。

**screening 判定と推奨アクション（issue #565）**

`forge ml walk-forward` は分類タスクの場合、上記メトリクスを使って **3 軸の自動判定** と **推奨アクション** を出力します（出力末尾の SCREENING RESULT / RECOMMENDATION ブロック）。

| 軸 | 既定閾値 | 上書き CLI オプション |
|---|---|---|
| `accuracy`（test 集計平均） | `>= 0.55` | `--screen-accuracy-min` |
| `fold_spread`（各 fold accuracy の最大-最小） | `<= 0.15` | `--screen-spread-max` |
| `proba_dispersion`（`proba_above_055`） | `>= 0.05` | `--screen-proba055-min` |

不合格パターン別の推奨アクション:

| パターン | 推奨 |
|---|---|
| accuracy NG | データ量・特徴量を増やす / モデル種別を変える（`accuracy_low`） |
| accuracy OK / spread NG | データ非定常性が強い → ラベル期間短縮 / regime 別学習（`fold_spread_high`） |
| accuracy/spread OK / proba NG | 閾値下げる / calibration 変える / ラベル比対称化（`proba_low_dispersion`） |
| すべて NG | 学習可能なシグナルではない → 特徴量設計から見直す（`no_learnable_signal`） |

JSON 出力では `screening` フィールドに `criteria` / `recommendations` / `overall_pass` がそのまま入ります。回帰タスクは現状 screening 対象外で、このフィールドは出力されません。

**戦略 JSON の WFT との関係**

- `forge ml walk-forward`: **ML モデル単体** の時系列安定性検証
- `forge optimize walk-forward`: **戦略 JSON 全体**（ML_SIGNAL 指標を含む場合もあり）の WFT
- ML 補強戦略の真価は最終的に `forge optimize walk-forward` で計測。本コマンドはその前段で「学習可能なシグナルか」を選別するために使用する。

### `ML_SIGNAL_WFT` 指標 — leak 安全な ML 補強（issue #517）

`forge ml train` で保存した joblib モデルを `ML_SIGNAL` 指標から参照すると、`forge optimize walk-forward` の OOS が学習期間と重複した場合に **look-ahead leak** が発生します（issue #512 Phase 4 検証で確認済み）。これを構造的に解消する新指標が `ML_SIGNAL_WFT` です。

`ML_SIGNAL_WFT` は **指標計算関数自体が「渡された df の先頭 train_ratio で自己学習 → 全体に対して predict」** を行う自己完結型の指標で、WFT エンジン側の変更は不要です。学習区間の予測値は NaN にされ、取引判断には test 区間の予測値のみが使われます。

**戦略 JSON の例**

```json
{
  "id": "ml_long_prob",
  "type": "ML_SIGNAL_WFT",
  "params": {
    "model_type": "gradient_boosting_classifier",
    "model_params": {"n_estimators": 200, "max_depth": 5},
    "features": [
      {"type": "LAG", "source": "close", "periods": [1, 2, 5, 10]},
      {"type": "PCT_CHANGE", "source": "close", "periods": 1},
      {"type": "ROLLING_MEAN", "source": "close", "window": 20}
    ],
    "label": "binary:24:0.005",
    "train_ratio": 0.7,
    "min_train_rows": 500,
    "random_state": 42,
    "output": "proba",
    "proba_class": 1,
    "threshold": null
  }
}
```

**主要パラメータ**

| パラメータ | 型 | 既定 | 説明 |
|---|---|---|---|
| `model_type` | str | — | `forge ml models` で表示されるモデル種別 |
| `model_params` | dict | `{}` | モデル追加パラメータ |
| `features` | list | — | `build_feature_matrix` 互換のスペック |
| `label` | str | — | `binary:N:thr` / `ternary:N:thr` / `regression:N` |
| `train_ratio` | float | 0.7 | 先頭の何割を学習に使うか |
| `min_train_rows` | int | 100 | 学習行数がこれ未満なら全 NaN（leak 防止優先） |
| `output` | str | "proba" | "proba"（確率）または "predict"（クラス） |
| `proba_class` | int | 1 | predict_proba のクラスインデックス |
| `threshold` | float \| null | null | 指定があれば proba >= threshold を 1 化 |
| `calibration` | str | "none" | 確率校正（issue #519）。"none" / "sigmoid" / "isotonic" |

**`ML_SIGNAL` との使い分け**

| 指標 | 用途 | leak 耐性 |
|---|---|---|
| `ML_SIGNAL` | 事前学習済みの joblib モデルを参照 | OOS が学習期間外なら安全、重複あれば leak |
| `ML_SIGNAL_WFT` | **WFT 整合の本番運用** — 評価コンテキスト内で自己学習 | **構造的に leak 不可能** |

**学習結果のキャッシュ**

WFT は各ウィンドウで Optuna を N 回試行するため、同じ IS データに対して `_calc_ml_signal_wft` が N 回呼ばれます。再学習を避けるため本指標は **コンテンツアドレス指定型のディスクキャッシュ**（既定: `<storage_path>/../ml_models/wft_cache/`）を持ち、SHA-256 で `(feature_columns, label values, model_type, model_params, random_state)` をキー化して joblib を再利用します。同じ入力なら 2 回目以降はキャッシュヒットで即座に推論可能です。

**Pine Script との関係**

`ML_SIGNAL` と同様、`ML_SIGNAL_WFT` も Pine Script には変換できません。`forge pine generate` 時には警告コメント付きで `<id> = true` として扱われます。

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

<!-- 同期元: `alpha-forge/src/alpha_forge/commands/{auth,init,pine,indicator,idea,altdata,pairs,docs}.py` の Click decorator。alpha-forge 側で引数追加・コマンド変更があった場合、本ページも追従更新が必要。 -->
