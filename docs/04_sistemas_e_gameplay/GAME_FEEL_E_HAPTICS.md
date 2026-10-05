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

## 3. Câmera Isométrica Elevada com Translação Pura (X e Z)

- **Posicionamento e Orientação Fixa:**
  - Câmera 3D em perspectiva inclinada com ângulo zenital elevado ($Y = +11.0\text{m}$, $Z = +7.5\text{m}$ relativo ao cortador).
  - **Rotação Travada:** A orientação angular é fixada estritamente no `_ready()` (sem chamada de `look_at()` no `_process()`), eliminando qualquer oscilação ou giro dinâmico quando o cortador manobra.
  - FOV de $48^\circ$, proporcionando excelente amplitude e profundidade da ilha sem distorção excessiva de perspectiva em telas verticais (Portrait).
- **Amortecimento com Interpolação Linear (`lerp`) Exclusivo em X e Z:**
  - A câmera translada suavemente acompanhando a coordenada do cortador apenas nos eixos $X$ e $Z$ com `follow_speed = 8.0 * delta`, mantendo a altura $Y$ constante e a imagem perfeitamente estável.
- **Camera Shake Procedural Translacional:**
  - Em impactos com obstáculos, o `GameManager` emite um sinal de tremor com intensidade $0.35$ e duração $0.20\text{s}$.
  - A perturbação aplica offsets aleatórios de translação apenas em $X$ e $Z$, preservando a rotação 100% rígida e sem náuseas visuais.
