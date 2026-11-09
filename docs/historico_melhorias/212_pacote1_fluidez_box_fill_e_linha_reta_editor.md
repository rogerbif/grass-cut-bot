# Melhoria 212: Pacote 1 de Fluidez e Ferramentas do Editor (Box Fill Vetorial, Linha Reta Shift+Clique e 60 FPS no Arrasto) 🛠️⚡

**Versão:** `v0.12.164-alpha`

## 1. Contexto e Diagnóstico
Após a migração das Camadas 0 (Terreno) e 1 (Grama) para o motor vetorial booleano (`VectorTerrainField` e `VectorGrassField`), uma auditoria completa no Editor de Fases identificou cinco pontos de atrito e inconsistência:
1. A ferramenta `[3] Retângulo (Box Fill)` ainda operava exclusivamente sobre os dicionários legados (`terrain_grid` e `object_grid`), não gerando polígonos no terreno vetorial nem na grama vetorial.
2. Criar pontes retas (inclusive diagonais) ou canais retilíneos à mão livre exigia extrema precisão manual no mouse.
3. Durante o arrasto contínuo de carimbos (`SQUARE`, `CIRCLE`, `STAR`), `_apply_brush_at` invocava `_sync_all_ui()` a cada passo do mouse, disparando `vector_grass.sample_all_tufts()` dezenas de vezes por segundo e causando quedas de FPS.
4. A validação de início do Playtest (`_start_playtest`) verificava apenas `terrain_grid.is_empty()`, podendo bloquear testes em ilhas desenhadas exclusivamente em `vector_terrain`.
5. O ajuste rápido de escala do pincel no scroll funcionava apenas com `Alt + Scroll`, enquanto `Ctrl + Scroll` movia o zoom da câmera, e a barra de status exibia atalhos legados inexistentes (`Pipeta [5]` e `Seleção [6]`).

## 2. Solução Implementada
- **Box Fill Vetorial (`_get_box_vector_polygon` & `_apply_box_fill`):**
  - Converte a área arrastada `[start_c, end_c]` em um polígono retangular exato no espaço de mundo `XZ`, exibindo preview holográfico dourado nas Camadas 0 e 1 e aplicando união booleana (`add_land` / `merge_or_add_shape`) ou escavação (`Shift` pressionado), com suporte integral ao Modo Espelho (`_get_mirrored_polygons`).
- **Linha Reta / Ponte Vetorial (`Shift + Clique`):**
  - Rastreia o último ponto clicado (`_last_vector_click_pos`) nas camadas vetoriais. Ao segurar `Shift`, o editor projeta em tempo real o preview holográfico de uma faixa/ponte reta (`BrushPatterns.create_ribbon_polygon`) conectando o ponto anterior ao cursor, aplicando-a ao clicar (tanto para construir pontes/gramados quanto para escavar canais retos com a Borracha) e permitindo encadear múltiplos segmentos consecutivos.
- **Fluidez 60 FPS no Arrasto Contínuo (`_sync_all_ui(recalc_goals: bool)`):**
  - Desacopla a reconstrução visual rápida da malha 3D (`_rebuild_3d_world()`) da varredura pesada de contagem de tufos (`update_goals_summary`), executando `sample_all_tufts()` apenas ao soltar o botão do mouse (`!mb.pressed`).
- **Validação Híbrida de Playtest & `Ctrl + Scroll`:**
  - `_start_playtest()` agora valida `vector_terrain` além de `terrain_grid`.
  - `Ctrl + Scroll` e `Alt + Scroll` ajustam a escala do pincel bloqueando o zoom simultâneo em `editor_camera.gd`.
  - Blindagem defensiva de Autoloads (`get_node_or_null("/root/...")`) aplicada em `level_editor.gd`, `isometric_camera.gd` e `floating_coin_manager.gd` conforme o Mandamento 16.

## 3. Verificação e Testes
- Suíte automatizada `tests/test_editor_pacote1.gd` (5/5 asserções aprovadas com 0 warnings e 0 erros).
- Suíte `tests/test_terrain_hole_and_curvature.gd` (7/7 testes aprovados).
- Smoke test `scripts/tools/verify_levels_integrity.gd` (40/40 fases íntegras).
