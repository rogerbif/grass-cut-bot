---
name: atualizar-documentacao
description: >-
  Executa a rotina obrigatória de atualização de documentação canônica, histórico de melhorias, Semantic Versioning (SemVer) e sincronização com o GitHub para o projeto Grass Cut Bot. Use esta skill ao finalizar refatorações ou implementar novos recursos.
---

# Protocolo de Governança e Documentação: Grass Cut Bot 🌿🤖

Ao finalizar melhorias, fases ou refatorações, execute os seguintes 5 passos obrigatórios com rigor:

## 1. Auditoria de Alterações
- Execute `git status` e `git diff` para mapear arquivos modificados e criados.
- Se houverem assets 3D (.glb) alterados, garanta que foram exportados com `export_apply=True` e que o cache `.godot/imported/` foi devidamente regenerado.

## 2. Mapeamento e Atualização Canônica
- Atualize os arquivos da pasta `docs/` de acordo com a Matriz do `GEMINI.md`:
  - **Visão Geral e Design:** `docs/01_visao_geral_e_gdd/GDD_OFICIAL.md`, `docs/01_visao_geral_e_gdd/DIRECAO_DE_ARTE_E_VISUAL.md`
  - **Entidades e Mecânicas:** `docs/02_entidades_e_mecanicas/SISTEMA_DO_CORTADOR.md`, `docs/02_entidades_e_mecanicas/SISTEMA_DE_VEGETACAO.md`, `docs/02_entidades_e_mecanicas/SISTEMA_DE_OBSTACULOS_E_TERRENO.md`
  - **Level Design:** `docs/03_level_design_e_fases/ESTRUTURA_DAS_FASES.md`
  - **Sistemas & Interface:** `docs/04_sistemas_e_gameplay/SISTEMA_DE_INTERFACE_HUD.md`, `docs/04_sistemas_e_gameplay/SISTEMA_DE_CONTROLES_TOUCH.md`, `docs/04_sistemas_e_gameplay/ECONOMIA_E_OFICINA.md`, `docs/04_sistemas_e_gameplay/GAME_FEEL_E_HAPTICS.md`
  - **Arquitetura & Engenharia:** `docs/05_arquitetura_e_desenvolvimento/ARQUITETURA_DO_PROJETO.md`, `docs/05_arquitetura_e_desenvolvimento/PADRAO_DE_SCRIPTS.md`, `docs/05_arquitetura_e_desenvolvimento/DIRETRIZES_DE_DESENVOLVIMENTO.md`, `docs/05_arquitetura_e_desenvolvimento/PORTABILIDADE_ANDROID.md`
- Atualize o Hub Mestre `docs/PROJETO_GRASS_CUT_BOT.md` se houverem novos documentos.

## 3. Changelog Perpétuo
- Crie um arquivo em `docs/historico_melhorias/<numero_ou_nome_da_melhoria>.md` contendo um consolidado do plano de implementação e do walkthrough executado.
- Atualize o catálogo mestre em `docs/historico_melhorias/INDICE_MELHORIAS.md`.

## 4. Ciclo Game SemVer
- Incremente a versão do projeto quando aplicável:
  - **PATCH (+1)**: Correções de bugs, balanceamento de cortes, ajustes de layout HUD.
  - **MINOR (+1)**: Novos subsistemas (Menu Inicial, Hub, etc.), novas variedades vegetais ou novos blocos de fases.
  - **MAJOR / STAGE**: Transição de MVP -> Alpha -> Beta -> Release.
- Sincronize a versão em `project.godot` (`config/version`) E em `export_presets.cfg` (`version/name` e `version/code`).
- Registre o bloco correspondente no changelog histórico.

## 5. Validação e Checkpoint no Git
- Execute `git status` para auditoria.
- Execute `git add .` e `git commit` utilizando `BypassSandbox: true` para evitar falhas de criação de lock (`.git/index.lock: Permission denied`) ocasionadas pelo isolamento do sandbox em caminhos do OneDrive no Windows.
- Crie o commit semântico padronizado (Exemplo: `git commit -m "docs: atualizacao da wiki e historico [vX.Y.Z]"`).
- Verifique se há repositório remoto configurado (`git remote -v`) antes de tentar `git push`.
