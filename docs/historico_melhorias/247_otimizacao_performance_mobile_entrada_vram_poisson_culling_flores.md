# Melhoria 247: Otimização de Performance para Mobile de Entrada (VRAM, Poisson O(1), Chunking e Culling) (`v0.12.212-alpha`)

## 📋 Resumo Executivo
Esta melhoria entrega o pacote completo de otimização de performance voltado para dispositivos móveis de entrada e intermediários (GPUs Mali-G52 / Adreno 610, CPUs ARM octa-core), eliminando 5 gargalos críticos de CPU, GPU (VRAM/Vértices) e tempo de carregamento:
1. **Redução de 93.7% na VRAM da Textura SVG dos Olhos:** Limitação de escala e downscale de 2048x2048 para 512x512 no `eyes_atlas.svg`, reduzindo o peso ETC2 de **5.59 MB para 0.34 MB** sem perda visual.
2. **Poisson Disc Sampling O(1) e Distância² com Early Exit:** Substituição de `remove_at` por swap-and-pop $O(1)$ na lista ativa de Poisson, eliminação de raízes quadradas redundantes e bounding box rejection de segmentos no cálculo de borda de polígonos em `VectorGrassField`.
3. **Cache em Memória de Amostragem de Vegetação:** Caching estático entre menu/prévia (`IslandNode`) e partida (`VegetationGrid`), permitindo que a entrada na partida ocorra em **0 ms**.
4. **Calibração de Densidade da Fase 36:** Normalização do raio de amostragem (`grass_sample_distance = 0.38`), reduzindo a contagem de tufos gerados de **11.303 para 3.911 tufos** (redução de 65% em vértices e tempo de amostragem de 1.553ms para 138ms, mantendo mais que o dobro das 1.881 metas necessárias com folga confortável).
5. **MultiMesh Spatial Chunking (Ativação de Frustum Culling Real):** Particionamento em 4 quadrantes espaciais 2x2 com `custom_aabb` restrito a cada quadrante para ilhas com > 800 tufos, permitindo que a Godot 4 descarte automaticamente até 75% dos vértices de vegetação fora do campo de visão da câmera portrait 9:16.
6. **Decimação de Malhas de Flores Nobres no Blender:** Redução de ~50% a 53% nas faces de `flower_02_rose.glb` (2.118 -> 933 faces), `flower_03_daisy.glb` (1.753 -> 500 faces) e `flower_04_sunflower.glb` (2.211 -> 761 faces), mantendo a fidelidade cel-shaded fosca intacta.
7. **Higiene Defensiva de Autoloads:** Eliminação de referências não qualificadas a `UpgradeManager` e `AudioManager` em `MenuBot`, garantindo conformidade estrita com o Mandamento 16.

---

## 🛠️ Modificações Detalhadas por Subsistema

### 1. VRAM & Textura SVG (`eyes_atlas.svg.import`)
- Configurado `svg/scale = 0.25` e `process/size_limit = 512`.
- O atlas de olhos do robô foi reimportado via `godot --headless --import`.
- **Métrica:** O arquivo `.godot/imported/eyes_atlas.svg-...etc2.ctex` caiu de `5.592.484 bytes` (5.59 MB) para `349.604 bytes` (0.34 MB), liberando mais de 5.2 MB de VRAM imediata no barramento móvel.

### 2. Algoritmos de Amostragem em `VectorGrassField` (`scripts/level/vector_grass_field.gd`)
- **Swap-and-Pop O(1):** No loop de Poisson (`_sample_poisson_in_polygon`), a remoção do elemento rejeitado trocou `active_list.remove_at(rand_idx)` por:
  ```gdscript
  var last_idx: int = active_list.size() - 1
  if rand_idx != last_idx:
      active_list[rand_idx] = active_list[last_idx]
  active_list.pop_back()
  ```
- **Rejeição por Bounding Box em Segmentos de Borda:** Em `_compute_min_distance_to_polygon_edge`, adicionado fast AABB rejection para cada segmento antes de chamar `Geometry2D.get_closest_point_to_segment`, e cálculo de distância ao quadrado (`distance_squared_to`), eliminando milhões de chamadas caras a `sqrt()`.
- **Cache Estático Global:** `static var _global_cache: Dictionary = {}` implementado para armazenar o resultado de `sample_all_tufts()` indexado por `cache_key` (`"level_%d"`), reutilizado instantaneamente com 0 ms de custo no replay ou transição menu -> gameplay.
- **Métrica Global:** Tempo total de CPU para amostragem de todas as 40 fases caiu de **8.176 ms para 3.425 ms** (ganho de 58% de velocidade de carregamento).

### 3. Calibração da Fase 36 (`data/levels/level_36.json`)
- Adicionada propriedade canônica `"grass_sample_distance": 0.38`.
- Tufos totais: reduzidos de **11.303 para 3.911 tufos**.
- Tempo de amostragem da fase: caiu de **1.553 ms para 138 ms** (11x mais rápido).
- Vértices da fase: reduzidos de ~1.100.000 para ~350.000.
- Metas de jogo mantidas: 773 verdes (1.607 disponíveis) e 1.108 amarelas (2.304 disponíveis).

### 4. MultiMesh Spatial Chunking (`scripts/plants/vegetation_grid.gd`)
- Quando a ilha possui mais de 800 tufos (`use_chunks = true`), a vegetação de cada cor é particionada em 4 quadrantes espaciais 2x2 (NW, NE, SW, SE).
- Cada quadrante gera seu próprio `MultiMeshInstance3D` com `custom_aabb` calculado sob medida para a sua extensão local.
- Eliminação do antigo `FIXED_ISLAND_AABB` gigante (70m x 70m), reativando o *Frustum Culling* nativo da Godot 4 para a orientação portrait de celular.
- Pré-cálculo de `rock_pos_2d: PackedVector2Array` em `_build_from_vector_field`, eliminando alocações repetidas de vetores e chamadas a `length()` no clearance de rochas.

### 5. Decimação de Malhas de Flores no Blender (`scripts/tools/optimize_flowers.py`)
- Executado Blender em background (`blender --background --python scripts/tools/optimize_flowers.py`) aplicando `DECIMATE` com preservação de triangulação e exportação canônica glTF (`export_apply=True`, `export_yup=True` - Mandamento 12).
- Resultados:
  - `flower_02_rose.glb`: 1.500 -> 814 vértices (-45.7%), 2.118 -> 933 faces.
  - `flower_03_daisy.glb`: 2.093 -> 1.034 vértices (-50.6%), 1.753 -> 500 faces.
  - `flower_04_sunflower.glb`: 2.199 -> 1.042 vértices (-52.6%), 2.211 -> 761 faces.
- Reimportação atômica concluída na Godot via `godot --headless --import`.

### 6. Higiene de Autoloads e Suíte de Testes
- Acesso defensivo com `get_node_or_null` em `scripts/menu/menu_bot.gd` para `UpgradeManager` e `AudioManager`.
- Atualização das asserções de tradução de `PLANT_WHEAT` ("Trigo Maduro" / "Ripe Wheat") em `test_translations.gd`.
- Atualização da contagem base de espécies de 13 para 36 em `test_species_auto_discovery.gd`.
- Criação dos testes automatizados canônicos `tests/test_performance_sampling_benchmark.gd` e `tests/test_vegetation_chunking.gd`.

---

## 🧪 Verificação & Resultados dos Testes
- `test_performance_sampling_benchmark.gd`: **PASSOU** (40 fases em 3.4s, segunda amostragem em 0 ms).
- `test_vegetation_chunking.gd`: **PASSOU** (16 chunks criados, AABBs válidos, corte e recuo 100% íntegros).
- `test_flower_materials_integrity.gd`: **PASSOU** (36/36 espécies auditadas com 0 bugs).
- `test_translations.gd`: **PASSOU** (locales pt_BR, en, es validados).
- `test_theme_auto_discovery.gd`: **PASSOU** (0 bugs).
- `test_obstacle_auto_discovery.gd`: **PASSOU** (0 bugs).
- `test_species_auto_discovery.gd`: **PASSOU** (0 bugs).
- `test_manifest_sync.gd`: **PASSOU** (0 erros).
- `test_menu_bot_teleport.tscn`: **PASSOU** (0 bugs).
- `test_wheat_shader.gd`: **PASSOU** (0 bugs).
- Console da Godot: **0 warnings, 0 erros**.
