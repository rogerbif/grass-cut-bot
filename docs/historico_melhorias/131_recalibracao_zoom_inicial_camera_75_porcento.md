# Melhoria 131: Recalibração do Zoom Inicial da Câmera para 75% de Distância

**Data:** 27 de Outubro de 2026  
**Versão:** `v0.12.54-alpha`  
**Autor:** Antigravity  

---

## 1. Contexto e Motivação

Após a implementação inicial do zoom dinâmico por nível da lâmina (Melhoria 129), a câmera iniciava no Nível 1 a 50% da distância canônica ($3,70\text{m}$, com `offset = Vector3(0.0, 2.390, 2.825)`). Na prática de gameplay, essa aproximação revelou-se excessivamente justa ("muito próximo"), diminuindo o campo de visão periférico essencial para o jogador avistar os primeiros tufos de vegetação e a margem da ilha.

O usuário solicitou: *"o zoom inicial ficou muito próximo reduza em 50%"*.  
Reduzir a aproximação (zoom-in) em 50% significa que, em vez de aproximar 50% da distância total ($0,50 \times 7,40\text{m}$), aproximamos 25% ($0,25 \times 7,40\text{m}$), fixando a distância inicial do Nível 1 em **75% da distância canônica** ($5,55\text{m}$).

---

## 2. Parâmetros e Calibração Geométrica

- **Distância Canônica (Nível 6 MAX - 100%):**
  - Offset: `Vector3(0.0, 4.780, 5.650)`
  - Distância euclidiana: $\approx 7,40\text{m}$
  - Ângulo de Pitch: $\arctan(-4,78 / 5,65) = -40,3^\circ$
- **Distância Inicial Calibrada (Nível 1 - 75%):**
  - Offset: `Vector3(0.0, 3.585, 4.2375)`
  - Distância euclidiana: $5,55\text{m}$ ($75\%$ de $7,40\text{m}$)
  - Ângulo de Pitch: $-40,3^\circ$ (inalterado e rigorosamente constante em toda a interpolação)

### Progressão Linear por Nível da Lâmina:
| Nível da Lâmina | Razão de Distância | Offset Relativo ao Cortador $(X, Y, Z)$ | Distância Total |
| :---: | :---: | :---: | :---: |
| **Nível 1 (Inicial)** | **75%** | `(0.000, 3.585, 4.2375)` | $5,55\text{m}$ |
| **Nível 2** | **80%** | `(0.000, 3.824, 4.5200)` | $5,92\text{m}$ |
| **Nível 3** | **85%** | `(0.000, 4.063, 4.8025)` | $6,29\text{m}$ |
| **Nível 4** | **90%** | `(0.000, 4.302, 5.0850)` | $6,66\text{m}$ |
| **Nível 5** | **95%** | `(0.000, 4.541, 5.3675)` | $7,03\text{m}$ |
| **Nível 6 (MAX)** | **100%** | `(0.000, 4.780, 5.6500)` | $7,40\text{m}$ |

---

## 3. Implementações Realizadas

1. **`scripts/camera/isometric_camera.gd`:**
   - Atualizado `MIN_DISTANCE_RATIO` de `0.50` para `0.75`.
   - Atualizado o offset inicial de gameplay `_current_gameplay_offset = Vector3(0.0, 3.585, 4.2375)`.
   - Preservada a interpolação via `Tween` cúbico desacelerado (`TRANS_CUBIC`, `EASE_OUT`) de $0,75\text{s}$ a cada subida de nível ou choque contra rochas.
2. **Documentação Canônica Atualizada:**
   - `docs/04_sistemas_e_gameplay/GAME_FEEL_E_HAPTICS.md`: Seção 3 atualizada com os novos valores de 75% a 100%.
   - `docs/01_visao_geral_e_gdd/DIRECAO_DE_ARTE_E_VISUAL.md`: Seção 3 sincronizada com a distância inicial calibrada.
   - `docs/historico_melhorias/INDICE_MELHORIAS.md`: Nova entrada registrada e indexada.

---

## 4. Verificação Visual e Validação

- **Captura direta de Viewport:** `snap_zoom_lv1_75.png` confirma enquadramento agradável, desobstruído e equilibrado no Nível 1.
- **Console Godot:** 0 erros e 0 warnings mantidos com tipagem estática e guardrails preservados.
