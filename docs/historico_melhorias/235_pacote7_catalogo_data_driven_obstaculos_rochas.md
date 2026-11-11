# Histórico de Melhoria: Pacote 7 — Catálogo Data-Driven para Obstáculos e Rochas (`RockData` & `ObstacleDatabase`) 🪨📐

- **Data de Conclusão:** 11/11/2026
- **Versão:** `v0.12.189-alpha` (Build Code: `1389`)
- **Status:** Entregue e Validado (Suíte de Testes 100%)
- **Subdomínio:** Gameplay, Mecânicas e Entidades / Arquitetura & GDScript
- **Arquivos Afetados:**
  - `scripts/obstacles/rock_data.gd` (Novo)
  - `scripts/obstacles/obstacle_database.gd` (Novo)
  - `data/obstacles/rock_slate.tres` (Novo)
  - `data/obstacles/rock_moss.tres` (Novo)
  - `data/obstacles/rock_spire.tres` (Novo)
  - `data/obstacles/rock_moss_spire.tres` (Novo)
  - `data/obstacles/rock_sandstone.tres` (Novo)
  - `data/obstacles/rock_boulder.tres` (Novo)
  - `tests/test_obstacle_auto_discovery.gd` (Novo)
  - `scripts/editor/tile_palette_db.gd`
  - `scripts/level/level_json_loader.gd`
  - `scripts/editor/level_editor.gd`
  - `scripts/menu/island_node.gd`
  - `scripts/core/game_version.gd`
  - `project.godot`
  - `export_presets.cfg`
  - `docs/historico_melhorias/INDICE_MELHORIAS.md`

---

## 1. Contexto e Motivação

Seguindo o sucesso da arquitetura Data-Driven e de Auto-Descoberta de espécies botânicas introduzida nos Pacotes 4 e 5, o subsistema de obstáculos sólidos (rochas) ainda dependia de estruturas rígidas e código duplicado:
1. **Declarações Estáticas em Múltiplos Arquivos:** As 6 variedades de rochas (`rock`, `rock_moss`, `rock_spire`, `rock_moss_spire`, `rock_sandstone`, `rock_boulder`) estavam declaradas manualmente em `TilePaletteDB.ITEM_VARIATIONS` e em dicionários de `LevelJsonLoader.OBJECT_SCENES`.
2. **Cenas Duplicadas:** Diversas cenas em `scenes/obstacles/rock_*.tscn` continham estruturas quase idênticas de `StaticBody3D` (layer 8, grupo `obstacles`), com apenas referências distintas a arquivos `.glb`.
3. **Monocromatismo no Mapa Mundi:** No arquipélago em miniatura do menu principal (`IslandNode`), todas as rochas eram renderizadas usando a malha única de ardósia (`rock.glb`) com material cinza fixo, ignorando as espécies reais selecionadas no editor de fases.

---

## 2. Implementações Realizadas

### A. Classe de Recurso `RockData` (`scripts/obstacles/rock_data.gd`)
- Criada a classe `class_name RockData extends Resource` com atributos tipados:
  - **Identidade:** `id`, `aliases`, `name`, `full_name`, `icon`, `color`, `category = "obstacle"`, `order`.
  - **Física & Gameplay:** `collision_radius` ($0.18\text{m}$), `collision_height` ($0.8\text{m}$), `clearance_radius` ($0.90\text{m}$), `xp_penalty` ($1000\text{ XP}$).
  - **Recursos Visuais:** `mesh_path`, `material_path` (`res://shaders/rock_toon_material.tres`), `scene_path`, `visual_scale`.
  - **Método de Conversão:** `to_dict()` para compatibilidade total com `TilePaletteDB`.

### B. Recursos Canônicos `.tres` em `res://data/obstacles/`
- Criados 6 recursos modulares para as rochas canônicas:
  1. `rock_slate.tres` (`id = "rock"`, alias `rock_slate`, `order = 1`)
  2. `rock_moss.tres` (`id = "rock_moss"`, `order = 2`)
  3. `rock_spire.tres` (`id = "rock_spire"`, `order = 3`)
  4. `rock_moss_spire.tres` (`id = "rock_moss_spire"`, `order = 4`)
  5. `rock_sandstone.tres` (`id = "rock_sandstone"`, `order = 5`)
  6. `rock_boulder.tres` (`id = "rock_boulder"`, `order = 6`)

### C. Motor Central `ObstacleDatabase` (`scripts/obstacles/obstacle_database.gd`)
- Auto-descoberta dinâmica de recursos `.tres` em `res://data/obstacles/` via `DirAccess`.
- Indexação dupla $O(1)$ por ID principal e aliases.
- Extração de `Mesh` a partir de cenas `.glb` ou recursos com cache em memória.
- Instanciação de nós de física atômica (`instantiate_obstacle_node`) com suporte a nós procedurais ou cenas prontas.
- Método `get_variations()` que alimenta dinamicamente a paleta do editor.

### D. Integração no Editor de Fases e Level Loader
- `TilePaletteDB`: Os métodos `get_variations("rock")`, `has_variations("rock")`, `get_base_id_for_variant()` e `get_variation_data()` agora consultam o `ObstacleDatabase`, integrando automaticamente qualquer nova rocha ao editor sem alteração de código.
- `LevelJsonLoader.instantiate_object_node()`: Delega a criação de obstáculos para `ObstacleDatabase.instantiate_obstacle_node()`.
- `LevelEditor`: Na reconstrução 3D dos objetos (`_rebuild_objects_3d`), utiliza diretamente `LevelJsonLoader.instantiate_object_node()`.

### E. Renderização Fiel no Arquipélago 3D (`IslandNode`)
- As rochas do mapa mundi agora são agrupadas por tipo em `_rock_transforms_by_type: Dictionary`.
- Cada tipo de rocha gera um `MultiMeshInstance3D` independente com sua malha real (`ObstacleDatabase.get_mesh()`) e seu material Toon real (`ObstacleDatabase.get_material()`).
- Ocultamento frontal (`_set_rocks_in_front_hidden`) atualizado para iterar por todos os MultiMeshes da ilha.

---

## 3. Verificação e Testes

1. **Auto-Descoberta Dinâmica de Obstáculos (`tests/test_obstacle_auto_discovery.gd`):**
   - Criação em runtime de `test_crystal_rock.tres`, validação de 7 variantes, teste de instanciação com colisor Layer 8 e raio customizado, exclusão e restauração para 6 variantes. Resultado: **100% de Sucesso**.
2. **Diversidade de Rochas Tropicais (`tests/test_rock_variations.gd`):**
   - Validação da ordem na paleta, categorias e colisores de todas as 6 variantes canônicas: **100% de Sucesso**.
3. **Golden Master Test da Vegetação (`tests/test_vegetation_spatial_index.tscn`):**
   - **`GOLDEN_RESULT|PASS`** nos níveis 1, 3, 12, 20 e 40 com 100% de paridade bitwise.
4. **Demais Testes:**
   - `test_species_auto_discovery.gd` -> **PASS (100%)**
   - `test_blade_progression.tscn` -> **PASS (100%)**
   - `test_collection_system.tscn` -> **PASS (100%)**
   - `test_all_botanical_variations.gd` -> **PASS (100%)**
   - `godot --headless --import` -> **0 Erros / 0 Warnings**
