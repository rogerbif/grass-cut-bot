# Melhoria 134: Recalibração da Faixa de Zoom da Câmera (Inicial no Nível 2 e Final no Nível 5) 🎥🤖

## 1. Resumo Executivo
- **Solicitação do Usuário:** "O zoom inicial quero que seja a distância que está no nível 2 e o final a que está no nível 5".
- **Objetivo:** Reposicionar os limites do zoom dinâmico adaptativo da câmera para que o jogador inicie a partida (Nível 1) na distância anterior do Nível 2 ($7.20\text{m}$) e alcance no Nível 6 (MAX) a distância anterior do Nível 5 ($10.80\text{m}$).
- **Benefício de Game Feel:** Elimina a aproximação inicial curta de $6.0\text{m}$, proporcionando maior conforto e visibilidade periférica de início, e evita que a câmera se afaste em excesso ($12.0\text{m}$) no final, mantendo o enquadramento equilibrado e intimista sem perder de vista a ilha.
- **Resultado:** Progressão linear contínua entre $7.20\text{m}$ (Lv 1) e $10.80\text{m}$ (Lv 6 MAX), com incremento de $+0.72\text{m}$ por nível com transição suave via Tween cúbico ($0.75\text{s}$).

---

## 2. Parâmetros e Calibração Matemática

### Mapeamento Anterior vs. Novo Mapeamento

| Nível da Lâmina | Razão Anterior (Melhoria 132) | Distância Anterior | Nova Razão (Melhoria 134) | Nova Distância | Novo Offset Vetorial `Vector3(x, y, z)` |
| :---: | :---: | :---: | :---: | :---: | :---: |
| **Nível 1 (Inicial)** | $0.50$ (50%) | $6.00\text{m}$ | **$0.60$ (60%)** | **$7.20\text{m}$** (antigo Lv 2) | `(0.0, 4.6507, 5.4971)` |
| **Nível 2** | $0.60$ (60%) | $7.20\text{m}$ | **$0.66$ (66%)** | **$7.92\text{m}$** | `(0.0, 5.1157, 6.0469)` |
| **Nível 3** | $0.70$ (70%) | $8.40\text{m}$ | **$0.72$ (72%)** | **$8.64\text{m}$** | `(0.0, 5.5808, 6.5966)` |
| **Nível 4** | $0.80$ (80%) | $9.60\text{m}$ | **$0.78$ (78%)** | **$9.36\text{m}$** | `(0.0, 6.0459, 7.1463)` |
| **Nível 5** | $0.90$ (90%) | $10.80\text{m}$ | **$0.84$ (84%)** | **$10.08\text{m}$** | `(0.0, 6.5109, 7.6960)` |
| **Nível 6 (MAX)** | $1.00$ (100%) | $12.00\text{m}$ | **$0.90$ (90%)** | **$10.80\text{m}$** (antigo Lv 5) | `(0.0, 6.9760, 8.2457)` |

A fórmula de interpolação em `get_target_offset_for_level(lvl)`:
$$t = \text{clamp}\left(\frac{\text{lvl} - 1}{5.0}, 0.0, 1.0\right)$$
$$\text{ratio} = \text{lerp}(0.60, 0.90, t)$$
$$\text{offset} = \text{base\_canonical\_offset} \times \text{ratio}$$

---

## 3. Modificações em Arquivos

1. **`scripts/camera/isometric_camera.gd`:**
   - Atualizados `MIN_DISTANCE_RATIO = 0.60` (correspondente ao antigo Nível 2) e `MAX_DISTANCE_RATIO = 0.90` (correspondente ao antigo Nível 5).
   - Atualizado o valor de repouso inicial `_current_gameplay_offset = Vector3(0.0, 4.6507, 5.4971)`.
2. **`scenes/main.tscn`:**
   - Atualizado o transform inicial da `IsometricCamera` para `Vector3(0.0, 4.6507, 5.4971)`.
3. **`tests/test_camera_zoom_levels.gd` & `.tscn`:**
   - Criado teste automatizado de integração e verificação analítica das distâncias nos 6 níveis.
4. **Documentação Canônica:**
   - Atualizados `docs/01_visao_geral_e_gdd/DIRECAO_DE_ARTE_E_VISUAL.md` e `docs/04_sistemas_e_gameplay/GAME_FEEL_E_HAPTICS.md`.

---

## 4. Testes e Validação
- **Teste Automatizado de Zoom:** `tests/test_camera_zoom_levels.tscn` aprovado com 100% de sucesso:
  - Nível 1: $7.20\text{m}$ (razão $0.60$, exatamente Lv 2 anterior).
  - Nível 6: $10.80\text{m}$ (razão $0.90$, exatamente Lv 5 anterior).
  - Progressão suave validada em todos os níveis intermediários.
- **Teste de Lâmina e Gameplay:** `tests/test_blade_progression.tscn` aprovado com 0 erros/warnings.
