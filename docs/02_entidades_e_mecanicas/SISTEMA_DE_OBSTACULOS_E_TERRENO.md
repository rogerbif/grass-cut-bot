# Sistema de Obstáculos e Terreno da Ilha 🪨🪵

Este documento descreve a topografia dos gramados, a contenção física da ilha e o comportamento mecânico dos obstáculos em **Grass Cut Bot**.

---

## 1. Topografia de Ilhas 3D Procedurais por Polígono Vetorial Extrudado (`IslandMeshBuilder`)

Para proporcionar uma experiência limpa, solar, fluida e de altíssima performance mobile (1 Draw Call), cada nível ocorre sobre uma **Ilha 3D Procedural Unificada (`IslandMeshBuilder.gd` e `water_ocean.tscn`)**:
- **Oceano Turquesa (`WaterOcean`):**
  - Superfície azul turquesa fosca (`Color(0.18, 0.65, 0.78)`, `roughness = 0.88`) posicionada em `Y = -0.71m` (linha d'água calibrada na base da falésia).
- **Malha Procedural Única (`IslandMesh` - 1 Draw Call):**
  - Gerada proceduralmente em tempo real pela classe utilitária `IslandMeshBuilder.build_island_mesh()` a partir dos polígonos perimetrais no plano horizontal XZ (`island_polygons`):
    - **Teto Superior Planalto ($Y = 0.0\text{m}$):** Triangulação plana contínua com `Geometry2D.triangulate_polygon`, normais voltadas para cima $(0, 1, 0)$ e mapeamento UV da textura atlas esmeralda (`tile_island_center_Image_0.png`).
    - **Chanfro / Borda Arredondada Low Poly:** Lábio sutil rebaixado em $Y = -0.06\text{m}$ com avanço perimetral de $0.015\text{m}$, reproduzindo a estética de borda suave sem emendas visuais.
    - **Falésias Costeiras Verticais ($Y = -0.06\text{m}$ a $-0.72\text{m}$):** Faixa de quadriláteros verticais ao longo de cada aresta perimetral com normais externas horizontais e mapeamento UV da rocha/terra do atlas `GRADIENT`.
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

## 2. Obstáculos Sólidos: Rochas Low Poly (`rock.tscn`)

As rochas atuam como barreiras táticas que obrigam o jogador a contornar o cenário e planejar linhas eficientes de corte contra o relógio:
- **Corpo e Colisão:**
  - Instanciadas como `StaticBody3D` pertencentes ao grupo `"obstacles"`.
  - Camada de colisão: `Layer 4: Obstacles` (`collision_layer = 8`).
  - Colisor: `CylinderShape3D(radius = 0.18m, height = 0.8m)` (reduzido em 50% de $0.36\text{m}$ para $0.18\text{m}$, permitindo manobras ágeis e evitando colisões invisíveis de perímetro).
- **Composição Visual 3D Oficial (`rock.glb`):**
  - Modelo 3D oficial facetado low-poly exportado do Blender (`Prop_Rock` / `assets/models/rock.glb`), substituindo os blocos primitivos BoxMesh provisórios.
  - Material canônico do jogo: `StandardMaterial3D` fosco com acabamento cinza ardósia (`Color(0.42, 0.46, 0.5)` e `roughness = 0.95`), mantendo a identidade visual estabelecida.
- **Interação com a Serra:**
  - A colisão física é estanque (o cortador desliza nas faces tangenciais ou ricocheteia frontalmente).
  - Colisões frontais com velocidade disparam o estado de choque com faíscas e recuo elástico do cortador.
