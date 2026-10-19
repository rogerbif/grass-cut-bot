# Sistema de Obstáculos e Terreno da Ilha 🪨🪵

Este documento descreve a topografia dos gramados, a contenção física da ilha e o comportamento mecânico dos obstáculos em **Grass Cut Bot**.

---

## 1. Topografia de Ilhas 3D sobre o Oceano (Sem Cercas)

Para proporcionar uma experiência limpa, solar e convidativa, cada nível ocorre sobre uma **Ilha 3D Modular sobre o Oceano (`water_ocean.tscn` e kit de tiles em `scenes/editor/tiles/`)**:
- **Oceano Turquesa (`WaterOcean`):**
  - Superfície azul turquesa fosca (`Color(0.18, 0.65, 0.78)`, `roughness = 0.88`) posicionada em `Y = -0.71m` (linha d'água calibrada na base da falésia).
- **Blocos Modulares de Ilha em GLB ($0.80\text{m} \times 0.80\text{m} \times 0.72\text{m}$):**
  - Modelos 3D estilizados exportados do Blender (`assets/models/tiles/`) utilizando a paleta de texturas atlas `GRADIENT` compartilhada:
    - **Quinas Externas Arredondadas (`tile_island_corner_out.glb`):** Curvatura cilíndrica suave ($R = 0.28\text{m}$) com simetria diagonal estrita e tolerância zero ($0.000000\text{m}$) de fresta com bordas retas e pisos.
    - **Quinas Internas Côncavas (`tile_island_corner_in.glb`):** Transição em arco côncavo suave ($R = 0.20\text{m}$) para reentrâncias e baías em curvas em "L", exportada com rotação pura (`rot_z_deg = -90`) e escala positiva (`0.40, 0.40, 0.18`) para preservar normais externas voltadas para fora e altura canônica de $0.72\text{m}$ (`scale.y = 2.0`).
    - **Pontas de Península (`tile_island_end.glb`):** Extremidade semicircular ($R = 0.20\text{m}$) de caminhos e promontórios de 1 tile ($0.80\text{m}$) com falésia em 3 lados e altura $0.72\text{m}$.
    - **Bordas Retas (`tile_island_edge.glb`):** Falésia vertical com lábio superior de grama arredondado e tampas laterais mapeadas para o marrom da falésia (`UV = (0.19, 0.83)`).
    - **Piso Central (`tile_island_center.glb` e `tile_island_dirt.glb`):** Grama esmeralda ou terra/trilha alaranjada no topo.
  - Geometria limpa e contínua: tolerância zero entre peças modulares, eliminando descontinuidades, frestas visuais e z-fighting.
- **Espuma Costeira 2D Minimalista em Curva Contínua (`CoastalFoamRibbon` & `coastal_foam.gdshader`):**
  - Gerada proceduralmente em malha única (`ArrayMesh` de 1 *draw call*) por `LevelJsonLoader.build_coastal_colliders_and_foam()`, acompanhando a equação exata da curva de cada tile costeiro (`island_edge`, arco convexo de $R = 0.32\text{m}$ em `island_corner_out`, arco côncavo de $R = 0.20\text{m}$ em `island_corner_in`, e semicírculo de $R = 0.20\text{m}$ em `island_end`) com normais radiais suaves por vértice ($C^1$).
  - Renderizada via `shaders/coastal_foam.gdshader` (`unshaded, depth_draw_never`) em duas faixas nítidas estilo 2D Toon/Minimalista com balanço suave de vai e vem da maré (`sin(TIME * wave_speed)`).
- **Contenção Física Costeira Invisível (Zero Cercas):**
  - Todas as bordas da ilha voltadas para a água recebem colisores invisíveis na Camada Física 1 (`Layer 1: Ground & Limits`), gerados por `LevelJsonLoader.build_coastal_colliders_and_foam()`.
  - Função: Impedir que o robô cortador caia na água sem necessitar de cercas ou muretas visuais.

---

## 2. Obstáculos Sólidos: Rochas Low Poly (`rock.tscn`)

As rochas atuam como barreiras táticas que obrigam o jogador a contornar o cenário e planejar linhas eficientes de corte contra o relógio:
- **Corpo e Colisão:**
  - Instanciadas como `StaticBody3D` pertencentes ao grupo `"obstacles"`.
  - Camada de colisão: `Layer 4: Obstacles` (`collision_layer = 8`).
  - Colisor: `CylinderShape3D(radius = 0.36m, height = 0.8m)`.
- **Composição Visual 3D Oficial (`rock.glb`):**
  - Modelo 3D oficial facetado low-poly exportado do Blender (`Prop_Rock` / `assets/models/rock.glb`), substituindo os blocos primitivos BoxMesh provisórios.
  - Material canônico do jogo: `StandardMaterial3D` fosco com acabamento cinza ardósia (`Color(0.42, 0.46, 0.5)` e `roughness = 0.95`), mantendo a identidade visual estabelecida.
- **Interação com a Serra:**
  - A colisão física é estanque (o cortador desliza nas faces tangenciais ou ricocheteia frontalmente).
  - Colisões frontais com velocidade disparam o estado de choque com faíscas e recuo elástico do cortador.
