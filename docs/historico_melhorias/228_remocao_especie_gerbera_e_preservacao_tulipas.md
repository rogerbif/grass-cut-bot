# Melhoria 228: Remoção da Espécie Redundante Gérbera e Preservação da Tulipa Unificada (`v0.12.182-alpha`)

## 1. Contexto e Motivação
Após a criação inicial da espécie botânica Gérbera Tropical associada ao modelo 3D `flower_01.glb`, constatou-se que esse modelo é a própria malha original canônica da **Flor Silvestre Nobre** (`flower`), já estabelecida e consagrada no ecossistema do jogo com suas 6 variações de cores.

A pedido expresso do usuário, a espécie Gérbera Tropical (`flower_gerbera`) foi completamente removida do ecossistema, eliminando redundâncias taxonômicas e mantendo a base de código 100% limpa, preservando intacta a unificação anatômica da **Tulipa Imperial** (`flower_07_tulip.glb`).

---

## 2. Ações Executadas

### A. Limpeza de Recursos e Cenas
- Removida a cena `scenes/plants/flower_gerbera.tscn`.
- Excluídos os 6 materiais de shader cel-shaded:
  - `shaders/flower_gerbera_material.tres`
  - `shaders/flower_gerbera_yellow_material.tres`
  - `shaders/flower_gerbera_purple_material.tres`
  - `shaders/flower_gerbera_orange_material.tres`
  - `shaders/flower_gerbera_pink_material.tres`
  - `shaders/flower_gerbera_white_material.tres`

### B. Remoção do Código e Subsistemas
1. **Editor de Fases (`scripts/editor/tile_palette_db.gd`, `level_editor.gd`, `level_editor_ui.gd`):**
   - Removido `flower_gerbera` da paleta de objetos e variações.
   - Removida a rotação de cena e tabela de metas.
   - Preservada a correção essencial de `begins_with("flower_tulip")` que garante que todas as tulipas usem `flower_07_tulip.glb`.
2. **Grade de Vegetação (`scripts/plants/vegetation_grid.gd`):**
   - Removidos materiais de `FLOWER_MATERIALS`, chaves de `VEG_TYPES`, malha estática e rotinas MultiMesh.
3. **Entidades e Dados (`scripts/plants/plant.gd`, `plant_database.gd`, `level_json_loader.gd`, `map_level_card.gd`, `island_node.gd`):**
   - Removidas as entradas de despetalação, cores, catálogo botânico, preload de objetos e visualizações de menu.
4. **Testes Unitários (`tests/test_all_botanical_variations.gd`):**
   - Atualizada a suíte botânica para testar rigorosamente as famílias ativas: Flor Silvestre, Rosa Nobre, Margarida do Campo, Girassol Solar, Tulipa Imperial e Canteiro Florido.

---

## 3. Verificação
- Suíte `tests/test_all_botanical_variations.gd` executada via Godot Headless: 100% de sucesso, 0 erros e 0 warnings.
- Validação de que nenhuma fase do jogo (`data/levels/*.json`) utiliza ou referenciava `flower_gerbera`.
- Árvore de trabalho limpa, SemVer incrementado para `v0.12.182-alpha`.
