# Sistema do Cortador (Serra Circular) 🪚🤖

Este documento detalha a física, estrutura mecânica, lógica de movimentação, detecção de corte radial e comportamento de choque do cortador em **Grass Cut Bot**.

---

## 1. Estrutura do Cortador (`cutter.tscn`)

![Concept Art Oficial - Cutter Bit](../assets/cutter_bit_concept_art.jpg)
*Figura 1: Concept Art oficial do Cutter Bit com vistas em perspectiva, anatomia mecânica (carcaça de impacto amarela, mono-wheel, bateria e luzes de LED), lâmina tripla e expressões dinâmicas.*

O cortador é instanciado a partir de um `CharacterBody3D` posicionado rente ao solo (`Y = 0.1m`), utilizando o modelo 3D oficial em glTF (`res://assets/models/grass_bot.glb`) modelado no Blender a partir do concept art ortogonal oficial, com acabamento fosco Low Poly (`roughness 0.85 ~ 0.95`):

```
Cutter (CharacterBody3D - Layer 2, Mask 1|8)
├── BodyCollision (CollisionShape3D - Cylinder r=0.45m, h=0.5m)
├── VisualPivot (Node3D - Escala 0.70x)
│   └── GrassBot (Instância de grass_bot.glb)
│       └── Robot (Node3D)
│           ├── Body (Node3D - Chassi, Cabeça, Paralama, Bateria, Container)
│           │   └── wheel (MeshInstance3D - Rolagem contínua no eixo X por velocidade)
│           └── BladeSpinner (Node3D - Rotação omnidirecional em Y: 1200°/s em movimento, 90°/s em idle)
│               ├── blade_tier_1 (MeshInstance3D - Nv. 1-2: Lâmina Tripla de Aço 3 pontas)
│               ├── blade_tier_2 (MeshInstance3D - Nv. 3-4: Lâmina Quádrupla Ninja 4 pontas)
│               └── blade_tier_3 (MeshInstance3D - Nv. 5+: Lâmina Estelar de Titânio)
├── BladeArea (Area3D - Layer 0, Mask 4)
│   └── CollisionShape3D (Cylinder r=0.90m dinâmico, h=0.4m em Y=0.45m)
└── SparkParticles (CPUParticles3D - Faíscas amarelas em impacto seco em Y=0.45m)
```

---

## 2. Parâmetros Físicos e Movimentação

| Parâmetro | Valor Base | Efeito no Jogo |
| :--- | :--- | :--- |
| `base_speed` | `6.5 m/s` | Velocidade máxima de deslocamento linear. Escalável via upgrade de Velocidade. |
| `acceleration` | `24.0 m/s²` | Rapidez com que o cortador atinge a velocidade desejada após o toque. |
| `friction` | `18.0 m/s²` | Desaceleração suave quando o jogador solta o joystick. |
| `rotation_speed`| `1200.0 °/s` | Rotação angular de alta velocidade da serra em torno do eixo Y durante a condução. |
| `idle_rotation_speed`| `90.0 °/s` | Rotação suave e lenta da lâmina em torno do eixo Y quando o robô estiver parado (idle). |
| `knockback_force`| `9.5 m/s` | Impulso reverso ampliado aplicado na direção normal da colisão ao tocar obstáculos sólidos com a serra. |

### Lógica de Vetor de Movimento e Orientação Frontal
Ao iniciar qualquer fase (no `_ready()`, no spawn de `vegetation_grid.gd` ou ao reiniciar a partida via `reset_orientation_to_camera()`), o Cutter Bit é garantido **olhando diretamente de frente para a câmera isométrica ($+Z$, `robot_body.rotation.y = 0.0`)**, estabelecendo contato visual imediato e carismático com os olhos de LED.

Durante o gameplay, o vetor 2D fornecido pelo joystick flutuante é convertido diretamente para o plano horizontal 3D ($X, Z$):
```gdscript
var move_dir = Vector3(input_direction.x, 0.0, input_direction.y)
if move_dir.length_squared() > 0.001:
    var target_vel = move_dir * target_speed
    velocity = velocity.move_toward(target_vel, acceleration * delta)
    # Alinhamento da frente do robô na direção de deslocamento (glTF +Z para frente):
    var target_angle = atan2(move_dir.x, move_dir.z)
    robot_body.rotation.y = lerp_angle(robot_body.rotation.y, target_angle, 14.0 * delta)
else:
    velocity = velocity.move_toward(Vector3.ZERO, friction * delta)
move_and_slide()
```

### Dinâmica Procedural de Suspensão e Inclinação (Game Feel)
O chassi e suas peças reagem organicamente às forças de inércia e relevo do gramado:
1. **Inclinação Longitudinal (Pitch):** O corpo inclina até $6^\circ$ para frente ao acelerar e inclina para trás ao desacelerar/frear, proporcionalmente a $(\vec{v} \cdot \vec{f}_{\text{robot}})$.
2. **Inclinação Lateral (Roll / Lean):** Ao curvar o joystick, o chassi inclina suavemente até $4.5^\circ$ no sentido da curva proporcionalmente à velocidade angular $\Delta \text{yaw} / \Delta t$.
3. **Suspensão Vertical (Bobbing & Shock):** 
   - Oscilação senoidal suave ($\pm 0.022\text{m}$) sincronizada com a velocidade de rolamento da mono-wheel.
   - Compressão súbita de suspensão ($-0.045\text{m}$) com retorno elástico amortecido em batidas contra rochas.
   - Contra-reação vertical da roda (`wheel`) absorvendo o relevo.
4. **Articulação de Braços e Cabeça:**
   - Braços da suspensão (`low_arm` e `up_arm`) rotacionam sutilmente em $X$ acompanhando o curso dos pistões.
   - O pescoço (`neck`) absorve o pitch para estabilizar a visão, e a cabeça (`head`) apresenta leve inércia/antecipação no Yaw ao virar.

---

## 3. Mecânica de Corte Radial por Contato

- O cortador opera com corte omnidirecional: o disco corta uniformemente em 360° em qualquer sentido de condução.
- A detecção é executada por um `Area3D` dedicado (`BladeArea`) com camada de colisão configurada para monitorar a vegetação (`collision_mask = 4`).
- O cortador opera de forma reativa via sinais `area_entered` / `area_exited` combinados a uma lista enxuta `_overlapping_vegetation` apenas para plantas resistentes (`max_health > 1`), eliminando alocações de `get_overlapping_areas()` a cada tick de física.
- Os parâmetros de upgrade (`_cached_blade_radius`, `_cached_cutter_speed`, `_cached_cutter_power`) ficam em cache e os uniforms de shader (`cutter_pos`, `cutter_interact_radius`) só são atualizados quando o cortador efetivamente se desloca (`distance_squared_to > 0.0004`).
- **Evolução por Upgrade:**
  - O raio da lâmina é calibrado dinamicamente: `raio = 0.90m + (nivel - 1) * 0.10m`.
  - A malha visual do disco e a área de interação com o shader de grama acompanham proporcionalmente o diâmetro da colisão.

### Tiers Modulares da Lâmina Estelar (Família Geométrica de Aço)
Todas as lâminas compartilham a mesma identidade visual: alcance radial idêntico ($R_{\text{tip}} = 1.66\text{m}$, resultando em $1.18\text{m}$ no jogo com escala de visual pivot $0.7$), furo central circular de montagem ($R_{\text{hole}} = 0.29\text{m}$), espessura de $0.042\text{m}$ com chanfro de corte e material uniforme em aço metálico cinza (`M_Aco_Lamina`):

| Tier | Nome Canônico | Geometria | Alcance Base | Requisitos de Nível |
| :--- | :--- | :--- | :--- | :--- |
| **Tier 1** | Lâmina Estelar Tripla | Estrela geométrica de 3 pontas com arestas retas | $R = 1.18\text{m}$ | Níveis 1 e 2 |
| **Tier 2** | Lâmina Estelar Quádrupla | Estrela geométrica de 4 pontas (cruz ninja) com arestas retas | $R = 1.18\text{m}$ | Níveis 3 e 4 |
| **Tier 3** | Lâmina Estelar de Titânio | Estrela geométrica de 5 pontas (pentagrama regular) com arestas retas | $R = 1.18\text{m}$ | Níveis 5 e 6 |
| **Tier 4** | Lâmina Estelar Hexagonal | Estrela geométrica de 6 pontas (hexagrama) com arestas retas | $R = 1.18\text{m}$ | Níveis 7+ |

### Capa Protetora da Serra (`blade_container`)
- O disco de corte é abraçado por um container protetor amarelo com interior em borracha grafite (`blade_container`), espelhado em Z via modificador `Mirror`.
- **Calibração Cirúrgica do Vão:** A fenda interna de passagem da lâmina possui abertura de **$0.045\text{m}$** ($z = \pm 0.0225\text{m}$), abraçando a lâmina de $0.042\text{m}$ ($z = \pm 0.0210\text{m}$) com folga mecânica limpa de apenas $1.5\text{mm}$ em cima e embaixo, eliminando vazios e conferindo encaixe aerodinâmico e realista.

---

## 4. Estado de Choque e Ricochete (Obstáculos)

Ao colidir contra obstáculos sólidos (como rochas do grupo `"obstacles"`), seja pelo perímetro da lâmina giratória (`_cached_blade_radius + obs_radius`, onde `obs_radius = 0.18m` para rochas) ou pelo corpo do cortador:
1. **Detecção Perimétrica da Lâmina:** A borda externa da serra é monitorada continuamente com base no colisor do obstáculo ($R = 0.18\text{m}$). Ao tocar a borda de uma rocha, um bloqueio elástico instantâneo reposiciona o robô para fora da malha da pedra, impedindo qualquer penetração visual fantasma.
2. **Interrupção de Inércia e Atordoamento Estendido:** O estado `is_stunned` é ativado por 0.24s (com cooldown de 0.32s), permitindo a leitura visual clara do impacto antes da retomada do joystick.
3. **Impulso Reverso Violento (Knockback Ampliado):** A velocidade do cortador recebe um impulso reverso de `9.5 m/s` na direção normal do impacto, arremessando o robô cerca de $1.2\text{m}$ para trás com atrito elástico:
   $$\vec{v}_{\text{choque}} = \vec{n}_{\text{colisão}} \times \text{knockback\_force}$$
4. **Compressão da Suspensão:** O chassi sofre afundamento vertical repentino (`shock_compression = -0.07`), transmitindo o recuo físico da batida mecânica.
5. **Emissão de Faíscas no Ponto de Contato:** O nó `SparkParticles` é reposicionado exatamente no ponto de fricção dente-de-serra contra rocha (`top_level = true`) e ativado instantaneamente.
6. **Vibração Tátil e Tremer de Câmera:** O `GameManager` emite vibração de 60ms (`Input.vibrate_handheld(60)`) e solicita um camera shake de intensidade 0.35 por 0.2s.

---

## 5. Desativação da Lâmina no Fim de Fase

Quando o estado do jogo transita para fora de `GameState.PLAYING` (abertura de modal de vitória `VICTORY`, derrota `GAME_OVER` ou pausa `PAUSED`):
1. **Zerar Vetores:** `velocity` e `input_direction` são imediatamente forçados para `Vector3.ZERO`.
2. **Interrupção de Física:** O loop `_physics_process()` retorna antecipadamente, cessando a rotação da serra (`rotate_y`), o deslocamento (`move_and_slide()`) e o corte de vegetação (`_process_cutting()`).
3. **Imunidade a Entradas:** Quaisquer comandos do joystick ou teclado são descartados enquanto os modais estiverem abertos.

---

## 6. Sistema de Olhos de LED e Expressões Emocionais 👁️🤖

A cabeça do cortador (`$VisualPivot/GrassBot/Robot/Body/head`) incorpora uma tela de exibição digital contínua (`screen_display`), gerenciada pelo controlador `RobotEyes` (`scripts/cutter/robot_eyes.gd`) em conjunto com o material `shaders/eye_display_material.tres` e o atlas vetorial `assets/textures/cutter/eyes_atlas.svg`:

- **Visor Digital Octogonal:** Malha plana contínua com mapeamento UV desdobrado de $(0, 0)$ a $(1, 1)$, permitindo expressões simétricas e assimétricas (como `? @` e `★ ♥`).
- **Shader de Matriz LED (`eye_display.gdshader`):** Renderiza scanlines horizontais digitais, efeito neon emissivo, piscar procedural suave via UV e deslocamento direcional da pupila (`look_offset`).
- **As 10 Expressões Canônicas:**
  1. `NORMAL`: Olhos circulares azuis/ciano, piscando de forma autônoma a cada 3~6s em idle.
  2. `HAPPY`: Arcos para cima `^ ^` ativados em velocidade alta e combos de corte.
  3. `SAD`: Arcos caídos com pálpebras em situações de perigo/dano.
  4. `ANGRY`: **Modo de Ataque** em vermelho vivo disparado em choques contra obstáculos sólidos.
  5. `ALERT`: Anéis vazados `O O` em amarelo.
  6. `SLEEPING`: Traços horizontais `— —` ativados automaticamente após 5.5s de inatividade.
  7. `GLITCH`: Interrogação e espiral `? @` com ruído elétrico durante o ricochete.
  8. `WINK`: Piscada com um olho em círculo e o outro em traço.
  9. `VICTORY`: Estrela e Coração `★ ♥` com pulso de brilho neon ao vencer a fase.
  10. `OFF`: Display apagado mantendo apenas as scanlines do visor quando o jogo estiver pausado.

---

## 7. Efeito de Teleporte no Mapa de Fases (Spatial Shader 3D) 🌌🤖

Ao navegar entre as ilhas no **Mapa de Fases** (`MAP_VIEW`), o cortador executa uma rotina de teleporte com desintegração e materialização física orientada por shader espacial (`shaders/teleport_effect.gdshader`), baseado no algoritmo procedural de [pend00](https://godotshaders.com/shader/teleport-effect/):

- **Desaparecendo de Cima para Baixo:** O robô na ilha de origem é varrido por uma linha horizontal de energia turquesa (`vec4(0.0, 1.02, 1.2, 1.0)`) com ruído de gradiente procedural que descarta fragmentos do topo até as rodas.
- **Transição Instantânea e Materialização de Baixo para Cima:** Na ilha de destino focada pela câmera, o robô surge a partir da base e o feixe sobe até o topo, recompondo a geometria.
- **Preservação PBR e Zero Sobrecarga:** As propriedades de cor original (`albedo_color`), texturas e reflexos da malha são clonadas no shader durante a transição; ao concluir, todos os `surface_override_material` são limpos, restaurando os materiais nativos e a tela dos olhos (`_setup_eyes()`).


