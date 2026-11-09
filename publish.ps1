# ==============================================================================
# Atalho Rapido de Publicacao Unificada (Grass Cut Bot)
# Executa: .\scripts\tools\publish_version.ps1
#
# Padrão: Atualiza SIMULTANEAMENTE tanto no Android (Google Play) quanto no itch.io (HTML5).
#
# Exemplos de uso:
#   .\publish.ps1                             # Bump Patch + Deploy Duplo (Android + itch.io) + Push
#   .\publish.ps1 -Bump Minor                 # Bump Minor + Deploy Duplo (Android + itch.io) + Push
#   .\publish.ps1 -Track alpha                # Deploy Duplo com Google Play na faixa Closed (Alpha)
#   .\publish.ps1 -Target GooglePlay          # Publica exclusivamente no Google Play
#   .\publish.ps1 -Target Itch                # Publica exclusivamente no itch.io (HTML5)
#   .\publish.ps1 -Bump None                  # Re-publica a versao atual em ambos sem bump
# ==============================================================================

param(
    [ValidateSet("Patch", "Minor", "None")]
    [string]$Bump = "Patch",

    [ValidateSet("internal", "alpha", "beta", "production")]
    [string]$Track = "internal",

    [string]$NotesPt = "",
    [string]$NotesEn = "",

    [ValidateSet("All", "GooglePlay", "Itch")]
    [string]$Target = "All",

    [switch]$NoGit
)

$scriptPath = "$PSScriptRoot\scripts\tools\publish_version.ps1"
& $scriptPath @PSBoundParameters
