# Melhoria 162: Redução de 40% na Velocidade do Bot e Ajuste de 40% na Distância Inicial da Câmera 🤖🎥

## 1. Resumo Executivo
- **Solicitação do Usuário:** "Reduza a velocidade do bot em 40% (inicial e final) e a distância inicial da câmera deixe 40% mais longe".
- **Objetivo:** 
  1. Tornar a condução do bot mais cadenciada, precisa e controlada com joystick touch no mobile, reduzindo em 40% tanto a velocidade base inicial (Nível 1) quanto a velocidade máxima final (Nível 6 MAX).
  2. Aumentar o campo de visão panorâmico e periférico inicial afastando a câmera em 40% na distância inicial do Nível 1.
- **Resultado:**
  - **Velocidade do Bot:** Reduzida de $3.25\text{ m/s} \dots 4.75\text{ m/s}$ para **$1.95\text{ m/s} \dots 2.85\text{ m/s}$** (incremento de $+0.18\text{ m/s}$ por nível).
  - **Câmera Isométrica (Zoom Dinâmico):** Distância inicial do Nível 1 ajustada de $6.0\text{ m}$ (`ratio = 0.50`, offset `Vector3(0.0, 3.8756, 4.5809)`) para **$8.4\text{ m}$** (`ratio = 0.70`, offset `Vector3(0.0, 5.4258, 6.4133)`), mantendo o enquadramento final de $12.0\text{ m}$ (`ratio = 1.00`, offset `Vector3(0.0, 7.7511, 9.1619)`) no Nível 6 MAX com transição suave via Tween cúbico.

---

## 2. Detalhes de Calibração Matemática

### A. Velocidade Linear por Nível (Redução de 40%)
| Nível | Velocidade Anterior | Nova Velocidade (-40%) | Incremento por Nível |
| :---: | :---: | :---: | :---: |
| **1 (Inicial)** | $3.25\text{ m/s}$ | **$1.95\text{ m/s}$** | Base |
| **2** | $3.55\text{ m/s}$ | **$2.13\text{ m/s}$** | $+0.18\text{ m/s}$ |
| **3** | $3.85\text{ m/s}$ | **$2.31\text{ m/s}$** | $+0.18\text{ m/s}$ |
| **4** | $4.15\text{ m/s}$ | **$2.49\text{ m/s}$** | $+0.18\text{ m/s}$ |
| **5** | $4.45\text{ m/s}$ | **$2.67\text{ m/s}$** | $+0.18\text{ m/s}$ |
| **6 (MAX)** | $4.75\text{ m/s}$ | **$2.85\text{ m/s}$** | $+0.18\text{ m/s}$ |

### B. Câmera Isométrica (Aumento de 40% na Distância Inicial)
- **Distância Base Canônica (100% no Lv 6 MAX):** $12.0\text{ m}$ (`offset = Vector3(0.0, 7.7511, 9.1619)`).
- **Razão Mínima Inicial (Lv 1):** Atualizada de `0.50` ($6.0\text{ m}$) para `0.70` ($8.4\text{ m}$, correspondendo a um aumento de 40% na distância inicial em relação aos $6.0\text{ m}$).
- **Offset Inicial do Nível 1:** `Vector3(0.0, 5.4258, 6.4133)`.
- **Progressão por Nível:**
  - Lv 1: $8.40\text{ m}$ (`Vector3(0.0, 5.4258, 6.4133)`)
  - Lv 2: $9.12\text{ m}$ (`Vector3(0.0, 5.8908, 6.9630)`)
  - Lv 3: $9.84\text{ m}$ (`Vector3(0.0, 6.3559, 7.5127)`)
  - Lv 4: $10.56\text{ m}$ (`Vector3(0.0, 6.8210, 8.0624)`)
  - Lv 5: $11.28\text{ m}$ (`Vector3(0.0, 7.2860, 8.6121)`)
  - Lv 6 (MAX): $12.00\text{ m}$ (`Vector3(0.0, 7.7511, 9.1619)`)

---

## 3. Arquivos Modificados
- `scripts/cutter/cutter.gd`: Atualizado `base_speed = 1.95`.
- `scripts/core/upgrade_manager.gd`: Atualizada a fórmula em `get_cutter_speed()` para `1.95 + (blade_level - 1) * 0.18`.
- `scripts/camera/isometric_camera.gd`: Atualizado `MIN_DISTANCE_RATIO = 0.70` e `_current_gameplay_offset = Vector3(0.0, 5.4258, 6.4133)`.
- `scenes/main.tscn`: Atualizado transform da câmera isométrica para `Vector3(0.0, 5.4258, 6.4133)`.
- `tests/test_blade_progression.gd`: Atualizados asserts de velocidade para a nova progressão calibrada ($1.95 \dots 2.85\text{ m/s}$).
- `docs/04_sistemas_e_gameplay/ECONOMIA_E_OFICINA.md`, `docs/04_sistemas_e_gameplay/GAME_FEEL_E_HAPTICS.md`, `docs/01_visao_geral_e_gdd/DIRECAO_DE_ARTE_E_VISUAL.md`: Documentações técnicas atualizadas.

---

## 4. Testes e Validação
- **`tests/test_blade_progression.tscn`:** Aprovado com sucesso validando todos os novos níveis de velocidade.
- **`tests/test_blade_pop_and_slash.tscn`:** Aprovado com sucesso.
- **`tests/test_wheat_level_02.tscn`:** Aprovado com sucesso.
- **`tests/test_editor_goals_and_panel.tscn`:** Aprovado com sucesso.
