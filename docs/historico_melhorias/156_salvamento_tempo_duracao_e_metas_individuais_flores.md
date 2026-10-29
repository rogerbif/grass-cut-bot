# Melhoria 156: Salvamento do Tempo de Duração da Fase, Metas por Padrão com Contagem Total e Separação Individual das 8 Flores ⏱️🎯🌸

## 🎯 Objetivo e Contexto
O usuário reportou três comportamentos críticos no Editor de Fases e no sistema de metas de colheita:
1. **Tempo de Duração da Fase não Salvo:** Ao alterar o tempo de duração da fase (SpinBox `⏱️(s)` na barra superior do editor), o valor não estava persistindo corretamente no JSON/TSCN, sendo frequentemente sobrescrito para o valor padrão (90s) pelas rotinas de sincronização de UI (`_sync_all_ui`).
2. **Ativação por Padrão de Qualquer Planta Adicionada:** Qualquer espécie vegetal (gramas, trigo ou flores) inserida no mapa deve ter seu objetivo marcado/ativo por padrão na lista de metas com a quantidade total presente como meta inicial.
3. **Metas de Flores 100% Separadas e Independentes:** As 8 flores (`flower`, `flower_rose`, `flower_daisy`, `flower_sunflower`, `flower_bell`, `flower_corolla`, `flower_tulip`, `flower_bed`) estavam sendo agrupadas sob uma única chave genérica `"flower"` caso houvesse mais de 2 tipos na fase (`flower_counts_by_type.size() > 2`). Agora cada flor possui sua meta separada, ícone e cor exclusivos.

---

## 🛠️ Alterações Realizadas

### 1. Resolução do Salvamento do Tempo de Duração (`time_limit`)
- **Extração Atômica com Foco Ativo:** Implementado `get_configured_time_limit() -> float` em `level_editor_ui.gd` que avalia se o usuário está digitando no `LineEdit` interno e retorna o valor numérico digitado ou o `spin_time.value`, evitando qualquer perda ou reset.
- **Proteção contra Sobrescrita em Background:** Em `update_level_header()`, a chamada `spin_time.set_value_no_signal(time_limit)` agora verifica se o `LineEdit` possui foco (`not le.has_focus()`), impedindo que cliques, pinceladas ou eventos de desenho resetem a digitação do usuário.
- **Sincronização Pré-Gravação:** Em `level_editor.gd`, antes de chamar `save_current_level_json()`, `bake_current_level_tscn()`, `_start_playtest()` e `_sync_all_ui()`, o valor configurado na UI é consultado e atualizado na variável de estado `time_limit`.
- **Sinais do LineEdit Conectados:** `spin_time.get_line_edit()` teve seus sinais `text_changed`, `text_submitted` e `focus_exited` conectados para propagar alterações numéricas imediatas para o editor.

### 2. Ativação por Padrão de Plantas e Metas com Valor Total
- **Regra Automática no Editor:** No método `update_goals_summary()` em `level_editor_ui.gd`, quando uma espécie vegetal possui `total_count > 0`, se o usuário não desmarcou expressamente o checkbox (`not _goal_manually_unchecked.get(g_key, false)`), o objetivo é automaticamente ativado (`chk.set_pressed_no_signal(true)`), o SpinBox é exibido (`spin.visible = true`) e seu valor é preenchido com a contagem total de tufos/flores presentes na fase.
- **Tracking de Desmarcação Manual:** Adicionado dicionário `_goal_manually_unchecked` para diferenciar quando o usuário deliberadamente desmarca uma meta (não reativando em background) versus uma nova planta colocada no mapa.
- **Higienização de Plantas Removidas:** Se uma planta tiver `total_count <= 0`, o checkbox é desabilitado e desmarcado, o SpinBox é ocultado e o estado de desmarcação manual é limpo, permitindo que, se o usuário voltar a desenhar aquela espécie futuramente, ela seja reativada por padrão.

### 3. Separação Completa das 8 Flores como Metas Individuais
- **Catálogo Expandido no Editor:** `GOALS_CATALOG` em `level_editor_ui.gd` possui agora 16 metas distintas:
  - 7 cores de grama (`grass_green`, `grass_yellow`, `grass_blue`, `grass_purple`, `grass_white`, `grass_red`, `grass_black`)
  - 1 trigo (`wheat`)
  - 8 flores individuais (`flower`, `flower_rose`, `flower_daisy`, `flower_sunflower`, `flower_bell`, `flower_corolla`, `flower_tulip`, `flower_bed`)
- **Fim do Agrupamento no VegetationGrid:** Em `scripts/plants/vegetation_grid.gd`, o agrupamento condicional de flores sob a chave genérica `"flower"` (quando `size > 2`) foi removido nas rotinas `_build_from_vegetation_field()` e `_build_from_legacy_objects()`. Todas as espécies de flores agora sempre alimentam o dicionário de metas com suas chaves individuais.
- **Diferenciação Visual no HUD In-Game e no Playtest F1:**
  - Em `scripts/ui/hud.gd`, cada tipo de flor agora recebe uma modulação de cor distinta correspondente à sua paleta canônica (Rosa Nobre avermelhada, Girassol dourado, Flor Sino ciano, Cravo alaranjado, etc.).
  - Em `level_editor_ui.gd`, o HUD de playtest [F1] exibe os emojis correspondentes a cada flor (🌹, 🌼, 🌻, 🔔, 🏵️, 🌷, 🪻, 🌸).

---

## 🧪 Testes Automatizados Criados e Validados
- **`tests/test_editor_goals_and_time_limit.gd` / `.tscn`:**
  - `test_time_limit_saving_and_sync`: Valida alteração de tempo no SpinBox, digitação direta no LineEdit, extração via `get_configured_time_limit()` e imunidade a sobrescrita durante foco.
  - `test_default_active_goals_with_total_count`: Valida que ao desenhar grama azul, trigo e flores variadas, todos vêm marcados por padrão com seus totais exatos como meta, mantendo espécies ausentes desabilitadas.
  - `test_individual_flowers_in_vegetation_grid`: Valida que um nível com 4 tipos distintos de flores não agrupa nada em `"flower"`, gerando 4 metas individuais 1:1.
- **Suíte de Regressão Executada:**
  - `test_editor_goals_and_panel.tscn` executado com 100% de sucesso.
  - `test_editor_camera_and_shortcuts.tscn` executado com 100% de sucesso.
  - `test_save_and_load_roundtrip.tscn` executado com 100% de sucesso.
  - Zero warnings e zero erros no Godot Engine 4.7.1 console.

---

## 📦 Game SemVer e Checkpoint
- **Versão anterior:** `v0.12.81-alpha`
- **Nova versão:** `v0.12.82-alpha`
- **Arquivos modificados:**
  - `scripts/editor/level_editor_ui.gd`
  - `scripts/editor/level_editor.gd`
  - `scripts/plants/vegetation_grid.gd`
  - `scripts/ui/hud.gd`
  - `tests/test_editor_goals_and_panel.gd`
  - `tests/test_editor_goals_and_time_limit.gd`
  - `tests/test_editor_goals_and_time_limit.tscn`
  - `project.godot`
  - `export_presets.cfg`
