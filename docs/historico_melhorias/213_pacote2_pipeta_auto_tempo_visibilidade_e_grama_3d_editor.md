# 213 — Pacote 2 de Produtividade Visual e Metas do Editor: Pipeta `Alt+Clique`, Auto-Tempo `⚡ Auto`, Visibilidade por Camada `👁️` e Grama 3D (`v0.12.165-alpha`)

**Data:** 09/11/2026  
**Versão:** `v0.12.165-alpha` (`version/code = 1365`)  
**Domínio:** Level Design & Editor de Fases (`scripts/editor/level_editor.gd`, `scripts/editor/level_editor_ui.gd`)

---

## 1. Contexto e Objetivo

Dando sequência ao Pacote 1 (`v0.12.164-alpha`), o **Pacote 2** de melhorias do Editor de Fases elimina atritos de seleção de elementos, calibração manual de tempo limite, inspeção visual de camadas e navegação segura entre fases:

1. **Pipeta / Conta-Gotas Instantâneo (`Alt + Clique Esquerdo`):** Permite copiar qualquer objeto (`rock`, variantes de flores `flower_*`, `wheat`), o marcador de `cutter_spawn`, a cor de grama vetorial (`grass_*`) ou o solo de terreno diretamente do mapa 3D sem procurar nos menus laterais.
2. **Botão `"⚡ Auto"` ao lado do Cronômetro (`⏱️(s)`):** Calcula e preenche automaticamente o `time_limit` recomendado com base na geometria real da fase aplicando a fórmula canônica **Abordagem 3 + 10%**.
3. **Botões de Visibilidade (`👁️` / `🚫`) por Camada + Toggle `"🌿 3D: ON/OFF"`:**
   - Oculta/exibe individualmente qualquer camada (`Terreno`, `Grama`, `Objetos`) com 1 clique.
   - Permite visualizar os tufos 3D volumétricos reais (`VegetationGrid`) diretamente no Modo Edição, mantendo a malha vetorial plana ultrarrápida (`< 0.5ms`) durante o arrasto ativo do mouse (`is_painting_lmb`).
4. **Indicador de Alterações Não Salvas (`*`) e Navegação Rápida `◀` / `▶` (até Fase 200):**
   - Expande o seletor de fases de `50` para `200`, adiciona botões rápidos `◀` e `▶`, sinaliza alterações pendentes no botão `"💾 Salvar* [Ctrl+S]"` em tom âmbar e protege contra perda acidental ao trocar de fase com o modal `unsaved_dialog`.

---

## 2. Solução Técnica Implementada

### 2.1 Pipeta / Conta-Gotas com Prioridade Visual Top-Down (`_pick_at_cursor`)
- Implementado em `scripts/editor/level_editor.gd`:
  - Ao detectar `MOUSE_BUTTON_LEFT` com `event.alt_pressed`, aciona `_pick_at_cursor(event.position)`.
  - Inspeciona o ponto clicado em ordem visual de empilhamento (de cima para baixo: `Spawn -> Objeto -> Grama Vetorial -> Terreno`), garantindo que clicar sobre uma Rosa Azul plantada em cima da Grama Verde copie a Rosa Azul (com sua variante cromática e rotação exatas), e clicar sobre o tapete de grama copie a cor da grama.
  - Sincroniza automaticamente a camada ativa (`active_layer`), ferramenta (`ToolMode.BRUSH` ou `ToolMode.SPAWN`), rotação (`current_rotation`) e dock inferior de variações (`PanelVariationsDock`).

### 2.2 Cálculo Automático de Tempo (`calculate_recommended_time_limit` & `⚡ Auto`)
- Adicionado o botão `"⚡ Auto"` ao lado de `⏱️(s)` na barra superior de `scripts/editor/level_editor_ui.gd`.
- Implementada a função `calculate_recommended_time_limit()` em `scripts/editor/level_editor.gd`:
  - Conta tufos amostrados (`cached_tuft_counts`), flores (peso de 3 hits), trigos (peso de 2 hits) e rochas (fator de desvio $+0.025$ por rocha até $+0.45$).
  - Aplica velocidade linear de $6\text{ blocos/s}$, faixa de corte da lâmina de $1.80\text{m}$ ($\approx 4.5$ células de $0.40\text{m}$), fator de manobra de $1.4\times$, margem de $+10\%$, arredondamento para múltiplos de $5\text{s}$ e clamp em $[20\text{s}, 240\text{s}]$.

### 2.3 Visibilidade por Camada (`👁️` / `🚫`) e Preview de Tufos 3D (`🌿 3D: ON/OFF`)
- Em `scripts/editor/level_editor_ui.gd`, cada botão de camada (`btn_layer_terrain`, `btn_layer_grass`, `btn_layer_objects`) foi encapsulado em um `HBoxContainer` acompanhado de um botão compacto `36x34` `"👁️"` (`btn_vis_layers[0..2]`).
- Em `scripts/editor/level_editor.gd`, `toggle_layer_visibility(layer_idx)` alterna `layer_visible[layer_idx]` e aplica visibilidade imediata em `_apply_layer_focus_transparency()`.
- O botão `"🌿 3D: OFF/ON"` na barra superior alterna `preview_3d_grass`. Quando ativo e sem arrasto de pintura (`not is_painting_lmb`), `_build_editor_vector_ground()` instancia `EditorPreviewVegGrid` via `LevelJsonLoader.populate_From_data()`, exibindo os tufos 3D reais diretamente na prancheta de edição.

### 2.4 Estado `is_dirty` (`*`), Modal de Proteção e Navegação `◀` / `▶` até 200
- `spin_level.max_value` expandido para `200`, ladeado pelos botões `◀` (`btn_prev_lv`) e `▶` (`btn_next_lv`).
- Todas as mutações de terreno, grama, objetos, spawn, metas e tempo acionam `_mark_dirty()`, mudando o botão salvar para `"💾 Salvar* [Ctrl+S]"` em amarelo-âmbar.
- Ao tentar trocar de fase com `is_dirty == true`, `_request_level_switch(target_lv)` exibe o `ConfirmationDialog` `unsaved_dialog` com opções para `"💾 Salvar e Abrir"`, `"🗑️ Descartar e Abrir"` ou `"Cancelar"`.

---

## 3. Validação e Testes Automatizados

- **`tests/test_editor_pacote2.gd` (`6/6` aprovados):**
  1. Verificação do limite de `spin_level.max_value == 200` e presença dos botões `◀`/`▶`, `⚡ Auto`, `🌿 3D` e `👁️`.
  2. Pipeta (`_pick_at_cursor`) amostrando Grama Verde (`grass_green`), Rosa Azul (`flower_rose_blue` a `90°`), Rocha (`rock`) e Spawn (`cutter_spawn`).
  3. Cálculo automático de tempo (`calculate_recommended_time_limit` e `apply_auto_calculated_time`) retornando múltiplos de `5s` em `[20s, 240s]`.
  4. Visibilidade individual por camada (`toggle_layer_visibility` nas camadas `0`, `1` e `2`).
  5. Toggle de Preview 3D dos Tufos (`toggle_3d_grass_preview` instanciando e limpando `EditorPreviewVegGrid`).
  6. Rastreamento de alterações não salvas (`is_dirty`, texto `"💾 Salvar* [Ctrl+S]"`) e limpeza após `save_current_level()`.
- **Testes de Regressão:** `test_editor_pacote1.gd` (`5/5`), `test_terrain_hole_and_curvature.gd` (`7/7`) e `verify_levels_integrity.gd` (`40/40`) executados com 0 warnings e 100% de sucesso.
