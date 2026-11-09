# ==============================================================================
# Script de Exportacao e Publicacao no itch.io (HTML5 / Web)
# Projeto: Grass Cut Bot
# Executa: Godot Web Export -> Butler Push (html5)
# ==============================================================================

param(
    [string]$ProjectSlug = "bifgames/grass-cut-bot",
    [string]$Channel = "html5",
    [string]$UserVersion = "",
    [switch]$SkipExport
)

$ErrorActionPreference = "Stop"

$rootDir = (Resolve-Path "$PSScriptRoot\..\..").Path
$gameVersionFile = "$rootDir\scripts\core\game_version.gd"
$webDir = "$rootDir\build\web"
$indexHtml = "$webDir\index.html"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ">>> EXPORTACAO E DEPLOY ITCH.IO (HTML5) <<<" -ForegroundColor Cyan
Write-Host "Slug do Jogo: $ProjectSlug" -ForegroundColor Yellow
Write-Host "Canal itch.io: $Channel" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Determina a versão se não fornecida
if (-not $UserVersion) {
    if (Test-Path $gameVersionFile) {
        $gvText = [System.IO.File]::ReadAllText($gameVersionFile, [System.Text.Encoding]::UTF8)
        $major = [int]([regex]::Match($gvText, 'const MAJOR:\s*int\s*=\s*(\d+)').Groups[1].Value)
        $minor = [int]([regex]::Match($gvText, 'const MINOR:\s*int\s*=\s*(\d+)').Groups[1].Value)
        $patch = [int]([regex]::Match($gvText, 'const PATCH:\s*int\s*=\s*(\d+)').Groups[1].Value)
        $stageMatch = [regex]::Match($gvText, 'const STAGE:\s*String\s*=\s*"([^"]*)"')
        $stage = if ($stageMatch.Success) { $stageMatch.Groups[1].Value } else { "ALPHA" }

        $UserVersion = "$major.$minor.$patch"
        if ($stage -and $stage.ToUpper() -ne "RELEASE") {
            $UserVersion += "-$($stage.ToLower())"
        }
    } else {
        $UserVersion = "1.0.0"
    }
}

Write-Host "Versao de Release: v$UserVersion" -ForegroundColor Green

# 2. Localiza o Butler CLI
$butlerExe = $null
$cmdButler = Get-Command butler -ErrorAction SilentlyContinue
if ($cmdButler) {
    $butlerExe = $cmdButler.Source
} else {
    $defaultButler = "$env:LOCALAPPDATA\itch-butler\butler.exe"
    if (Test-Path $defaultButler) {
        $butlerExe = $defaultButler
    }
}

if (-not $butlerExe) {
    Write-Error @"
Butler CLI nao encontrado no PATH nem em $env:LOCALAPPDATA\itch-butler\butler.exe!
Para instalar automaticamente, execute:
  .\scripts\tools\setup_butler.ps1
E em seguida autorize sua conta com:
  butler login
"@
    exit 1
}

# 3. Exportação Web com o Godot
if (-not $SkipExport) {
    Write-Host "`n[1/2] Compilando WebAssembly / HTML5 com Godot..." -ForegroundColor White

    $godotExe = "C:\Users\User\OneDrive\Documentos\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
    if (-not (Test-Path $godotExe)) {
        $godotExe = "C:\Users\User\OneDrive\Documentos\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe"
    }
    if (-not (Test-Path $godotExe)) {
        $cmdGodot = Get-Command godot -ErrorAction SilentlyContinue
        if ($cmdGodot) { $godotExe = $cmdGodot.Source }
    }

    if (-not (Test-Path $godotExe)) {
        Write-Error "Executavel do Godot nao foi encontrado!"
        exit 1
    }

    if (-not (Test-Path $webDir)) {
        New-Item -ItemType Directory -Path $webDir -Force | Out-Null
    }

    & $godotExe --headless --export-release "grasscutbot_Web" "$indexHtml"
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $indexHtml)) {
        Write-Error "Falha na exportacao Web do Godot."
        exit 1
    }

    # Limpeza de arquivos .import desnecessários no build web
    Get-ChildItem -Path $webDir -Filter "*.import" -Recurse | Remove-Item -Force -ErrorAction SilentlyContinue

    Write-Host "  [OK] Exportacao Web concluida com sucesso em $webDir" -ForegroundColor Green
} else {
    Write-Host "`n[1/2] Pulando exportacao do Godot (-SkipExport ativo)." -ForegroundColor Yellow
}

# 4. Envio com Butler para o itch.io
$butlerTarget = "$($ProjectSlug):$($Channel)"
Write-Host "`n[2/2] Enviando build para o itch.io via Butler CLI..." -ForegroundColor White
Write-Host "Target: $butlerTarget" -ForegroundColor Cyan
Write-Host "Versao: $UserVersion" -ForegroundColor Cyan

& $butlerExe push "$webDir" "$butlerTarget" --userversion "$UserVersion"

if ($LASTEXITCODE -ne 0) {
    Write-Error @"
Falha ao enviar a build para o itch.io com o Butler.
Verifique se voce ja executou 'butler login' ou se tem permissao no projeto '$ProjectSlug'.
"@
    exit 1
}

Write-Host "`n==================================================" -ForegroundColor Green
Write-Host ">>> SUCESSO: BUILD HTML5 PUBLICADA NO ITCH.IO! <<<" -ForegroundColor Green
Write-Host "Acesse o jogo em: https://bifgames.itch.io/grass-cut-bot" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Green
