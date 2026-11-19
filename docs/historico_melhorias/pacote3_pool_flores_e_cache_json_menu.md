# Histórico de Melhorias: Pacote 3 — Pool de Flores e Cache Estático JSON/Clippings do Menu 🌺💾

**Versão Associada:** `v0.12.208-alpha`  
**Data de Conclusão:** 19/11/2026  
**Status:** Concluído e Validado  

---

## 1. Visão Geral e Contexto do Problema

Para reduzir picos de alocação em memória heap e travamentos de I/O síncrono em smartphones modestos sem alterar o comportamento visual ou de gameplay, o **Pacote 3** atacou dois pontos recorrentes de pressão em CPU/GC:

1. **Corte de Flores (`scripts/plants/flower_detach_piece.gd` & `scripts/plants/plant.gd`):** Cada 1º hit em qualquer espécie de flor criava 3 novos nós `FlowerDetachPiece` e 3 nós filhos `MeshInstance3D` via `.new()`, anexava na árvore de cena e chamava `queue_free()` ~2.4s depois.
2. **Inicialização do Menu Principal (`scripts/level/level_card_data.gd`, `scripts/menu/island_node.gd` & `scripts/menu/main_menu.gd`):** Ao abrir ou retornar ao Menu Principal:
   - `MainMenu._detect_levels_and_build_archipelago()` executava um loop de 100 verificações `FileAccess.file_exists()` mesmo com `GameManager.get_total_levels()` já em cache.
   - Para cada uma das 40 ilhas, `IslandNode.read_island_metadata()`, `IslandNode.build_miniature_from_json()` e `LevelCardData.get_level_card_data()` abriam e faziam `JSON.parse_string()` do mesmo arquivo `level_XX.json` múltiplas vezes.
   - Além disso, `IslandNode` repetia os recortes booleanos Clipper (`VectorGrassField.clip_shapes`) para todas as rochas e clareira de spawn tanto em `_build_vector_ground()` quanto em `_ensure_3d_veg_built()`.

---

## 2. Modificações Implementadas

### 2.1 Pool Estático Reutilizável de Pétalas e Folhas (`FlowerDetachPiece` + `Plant`)
- **`scripts/plants/flower_detach_piece.gd`:**
  - Adicionados `const POOL_MAX_SIZE: int = 24`, `const POOL_HOST_NAME: StringName = &"FlowerDetachPoolHost"`, `static var _pool: Array[FlowerDetachPiece] = []` e `var mesh_instance: MeshInstance3D = null`.
  - Implementados `FlowerDetachPiece.acquire()` e `FlowerDetachPiece.release(piece)` para reaproveitamento completo do par `FlowerDetachPiece` + `MeshInstance3D` (`cast_shadow = SHADOW_CASTING_SETTING_OFF`, `physics_interpolation_mode = PHYSICS_INTERPOLATION_MODE_OFF`).
  - Peças recicladas após o término do encolhimento (`_recycle()`) têm `_process` e `visible` desativados, são desanexadas da cena ativa (`remove_child`) e armazenadas sob o container inativo `/root/FlowerDetachPoolHost` (`process_mode = PROCESS_MODE_DISABLED`, `visible = false`), evitando vazamentos no `ObjectDB` ao encerrar a árvore e preservando o reuso entre trocas de cena.
  - Em `launch(...)`, todos os temporizadores/flags (`_landed`, `_shrink_timer`, `_flight_timer`) e o estado ativo (`visible = true`, `set_process(true)`, `reset_physics_interpolation()`) são redefinidos antes da inserção na cena.
- **`scripts/plants/plant.gd`:**
  - `spawn_flower_detach_pieces()` agora utiliza `FlowerDetachPiece.acquire()`, atualizando `piece.mesh_instance.mesh` e `piece.mesh_instance.material_override` sem chamadas recorrentes a `.new()`.

### 2.2 Cache Estático Unificado de JSON/Metadados e Deduplicação Clipper
- **`scripts/level/level_card_data.gd`:**
  - Expandido o cache estático com `_json_cache` e `_meta_cache`.
  - Adicionados `LevelCardData.get_cached_level_json(level_num)` (carregando via `LevelJsonLoader.load_json_file()` uma única vez por sessão) e `LevelCardData.get_cached_island_meta(level_num)` (dimensões e posição de spawn em $O(1)$).
  - Atualizado `get_level_card_data()` para ler de `get_cached_level_json()` e `clear_cache()` para invalidar `_cache`, `_json_cache` e `_meta_cache` em sincronia quando `LevelSerializer.save_level_json()` salva alterações no Editor.
- **`scripts/menu/island_node.gd`:**
  - `read_island_metadata(lvl)` consulta `LevelCardData.get_cached_island_meta(lvl)` sem I/O nem `JSON.parse_string()`.
  - `build_miniature_from_json(lvl)` consome `LevelCardData.get_cached_level_json(lvl)` em memória.
  - Adicionado `_get_base_clipped_vector_field()` com cache de instância (`_cached_clipped_shapes`, `_cached_clipped_next_id`, `_has_clipped_shapes`) compartilhando os polígonos já recortados por rochas e spawn entre `_build_vector_ground()` e `_ensure_3d_veg_built()`.
- **`scripts/menu/main_menu.gd`:**
  - `_detect_levels_and_build_archipelago()` passa a consultar `GameManager.get_total_levels()` quando `GameManager` está disponível, mantendo fallback de varredura apenas em cenários isolados.

---

## 3. Arquivos Modificados

| Arquivo | Modificação |
| :--- | :--- |
| `scripts/plants/flower_detach_piece.gd` | Pool estático (`acquire`/`release`), host inativo `/root/FlowerDetachPoolHost` e reciclagem em `_recycle()`. |
| `scripts/plants/plant.gd` | Substituição de `.new()`/`MeshInstance3D.new()` por `FlowerDetachPiece.acquire()` em `spawn_flower_detach_pieces()`. |
| `scripts/level/level_card_data.gd` | Cache estático `_json_cache` e `_meta_cache` (`get_cached_level_json`, `get_cached_island_meta`, `clear_cache`). |
| `scripts/menu/island_node.gd` | Leitura via cache em `read_island_metadata()` e `build_miniature_from_json()`, mais `_get_base_clipped_vector_field()`. |
| `scripts/menu/main_menu.gd` | Uso de `GameManager.get_total_levels()` em `_detect_levels_and_build_archipelago()`. |
| `scripts/core/game_version.gd`, `project.godot`, `export_presets.cfg` | Bump SemVer `0.12.208-alpha` (`version/code=1408`). |
| `docs/05_arquitetura_e_desenvolvimento/PLANO_MESTRE_DE_PERFORMANCE.md` | Registro da tarefa 3.7 (Pacote 3) como concluída. |

---

## 4. Testes e Validação (Headless CLI)

Executados na versão `v0.12.208-alpha` sem warnings de GDScript ou vazamentos do pool:
- `res://tests/test_flower_detach.gd` — **Aprovado** (`RESULTADO FINAL 8 FLORES: OK`, exit code `0`, 3 peças ativas durante voo e 0 peças restantes na flor após reciclagem; verificado com `--verbose` sem vazamentos de `FlowerDetachPiece`/`MeshInstance3D`).
- `res://tests/test_island_node_lvl4.tscn` — **Aprovado** (exit code `0`, `Veg3DContainer` com 3 `MultiMeshInstance3D` e materiais íntegros).
- `res://tests/test_menu_bot_view_clearance.tscn` — **Aprovado** (exit code `0`, 905 instâncias verificadas sem obstrução frontal na Ilha 5 e tratamento de rocha no Level 9).
- `res://tests/test_android_lifecycle_and_navigation.tscn` — **Aprovado** (exit code `0`, suíte completa de ciclo de vida Android, Safe Area, HUD e navegação no Menu Principal).
- `res://scenes/main.tscn` (`--headless --quit`) — **Aprovado** (exit code `0`).
