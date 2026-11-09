# ==============================================================================
# Atalho Rapido de Publicacao (Grass Cut Bot)
# Executa: .\scripts\tools\publish_version.ps1
#
# Exemplos de uso:
#   .\publish.ps1                           # Bump Patch + Deploy Google Play (Internal) + Push
#   .\publish.ps1 -Itch                     # Bump Patch + Deploy Google Play + itch.io (HTML5) + Push
#   .\publish.ps1 -Target Itch              # Bump Patch + Deploy apenas itch.io (HTML5) + Push
#   .\publish.ps1 -Target All               # Bump Patch + Deploy Google Play + itch.io (HTML5) + Push
#   .\publish.ps1 -Track alpha              # Bump Patch + Deploy Google Play (Alpha/Closed) + Push
#   .\publish.ps1 -Bump None -Target Itch   # Re-publica versao atual apenas no itch.io sem bump
# ==============================================================================

param(
    [ValidateSet("Patch", "Minor", "None")]
    [string]$Bump = "Patch",

    [ValidateSet("internal", "alpha", "beta", "production")]
    [string]$Track = "internal",

    [string]$NotesPt = "",
    [string]$NotesEn = "",

    [ValidateSet("GooglePlay", "Itch", "All")]
    [string]$Target = "GooglePlay",

    [switch]$Itch,
    [switch]$NoGit
)

$scriptPath = "$PSScriptRoot\scripts\tools\publish_version.ps1"
& $scriptPath @PSBoundParameters
