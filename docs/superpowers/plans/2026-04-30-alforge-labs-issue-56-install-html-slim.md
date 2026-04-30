# install.html 簡素化と MkDocs 導線追加 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `templates/install.html.j2` を簡素化して `{ja,en}/install.html` をスクロール最小化し、MkDocs 公式ドキュメント `/{ja,en}/docs/getting-started/` への導線を 2 箇所追加する。

**Architecture:** Jinja2 テンプレート（`templates/install.html.j2`）のインプレース編集 → `uv run python build.py` でビルド成果物を再生成 → 2 コミット（テンプレ + ビルド成果物）→ PR 作成。新規 CSS は不要、既存の `.callout` + `.btn-primary` を流用。

**Tech Stack:** Jinja2, Python 3 (build.py with PyYAML), 静的 HTML/CSS/JS, GitHub Pages, gh CLI

**作業ブランチ:** `feat/docs-issue-56-install-html-slim`（spec コミット `3df8426` で作成済み）

**Spec:** `docs/superpowers/specs/2026-04-30-alforge-labs-issue-56-install-html-slim-design.md`

---

## File Structure

| ファイル | 責務 | 変更タイプ |
|---|---|---|
| `templates/install.html.j2` | Jinja2 テンプレート（正本） | 編集（簡素化 + Docs 誘導追加） |
| `ja/install.html` | build.py 出力 | 再生成（コミット） |
| `en/install.html` | build.py 出力 | 再生成（コミット） |
| `seo.yaml` | SEO メタデータ | 変更なし |
| `page.css` | スタイル | 変更なし |
| `build.py` | ビルドスクリプト | 変更なし |

各タスクは ja セクションと en セクションを「1 タスク内で連続編集」する。テンプレが lang ごとに `lang-content lang-ja` / `lang-content lang-en` で並列構造になっているため、同じ変更を 2 度繰り返す形になる。

---

## Task 1: ヒーロー文言を ja/en で更新

**Files:**
- Modify: `templates/install.html.j2:48-50`（ja ヒーロー）
- Modify: `templates/install.html.j2:122-124`（en ヒーロー）

- [ ] **Step 1: 現状の ja ヒーロー部分を確認**

```bash
grep -n -A 2 'page-label">Getting Started' templates/install.html.j2
```

期待: 2 箇所のヒット（ja: line 48 付近、en: line 122 付近）。各ヒーローの h1 と subtitle の現行テキストを確認する。

- [ ] **Step 2: ja のヒーロー文言を更新**

Edit 対象（既存）:
```html
      <div class="page-label">Getting Started</div>
      <h1 class="page-title">インストールガイド</h1>
      <p class="page-subtitle">AlphaForge CLI をインストールしてライセンス認証するまでの手順です。所要時間は約5分です。</p>
```

新規:
```html
      <div class="page-label">Getting Started</div>
      <h1 class="page-title">5 分で AlphaForge を動かす</h1>
      <p class="page-subtitle">CLI のインストールからライセンス認証まで、たった 2 コマンド。詳細手順は公式ドキュメントへ。</p>
```

- [ ] **Step 3: en のヒーロー文言を更新**

Edit 対象（既存）:
```html
      <div class="page-label">Getting Started</div>
      <h1 class="page-title">Installation Guide</h1>
      <p class="page-subtitle">Install AlphaForge CLI and activate your license in about five minutes.</p>
```

新規:
```html
      <div class="page-label">Getting Started</div>
      <h1 class="page-title">Get AlphaForge Running in 5 Minutes</h1>
      <p class="page-subtitle">Install the CLI and activate your license in two commands. Full instructions live in the official docs.</p>
```

- [ ] **Step 4: 検証**

```bash
grep -c 'インストールガイド\|Installation Guide' templates/install.html.j2
```

期待: `0`（旧 h1 が完全に消えていること）。

```bash
grep -c '5 分で AlphaForge を動かす\|Get AlphaForge Running in 5 Minutes' templates/install.html.j2
```

期待: `2`（ja + en 各 1 件）。

---

## Task 2: ヒーロー直下に Docs 誘導 callout（上）を追加

**Files:**
- Modify: `templates/install.html.j2`（ja ヒーロー直後）
- Modify: `templates/install.html.j2`（en ヒーロー直後）

- [ ] **Step 1: 挿入位置の特定**

```bash
grep -n 'page-subtitle\|section-heading">前提条件\|section-heading">Requirements' templates/install.html.j2
```

期待: ja の page-subtitle と「前提条件」見出しの行番号、en の page-subtitle と「Requirements」見出しの行番号が確認できる。Docs 誘導 callout はその間に挿入する。Task 3 で前提条件は削除されるので、結果的にヒーロー直後の位置に残る。

- [ ] **Step 2: ja の page-subtitle 直後に Docs 誘導 callout を挿入**

ja セクションの subtitle（Task 1 で更新済み）の直後、`<h2 class="section-heading">前提条件</h2>` の直前に以下を挿入:

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

Edit する old_string は ja subtitle の末尾と前提条件 h2 の組み合わせを使う:

```html
      <p class="page-subtitle">CLI のインストールからライセンス認証まで、たった 2 コマンド。詳細手順は公式ドキュメントへ。</p>

      <h2 class="section-heading">前提条件</h2>
```

new_string:

```html
      <p class="page-subtitle">CLI のインストールからライセンス認証まで、たった 2 コマンド。詳細手順は公式ドキュメントへ。</p>

      <div class="callout" style="margin-bottom: 2rem;">
        <p style="margin-bottom: 0.75rem;">
          詳しい手順・パラメータ・トラブルシューティング全集は
          <strong>公式ドキュメント</strong>を参照してください。
        </p>
        <a href="/ja/docs/getting-started/" class="btn-primary">
          ドキュメントを開く →
        </a>
      </div>

      <h2 class="section-heading">前提条件</h2>
```

- [ ] **Step 3: en の page-subtitle 直後に Docs 誘導 callout を挿入**

old_string:

```html
      <p class="page-subtitle">Install the CLI and activate your license in two commands. Full instructions live in the official docs.</p>

      <h2 class="section-heading">Requirements</h2>
```

new_string:

```html
      <p class="page-subtitle">Install the CLI and activate your license in two commands. Full instructions live in the official docs.</p>

      <div class="callout" style="margin-bottom: 2rem;">
        <p style="margin-bottom: 0.75rem;">
          For complete instructions, parameters, and the full troubleshooting guide,
          see the <strong>official documentation</strong>.
        </p>
        <a href="/en/docs/getting-started/" class="btn-primary">
          Open Documentation →
        </a>
      </div>

      <h2 class="section-heading">Requirements</h2>
```

- [ ] **Step 4: 検証**

```bash
grep -c 'ドキュメントを開く →\|Open Documentation →' templates/install.html.j2
```

期待: `2`（ja + en 各 1 件、上部のみ）。

```bash
grep -c '/ja/docs/getting-started/\|/en/docs/getting-started/' templates/install.html.j2
```

期待: `2`（ja + en 各 1 件）。

---

## Task 3: 前提条件セクション（OS リスト）を ja/en で削除

**Files:**
- Modify: `templates/install.html.j2`（ja Requirements セクション）
- Modify: `templates/install.html.j2`（en Requirements セクション）

- [ ] **Step 1: ja の前提条件セクションを削除**

old_string:

```html
      <h2 class="section-heading">前提条件</h2>
      <ul>
        <li>macOS 12 (Monterey) 以降 / Ubuntu 22.04 以降 / Windows 11</li>
        <li>インターネット接続（ライセンス認証時）</li>
        <li>有効な AlphaForge ライセンスキー（<a href="index.html#pricing">購入ページ</a>から入手）</li>
      </ul>

      <h2 class="section-heading">インストール</h2>
```

new_string:

```html
      <h2 class="section-heading">クイックインストール</h2>
```

- [ ] **Step 2: en の前提条件セクションを削除**

old_string:

```html
      <h2 class="section-heading">Requirements</h2>
      <ul>
        <li>macOS 12 Monterey or later / Ubuntu 22.04 or later / Windows 11</li>
        <li>Internet access for license activation</li>
        <li>A valid AlphaForge license key from the <a href="index.html#pricing">pricing page</a></li>
      </ul>

      <h2 class="section-heading">Install</h2>
```

new_string:

```html
      <h2 class="section-heading">Quick Install</h2>
```

- [ ] **Step 3: 検証**

```bash
grep -c 'section-heading">前提条件\|section-heading">Requirements' templates/install.html.j2
```

期待: `0`（前提条件セクションが完全に削除されている）。

```bash
grep -c 'section-heading">クイックインストール\|section-heading">Quick Install' templates/install.html.j2
```

期待: `2`（ja + en 各 1 件、見出しがリネームされている）。

```bash
grep -c 'section-heading">インストール</h2\|section-heading">Install</h2' templates/install.html.j2
```

期待: `0`（旧見出しが消えている）。

---

## Task 4: クイックインストールを 2 タブに簡素化（手動タブと INSTALL_DIR callout を削除）

**Files:**
- Modify: `templates/install.html.j2`（ja platform-tabs と manual タブ）
- Modify: `templates/install.html.j2`（en platform-tabs と manual タブ）

- [ ] **Step 1: ja のタブヘッダーから手動インストールを削除**

old_string:

```html
      <div class="platform-tabs">
        <div class="platform-tab active" onclick="switchTab('ja', 'mac', event)">macOS / Linux</div>
        <div class="platform-tab" onclick="switchTab('ja', 'win', event)">Windows</div>
        <div class="platform-tab" onclick="switchTab('ja', 'manual', event)">手動インストール</div>
      </div>
```

new_string:

```html
      <div class="platform-tabs">
        <div class="platform-tab active" onclick="switchTab('ja', 'mac', event)">macOS / Linux</div>
        <div class="platform-tab" onclick="switchTab('ja', 'win', event)">Windows</div>
      </div>
```

- [ ] **Step 2: ja の mac タブから INSTALL_DIR callout を削除**

old_string:

```html
      <div id="tab-ja-mac" class="platform-content active">
        <p>ターミナルで以下のコマンドを実行してください。インストーラーが最新バイナリをダウンロードし、<code>/usr/local/bin</code> に配置します。</p>
        <pre><code>curl -sSL https://alforge-labs.github.io/install.sh | bash</code></pre>
        <div class="callout">
          <p>インストール先を変更したい場合は <code>INSTALL_DIR</code> 環境変数で指定できます。例: <code>INSTALL_DIR=~/.local/bin curl -sSL ... | bash</code></p>
        </div>
      </div>
```

new_string:

```html
      <div id="tab-ja-mac" class="platform-content active">
        <p>ターミナルで実行します。インストーラーが最新バイナリをダウンロードし、<code>/usr/local/bin</code> に配置します。</p>
        <pre><code>curl -sSL https://alforge-labs.github.io/install.sh | bash</code></pre>
      </div>
```

- [ ] **Step 3: ja の win タブから補足 callout を削除**

old_string:

```html
      <div id="tab-ja-win" class="platform-content">
        <p>PowerShell（管理者権限不要）で以下を実行してください。バイナリを <code>%USERPROFILE%\.forge\bin</code> にインストールし、PATH を自動設定します。</p>
        <pre><code>irm https://alforge-labs.github.io/install.ps1 | iex</code></pre>
        <div class="callout">
          <p>インストール後、新しいターミナルウィンドウを開いてから次の手順に進んでください。</p>
        </div>
      </div>
```

new_string:

```html
      <div id="tab-ja-win" class="platform-content">
        <p>PowerShell（管理者権限不要）で実行します。バイナリを <code>%USERPROFILE%\.forge\bin</code> にインストールし、PATH を自動設定します。</p>
        <pre><code>irm https://alforge-labs.github.io/install.ps1 | iex</code></pre>
      </div>
```

- [ ] **Step 4: ja の手動インストールタブブロック全体を削除**

old_string:

```html
      <div id="tab-ja-manual" class="platform-content">
        <ol>
          <li>
            <a href="https://github.com/alforge-labs/alforge-labs.github.io/releases/latest" target="_blank" rel="noopener">GitHub Releases</a>
            から使用するプラットフォームのバイナリをダウンロードします。
          </li>
          <li>macOS / Linux: 実行権限を付与して PATH の通ったディレクトリに配置します。<pre><code>chmod +x forge-macos-arm64
sudo mv forge-macos-arm64 /usr/local/bin/forge</code></pre></li>
          <li>Windows: バイナリを任意のフォルダに配置し、そのフォルダを PATH に追加します。</li>
        </ol>
      </div>

      <h2 class="section-heading">ライセンス認証</h2>
```

new_string:

```html

      <h2 class="section-heading">ライセンス認証</h2>
```

- [ ] **Step 5: en のタブヘッダーから手動インストールを削除**

old_string:

```html
      <div class="platform-tabs">
        <div class="platform-tab active" onclick="switchTab('en', 'mac', event)">macOS / Linux</div>
        <div class="platform-tab" onclick="switchTab('en', 'win', event)">Windows</div>
        <div class="platform-tab" onclick="switchTab('en', 'manual', event)">Manual</div>
      </div>
```

new_string:

```html
      <div class="platform-tabs">
        <div class="platform-tab active" onclick="switchTab('en', 'mac', event)">macOS / Linux</div>
        <div class="platform-tab" onclick="switchTab('en', 'win', event)">Windows</div>
      </div>
```

- [ ] **Step 6: en の mac タブから INSTALL_DIR callout を削除**

old_string:

```html
      <div id="tab-en-mac" class="platform-content active">
        <p>Run the following command in your terminal. The installer downloads the latest binary and places it in <code>/usr/local/bin</code>.</p>
        <pre><code>curl -sSL https://alforge-labs.github.io/install.sh | bash</code></pre>
        <div class="callout">
          <p>Set <code>INSTALL_DIR</code> if you want to install elsewhere. Example: <code>INSTALL_DIR=~/.local/bin curl -sSL ... | bash</code></p>
        </div>
      </div>
```

new_string:

```html
      <div id="tab-en-mac" class="platform-content active">
        <p>Run the following in your terminal. The installer downloads the latest binary into <code>/usr/local/bin</code>.</p>
        <pre><code>curl -sSL https://alforge-labs.github.io/install.sh | bash</code></pre>
      </div>
```

- [ ] **Step 7: en の win タブから補足 callout を削除**

old_string:

```html
      <div id="tab-en-win" class="platform-content">
        <p>Run this in PowerShell. It installs the binary into <code>%USERPROFILE%\.forge\bin</code> and updates PATH.</p>
        <pre><code>irm https://alforge-labs.github.io/install.ps1 | iex</code></pre>
        <div class="callout">
          <p>Open a new terminal window after installation before continuing.</p>
        </div>
      </div>
```

new_string:

```html
      <div id="tab-en-win" class="platform-content">
        <p>Run this in PowerShell (no admin needed). Installs into <code>%USERPROFILE%\.forge\bin</code> and updates PATH.</p>
        <pre><code>irm https://alforge-labs.github.io/install.ps1 | iex</code></pre>
      </div>
```

- [ ] **Step 8: en の手動インストールタブブロック全体を削除**

old_string:

```html
      <div id="tab-en-manual" class="platform-content">
        <ol>
          <li>Download the binary for your platform from <a href="https://github.com/alforge-labs/alforge-labs.github.io/releases/latest" target="_blank" rel="noopener">GitHub Releases</a>.</li>
          <li>macOS / Linux: make it executable and move it to a directory on your PATH.<pre><code>chmod +x forge-macos-arm64
sudo mv forge-macos-arm64 /usr/local/bin/forge</code></pre></li>
          <li>Windows: place the binary in any folder and add that folder to PATH.</li>
        </ol>
      </div>

      <h2 class="section-heading">License Activation</h2>
```

new_string:

```html

      <h2 class="section-heading">License Activation</h2>
```

- [ ] **Step 9: 検証**

```bash
grep -c 'tab-ja-manual\|tab-en-manual\|手動インストール\|Manual</div>' templates/install.html.j2
```

期待: `0`（手動タブ関連が完全削除）。

```bash
grep -c 'INSTALL_DIR' templates/install.html.j2
```

期待: `0`（INSTALL_DIR への言及が削除）。

```bash
grep -c "switchTab('ja'" templates/install.html.j2
```

期待: `2`（ja の mac/win タブのみ）。

```bash
grep -c "switchTab('en'" templates/install.html.j2
```

期待: `2`（en の mac/win タブのみ）。

---

## Task 5: ライセンス認証を 1 ブロックに簡素化（3 ステップ → 1 ブロック）

**Files:**
- Modify: `templates/install.html.j2`（ja License Activation セクション）
- Modify: `templates/install.html.j2`（en License Activation セクション）

- [ ] **Step 1: ja のライセンス認証セクションを簡素化**

old_string:

```html
      <h2 class="section-heading">ライセンス認証</h2>
      <ol class="steps">
        <li><div class="step-body"><div class="step-title">インストール確認</div><p>インストールが成功したことを確認します。</p><pre><code>forge --version</code></pre></div></li>
        <li><div class="step-body"><div class="step-title">ライセンスキーを認証</div><p>購入完了メールに記載されているライセンスキーで認証します。</p><pre><code>forge license activate &lt;YOUR_LICENSE_KEY&gt;</code></pre><p>認証情報は <code>~/.forge/license.json</code> に保存されます。オンライン接続が必要です。</p></div></li>
        <li><div class="step-body"><div class="step-title">動作確認</div><p>バックテストコマンドが利用可能なことを確認します。</p><pre><code>forge backtest --help</code></pre></div></li>
      </ol>
```

new_string:

```html
      <h2 class="section-heading">ライセンス認証</h2>
      <p>購入完了メールに記載されているライセンスキーで認証します。認証情報は <code>~/.forge/license.json</code> に保存されます。</p>
      <pre><code>forge license activate &lt;YOUR_LICENSE_KEY&gt;</code></pre>
```

- [ ] **Step 2: en のライセンス認証セクションを簡素化**

old_string:

```html
      <h2 class="section-heading">License Activation</h2>
      <ol class="steps">
        <li><div class="step-body"><div class="step-title">Check installation</div><p>Confirm that the binary is available.</p><pre><code>forge --version</code></pre></div></li>
        <li><div class="step-body"><div class="step-title">Activate your license</div><p>Use the license key from your purchase email.</p><pre><code>forge license activate &lt;YOUR_LICENSE_KEY&gt;</code></pre><p>Activation data is cached at <code>~/.forge/license.json</code>. Internet access is required.</p></div></li>
        <li><div class="step-body"><div class="step-title">Verify commands</div><p>Confirm that backtest commands are available.</p><pre><code>forge backtest --help</code></pre></div></li>
      </ol>
```

new_string:

```html
      <h2 class="section-heading">License Activation</h2>
      <p>Use the license key from your purchase email. Activation data is cached at <code>~/.forge/license.json</code>.</p>
      <pre><code>forge license activate &lt;YOUR_LICENSE_KEY&gt;</code></pre>
```

- [ ] **Step 3: 検証**

```bash
grep -c 'forge --version\|forge backtest --help' templates/install.html.j2
```

期待: `0`（導通確認コマンドが削除されている）。

```bash
grep -c 'class="steps"\|step-title' templates/install.html.j2
```

期待: `0`（3 ステップ展開構造が完全に消えている）。

```bash
grep -c 'forge license activate' templates/install.html.j2
```

期待: `2`（ja + en 各 1 件のメインコマンド）。

---

## Task 6: アンインストールセクションを ja/en で削除

**Files:**
- Modify: `templates/install.html.j2`（ja Uninstall セクション）
- Modify: `templates/install.html.j2`（en Uninstall セクション）

- [ ] **Step 1: ja のアンインストールセクションを削除**

old_string:

```html
      <h2 class="section-heading">アンインストール</h2>
      <pre><code># macOS / Linux
sudo rm /usr/local/bin/forge
rm -rf ~/.forge</code></pre>

      <h2 class="section-heading">トラブルシューティング</h2>
```

new_string:

```html
      <h2 class="section-heading">トラブルシューティング</h2>
```

- [ ] **Step 2: en のアンインストールセクションを削除**

old_string:

```html
      <h2 class="section-heading">Uninstall</h2>
      <pre><code># macOS / Linux
sudo rm /usr/local/bin/forge
rm -rf ~/.forge</code></pre>

      <h2 class="section-heading">Troubleshooting</h2>
```

new_string:

```html
      <h2 class="section-heading">Troubleshooting</h2>
```

- [ ] **Step 3: 検証**

```bash
grep -c 'section-heading">アンインストール\|section-heading">Uninstall' templates/install.html.j2
```

期待: `0`（アンインストール見出しが完全削除）。

```bash
grep -c 'sudo rm /usr/local/bin/forge' templates/install.html.j2
```

期待: `0`（アンインストールコマンドが削除）。

```bash
grep -c 'section-heading">トラブルシューティング\|section-heading">Troubleshooting' templates/install.html.j2
```

期待: `2`（次のセクションの見出しは維持）。

---

## Task 7: トラブルシューティング表のあとに下部 Docs 誘導 callout を追加

**Files:**
- Modify: `templates/install.html.j2`（ja の trouble table と support callout の間）
- Modify: `templates/install.html.j2`（en の trouble table と support callout の間）

- [ ] **Step 1: ja の Support callout 直前に Docs 誘導 callout を挿入**

old_string:

```html
        </tbody>
      </table>

      <div class="callout" style="margin-top: 2rem;">
        <p>問題が解決しない場合は <a href="mailto:support@alforgelabs.com">support@alforgelabs.com</a> までお問い合わせください。</p>
      </div>
    </div>

    <div class="lang-content lang-en">
```

new_string:

```html
        </tbody>
      </table>

      <div class="callout" style="margin-top: 2rem;">
        <p style="margin-bottom: 0.75rem;">
          アンインストール手順、環境変数によるカスタマイズ、完全なトラブルシューティング表は
          ドキュメントを参照してください。
        </p>
        <a href="/ja/docs/getting-started/" class="btn-primary">
          ドキュメントを開く →
        </a>
      </div>

      <div class="callout" style="margin-top: 1rem;">
        <p>問題が解決しない場合は <a href="mailto:support@alforgelabs.com">support@alforgelabs.com</a> までお問い合わせください。</p>
      </div>
    </div>

    <div class="lang-content lang-en">
```

- [ ] **Step 2: en の Support callout 直前に Docs 誘導 callout を挿入**

old_string:

```html
        </tbody>
      </table>

      <div class="callout" style="margin-top: 2rem;">
        <p>If the issue persists, contact <a href="mailto:support@alforgelabs.com">support@alforgelabs.com</a>.</p>
      </div>
    </div>
  </div>

  <footer>
```

new_string:

```html
        </tbody>
      </table>

      <div class="callout" style="margin-top: 2rem;">
        <p style="margin-bottom: 0.75rem;">
          For uninstall steps, environment variable customization, and the complete
          troubleshooting matrix, see the documentation.
        </p>
        <a href="/en/docs/getting-started/" class="btn-primary">
          Open Documentation →
        </a>
      </div>

      <div class="callout" style="margin-top: 1rem;">
        <p>If the issue persists, contact <a href="mailto:support@alforgelabs.com">support@alforgelabs.com</a>.</p>
      </div>
    </div>
  </div>

  <footer>
```

- [ ] **Step 3: 検証**

```bash
grep -c 'btn-primary' templates/install.html.j2
```

期待: `4`（上下の Docs 誘導 callout × ja/en）。

```bash
grep -c '/ja/docs/getting-started/' templates/install.html.j2
```

期待: `2`（ja 上下の callout）。

```bash
grep -c '/en/docs/getting-started/' templates/install.html.j2
```

期待: `2`（en 上下の callout）。

```bash
grep -c 'support@alforgelabs.com' templates/install.html.j2
```

期待: `2`（ja + en の Support callout は維持）。

---

## Task 8: テンプレ構造の最終検証 → コミット 1（テンプレ）

**Files:**
- Verify: `templates/install.html.j2`

- [ ] **Step 1: テンプレ全体の git diff を確認**

```bash
git diff --stat templates/install.html.j2
git diff templates/install.html.j2 | head -200
```

期待: 削除行 > 追加行（簡素化されている）、`page-label`/`section-heading`/`platform-tab`/`callout`/`btn-primary` などの class が一貫して使われている、Jinja2 変数（`{{ lang }}`, `{{ title }}` 等）は無傷。

- [ ] **Step 2: HTML の対称性確認（ja セクション内のタグバランス）**

```bash
awk '/lang-content lang-ja/,/lang-content lang-en/' templates/install.html.j2 | grep -c '<h2 class="section-heading"'
```

期待: `3`（ja セクション内の h2: クイックインストール、ライセンス認証、トラブルシューティング）。

```bash
awk '/lang-content lang-en/,/<\/div>$/' templates/install.html.j2 | grep -c '<h2 class="section-heading"'
```

期待: `3`（en セクション内の h2: Quick Install, License Activation, Troubleshooting）。

- [ ] **Step 3: テンプレをステージング & コミット**

```bash
git add templates/install.html.j2
git status
git commit -m "feat: install.html を簡素化、MkDocs ドキュメントへの導線を追加

- ヒーロー文言を「5 分で AlphaForge を動かす」に刷新
- ヒーロー直下とトラブルシューティング表後に Docs 誘導 callout を追加
- 前提条件 OS リスト、手動インストールタブ、INSTALL_DIR callout、
  ライセンス認証の 3 ステップ展開、アンインストールセクションを削除
- 詳細は /{ja,en}/docs/getting-started/ へリンク（MkDocs を正本に）

Refs #56"
```

期待: コミット成功、`templates/install.html.j2` が 1 ファイル変更として記録される。

```bash
git log --oneline -3
```

期待: 最新コミットが上記メッセージで記録されている。

---

## Task 9: build.py を実行してビルド成果物を再生成 → コミット 2

**Files:**
- Generate: `ja/install.html`
- Generate: `en/install.html`

- [ ] **Step 1: build.py を実行**

```bash
uv run python build.py
```

期待出力（順不同で各 ✓ 行が確認できる）:
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

エラーが出た場合は build.py の依存（`yaml`, `jinja2`）が `uv sync --dev` で揃っているか確認する。

- [ ] **Step 2: install.html 以外のページが偶発的に変わっていないか確認**

```bash
git diff --stat ja/ en/ robots.txt sitemap.xml
```

期待: `ja/install.html` と `en/install.html` のみが変更ファイルに含まれること。他のページ（index.html, docs.html, tutorial-strategy.html, privacy.html, terms.html）と robots.txt / sitemap.xml に差分が無いこと。

もし他ページに変更があればテンプレ編集での副作用なので調査する（基本的には起きないはずだが、念のため確認）。

- [ ] **Step 3: ja/install.html の構造確認**

```bash
grep -c 'btn-primary' ja/install.html
```

期待: `2`（上下の Docs 誘導 callout）。

```bash
grep -c '/ja/docs/getting-started/' ja/install.html
```

期待: `2`。

```bash
grep -c '5 分で AlphaForge を動かす' ja/install.html
```

期待: `1`。

```bash
grep -c '前提条件\|アンインストール\|手動インストール\|INSTALL_DIR' ja/install.html
```

期待: `0`（削除セクション関連の文字列が完全に消えている）。

```bash
grep -c '"@context"' ja/install.html
```

期待: `1`（JSON-LD が無傷）。

```bash
grep -c 'hreflang=' ja/install.html
```

期待: `3`（ja, en, x-default）。

- [ ] **Step 4: en/install.html の構造確認**

```bash
grep -c 'btn-primary' en/install.html
```

期待: `2`。

```bash
grep -c '/en/docs/getting-started/' en/install.html
```

期待: `2`。

```bash
grep -c 'Get AlphaForge Running in 5 Minutes' en/install.html
```

期待: `1`。

```bash
grep -c 'Requirements\|Uninstall\|Manual</div>\|INSTALL_DIR' en/install.html
```

期待: `0`。

```bash
grep -c '"@context"' en/install.html
```

期待: `1`。

- [ ] **Step 5: ローカルブラウザ確認（手動）**

```bash
open ja/install.html
```

検証項目（ブラウザで目視）:
- ヒーロー h1 が「5 分で AlphaForge を動かす」になっている
- ヒーロー直下に Docs 誘導 callout（accent ボーダーの枠 + 黄色塊ボタン）が表示される
- ボタン「ドキュメントを開く →」をクリック → `/ja/docs/getting-started/` へ遷移する（GitHub Pages 公開後に有効）
- 「クイックインストール」見出しの下に macOS/Linux と Windows の 2 タブのみ表示
- タブ切替（クリック）が動作する
- 「ライセンス認証」が 1 段落 + 1 コマンドだけのシンプル構造
- 「トラブルシューティング」表が 3 行表示される
- 表の下に Docs 誘導 callout（下）が表示される
- その下に Support callout（メールリンク）が表示される
- ヘッダー / フッターが正常表示
- アンインストールセクションが表示されない
- 全体がスクロール量が大幅に減少している

```bash
open en/install.html
```

同等項目を英語版で確認。

- [ ] **Step 6: ビルド成果物をステージング & コミット**

```bash
git add ja/install.html en/install.html
git status
git commit -m "chore: install.html の build.py 出力を再生成

templates/install.html.j2 の簡素化に伴うビルド成果物の更新。

Refs #56"
```

期待: コミット成功、ja/install.html と en/install.html の 2 ファイルが変更として記録される。

```bash
git log --oneline -5
```

期待: 直近 2 コミット（Task 8 のテンプレコミット + Task 9 のビルド成果物コミット）が記録されている。

---

## Task 10: PR 作成

**Files:**
- 変更なし（GitHub PR 作成のみ）

- [ ] **Step 1: ローカル状態確認**

```bash
git status
```

期待: `On branch feat/docs-issue-56-install-html-slim`、working tree clean。

```bash
git log --oneline main..HEAD
```

期待: 3 コミット（spec / テンプレ編集 / ビルド成果物）が確認できる。

- [ ] **Step 2: リモートに push**

```bash
git push -u origin feat/docs-issue-56-install-html-slim
```

期待: 新規ブランチが GitHub に push される。

- [ ] **Step 3: PR 作成**

```bash
gh pr create --title "feat: install.html を簡素化し MkDocs への導線を追加 (#56)" --body "$(cat <<'EOF'
## Summary

- \`templates/install.html.j2\` を簡素化し、ヒーロー / クイックインストール / ライセンス認証 / 主要トラブルシューティングのみを残す
- ヒーロー直下とトラブルシューティング表後の 2 箇所に MkDocs 公式ドキュメントへの誘導 callout を追加
- 前提条件 OS リスト・手動インストールタブ・INSTALL_DIR callout・ライセンス認証 3 ステップ展開・アンインストールセクションを削除（詳細は \`/{ja,en}/docs/getting-started/\` を正本に）

## 設計ドキュメント

\`docs/superpowers/specs/2026-04-30-alforge-labs-issue-56-install-html-slim-design.md\`

## Test plan

- [x] \`uv run python build.py\` が正常終了し \`{ja,en}/install.html\` のみが再生成される
- [x] \`grep -c 'btn-primary' ja/install.html\` が \`2\` を返す
- [x] \`grep -c '/ja/docs/getting-started/' ja/install.html\` が \`2\` を返す
- [x] \`grep -c '前提条件\\|アンインストール\\|手動インストール\\|INSTALL_DIR' ja/install.html\` が \`0\` を返す
- [x] JSON-LD と hreflang が維持されている
- [x] ブラウザでヒーロー / タブ切替 / Docs 誘導ボタン / トラブルシューティング表が正常表示
- [x] en 側も同等の構造で動作

## SEO 影響評価

- \`seo.yaml\` の install ページコピーは無変更
- \`sitemap.xml\` の install エントリ priority/changefreq 維持
- JSON-LD（BreadcrumbList）は build.py で動的生成、構造変更なし
- hreflang リンク（ja / en / x-default）維持

Closes #56
EOF
)"
```

期待: PR 番号と URL が表示される。

- [ ] **Step 4: PR が CI を通過するか確認（GitHub Pages のみ）**

```bash
gh pr view --json number,url,state,statusCheckRollup
```

期待: PR がオープン状態、check が pass または skip（このリポジトリは GitHub Pages のみで自動 CI が無いはず）。

- [ ] **Step 5: ユーザーレビュー後、squash マージ & ブランチ削除**

ユーザーから「マージして」確認を受けたあとに実行:

```bash
gh pr merge <PR_NUMBER> --squash --delete-branch
git checkout main
git pull origin main
git log --oneline -3
```

期待: PR が squash merge され、`feat/docs-issue-56-install-html-slim` ブランチがリモート / ローカル両方から削除される。main の最新コミットに #56 の squash commit が含まれる。

---

## Self-Review

### Spec coverage

| Spec 要件 | 対応タスク |
|---|---|
| ヒーロー: 「AlphaForge を 5 分で動かす」 | Task 1 |
| Docs 誘導 callout（上） | Task 2 |
| 前提条件 OS リスト削除 | Task 3 |
| クイックインストール: 2 タブに簡素化 | Task 4 |
| 手動インストールタブ削除 | Task 4 |
| INSTALL_DIR callout 削除 | Task 4 |
| ライセンス認証: 1 ブロックに簡素化 | Task 5 |
| アンインストールセクション削除 | Task 6 |
| Docs 誘導 callout（下） | Task 7 |
| 主要トラブルシューティング 3 件維持 | （既存維持、削除タスク無し） |
| サポートメール callout 維持 | （既存維持、削除タスク無し） |
| build.py で再生成 | Task 9 |
| `seo.yaml` 無変更 | （タスク内で触らない） |
| `page.css` 無変更 | （タスク内で触らない） |
| JSON-LD / hreflang 維持 | Task 9 Step 3-4 で grep 検証 |
| 2 コミット粒度 | Task 8（テンプレ）+ Task 9（成果物） |
| PR タイトル / Closes #56 | Task 10 |

すべての spec 要件にタスクがマッピングされている。ギャップなし。

### Placeholder scan

- [x] "TBD" / "TODO" / "implement later" / "fill in details" — なし
- [x] 各 Edit の old_string / new_string は完全に明示している
- [x] 検証用 grep コマンドは具体値で記述
- [x] PR 本文 HEREDOC も実テキストで完成している

### Type / signature 一貫性

- [x] ヒーロー文言（Task 1 と Task 2 の old_string）が一致している
- [x] Quick Install 見出し（Task 3 で生成、Task 4 で参照）の表記が一致
- [x] Docs 誘導 callout の URL（`/ja/docs/getting-started/` / `/en/docs/getting-started/`）が Task 2 / Task 7 / Task 9 で一貫
- [x] `.btn-primary` / `.callout` の class 名が全タスクで統一
