# Melhoria 217: Diversidade de Rochas Tropicais (6 Variantes) e Seletor Visual no Editor de Fases 🪨🌴

## 1. Visão Geral e Objetivos
Esta melhoria expande a diversidade visual e tática dos obstáculos rochosos no mundo das Ilhas Tropicais do **Grass Cut Bot**. A rocha única ardósia legada foi expandida para uma família de **6 rochas tropicais exclusivas**, catalogadas a partir do asset de ambiente `plants1.blend` e integradas com pipeline Toon fosco, Vertex Colors limpos e um seletor visual de variações no Editor de Fases PC.

## 2. Catálogo das 6 Rochas Tropicais
1. **Ardósia Clássica (`rock`)**: O monólito ardósia cinza original (`Color(0.42, 0.46, 0.5)`), mantendo 100% de retrocompatibilidade com todas as fases já criadas.
2. **Rocha com Manto de Musgo (`rock_moss`)**: Rocha ardósia com platô superior coberto por musgo esmeralda vivo tropical (`RBg1_GRADIENT_0`).
3. **Monólito Ardósia (`rock_spire`)**: Pilar pontiagudo facetado de formato esguio e imponente (`RB3_GRADIENT_0`).
4. **Monólito com Musgo (`rock_moss_spire`)**: Monólito vertical encimado por densa vegetação de musgo tropical (`RBg3_GRADIENT_0`).
5. **Arenito Solar de Praia (`rock_sandstone`)**: Rocha em tom quente terracota/arenito dourado costeiro (`RG1_GRADIENT_0`).
6. **Boulder Costeiro (`rock_boulder`)**: Rocha arredondada e polida pelas ondas do mar, em tom basalto ardósia profundo (`RB2_GRADIENT_0`).

## 3. Arquitetura e Implementação Técnica
- **Pipeline 3D Blender -> Godot (Mandamento 12):**
  - Script automatizado `scripts/tools/export_tropical_rocks.py` com Blender 5.2 LTS headless.
  - Preservação estrita da matriz de mundo anatômica (`src_obj.matrix_world`) ao desvincular do objeto pai, garantindo que as rochas fiquem assentadas na base horizontal em $Y = 0.0$ no Godot e com os topos e platôs de musgo voltados para o céu.
  - Eliminação de offsets residuais de origem via `transform_apply(location=True, rotation=True, scale=True)` e centralização exata de pivô na base `(0.0, 0.0, 0.0)`.
  - Assamento limpo de Vertex Colors Toon no canal linear `COLOR_0` via `ColorAttribute` único no Blender, eliminando duplicações e artefatos de sRGB.
- **Material Canônico Toon e Cenas (Mandamentos 4, 7 e 13):**
  - Criação de `shaders/rock_toon_material.tres` com shading Toon (`diffuse_mode = TOON`, `specular_mode = TOON`, `vertex_color_use_as_albedo = true`, `roughness = 0.95`).
  - Criação de 5 novas cenas modulares em `scenes/obstacles/` (`rock_moss.tscn`, `rock_spire.tscn`, `rock_moss_spire.tscn`, `rock_sandstone.tscn`, `rock_boulder.tscn`), com grupo `"obstacles"`, `collision_layer = 8`, `collision_mask = 0` e `CylinderShape3D(radius = 0.18, height = 0.8)`.
- **Seletor de Variações no Editor de Fases:**
  - Registro da chave `"rock"` em `TilePaletteDb.ITEM_VARIATIONS` com badges, ícones e nomes das 6 espécies.
  - Atualização de `LevelEditorUi._create_variation_card` para suportar renderização de cards de rochas tropicais.
  - Generalização dos filtros no `LevelEditor` (`.begins_with("rock")`) para raio de liberação de grama, pintura e serialização JSON.
- **Suporte Geral no Jogo:**
  - Atualização do `LevelJsonLoader.OBJECT_SCENES` e método utilitário `LevelJsonLoader.instantiate_object_node`.
  - Recorte defensivo de grama sob qualquer subtipo de rocha em `VegetationField`, `VegetationGrid` e `IslandNode`.
- **Validação e Zero Warnings (Mandamento 1):**
  - Teste de regressão automatizado `tests/test_rock_variations.gd` aprovado com 0 erros e 0 warnings.
