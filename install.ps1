#Requires -Version 5.1
<#
.SYNOPSIS
    AlphaForge forge の Windows インストーラー

.DESCRIPTION
    GitHub Releases から最新の forge.exe をダウンロードし、
    %USERPROFILE%\bin\forge.exe へ配置します。
    PATH が未設定の場合は追加方法を案内します。

.EXAMPLE
    irm https://alforge-labs.github.io/install.ps1 | iex
#>

$ErrorActionPreference = "Stop"

$REPO       = "ysakae/alpha-forge"
$ARTIFACT   = "forge-windows-x86_64.exe"
$INSTALL_DIR = Join-Path $env:USERPROFILE "bin"
$INSTALL_PATH = Join-Path $INSTALL_DIR "forge.exe"

# 最新バージョンを取得
Write-Host "最新バージョンを確認中..."
try {
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases/latest" -UseBasicParsing
    $VERSION = $release.tag_name
} catch {
    Write-Error "リリースバージョンの取得に失敗しました: $_"
    exit 1
}

if (-not $VERSION) {
    Write-Error "バージョン情報を取得できませんでした。"
    exit 1
}

Write-Host "AlphaForge forge $VERSION をインストールします..."

# インストール先ディレクトリを作成
if (-not (Test-Path $INSTALL_DIR)) {
    New-Item -ItemType Directory -Path $INSTALL_DIR | Out-Null
    Write-Host "$INSTALL_DIR を作成しました。"
}

# ダウンロード
$DOWNLOAD_URL = "https://github.com/$REPO/releases/download/$VERSION/$ARTIFACT"
$TMP_PATH = Join-Path $env:TEMP "forge_tmp.exe"

Write-Host "ダウンロード中: $DOWNLOAD_URL"
try {
    Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile $TMP_PATH -UseBasicParsing
} catch {
    Write-Error "ダウンロードに失敗しました: $_"
    exit 1
}

# 配置
Move-Item -Path $TMP_PATH -Destination $INSTALL_PATH -Force

Write-Host ""
Write-Host "✓ forge を $INSTALL_PATH にインストールしました" -ForegroundColor Green
Write-Host ""

# PATH の確認と案内
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*$INSTALL_DIR*") {
    Write-Host "PATH に $INSTALL_DIR が含まれていません。" -ForegroundColor Yellow
    Write-Host "以下のコマンドで追加できます（PowerShell を再起動後に有効）:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [Environment]::SetEnvironmentVariable('PATH', `$env:PATH + ';$INSTALL_DIR', 'User')" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host "PATH は設定済みです。"
}

Write-Host "次のステップ:"
Write-Host "  forge --version"
Write-Host "  forge license activate <YOUR_LICENSE_KEY>"
