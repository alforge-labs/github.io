#!/usr/bin/env bash
# AlphaForge forge アンインストーラー
# Usage:
#   bash <(curl -sSL https://alforge-labs.github.io/uninstall.sh)
#   bash <(curl -sSL https://alforge-labs.github.io/uninstall.sh) --dry-run
#   bash <(curl -sSL https://alforge-labs.github.io/uninstall.sh) --purge
#
#   # INSTALL_DIR でインストールした場合は同じ env var で位置を伝える
#   INSTALL_DIR=/opt/forge/bin bash <(curl -sSL https://alforge-labs.github.io/uninstall.sh)
#
# 削除対象（デフォルト）:
#   - forge symlink: INSTALL_DIR が指定されていればそこ、それ以外は
#     ${HOME}/.local/bin/forge と /usr/local/bin/forge の両方を探索
#   - forge.dist 全体: symlink と同階層の share/alpha-forge/
#     （例: ~/.local/bin/forge に対して ~/.local/share/alpha-forge/）
#   - PATH 行 (# AlphaForge forge コメント付き): ${HOME}/.zshrc 等
#
# --purge 指定時のみ追加で削除:
#   - ${HOME}/.config/forge/ (credentials.json = Whop OAuth トークン、eula.json)
#   - ${HOME}/.forge/ (legacy 旧パス、もし存在すれば)
#
# 削除「しない」もの（ユーザー作業ディレクトリ）:
#   - forge system init で生成された forge.yaml / data/ 等のプロジェクトファイル

set -euo pipefail

DRY_RUN=false
PURGE=false
INSTALL_DIR_FROM_ENV="${INSTALL_DIR:-}"

usage() {
  cat <<'USAGE'
AlphaForge forge アンインストーラー

Usage:
  bash <(curl -sSL https://alforge-labs.github.io/uninstall.sh) [OPTIONS]

Options:
  --dry-run  削除内容を表示するだけで実際には削除しない
  --purge    認証情報 (~/.config/forge/) と legacy 設定 (~/.forge/) も削除
  -h, --help このヘルプを表示

環境変数:
  INSTALL_DIR  install.sh で INSTALL_DIR を指定してインストールした場合、
               同じ値を渡して symlink 配置場所を特定する。未指定なら
               ~/.local/bin と /usr/local/bin を自動探索する。

デフォルトでは認証情報を残します。後で同じ forge を再インストールしたい場合、
再認証 (forge system auth login) を省略できます。
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --purge)   PURGE=true ;;
    -h|--help) usage; exit 0 ;;
    *) printf "  ✗ 未知のオプション: %s\n\n" "$arg" >&2; usage; exit 1 ;;
  esac
done

ok()   { echo "  ✓ $*"; }
info() { echo "  → $*"; }
warn() { printf "  ⚠ %b\n" "$*" >&2; }
fail() { printf "  ✗ %b\n" "$*" >&2; exit 1; }

# sudo 起動が必要かどうかを判定し、必要なら sudo を前置するヘルパ
maybe_sudo_rm() {
  local target=$1
  local kind=$2   # "file" | "dir"
  if [ ! -e "${target}" ] && [ ! -L "${target}" ]; then
    return 0
  fi
  if [ "${DRY_RUN}" = "true" ]; then
    if [ "${kind}" = "dir" ]; then
      echo "      [dry-run] rm -rf ${target}"
    else
      echo "      [dry-run] rm -f ${target}"
    fi
    return 0
  fi
  local rm_cmd="rm -f"
  [ "${kind}" = "dir" ] && rm_cmd="rm -rf"
  # まず sudo なしで試す。書き込み不可なら sudo にフォールバック。
  local parent
  parent="$(dirname "${target}")"
  if [ -w "${parent}" ]; then
    ${rm_cmd} "${target}"
  else
    info "sudo で削除します: ${target}"
    sudo ${rm_cmd} "${target}"
  fi
  ok "削除: ${target}"
}

# ── 1. インストール先を検出して symlink + forge.dist を削除 ───────
echo "=== AlphaForge アンインストール ==="
[ "${DRY_RUN}" = "true" ] && echo "[dry-run] 実際には削除しません"
echo ""

if [ -n "${INSTALL_DIR_FROM_ENV}" ]; then
  # INSTALL_DIR が明示指定された場合はそこのみを対象にする。
  # tilde は呼び出し shell で展開されないことがあるので明示的に置換。
  case "${INSTALL_DIR_FROM_ENV}" in
    "~"|"~/"*) BIN_CANDIDATES=("${HOME}${INSTALL_DIR_FROM_ENV#"~"}") ;;
    *)         BIN_CANDIDATES=("${INSTALL_DIR_FROM_ENV}") ;;
  esac
  echo "INSTALL_DIR 環境変数による探索: ${BIN_CANDIDATES[0]}"
else
  BIN_CANDIDATES=("${HOME}/.local/bin" "/usr/local/bin")
fi
DIST_SUFFIX="share/alpha-forge"
removed_count=0

for bin_dir in "${BIN_CANDIDATES[@]}"; do
  symlink="${bin_dir}/forge"
  if [ ! -L "${symlink}" ] && [ ! -f "${symlink}" ]; then
    continue
  fi

  parent="$(dirname "${bin_dir}")"
  dist_dir="${parent}/${DIST_SUFFIX}"

  echo "見つけたインストール:"
  echo "  symlink:    ${symlink}"
  if [ -L "${symlink}" ]; then
    echo "  → 実体:     $(readlink "${symlink}")"
  fi
  echo "  forge.dist: ${dist_dir}"

  maybe_sudo_rm "${symlink}" "file"

  if [ -d "${dist_dir}" ]; then
    # dist_dir = ${parent}/share/alpha-forge は alpha-forge install が
    # 排他的に所有する subdirectory のため、forge.dist もろともまるごと削除する。
    # その親 (${parent}/share) は XDG 標準ディレクトリで他アプリも使うので
    # 触らない（過去に空なら削除する誤ロジックがあり修正済み）。
    maybe_sudo_rm "${dist_dir}" "dir"
  fi

  # 古い .bak.* バックアップが残っていれば一緒に掃除
  for bak in "${dist_dir}".bak.*; do
    if [ -d "${bak}" ]; then
      info "古いバックアップを削除: ${bak}"
      maybe_sudo_rm "${bak}" "dir"
    fi
  done

  removed_count=$((removed_count + 1))
  echo ""
done

if [ "${removed_count}" -eq 0 ]; then
  warn "forge シンボリックリンクが見つかりませんでした (${BIN_CANDIDATES[*]} を確認)"
fi

# ── 2. shell rc から PATH 行を削除 ────────────────────────────────
SHELL_NAME="$(basename "${SHELL:-bash}")"
case "${SHELL_NAME}" in
  zsh)  RCS=("${HOME}/.zshrc") ;;
  fish) RCS=("${HOME}/.config/fish/config.fish") ;;
  *)    RCS=("${HOME}/.bashrc" "${HOME}/.bash_profile" "${HOME}/.profile") ;;
esac

for rc in "${RCS[@]}"; do
  [ -f "${rc}" ] || continue
  if grep -q "# AlphaForge forge" "${rc}" 2>/dev/null; then
    echo "PATH 行を ${rc} から削除します"
    if [ "${DRY_RUN}" = "true" ]; then
      echo "      [dry-run] sed -i '/# AlphaForge forge/,+1d' ${rc}"
      grep -n "# AlphaForge forge" "${rc}" || true
    else
      # コメント行と次行 (export PATH=...) をセットで削除。
      # macOS 標準 sed (BSD sed) 互換のため -i に拡張子を渡す。
      cp "${rc}" "${rc}.alpha-forge-uninstall.bak"
      sed -i.tmp '/# AlphaForge forge/,+1d' "${rc}"
      rm -f "${rc}.tmp"
      ok "削除: ${rc} の PATH 行 (バックアップ: ${rc}.alpha-forge-uninstall.bak)"
    fi
  fi
done

# ── 3. --purge: 認証・設定ディレクトリも削除 ──────────────────────
if [ "${PURGE}" = "true" ]; then
  echo ""
  echo "--purge: 認証・設定ディレクトリも削除します"
  PURGE_PATHS=(
    "${HOME}/.config/forge"     # credentials.json (Whop OAuth) + eula.json
    "${HOME}/.forge"            # legacy 旧パス
  )
  for p in "${PURGE_PATHS[@]}"; do
    if [ -d "${p}" ]; then
      echo "  対象: ${p}"
      if [ "${DRY_RUN}" = "false" ]; then
        # ファイル一覧を残しておく (誤削除時の確認用)
        find "${p}" -maxdepth 2 -type f 2>/dev/null | sed 's/^/      /'
      fi
      maybe_sudo_rm "${p}" "dir"
    fi
  done
fi

# ── 4. 完了メッセージ ─────────────────────────────────────────────
echo ""
echo "=== アンインストール完了 ==="
if [ "${DRY_RUN}" = "true" ]; then
  echo "  --dry-run のため実際には削除されていません。"
  echo "  実行するには: bash <(curl -sSL https://alforge-labs.github.io/uninstall.sh)"
else
  if [ "${PURGE}" = "false" ]; then
    echo "  認証情報 (~/.config/forge/credentials.json) は残してあります。"
    echo "  完全削除する場合: bash <(curl -sSL https://alforge-labs.github.io/uninstall.sh) --purge"
  fi
  echo ""
  echo "  ユーザー作業ディレクトリ (forge system init で生成された forge.yaml や data/) は"
  echo "  保護対象外のため、必要なら手動で削除してください。"
  echo ""
  case "${SHELL_NAME}" in
    zsh)  echo "  シェルへ反映: source ~/.zshrc (または 'rehash' / 新しいターミナル)" ;;
    bash) echo "  シェルへ反映: source ~/.bashrc (または 'hash -r' / 新しいターミナル)" ;;
  esac
fi
