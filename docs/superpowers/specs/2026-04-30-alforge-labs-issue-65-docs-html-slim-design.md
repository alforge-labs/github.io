# alforge-labs Issue #65 — docs.html 簡素化と「カタログ + 主要 6 コマンド」再構成

## 目的

`{ja,en}/docs.html`（および Jinja2 テンプレート `templates/docs.html.j2`）を簡素化し、現状 1012 行の包括的コマンドリファレンスを「**ヒーロー + 主要 6 コマンドのカードグリッド + 全グループカタログ表 + cli-reference 誘導**」のページに再構成する。MkDocs `cli-reference/` を**正本（source of truth）** とし、HTML ランディングは「サブコマンド早見表」として最短到達を担う。

## 背景

- #49〜#72 で MkDocs 側の `cli-reference/` を「全コマンドカタログ + 7 サブページ（76 サブコマンドの完全詳細）」として整備済み（コミット `3043fbf`〜`a50fe1a`）。
- 現状の `docs.html` は左サイドバー目次 + `forge data/strategy/backtest/optimize/pine/dashboard/license` の 7 セクション + 「ワークフロー」「TradingView 反映」「alpha-strike 連携」の 3 ガイドセクションで構成され、1012 行に及ぶ。
- #56 (install.html 簡素化) と同じく MkDocs を正本にする方針で、HTML ランディングは「最短到達」「SEO 維持」が役割。

## スコープ確定事項（ブレインストーミングで決定）

| 論点 | 決定 |
|------|------|
| 3 ガイドセクション（workflow / tradingview / strike） | **すべて削除**、将来 MkDocs に移植する別 issue を登録 |
| 主要 6 コマンドの記述構造 | **ダッシュボード風カードグリッド**（CSS Grid 3 列、auto-fit） |
| その他コマンドのカタログ | cli-reference の MkDocs グループページに対応する **7 行の表**（backtest/optimize/strategy/data/journal/live/その他） |
| 左サイドバー（cmd-nav） | **削除**（簡素化後の section 数が少ないため不要） |
| Docs 誘導の配置 | **ヒーロー直下とカタログ表のあとの 2 箇所** |
| 実装アプローチ | `templates/docs.html.j2` を **ゼロから書き直し**（既存テンプレ上下の SEO/メタ/ヘッダー/フッター部分はコピーで保護） |
| 新規 CSS | `templates/docs.html.j2` 内の `<style>` ブロックに `.cmd-card-grid` / `.cmd-card` 関連のローカル CSS を追加（page.css は無変更） |

## ページ構造（簡素化後）

```
1. ヒーロー
   - page-label: "Documentation"
   - h1: "forge コマンドの早見表" / "forge Command Quick Reference"
   - subtitle: 「主要 6 コマンドのカードと全コマンドカタログ。詳細は公式ドキュメントへ」

2. Docs 誘導 callout（上）— 新規
   - .callout + .btn-primary
   - href="/ja/docs/cli-reference/" / "/en/docs/cli-reference/"

3. 主要 6 コマンドのカードグリッド
   - h2: "主要コマンド" / "Top Commands"
   - .cmd-card-grid（CSS Grid: repeat(auto-fit, minmax(280px, 1fr))）
   - 6 カード:
     a. forge backtest run
     b. forge optimize run
     c. forge optimize walk-forward
     d. forge data fetch
     e. forge strategy save
     f. forge journal show
   - 各カードは <a> タグ（全体クリック可能）、cli-reference のサブコマンドアンカーへリンク

4. 全コマンドカタログ
   - h2: "全コマンドカタログ" / "All Command Groups"
   - .cmd-table（既存スタイル流用）
   - 7 行: backtest(11) / optimize(9) / strategy(7) / data(4) / journal(7) / live(9) / その他 (10 グループ)
   - グループ名のセルは cli-reference の各ページへリンク

5. Docs 誘導 callout（下）— 新規
   - 「全 76 サブコマンドの完全詳細はドキュメントへ」

6. サポートメール callout（既存維持）
   - support@alforgelabs.com
```

### 削除されるセクション（現状約 700+ 行を削除）

| セクション | 削除理由 | MkDocs での代替 |
|---|---|---|
| 左サイドバー `<aside class="cmd-nav">` + 関連 `<style>` (~50 行) | 簡素化後の section 数が少なく不要 | （MkDocs Material のサイドバー） |
| `forge data` 既存セクション (line 158-187) | 主要 fetch のみカード化、他は MkDocs cli-reference/data/ へ | `mkdocs_src/{ja,en}/cli-reference/data.md` |
| `forge strategy` 既存セクション (line 192-220) | 同上、save のみカード化 | `cli-reference/strategy.md` |
| `forge backtest` 既存セクション (line 225-268) | 同上、run のみカード化 | `cli-reference/backtest.md` |
| `forge optimize` 既存セクション (line 273-305) | 同上、run/walk-forward のみカード化 | `cli-reference/optimize.md` |
| `forge pine` セクション (line 310-340) | カタログ表で参照 | `cli-reference/other.md` |
| `forge dashboard` セクション (line 345-351) | カタログ表で参照 | `cli-reference/other.md` |
| `forge license` セクション (line 353-366) | カタログ表で参照 | `cli-reference/other.md` |
| 「エンドツーエンド戦略開発ワークフロー」セクション (line 371-443) | 別 issue で MkDocs に移植予定 | （未） |
| 「TradingView への Pine Script 反映」セクション (line 448-488) | 別 issue で MkDocs に移植予定 | （未） |
| 「TradingView と alpha-strike の連携」セクション (line 493-562) | 別 issue で MkDocs に移植予定 | （未） |
| 関連 CSS（`.doc-layout`, `.option-table`, `.payload-table`, `.step-list` 関連 ~80 行） | 削除セクション専用スタイル | （不要） |

### 維持されるセクション（変更なし）

- Jinja2 テンプレ上部（meta タグ・JSON-LD・hreflang・preconnect・theme 初期化スクリプト）
- ヘッダー（`<div id="site-header"></div>` + `site-header.jsx`）
- フッター（言語別リンク）
- React/Babel スクリプトロード

## HTML スニペット

### ヒーロー

**ja**:
```html
<div class="page-label">Documentation</div>
<h1 class="page-title">forge コマンドの早見表</h1>
<p class="page-subtitle">主要 6 コマンドのカードと全コマンドカタログ。詳細パラメータと出力例は公式ドキュメントへ。</p>
```

**en**:
```html
<div class="page-label">Documentation</div>
<h1 class="page-title">forge Command Quick Reference</h1>
<p class="page-subtitle">Cards for the six core commands plus a full command catalog. Detailed parameters and output examples live in the official docs.</p>
```

### Docs 誘導 callout（上、ヒーロー直下）

**ja**:
```html
<div class="callout" style="margin-bottom: 2rem;">
  <p style="margin-bottom: 0.75rem;">
    全 76 サブコマンドの詳細パラメータ、出力例、エラーコードは
    <strong>公式ドキュメント</strong>を参照してください。
  </p>
  <a href="/ja/docs/cli-reference/" class="btn-primary">
    CLI リファレンスを開く →
  </a>
</div>
```

**en**:
```html
<div class="callout" style="margin-bottom: 2rem;">
  <p style="margin-bottom: 0.75rem;">
    For detailed parameters, output examples, and error codes for all 76 subcommands,
    see the <strong>official documentation</strong>.
  </p>
  <a href="/en/docs/cli-reference/" class="btn-primary">
    Open CLI Reference →
  </a>
</div>
```

### Docs 誘導 callout（下、カタログ表のあと）

**ja**:
```html
<div class="callout" style="margin-top: 2rem;">
  <p style="margin-bottom: 0.75rem;">
    各グループの完全なサブコマンドリスト、オプション一覧、戻り値、サンプル出力は
    ドキュメントの CLI リファレンスを参照してください。
  </p>
  <a href="/ja/docs/cli-reference/" class="btn-primary">
    CLI リファレンスを開く →
  </a>
</div>
```

**en**:
```html
<div class="callout" style="margin-top: 2rem;">
  <p style="margin-bottom: 0.75rem;">
    For complete subcommand listings, options, return values, and sample output for each group,
    see the CLI Reference in the official docs.
  </p>
  <a href="/en/docs/cli-reference/" class="btn-primary">
    Open CLI Reference →
  </a>
</div>
```

### カードグリッド用 CSS（`templates/docs.html.j2` 内 `<style>` に追加）

```css
/* ── CARD GRID ── */
.cmd-card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 1rem;
  margin: 1.5rem 0 2.5rem;
}
.cmd-card {
  display: block;
  padding: 1.25rem;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--r);
  text-decoration: none;
  transition: border-color 0.15s, transform 0.15s;
}
.cmd-card:hover {
  border-color: var(--accent);
  transform: translateY(-2px);
  text-decoration: none;
}
.cmd-card-name {
  font-family: var(--mono);
  font-size: 0.95rem;
  font-weight: 600;
  color: var(--accent);
  margin-bottom: 0.4rem;
}
.cmd-card-desc { font-size: 0.85rem; color: var(--text2); margin-bottom: 0.75rem; }
.cmd-card-usage {
  background: var(--bg2);
  padding: 0.5rem 0.75rem;
  border-radius: 4px;
  font-family: var(--mono);
  font-size: 0.78rem;
  color: var(--text);
  margin: 0 0 0.75rem;
  overflow-x: auto;
}
.cmd-card-options { display: flex; flex-wrap: wrap; gap: 0.4rem; margin-bottom: 0.75rem; }
.cmd-card-option {
  font-family: var(--mono); font-size: 0.72rem;
  padding: 0.2rem 0.5rem;
  background: var(--accent-bg); color: var(--accent);
  border-radius: 4px;
}
.cmd-card-link {
  font-size: 0.78rem;
  color: var(--text3);
  font-family: var(--mono);
}
.cmd-card:hover .cmd-card-link { color: var(--accent); }
```

### 6 カードのコンテンツ（ja の例、en は文言のみ差替）

#### Card 1: forge backtest run

```html
<a class="cmd-card" href="/ja/docs/cli-reference/backtest/#forge-backtest-run">
  <div class="cmd-card-name">forge backtest run</div>
  <div class="cmd-card-desc">単一銘柄に戦略を適用してバックテストを実行する。</div>
  <pre class="cmd-card-usage"><code>forge backtest run SYMBOL --strategy ID</code></pre>
  <div class="cmd-card-options">
    <span class="cmd-card-option">--strategy</span>
    <span class="cmd-card-option">--start</span>
    <span class="cmd-card-option">--json</span>
  </div>
  <div class="cmd-card-link">cli-reference で詳細 →</div>
</a>
```

#### Card 2: forge optimize run

```html
<a class="cmd-card" href="/ja/docs/cli-reference/optimize/#forge-optimize-run">
  <div class="cmd-card-name">forge optimize run</div>
  <div class="cmd-card-desc">Optuna によるパラメータ最適化（TPE）。多目的最適化にも対応。</div>
  <pre class="cmd-card-usage"><code>forge optimize run SYMBOL --strategy ID</code></pre>
  <div class="cmd-card-options">
    <span class="cmd-card-option">--metric</span>
    <span class="cmd-card-option">--trials</span>
    <span class="cmd-card-option">--apply</span>
  </div>
  <div class="cmd-card-link">cli-reference で詳細 →</div>
</a>
```

#### Card 3: forge optimize walk-forward

```html
<a class="cmd-card" href="/ja/docs/cli-reference/optimize/#forge-optimize-walk-forward">
  <div class="cmd-card-name">forge optimize walk-forward</div>
  <div class="cmd-card-desc">時系列をウィンドウ分割し IS 最適化 → OOS 評価で過学習耐性を測定。</div>
  <pre class="cmd-card-usage"><code>forge optimize walk-forward SYMBOL --strategy ID --windows N</code></pre>
  <div class="cmd-card-options">
    <span class="cmd-card-option">--windows</span>
    <span class="cmd-card-option">--metric</span>
  </div>
  <div class="cmd-card-link">cli-reference で詳細 →</div>
</a>
```

#### Card 4: forge data fetch

```html
<a class="cmd-card" href="/ja/docs/cli-reference/data/#forge-data-fetch">
  <div class="cmd-card-name">forge data fetch</div>
  <div class="cmd-card-desc">OHLCV をプロバイダーから取得し Parquet で保存。</div>
  <pre class="cmd-card-usage"><code>forge data fetch SYMBOL --period 5y --interval 1d</code></pre>
  <div class="cmd-card-options">
    <span class="cmd-card-option">--period</span>
    <span class="cmd-card-option">--interval</span>
    <span class="cmd-card-option">--watchlist</span>
  </div>
  <div class="cmd-card-link">cli-reference で詳細 →</div>
</a>
```

#### Card 5: forge strategy save

```html
<a class="cmd-card" href="/ja/docs/cli-reference/strategy/#forge-strategy-save">
  <div class="cmd-card-name">forge strategy save</div>
  <div class="cmd-card-desc">戦略 JSON をレジストリに登録（任意で Journal に記録）。</div>
  <pre class="cmd-card-usage"><code>forge strategy save FILE_PATH</code></pre>
  <div class="cmd-card-options">
    <span class="cmd-card-option">--force</span>
  </div>
  <div class="cmd-card-link">cli-reference で詳細 →</div>
</a>
```

#### Card 6: forge journal show

```html
<a class="cmd-card" href="/ja/docs/cli-reference/journal/#forge-journal-show">
  <div class="cmd-card-name">forge journal show</div>
  <div class="cmd-card-desc">戦略の全履歴（スナップショット・Runs・タグ・ライブサマリ）を表示。</div>
  <pre class="cmd-card-usage"><code>forge journal show STRATEGY_ID</code></pre>
  <div class="cmd-card-link">cli-reference で詳細 →</div>
</a>
```

`forge journal show` は引数のみのため `.cmd-card-options` ブロックを省略。

### 全コマンドカタログ表（ja）

```html
<h2 class="section-heading">全コマンドカタログ</h2>
<table class="cmd-table">
  <thead>
    <tr><th>グループ</th><th>説明</th><th>サブコマンド数</th></tr>
  </thead>
  <tbody>
    <tr>
      <td><a href="/ja/docs/cli-reference/backtest/"><code>forge backtest</code></a></td>
      <td>バックテスト実行・スキャン・カスタム実験</td>
      <td>11</td>
    </tr>
    <tr>
      <td><a href="/ja/docs/cli-reference/optimize/"><code>forge optimize</code></a></td>
      <td>パラメータ最適化（grid / bayes / wfa）</td>
      <td>9</td>
    </tr>
    <tr>
      <td><a href="/ja/docs/cli-reference/strategy/"><code>forge strategy</code></a></td>
      <td>戦略 JSON の保存・検証・適用</td>
      <td>7</td>
    </tr>
    <tr>
      <td><a href="/ja/docs/cli-reference/data/"><code>forge data</code></a></td>
      <td>ヒストリカルデータ取得・更新</td>
      <td>4</td>
    </tr>
    <tr>
      <td><a href="/ja/docs/cli-reference/journal/"><code>forge journal</code></a></td>
      <td>取引ジャーナル・トレード分析</td>
      <td>7</td>
    </tr>
    <tr>
      <td><a href="/ja/docs/cli-reference/live/"><code>forge live</code></a></td>
      <td>ライブトレーディング・ブローカー連携</td>
      <td>9</td>
    </tr>
    <tr>
      <td><a href="/ja/docs/cli-reference/other/">その他コマンド</a></td>
      <td><code>pine</code> / <code>dashboard</code> / <code>license</code> / <code>config</code> 他</td>
      <td>10 グループ</td>
    </tr>
  </tbody>
</table>
```

### 全コマンドカタログ表（en）

```html
<h2 class="section-heading">All Command Groups</h2>
<table class="cmd-table">
  <thead>
    <tr><th>Group</th><th>Description</th><th>Subcommands</th></tr>
  </thead>
  <tbody>
    <tr>
      <td><a href="/en/docs/cli-reference/backtest/"><code>forge backtest</code></a></td>
      <td>Backtest execution, scanning, custom experiments</td>
      <td>11</td>
    </tr>
    <tr>
      <td><a href="/en/docs/cli-reference/optimize/"><code>forge optimize</code></a></td>
      <td>Parameter optimization (grid / bayes / wfa)</td>
      <td>9</td>
    </tr>
    <tr>
      <td><a href="/en/docs/cli-reference/strategy/"><code>forge strategy</code></a></td>
      <td>Strategy JSON save / validate / apply</td>
      <td>7</td>
    </tr>
    <tr>
      <td><a href="/en/docs/cli-reference/data/"><code>forge data</code></a></td>
      <td>Historical data fetch / update</td>
      <td>4</td>
    </tr>
    <tr>
      <td><a href="/en/docs/cli-reference/journal/"><code>forge journal</code></a></td>
      <td>Trading journal and trade analysis</td>
      <td>7</td>
    </tr>
    <tr>
      <td><a href="/en/docs/cli-reference/live/"><code>forge live</code></a></td>
      <td>Live trading and broker integration</td>
      <td>9</td>
    </tr>
    <tr>
      <td><a href="/en/docs/cli-reference/other/">Other commands</a></td>
      <td><code>pine</code> / <code>dashboard</code> / <code>license</code> / <code>config</code> and more</td>
      <td>10 groups</td>
    </tr>
  </tbody>
</table>
```

## MkDocs アンカー検証

カードの href（`/ja/docs/cli-reference/backtest/#forge-backtest-run` など）が実際の MkDocs ビルド成果物に存在することを実装フェーズで grep 検証する。MkDocs Material は `## forge backtest run` 見出しに対して `id="forge-backtest-run"` を pymdownx.toc で自動生成する規約。

検証コマンド例:
```bash
grep -c 'id="forge-backtest-run"' ja/docs/cli-reference/backtest/index.html
# 期待: 1

grep -c 'id="forge-optimize-walk-forward"' ja/docs/cli-reference/optimize/index.html
# 期待: 1
```

## 影響範囲（ファイル変更）

| ファイル | 変更内容 |
|---|---|
| `templates/docs.html.j2` | 全書き直し（簡素化、構造刷新） |
| `ja/docs.html` | `uv run python build.py` で再生成 |
| `en/docs.html` | `uv run python build.py` で再生成 |
| `seo.yaml` | **変更なし**（docs ページの title/description/keywords は依然正確） |
| `sitemap.xml` | **変更なし**（priority 0.9 / changefreq weekly 維持） |
| `robots.txt` | **変更なし** |
| `page.css` | **変更なし**（カードグリッド CSS は `templates/docs.html.j2` 内の `<style>` ブロックに局所追加） |
| MkDocs 関連 | **一切変更なし** |

## ビルド & 検証

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs

# 1. テンプレ書き直し後にビルド
uv run python build.py

# 2. 差分確認
git diff --stat templates/docs.html.j2 ja/docs.html en/docs.html

# 3. ビルド成果物の構造検証
grep -c 'cmd-card' ja/docs.html  # 期待: 6 カード × 2 言語 = 多数（カードクラス使用箇所）
grep -c 'btn-primary' ja/docs.html  # 期待: 4（上下 callout × ja/en）
grep -c '/ja/docs/cli-reference/' ja/docs.html  # ja セクション内のリンク総数を確認
grep -c 'forge コマンドの早見表' ja/docs.html  # 期待: 1
grep -c 'forge Command Quick Reference' en/docs.html  # 期待: 1
grep -c 'cmd-nav-list' ja/docs.html  # 期待: 0（左サイドバー削除）
grep -c '"@context"' ja/docs.html  # 期待: 1（JSON-LD 維持）
grep -c 'hreflang=' ja/docs.html  # 期待: 3

# 4. 副作用チェック
git diff --stat ja/ en/ robots.txt sitemap.xml
# 期待: docs.html のみ変更、他ページ・robots/sitemap は無差分

# 5. MkDocs アンカー存在確認
grep -c 'id="forge-backtest-run"' ja/docs/cli-reference/backtest/index.html  # 期待: 1
grep -c 'id="forge-optimize-run"' ja/docs/cli-reference/optimize/index.html  # 期待: 1
grep -c 'id="forge-optimize-walk-forward"' ja/docs/cli-reference/optimize/index.html  # 期待: 1
grep -c 'id="forge-data-fetch"' ja/docs/cli-reference/data/index.html  # 期待: 1
grep -c 'id="forge-strategy-save"' ja/docs/cli-reference/strategy/index.html  # 期待: 1
grep -c 'id="forge-journal-show"' ja/docs/cli-reference/journal/index.html  # 期待: 1

# 6. ローカルブラウザ確認
open ja/docs.html
# 検証: ヒーロー / Docs 誘導 callout（上）/ 6 カード（クリックで cli-reference に飛ぶ） /
#       全グループカタログ表 / Docs 誘導 callout（下）/ Support callout
open en/docs.html
# 同等を英語版で確認
```

## ロールバック

すべて新規ブランチ上の変更でコミットされる:

```bash
git checkout main -- templates/docs.html.j2 ja/docs.html en/docs.html
```

または PR の squash commit を revert。MkDocs 関連ファイルには一切触らないため副作用なし。

## コミット粒度

ブランチ名: `feat/docs-issue-65-docs-html-slim`

```
コミット 1: feat: docs.html を「カタログ + 主要 6 コマンド」に再構成
  対象: templates/docs.html.j2

コミット 2: chore: docs.html の build.py 出力を再生成
  対象: ja/docs.html, en/docs.html
```

## PR

- タイトル: `feat: docs.html を「カタログ + 主要 6 コマンド」に再構成 (#65)`
- 本文に `Closes #65` を含める
- マージ後: `gh pr merge <N> --squash --delete-branch`

## 受入条件チェック（issue #65 より転載）

- [x] `/ja/docs.html` と `/en/docs.html` がスクロールせずに主要情報が読める短さに圧縮されている
  - 1012 行 → 推定 350-400 行（主要 6 カード + 7 行表 + ヘッダー/フッター/SEO ブロック）
- [x] `/ja/docs/cli-reference/` への目立つ導線がある
  - ヒーロー直下の上部 callout、カタログ表後の下部 callout、各カードのクリック、各カタログ表行のリンク = 多数の導線
- [x] `templates/docs.html.j2` の Jinja2 テンプレートも更新されている
  - 正本としてテンプレを書き直し、`build.py` でビルド成果物を再生成
- [x] 既存 SEO（seo.yaml、メタタグ、構造化データ）に大きな悪影響がない
  - seo.yaml 無変更、JSON-LD は build.py で動的生成され構造変更なし、hreflang 維持

## 今回スコープ外

- ガイドコンテンツ（「エンドツーエンド戦略開発ワークフロー」「TradingView への Pine Script 反映」「TradingView と alpha-strike の連携」）の MkDocs への移植 → 別 issue として登録予定
- `templates/docs.html.j2` の lang 並列構造（`lang-content lang-ja` / `lang-content lang-en`）の見直し → 別 issue (#78) で扱う
- React/React-DOM の production build 切り替え → 別 issue (#79) で扱う
- platform-tabs アクセシビリティ → docs.html ではタブを使用しないため該当なし
