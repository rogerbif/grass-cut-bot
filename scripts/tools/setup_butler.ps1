# ==============================================================================
# Script Utilitário de Instalação/Configuração do Butler CLI (itch.io)
# Grass Cut Bot
# ==============================================================================

param(
    [string]$InstallDir = "$env:LOCALAPPDATA\itch-butler"
)

$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ">>> INSTALADOR DO BUTLER CLI (ITCH.IO) <<<" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Verifica se já está instalado e funcional
$existing = Get-Command butler -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "[OK] Butler ja esta instalado no sistema:" -ForegroundColor Green
    Write-Host "     Caminho: $($existing.Source)" -ForegroundColor White
    & butler -V
    Write-Host "`nPara autenticar sua conta, execute: butler login" -ForegroundColor Yellow
    exit 0
}

# 2. Se não estiver no PATH, verifica no diretório padrão
$targetExe = Join-Path $InstallDir "butler.exe"
if (Test-Path $targetExe) {
    Write-Host "[OK] Executavel encontrado em $targetExe" -ForegroundColor Green
} else {
    Write-Host "[1/3] Baixando a versao mais recente do Butler para Windows 64-bit..." -ForegroundColor White
    
    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }

    $zipUrl = "https://github.com/itchio/butler/releases/download/v15.32.0/butler-windows-amd64.zip"
    $zipPath = Join-Path $InstallDir "butler.zip"

    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
    Write-Host "[2/3] Extraindo arquivos..." -ForegroundColor White
    Expand-Archive -Path $zipPath -DestinationPath $InstallDir -Force
    Remove-Item $zipPath -Force

    # Se descompactou dentro de subpasta (ex: windows-amd64), move para a raiz
    $subDir = Join-Path $InstallDir "windows-amd64"
    if (Test-Path $subDir) {
        Get-ChildItem -Path $subDir | Move-Item -Destination $InstallDir -Force
        Remove-Item $subDir -Force -Recurse
    }
}

# 3. Adiciona ao PATH do Usuário se ainda não estiver
$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($userPath -notlike "*$InstallDir*") {
    Write-Host "[3/3] Adicionando $InstallDir ao PATH do usuario..." -ForegroundColor White
    $newUserPath = "$userPath;$InstallDir"
    [Environment]::SetEnvironmentVariable("PATH", $newUserPath, "User")
    $env:PATH = "$env:PATH;$InstallDir"
    Write-Host "  [OK] Variavel de ambiente PATH atualizada com sucesso!" -ForegroundColor Green
} else {
    $env:PATH = "$env:PATH;$InstallDir"
}

Write-Host "`n==================================================" -ForegroundColor Green
Write-Host ">>> BUTLER INSTALADO COM SUCESSO! <<<" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green

& "$InstallDir\butler.exe" -V

Write-Host "`nPROXIMO PASSO OBRIGATORIO (Uma unica vez):" -ForegroundColor Yellow
Write-Host "Execute o comando abaixo no terminal para autorizar sua conta do itch.io:" -ForegroundColor Cyan
Write-Host "  butler login" -ForegroundColor White
Write-Host "==================================================" -ForegroundColor Green
