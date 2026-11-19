# Melhoria 245: Paridade de Cantos Arredondados entre Editor de Fases e Gameplay (`v0.12.209-alpha`) 🌿🏝️

## 📋 Diagnóstico e Causa Raiz

Ao criar ou editar fases no Editor de Fases (`F2`) utilizando a ferramenta de terreno vetorial (`VectorTerrainField`) e curvatura de cantos (`corner_radius > 0`), a ilha era exibida com belos cantos arredondados na tela do editor. No entanto, ao salvar a fase e carregá-la no jogo (gameplay) ou no Menu Inicial/Mapa, a ilha aparecia com cantos estritamente retos e angulosos a 90° (tanto no perímetro externo quanto em furos/canais d'água internos).

### 🔍 Causa Raiz Identificada:
1. **Exportação de Polígonos Não-Arredondados em `VectorTerrainField.to_dict()`:**
   - Em `vector_terrain_field.gd`, a função `to_dict()` realizava a seleção:
     ```gdscript
     var src_outers: Array[PackedVector2Array] = base_outer_polygons if not base_outer_polygons.is_empty() else outer_polygons
     var src_holes: Array[PackedVector2Array] = base_holes if not base_holes.is_empty() else holes
     ```
   - `base_outer_polygons` e `base_holes` armazenavam os retângulos retos originais antes da aplicação dos arcos circulares tangentes. Portanto, `to_dict()` gravava os polígonos **retos/não-arredondados** na chave `"island_polygons"` e `"island_holes"` do JSON.
2. **Omissão de Metadados em `LevelSerializer.save_level_json()`:**
   - O serializador descartava o `corner_radius` retornado por `to_dict()`, não gravando-o no arquivo da fase.
3. **Consumo Direto no Gameplay:**
   - O subsistema de carregamento (`LevelJsonLoader.get_island_polygons` e `VegetationGrid.build_from_level_json`) consome diretamente os vértices de `"island_polygons"` e `"island_holes"` para alimentar `IslandMeshBuilder.build_island_mesh()`, `IslandMeshBuilder.build_coastal_colliders()` e `IslandMeshBuilder.build_coastal_foam_mesh()`.
   - Como os polígonos no JSON estavam retos, a malha 3D, a colisão de contenção costeira e a espuma do mar eram geradas com cantos retos.
4. **Fita de Espuma Incompleta em `IslandNode`:**
   - No menu inicial/mapa, `IslandNode` chamava `IslandMeshBuilder.build_coastal_foam_mesh(island_polys)` sem passar `island_holes`, deixando lagos/furos internos sem a fita de espuma.

---

## 🛠️ Solução Implementada

### 1. `VectorTerrainField.to_dict()` e `from_dict()`
- **Exportação Fiel dos Polígonos Derivados:**
  - `"island_polygons"` e `"island_holes"` agora exportam sempre os polígonos finais arredondados (`outer_polygons` e `holes`).
  - Criação das chaves `"base_island_polygons"` e `"base_island_holes"` para preservar a geometria base retangular de edição sem perdas ou acúmulo de subdivisões.
  - Gravação garantida de `"corner_radius": snappedf(corner_radius, 0.001)`.
- **Recarga Inteligente:**
  - Em `from_dict()`, o editor prioriza carregar `"base_island_polygons"` como malha de edição, regenerando `outer_polygons` a partir de `corner_radius`. Caso ausente (fases legadas), realiza fallback transparente para `"island_polygons"`.

### 2. `LevelSerializer.save_level_json()` e `save_autosave_snapshot()`
- Serialização de `corner_radius`, `base_island_polygons` e `base_island_holes` no payload do JSON da fase e no snapshot de autosave.

### 3. `LevelJsonLoader` com Fallback Defensivo
- Em `get_island_polygons()` e `get_island_holes()`, caso `"island_polygons"` esteja vazio mas `"base_island_polygons"` esteja presente, realiza fallback automático.

### 4. `IslandNode.build_miniature_from_json()`
- Chamada de `IslandMeshBuilder.build_coastal_foam_mesh(island_polys, island_holes)` incluindo furos internos.

---

## 🧪 Validação e Testes

1. **Teste Unitário Automatizado (`test_vector_terrain_rounding.gd`):**
   - Criação de ilha vetorial 10m x 8m com canal central e `corner_radius = 0.40m`.
   - Validação de 4 vértices retos na base e 24 vértices em arco no derivado.
   - Validação de que `to_dict()` gravou os 24 vértices arredondados em `island_polygons`.
   - Validação de que `from_dict()` preservou a base reta e recalculou os vértices derivados com exatidão.
   - Execução via Godot 4.7.2 Headless com 100% de aprovação.
2. **Smoke Test Canônico (`verify_levels_integrity.gd`):**
   - Todas as 40 fases canônicas validadas com 100% de integridade e conformidade com o Mandamento 17.
