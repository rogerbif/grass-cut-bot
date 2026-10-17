# Sistema de Obstáculos e Terreno da Ilha 🪨🪵

Este documento descreve a topografia dos gramados, a contenção física da ilha e o comportamento mecânico dos obstáculos em **Grass Cut Bot**.

---

## 1. Topografia de Ilhas 3D sobre o Oceano (Sem Cercas)

Para proporcionar uma experiência limpa, solar e convidativa, cada nível ocorre sobre uma **Ilha 3D Modular sobre o Oceano (`water_ocean.tscn` e kit de tiles em `scenes/editor/tiles/`)**:
- **Oceano Turquesa (`WaterOcean`):**
  - Superfície azul turquesa fosca (`Color(0.18, 0.65, 0.78)`, `roughness = 0.88`) posicionada em `Y = -0.34m`.
- **Blocos Modulares de Ilha ($0.80\text{m} \times 0.80\text{m}$):**
  - Topo verde grama (`Color(0.32, 0.64, 0.24)`) ou trilha de terra (`Color(0.56, 0.41, 0.27)`), com paredão/falésia marrom escuro (`Color(0.34, 0.23, 0.16)`) nas faces costeiras e faixa de espuma azul-clara (`Color(0.55, 0.86, 0.94)`) na linha d'água.
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
