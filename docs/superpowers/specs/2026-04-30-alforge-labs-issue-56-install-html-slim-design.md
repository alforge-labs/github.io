# alforge-labs Issue #56 — install.html 簡素化と MkDocs 導線追加

## 目的

`{ja,en}/install.html`（および Jinja2 テンプレート `templates/install.html.j2`）を簡素化し、詳細手順は MkDocs 公式ドキュメント（`/ja/docs/getting-started/`・`/en/docs/getting-started/`）への導線に集約する。MkDocs を**正本（source of truth）** とし、HTML ランディングは「5 分で動かす」ための最短経路に絞る。

## 背景

- #48 で MkDocs `getting-started.md` にインストール手順・ライセンス認証・トラブルシューティングを完全コピー済み（`mkdocs_src/{ja,en}/getting-started.md` 約 195 行）。
- 現状の `install.html` は前提条件・3 タブインストール・3 ステップライセンス認証・アンインストール・トラブルシューティング表まで網羅しており、スクロール量が多い。
- MkDocs 側を正本にする方針は #54〜#74 で確立済み。HTML ランディングは「最短到達」「SEO 維持」が役割。

## スコープ確定事項（ブレインストーミングで決定）

| 論点 | 決定 |
|------|------|
| ライセンス認証セクション | **残す**（1 ブロックに簡素化） |
| 前提条件 OS リスト | 削除（MkDocs に既存） |
| 手動インストールタブ | 削除（MkDocs に既存） |
| アンインストールセクション | 削除（`mkdocs_src/{ja,en}/getting-started.md:159` に既存） |
| Docs 誘導の配置 | **ヒーロー直下とページ末尾の 2 箇所** |
| 実装アプローチ | 既存 `install.html.j2` をインプレース編集 |
| 新規 CSS | 不要（既存 `.callout` + `.btn-primary` を流用） |

## ページ構造（簡素化後）

```
1. ヒーロー
   - page-label: "Getting Started"
   - h1: "5 分で AlphaForge を動かす" / "Get AlphaForge Running in 5 Minutes"
   - subtitle: 「2 コマンドで完了。詳細は公式ドキュメントへ」

2. Docs 誘導 callout（上）— 新規
   - .callout + .btn-primary
   - href="/ja/docs/getting-started/" / "/en/docs/getting-started/"

3. クイックインストール
   - h2: "クイックインストール" / "Quick Install"
   - .platform-tabs（macOS/Linux + Windows の 2 タブ）
   - 各タブに 1 コマンド + 1 行説明のみ

4. ライセンス認証（簡素化）
   - h2: "ライセンス認証" / "License Activation"
   - 平文 1 段落 + forge license activate コマンド 1 行

5. 主要トラブルシューティング（現状維持）
   - .cmd-table 3 行
     - command not found: forge
     - ライセンス認証エラー
     - macOS セキュリティ警告

6. Docs 誘導 callout（下）— 新規
   - 「アンインストール手順・環境変数・完全なトラブルシューティング表はドキュメントへ」

7. サポートメール callout（現状維持）
   - support@alforgelabs.com
```

### 削除されるセクション

| セクション | 削除理由 | MkDocs での代替 |
|---|---|---|
| 前提条件（OS リスト 3 項目） | スクロール削減 | `getting-started.md` Prerequisites |
| 「手動インストール」タブ | クイックインストール 2 経路で十分 | `getting-started.md` Manual Install |
| ライセンス認証の `forge --version` ステップ | 導通確認は MkDocs に既存 | 同 |
| ライセンス認証の `forge backtest --help` ステップ | 導通確認は MkDocs に既存 | 同 |
| アンインストールセクション | install.html での出現頻度低 | `getting-started.md:159` |

### 維持されるセクション（変更なし）

- Jinja2 テンプレ上部（meta タグ・JSON-LD・hreflang・preconnect・theme 初期化スクリプト）
- ヘッダー（`<div id="site-header"></div>` + `site-header.jsx`）
- フッター（言語別リンク）
- React/Babel スクリプトロード
- `switchTab()` JavaScript（macOS/Linux と Windows の 2 値のみ参照されるようになる）

## HTML スニペット

### Docs 誘導 callout（上、ヒーロー直下）

**ja**:
```html
<div class="callout" style="margin-bottom: 2rem;">
  <p style="margin-bottom: 0.75rem;">
    詳しい手順・パラメータ・トラブルシューティング全集は
    <strong>公式ドキュメント</strong>を参照してください。
  </p>
  <a href="/ja/docs/getting-started/" class="btn-primary">
    ドキュメントを開く →
  </a>
</div>
```

**en**:
```html
<div class="callout" style="margin-bottom: 2rem;">
  <p style="margin-bottom: 0.75rem;">
    For complete instructions, parameters, and the full troubleshooting guide,
    see the <strong>official documentation</strong>.
  </p>
  <a href="/en/docs/getting-started/" class="btn-primary">
    Open Documentation →
  </a>
</div>
```

### Docs 誘導 callout（下、トラブルシューティング表のあと）

**ja**:
```html
<div class="callout" style="margin-top: 2rem;">
  <p style="margin-bottom: 0.75rem;">
    アンインストール手順、環境変数によるカスタマイズ、完全なトラブルシューティング表は
    ドキュメントを参照してください。
  </p>
  <a href="/ja/docs/getting-started/" class="btn-primary">
    ドキュメントを開く →
  </a>
</div>
```

**en**:
```html
<div class="callout" style="margin-top: 2rem;">
  <p style="margin-bottom: 0.75rem;">
    For uninstall steps, environment variable customization, and the complete
    troubleshooting matrix, see the documentation.
  </p>
  <a href="/en/docs/getting-started/" class="btn-primary">
    Open Documentation →
  </a>
</div>
```

### ヒーロー文言

**ja**:
```html
<div class="page-label">Getting Started</div>
<h1 class="page-title">5 分で AlphaForge を動かす</h1>
<p class="page-subtitle">CLI のインストールからライセンス認証まで、たった 2 コマンド。詳細手順は公式ドキュメントへ。</p>
```

**en**:
```html
<div class="page-label">Getting Started</div>
<h1 class="page-title">Get AlphaForge Running in 5 Minutes</h1>
<p class="page-subtitle">Install the CLI and activate your license in two commands. Full instructions live in the official docs.</p>
```

### クイックインストール（簡素化後、ja のみ抜粋・en は label/コメント差し替え）

```html
<h2 class="section-heading">クイックインストール</h2>
<div class="platform-tabs">
  <div class="platform-tab active" onclick="switchTab('ja', 'mac', event)">macOS / Linux</div>
  <div class="platform-tab" onclick="switchTab('ja', 'win', event)">Windows</div>
</div>

<div id="tab-ja-mac" class="platform-content active">
  <p>ターミナルで実行します。インストーラーが最新バイナリをダウンロードし、<code>/usr/local/bin</code> に配置します。</p>
  <pre><code>curl -sSL https://alforge-labs.github.io/install.sh | bash</code></pre>
</div>

<div id="tab-ja-win" class="platform-content">
  <p>PowerShell（管理者権限不要）で実行します。バイナリを <code>%USERPROFILE%\.forge\bin</code> にインストールし、PATH を自動設定します。</p>
  <pre><code>irm https://alforge-labs.github.io/install.ps1 | iex</code></pre>
</div>
```

### ライセンス認証（簡素化後）

**ja**:
```html
<h2 class="section-heading">ライセンス認証</h2>
<p>購入完了メールに記載されているライセンスキーで認証します。認証情報は <code>~/.forge/license.json</code> に保存されます。</p>
<pre><code>forge license activate &lt;YOUR_LICENSE_KEY&gt;</code></pre>
```

**en**:
```html
<h2 class="section-heading">License Activation</h2>
<p>Use the license key from your purchase email. Activation data is cached at <code>~/.forge/license.json</code>.</p>
<pre><code>forge license activate &lt;YOUR_LICENSE_KEY&gt;</code></pre>
```

## 影響範囲（ファイル変更）

| ファイル | 変更内容 |
|---|---|
| `templates/install.html.j2` | インプレース編集（簡素化＋ Docs 誘導 callout 2 箇所追加） |
| `ja/install.html` | `uv run python build.py` で再生成 |
| `en/install.html` | `uv run python build.py` で再生成 |
| `seo.yaml` | **変更なし**（install ページの title/description/keywords は依然正確） |
| `sitemap.xml` | **変更なし**（build.py が既存 priority/changefreq で再生成） |
| `robots.txt` | **変更なし**（build.py が既存内容で再生成） |
| `page.css` | **変更なし**（既存 `.callout` + `.btn-primary` を流用） |
| MkDocs 関連ファイル | **一切変更なし**（#48 で完成済み） |

## ビルド & 検証

```bash
cd /Users/sakae/dev/alpha-trade/alforge-labs

# 1. テンプレ更新後にビルド
uv run python build.py
# 期待出力: ✓ ja/install.html, ✓ en/install.html, ✓ robots.txt, ✓ sitemap.xml

# 2. 差分確認
git diff --stat templates/install.html.j2 ja/install.html en/install.html

# 3. ローカル確認
open ja/install.html
# 検証項目:
#   - h1 が「5 分で AlphaForge を動かす」になっている
#   - ヒーロー直下に Docs 誘導 callout がある（ボタンがクリック可能で /ja/docs/getting-started/ へ遷移する）
#   - クイックインストールタブが macOS/Linux と Windows の 2 つ
#   - タブ切り替えが動作する（switchTab JS）
#   - ライセンス認証セクションが 1 ブロック（ステップ番号なし）
#   - トラブルシューティング表が 3 行
#   - 表のあとに Docs 誘導 callout（下）がある
#   - アンインストールセクションが存在しない
#   - Support callout が末尾にある
#   - ヘッダー / フッターが正常表示
open en/install.html
# 同上を英語版で検証

# 4. SEO 構造の確認
grep -c '"@context"' ja/install.html  # JSON-LD が 1 つ存在することを確認
grep -c 'hreflang' ja/install.html    # hreflang リンクが残存していることを確認
```

## ロールバック

すべて新規ファイル追加とテンプレートのインプレース編集なので、ロールバックは安全：

```bash
git checkout main -- templates/install.html.j2 ja/install.html en/install.html
# あるいは
git revert <PR の squash commit hash>
```

MkDocs 関連ファイル（`mkdocs.{ja,en}.yml` / `mkdocs_src/` / `{ja,en}/docs/`）には一切触らないため、副作用なし。

## コミット粒度

ブランチ名: `feat/docs-issue-56-install-html-slim`

```
コミット 1: feat: install.html を簡素化、MkDocs ドキュメントへの導線を追加
  対象: templates/install.html.j2

コミット 2: chore: install.html の build.py 出力を再生成
  対象: ja/install.html, en/install.html
```

## PR

- タイトル: `feat: install.html を簡素化し MkDocs への導線を追加 (#56)`
- 本文に `Closes #56` を含める
- マージ後: `gh pr merge <N> --squash --delete-branch`

## 受入条件チェック（issue #56 より転載）

- [x] `/ja/install.html` と `/en/install.html` がスクロールせずに主要情報が読める短さに圧縮されている
  - 削除セクション: 前提条件・手動インストールタブ・3 ステップ展開・アンインストール
- [x] `/ja/docs/getting-started/` への目立つ導線がある
  - ヒーロー直下と末尾の 2 箇所、`.btn-primary` で視認性高い
- [x] `templates/install.html.j2` の Jinja2 テンプレートも更新されている
  - 正本としてテンプレを編集し、`build.py` でビルド成果物を再生成
- [x] 既存 SEO（seo.yaml、メタタグ、構造化データ）に大きな悪影響がない
  - seo.yaml 無変更、JSON-LD は build.py で動的生成され構造変更なし、hreflang 維持

## 今回スコープ外

- `seo.yaml` の install ページコピー文の刷新（必要なら別 issue）
- `homepage-app.jsx` などのページ全体 React アプリへの影響（install.html はヘッダーのみ React で、ページ本体は静的 HTML のため影響なし）
- `templates/install.html.j2` の lang 並列構造（`lang-content lang-ja` / `lang-content lang-en` を 1 ファイル内に並べる方式）の見直し（別途リファクタリング issue 候補）
