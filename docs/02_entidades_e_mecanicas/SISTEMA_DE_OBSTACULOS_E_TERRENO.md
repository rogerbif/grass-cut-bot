# Sistema de Obstáculos e Terreno da Ilha 🪨🏝️

Este documento descreve a topografia dos gramados, a contenção física da ilha, o comportamento mecânico dos obstáculos e o sistema data-driven de biomas e atmosferas em **Grass Cut Bot**.

---

## 1. Topografia de Ilhas 3D Procedurais por Polígono Vetorial Extrudado (`IslandMeshBuilder`)

Para proporcionar uma experiência limpa, solar, fluida e de altíssima performance mobile (1 Draw Call), cada nível ocorre sobre uma **Ilha 3D Procedural Unificada (`IslandMeshBuilder.gd` e `water_ocean.tscn`)**:
- **Oceano Turquesa (`WaterOcean`):**
  - Superfície azul turquesa fosca (`Color(0.18, 0.65, 0.78)`, `roughness = 0.88`) posicionada em `Y = -0.71m` (linha d'água calibrada na base da falésia).
- **Malha Procedural Única (`IslandMesh` - 1 Draw Call):**
  - Gerada proceduralmente em tempo real pela classe utilitária `IslandMeshBuilder.build_island_mesh()` a partir dos polígonos perimetrais no plano horizontal XZ (`island_polygons`):
    - **Teto Superior Planalto ($Y = 0.0\text{m}$):** Triangulação plana contínua com `Geometry2D.triangulate_polygon`, normais voltadas para cima $(0, 1, 0)$ e mapeamento UV da textura atlas esmeralda (`tile_island_center_Image_0.png`).
    - **Chanfro / Borda Arredondada Low Poly:** Lábio sutil rebaixado em $Y = -0.06\text{m}$ com avanço perimetral de $0.015\text{m}$, reproduzindo a estética de borda suave sem emendas visuais.
    - **Falésias Costeiras Verticais ($Y = -0.06\text{m}$ a $-0.72\text{m}$):** Faixa de quadriláteros verticais ao longo de cada aresta perimetral com normais externas horizontais e mapeamento UV da rocha/terra do atlas `GRADIENT`. Suporta cores temáticas dinâmicas via `IslandMeshBuilder.set_ground_parameters()`.
    - **Fechamento Submerso ($Y = -0.72\text{m}$):** Geometria estanque que penetra a superfície do oceano sem frestas ou faces internas degeneradas.
- **Espuma Costeira 2D Minimalista em Fita Contínua (`CoastalFoamRibbon` & `coastal_foam.gdshader`):**
  - Gerada proceduralmente por `IslandMeshBuilder.build_coastal_foam_mesh()`, acompanhando as normais radiais suaves dos vértices do perímetro da ilha ($C^1$) em $Y = -0.692\text{m}$.
  - Renderizada via `shaders/coastal_foam.gdshader` (`unshaded, depth_draw_never`) em duas faixas nítidas estilo 2D Toon com oscilação contínua da maré (`sin(TIME * wave_speed)`).
- **Contenção Física Costeira Invisível (Camada 1 - Zero Cercas):**
  - Todas as bordas da ilha voltadas para a água recebem barreiras físicas de colisão verticais na Camada Física 1 (`Layer 1: Ground & Limits`), geradas por `IslandMeshBuilder.build_coastal_colliders()`.
  - As caixas têm espessura de $0.06\text{m}$ e altura de $1.2\text{m}$, contendo perfeitamente o cortador sem necessitar de cercas visuais.
- **Retrocompatibilidade, JSON v4 e Cantos Arredondados Canônicos ($R = 0.28\text{m}$):**
  - Níveis legados com matriz `"terrain"` de blocos são convertidos automaticamente via união booleana (`Geometry2D.merge_polygons`) seguida de arredondamento analítico de cantos convexos (`IslandMeshBuilder.round_polygon_corners()` com raio canônico de $0.28\text{m}$ e 5 arcos de segmento).
  - Todos os 20 níveis canônicos do jogo possuem polígonos perimetrais no formato JSON v4 com cantos suaves idênticos à curvatura dos tiles originais (`tile_island_corner_out.glb`), eliminando quinas retas ásperas de 90° e garantindo continuidade suave $C^1$ tanto na malha do platô quanto na fita de espuma e nos colisores de limite.

---

## 2. Obstáculos Sólidos: Família de Rochas Tropicais (6 Variantes)

As rochas atuam como barreiras táticas que obrigam o jogador a contornar o cenário e planejar linhas eficientes de corte contra o relógio. O ecossistema de obstáculos dispõe de uma família de 6 espécies estilizadas do primeiro mundo de ilhas tropicais:

1. **Ardósia Clássica (`rock` / `scenes/obstacles/rock.tscn`):** Monólito ardósia cinza original (`Color(0.42, 0.46, 0.5)`), base canônica e 100% retrocompatível com as fases existentes.
2. **Rocha com Manto de Musgo (`rock_moss` / `scenes/obstacles/rock_moss.tscn`):** Rocha ardósia com platô superior coberto por manto verde esmeralda tropical vivo (`assets/models/rock_moss.glb`).
3. **Monólito Ardósia (`rock_spire` / `scenes/obstacles/rock_spire.tscn`):** Pilar vertical pontiagudo de ardósia facetada (`assets/models/rock_spire.glb`).
4. **Monólito com Musgo (`rock_moss_spire` / `scenes/obstacles/rock_moss_spire.tscn`):** Monólito encimado por densa vegetação tropical no cume (`assets/models/rock_moss_spire.glb`).
5. **Arenito Solar de Praia (`rock_sandstone` / `scenes/obstacles/rock_sandstone.tscn`):** Rocha em tom terracota / arenito dourado de praia tropical (`assets/models/rock_sandstone.glb`).
6. **Boulder Costeiro (`rock_boulder` / `scenes/obstacles/rock_boulder.tscn`):** Rocha arredondada e polida pelas ondas marinhas em tom basalto escuro (`assets/models/rock_boulder.glb`).

- **Corpo e Colisão:**
  - Instanciadas como `StaticBody3D` pertencentes ao grupo `"obstacles"`.
  - Camada de colisão: `Layer 4: Obstacles` (`collision_layer = 8`, `collision_mask = 0`).
  - Colisor padronizado: `CylinderShape3D(radius = 0.18m, height = 0.8m)` centralizado em `Y = 0.4m`, permitindo manobras ágeis e evitando colisões invisíveis de perímetro.
- **Material Canônico Toon Fosco (`shaders/rock_toon_material.tres`):**
  - Shading Toon cel-shaded (`diffuse_mode = TOON`, `specular_mode = TOON`, `roughness = 0.95`, `metallic_specular = 0.12`).
  - Vértices assados com cores lineares (`vertex_color_use_as_albedo = true`), dispensando texturas rasterizadas e garantindo compatibilidade total com o compilador mobile.
- **Interação com a Serra:**
  - A colisão física é estanque (o cortador desliza nas faces tangenciais ou ricocheteia frontalmente).
  - Colisões frontais com velocidade disparam o estado de choque com faíscas e recuo elástico do cortador.

---

## 3. Temas de Ilha e Atmosferas Data-Driven (`IslandThemeData` & `ThemeDatabase`)

Para permitir que cada mundo ou fase possua identidade visual, bioma, paleta de cores e atmosfera solar únicas sem código engessado em nós da cena, o projeto adota uma arquitetura desacoplada e 100% orientada a dados:

### 3.1 O Recurso `IslandThemeData` (`scripts/themes/island_theme_data.gd`)
Herdeiro de `Resource`, encapsula as propriedades visuais de um bioma completo:
- **Geologia da Ilha:**
  - `ground_color` (`Color`): Tom superior do platô de grama/terra.
  - `cliff_color` (`Color`): Cor da rocha vertical da falésia (default: `Color(0.85, 0.48, 0.28)`).
  - `dirt_color` (`Color`): Cor do extrato de terra intermediário (default: `Color(0.72, 0.38, 0.20)`).
- **Oceano e Água:**
  - `water_color` (`Color`): Cor primária do mar turquesa/oceano.
  - `water_deep_color` (`Color`): Cor de profundidade abissal.
- **Iluminação Solar (`DirectionalLight3D`):**
  - `sun_color` (`Color`): Tonalidade da luz solar direta.
  - `sun_energy` (`float`): Intensidade luminosa (ex: 1.10 no dia tropical, 0.45 à noite).
  - `sun_rotation_degrees` (`Vector3`): Ângulo e inclinação do sol no céu.
- **Ambiente e Céu (`WorldEnvironment` & `Environment`):**
  - `ambient_color` (`Color`): Luz de preenchimento ambiente.
  - `ambient_energy` (`float`): Intensidade da luz difusa global.
  - `sky_top_color` / `sky_horizon_color` (`Color`): Gradiente vertical do domo celeste.

### 3.2 Catálogo e Auto-Descoberta (`ThemeDatabase` em `scripts/themes/theme_database.gd`)
- **Varredura Dinâmica:** Escaneia automaticamente todos os arquivos `.tres` em `res://data/themes/` na inicialização do jogo ou via `ThemeDatabase.reload_themes()`.
- **Roteamento Inteligente:** Determina o tema canônico da fase com base no número do nível ou no mundo correspondente:
  - *Mundo 1 (Níveis 1 a 40):* `theme_tropical_day.tres` (Dia Tropical ensolarado).
  - *Mundo 2 (Níveis 41 a 80):* `theme_sunset_golden.tres` (Entardecer Dourado).
  - *Mundo 3 (Níveis 81 a 120):* `theme_night_stars.tres` (Noite Estrelada).
- **Aplicação Atômica (`apply_theme_to_scene`):** Injeta os parâmetros diretamente em `WorldEnvironment`, `DirectionalLight3D`, `IslandMeshBuilder` e `WaterOcean` em um único ciclo antes da construção da vegetação.
