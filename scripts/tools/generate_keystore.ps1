# ==============================================================================
# Script de Geração da Keystore de Release para Google Play Store
# Projeto: Grass Cut Bot
# ==============================================================================

param(
    [string]$KeystoreName = "upload-keystore.jks",
    [string]$Alias = "grasscutbot",
    [string]$Password = "grasscutbot2026",
    [int]$ValidityDays = 10000
)

$keytoolCmd = Get-Command keytool -ErrorAction SilentlyContinue
if (-not $keytoolCmd) {
    $fallback = "C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot\bin\keytool.exe"
    if (Test-Path $fallback) {
        $keytoolCmd = $fallback
    } else {
        Write-Error "keytool não encontrado no PATH nem no JDK padrão!"
        exit 1
    }
} else {
    $keytoolCmd = $keytoolCmd.Source
}

Write-Host "--- Gerando Keystore de Release para Android ($KeystoreName) ---" -ForegroundColor Cyan
& $keytoolCmd -genkeypair -v `
  -keystore $KeystoreName `
  -alias $Alias `
  -keyalg RSA `
  -keysize 2048 `
  -validity $ValidityDays `
  -storepass $Password `
  -keypass $Password `
  -dname "CN=BifGames, OU=Games, O=BifGames, L=SaoPaulo, ST=SP, C=BR"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✔ Keystore gerada com sucesso: $KeystoreName (Alias: $Alias)" -ForegroundColor Green
} else {
    Write-Error "Falha ao gerar a keystore!"
}
