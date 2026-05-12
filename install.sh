#!/usr/bin/env bash
# AlphaForge forge インストーラー
# Usage:
#   bash <(curl -sSL https://alforge-labs.github.io/install.sh)
#   bash <(curl -sSL https://alforge-labs.github.io/install.sh) --dry-run
#
# 実装メモ:
#   - Nuitka standalone ビルドの forge.dist/ は forge バイナリ + 1100+ の dylib /
#     データファイルから成り、forge は @executable_path 相対で同居 dylib を
#     ロードする。よってバイナリ単体ではなく forge.dist/ ディレクトリ全体を
#     インストール先に置き、forge を symlink で PATH に通すレイアウトを取る。
#   - macOS Gatekeeper は curl 経由 DL に com.apple.quarantine xattr を付ける
#     ので、未署名バイナリの抑止解除のため xattr -dr で除去する。
#   - curl | bash 経由実行では stdin がスクリプト本文に占有されているため、
#     対話 read は </dev/tty で TTY 直結する。

set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "[dry-run] 実際のインストールは行いません。"
fi

REPO="alforge-labs/alforge-labs.github.io"

# bin: 実行ファイル symlink を置く場所 (PATH に通っているべき)
DEFAULT_BIN_DIR="${HOME}/.local/bin"
BIN_DIR=""

# lib: forge.dist/ 配下の全ファイルを置く場所 (バイナリ + dylib + データ)
# bin 配下に「forge.dist」名で展開し、forge -> forge.dist/forge の symlink を貼る
DIST_NAME="forge.dist"

ok()   { echo "  ✓ $*"; }
info() { echo "  → $*"; }
fail() { printf "  ✗ %b\n" "$*" >&2; exit 1; }

# curl | bash の stdin はスクリプト本文に占有されているため、対話読みは TTY 直結。
# TTY が無い (CI 等) なら空文字を返してデフォルトにフォールバック。
prompt_tty() {
  local prompt_msg=$1
  local reply=""
  # /dev/tty が無い・読めない環境（CI, --no-tty 等）では即フォールバック。
  # bash のリダイレクト失敗は read 単体への 2>/dev/null では捕まらないため、
  # ブロック全体を { ... } 2>/dev/null で囲む。
  # shellcheck disable=SC2229
  { read -r -p "${prompt_msg}" reply </dev/tty; } 2>/dev/null || reply=""
  printf '%s' "${reply}"
}

# ── 1. OS + アーキテクチャ検出 ──────────────────────────────────
OS="$(uname -s)"
ARCH="$(uname -m)"

case "${OS}-${ARCH}" in
  Darwin-arm64)  ARTIFACT="forge-macos-arm64"; EXT="tar.gz" ;;
  Darwin-x86_64) ARTIFACT="forge-macos-x64";   EXT="tar.gz" ;;
  *) fail "未対応プラットフォーム: ${OS}-${ARCH}。対応: macOS arm64, macOS x86_64" ;;
esac

info "プラットフォーム: ${OS}-${ARCH} → ${ARTIFACT}"

# ── 2. 最新バージョンを取得 ─────────────────────────────────────
info "最新バージョンを確認中..."
if ! command -v curl >/dev/null 2>&1; then
  fail "curl がインストールされていません。インストール後に再実行してください。"
fi

VERSION="$(curl -sSfL "https://api.github.com/repos/${REPO}/releases/latest" \
  2>/dev/null | grep '"tag_name"' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')" || true

if [ -z "${VERSION}" ]; then
  if [ "${DRY_RUN}" = "true" ]; then
    VERSION="vX.Y.Z（dry-run: バージョン未取得）"
    info "バージョン取得できませんでした（dry-run のため続行）"
  else
    fail "バージョン取得に失敗しました。ネットワーク接続を確認してください。\n  https://github.com/${REPO}/releases"
  fi
fi

ok "最新バージョン: ${VERSION}"

DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${ARTIFACT}.${EXT}"

# 既存バイナリのバージョン確認
if command -v forge >/dev/null 2>&1; then
  CURRENT_VER="$(forge --version 2>/dev/null | head -1)" || CURRENT_VER=""
  if [ -n "${CURRENT_VER}" ]; then
    info "現在のバージョン: ${CURRENT_VER} → ${VERSION} に更新します"
  fi
fi

# ── 3. ダウンロード & 展開 ─────────────────────────────────────
TMP_DIR="$(mktemp -d /tmp/forge-install.XXXXXX)"
trap 'rm -rf "${TMP_DIR}"' EXIT

if [ "${DRY_RUN}" = "false" ]; then
  info "ダウンロード中: ${DOWNLOAD_URL}"
  curl -sSfL "${DOWNLOAD_URL}" -o "${TMP_DIR}/archive.${EXT}" \
    || fail "ダウンロードに失敗しました。\n  ${DOWNLOAD_URL}"
  tar xzf "${TMP_DIR}/archive.${EXT}" -C "${TMP_DIR}"
  if [ ! -d "${TMP_DIR}/forge.dist" ]; then
    fail "展開後に forge.dist ディレクトリが見つかりません"
  fi
  if [ ! -x "${TMP_DIR}/forge.dist/forge" ]; then
    fail "展開後に forge.dist/forge が実行可能ファイルでありません"
  fi
  ok "ダウンロード・展開完了"
else
  echo "  [dry-run] curl -L ${DOWNLOAD_URL} → tar xzf → ${TMP_DIR}/forge.dist/"
fi

# ── 4. macOS Gatekeeper の quarantine 属性を除去 ─────────────────
# curl 経由でダウンロードしたバイナリには com.apple.quarantine xattr が付き、
# 未署名のため起動時 Abort trap: 6 で必ず死ぬ。展開直後に除去しておく。
if [ "${DRY_RUN}" = "false" ] && [ "${OS}" = "Darwin" ]; then
  if command -v xattr >/dev/null 2>&1; then
    xattr -dr com.apple.quarantine "${TMP_DIR}/forge.dist" 2>/dev/null || true
    ok "macOS quarantine 属性を除去しました"
  fi
fi

# ── 5. インストール先を確定 ──────────────────────────────────────
echo ""
echo "インストール先を選択してください（デフォルト: ${DEFAULT_BIN_DIR}）"
if [ "${DRY_RUN}" = "true" ]; then
  BIN_DIR="${DEFAULT_BIN_DIR}"
  echo "  [dry-run] インストール先: ${BIN_DIR}（デフォルト）"
else
  REPLY="$(prompt_tty "  /usr/local/bin にインストールしますか？ [y/N] ")"
  if [[ "${REPLY}" =~ ^[Yy]$ ]]; then
    BIN_DIR="/usr/local/bin"
  else
    BIN_DIR="${DEFAULT_BIN_DIR}"
  fi
fi

# forge.dist の同居先（bin と同階層）。ここに 1100+ ファイル一式を展開する。
DIST_DIR="$(dirname "${BIN_DIR}")/share/alpha-forge/${DIST_NAME}"
SYMLINK_PATH="${BIN_DIR}/forge"

# ── 6. インストール ──────────────────────────────────────────────
if [ "${DRY_RUN}" = "false" ]; then
  info "forge.dist 全体を ${DIST_DIR} に展開します"
  if ! mkdir -p "${BIN_DIR}" 2>/dev/null; then
    info "sudo で ${BIN_DIR} を作成します..."
    sudo mkdir -p "${BIN_DIR}"
  fi
  if ! mkdir -p "$(dirname "${DIST_DIR}")" 2>/dev/null; then
    info "sudo で $(dirname "${DIST_DIR}") を作成します..."
    sudo mkdir -p "$(dirname "${DIST_DIR}")"
  fi

  # 既存 install があれば一旦退避してアトミックに置換（途中失敗時の救済余地）
  if [ -d "${DIST_DIR}" ]; then
    BACKUP="${DIST_DIR}.bak.$$"
    info "既存インストール (${DIST_DIR}) を ${BACKUP} に退避"
    if [ -w "$(dirname "${DIST_DIR}")" ]; then
      mv "${DIST_DIR}" "${BACKUP}"
    else
      sudo mv "${DIST_DIR}" "${BACKUP}"
    fi
  fi

  # cp -R の方が dotfiles を含めて素直にコピーできる
  if [ -w "$(dirname "${DIST_DIR}")" ]; then
    cp -R "${TMP_DIR}/forge.dist" "${DIST_DIR}"
  else
    info "sudo でコピーします..."
    sudo cp -R "${TMP_DIR}/forge.dist" "${DIST_DIR}"
  fi

  # quarantine 属性が再付与されることがあるので念のためインストール先でも除去
  if [ "${OS}" = "Darwin" ] && command -v xattr >/dev/null 2>&1; then
    xattr -dr com.apple.quarantine "${DIST_DIR}" 2>/dev/null \
      || sudo xattr -dr com.apple.quarantine "${DIST_DIR}" 2>/dev/null \
      || true
  fi

  # symlink を BIN_DIR/forge に貼る（既存ファイル・symlink は ln -sfn で上書き）
  if [ -w "${BIN_DIR}" ]; then
    ln -sfn "${DIST_DIR}/forge" "${SYMLINK_PATH}"
  else
    info "sudo で symlink を貼ります..."
    sudo ln -sfn "${DIST_DIR}/forge" "${SYMLINK_PATH}"
  fi

  ok "forge を ${SYMLINK_PATH} に配置しました (実体: ${DIST_DIR}/forge)"

  # 古いバックアップは成功後にクリーンアップ
  if [ -n "${BACKUP:-}" ] && [ -d "${BACKUP}" ]; then
    if [ -w "$(dirname "${BACKUP}")" ]; then
      rm -rf "${BACKUP}"
    else
      sudo rm -rf "${BACKUP}"
    fi
  fi
else
  echo "  [dry-run] cp -R forge.dist → ${DIST_DIR}"
  echo "  [dry-run] ln -sfn ${DIST_DIR}/forge → ${SYMLINK_PATH}"
fi

# ── 7. PATH 自動追記 ─────────────────────────────────────────────
SHELL_NAME="$(basename "${SHELL:-bash}")"
case "${SHELL_NAME}" in
  zsh)  RC="${HOME}/.zshrc" ;;
  fish) RC="${HOME}/.config/fish/config.fish" ;;
  *)    RC="${HOME}/.bashrc" ;;
esac

if [[ ":${PATH}:" != *":${BIN_DIR}:"* ]]; then
  PATH_LINE="export PATH=\"${BIN_DIR}:\${PATH}\""

  if [ "${DRY_RUN}" = "false" ]; then
    if ! grep -qF "${BIN_DIR}" "${RC}" 2>/dev/null; then
      printf '\n# AlphaForge forge\n%s\n' "${PATH_LINE}" >> "${RC}"
      ok "PATH を ${RC} に追記しました"
    else
      ok "PATH はすでに ${RC} に設定済みです"
    fi
  else
    echo "  [dry-run] echo '${PATH_LINE}' >> ${RC}"
  fi
else
  ok "PATH はすでに設定済みです"
fi

# ── 8. 動作確認（フルパス実行で dylib 解決を検証）─────────────────
echo ""
if [ "${DRY_RUN}" = "false" ]; then
  if "${SYMLINK_PATH}" --version >/dev/null 2>&1; then
    ok "インストール完了！ ($(${SYMLINK_PATH} --version))"
  else
    fail "forge コマンドの動作確認に失敗しました。\n  手動確認: ${SYMLINK_PATH} --version\n  問題が続く場合: $(${SYMLINK_PATH} --version 2>&1 | head -5)"
  fi
else
  ok "ドライランが完了しました。実際にインストールするには --dry-run を外して再実行してください。"
fi

# ── 9. ライセンス認証の案内（forge system auth login）────────────
echo ""
echo "次のステップ: ライセンス認証"
echo "  AlphaForge は Whop OAuth でライセンス認証を行います。"
echo "  以下のコマンドを実行するとブラウザが開き、Whop で購入したアカウントで認証できます："
echo ""
echo "      forge system auth login"
echo ""
echo "  認証状態を確認:"
echo "      forge system auth status"

# ── 10. シェルへの反映案内 ──────────────────────────────────────
echo ""
if [ "${DRY_RUN}" = "false" ]; then
  # 現在のシェルから PATH を反映するための手順
  if [[ ":${PATH}:" != *":${BIN_DIR}:"* ]]; then
    echo "PATH を現在のシェルに反映するには、次のいずれかを実行してください："
    echo "    source ${RC}"
    case "${SHELL_NAME}" in
      zsh)  echo "    # または: rehash (zsh のコマンドハッシュをクリア)" ;;
      bash) echo "    # または: hash -r (bash のコマンドハッシュをクリア)" ;;
    esac
    echo "    # または新しいターミナルを開く"
  else
    # 既に PATH に入っているが、シェルのコマンドキャッシュが古い場合に備えて案内
    case "${SHELL_NAME}" in
      zsh)  echo "現在のシェルで forge が見つからない場合は 'rehash' を実行してください。" ;;
      bash) echo "現在のシェルで forge が見つからない場合は 'hash -r' を実行してください。" ;;
    esac
  fi
  echo ""
  echo "使い方: forge --help"
  echo ""
  echo "アンインストールするには:"
  echo "    bash <(curl -sSL https://alforge-labs.github.io/uninstall.sh)"
  echo "    # 認証情報も完全削除する場合: --purge オプション"
fi
