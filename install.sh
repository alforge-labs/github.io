#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
REPO="ysakae/alpha-forge"

# OS・アーキテクチャ判定
OS="$(uname -s)"
ARCH="$(uname -m)"
case "${OS}-${ARCH}" in
  Darwin-arm64)  ARTIFACT="forge-macos-arm64" ;;
  Darwin-x86_64) ARTIFACT="forge-macos-x86_64" ;;
  Linux-x86_64)  ARTIFACT="forge-linux-x86_64" ;;
  *) echo "未対応プラットフォーム: ${OS}-${ARCH}"; exit 1 ;;
esac

# 最新バージョンを取得
VERSION="$(curl -sSL "https://api.github.com/repos/${REPO}/releases/latest" \
  | grep '"tag_name"' | cut -d '"' -f 4)"

if [ -z "${VERSION}" ]; then
  echo "エラー: リリースバージョンの取得に失敗しました。"
  exit 1
fi

echo "AlphaForge forge ${VERSION} (${ARTIFACT}) をインストールします..."

# インストール先ディレクトリが存在しない場合は作成を試みる
if [ ! -d "${INSTALL_DIR}" ]; then
  echo "${INSTALL_DIR} が存在しないため作成します..."
  mkdir -p "${INSTALL_DIR}" 2>/dev/null || {
    echo "権限エラー: sudo で再実行してください。"
    echo "  sudo INSTALL_DIR=${INSTALL_DIR} bash <(curl -sSL https://alforge-labs.github.io/install.sh)"
    exit 1
  }
fi

# ダウンロード & 配置
TMP_FILE="$(mktemp)"
trap 'rm -f "${TMP_FILE}"' EXIT

curl -sSL \
  "https://github.com/${REPO}/releases/download/${VERSION}/${ARTIFACT}" \
  -o "${TMP_FILE}"

# 書き込み権限チェック
if [ ! -w "${INSTALL_DIR}" ]; then
  echo "権限エラー: ${INSTALL_DIR} への書き込み権限がありません。sudo で再実行してください。"
  echo "  sudo INSTALL_DIR=${INSTALL_DIR} bash <(curl -sSL https://alforge-labs.github.io/install.sh)"
  exit 1
fi

cp "${TMP_FILE}" "${INSTALL_DIR}/forge"
chmod +x "${INSTALL_DIR}/forge"

echo ""
echo "✓ forge を ${INSTALL_DIR}/forge にインストールしました"
echo ""
echo "次のステップ:"
echo "  forge --version"
echo "  forge license activate <YOUR_LICENSE_KEY>"
