# ==============================================================================
# Script de Publicação Completa com 1 Comando (Grass Cut Bot)
# Executa: Bump de Versão -> Compilação AAB -> Upload Google Play -> Git Push
# ==============================================================================

param(
    [ValidateSet("Patch", "Minor", "None")]
    [string]$Bump = "Patch",

    [ValidateSet("internal", "alpha", "beta", "production")]
    [string]$Track = "internal",

    [string]$NotesPt = "",
    [string]$NotesEn = "",

    [switch]$NoGit
)

$ErrorActionPreference = "Stop"

$rootDir = (Resolve-Path "$PSScriptRoot\..\..").Path
$gameVersionFile = "$rootDir\scripts\core\game_version.gd"
$projectGodotFile = "$rootDir\project.godot"
$exportPresetsFile = "$rootDir\export_presets.cfg"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ">>> PIPELINE DE PUBLICACAO AUTOMATIZADA GOOGLE PLAY <<<" -ForegroundColor Cyan
Write-Host "Modo de Bump: $Bump" -ForegroundColor Yellow
Write-Host "Faixa Google Play: $Track" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Bump de versão
$gvText = [System.IO.File]::ReadAllText($gameVersionFile, [System.Text.Encoding]::UTF8)
$major = [int]([regex]::Match($gvText, 'const MAJOR:\s*int\s*=\s*(\d+)').Groups[1].Value)
$minor = [int]([regex]::Match($gvText, 'const MINOR:\s*int\s*=\s*(\d+)').Groups[1].Value)
$patch = [int]([regex]::Match($gvText, 'const PATCH:\s*int\s*=\s*(\d+)').Groups[1].Value)
$stageMatch = [regex]::Match($gvText, 'const STAGE:\s*String\s*=\s*"([^"]*)"')
$stage = if ($stageMatch.Success) { $stageMatch.Groups[1].Value } else { "ALPHA" }

Write-Host "`n[1/4] Versao atual detectada: v$major.$minor.$patch-$($stage.ToLower())" -ForegroundColor White

if ($Bump -eq "Patch") {
    $patch += 1
} elseif ($Bump -eq "Minor") {
    $minor += 1
    $patch = 0
}

$rawVersion = "$major.$minor.$patch"
if ($stage -and $stage.ToUpper() -ne "RELEASE") {
    $rawVersion += "-$($stage.ToLower())"
}
$versionString = "v$rawVersion"
$versionCode = ($major * 10000) + ($minor * 100) + $patch

Write-Host ">>> Nova Versao Alvo: $versionString (Version Code: $versionCode)" -ForegroundColor Green

if ($Bump -ne "None") {
    # Atualiza game_version.gd
    $gvText = [regex]::Replace($gvText, 'const MAJOR:\s*int\s*=\s*\d+', "const MAJOR: int = $major")
    $gvText = [regex]::Replace($gvText, 'const MINOR:\s*int\s*=\s*\d+', "const MINOR: int = $minor")
    $gvText = [regex]::Replace($gvText, 'const PATCH:\s*int\s*=\s*\d+', "const PATCH: int = $patch")
    [System.IO.File]::WriteAllText($gameVersionFile, $gvText, [System.Text.UTF8Encoding]::new($false))
    Write-Host "  [OK] Atualizado scripts/core/game_version.gd" -ForegroundColor Gray

    # Atualiza project.godot
    $projText = [System.IO.File]::ReadAllText($projectGodotFile, [System.Text.Encoding]::UTF8)
    $projText = [regex]::Replace($projText, 'config/version="[^"]*"', "config/version=`"$rawVersion`"")
    [System.IO.File]::WriteAllText($projectGodotFile, $projText, [System.Text.UTF8Encoding]::new($false))
    Write-Host "  [OK] Atualizado project.godot" -ForegroundColor Gray

    # Atualiza export_presets.cfg
    $presetsText = [System.IO.File]::ReadAllText($exportPresetsFile, [System.Text.Encoding]::UTF8)
    $presetsText = [regex]::Replace($presetsText, 'version/code=\d+', "version/code=$versionCode")
    $presetsText = [regex]::Replace($presetsText, 'version/name="[^"]*"', "version/name=`"$rawVersion`"")
    [System.IO.File]::WriteAllText($exportPresetsFile, $presetsText, [System.Text.UTF8Encoding]::new($false))
    Write-Host "  [OK] Atualizado export_presets.cfg" -ForegroundColor Gray
}

# 2. Release Notes padrão caso não fornecidas
if (-not $NotesPt) {
    $NotesPt = "Novidades da versão $($versionString):`n• Melhorias contínuas de jogabilidade e resposta de corte.`n• Otimizações de renderização e estabilidade mobile.`n• Refinamentos nas metas de fases e navegação."
}
if (-not $NotesEn) {
    $NotesEn = "What's new in version $($versionString):`n• Gameplay refinements and responsive blade cutting.`n• Mobile rendering and stability optimizations.`n• Archipelago level goals and navigation improvements."
}

# 3. Compilação e Upload AAB
Write-Host "`n[2/4] Compilando e enviando pacote .AAB para Google Play..." -ForegroundColor White
$buildScript = "$PSScriptRoot\build_android_aab.ps1"

& $buildScript -Publish -Track $Track -NotesPt $NotesPt -NotesEn $NotesEn

if ($LASTEXITCODE -ne 0) {
    Write-Error "Falha na compilacao ou publicacao do AAB."
    exit 1
}

# 4. Exibe Release Notes obrigatórias
Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host ">>> NOTAS DA VERSAO PUBLICADA (PLAY CONSOLE) <<<" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "<pt-BR>`n$NotesPt`n</pt-BR>" -ForegroundColor Green
Write-Host ""
Write-Host "<en-US>`n$NotesEn`n</en-US>" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan

# 5. Git Commit & Push
if (-not $NoGit) {
    Write-Host "`n[3/4] Sincronizando checkpoint no Git e GitHub..." -ForegroundColor White
    git add export_presets.cfg project.godot scripts/core/game_version.gd
    git commit -m "chore(release): bump version para $rawVersion (code $versionCode) e deploy Google Play"
    Write-Host "`n[4/4] Enviando para repositório remoto (git push origin main)..." -ForegroundColor White
    git push origin main
}

Write-Host "`n==================================================" -ForegroundColor Green
Write-Host ">>> SUCESSO TOTAL: VERSAO $versionString (CODE $versionCode) PUBLICADA! <<<" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
