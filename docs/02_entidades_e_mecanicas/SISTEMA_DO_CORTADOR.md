# Sistema do Cortador (Serra Circular) 🪚🤖

Este documento detalha a física, estrutura mecânica, lógica de movimentação, detecção de corte radial e comportamento de choque do cortador em **Grass Cut Bot**.

---

## 1. Estrutura do Cortador (`cutter.tscn`)

O cortador é instanciado a partir de um `CharacterBody3D` posicionado rente ao solo (`Y = 0.1m`):

```
Cutter (CharacterBody3D - Layer 2, Mask 1|8)
├── BodyCollision (CollisionShape3D - Cylinder r=0.5m, h=0.3m)
├── VisualPivot (Node3D)
│   └── SawMesh (Node3D - gira continuamente em Y)
│       ├── BladeDisc (MeshInstance3D - Cylinder r=0.65m, h=0.04m, Aço)
│       ├── CenterMotor (MeshInstance3D - Cylinder r=0.28m, h=0.22m, Vermelho)
│       └── MotorCap (MeshInstance3D - Cylinder r=0.12m, h=0.28m, Chumbo)
├── BladeArea (Area3D - Layer 0, Mask 4)
│   └── CollisionShape3D (Cylinder r=0.65m, h=0.5m)
└── SparkParticles (CPUParticles3D - Faíscas amarelas em impacto)
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

### Lógica de Vetor de Movimento
O vetor 2D fornecido pelo joystick flutuante é convertido diretamente para o plano horizontal 3D ($X, Z$):
```gdscript
var move_dir = Vector3(input_direction.x, 0.0, input_direction.y)
if move_dir.length_squared() > 0.001:
    var target_vel = move_dir * target_speed
    velocity = velocity.move_toward(target_vel, acceleration * delta)
else:
    velocity = velocity.move_toward(Vector3.ZERO, friction * delta)
move_and_slide()
```

---

## 3. Mecânica de Corte Radial por Contato

- O cortador é omnidirecional: não existe dianteira ou traseira, o corte é uniforme em qualquer sentido de condução.
- A detecção é executada por um `Area3D` dedicado (`BladeArea`) com camada de colisão configurada para monitorar a vegetação (`collision_mask = 4`).
- A cada frame de física, o cortador varre as áreas sobrepostas pertencentes ao grupo `"vegetation"` e dispara `plant.cut(power)`.
- **Evolução por Upgrade:**
  - O raio da lâmina é calibrado dinamicamente: `raio = 0.65m + (nivel - 1) * 0.12m`.
  - A malha visual do disco acompanha proporcionalmente o novo diâmetro da área de colisão.

---

## 4. Estado de Choque e Ricochete (Obstáculos)

Ao colidir frontalmente contra obstáculos sólidos (como rochas do grupo `"obstacles"`):
1. **Interrupção de Inércia e Atordoamento:** O estado `is_stunned` é ativado por 0.18s, impedindo a aceitação de comandos direcionais imediatos.
2. **Impulso Reverso (Knockback):** A velocidade do cortador é redirecionada na direção normal da colisão:
   $$\vec{v}_{\text{choque}} = \vec{n}_{\text{colisão}} \times \text{knockback\_force}$$
3. **Emissão de Faíscas:** O nó `SparkParticles` é reposicionado no ponto de contato e ativado instantaneamente.
4. **Vibração Tátil e Tremer de Câmera:** O `GameManager` emite vibração seca (`Input.vibrate_handheld(60)`) e solicita um camera shake de intensidade 0.35 por 0.2s.
