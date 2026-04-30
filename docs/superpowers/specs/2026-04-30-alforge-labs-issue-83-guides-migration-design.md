# alforge-labs Issue #83 — 削除した 3 ガイドセクションを MkDocs に移植

## 目的

PR #82 (#65) で `templates/docs.html.j2` を簡素化した際に削除した 3 つのガイドコンテンツを、MkDocs (`mkdocs_src/{ja,en}/guides/`) に新規ページとして移植し、`alforgelabs.com/{ja,en}/docs/guides/...` で公開する。

## 背景

- 旧 `docs.html.j2`（リビジョン `3dffcfd`）には「エンドツーエンド戦略開発ワークフロー」「TradingView への Pine Script 反映」「TradingView と alpha-strike の連携」の 3 ガイドが埋め込まれていた。
- HTML ランディングを「主要 6 コマンドの早見表 + カタログ」に簡素化する方針 (#65) のため削除されたが、コンテンツ自体は有用なため別形式での再公開が必要。
- 旧テンプレ全文は `git show 3dffcfd:templates/docs.html.j2` で取得可能。

## 意図する成果

1. `https://alforgelabs.com/{ja,en}/docs/guides/end-to-end-workflow/` 等で 3 ガイドが閲覧可能。
2. MkDocs nav に「ガイド」サブメニューが追加され、3 ガイドへ視線誘導される。
3. 旧コンテンツの古いコマンド名（例: `forge backtest wft --folds`）は現状の cli-reference (`forge optimize walk-forward --windows`) に整合するよう修正される。
4. 既存ページ（`ai-driven-forges.md`、`cli-reference/`、`templates.md`）の URL は無変更（SEO 影響ゼロ）。

## スコープ確定事項（ブレインストーミングで決定）

| 論点 | 決定 |
|------|------|
| ページ分割 | **3 ページに分割**（end-to-end-workflow / tradingview-pine-integration / tradingview-alpha-strike） |
| nav 配置 | `戦略テンプレート` の直後、`AI エージェント連携` の直前に「ガイド」サブメニューを追加 |
| 既存ページの URL | **完全維持**（ai-driven-forges.md は移動しない） |
| コマンド例の不整合 | **現状の cli-reference に一致させて修正** |
| 実装アプローチ | mkdocs_src/{ja,en}/guides/ に新規 md 6 ファイル + mkdocs.{ja,en}.yml の nav 更新 |
| Markdown スタイル | 既存 cli-reference 配下の md パターンに揃える（admonition / 標準 table / pymdownx.superfences） |

## ディレクトリ構成

```
alforge-labs/
├── mkdocs.ja.yml                    # nav に「ガイド」サブメニュー追加
├── mkdocs.en.yml                    # nav に "Guides" サブメニュー追加
├── mkdocs_src/
│   ├── ja/
│   │   └── guides/                  # 新規ディレクトリ
│   │       ├── end-to-end-workflow.md
│   │       ├── tradingview-pine-integration.md
│   │       └── tradingview-alpha-strike.md
│   └── en/
│       └── guides/                  # 新規ディレクトリ
│           ├── end-to-end-workflow.md
│           ├── tradingview-pine-integration.md
│           └── tradingview-alpha-strike.md
├── ja/docs/guides/                  # mkdocs build 出力（git 管理、コミット）
│   ├── end-to-end-workflow/index.html
│   ├── tradingview-pine-integration/index.html
│   └── tradingview-alpha-strike/index.html
└── en/docs/guides/                  # 同上
```

## nav 変更

### mkdocs.ja.yml

```yaml
nav:
  - ホーム: index.md
  - はじめに: getting-started.md
  - CLI リファレンス:
      - 概要: cli-reference/index.md
      # ... (変更なし)
  - 戦略テンプレート: templates.md
  - ガイド:                                                       # 新規
      - エンドツーエンド戦略開発ワークフロー: guides/end-to-end-workflow.md
      - TradingView への Pine Script 反映: guides/tradingview-pine-integration.md
      - TradingView と alpha-strike の連携: guides/tradingview-alpha-strike.md
  - AI エージェント連携: ai-driven-forges.md
  - 利用規約と免責:
      # ... (変更なし)
```

### mkdocs.en.yml

```yaml
  - Strategy Templates: templates.md
  - Guides:                                                       # 新規
      - End-to-End Strategy Development Workflow: guides/end-to-end-workflow.md
      - Bringing Pine Scripts into TradingView: guides/tradingview-pine-integration.md
      - TradingView × alpha-strike Integration: guides/tradingview-alpha-strike.md
  - AI Agent Integration: ai-driven-forges.md
```

## 各ガイドの構成

### Guide 1: end-to-end-workflow.md

旧 docs.html.j2 line 371-443 (ja) / 対応する en セクションから移植 + コマンド修正。

- 冒頭の説明 + `!!! note "前提"` admonition（`alpha-strategies/` ディレクトリ + `FORGE_CONFIG=forge.yaml uv run` 前提）
- `## 1. データ取得` — `forge data fetch USDJPY`
- `## 2. 戦略テンプレート作成` — `forge strategy create --template ema_crossover ...` + `forge strategy save`
- `## 3. バックテスト実行` — `forge backtest run` + `forge backtest chart`
- `## 4. パラメータ最適化` — `forge optimize run --metric sharpe_ratio --trials 300 --save` + `forge optimize apply`
- `## 5. ウォークフォワード検証` — `forge optimize walk-forward --windows 5` + `forge optimize sensitivity`
- `## 6. Pine Script 生成` — `forge pine generate --strategy ID`
- 末尾に `!!! tip "関連コマンド"` で cli-reference へリンク

### Guide 2: tradingview-pine-integration.md

旧 docs.html.j2 line 448-488 から移植。

- 冒頭の説明
- `## 1. Pine エディタを開く`
- `## 2. スクリプトを貼り付ける`
- `## 3. アラートを設定する` — Webhook URL 入力、メッセージ JSON への言及
- `## 4. アラートメッセージのヒント` — `alertcondition` の Pine 例（` ```pinescript ` フェンス）
- 末尾に「次は alpha-strike 連携」のリンク（Guide 3 へ）

### Guide 3: tradingview-alpha-strike.md

旧 docs.html.j2 line 493-562 から移植。

- 冒頭の説明（alpha-strike が Webhook を受けて自動発注）
- `## 1. 環境変数の設定` — `.env` 例（OANDA / moomoo の必須変数）
- `## 2. Webhook URL` — `http://<your-server>:8080/webhook`（admonition で配置）
- `## 3. ペイロード仕様` — JSON 例 + Markdown テーブル（フィールド / 説明 / 値の例 / `**必須**` マーカー）
- `## 4. ティッカーと OANDA instrument の対応` — Markdown テーブル
- `## 5. 動作確認` — `curl http://localhost:8080/health` + テスト発注 curl 例

## コマンド例の修正（旧 → 新）

| 旧（docs.html.j2 にあった表記） | 新（cli-reference との整合） | 出現ガイド |
|---|---|---|
| `forge backtest wft USDJPY --strategy ID --folds 5` | `forge optimize walk-forward USDJPY --strategy ID --windows 5` | Guide 1 (Step 5) |
| `forge optimize run ... -j 4 --save` | `-j` は cli-reference にない場合は削除（実装時に grep で確認） | Guide 1 (Step 4) |
| `forge optimize apply data/results/...json --to-strategy ID` | cli-reference/optimize.md の現行シグネチャに整合（実装時確認） | Guide 1 (Step 4) |
| `forge optimize sensitivity USDJPY --strategy ID` | そのまま（cli-reference/optimize.md line 296 で確認済み） | Guide 1 (Step 5) |
| `forge pine generate --strategy ID` | cli-reference/other.md の現行シグネチャ確認後、必要なら修正 | Guide 1 (Step 6) |

実装フェーズ（writing-plans）で各サブコマンドの現行 cli-reference 内容を grep で確認し、コマンド例を確定する。

## Markdown スタイル方針

| 旧 HTML | Markdown 対応 |
|---|---|
| `<h2 class="section-heading">` | `##` |
| `<h3 class="sub-heading">` | `###` |
| `<div class="callout">` | `!!! note` / `!!! tip` / `!!! warning` admonition |
| `<ol class="step-list">` の番号付きステップ | `## N. タイトル` セクション分割（h2 で各ステップ表示） |
| `<table class="option-table">` / `<table class="payload-table">` | 標準 Markdown テーブル |
| `<span class="req">必須</span>` | テーブル内で説明文に `**必須**` を含める |
| `<pre><code>` | ` ```bash ` / ` ```json ` / ` ```pinescript ` 言語別フェンス |

既存の `cli-reference/data.md` `getting-started.md` のスタイルに揃える。フロントマターは使わない（既存 md と一貫）。

## 影響範囲（ファイル変更）

| ファイル | 変更タイプ |
|---|---|
| `mkdocs.ja.yml` | 編集（nav に「ガイド」サブメニュー 3 行追加） |
| `mkdocs.en.yml` | 編集（nav に "Guides" サブメニュー 3 行追加） |
| `mkdocs_src/ja/guides/end-to-end-workflow.md` | 新規 |
| `mkdocs_src/ja/guides/tradingview-pine-integration.md` | 新規 |
| `mkdocs_src/ja/guides/tradingview-alpha-strike.md` | 新規 |
| `mkdocs_src/en/guides/end-to-end-workflow.md` | 新規 |
| `mkdocs_src/en/guides/tradingview-pine-integration.md` | 新規 |
| `mkdocs_src/en/guides/tradingview-alpha-strike.md` | 新規 |
| `ja/docs/guides/*` | 新規（mkdocs build 出力） |
| `en/docs/guides/*` | 新規（mkdocs build 出力） |
| `templates/docs.html.j2` | **変更なし** |
| `ja/docs.html` / `en/docs.html` | **変更なし** |
| `seo.yaml` | **変更なし**（#84 で別対応） |
| `page.css` / `build.py` | **変更なし** |
| 既存 mkdocs_src の他のページ | **変更なし**（ai-driven-forges.md, templates.md, getting-started.md, cli-reference/*, legal/* 全部維持） |

## ビルド & 検証

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs

# 1. 各ガイド md を作成し、mkdocs.{ja,en}.yml に nav 追加

# 2. ビルド
uv run mkdocs build -f mkdocs.ja.yml --clean
uv run mkdocs build -f mkdocs.en.yml --clean

# 3. 生成確認
for lang in ja en; do
  for guide in end-to-end-workflow tradingview-pine-integration tradingview-alpha-strike; do
    test -f $lang/docs/guides/$guide/index.html && echo "OK $lang $guide" || echo "MISSING $lang $guide"
  done
done
# 期待: 6 行すべて OK

# 4. nav に「ガイド」セクションが含まれることを確認
grep -c 'guides/end-to-end-workflow' ja/docs/index.html
# 期待: 1 以上

# 5. 既存 URL 維持を確認
test -f ja/docs/ai-driven-forges/index.html && echo "ai-driven-forges 維持 OK"
test -f en/docs/ai-driven-forges/index.html && echo "ai-driven-forges (en) 維持 OK"
test -f ja/docs/cli-reference/index.html && echo "cli-reference 維持 OK"
test -f ja/docs/templates/index.html && echo "templates 維持 OK"
```

## ロールバック

すべて新規ファイル + nav への追加のみ。問題があれば:

```bash
git checkout main -- mkdocs.ja.yml mkdocs.en.yml
git rm -r mkdocs_src/ja/guides/ mkdocs_src/en/guides/ ja/docs/guides/ en/docs/guides/
```

または PR の squash commit を `git revert`。既存ページに副作用なし。

## コミット粒度

ブランチ名: `feat/docs-issue-83-guides-migration`

```
コミット 1: feat: 削除された 3 ガイドを MkDocs に移植
  対象: mkdocs.{ja,en}.yml, mkdocs_src/{ja,en}/guides/*.md (6 ファイル)

コミット 2: chore: MkDocs ビルド成果物を更新（ガイド 3 ページ追加）
  対象: ja/docs/, en/docs/ 配下のビルド出力（既存ページの再生成も含む）
```

## PR

- タイトル: `feat: 削除した 3 ガイドを MkDocs に移植 (#83)`
- 本文に `Closes #83` を含める
- マージ後: `gh pr merge <N> --squash --delete-branch`

## 受入条件チェック（issue #83 より転載）

- [x] 3 ガイドが MkDocs サイトに公開される（`/{ja,en}/docs/guides/...`）
- [x] nav に「ガイド」または同等の見出しでアクセスできる
- [x] 旧コンテンツの構造化データ（option-table、payload-table、step-list 相当）が Markdown で表現される
  - `<table class="option-table">` / `<table class="payload-table">` → 標準 Markdown table
  - `<ol class="step-list">` → `## N. タイトル` セクション分割
- [x] `mkdocs build` がエラーなく完了する

## 今回スコープ外

- `templates/docs.html.j2` への変更（HTML ランディングは PR #82 の状態維持）
- `seo.yaml` の更新（issue #84 で別対応中）
- 既存 ai-driven-forges.md の URL 変更（影響大のため避ける）
- 旧コンテンツに含まれない新しいガイドの追加（純粋な「移植」のみ）

## 関連 issue

- Parent: #65 (PR #82 でクローズ済み、本 issue はその follow-up)
- Sibling: #84 (seo.yaml docs エントリ更新、別 PR)
- Sibling: #78 (lang-content 並列構造の見直し、本 PR とは無関係)
- Sibling: #79 (React production build 切替、本 PR とは無関係)
