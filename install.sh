#!/usr/bin/env bash
# AlphaForge forge インストーラー
# Usage: bash <(curl -sSL https://alforge-labs.github.io/install.sh)
#        bash <(curl -sSL https://alforge-labs.github.io/install.sh) --dry-run
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "[dry-run] 実際のインストールは行いません。"
fi

REPO="alforge-labs/alforge-labs.github.io"
DEFAULT_INSTALL_DIR="${HOME}/.local/bin"
INSTALL_DIR=""

ok()   { echo "  ✓ $*"; }
info() { echo "  → $*"; }
fail() { printf "  ✗ %b\n" "$*" >&2; exit 1; }

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
  fail "バージョン取得に失敗しました。ネットワーク接続を確認してください。\n  https://github.com/${REPO}/releases"
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
  BINARY="${TMP_DIR}/forge.dist/forge"
  if [ ! -f "${BINARY}" ]; then
    fail "展開後にバイナリが見つかりません"
  fi
  ok "ダウンロード・展開完了"
else
  echo "  [dry-run] curl -L ${DOWNLOAD_URL} → tar xzf → ${TMP_DIR}/forge.dist/forge"
  BINARY="${TMP_DIR}/forge.dist/forge"
fi

# ── 4. インストール先を確定 ──────────────────────────────────────
echo ""
echo "インストール先を選択してください（デフォルト: ${DEFAULT_INSTALL_DIR}）"
if [ "${DRY_RUN}" = "true" ]; then
  INSTALL_DIR="${DEFAULT_INSTALL_DIR}"
  echo "  [dry-run] インストール先: ${INSTALL_DIR}（デフォルト）"
else
  read -r -p "  /usr/local/bin にインストールしますか？ [y/N] " REPLY
  if [[ "${REPLY}" =~ ^[Yy]$ ]]; then
    INSTALL_DIR="/usr/local/bin"
  else
    INSTALL_DIR="${DEFAULT_INSTALL_DIR}"
  fi
fi

if [ "${DRY_RUN}" = "false" ]; then
  mkdir -p "${INSTALL_DIR}"
  if [ -w "${INSTALL_DIR}" ]; then
    install -m 755 "${BINARY}" "${INSTALL_DIR}/forge"
  else
    info "sudo でインストールします..."
    if ! sudo install -m 755 "${BINARY}" "${INSTALL_DIR}/forge"; then
      info "sudo 失敗。${DEFAULT_INSTALL_DIR} にフォールバックします"
      INSTALL_DIR="${DEFAULT_INSTALL_DIR}"
      mkdir -p "${INSTALL_DIR}"
      install -m 755 "${BINARY}" "${INSTALL_DIR}/forge"
    fi
  fi
  ok "forge を ${INSTALL_DIR}/forge に配置しました"
else
  echo "  [dry-run] install -m 755 forge → ${INSTALL_DIR}/forge"
fi

# ── 5. PATH 自動追記 ─────────────────────────────────────────────
if [[ ":${PATH}:" != *":${INSTALL_DIR}:"* ]]; then
  SHELL_NAME="$(basename "${SHELL:-bash}")"
  case "${SHELL_NAME}" in
    zsh)  RC="${HOME}/.zshrc" ;;
    fish) RC="${HOME}/.config/fish/config.fish" ;;
    *)    RC="${HOME}/.bashrc" ;;
  esac

  PATH_LINE="export PATH=\"${INSTALL_DIR}:\${PATH}\""

  if [ "${DRY_RUN}" = "false" ]; then
    if ! grep -qF "${INSTALL_DIR}" "${RC}" 2>/dev/null; then
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

# ── 6. ライセンスアクティベーション ──────────────────────────────
echo ""
echo "ライセンスアクティベーション"
echo "  Whop でご購入のライセンスキーを入力してください。"
if [ "${DRY_RUN}" = "true" ]; then
  echo "  [dry-run] ライセンスキー入力をスキップ"
  LICENSE_KEY=""
else
  read -r -p "  ライセンスキー（Enter でスキップ）: " LICENSE_KEY
fi

if [ -n "${LICENSE_KEY}" ]; then
  if [ "${DRY_RUN}" = "false" ]; then
    if "${INSTALL_DIR}/forge" license activate "${LICENSE_KEY}"; then
      ok "ライセンス認証が完了しました"
    else
      echo "  ⚠ ライセンス認証に失敗しました。後から再実行してください:"
      echo "      forge license activate <YOUR_LICENSE_KEY>"
    fi
  else
    echo "  [dry-run] forge license activate ${LICENSE_KEY}"
  fi
else
  echo "  → スキップしました。後から実行してください:"
  echo "      forge license activate <YOUR_LICENSE_KEY>"
fi

# ── 7. 確認 ─────────────────────────────────────────────────────
echo ""
if [ "${DRY_RUN}" = "false" ]; then
  if "${INSTALL_DIR}/forge" --version >/dev/null 2>&1; then
    ok "インストール完了！"
    echo ""
    echo "  PATH を反映するには新しいターミナルを開くか、以下を実行してください:"
    echo "    source ${RC:-~/.zshrc}"
    echo ""
    echo "  使い方: forge --help"
  else
    echo "  ⚠ forge コマンドの確認に失敗しました。PATH を確認してください:"
    echo "    export PATH=\"${INSTALL_DIR}:\${PATH}\""
    echo "    forge --version"
  fi
else
  ok "ドライランが完了しました。実際にインストールするには --dry-run を外して再実行してください。"
fi
