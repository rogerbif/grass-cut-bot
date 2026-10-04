# Sistema de Obstáculos e Terreno da Ilha 🪨🪵

Este documento descreve a topografia dos gramados, a contenção física da ilha e o comportamento mecânico dos obstáculos em **Grass Cut Bot**.

---

## 1. Topografia e Ilha de Gramado (`terrain.tscn`)

Para proporcionar uma experiência focada e relaxante, cada nível ocorre sobre uma **ilha compacta delimitada**:
- **Piso Principal (`GroundMesh`):**
  - Malha `BoxMesh(18.0, 0.4, 16.0)` rebaixada em `Y = -0.2m`.
  - Material verde profundo fosco (`albedo_color = Color(0.18, 0.44, 0.22)`, `roughness = 0.95`), simulando a grama recém-aparada sob os tufos altos.
- **Paredes Limítrofes (Cercas de Contenção):**
  - Quatro bordas nas extremidades (Norte, Sul, Leste e Oeste) construídas com `BoxShape3D` e malhas de madeira tratada fosca (`Color(0.48, 0.35, 0.26)`).
  - Configuradas na Camada Física 1 (`Layer 1: Ground & Limits`).
  - Função: Impedir que a inércia do cortador o projete para fora da área jogável, mantendo a navegação segura e fluida.

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
