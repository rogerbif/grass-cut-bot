# Melhoria 132: Câmera com Zoom Dinâmico de 6m a 12m por Nível da Lâmina

**Data:** 27 de Outubro de 2026  
**Versão:** `v0.12.55-alpha`  
**Autor:** Antigravity  

---

## 1. Contexto e Motivação

Com o objetivo de expandir o alcance da visão periférica tanto no estágio inicial quanto na progressão máxima da serra circular, o usuário solicitou que a distância da câmera seja configurada expressamente com:
- **Distância Inicial (Nível 1):** $6{,}0\text{ metros}$
- **Distância Final (Nível 6 MAX):** $12{,}0\text{ metros}$

A ampliação da distância máxima para $12{,}0\text{m}$ acomoda com total clareza e conforto a enorme lâmina de 6 pontas (raio de $1{,}40\text{m}$) e a velocidade máxima do robô ($4{,}75\text{m/s}$), além de permitir que o jogador aviste com folga os limites da ilha, obstáculos sólidos e rotas de colheita.

---

## 2. Parâmetros e Calibração Geométrica

- **Vetor Unitário de Direção Isométrica (Pitch constante de $-40{,}3^\circ$):**
  - Ângulo de pitch: $\arctan(-4{,}78 / 5{,}65) \approx -40{,}23^\circ \approx -40{,}3^\circ$
  - Versor normalizado: $\hat{u} = (0{,}0,\; 0{,}645925,\; 0{,}763489)$
- **Offset Inicial ($6{,}0\text{m}$):** $6{,}0 \times \hat{u} =$ `Vector3(0.0, 3.8756, 4.5809)`
- **Offset Final ($12{,}0\text{m}$):** $12{,}0 \times \hat{u} =$ `Vector3(0.0, 7.7511, 9.1619)`

### Tabela de Progressão Linear por Nível da Lâmina:
| Nível da Lâmina | Distância Euclidiana | Offset Relativo ao Cortador $(X, Y, Z)$ | Proporção (Ratio) |
| :---: | :---: | :---: | :---: |
| **Nível 1 (Base)** | **$6{,}0\text{ m}$** | `(0.000, 3.8756, 4.5809)` | $50\%$ |
| **Nível 2** | **$7{,}2\text{ m}$** | `(0.000, 4.6507, 5.4971)` | $60\%$ |
| **Nível 3** | **$8{,}4\text{ m}$** | `(0.000, 5.4258, 6.4133)` | $70\%$ |
| **Nível 4** | **$9{,}6\text{ m}$** | `(0.000, 6.2009, 7.3295)` | $80\%$ |
| **Nível 5** | **$10{,}8\text{ m}$** | `(0.000, 6.9760, 8.2457)` | $90\%$ |
| **Nível 6 (MAX)** | **$12{,}0\text{ m}$** | `(0.000, 7.7511, 9.1619)` | $100\%$ |

---

## 3. Implementações Realizadas

1. **`scripts/camera/isometric_camera.gd`:**
   - Configurado `base_canonical_offset = Vector3(0.0, 7.7511, 9.1619)` correspondente aos $12{,}0\text{m}$ no Nível 6 MAX.
   - Definidos `MIN_DISTANCE_RATIO = 0.50` ($6{,}0\text{m}$) e `MAX_DISTANCE_RATIO = 1.00` ($12{,}0\text{m}$).
   - `_current_gameplay_offset = Vector3(0.0, 3.8756, 4.5809)`.
   - Transição interpolada por nível via `Tween` cúbico desacelerado (`TRANS_CUBIC`, `EASE_OUT`) de $0{,}75\text{s}$.
2. **`scenes/main.tscn`:**
   - Atualizado o transform inicial padrão do nó `IsometricCamera` para `(0, 3.8756, 4.5809)`.
3. **Documentação Canônica Sincronizada:**
   - Atualizados [`GAME_FEEL_E_HAPTICS.md`](../04_sistemas_e_gameplay/GAME_FEEL_E_HAPTICS.md) e [`DIRECAO_DE_ARTE_E_VISUAL.md`](../01_visao_geral_e_gdd/DIRECAO_DE_ARTE_E_VISUAL.md).
   - Indexado no [`INDICE_MELHORIAS.md`](./INDICE_MELHORIAS.md).

---

## 4. Verificação Visual e Validação

- **Nível 1 ($6{,}0\text{m}$):** Captura `snap_zoom_6m.png` demonstra enquadramento centralizado, foco claro na serra inicial e visão confortável do gramado ao redor.
- **Nível 6 MAX ($12{,}0\text{m}$):** Captura `snap_zoom_12m.png` demonstra visão panorâmica com espaço amplo para operação da serra estelar de $1{,}40\text{m}$ de raio e visualização integral das margens da ilha.
- **Headless Check:** Execução limpa com 0 erros e 0 warnings no Godot 4.
