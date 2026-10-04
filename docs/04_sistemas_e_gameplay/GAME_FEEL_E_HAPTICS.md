# Game Feel, Haptics e Câmera Isométrica ✨📳

Este documento detalha os elementos sensoriais que constroem a sensação de relaxamento, prazer tátil e polimento (*Juicy Game Feel*) em **Grass Cut Bot**.

---

## 1. Os Três Pilares do "Satisfying Game Feel"

1. **Resposta Mecânica Imediata:** Não há atraso entre a passagem da lâmina e a remoção da grama. O corte ocorre no exato instante do contato radial.
2. **Recompensa Sensorial Multissensorial:** Cada corte aciona simultaneamente:
   - Resposta visual (partículas parabólicas + animação de squeeze do tufo + piso limpo revelado).
   - Resposta de interface (card de metas com animação de pop + incremento de moedas).
   - Resposta tátil (pulso háptico no motor de vibração do smartphone).
3. **Fluidez de Movimento:** O cortador possui inércia equilibrada, permitindo deslizamento suave sem sensação de atrito excessivo.

---

## 2. Sistema de Feedback Tátil (Haptics)

O motor do jogo utiliza a API nativa da Godot para dispositivos móveis (`Input.vibrate_handheld`):

| Ação do Jogo | Duração do Pulso | Sensação no Aparelho |
| :--- | :--- | :--- |
| **Corte de Tufo Vegetal** | `15 ms` | Micro-pulso sutil quase imperceptível individualmente, mas que cria um zumbido tátil rítmico contínuo e extremamente satisfatório ao ceifar fileiras de grama em velocidade. |
| **Colisão com Obstáculo Sólido** | `60 ms` | Impacto seco e vigoroso transmitindo rigidez física da rocha e sinalizando o ricochete da lâmina. |

---

## 3. Câmera Isométrica Elevada e Suavização

- **Posicionamento e Orientação:**
  - Câmera 3D em perspectiva inclinada com ângulo zenital elevado ($Y = +11.0\text{m}$, $Z = +7.5\text{m}$ relativo ao cortador).
  - FOV de $48^\circ$, proporcionando excelente amplitude e profundidade da ilha sem distorção excessiva de perspectiva em telas verticais (Portrait).
- **Amortecimento com Interpolação Linear (`lerp`):**
  - A câmera acompanha a coordenada do cortador com fator de suavização `follow_speed = 8.0 * delta`, eliminando movimentos bruscos e mantendo o enquadramento fluido.
- **Camera Shake Procedural:**
  - Em impactos com obstáculos, o `GameManager` emite um sinal de tremor com intensidade $0.35$ e duração $0.20\text{s}$.
  - A câmera calcula offsets aleatórios nos eixos $X, Y, Z$ que decaem gradualmente até zero, conferindo peso físico ao choque da máquina.
