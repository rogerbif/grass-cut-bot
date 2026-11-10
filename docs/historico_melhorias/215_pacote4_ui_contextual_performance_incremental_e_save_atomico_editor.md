# 215 — Pacote 4: UI Contextual, Performance Incremental 3D e Sistema de Salvamento Blindado no Editor (`v0.12.167-alpha`)

**Data:** 09/11/2026
**Versão:** `v0.12.167-alpha` (`version/code = 1367`)
**Arquivos Modificados:**
- `scripts/editor/level_editor_ui.gd`
- `scripts/editor/level_editor.gd`
- `scripts/editor/level_serializer.gd`
- `scripts/menu/island_node.gd`
- `tests/test_editor_pacote4.gd`

---

## 🎯 Contexto e Objetivo
Dando sequência aos Pacotes 1, 2 e 3 de evolução do Editor de Fases, o **Pacote 4** concentrou-se em três frentes solicitadas pelo usuário:
1. **Simplificação e Contextualização da Interface:** remoção de botões redundantes, ocultação automática de controles irrelevantes para a ferramenta selecionada e Modo Tela Limpa (`Tab`).
2. **Performance Incremental 3D e Cache Costeiro $O(1)$:** separação da reconstrução 3D por camada para evitar retriangular a malha da ilha ao pintar grama ou objetos, e cache do polígono costeiro seguro para eliminar `Geometry2D.offset_polygon()` a 60 Hz no movimento do mouse.
3. **Sistema de Salvamento Blindado:** escrita atômica via `.tmp`, backup automático da versão anterior em `user://editor_backups/`, Auto-Save periódico a cada `45s` (e antes do Playtest) em `user://editor_autosave.json`, Validador Pré-Save e suporte completo a `island_holes` nas miniaturas 3D do Mapa Mundi (`island_node.gd`).

---

## 🛠️ Alterações Implementadas

### 1. Simplificação da UI e Painéis Contextuais (`level_editor_ui.gd`)
- **Unificação na Barra Superior:** Removido o botão legado redundante `"📦 Bake .tscn"` e unificado `"🏝️ Ilha Base"` diretamente no menu `"🏝️ Templates ▾"`.
- **Ocultação Contextual Automática (`sync_state`):**
  - Quando a ferramenta ativa é `Retângulo [3]`, `Spawn [4]` ou `Balde [5]`, a seção `"FORMATO DO PINCEL / CARIMBO"` (`lbl_shapes_node` e `grid_shapes_node`) e o painel `"Escala [S]"` (`panel_scale_box`) são ocultados automaticamente.
  - Quando a rotação não tem efeito prático (ferramentas `Caixa`/`Balde` ou formas simétricas `Único`/`Círculo` no Terreno/Grama), o bloco `"🔄 Girar [R]"` (`panel_rotate_box`) também é ocultado.
- **Templates no Painel Direito da Camada 0:** Substituídos os 4 botões duplicados de carimbos na seção `"1. ILHA 3D & TERRENO VETORIAL"` por cards diretos para os 6 Templates de Ilha.
- **Modo Tela Limpa (`Tab`):** Adicionado `toggle_clean_screen_mode()` acionado pela tecla `Tab` para ocultar/exibir os painéis laterais esquerdo e direito.

### 2. Rebuild 3D Incremental & Cache Costeiro $O(1)$ (`level_editor.gd`)
- **Separação de Rebuild por Camada:** `_rebuild_3d_world()` foi desacoplado em `_rebuild_terrain_3d()`, `_rebuild_objects_3d()` e `_rebuild_grass_3d()`. Pintar ou apagar grama reconstrói apenas a vegetação vetorial, preservando intacta a instância `IslandMesh` e os colisores costeiros.
- **Cache Costeiro (`_cached_safe_coastal_polys`):** `_get_safe_coastal_island_polygons()` agora armazena em cache o resultado de `Geometry2D.offset_polygon(..., -COASTAL_GRASS_CORRIDOR)` e só o recalcula quando `_coastal_cache_dirty == true` (invalidado apenas em `_rebuild_terrain_3d()`).

### 3. Salvamento Atômico, Backup, Auto-Save, Validador Pré-Save e Mapa Mundi (`level_serializer.gd`, `level_editor.gd`, `island_node.gd`)
- **Escrita Atômica e Backup (`LevelSerializer.save_level_json`):** Grava primeiro em `.json.tmp`, verifica integridade não vazia, faz backup da versão anterior em `user://editor_backups/level_%02d_bak.json` e substitui o `.json` final removendo o `.tmp`.
- **Auto-Save (`LevelSerializer.save_autosave_snapshot`):** Salva snapshot silencioso em `user://editor_autosave.json` a cada `45s` quando `is_dirty == true` e imediatamente antes de `_start_playtest()`.
- **Validador Pré-Save (`validate_level_before_save`):** Verifica se o Spawn está sobre terra firme (`is_point_on_land`), se há colisão de rocha com o Spawn e se a fase possui vegetação/metas, exibindo aviso claro no toast ao salvar.
- **Paridade no Mapa Mundi (`island_node.gd`):** `build_miniature_from_json` passa `LevelJsonLoader.get_island_holes(data)` para `IslandMeshBuilder.build_island_mesh(island_polys, island_holes)`, renderizando lagos e atóis nas miniaturas 3D.

---

## ✅ Verificação e Testes
- Criada e executada a suíte headless `res://tests/test_editor_pacote4.gd` validando UI contextual, Modo Tela Limpa (`Tab`), cache costeiro $O(1)$, preservação da `IslandMesh` ao pintar grama, escrita atômica + backup + auto-save e detecção de Spawn na água no Atol.
- Todas as suítes `test_editor_pacote1.gd` a `test_editor_pacote4.gd` e `verify_levels_integrity.gd` (40 fases) passaram com **0 warnings e 0 erros**.
