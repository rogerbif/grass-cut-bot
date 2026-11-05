# Registro de Melhoria: Filtragem Dinâmica das Metas da Fase no Painel Direito do Editor

## 1. Visão Geral e Contexto
- **Solicitação do Usuário:** No editor de fases, no painel direito na seção "METAS DA FASE (OBJETIVOS)", exibir apenas as espécies de vegetação/flores que realmente estão presentes na fase atual (escondendo os cards de espécies com contagem 0).
- **Diagnóstico:** Anteriormente, todos os cards do catálogo de metas (`GOALS_CATALOG`) eram exibidos continuamente na interface com contagem `0 tufos / 0 flores / 0 trigos`, ocupando espaço vertical desnecessário e poluindo a visualização.

## 2. Alterações Realizadas
1. **`scripts/editor/level_editor_ui.gd`:**
   - Adicionado dicionário de rastreamento `_goal_cards: Dictionary = {}` para armazenar a referência de cada `PanelContainer` (card) de meta instanciado em `_build_goals_metric_section()`.
   - Em `update_goals_summary()`, implementada a visibilidade reativa:
     ```gdscript
     var card: PanelContainer = _goal_cards.get(g_key, null) as PanelContainer
     if card != null:
         card.visible = (total_count > 0)
     ```
   - Dessa forma, apenas as plantas/flores/trigo que possuem pelo menos 1 exemplar na fase são exibidas no painel de metas. Se uma planta for removida ou adicionada durante a edição, o painel atualiza dinamicamente em tempo real.
2. **SemVer & Presets:**
   - Versão incrementada para `v0.12.122-alpha` (code 1321) em `project.godot` e `export_presets.cfg`.

## 3. Verificação e Testes
- Testes automatizados executados via Godot headless:
  - `tests/test_editor_goals_and_time_limit.tscn` (0 erros)
  - `tests/test_save_and_load_roundtrip.tscn` (0 erros)
  - `tests/test_editor_camera_and_shortcuts.tscn` (0 erros)
