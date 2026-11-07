# Melhoria 201: Atalho de Publicação Automática `publish.ps1` & Slash Command `/publicar-versao` (`v0.12.151-alpha`)

## 1. Resumo Executivo
- **Título da Entrega:** Criação de atalhos universais para publicação automatizada de versões: script de terminal `publish.ps1` na raiz do projeto e skill de chat `.agent/skills/publicar-versao/` (invocável via `/publicar-versao`).
- **Versão SemVer Alcançada:** `v0.12.151-alpha` (Version Code `1351`).
- **Data de Conclusão:** 07 de Novembro de 2026.
- **Status:** Concluído e Validado.

---

## 2. Objetivos e Motivação
Atender à solicitação do usuário de criar um atalho prático para automatizar todo o ciclo de publicação de uma nova versão:
1. Incremento de versão SemVer (Patch ou Minor) e Version Code.
2. Sincronização atômica entre `scripts/core/game_version.gd`, `project.godot` e `export_presets.cfg`.
3. Compilação do Android App Bundle (`.aab`) assinado.
4. Upload direto para o Google Play Console via API (`androidpublisher.googleapis.com`).
5. Apresentação obrigatória das notas de versão em `<pt-BR>` e `<en-US>` (Mandamento Invariante 18).
6. Commit semântico no Git e `git push origin main`.

---

## 3. Implementações Realizadas

### A. Script PowerShell Raiz (`publish.ps1`)
- Atalho direto na raiz do projeto que pode ser invocado simplesmente com:
  ```powershell
  # Publica uma nova versão Patch no Teste Interno (padrão):
  .\publish.ps1

  # Publica no Teste Fechado (Alpha):
  .\publish.ps1 -Track alpha

  # Publica um novo Minor com notas customizadas:
  .\publish.ps1 -Bump Minor -NotesPt "Novidades..." -NotesEn "What's new..."

  # Re-publica a versão atual sem alterar números de versão:
  .\publish.ps1 -Bump None
  ```

### B. Módulo de Automação do Pipeline (`scripts/tools/publish_version.ps1`)
- Orquestra as etapas de forma determinística:
  - Extrai versão atual via regex de `scripts/core/game_version.gd`.
  - Incrementa Patch ou Minor e calcula `version_code = (major * 10000) + (minor * 100) + patch`.
  - Atualiza os 3 arquivos canônicos mantendo UTF-8 sem BOM.
  - Invoca `scripts/tools/build_android_aab.ps1 -Publish` com repasse de notas e faixa.
  - Exibe no terminal as tags `<pt-BR>` e `<en-US>`.
  - Executa `git commit` semântico e `git push origin main`.

### C. Antigravity Skill & Slash Command (`.agent/skills/publicar-versao/SKILL.md`)
- Registrado no catálogo de skills do agente.
- O usuário pode digitar a qualquer momento `/publicar-versao` (ou pedir "suba uma nova versão") para que o assistente execute o fluxo de ponta a ponta e apresente os resultados com as release notes formatadas.

### D. Suporte a Release Notes Dinâmicas no Uploader
- `scripts/tools/play_store_uploader/upload.js` atualizado para receber `--notes-pt`, `--notes-en`, `--notes-file` ou variáveis de ambiente `RELEASE_NOTES_PT` e `RELEASE_NOTES_EN` (compatível com GitHub Actions e CLI local).

---

## 4. Arquivos Afetados
- `publish.ps1`: Atalho de 1 comando na raiz.
- `scripts/tools/publish_version.ps1`: Script de automação completa do pipeline.
- `.agent/skills/publicar-versao/SKILL.md`: Definição da skill e slash command do agente.
- `scripts/tools/build_android_aab.ps1`: Parâmetros `-NotesPt` e `-NotesEn`.
- `scripts/tools/play_store_uploader/upload.js`: Suporte universal a notas dinâmicas.
- `docs/historico_melhorias/INDICE_MELHORIAS.md`: Registro da melhoria 201.
