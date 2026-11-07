# ==============================================================================
# Script de Exportacao Automatizada: Android App Bundle (.aab) para Google Play
# Projeto: Grass Cut Bot
# ==============================================================================

param(
    [string]$PresetName = "grasscutbot",
    [string]$OutputPath = "build/release/grass_cut_bot.aab",
    [string]$KeystorePath = "$PSScriptRoot\..\..\upload-keystore.jks",
    [string]$KeystoreUser = "grasscutbot",
    [string]$KeystorePass = "grasscutbot2026",
    [switch]$Publish,
    [string]$Track = "internal",
    [string]$NotesPt = "",
    [string]$NotesEn = ""
)

$godotExe = "C:\Users\User\OneDrive\Documentos\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
if (-not (Test-Path $godotExe)) {
    $godotExe = "C:\Users\User\OneDrive\Documentos\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe"
}

if (-not (Test-Path $godotExe)) {
    Write-Error "Executavel do Godot nao foi encontrado!"
    exit 1
}

$fullKeystorePath = (Resolve-Path $KeystorePath -ErrorAction SilentlyContinue)
if (-not $fullKeystorePath -or -not (Test-Path $fullKeystorePath)) {
    Write-Error "Keystore de release nao foi encontrado no caminho: $KeystorePath"
    exit 1
}

$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = $fullKeystorePath.Path
$env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = $KeystoreUser
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = $KeystorePass

$targetDir = Split-Path -Parent $OutputPath
if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

# Limpa resíduos de exportações e builds anteriores para evitar locks do Windows e duplicidade de assets
$buildRoot = (Resolve-Path "$PSScriptRoot\..\..\android\build").Path
cmd.exe /c "if exist `"$buildRoot\build`" rmdir /s /q `"$buildRoot\build`""
cmd.exe /c "if exist `"$buildRoot\assetPackInstallTime\build`" rmdir /s /q `"$buildRoot\assetPackInstallTime\build`""
cmd.exe /c "if exist `"$buildRoot\src\main\assets`" rmdir /s /q `"$buildRoot\src\main\assets`""

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ">>> COMPILANDO ANDROID APP BUNDLE (.AAB) PARA GOOGLE PLAY <<<" -ForegroundColor Cyan
Write-Host "Preset: $PresetName" -ForegroundColor Yellow
Write-Host "Destino: $OutputPath" -ForegroundColor Yellow
Write-Host "Keystore: $($fullKeystorePath.Path)" -ForegroundColor Yellow
Write-Host "Godot: $godotExe" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Cyan

& $godotExe --headless --export-release $PresetName $OutputPath

if (Test-Path $OutputPath) {
    $fileInfo = Get-Item $OutputPath
    $sizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
    Write-Host ""
    Write-Host "[SUCESSO] Android App Bundle gerado com sucesso:" -ForegroundColor Green
    Write-Host "  Arquivo: $($fileInfo.FullName)" -ForegroundColor Green
    Write-Host "  Tamanho: $sizeMB MB" -ForegroundColor Green

    if ($Publish) {
        Write-Host ""
        Write-Host "==================================================" -ForegroundColor Magenta
        Write-Host ">>> DISPARANDO UPLOAD AUTOMATICO PARA GOOGLE PLAY <<<" -ForegroundColor Magenta
        Write-Host "Faixa: $Track" -ForegroundColor Yellow
        Write-Host "==================================================" -ForegroundColor Magenta
        $uploaderScript = (Resolve-Path "$PSScriptRoot\play_store_uploader\upload.js").Path
        $uploadArgs = @("--track=$Track", "--aab=$OutputPath")
        if ($NotesPt) { $uploadArgs += "--notes-pt=$NotesPt" }
        if ($NotesEn) { $uploadArgs += "--notes-en=$NotesEn" }
        node $uploaderScript @uploadArgs
    }
} else {
    Write-Host ""
    Write-Host "[FALHA] Erro na exportacao do Android App Bundle." -ForegroundColor Red
    exit 1
}
