#Requires -Version 5.1
<#
.SYNOPSIS
    AlphaForge forge の Windows インストーラー

.DESCRIPTION
    GitHub Releases から最新の forge を取得し、$HOME\bin\forge.exe へ配置します。
    -DryRun スイッチで実際の変更なしに動作を確認できます。

.EXAMPLE
    irm https://alforge-labs.github.io/install.ps1 | iex

.EXAMPLE
    & ([scriptblock]::Create((irm https://alforge-labs.github.io/install.ps1))) -DryRun
#>
param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$REPO         = "alforge-labs/alforge-labs.github.io"
$ARTIFACT     = "forge-windows-x64"
$EXT          = "zip"
$INSTALL_DIR  = Join-Path $env:USERPROFILE "bin"
$INSTALL_PATH = Join-Path $INSTALL_DIR "forge.exe"

function Write-Ok   { param($msg) Write-Host "  ✓ $msg" -ForegroundColor Green }
function Write-Info { param($msg) Write-Host "  → $msg" }
function Write-Warn { param($msg) Write-Host "  ⚠ $msg" -ForegroundColor Yellow }
function Write-Fail { param($msg) Write-Host "  ✗ $msg" -ForegroundColor Red; exit 1 }

if ($DryRun) { Write-Host "[dry-run] 実際のインストールは行いません。" -ForegroundColor Cyan }

# ── 1. 最新バージョンを取得 ─────────────────────────────────────
Write-Info "最新バージョンを確認中..."
try {
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases/latest" -UseBasicParsing
    $VERSION = $release.tag_name
} catch {
    Write-Fail "バージョン取得に失敗しました: $_"
}
if (-not $VERSION) { Write-Fail "バージョン情報を取得できませんでした。" }

Write-Ok "最新バージョン: $VERSION"

# 既存バイナリのバージョン確認
if (Get-Command forge -ErrorAction SilentlyContinue) {
    $currentVer = & forge --version 2>$null | Select-Object -First 1
    if ($currentVer) { Write-Info "現在: $currentVer → $VERSION に更新します" }
}

$DOWNLOAD_URL = "https://github.com/$REPO/releases/download/$VERSION/${ARTIFACT}.${EXT}"

# ── 2. ダウンロード & 展開 ─────────────────────────────────────
$TMP_DIR = Join-Path $env:TEMP "forge-install-$(Get-Random)"
$TMP_ZIP = Join-Path $TMP_DIR "${ARTIFACT}.${EXT}"

if (-not $DryRun) {
    New-Item -ItemType Directory -Path $TMP_DIR | Out-Null
    try {
        Write-Info "ダウンロード中: $DOWNLOAD_URL"
        Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile $TMP_ZIP -UseBasicParsing
    } catch {
        Write-Fail "ダウンロードに失敗しました: $_`n  $DOWNLOAD_URL"
    }
    try {
        Expand-Archive -Path $TMP_ZIP -DestinationPath $TMP_DIR -Force
    } catch {
        # .NET フォールバック
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($TMP_ZIP, $TMP_DIR)
    }
    $BINARY = Join-Path $TMP_DIR "forge.dist\forge.exe"
    if (-not (Test-Path $BINARY)) { Write-Fail "展開後にバイナリが見つかりません" }
    Write-Ok "ダウンロード・展開完了"
} else {
    Write-Host "  [dry-run] Invoke-WebRequest $DOWNLOAD_URL → Expand-Archive"
}

# ── 3. インストール先を確定 ──────────────────────────────────────
Write-Host ""
if ($DryRun) {
    Write-Host "  [dry-run] インストール先: $INSTALL_DIR（デフォルト）"
} else {
    $choice = Read-Host "  C:\Program Files\forge\ にインストールしますか？ [y/N]"
    if ($choice -match '^[Yy]$') {
        $INSTALL_DIR  = "C:\Program Files\forge"
        $INSTALL_PATH = Join-Path $INSTALL_DIR "forge.exe"
    }
}

if (-not $DryRun) {
    if (-not (Test-Path $INSTALL_DIR)) {
        New-Item -ItemType Directory -Path $INSTALL_DIR | Out-Null
    }
    Copy-Item -Path $BINARY -Destination $INSTALL_PATH -Force
    Write-Ok "forge を $INSTALL_PATH に配置しました"
} else {
    Write-Host "  [dry-run] Copy-Item forge.exe → $INSTALL_PATH"
}

# ── 4. PATH 自動登録 ─────────────────────────────────────────────
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*$INSTALL_DIR*") {
    if ($DryRun) {
        Write-Host "  [dry-run] PATH に $INSTALL_DIR を追加"
    } else {
        $newPath = if ($currentPath) { "$currentPath;$INSTALL_DIR" } else { $INSTALL_DIR }
        if ($newPath.Length -gt 2048) {
            Write-Warn "PATH が 2048 文字を超えています。手動で追加してください:"
            Write-Host "    [Environment]::SetEnvironmentVariable('PATH', `$env:PATH + ';$INSTALL_DIR', 'User')"
        } else {
            [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
            $env:PATH = "$env:PATH;$INSTALL_DIR"
            Write-Ok "PATH に $INSTALL_DIR を追加しました（次回ターミナル起動から有効）"
        }
    }
} else {
    Write-Ok "PATH はすでに設定済みです"
}

# ── 5. ライセンスアクティベーション ──────────────────────────────
Write-Host ""
Write-Host "ライセンスアクティベーション"
Write-Host "  Whop でご購入のライセンスキーを入力してください。"
if ($DryRun) {
    Write-Host "  [dry-run] ライセンスキー入力をスキップ"
    $LICENSE_KEY = ""
} else {
    $LICENSE_KEY = Read-Host "  ライセンスキー（Enter でスキップ）"
}

if ($LICENSE_KEY) {
    if ($DryRun) {
        Write-Host "  [dry-run] forge license activate $LICENSE_KEY"
    } else {
        try {
            & $INSTALL_PATH license activate $LICENSE_KEY
            Write-Ok "ライセンス認証が完了しました"
        } catch {
            Write-Warn "ライセンス認証に失敗しました。後から再実行してください:"
            Write-Host "    forge license activate <YOUR_LICENSE_KEY>"
        }
    }
} else {
    Write-Host "  → スキップしました。後から実行してください:"
    Write-Host "      forge license activate <YOUR_LICENSE_KEY>"
}

# ── 6. 確認 ─────────────────────────────────────────────────────
Write-Host ""
if (-not $DryRun) {
    try {
        & $INSTALL_PATH --version | Out-Null
        Write-Ok "インストール完了！"
        Write-Host ""
        Write-Host "  新しいターミナルを開いて試してください: forge --help"
    } catch {
        Write-Warn "forge の確認に失敗しました。新しいターミナルを開いて試してください:"
        Write-Host "    forge --version"
    }
    # クリーンアップ
    if (Test-Path $TMP_DIR) { Remove-Item -Recurse -Force $TMP_DIR }
} else {
    Write-Ok "ドライランが完了しました。実際にインストールするには -DryRun を外して再実行してください。"
}
