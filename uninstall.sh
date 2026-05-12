#!/usr/bin/env bash
# AlphaForge forge アンインストーラー / AlphaForge forge uninstaller
# Usage:
#   bash <(curl -sSL https://alforge-labs.github.io/uninstall.sh)
#   bash <(curl -sSL https://alforge-labs.github.io/uninstall.sh) --dry-run
#   bash <(curl -sSL https://alforge-labs.github.io/uninstall.sh) --purge
#
#   # INSTALL_DIR でインストールした場合は同じ env var で位置を伝える
#   INSTALL_DIR=/opt/forge/bin bash <(curl -sSL https://alforge-labs.github.io/uninstall.sh)
#
#   # 表示言語を明示指定（自動判定をオーバーライド）
#   FORGE_INSTALL_LOCALE=en bash <(curl -sSL https://alforge-labs.github.io/uninstall.sh)
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

# ── 0. ロケール判定（install.sh と同じロジック）─────────────────────
FORGE_LOCALE="en"
case "${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}" in
  ja|ja_*|ja.*) FORGE_LOCALE="ja" ;;
esac
case "${FORGE_INSTALL_LOCALE:-}" in
  ja|en) FORGE_LOCALE="${FORGE_INSTALL_LOCALE}" ;;
esac

lang() {
  if [ "${FORGE_LOCALE}" = "ja" ]; then
    printf '%s' "$1"
  else
    printf '%s' "$2"
  fi
}

DRY_RUN=false
PURGE=false
INSTALL_DIR_FROM_ENV="${INSTALL_DIR:-}"

usage() {
  if [ "${FORGE_LOCALE}" = "ja" ]; then
    cat <<'USAGE_JA'
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
  FORGE_INSTALL_LOCALE
               表示言語を明示指定する（ja または en）。未指定なら LANG /
               LC_ALL から自動判定する。

デフォルトでは認証情報を残します。後で同じ forge を再インストールしたい場合、
再認証 (forge system auth login) を省略できます。
USAGE_JA
  else
    cat <<'USAGE_EN'
AlphaForge forge uninstaller

Usage:
  bash <(curl -sSL https://alforge-labs.github.io/uninstall.sh) [OPTIONS]

Options:
  --dry-run  Show what would be removed without actually removing anything
  --purge    Also remove auth credentials (~/.config/forge/) and legacy
             config (~/.forge/)
  -h, --help Show this help

Environment variables:
  INSTALL_DIR  If install.sh was run with INSTALL_DIR, pass the same value
               to locate the symlink. If unset, ~/.local/bin and
               /usr/local/bin are auto-detected.
  FORGE_INSTALL_LOCALE
               Force display language (ja or en). If unset, detected from
               LANG / LC_ALL.

Auth credentials are preserved by default. If you plan to re-install later,
this lets you skip re-authentication (forge system auth login).
USAGE_EN
  fi
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --purge)   PURGE=true ;;
    -h|--help) usage; exit 0 ;;
    *)
      printf "  ✗ %s: %s\n\n" "$(lang "未知のオプション" "Unknown option")" "$arg" >&2
      usage
      exit 1
      ;;
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
    info "$(lang "sudo で削除します" "Removing with sudo"): ${target}"
    sudo ${rm_cmd} "${target}"
  fi
  ok "$(lang "削除" "Removed"): ${target}"
}

# ── 1. インストール先を検出して symlink + forge.dist を削除 ───────
echo "=== $(lang "AlphaForge アンインストール" "AlphaForge uninstall") ==="
if [ "${DRY_RUN}" = "true" ]; then
  echo "$(lang "[dry-run] 実際には削除しません" "[dry-run] Nothing will be removed")"
fi
echo ""

if [ -n "${INSTALL_DIR_FROM_ENV}" ]; then
  # INSTALL_DIR が明示指定された場合はそこのみを対象にする。
  # tilde は呼び出し shell で展開されないことがあるので明示的に置換。
  case "${INSTALL_DIR_FROM_ENV}" in
    "~"|"~/"*) BIN_CANDIDATES=("${HOME}${INSTALL_DIR_FROM_ENV#"~"}") ;;
    *)         BIN_CANDIDATES=("${INSTALL_DIR_FROM_ENV}") ;;
  esac
  echo "$(lang "INSTALL_DIR 環境変数による探索" "Searching from INSTALL_DIR environment variable"): ${BIN_CANDIDATES[0]}"
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

  echo "$(lang "見つけたインストール" "Found installation"):"
  echo "  symlink:    ${symlink}"
  if [ -L "${symlink}" ]; then
    echo "  → $(lang "実体" "target"):     $(readlink "${symlink}")"
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
      info "$(lang "古いバックアップを削除" "Removing old backup"): ${bak}"
      maybe_sudo_rm "${bak}" "dir"
    fi
  done

  removed_count=$((removed_count + 1))
  echo ""
done

if [ "${removed_count}" -eq 0 ]; then
  warn "$(lang "forge シンボリックリンクが見つかりませんでした (${BIN_CANDIDATES[*]} を確認)" \
                "No forge symlink found (checked: ${BIN_CANDIDATES[*]})")"
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
    echo "$(lang "PATH 行を ${rc} から削除します" "Removing PATH entry from ${rc}")"
    if [ "${DRY_RUN}" = "true" ]; then
      echo "      [dry-run] sed -i '/# AlphaForge forge/,+1d' ${rc}"
      grep -n "# AlphaForge forge" "${rc}" || true
    else
      # コメント行と次行 (export PATH=...) をセットで削除。
      # macOS 標準 sed (BSD sed) 互換のため -i に拡張子を渡す。
      cp "${rc}" "${rc}.alpha-forge-uninstall.bak"
      sed -i.tmp '/# AlphaForge forge/,+1d' "${rc}"
      rm -f "${rc}.tmp"
      ok "$(lang "削除: ${rc} の PATH 行 (バックアップ: ${rc}.alpha-forge-uninstall.bak)" \
                  "Removed PATH entry from ${rc} (backup: ${rc}.alpha-forge-uninstall.bak)")"
    fi
  fi
done

# ── 3. --purge: 認証・設定ディレクトリも削除 ──────────────────────
if [ "${PURGE}" = "true" ]; then
  echo ""
  echo "$(lang "--purge: 認証・設定ディレクトリも削除します" \
                "--purge: removing auth and config directories as well")"
  PURGE_PATHS=(
    "${HOME}/.config/forge"     # credentials.json (Whop OAuth) + eula.json
    "${HOME}/.forge"            # legacy 旧パス
  )
  for p in "${PURGE_PATHS[@]}"; do
    if [ -d "${p}" ]; then
      echo "  $(lang "対象" "Target"): ${p}"
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
echo "=== $(lang "アンインストール完了" "Uninstall complete") ==="
if [ "${DRY_RUN}" = "true" ]; then
  echo "  $(lang "--dry-run のため実際には削除されていません。" \
                  "--dry-run was specified; nothing was actually removed.")"
  echo "  $(lang "実行するには" "To actually run"): bash <(curl -sSL https://alforge-labs.github.io/uninstall.sh)"
else
  if [ "${PURGE}" = "false" ]; then
    echo "  $(lang "認証情報 (~/.config/forge/credentials.json) は残してあります。" \
                    "Auth credentials (~/.config/forge/credentials.json) are preserved.")"
    echo "  $(lang "完全削除する場合" "For full removal"): bash <(curl -sSL https://alforge-labs.github.io/uninstall.sh) --purge"
  fi
  echo ""
  echo "  $(lang "ユーザー作業ディレクトリ (forge system init で生成された forge.yaml や data/) は" \
                  "User project directories (forge.yaml / data/ created by forge system init) are")"
  echo "  $(lang "保護対象外のため、必要なら手動で削除してください。" \
                  "not removed automatically; delete them manually if needed.")"
  echo ""
  case "${SHELL_NAME}" in
    zsh)  echo "  $(lang "シェルへ反映: source ~/.zshrc (または 'rehash' / 新しいターミナル)" \
                          "Apply to shell: source ~/.zshrc (or 'rehash' / open a new terminal)")" ;;
    bash) echo "  $(lang "シェルへ反映: source ~/.bashrc (または 'hash -r' / 新しいターミナル)" \
                          "Apply to shell: source ~/.bashrc (or 'hash -r' / open a new terminal)")" ;;
  esac
fi
