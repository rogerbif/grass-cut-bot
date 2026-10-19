# Sistema de Obstáculos e Terreno da Ilha 🪨🪵

Este documento descreve a topografia dos gramados, a contenção física da ilha e o comportamento mecânico dos obstáculos em **Grass Cut Bot**.

---

## 1. Topografia de Ilhas 3D sobre o Oceano (Sem Cercas)

Para proporcionar uma experiência limpa, solar e convidativa, cada nível ocorre sobre uma **Ilha 3D Modular sobre o Oceano (`water_ocean.tscn` e kit de tiles em `scenes/editor/tiles/`)**:
- **Oceano Turquesa (`WaterOcean`):**
  - Superfície azul turquesa fosca (`Color(0.18, 0.65, 0.78)`, `roughness = 0.88`) posicionada em `Y = -0.71m` (linha d'água calibrada na base da falésia).
- **Blocos Modulares de Ilha em GLB ($0.80\text{m} \times 0.80\text{m} \times 0.72\text{m}$):**
  - Modelos 3D estilizados exportados do Blender (`assets/models/tiles/`) utilizando a paleta de texturas atlas `GRADIENT` compartilhada:
    - **Quinas Externas Arredondadas (`tile_island_corner_out.glb`):** Curvatura cilíndrica suave ($R = 0.28\text{m}$) com 6 subdivisões angulares e *smooth shading*, eliminando cantos pontudos.
    - **Bordas Retas (`tile_island_edge.glb`):** Falésia vertical com lábio superior de grama arredondado e faixa de espuma d'água contínua na linha d'água integrada à própria malha 3D.
    - **Piso Central (`tile_island_center.glb` e `tile_island_dirt.glb`):** Grama esmeralda ou terra/trilha alaranjada no topo.
  - Geometria limpa e contínua: sem caixas procedurais sobrepostas, eliminando z-fighting e quinas quadradas artificiais.
- **Contenção Física Costeira Invisível (Zero Cercas):**
  - Todas as bordas da ilha voltadas para a água recebem colisores invisíveis na Camada Física 1 (`Layer 1: Ground & Limits`), gerados por `LevelJsonLoader.build_coastal_colliders_and_foam()`.
  - Função: Impedir que o robô cortador caia na água sem necessitar de cercas ou muretas visuais.

---

## 2. Obstáculos Sólidos: Rochas Low Poly (`rock.tscn`)

As rochas atuam como barreiras táticas que obrigam o jogador a contornar o cenário e planejar linhas eficientes de corte contra o relógio:
- **Corpo e Colisão:**
  - Instanciadas como `StaticBody3D` pertencentes ao grupo `"obstacles"`.
  - Camada de colisão: `Layer 4: Obstacles` (`collision_layer = 8`).
  - Colisor: `CylinderShape3D(radius = 0.55m, height = 0.8m)`.
- **Composição Visual Low Poly:**
  - Duas caixas anguladas empilhadas (`BaseRock` e `TopRock`) com rotações assimétricas e acabamento fosco cinza ardósia (`Color(0.42, 0.46, 0.5)`).
- **Interação com a Serra:**
  - A colisão física é estanque (o cortador desliza nas faces tangenciais ou ricocheteia frontalmente).
  - Colisões frontais com velocidade disparam o estado de choque com faíscas e recuo elástico do cortador.
