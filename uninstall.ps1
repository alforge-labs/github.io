#Requires -Version 5.1
<#
.SYNOPSIS
    AlphaForge forge の Windows アンインストーラー

.DESCRIPTION
    新レイアウト (%LOCALAPPDATA%\Programs\alpha-forge\) を優先的に削除し、
    旧レイアウト ($HOME\bin\forge.exe / C:\Program Files\forge\forge.exe)
    も検出次第クリーンアップする。User PATH からも該当エントリを除去する。

    -Yes スイッチで対話確認をスキップする。
    -Purge スイッチで認証キャッシュ (~\.config\forge\credentials.json) も削除する。

.EXAMPLE
    irm https://alforge-labs.github.io/uninstall.ps1 | iex

.EXAMPLE
    & ([scriptblock]::Create((irm https://alforge-labs.github.io/uninstall.ps1))) -Yes -Purge

.NOTES
    Issue alforge-labs/alforge-labs.github.io#251 で新レイアウトに対応。
#>
param(
    [switch]$Yes,
    [switch]$Purge
)

$ErrorActionPreference = "Stop"

$INSTALL_ROOT      = Join-Path $env:LOCALAPPDATA "Programs\alpha-forge"
$DIST_DIR          = Join-Path $INSTALL_ROOT "forge.dist"
$LAUNCHER          = Join-Path $INSTALL_ROOT "alpha-forge.cmd"
$OLD_LAUNCHER      = Join-Path $INSTALL_ROOT "forge.cmd"  # v0.4.x 以下からの移行残骸
$OLD_USER_BIN      = Join-Path $HOME "bin\forge.exe"
$OLD_USER_BIN_DIR  = Join-Path $HOME "bin"
$OLD_PROGRAM_FILES = "C:\Program Files\forge\forge.exe"
$OLD_PROGRAM_DIR   = "C:\Program Files\forge"
$CRED_PATH         = Join-Path $HOME ".config\forge\credentials.json"

function Write-Ok   { param($msg) Write-Host "  ✓ $msg" -ForegroundColor Green }
function Write-Info { param($msg) Write-Host "  → $msg" }
function Write-Warn { param($msg) Write-Host "  ⚠ $msg" -ForegroundColor Yellow }

# 検出対象を整理
$found = @()
if (Test-Path $INSTALL_ROOT)      { $found += "新レイアウト: $INSTALL_ROOT" }
if (Test-Path $OLD_USER_BIN)      { $found += "旧 user-bin : $OLD_USER_BIN" }
if (Test-Path $OLD_PROGRAM_FILES) { $found += "旧 Program Files: $OLD_PROGRAM_FILES" }

if ($found.Count -eq 0) {
    Write-Warn "forge のインストールが見つかりません。"
    exit 0
}

Write-Host "アンインストール対象:"
$found | ForEach-Object { Write-Host "    - $_" }
Write-Host ""
Write-Host "重要: 認証情報を Whop 側のセッションから外したい場合は、削除前に以下を実行してください:" -ForegroundColor Yellow
Write-Host "    forge system auth logout" -ForegroundColor Cyan
Write-Host ""

if (-not $Yes) {
    $CONFIRMED = Read-Host "上記をすべて削除しますか? [y/N]"
    if ($CONFIRMED -notmatch "^[yY]") {
        Write-Host "アンインストールをキャンセルしました。"
        exit 0
    }
}

# ── 新レイアウト削除 ─────────────────────────────────────────────
if (Test-Path $INSTALL_ROOT) {
    try {
        Remove-Item -Path $INSTALL_ROOT -Recurse -Force
        Write-Ok "削除: $INSTALL_ROOT"
    } catch {
        Write-Warn "$INSTALL_ROOT の削除に失敗しました: $_"
    }
}

# ── 旧 user-bin 削除 ─────────────────────────────────────────────
if (Test-Path $OLD_USER_BIN) {
    try {
        Remove-Item -Path $OLD_USER_BIN -Force
        Write-Ok "削除: $OLD_USER_BIN"
        # 空なら親 dir も削除（混在の可能性があるので空のときだけ）
        if ((Test-Path $OLD_USER_BIN_DIR) -and -not (Get-ChildItem -Path $OLD_USER_BIN_DIR -Force | Select-Object -First 1)) {
            Remove-Item -Path $OLD_USER_BIN_DIR -Force
            Write-Ok "空ディレクトリを削除: $OLD_USER_BIN_DIR"
        }
    } catch {
        Write-Warn "$OLD_USER_BIN の削除に失敗しました: $_"
    }
}

# ── 旧 Program Files 削除（要管理者権限）─────────────────────────
if (Test-Path $OLD_PROGRAM_FILES) {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
    if (-not $isAdmin) {
        Write-Warn "$OLD_PROGRAM_DIR の削除には管理者権限が必要です。PowerShell を管理者として起動して以下を実行してください:"
        Write-Host "    Remove-Item -Recurse -Force '$OLD_PROGRAM_DIR'"
    } else {
        try {
            Remove-Item -Path $OLD_PROGRAM_DIR -Recurse -Force
            Write-Ok "削除: $OLD_PROGRAM_DIR"
        } catch {
            Write-Warn "$OLD_PROGRAM_DIR の削除に失敗しました: $_"
        }
    }
}

# ── User PATH からエントリ除去 ───────────────────────────────────
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath) {
    $pathEntries = $currentPath -split ";" | Where-Object {
        $_ -ne "" -and
        $_ -ne $INSTALL_ROOT -and
        $_ -ne $OLD_PROGRAM_DIR -and
        $_ -ne $OLD_USER_BIN_DIR
    }
    $newPath = ($pathEntries -join ";")
    if ($newPath -ne $currentPath) {
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        Write-Ok "User PATH から forge 関連エントリを削除しました"
    }
}

# ── 認証キャッシュの扱い ─────────────────────────────────────────
if ($Purge -and (Test-Path $CRED_PATH)) {
    try {
        Remove-Item -Path $CRED_PATH -Force
        Write-Ok "認証キャッシュを削除: $CRED_PATH"
    } catch {
        Write-Warn "$CRED_PATH の削除に失敗しました: $_"
    }
} elseif (Test-Path $CRED_PATH) {
    Write-Info "認証キャッシュは保持されました: $CRED_PATH"
    Write-Host "    再インストール時に forge system auth login をやり直さずに済みます。"
    Write-Host "    完全削除するには -Purge を付けて再実行してください。"
}

Write-Host ""
Write-Ok "アンインストールが完了しました。"
