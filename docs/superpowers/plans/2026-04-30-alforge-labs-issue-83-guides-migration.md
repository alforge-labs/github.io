# 削除した 3 ガイドを MkDocs に移植 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** PR #82 (#65) で `templates/docs.html.j2` を簡素化した際に削除された 3 ガイドコンテンツを `mkdocs_src/{ja,en}/guides/` に新規 md ページとして移植し、MkDocs nav に「ガイド」サブメニューを追加して `alforgelabs.com/{ja,en}/docs/guides/...` で公開する。

**Architecture:** mkdocs_src/{ja,en}/guides/ に新規 md 6 ファイルを作成 → mkdocs.{ja,en}.yml の nav に「ガイド」サブメニュー追加 → `uv run mkdocs build -f mkdocs.{ja,en}.yml --clean` で成果物を再生成 → 2 コミット（md + nav / build 成果物）→ PR 作成。新規 CSS や JS は無し、既存 mkdocs-material のスタイル / pymdownx 拡張のみで完結。

**Tech Stack:** MkDocs Material, Python 3 (uv), pymdownx (admonition / superfences / highlight / tabbed / details / toc), Markdown, gh CLI

**作業ブランチ:** `feat/docs-issue-83-guides-migration`（spec コミット `bcb83f6` で作成済み）

**Spec:** `docs/superpowers/specs/2026-04-30-alforge-labs-issue-83-guides-migration-design.md`

---

## File Structure

| ファイル | 責務 | 変更タイプ |
|---|---|---|
| `mkdocs.ja.yml` | 日本語版 MkDocs 設定 | 編集（nav に「ガイド」サブメニュー 4 行追加） |
| `mkdocs.en.yml` | 英語版 MkDocs 設定 | 編集（nav に "Guides" サブメニュー 4 行追加） |
| `mkdocs_src/ja/guides/end-to-end-workflow.md` | ja Guide 1 ソース | 新規 |
| `mkdocs_src/ja/guides/tradingview-pine-integration.md` | ja Guide 2 ソース | 新規 |
| `mkdocs_src/ja/guides/tradingview-alpha-strike.md` | ja Guide 3 ソース | 新規 |
| `mkdocs_src/en/guides/end-to-end-workflow.md` | en Guide 1 ソース | 新規 |
| `mkdocs_src/en/guides/tradingview-pine-integration.md` | en Guide 2 ソース | 新規 |
| `mkdocs_src/en/guides/tradingview-alpha-strike.md` | en Guide 3 ソース | 新規 |
| `ja/docs/guides/*` | mkdocs build 出力 | 新規（コミット） |
| `en/docs/guides/*` | mkdocs build 出力 | 新規（コミット） |
| その他 | 全部 | **変更なし** |

---

## Task 1: 6 ガイド md を作成 + mkdocs.{ja,en}.yml に nav を追加 → コミット 1

このタスクは 1 つの subagent で実装する。ファイル新規作成（Write）と既存ファイルへの nav 行追加（Edit）の組み合わせ。

### Step 1: ja ディレクトリ準備

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs && mkdir -p mkdocs_src/ja/guides mkdocs_src/en/guides && ls -la mkdocs_src/ja/guides/ mkdocs_src/en/guides/
```
期待: 各ディレクトリが新規作成され、空である（`. ..` のみ）。

### Step 2: `mkdocs_src/ja/guides/end-to-end-workflow.md` を Write

```markdown
# エンドツーエンド戦略開発ワークフロー

ヒストリカルデータの取得から自動発注までの典型的な開発フロー。Claude Code などのコーディングエージェントと組み合わせると、各ステップの自動化やパラメータ探索を高速化できます。

!!! note "前提"
    以下のコマンドはすべて `alpha-strategies/` ディレクトリから `FORGE_CONFIG=forge.yaml uv run` 付きで実行することを想定しています。

## 1. データ取得

対象シンボルのヒストリカルデータをローカルに保存します。

```bash
forge data fetch USDJPY
```

## 2. 戦略テンプレート作成

テンプレートから戦略 JSON の雛形を生成し、パラメータを編集してから登録します。

```bash
forge strategy create --template ema_crossover \
  --id usdjpy_ema_v1 \
  --out data/strategies/usdjpy_ema_v1.json

# 生成されたファイルをエディタで編集し、パラメータを調整
forge strategy save data/strategies/usdjpy_ema_v1.json
```

## 3. バックテスト実行

定義した戦略のパフォーマンスを過去データで検証します。

```bash
forge backtest run USDJPY --strategy usdjpy_ema_v1

# インタラクティブチャートで視覚的に確認
forge backtest chart USDJPY --strategy usdjpy_ema_v1
```

## 4. パラメータ最適化

Optuna のベイズ最適化（TPE）で最適なパラメータを探索します。

```bash
forge optimize run USDJPY --strategy usdjpy_ema_v1 \
  --metric sharpe_ratio --trials 300 --save

# 結果を新しい戦略として保存
forge optimize apply data/results/usdjpy_ema_v1_opt.json \
  --to-strategy usdjpy_ema_v1_optimized
```

## 5. ウォークフォワード検証

過学習を検出するため、訓練期間とテスト期間を分けた検証を行います。

```bash
forge optimize walk-forward USDJPY \
  --strategy usdjpy_ema_v1_optimized --windows 5

# 感度分析でパラメータの堅牢性を確認
forge optimize sensitivity USDJPY \
  --strategy usdjpy_ema_v1_optimized
```

## 6. Pine Script 生成

TradingView 用のアラートスクリプトを自動生成します。

```bash
forge pine generate --strategy usdjpy_ema_v1_optimized
```

出力先: `output/pinescript/usdjpy_ema_v1_optimized.pine`

!!! tip "関連コマンド"
    各サブコマンドの完全なオプション一覧は [CLI リファレンス](../cli-reference/index.md) を参照してください。次のステップは [TradingView への Pine Script 反映](tradingview-pine-integration.md) です。
```

### Step 3: `mkdocs_src/ja/guides/tradingview-pine-integration.md` を Write

```markdown
# TradingView への Pine Script 反映

`forge pine generate` で生成した `.pine` ファイルを TradingView に貼り付けてアラートを設定します。

## 1. Pine エディタを開く

TradingView でチャートを開き、画面下部の「Pine エディタ」タブをクリックします。

## 2. スクリプトを貼り付ける

生成した `.pine` ファイルの内容をエディタに貼り付け、「スクリプトを追加」（▶ ボタン）をクリックします。

## 3. アラートを設定する

チャート右上のベルアイコン（アラート）→「アラートを追加」をクリック。

- **条件**: 追加したスクリプト名を選択
- **Webhook URL**: チェックを入れ、alpha-strike のエンドポイントを入力
- **メッセージ**: 後述の JSON ペイロードを入力（[alpha-strike 連携ガイド](tradingview-alpha-strike.md) 参照）

## 4. アラートメッセージのヒント

Pine Script 内でシグナル変数（例: `longSignal`）を定義しておくと、アラートの条件設定が簡単になります。

```pinescript
// Pine Script 内でのアラート定義例
longSignal = ta.crossover(ema_fast, ema_slow)
shortSignal = ta.crossunder(ema_fast, ema_slow)
alertcondition(longSignal, title="Long Entry", message="long")
```

!!! tip "次のステップ"
    Webhook 受信側の設定は [TradingView と alpha-strike の連携](tradingview-alpha-strike.md) を参照してください。
```

### Step 4: `mkdocs_src/ja/guides/tradingview-alpha-strike.md` を Write

```markdown
# TradingView と alpha-strike の連携

alpha-strike は TradingView のアラートを Webhook で受け取り、OANDA・moomoo 証券に自動発注します。

## 1. 環境変数の設定

`alpha-strike/.env` を作成して以下を設定します。

```bash
# 必須
WEBHOOK_PASSPHRASE=your-secret-passphrase   # 任意の秘密文字列

# OANDA 使用時
OANDA_API_KEY=your-personal-access-token
OANDA_ACCOUNT_ID=your-account-id
OANDA_ENV=PRACTICE    # 本番は LIVE

# moomoo 使用時
MOOMOO_HOST=127.0.0.1
MOOMOO_PORT=11111
MOOMOO_TRD_ENV=SIMULATE   # 本番は REAL
```

## 2. Webhook URL

!!! note "Webhook エンドポイント"
    TradingView のアラート Webhook URL に以下を設定します:
    `http://<your-server>:8080/webhook`

## 3. ペイロード仕様

TradingView のアラートメッセージに JSON を記述します。

```json
{
  "passphrase": "your-secret-passphrase",
  "broker": "oanda",
  "asset_class": "FX",
  "action": "buy",
  "ticker": "USDJPY",
  "quantity": 1000
}
```

| フィールド | 説明 | 値の例 |
|------|------|--------|
| `passphrase` | **必須** — `.env` の `WEBHOOK_PASSPHRASE` と一致させること | `"my-secret"` |
| `broker` | **必須** — 発注先の証券会社 | `"oanda"` / `"moomoo"` |
| `asset_class` | **必須** — アセットクラス | `"FX"` / `"COMMODITY"` / `"US"` / `"INDEX"` |
| `action` | **必須** — 注文方向 | `"buy"` / `"sell"` |
| `ticker` | **必須** — 銘柄コード（TradingView のシンボル名） | `"USDJPY"` / `"XAUUSD"` |
| `quantity` | **必須** — 注文数量（0 より大きい正の数） | `1000` / `0.1` |

## 4. ティッカーと OANDA instrument の対応

| asset_class | ticker 例 | OANDA instrument |
|---|---|---|
| FX | USDJPY | USD_JPY |
| COMMODITY | XAUUSD | XAU_USD |
| INDEX | NAS100 | NAS100_USD |
| US | AAPL | AAPL_USD |

## 5. 動作確認

```bash
# ヘルスチェック
curl http://localhost:8080/health
# → {"status":"ok"}

# テスト発注（PRACTICE / SIMULATE 環境で確認）
curl -X POST http://localhost:8080/webhook \
  -H "Content-Type: application/json" \
  -d '{"passphrase":"your-secret","broker":"oanda","asset_class":"FX","action":"buy","ticker":"USDJPY","quantity":1000}'
```
```

### Step 5: `mkdocs_src/en/guides/end-to-end-workflow.md` を Write

```markdown
# End-to-End Strategy Development Workflow

A typical flow from raw data to live execution. This pairs naturally with a coding agent (e.g. Claude Code) for automated parameter exploration and strategy generation.

!!! note "Prerequisite"
    All commands below assume you are running from `alpha-strategies/` with `FORGE_CONFIG=forge.yaml uv run` prepended.

## 1. Fetch historical data

Save historical OHLCV data for a target symbol locally.

```bash
forge data fetch USDJPY
```

## 2. Create a strategy from a template

Generate a JSON scaffold, edit parameters, and register it.

```bash
forge strategy create --template ema_crossover \
  --id usdjpy_ema_v1 \
  --out data/strategies/usdjpy_ema_v1.json

# Edit the JSON, then register
forge strategy save data/strategies/usdjpy_ema_v1.json
```

## 3. Run a backtest

Validate the strategy against historical data.

```bash
forge backtest run USDJPY --strategy usdjpy_ema_v1

# Visual equity curve
forge backtest chart USDJPY --strategy usdjpy_ema_v1
```

## 4. Optimize parameters

Bayesian search with Optuna (TPE), then apply the best result.

```bash
forge optimize run USDJPY --strategy usdjpy_ema_v1 \
  --metric sharpe_ratio --trials 300 --save

forge optimize apply data/results/usdjpy_ema_v1_opt.json \
  --to-strategy usdjpy_ema_v1_optimized
```

## 5. Walk-forward validation

Detect overfitting with out-of-sample testing.

```bash
forge optimize walk-forward USDJPY \
  --strategy usdjpy_ema_v1_optimized --windows 5

# Confirm parameter robustness
forge optimize sensitivity USDJPY \
  --strategy usdjpy_ema_v1_optimized
```

## 6. Generate Pine Script

Export a TradingView alert script from the optimized strategy.

```bash
forge pine generate --strategy usdjpy_ema_v1_optimized
```

Output: `output/pinescript/usdjpy_ema_v1_optimized.pine`

!!! tip "Related commands"
    See [CLI Reference](../cli-reference/index.md) for the complete option lists. Next step: [Bringing Pine Scripts into TradingView](tradingview-pine-integration.md).
```

### Step 6: `mkdocs_src/en/guides/tradingview-pine-integration.md` を Write

```markdown
# Bringing Pine Scripts into TradingView

Paste the `.pine` file generated by `forge pine generate` into TradingView and configure an alert.

## 1. Open the Pine Editor

Open a chart in TradingView and click the "Pine Editor" tab at the bottom of the screen.

## 2. Paste the script

Copy the contents of the generated `.pine` file into the editor and click "Add to chart" (▶).

## 3. Create an alert

Click the bell icon (Alerts) on the top right → "Create alert".

- **Condition**: Select your script
- **Webhook URL**: Enable and paste the alpha-strike endpoint
- **Message**: Use the JSON payload format described in the [alpha-strike integration guide](tradingview-alpha-strike.md)

## 4. Tip: in-script alert conditions

Defining `alertcondition` inside Pine Script makes alert setup cleaner.

```pinescript
// Example alertcondition definition
longSignal = ta.crossover(ema_fast, ema_slow)
shortSignal = ta.crossunder(ema_fast, ema_slow)
alertcondition(longSignal, title="Long Entry", message="long")
```

!!! tip "Next step"
    Configure the webhook receiver in [TradingView × alpha-strike Integration](tradingview-alpha-strike.md).
```

### Step 7: `mkdocs_src/en/guides/tradingview-alpha-strike.md` を Write

```markdown
# TradingView × alpha-strike Integration

alpha-strike receives TradingView webhook alerts and forwards orders to OANDA or moomoo brokers.

## 1. Configure environment variables

Create `alpha-strike/.env` with the following:

```bash
# Required
WEBHOOK_PASSPHRASE=your-secret-passphrase

# OANDA
OANDA_API_KEY=your-personal-access-token
OANDA_ACCOUNT_ID=your-account-id
OANDA_ENV=PRACTICE    # or LIVE

# moomoo
MOOMOO_HOST=127.0.0.1
MOOMOO_PORT=11111
MOOMOO_TRD_ENV=SIMULATE   # or REAL
```

## 2. Webhook URL

!!! note "Webhook endpoint"
    Set the TradingView alert Webhook URL to:
    `http://<your-server>:8080/webhook`

## 3. Payload format

Use the following JSON in the TradingView alert message:

```json
{
  "passphrase": "your-secret-passphrase",
  "broker": "oanda",
  "asset_class": "FX",
  "action": "buy",
  "ticker": "USDJPY",
  "quantity": 1000
}
```

| Field | Description | Example |
|------|-------------|---------|
| `passphrase` | **Required** — Must match `WEBHOOK_PASSPHRASE` in `.env` | `"my-secret"` |
| `broker` | **Required** — Target broker | `"oanda"` / `"moomoo"` |
| `asset_class` | **Required** — Asset class | `"FX"` / `"COMMODITY"` / `"US"` / `"INDEX"` |
| `action` | **Required** — Order direction | `"buy"` / `"sell"` |
| `ticker` | **Required** — Symbol (TradingView notation) | `"USDJPY"` / `"XAUUSD"` |
| `quantity` | **Required** — Order size (positive number) | `1000` / `0.1` |

## 4. Ticker to OANDA instrument mapping

| asset_class | ticker | OANDA instrument |
|---|---|---|
| FX | USDJPY | USD_JPY |
| COMMODITY | XAUUSD | XAU_USD |
| INDEX | NAS100 | NAS100_USD |
| US | AAPL | AAPL_USD |

## 5. Verify connectivity

```bash
# Health check
curl http://localhost:8080/health
# → {"status":"ok"}

# Test order (use PRACTICE / SIMULATE environment)
curl -X POST http://localhost:8080/webhook \
  -H "Content-Type: application/json" \
  -d '{"passphrase":"your-secret","broker":"oanda","asset_class":"FX","action":"buy","ticker":"USDJPY","quantity":1000}'
```
```

### Step 8: `mkdocs.ja.yml` の nav に「ガイド」サブメニューを追加

Edit で以下の置換:

old_string:
```
  - 戦略テンプレート: templates.md
  - AI エージェント連携: ai-driven-forges.md
```

new_string:
```
  - 戦略テンプレート: templates.md
  - ガイド:
      - エンドツーエンド戦略開発ワークフロー: guides/end-to-end-workflow.md
      - TradingView への Pine Script 反映: guides/tradingview-pine-integration.md
      - TradingView と alpha-strike の連携: guides/tradingview-alpha-strike.md
  - AI エージェント連携: ai-driven-forges.md
```

### Step 9: `mkdocs.en.yml` の nav に "Guides" サブメニューを追加

Edit で以下の置換:

old_string:
```
  - Strategy Templates: templates.md
  - AI Agent Integration: ai-driven-forges.md
```

new_string:
```
  - Strategy Templates: templates.md
  - Guides:
      - End-to-End Strategy Development Workflow: guides/end-to-end-workflow.md
      - Bringing Pine Scripts into TradingView: guides/tradingview-pine-integration.md
      - TradingView × alpha-strike Integration: guides/tradingview-alpha-strike.md
  - AI Agent Integration: ai-driven-forges.md
```

### Step 10: 検証

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs && ls mkdocs_src/ja/guides/ mkdocs_src/en/guides/
```
期待: 各ディレクトリに 3 ファイル (end-to-end-workflow.md, tradingview-pine-integration.md, tradingview-alpha-strike.md) が存在。

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs && grep -c '^  - ガイド:\|^  - Guides:' mkdocs.ja.yml mkdocs.en.yml
```
期待: `mkdocs.ja.yml:1` と `mkdocs.en.yml:1`。

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs && grep -c 'guides/end-to-end-workflow\|guides/tradingview-pine-integration\|guides/tradingview-alpha-strike' mkdocs.ja.yml
```
期待: `3`

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs && grep -c 'guides/end-to-end-workflow\|guides/tradingview-pine-integration\|guides/tradingview-alpha-strike' mkdocs.en.yml
```
期待: `3`

各 md ファイル冒頭の h1 を確認:

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs && head -1 mkdocs_src/ja/guides/end-to-end-workflow.md
```
期待: `# エンドツーエンド戦略開発ワークフロー`

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs && head -1 mkdocs_src/en/guides/end-to-end-workflow.md
```
期待: `# End-to-End Strategy Development Workflow`

### Step 11: コミット 1

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs && git add mkdocs.ja.yml mkdocs.en.yml mkdocs_src/ja/guides/ mkdocs_src/en/guides/
git status
```
期待: 8 ファイル変更（mkdocs.{ja,en}.yml の 2 modified + 6 新規 md）。

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs && git commit -m "feat: 削除された 3 ガイドを MkDocs に移植

PR #82 (#65) の docs.html 簡素化で削除されたガイドコンテンツを
mkdocs_src/{ja,en}/guides/ に新規 md として再公開。

- エンドツーエンド戦略開発ワークフロー（6 ステップ）
- TradingView への Pine Script 反映（4 ステップ）
- TradingView と alpha-strike の連携（5 サブセクション）

旧コマンド名は現状の cli-reference に整合させて修正:
- forge backtest wft --folds → forge optimize walk-forward --windows
- forge optimize run の -j オプション削除（cli-reference に存在しないため）

mkdocs.{ja,en}.yml の nav に「ガイド」サブメニューを追加。
既存ページの URL は完全維持（ai-driven-forges.md など影響なし）。

Refs #83"
```

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs && git log --oneline -3
```
期待: 直近 2 コミット（spec / 本コミット）が確認できる。

---

## Task 2: mkdocs build を実行 → コミット 2（成果物）

### Step 1: ja サイトをビルド

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs && uv run mkdocs build -f mkdocs.ja.yml --clean
```
期待出力: ビルドが正常完了。`Documentation built in N.NN seconds` のような表示。エラーや warn が無いこと（特に「documentation file ... was not found」のリンク警告）。

### Step 2: en サイトをビルド

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs && uv run mkdocs build -f mkdocs.en.yml --clean
```
期待: 同様に正常完了。

### Step 3: 生成成果物の存在確認

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs && for lang in ja en; do
  for guide in end-to-end-workflow tradingview-pine-integration tradingview-alpha-strike; do
    test -f $lang/docs/guides/$guide/index.html && echo "OK $lang $guide" || echo "MISSING $lang $guide"
  done
done
```
期待: 6 行すべて `OK ...`。

### Step 4: 既存 URL の維持を確認

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs && for f in ja/docs/ai-driven-forges/index.html en/docs/ai-driven-forges/index.html ja/docs/cli-reference/index.html en/docs/cli-reference/index.html ja/docs/templates/index.html en/docs/templates/index.html; do
  test -f "$f" && echo "MAINTAINED $f" || echo "MISSING $f"
done
```
期待: 6 行すべて `MAINTAINED ...`。

### Step 5: nav に「ガイド」サブメニューが反映されていることを確認

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs && grep -c 'guides/end-to-end-workflow' ja/docs/index.html
```
期待: `1` 以上（nav HTML 内に少なくとも 1 リンク）。

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs && grep -c 'guides/end-to-end-workflow' en/docs/index.html
```
期待: `1` 以上。

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs && grep -c 'forge optimize walk-forward' ja/docs/guides/end-to-end-workflow/index.html
```
期待: `1`（コマンド修正反映確認）。

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs && grep -c '\\-j 4\|forge backtest wft' ja/docs/guides/end-to-end-workflow/index.html
```
期待: `0`（旧コマンドが残っていないこと）。

### Step 6: 副作用チェック（ビルド成果物以外への影響）

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs && git diff --stat ja/docs.html en/docs.html ja/install.html en/install.html ja/index.html en/index.html ja/privacy.html en/privacy.html ja/terms.html en/terms.html ja/tutorial-strategy.html en/tutorial-strategy.html robots.txt sitemap.xml templates/ seo.yaml page.css build.py
```
期待: 全部 `0` または出力なし。MkDocs ビルドは `ja/docs/` と `en/docs/` 配下のみを書き換えるため、build.py 由来の他のページに影響しないこと。

### Step 7: コミット 2

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs && git add ja/docs/ en/docs/ && git status
```
期待: ja/docs/ と en/docs/ 配下の追加・変更ファイル。3 ガイドの新規 index.html + nav 反映による既存ページ（templates / cli-reference / etc.）の HTML 再生成が含まれる。

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs && git commit -m "chore: MkDocs ビルド成果物を更新（ガイド 3 ページ追加）

mkdocs.{ja,en}.yml の nav 更新と guides/ 配下の新規 md 追加に伴う
ja/docs/ と en/docs/ 配下のビルド出力更新。

新規生成:
- {ja,en}/docs/guides/end-to-end-workflow/index.html
- {ja,en}/docs/guides/tradingview-pine-integration/index.html
- {ja,en}/docs/guides/tradingview-alpha-strike/index.html

既存ページの再生成は nav 変更による sidebar HTML の更新のみ。
URL や本文は変更されていない。

Refs #83"
```

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs && git log --oneline -5
```
期待: 直近 3 コミット（spec / feat / chore）が確認できる。

---

## Task 3: PR 作成

### Step 1: ローカル状態確認

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs && git status
```
期待: `On branch feat/docs-issue-83-guides-migration`、working tree clean。

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs && git log --oneline main..HEAD
```
期待: 3 コミット (spec `bcb83f6` / feat / chore) が確認できる。

### Step 2: リモートに push

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs && git push -u origin feat/docs-issue-83-guides-migration
```
期待: 新規ブランチが GitHub に push される。

### Step 3: PR 作成

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs && gh pr create --title "feat: 削除した 3 ガイドを MkDocs に移植 (#83)" --body "$(cat <<'EOF'
## Summary

- PR #82 (#65) で \`templates/docs.html.j2\` を簡素化した際に削除した 3 つのガイドコンテンツを MkDocs (\`mkdocs_src/{ja,en}/guides/\`) に新規ページとして移植
  - エンドツーエンド戦略開発ワークフロー（6 ステップ）
  - TradingView への Pine Script 反映（4 ステップ）
  - TradingView と alpha-strike の連携（5 サブセクション）
- \`mkdocs.{ja,en}.yml\` の nav に「ガイド」サブメニューを追加（戦略テンプレートと AI エージェント連携の間に配置）
- 旧コンテンツの古いコマンド名を現状の cli-reference に整合させて修正
  - \`forge backtest wft --folds\` → \`forge optimize walk-forward --windows\`
  - \`forge optimize run ... -j 4 --save\` から \`-j\` を削除（cli-reference に存在しないため）
- 既存ページ（ai-driven-forges、cli-reference、templates、legal）の URL は完全維持

## 設計ドキュメント

\`docs/superpowers/specs/2026-04-30-alforge-labs-issue-83-guides-migration-design.md\`

## 実装計画

\`docs/superpowers/plans/2026-04-30-alforge-labs-issue-83-guides-migration.md\`

## Test plan

- [x] \`uv run mkdocs build -f mkdocs.{ja,en}.yml --clean\` が警告なく完了
- [x] \`{ja,en}/docs/guides/{end-to-end-workflow,tradingview-pine-integration,tradingview-alpha-strike}/index.html\` の 6 ファイルすべて生成
- [x] nav に「ガイド」「Guides」サブメニューが反映
- [x] 既存ページ URL（ai-driven-forges, cli-reference, templates, legal）すべて維持
- [x] 旧コマンド (\`forge backtest wft\` / \`-j 4\`) が新ガイド md に残っていない
- [ ] 公開後ブラウザで /ja/docs/guides/end-to-end-workflow/ などを開いて表示・リンク動作確認

## スコープ外（フォローアップ）

- \`templates/docs.html.j2\` への変更なし（HTML ランディングは PR #82 の状態維持）
- \`seo.yaml\` の更新（issue #84 で別対応）

Closes #83
EOF
)"
```
期待: PR 番号と URL が表示される。

### Step 4: PR 状態確認

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs && gh pr view --json number,url,state,statusCheckRollup
```
期待: PR がオープン状態、status check は空 or success。

### Step 5: マージは実施しない

ユーザー承認待ち。`gh pr merge` は controller 側で実行する。

---

## Self-Review

### Spec coverage

| Spec 要件 | 対応タスク |
|---|---|
| ja Guide 1 (end-to-end-workflow) 作成 | Task 1 Step 2 |
| ja Guide 2 (tradingview-pine-integration) 作成 | Task 1 Step 3 |
| ja Guide 3 (tradingview-alpha-strike) 作成 | Task 1 Step 4 |
| en Guide 1 作成 | Task 1 Step 5 |
| en Guide 2 作成 | Task 1 Step 6 |
| en Guide 3 作成 | Task 1 Step 7 |
| mkdocs.ja.yml の nav 更新 | Task 1 Step 8 |
| mkdocs.en.yml の nav 更新 | Task 1 Step 9 |
| 旧コマンドの修正（wft → walk-forward, -j 削除） | Task 1 Step 2/Step 5 内、Task 2 Step 5 で検証 |
| mkdocs build で成果物再生成 | Task 2 Step 1-2 |
| 既存 URL 維持確認 | Task 2 Step 4 |
| 2 コミット粒度（feat / chore） | Task 1 Step 11 + Task 2 Step 7 |
| PR タイトル / Closes #83 | Task 3 Step 3 |

すべての spec 要件にタスクがマップされている。ギャップなし。

### Placeholder scan

- [x] "TBD" / "TODO" / "implement later" — なし
- [x] 6 つの md ファイル全文が完全に展開されている（Task 1 Step 2-7）
- [x] mkdocs.{ja,en}.yml の Edit old_string / new_string が完全展開
- [x] grep 検証コマンドはすべて期待値が具体値で書かれている
- [x] PR 本文 HEREDOC も実テキストで完成している

### Type / signature 一貫性

- [x] 6 つの md ファイル名が File Structure / nav 更新 / 検証コマンドで完全一致
- [x] 内部リンク (`tradingview-pine-integration.md` 等) が同ディレクトリの他ファイルを正しく参照
- [x] `../cli-reference/index.md` 相対リンクが MkDocs Material の標準ナビ構造に整合
- [x] コマンド例 (`forge optimize walk-forward --windows 5` など) が cli-reference の現行シグネチャと一致
- [x] `forge optimize apply ... --to-strategy ID` が cli-reference/optimize.md の現行シグネチャと一致
- [x] `forge pine generate --strategy ID` が cli-reference/other.md の現行シグネチャと一致
