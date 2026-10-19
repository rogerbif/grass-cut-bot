# Melhoria 041: Remoção do Tile Modular `Tile_Cliff_Corner_Inner` dos Tiles 3D de Terreno [v0.7.4-alpha] 🏝️🌿📐

## 1. Contexto e Motivação
A peça modular côncava de terreno `Tile_Cliff_Corner_Inner` (utilizada anteriormente para reentrâncias e quinas internas de falésia) foi descontinuada a pedido do usuário. A remoção visa simplificar a geometria do terreno, evitar descontinuidades visuais e alinhar a biblioteca modular 3D aos padrões estéticos limpos das ilhas flutuantes sobre o oceano.

---

## 2. Modificações Realizadas

### A. Modelagem 3D & Blender (`enviroment.blend`)
- **Remoção e Purga de Malhas:**
  - Excluído o objeto `Tile_Cliff_Corner_Inner` da coleção `Tileset_Terrain_3D`.
  - Purgadas as malhas órfãs (`Tile_Cliff_Corner_Inner_Mesh.002` e `Mesh_Tile_Island_Corner_In`) de `bpy.data.meshes`.
- **Reexportação glTF Padronizada (Guardrail 12):**
  - Reexportado o arquivo mestre [`assets/models/terrain_tileset.glb`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/assets/models/terrain_tileset.glb) com `export_apply=True` e `export_yup=True`, contendo exclusivamente os 5 tiles canônicos e 6 props decorativos.
  - Salvo o arquivo fonte Blender `enviroment.blend`.

### B. Engine Godot 4 & Editor de Fases
- **Limpeza de Cenas e Modelos Individuais:**
  - Removida a cena modular [`scenes/editor/tiles/tile_island_corner_in.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/editor/tiles/tile_island_corner_in.tscn).
  - Removido o modelo individual `assets/models/tiles/tile_island_corner_in.glb` e arquivos associados.
- **Paleta de Terreno (`scripts/editor/tile_palette_db.gd`):**
  - Removido o item `island_corner_in` do catálogo `TERRAIN_ITEMS`.
- **Algoritmo Auto-Tile (`scripts/editor/island_autotiler.gd` & `scripts/tools/generate_levels.js`):**
  - Desativada a ramificação de busca por quinas internas diagonais.
  - Células interiores cercadas pelos 4 vizinhos cardeais agora resolvem diretamente para `island_center` com rotação 0, garantindo cobertura contínua e sem frestas.
- **Carregador de Fases (`scripts/level/level_json_loader.gd`):**
  - Atualizado `TILE_SCENES` removendo a chave obsoleta e apontando `island_dirt` para sua respectiva cena modular.
  - Preservado fallback gracioso para `island_center` caso identificadores legados sejam solicitados.
- **Regeneração de Fases (`data/levels/`):**
  - Executado o gerador `scripts/tools/generate_levels.js` regenerando as 20 fases canônicas com 0 referências a `island_corner_in`.

### C. Invalidação de Cache e Governança SemVer
- Limpos os caches compilados em `.godot/imported/*terrain_tileset*` e `.godot/imported/*tile_island_corner_in*`.
- Atualizada a documentação canônica em `docs/02_entidades_e_mecanicas/SISTEMA_DE_OBSTACULOS_E_TERRENO.md` e `docs/03_level_design_e_fases/SISTEMA_EDITOR_DE_FASES.md`.
- Versão do projeto incrementada para **`0.7.4-alpha`** em `scripts/core/game_version.gd`, `project.godot` e `export_presets.cfg`.

---

## 3. Validação e Qualidade
- **Execução via Godot MCP:**
  - `res://scenes/main.tscn`: **0 Erros, 0 Warnings**.
  - `res://scenes/editor/level_editor.tscn`: **0 Erros, 0 Warnings**.
- **Inspeção de Integridade dos Níveis:**
  - Todas as 20 fases canônicas carregam e constroem terrenos intactos, estanques e navegáveis.
