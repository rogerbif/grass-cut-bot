# Sistema do Cortador (Serra Circular) 🪚🤖

Este documento detalha a física, estrutura mecânica, lógica de movimentação, detecção de corte radial e comportamento de choque do cortador em **Grass Cut Bot**.

---

## 1. Estrutura do Cortador (`cutter.tscn`)

O cortador é instanciado a partir de um `CharacterBody3D` posicionado rente ao solo (`Y = 0.1m`), utilizando o modelo 3D oficial em glTF (`res://assets/models/grass_bot.glb`) modelado no Blender a partir do concept art ortogonal oficial, com acabamento fosco Low Poly (`roughness 0.85 ~ 0.95`):

```
Cutter (CharacterBody3D - Layer 2, Mask 1|8)
├── BodyCollision (CollisionShape3D - Cylinder r=0.45m, h=0.5m)
├── VisualPivot (Node3D - Escala 0.70x)
│   └── GrassBot (Instância de grass_bot.glb)
│       └── Robot (Node3D)
│           ├── Body (Node3D - Chassi, Cabeça, Paralama, Bateria, Container)
│           │   └── wheel (MeshInstance3D - Rolagem contínua no eixo X por velocidade)
│           └── BladeSpinner (Node3D - Rotação omnidirecional ininterrupta em Y a 1200°/s)
│               ├── blade_tier_1 (MeshInstance3D - Nv. 1-2: Lâmina Tripla de Aço 3 pontas)
│               ├── blade_tier_2 (MeshInstance3D - Nv. 3-4: Lâmina Quádrupla Ninja 4 pontas)
│               └── blade_tier_3 (MeshInstance3D - Nv. 5+: Lâmina Estelar de Titânio)
├── BladeArea (Area3D - Layer 0, Mask 4)
│   └── CollisionShape3D (Cylinder r=1.18m dinâmico, h=0.4m em Y=0.45m)
└── SparkParticles (CPUParticles3D - Faíscas amarelas em impacto seco em Y=0.45m)
```

---

## 2. Parâmetros Físicos e Movimentação

| Parâmetro | Valor Base | Efeito no Jogo |
| :--- | :--- | :--- |
| `base_speed` | `6.5 m/s` | Velocidade máxima de deslocamento linear. Escalável via upgrade de Velocidade. |
| `acceleration` | `24.0 m/s²` | Rapidez com que o cortador atinge a velocidade desejada após o toque. |
| `friction` | `18.0 m/s²` | Desaceleração suave quando o jogador solta o joystick. |
| `rotation_speed`| `1200.0 °/s` | Rotação angular ininterrupta do disco da serra em torno do eixo Y. |
| `knockback_force`| `5.0 m/s` | Impulso reverso aplicado na direção normal da colisão contra obstáculos. |

### Lógica de Vetor de Movimento e Orientação Frontal
O vetor 2D fornecido pelo joystick flutuante é convertido diretamente para o plano horizontal 3D ($X, Z$):
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
- A cada frame de física, o cortador varre as áreas sobrepostas pertencentes ao grupo `"vegetation"` e dispara `plant.cut(power)`.
- **Evolução por Upgrade:**
  - O raio da lâmina é calibrado dinamicamente: `raio = 1.18m + (nivel - 1) * 0.15m`.
  - A malha visual do disco e a área de interação com o shader de grama acompanham proporcionalmente o diâmetro da colisão.

### Tiers Modulares da Lâmina Estelar (Família Geométrica de Aço)
Todas as lâminas compartilham a mesma identidade visual: alcance radial idêntico ($R_{\text{tip}} = 1.66\text{m}$, resultando em $1.18\text{m}$ no jogo com escala de visual pivot $0.7$), furo central circular de montagem ($R_{\text{hole}} = 0.29\text{m}$), espessura de $0.042\text{m}$ com chanfro de corte e material uniforme em aço metálico cinza (`M_Aco_Lamina`):

| Tier | Nome Canônico | Geometria | Alcance Base | Requisitos de Nível |
| :--- | :--- | :--- | :--- | :--- |
| **Tier 1** | Lâmina Estelar Tripla | Estrela geométrica de 3 pontas com arestas retas | $R = 1.18\text{m}$ | Níveis 1 e 2 |
| **Tier 2** | Lâmina Estelar Quádrupla | Estrela geométrica de 4 pontas (cruz ninja) com arestas retas | $R = 1.18\text{m}$ | Níveis 3 e 4 |
| **Tier 3** | Lâmina Estelar de Titânio | Estrela geométrica de 5 pontas (pentagrama regular) com arestas retas | $R = 1.18\text{m}$ | Níveis 5 e 6 |
| **Tier 4** | Lâmina Estelar Hexagonal | Estrela geométrica de 6 pontas (hexagrama) com arestas retas | $R = 1.18\text{m}$ | Níveis 7+ |


---

## 4. Estado de Choque e Ricochete (Obstáculos)

Ao colidir frontalmente contra obstáculos sólidos (como rochas do grupo `"obstacles"`):
1. **Interrupção de Inércia e Atordoamento:** O estado `is_stunned` é ativado por 0.18s, impedindo a aceitação de comandos direcionais imediatos.
2. **Impulso Reverso (Knockback):** A velocidade do cortador é redirecionada na direção normal da colisão:
   $$\vec{v}_{\text{choque}} = \vec{n}_{\text{colisão}} \times \text{knockback\_force}$$
3. **Emissão de Faíscas:** O nó `SparkParticles` é reposicionado no ponto de contato e ativado instantaneamente.
4. **Vibração Tátil e Tremer de Câmera:** O `GameManager` emite vibração seca (`Input.vibrate_handheld(60)`) e solicita um camera shake de intensidade 0.35 por 0.2s.

---

## 5. Desativação da Lâmina no Fim de Fase

Quando o estado do jogo transita para fora de `GameState.PLAYING` (abertura de modal de vitória `VICTORY`, derrota `GAME_OVER` ou pausa `PAUSED`):
1. **Zerar Vetores:** `velocity` e `input_direction` são imediatamente forçados para `Vector3.ZERO`.
2. **Interrupção de Física:** O loop `_physics_process()` retorna antecipadamente, cessando a rotação da serra (`rotate_y`), o deslocamento (`move_and_slide()`) e o corte de vegetação (`_process_cutting()`).
3. **Imunidade a Entradas:** Quaisquer comandos do joystick ou teclado são descartados enquanto os modais estiverem abertos.
