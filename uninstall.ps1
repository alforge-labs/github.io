#Requires -Version 5.1
<#
.SYNOPSIS
    AlphaForge forge の Windows アンインストーラー

.DESCRIPTION
    %USERPROFILE%\bin\forge.exe を削除します。
    削除前にライセンスの非アクティベートを案内します。

.EXAMPLE
    irm https://alforge-labs.github.io/uninstall.ps1 | iex
#>

$ErrorActionPreference = "Stop"

$INSTALL_DIR  = Join-Path $env:USERPROFILE "bin"
$INSTALL_PATH = Join-Path $INSTALL_DIR "forge.exe"

if (-not (Test-Path $INSTALL_PATH)) {
    Write-Error "forge が $INSTALL_PATH に見つかりません。"
    exit 1
}

Write-Host "アンインストールを開始します。"
Write-Host ""
Write-Host "重要: ライセンスシートを解放するために、先にライセンスを非アクティベートしてください:" -ForegroundColor Yellow
Write-Host "  forge license deactivate" -ForegroundColor Cyan
Write-Host ""
$CONFIRMED = Read-Host "非アクティベート済みですか? [y/N]"

if ($CONFIRMED -notmatch "^[yY]") {
    Write-Host "アンインストールをキャンセルしました。"
    Write-Host "先に 'forge license deactivate' を実行してください。"
    exit 0
}

Remove-Item -Path $INSTALL_PATH -Force

Write-Host ""
Write-Host "✓ forge を $INSTALL_PATH から削除しました" -ForegroundColor Green
