# ==============================================================================
# Atalho Rapido de Publicacao no Google Play (Grass Cut Bot)
# Executa: .\scripts\tools\publish_version.ps1
#
# Exemplos de uso:
#   .\publish.ps1                           # Bump Patch + Upload Teste Interno + Push
#   .\publish.ps1 -Track alpha             # Bump Patch + Upload Teste Fechado + Push
#   .\publish.ps1 -Bump Minor              # Bump Minor + Upload Teste Interno + Push
#   .\publish.ps1 -Bump None               # Re-publica a versao atual sem bump
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

$scriptPath = "$PSScriptRoot\scripts\tools\publish_version.ps1"
& $scriptPath @PSBoundParameters
