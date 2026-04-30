# docs.html 簡素化と「カタログ + 主要 6 コマンド」再構成 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `templates/docs.html.j2`（現状 1012 行）を「ヒーロー + 主要 6 コマンドカードグリッド + 全グループカタログ表 + cli-reference 誘導」のページに再構成し、`{ja,en}/docs.html` を再生成する。

**Architecture:** Jinja2 テンプレート (`templates/docs.html.j2`) を `Write` で完全置換 → `uv run python build.py` で `ja/docs.html` と `en/docs.html` を再生成 → 2 コミット → PR 作成。新規 CSS（カードグリッド用）はテンプレ内 `<style>` ブロックに局所追加、`page.css` は無変更。MkDocs `cli-reference/` への各サブコマンドアンカー (`#forge-{group}-{sub}`) リンクが正常に機能するか実装フェーズで検証する。

**Tech Stack:** Jinja2, Python 3 (build.py with PyYAML), 静的 HTML/CSS, GitHub Pages, gh CLI, MkDocs Material（既存ビルド済み）

**作業ブランチ:** `feat/docs-issue-65-docs-html-slim`（spec コミット `6329bf8` で作成済み）

**Spec:** `docs/superpowers/specs/2026-04-30-alforge-labs-issue-65-docs-html-slim-design.md`

---

## File Structure

| ファイル | 責務 | 変更タイプ |
|---|---|---|
| `templates/docs.html.j2` | Jinja2 テンプレート（正本） | **完全書き直し（Write）** |
| `ja/docs.html` | build.py 出力 | 再生成（コミット） |
| `en/docs.html` | build.py 出力 | 再生成（コミット） |
| `seo.yaml` | SEO メタデータ | 変更なし |
| `page.css` | グローバルスタイル | 変更なし |
| `build.py` | ビルドスクリプト | 変更なし |
| `mkdocs_src/`, `{ja,en}/docs/` | MkDocs 関連 | **一切変更なし** |

---

## Task 1: `templates/docs.html.j2` を新構造で完全書き直し

**Files:**
- Modify: `templates/docs.html.j2`（既存 1012 行を完全置換、推定 ~310 行へ）

- [ ] **Step 1: 既存テンプレートの上下保持部分を確認**

```bash
sed -n '1,25p' templates/docs.html.j2  # head: meta タグ群（保持）
sed -n '108,122p' templates/docs.html.j2  # theme スクリプト + body 開始（保持）
sed -n '998,1012p' templates/docs.html.j2  # footer + React/Babel scripts（保持）
```

期待: meta タグ・JSON-LD・hreflang（line 1-25）、theme 初期化スクリプト（line 108-119）、body 開始 + site-header div（line 121-122）、footer（line 998-1002）、React/Babel scripts（line 1004-1010）が確認できる。これらは新テンプレートでも保持する。

- [ ] **Step 2: `templates/docs.html.j2` を Write で完全置換**

ファイル全文を以下の内容で上書きする:

```html
<!DOCTYPE html>
<html lang="{{ lang }}">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>{{ title }}</title>
  <meta name="description" content="{{ description }}" />
  <meta name="keywords" content="{{ keywords }}" />
  <link rel="canonical" href="{{ canonical_url }}" />
  <link rel="alternate" hreflang="ja" href="{{ hreflang_ja }}" />
  <link rel="alternate" hreflang="en" href="{{ hreflang_en }}" />
  <link rel="alternate" hreflang="x-default" href="https://alforgelabs.com/" />
  <meta property="og:url" content="{{ canonical_url }}" />
  <meta property="og:image" content="{{ og_image }}" />
  <meta property="og:locale" content="{{ og_locale }}" />
  <meta property="og:site_name" content="Alforge Labs" />
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:site" content="{{ twitter_site }}" />
  <meta name="twitter:title" content="{{ og_title }}" />
  <meta name="twitter:description" content="{{ og_description }}" />
  <meta name="twitter:image" content="{{ og_image }}" />
  <script type="application/ld+json">{{ json_ld }}</script>
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet" />
  <link rel="stylesheet" href="../page.css" />
  <style>
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
  </style>
  <script>
    (function() {
      var t = localStorage.getItem('al_theme') || 'dark';
      var l = localStorage.getItem('al_lang') || '{{ lang }}';
      document.documentElement.setAttribute('data-theme', t);
      document.documentElement.setAttribute('lang', l);
      document.addEventListener('DOMContentLoaded', function() {
        document.body.setAttribute('data-theme', t);
        document.body.setAttribute('data-lang', l);
      });
    })();
  </script>
</head>
<body data-theme="dark" data-lang="{{ lang }}">
  <div id="site-header"></div>

  <div class="page-wrap">

    <!-- ==================== 日本語版 ==================== -->
    <div class="lang-content lang-ja">
      <div class="page-label">Documentation</div>
      <h1 class="page-title">forge コマンドの早見表</h1>
      <p class="page-subtitle">主要 6 コマンドのカードと全コマンドカタログ。詳細パラメータと出力例は公式ドキュメントへ。</p>

      <div class="callout" style="margin-bottom: 2rem;">
        <p style="margin-bottom: 0.75rem;">
          全 76 サブコマンドの詳細パラメータ、出力例、エラーコードは
          <strong>公式ドキュメント</strong>を参照してください。
        </p>
        <a href="/ja/docs/cli-reference/" class="btn-primary">
          CLI リファレンスを開く →
        </a>
      </div>

      <h2 class="section-heading">主要コマンド</h2>
      <div class="cmd-card-grid">
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

        <a class="cmd-card" href="/ja/docs/cli-reference/strategy/#forge-strategy-save">
          <div class="cmd-card-name">forge strategy save</div>
          <div class="cmd-card-desc">戦略 JSON をレジストリに登録（任意で Journal に記録）。</div>
          <pre class="cmd-card-usage"><code>forge strategy save FILE_PATH</code></pre>
          <div class="cmd-card-options">
            <span class="cmd-card-option">--force</span>
          </div>
          <div class="cmd-card-link">cli-reference で詳細 →</div>
        </a>

        <a class="cmd-card" href="/ja/docs/cli-reference/journal/#forge-journal-show">
          <div class="cmd-card-name">forge journal show</div>
          <div class="cmd-card-desc">戦略の全履歴（スナップショット・Runs・タグ・ライブサマリ）を表示。</div>
          <pre class="cmd-card-usage"><code>forge journal show STRATEGY_ID</code></pre>
          <div class="cmd-card-link">cli-reference で詳細 →</div>
        </a>
      </div>

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

      <div class="callout" style="margin-top: 2rem;">
        <p style="margin-bottom: 0.75rem;">
          各グループの完全なサブコマンドリスト、オプション一覧、戻り値、サンプル出力は
          ドキュメントの CLI リファレンスを参照してください。
        </p>
        <a href="/ja/docs/cli-reference/" class="btn-primary">
          CLI リファレンスを開く →
        </a>
      </div>

      <div class="callout" style="margin-top: 1rem;">
        <p>サポートが必要な場合は <a href="mailto:support@alforgelabs.com">support@alforgelabs.com</a> までお問い合わせください。</p>
      </div>
    </div>

    <!-- ==================== English ==================== -->
    <div class="lang-content lang-en">
      <div class="page-label">Documentation</div>
      <h1 class="page-title">forge Command Quick Reference</h1>
      <p class="page-subtitle">Cards for the six core commands plus a full command catalog. Detailed parameters and output examples live in the official docs.</p>

      <div class="callout" style="margin-bottom: 2rem;">
        <p style="margin-bottom: 0.75rem;">
          For detailed parameters, output examples, and error codes for all 76 subcommands,
          see the <strong>official documentation</strong>.
        </p>
        <a href="/en/docs/cli-reference/" class="btn-primary">
          Open CLI Reference →
        </a>
      </div>

      <h2 class="section-heading">Top Commands</h2>
      <div class="cmd-card-grid">
        <a class="cmd-card" href="/en/docs/cli-reference/backtest/#forge-backtest-run">
          <div class="cmd-card-name">forge backtest run</div>
          <div class="cmd-card-desc">Run a backtest applying a strategy to a single symbol.</div>
          <pre class="cmd-card-usage"><code>forge backtest run SYMBOL --strategy ID</code></pre>
          <div class="cmd-card-options">
            <span class="cmd-card-option">--strategy</span>
            <span class="cmd-card-option">--start</span>
            <span class="cmd-card-option">--json</span>
          </div>
          <div class="cmd-card-link">See cli-reference →</div>
        </a>

        <a class="cmd-card" href="/en/docs/cli-reference/optimize/#forge-optimize-run">
          <div class="cmd-card-name">forge optimize run</div>
          <div class="cmd-card-desc">Parameter optimization with Optuna (TPE). Multi-objective also supported.</div>
          <pre class="cmd-card-usage"><code>forge optimize run SYMBOL --strategy ID</code></pre>
          <div class="cmd-card-options">
            <span class="cmd-card-option">--metric</span>
            <span class="cmd-card-option">--trials</span>
            <span class="cmd-card-option">--apply</span>
          </div>
          <div class="cmd-card-link">See cli-reference →</div>
        </a>

        <a class="cmd-card" href="/en/docs/cli-reference/optimize/#forge-optimize-walk-forward">
          <div class="cmd-card-name">forge optimize walk-forward</div>
          <div class="cmd-card-desc">Split time series into windows; IS optimization → OOS evaluation for overfitting resistance.</div>
          <pre class="cmd-card-usage"><code>forge optimize walk-forward SYMBOL --strategy ID --windows N</code></pre>
          <div class="cmd-card-options">
            <span class="cmd-card-option">--windows</span>
            <span class="cmd-card-option">--metric</span>
          </div>
          <div class="cmd-card-link">See cli-reference →</div>
        </a>

        <a class="cmd-card" href="/en/docs/cli-reference/data/#forge-data-fetch">
          <div class="cmd-card-name">forge data fetch</div>
          <div class="cmd-card-desc">Fetch OHLCV from a provider and store as Parquet.</div>
          <pre class="cmd-card-usage"><code>forge data fetch SYMBOL --period 5y --interval 1d</code></pre>
          <div class="cmd-card-options">
            <span class="cmd-card-option">--period</span>
            <span class="cmd-card-option">--interval</span>
            <span class="cmd-card-option">--watchlist</span>
          </div>
          <div class="cmd-card-link">See cli-reference →</div>
        </a>

        <a class="cmd-card" href="/en/docs/cli-reference/strategy/#forge-strategy-save">
          <div class="cmd-card-name">forge strategy save</div>
          <div class="cmd-card-desc">Register a strategy JSON to the registry (optionally recorded in the Journal).</div>
          <pre class="cmd-card-usage"><code>forge strategy save FILE_PATH</code></pre>
          <div class="cmd-card-options">
            <span class="cmd-card-option">--force</span>
          </div>
          <div class="cmd-card-link">See cli-reference →</div>
        </a>

        <a class="cmd-card" href="/en/docs/cli-reference/journal/#forge-journal-show">
          <div class="cmd-card-name">forge journal show</div>
          <div class="cmd-card-desc">Show the full history of a strategy (snapshots, runs, tags, live summary).</div>
          <pre class="cmd-card-usage"><code>forge journal show STRATEGY_ID</code></pre>
          <div class="cmd-card-link">See cli-reference →</div>
        </a>
      </div>

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

      <div class="callout" style="margin-top: 2rem;">
        <p style="margin-bottom: 0.75rem;">
          For complete subcommand listings, options, return values, and sample output for each group,
          see the CLI Reference in the official docs.
        </p>
        <a href="/en/docs/cli-reference/" class="btn-primary">
          Open CLI Reference →
        </a>
      </div>

      <div class="callout" style="margin-top: 1rem;">
        <p>If you need help, contact <a href="mailto:support@alforgelabs.com">support@alforgelabs.com</a>.</p>
      </div>
    </div>

  </div>

  <footer>
    <div class="footer-logo">alforge<span class="dot">.</span>labs</div>
    <div class="lang-content lang-ja"><div class="footer-links"><a href="index.html">ホーム</a><a href="install.html">インストール</a><a href="docs.html">ドキュメント</a><a href="terms.html">利用規約</a><a href="privacy.html">プライバシー</a></div></div>
    <div class="lang-content lang-en"><div class="footer-links"><a href="index.html">Home</a><a href="install.html">Install</a><a href="docs.html">Docs</a><a href="terms.html">Terms</a><a href="privacy.html">Privacy</a></div></div>
  </footer>

  <script src="https://unpkg.com/react@18.3.1/umd/react.development.js" integrity="sha384-hD6/rw4ppMLGNu3tX5cjIb+uRZ7UkRJ6BPkLpg4hAu/6onKUg4lLsHAs9EBPT82L" crossorigin="anonymous"></script>
  <script src="https://unpkg.com/react-dom@18.3.1/umd/react-dom.development.js" integrity="sha384-u6aeetuaXnQ38mYT8rp6sbXaQe3NL9t+IBXmnYxwkUI2Hw4bsp2Wvmx4yRQF1uAm" crossorigin="anonymous"></script>
  <script src="https://unpkg.com/@babel/standalone@7.29.0/babel.min.js" integrity="sha384-m08KidiNqLdpJqLq95G/LEi8Qvjl/xUYll3QILypMoQ65QorJ9Lvtp2RXYGBFj1y" crossorigin="anonymous"></script>
  <script type="text/babel" src="../site-header.jsx"></script>
  <script type="text/babel">
    renderStandaloneHeader({ active: 'docs' });
  </script>
</body>
</html>
```

Write ツールで `templates/docs.html.j2` の全内容を上記で置換する。**注意**: 既存ファイルなので Write 前に Read で 1 回読んでから Write すること（Claude Code の Write tool 仕様上、既存ファイルへの上書きは Read 必須）。

- [ ] **Step 3: テンプレ全体の構造検証**

```bash
wc -l templates/docs.html.j2
```
期待: 約 290〜320 行（1012 行から大幅圧縮）

```bash
grep -c '<h1 class="page-title">' templates/docs.html.j2
```
期待: `2`（ja + en の各ヒーロー）

```bash
grep -c 'cmd-card-grid' templates/docs.html.j2
```
期待: `2`（ja + en で各 1 グリッド）+ CSS 定義 1 = `3`。CSS のみカウントする場合は別 grep。

```bash
grep -c '<a class="cmd-card"' templates/docs.html.j2
```
期待: `12`（ja + en で 6 カードずつ）

```bash
grep -c 'btn-primary' templates/docs.html.j2
```
期待: `4`（上下 callout × ja/en）

```bash
grep -c '/ja/docs/cli-reference/' templates/docs.html.j2
```
期待: `15`（ja セクションのリンク総数: 上 callout 1 + 6 カード + 7 表行 + 下 callout 1 = 15）

```bash
grep -c '/en/docs/cli-reference/' templates/docs.html.j2
```
期待: `15`（en セクション同等）

```bash
grep -c 'forge コマンドの早見表' templates/docs.html.j2
```
期待: `1`

```bash
grep -c 'forge Command Quick Reference' templates/docs.html.j2
```
期待: `1`

```bash
grep -c 'cmd-nav-list\|doc-layout\|option-table\|payload-table\|step-list' templates/docs.html.j2
```
期待: `0`（削除セクション関連の class が完全に消えている）

```bash
grep -c 'エンドツーエンド\|TradingView\|alpha-strike' templates/docs.html.j2
```
期待: `0`（ガイド 3 セクションが完全削除）

- [ ] **Step 4: Jinja2 変数とヘッダー/フッターの保持を検証**

```bash
grep -c '{{ lang }}' templates/docs.html.j2
```
期待: `4`（html lang, theme スクリプト 2 箇所、body data-lang）

```bash
grep -c '{{ canonical_url }}\|{{ hreflang_ja }}\|{{ hreflang_en }}\|{{ json_ld }}' templates/docs.html.j2
```
期待: `4`（各 1 件、SEO 維持）

```bash
grep -c "renderStandaloneHeader({ active: 'docs' })" templates/docs.html.j2
```
期待: `1`

```bash
grep -c 'site-header.jsx' templates/docs.html.j2
```
期待: `1`

- [ ] **Step 5: テンプレをステージング & コミット**

```bash
git add templates/docs.html.j2
git status
git commit -m "feat: docs.html を「カタログ + 主要 6 コマンド」に再構成

- 1012 行から約 300 行へ大幅簡素化
- ヒーロー + 主要 6 コマンドのカードグリッド + 全 7 グループのカタログ表 +
  上下 2 箇所の cli-reference 誘導 callout に再構成
- 削除: 左サイドバー、forge {data,strategy,backtest,optimize,pine,dashboard,license}
  セクション、ワークフロー / TradingView / alpha-strike 連携の 3 ガイドセクション
- 詳細は /{ja,en}/docs/cli-reference/ へリンク（MkDocs を正本に）

Refs #65"
```

期待: コミット成功、`templates/docs.html.j2` が 1 ファイル変更として記録される。

```bash
git log --oneline -3
```
期待: 最新コミットが上記メッセージで記録されている。

---

## Task 2: build.py を実行してビルド成果物を再生成 → コミット 2

**Files:**
- Generate: `ja/docs.html`
- Generate: `en/docs.html`

- [ ] **Step 1: build.py を実行**

```bash
uv run python build.py
```
期待出力（順不同）:
```
  ✓ ja/index.html
  ✓ ja/install.html
  ✓ ja/docs.html
  ✓ ja/tutorial-strategy.html
  ✓ ja/privacy.html
  ✓ ja/terms.html
  ✓ en/index.html
  ✓ en/install.html
  ✓ en/docs.html
  ✓ en/tutorial-strategy.html
  ✓ en/privacy.html
  ✓ en/terms.html
  ✓ robots.txt
  ✓ sitemap.xml
Build complete.
```

- [ ] **Step 2: 副作用チェック（docs.html 以外が変わっていないこと）**

```bash
git diff --stat ja/ en/ robots.txt sitemap.xml
```
期待: `ja/docs.html` と `en/docs.html` のみが変更ファイルに含まれる。他のページ（index.html, install.html, tutorial-strategy.html, privacy.html, terms.html）と robots.txt / sitemap.xml に差分が無い。

- [ ] **Step 3: ja/docs.html の構造確認**

```bash
grep -c '<a class="cmd-card"' ja/docs.html
```
期待: `12`（ja + en の各カードが SPA 構造で 1 ファイルに同梱）

```bash
grep -c 'btn-primary' ja/docs.html
```
期待: `4`（上下 callout × ja/en 合算）

```bash
grep -c '/ja/docs/cli-reference/' ja/docs.html
```
期待: `15`（ja セクション内のリンク総数）

```bash
grep -c '/en/docs/cli-reference/' ja/docs.html
```
期待: `15`（同一ファイル内の en セクションのリンク）

```bash
grep -c 'forge コマンドの早見表' ja/docs.html
```
期待: `1`

```bash
grep -c 'forge Command Quick Reference' ja/docs.html
```
期待: `1`（同一ファイル内に en コンテンツも含まれる SPA 構造）

```bash
grep -c 'cmd-nav-list\|エンドツーエンド\|TradingView\|alpha-strike' ja/docs.html
```
期待: `0`（削除セクション関連の文字列が完全に消えている）

```bash
grep -c '"@context"' ja/docs.html
```
期待: `1`（JSON-LD 維持）

```bash
grep -c 'hreflang=' ja/docs.html
```
期待: `3`（ja, en, x-default）

```bash
grep -c '<title>ドキュメント — Alforge Labs</title>' ja/docs.html
```
期待: `1`（seo.yaml の docs.ja.title）

- [ ] **Step 4: en/docs.html の構造確認**

```bash
grep -c '<a class="cmd-card"' en/docs.html
```
期待: `12`

```bash
grep -c 'btn-primary' en/docs.html
```
期待: `4`

```bash
grep -c 'forge Command Quick Reference' en/docs.html
```
期待: `1`

```bash
grep -c '<title>Documentation — Alforge Labs</title>' en/docs.html
```
期待: `1`（seo.yaml の docs.en.title）

```bash
grep -c '"@context"' en/docs.html
```
期待: `1`

- [ ] **Step 5: ローカルブラウザ確認はスキップ**

`open` は subagent では実行できないため、Step 5 は省略。Step 3 と Step 4 の grep 検証で構造確認は十分。controller / ユーザー側で目視確認する。

- [ ] **Step 6: ビルド成果物をステージング & コミット**

```bash
git add ja/docs.html en/docs.html
git status
git commit -m "chore: docs.html の build.py 出力を再生成

templates/docs.html.j2 の再構成に伴うビルド成果物の更新。

Refs #65"
```

期待: コミット成功、`ja/docs.html` と `en/docs.html` の 2 ファイルが変更として記録される。

```bash
git log --oneline -5
```
期待: 直近 3 コミット（spec / テンプレ書き直し / ビルド成果物）が確認できる。

---

## Task 3: MkDocs アンカー存在検証

**Files:**
- 変更なし（検証のみ）

カードの href が指す MkDocs ビルド済みアンカー (`#forge-{group}-{sub}`) が実在することを確認する。

- [ ] **Step 1: 各サブコマンドアンカーの存在確認**

```bash
grep -c 'id="forge-backtest-run"' ja/docs/cli-reference/backtest/index.html
```
期待: `1`

```bash
grep -c 'id="forge-optimize-run"' ja/docs/cli-reference/optimize/index.html
```
期待: `1`

```bash
grep -c 'id="forge-optimize-walk-forward"' ja/docs/cli-reference/optimize/index.html
```
期待: `1`

```bash
grep -c 'id="forge-data-fetch"' ja/docs/cli-reference/data/index.html
```
期待: `1`

```bash
grep -c 'id="forge-strategy-save"' ja/docs/cli-reference/strategy/index.html
```
期待: `1`

```bash
grep -c 'id="forge-journal-show"' ja/docs/cli-reference/journal/index.html
```
期待: `1`

- [ ] **Step 2: 英語版アンカーの存在確認**

```bash
grep -c 'id="forge-backtest-run"' en/docs/cli-reference/backtest/index.html
```
期待: `1`

```bash
grep -c 'id="forge-optimize-run"' en/docs/cli-reference/optimize/index.html
```
期待: `1`

```bash
grep -c 'id="forge-optimize-walk-forward"' en/docs/cli-reference/optimize/index.html
```
期待: `1`

```bash
grep -c 'id="forge-data-fetch"' en/docs/cli-reference/data/index.html
```
期待: `1`

```bash
grep -c 'id="forge-strategy-save"' en/docs/cli-reference/strategy/index.html
```
期待: `1`

```bash
grep -c 'id="forge-journal-show"' en/docs/cli-reference/journal/index.html
```
期待: `1`

- [ ] **Step 3: グループページの存在確認**

```bash
ls ja/docs/cli-reference/{backtest,optimize,strategy,data,journal,live,other}/index.html 2>/dev/null | wc -l
```
期待: `7`

```bash
ls en/docs/cli-reference/{backtest,optimize,strategy,data,journal,live,other}/index.html 2>/dev/null | wc -l
```
期待: `7`

すべて `1` または `7` が返ることを確認すること。もし `0` が返るアンカーがあれば、MkDocs ビルドのアンカー命名規約と Plan の前提（`forge-{group}-{sub}` 形式）が一致していないため、controller に BLOCKED で報告する。

- [ ] **Step 4: コミット不要、Task 3 はチェックのみ**

このタスクは検証のみで、新たなコミットは作成しない。万一アンカーが見つからなかった場合、Task 1 のテンプレを修正して再度ビルド成果物を更新する必要がある。

---

## Task 4: PR 作成

**Files:**
- 変更なし（GitHub PR 作成のみ）

- [ ] **Step 1: ローカル状態確認**

```bash
git status
```
期待: `On branch feat/docs-issue-65-docs-html-slim`、working tree clean。

```bash
git log --oneline main..HEAD
```
期待: 3 コミットが確認できる:
- spec ドキュメント (6329bf8)
- plan ドキュメント (本コミット、Task 0 で作成 — 注: writing-plans 後に commit 済み)
- feat: docs.html 再構成
- chore: ビルド成果物再生成

注: writing-plans skill の plan 文書もこのブランチ上にあるはず。実装時に main..HEAD で確認する。

- [ ] **Step 2: リモートに push**

```bash
git push -u origin feat/docs-issue-65-docs-html-slim
```
期待: 新規ブランチが GitHub に push される。

- [ ] **Step 3: PR 作成**

```bash
gh pr create --title "feat: docs.html を「カタログ + 主要 6 コマンド」に再構成 (#65)" --body "$(cat <<'EOF'
## Summary

- \`templates/docs.html.j2\` を 1012 行から約 300 行へ簡素化し、ヒーロー + 主要 6 コマンドのカードグリッド + 全 7 グループのカタログ表に再構成
- ヒーロー直下とカタログ表後の 2 箇所に MkDocs 公式 cli-reference への誘導 callout を追加
- 削除: 左サイドバー目次、\`forge {data,strategy,backtest,optimize,pine,dashboard,license}\` の 7 セクション、ワークフロー / TradingView / alpha-strike 連携の 3 ガイドセクション
- カードクリックで \`/{ja,en}/docs/cli-reference/{group}/#forge-{group}-{sub}\` のサブコマンドアンカーへ直接遷移

## 設計ドキュメント

\`docs/superpowers/specs/2026-04-30-alforge-labs-issue-65-docs-html-slim-design.md\`

## 実装計画

\`docs/superpowers/plans/2026-04-30-alforge-labs-issue-65-docs-html-slim.md\`

## Test plan

- [x] \`uv run python build.py\` が正常終了し \`{ja,en}/docs.html\` のみが再生成される
- [x] \`grep -c '<a class=\"cmd-card\"' ja/docs.html\` が \`12\` を返す（ja+en 各 6 カード）
- [x] \`grep -c 'btn-primary' ja/docs.html\` が \`4\` を返す（上下 callout × ja/en）
- [x] MkDocs cli-reference の各サブコマンドアンカー（\`#forge-{group}-{sub}\`）が実在
- [x] \`cmd-nav-list\`, \`エンドツーエンド\`, \`TradingView\`, \`alpha-strike\` がいずれも残っていない
- [x] JSON-LD と hreflang が維持されている
- [ ] 公開後ブラウザでヒーロー / カードグリッド / カタログ表 / 各リンクの動作を確認

## SEO 影響評価

- \`seo.yaml\` の docs ページコピーは無変更
- \`sitemap.xml\` の docs エントリ priority \`0.9\` / changefreq \`weekly\` 維持
- JSON-LD（BreadcrumbList）は build.py で動的生成、構造変更なし
- hreflang リンク（ja / en / x-default）維持

## フォローアップ（別 issue で対応推奨）

- 削除した 3 ガイドセクション（ワークフロー / TradingView / alpha-strike 連携）の MkDocs 移植
- React/React-DOM の production build 切り替え（既存 issue #79）
- HTML テンプレートの lang-content 並列構造の見直し（既存 issue #78）

Closes #65
EOF
)"
```
期待: PR 番号と URL が表示される。

- [ ] **Step 4: PR 状態確認**

```bash
gh pr view --json number,url,state,statusCheckRollup
```
期待: PR がオープン状態、status check は空 or success（GitHub Pages リポジトリで通常 CI なし）。

- [ ] **Step 5: マージは実施しない**

ユーザー承認待ち。`gh pr merge` は controller 側で実行する。

---

## Self-Review

### Spec coverage

| Spec 要件 | 対応タスク |
|---|---|
| ヒーロー: 「forge コマンドの早見表」 | Task 1 Step 2（テンプレ全文に含む） |
| Docs 誘導 callout（上） | Task 1 Step 2 |
| 主要 6 コマンドのカードグリッド (CSS Grid) | Task 1 Step 2 |
| カードのリンク先 (`#forge-{group}-{sub}` アンカー) | Task 1 Step 2、Task 3 で検証 |
| 全コマンドカタログ表（7 行） | Task 1 Step 2 |
| Docs 誘導 callout（下） | Task 1 Step 2 |
| 削除: 左サイドバー、7 コマンドセクション、3 ガイド | Task 1 Step 2（Write で完全置換）、Step 3 で検証 |
| 新規 CSS をテンプレ内 `<style>` に局所追加 | Task 1 Step 2 |
| `seo.yaml` 無変更 | （タスク内で触らない） |
| `page.css` 無変更 | （タスク内で触らない） |
| build.py で再生成 | Task 2 |
| MkDocs アンカー存在検証 | Task 3 |
| 2 コミット粒度 | Task 1 Step 5（テンプレ）+ Task 2 Step 6（成果物） |
| PR タイトル / Closes #65 | Task 4 Step 3 |

すべての spec 要件にタスクが割り当てられている。ギャップなし。

### Placeholder scan

- [x] "TBD" / "TODO" / "implement later" — なし
- [x] テンプレ全文が完全に展開されている（Task 1 Step 2）
- [x] grep 検証コマンドはすべて期待値が具体値で書かれている
- [x] PR 本文 HEREDOC も実テキストで完成している

### Type / signature 一貫性

- [x] CSS class 名 (`.cmd-card-grid`, `.cmd-card`, `.cmd-card-name`, `.cmd-card-desc`, `.cmd-card-usage`, `.cmd-card-options`, `.cmd-card-option`, `.cmd-card-link`) が CSS 定義と HTML 利用箇所で完全一致
- [x] カードの href URL (`/ja/docs/cli-reference/{group}/#forge-{group}-{sub}`) が Task 1 と Task 3 の検証で一致
- [x] カタログ表のグループ別 URL (`/ja/docs/cli-reference/{group}/`) と Task 3 のディレクトリ存在チェック対象が一致
- [x] ヒーロー文言「forge コマンドの早見表」「forge Command Quick Reference」が Task 1 内と PR タイトル / 検証コマンドで一致
