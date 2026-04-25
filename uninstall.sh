#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
FORGE_PATH="${INSTALL_DIR}/forge"

if [ ! -f "${FORGE_PATH}" ]; then
  echo "forge が ${FORGE_PATH} に見つかりません。インストール先を INSTALL_DIR で指定してください。"
  exit 1
fi

# ライセンスを非アクティベートしてからアンインストールするよう案内
echo "アンインストールを開始します。"
echo ""
echo "重要: ライセンスシートを解放するために、先にライセンスを非アクティベートしてください:"
echo "  forge license deactivate"
echo ""
read -r -p "非アクティベート済みですか? [y/N]: " CONFIRMED
case "${CONFIRMED}" in
  [yY]|[yY][eE][sS]) ;;
  *)
    echo "アンインストールをキャンセルしました。"
    echo "先に 'forge license deactivate' を実行してください。"
    exit 0
    ;;
esac

# 削除
if [ ! -w "${INSTALL_DIR}" ]; then
  echo "権限エラー: ${INSTALL_DIR} への書き込み権限がありません。sudo で再実行してください。"
  echo "  sudo INSTALL_DIR=${INSTALL_DIR} bash <(curl -sSL https://alforge-labs.github.io/uninstall.sh)"
  exit 1
fi

rm -f "${FORGE_PATH}"

echo ""
echo "✓ forge を ${FORGE_PATH} から削除しました"
