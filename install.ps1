#Requires -Version 5.1
<#
.SYNOPSIS
    AlphaForge forge の Windows インストーラー

.DESCRIPTION
    GitHub Releases から最新の forge-windows-x64.zip を取得し、
    %LOCALAPPDATA%\Programs\alpha-forge\forge.dist\ に同梱ファイル一式を
    展開して %LOCALAPPDATA%\Programs\alpha-forge\forge.cmd ラッパーを生成する。
    User PATH に %LOCALAPPDATA%\Programs\alpha-forge を追加する。

    -DryRun スイッチで実際の変更なしに動作を確認できる。
    -Yes スイッチで対話確認をスキップして自動進行する（CI / 再インストール用）。

.EXAMPLE
    irm https://alforge-labs.github.io/install.ps1 | iex

.EXAMPLE
    & ([scriptblock]::Create((irm https://alforge-labs.github.io/install.ps1))) -DryRun

.NOTES
    Issue alforge-labs/alforge-labs.github.io#251 で forge.dist ディレクトリ方式に移行。
    旧レイアウト ($HOME\bin\forge.exe / C:\Program Files\forge\forge.exe) は
    検出次第クリーンアップする。
#>
param(
    [switch]$DryRun,
    [switch]$Yes
)

$ErrorActionPreference = "Stop"

$REPO         = "alforge-labs/alforge-labs.github.io"
$ARTIFACT     = "forge-windows-x64"
$EXT          = "zip"
$INSTALL_ROOT = Join-Path $env:LOCALAPPDATA "Programs\alpha-forge"
$DIST_DIR     = Join-Path $INSTALL_ROOT "forge.dist"
$LAUNCHER     = Join-Path $INSTALL_ROOT "forge.cmd"

# 旧レイアウト（マイグレーション対象）
$OLD_USER_BIN      = Join-Path $HOME "bin\forge.exe"
$OLD_PROGRAM_FILES = "C:\Program Files\forge\forge.exe"
$OLD_PROGRAM_DIR   = "C:\Program Files\forge"

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

# 既存バイナリのバージョン確認（情報表示のみ）
if (Get-Command forge -ErrorAction SilentlyContinue) {
    try {
        $currentVer = (& forge --version 2>$null | Select-Object -First 1)
        if ($currentVer) { Write-Info "現在: $currentVer → $VERSION に更新します" }
    } catch {
        # 旧バイナリが壊れていて起動できない場合（forge.dist 単一 .exe コピーの被害者）
        # は無視して新インストールを進める
    }
}

$DOWNLOAD_URL = "https://github.com/$REPO/releases/download/$VERSION/${ARTIFACT}.${EXT}"

# ── 2. ダウンロード & 展開 ─────────────────────────────────────
$TMP_DIR = Join-Path $env:TEMP "forge-install-$(Get-Random)"

if ($DryRun) {
    Write-Host "  [dry-run] Invoke-WebRequest $DOWNLOAD_URL → Expand-Archive → $TMP_DIR"
    Write-Host ""
    Write-Host "  [dry-run] インストール先:"
    Write-Host "    forge.dist : $DIST_DIR"
    Write-Host "    ラッパー   : $LAUNCHER"
    Write-Host ""
    Write-Host "  [dry-run] 旧レイアウト検出: 実行時に $OLD_USER_BIN / $OLD_PROGRAM_FILES を探索"
    Write-Host "  [dry-run] User PATH に $INSTALL_ROOT を追加（重複時はスキップ）"
    Write-Host ""
    Write-Ok "ドライランが完了しました。実際にインストールするには -DryRun を外して再実行してください。"
    return
}

New-Item -ItemType Directory -Path $TMP_DIR | Out-Null
try {
    $TMP_ZIP = Join-Path $TMP_DIR "${ARTIFACT}.${EXT}"
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

    $SRC_DIST = Join-Path $TMP_DIR "forge.dist"
    $SRC_EXE  = Join-Path $SRC_DIST "forge.exe"
    if (-not (Test-Path $SRC_DIST -PathType Container)) {
        Write-Fail "展開後に forge.dist ディレクトリが見つかりません ($SRC_DIST)"
    }
    if (-not (Test-Path $SRC_EXE -PathType Leaf)) {
        Write-Fail "展開後に forge.dist\forge.exe が見つかりません"
    }
    Write-Ok "ダウンロード・展開完了"

    # ── 3. 既存インストール検出 & クリーンアップ ─────────────────────
    $hasNewLayout = Test-Path $DIST_DIR -PathType Container
    $hasOldUserBin = Test-Path $OLD_USER_BIN -PathType Leaf
    $hasOldProgramFiles = Test-Path $OLD_PROGRAM_FILES -PathType Leaf

    if ($hasNewLayout) {
        Write-Info "既存インストール検出: $DIST_DIR （上書き更新します）"
    }

    if ($hasOldUserBin -or $hasOldProgramFiles) {
        Write-Warn "旧レイアウトを検出しました。新レイアウトへ移行します:"
        if ($hasOldUserBin)      { Write-Host "    - $OLD_USER_BIN" }
        if ($hasOldProgramFiles) { Write-Host "    - $OLD_PROGRAM_FILES" }
        Write-Host ""
        $migrate = if ($Yes) { "y" } else { Read-Host "  旧インストールを削除して新レイアウトへ移行しますか? [Y/n]" }
        if ($migrate -match "^[Nn]") {
            Write-Fail "ユーザーがマイグレーションを拒否したためインストールを中止します。"
        }

        if ($hasOldUserBin) {
            try {
                Remove-Item -Path $OLD_USER_BIN -Force
                Write-Ok "削除: $OLD_USER_BIN"
                # 親 dir が空なら削除（他用途と混在の可能性があるので空のときだけ）
                $oldUserDir = Split-Path -Parent $OLD_USER_BIN
                if ((Test-Path $oldUserDir) -and -not (Get-ChildItem -Path $oldUserDir -Force | Select-Object -First 1)) {
                    Remove-Item -Path $oldUserDir -Force
                    Write-Ok "空ディレクトリを削除: $oldUserDir"
                }
            } catch {
                Write-Warn "旧 $OLD_USER_BIN の削除に失敗しました: $_"
            }
        }

        if ($hasOldProgramFiles) {
            $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
                [Security.Principal.WindowsBuiltInRole]::Administrator
            )
            if (-not $isAdmin) {
                Write-Warn "$OLD_PROGRAM_FILES の削除には管理者権限が必要です。新レイアウトのインストール自体は続行しますが、PowerShell を管理者として起動して以下を手動実行してください:"
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
    }

    # ── 4. 新レイアウトをアトミックに配置 ─────────────────────────
    if (-not (Test-Path $INSTALL_ROOT)) {
        New-Item -ItemType Directory -Path $INSTALL_ROOT -Force | Out-Null
        Write-Ok "ディレクトリ作成: $INSTALL_ROOT"
    }

    $TIMESTAMP = [int][double]::Parse((Get-Date -UFormat %s))
    $BACKUP_DIR = Join-Path $INSTALL_ROOT "forge.dist.bak-$TIMESTAMP"
    $STAGED_DIR = Join-Path $INSTALL_ROOT "forge.dist.new"

    # staging: 新 forge.dist を兄弟に置く（同一 FS のため rename がアトミック）
    if (Test-Path $STAGED_DIR) { Remove-Item -Recurse -Force $STAGED_DIR }
    try {
        # Move-Item は同一ボリュームではアトミック rename
        Move-Item -Path $SRC_DIST -Destination $STAGED_DIR
    } catch {
        # 異なるボリュームの場合は Copy-Item へフォールバック
        Copy-Item -Path $SRC_DIST -Destination $STAGED_DIR -Recurse -Force
    }

    if ($hasNewLayout) {
        Move-Item -Path $DIST_DIR -Destination $BACKUP_DIR
    }
    try {
        Move-Item -Path $STAGED_DIR -Destination $DIST_DIR
    } catch {
        # 復旧: バックアップを元に戻す
        if (Test-Path $BACKUP_DIR) { Move-Item -Path $BACKUP_DIR -Destination $DIST_DIR -Force }
        throw
    }

    # 旧バックアップは新レイアウト配置成功後に削除（最新世代のみ保持）
    if ($hasNewLayout -and (Test-Path $BACKUP_DIR)) {
        Remove-Item -Recurse -Force $BACKUP_DIR -ErrorAction SilentlyContinue
    }

    # forge.cmd ラッパーを生成（ASCII、改行は CRLF）
    $LAUNCHER_BODY = @"
@echo off
"%~dp0forge.dist\forge.exe" %*
"@
    Set-Content -Path $LAUNCHER -Value $LAUNCHER_BODY -Encoding ASCII
    Write-Ok "forge.dist を $DIST_DIR に配置しました"
    Write-Ok "ラッパーを $LAUNCHER に生成しました"

    # ── 5. PATH 自動登録 ─────────────────────────────────────────────
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    $pathEntries = if ($currentPath) { $currentPath -split ";" } else { @() }
    # 旧エントリを除去
    $pathEntries = $pathEntries | Where-Object {
        $_ -ne "" -and
        $_ -ne $OLD_PROGRAM_DIR -and
        $_ -ne (Split-Path -Parent $OLD_USER_BIN)
    }
    # 新エントリが含まれなければ追加
    if ($pathEntries -notcontains $INSTALL_ROOT) {
        $pathEntries = $pathEntries + $INSTALL_ROOT
    }
    $newPath = ($pathEntries -join ";")

    if ($newPath.Length -gt 2048) {
        Write-Warn "User PATH が 2048 文字を超えています。手動で追加してください:"
        Write-Host "    [Environment]::SetEnvironmentVariable('PATH', `$env:PATH + ';$INSTALL_ROOT', 'User')"
    } else {
        if ($newPath -ne $currentPath) {
            [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
            Write-Ok "User PATH を更新しました（次回ターミナル起動から有効）"
        } else {
            Write-Ok "User PATH はすでに最新です"
        }
        # 現セッション PATH にも反映（インストール直後の動作確認のため）
        if ($env:PATH -notlike "*$INSTALL_ROOT*") {
            $env:PATH = "$env:PATH;$INSTALL_ROOT"
        }
    }

    # ── 6. 動作確認 ─────────────────────────────────────────────────
    Write-Host ""
    try {
        $versionOut = & $LAUNCHER --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Ok "インストール完了！ ($($versionOut | Select-Object -First 1))"
        } else {
            Write-Warn "forge の起動確認に失敗しました（exit code: $LASTEXITCODE）。"
            Write-Host "    手動確認: $LAUNCHER --version"
        }
    } catch {
        Write-Warn "forge コマンドの動作確認に失敗しました: $_"
        Write-Host "    新しいターミナルを開いて再試行してください: forge --version"
    }

    # ── 7. 認証案内 ─────────────────────────────────────────────────
    Write-Host ""
    Write-Host "次のステップ: ライセンス認証"
    Write-Host "  AlphaForge は Whop OAuth でライセンス認証を行います。"
    Write-Host "  新しいターミナルを開いて以下を実行してください:"
    Write-Host ""
    Write-Host "      forge system auth login" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  認証状態の確認:"
    Write-Host "      forge system auth status"
    Write-Host ""
    Write-Host "使い方: forge --help"

} finally {
    if (Test-Path $TMP_DIR) { Remove-Item -Recurse -Force $TMP_DIR -ErrorAction SilentlyContinue }
}
