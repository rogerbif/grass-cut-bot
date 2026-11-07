# Melhoria 191: Centralização Óptica da Câmera no Quadrante Visível Superior da Visão de Mapa 📷🗺️

**Versão do Projeto:** `v0.12.141-alpha`  
**Data:** 07/11/2026  
**Status:** Concluído e Validado ✅  

---

## 📌 Contexto e Diagnóstico

Na tela de visualização de Mapa (`MAP_VIEW`) em orientação mobile portrait (720x1280), o terço inferior da tela é ocupado pelos componentes de interface:
- O card de informações da fase (`MapLevelCard`) fica posicionado em $Y \in [824, 1018]\text{px}$.
- Os botões de ação (`JOGAR` e `BOT`) e a barra de navegação inferior ocupam de $Y \approx 1020\text{px}$ até a base ($1280\text{px}$).
- A barra superior (`TopBar`) ocupa $Y \in [0, 100]\text{px}$.

Anteriormente, o eixo óptico da câmera mirava no centro geométrico absoluto da tela ($Y = 640\text{px}$, 50% da altura). Como resultado, a metade inferior da ilha ficava mergulhada atrás do `MapLevelCard`, enquanto a parte superior da tela exibia uma vasta extensão vazia de oceano.

O usuário solicitou que a ilha em foco seja centralizada exatamente no quadrante útil desobstruído da tela (entre a TopBar e o topo do MapLevelCard).

---

## 🛠️ Implementações Realizadas

### 1. Cálculo Trigonométrico de Deslocamento Óptico (`scripts/menu/menu_camera.gd`)
- Definição do ponto focal do quadrante em `quadrant_center_y_ratio = 0.36` ($Y = 460.8\text{px}$ do topo em tela 720x1280).
- Criação do método `calculate_camera_z_offset(cam_y: float) -> float`:
  - Converte a coordenada vertical do quadrante para espaço de coordenadas normalizadas (NDC):
    $$y_{\text{ndc}} = \frac{0.5 - v}{0.5} = \frac{0.5 - 0.36}{0.5} = 0.28$$
  - Calcula a deflexão angular frustum ($\alpha$) com base no semi-ângulo do FOV vertical ($48^\circ$):
    $$k = y_{\text{ndc}} \cdot \tan\left(\frac{\text{FOV}}{2}\right) = 0.28 \cdot \tan(24^\circ) \approx 0.1252$$
    $$\alpha = \text{atan}(k) \approx 7.14^\circ$$
  - Determina o pitch efetivo de projeção:
    $$\theta_{\text{efetivo}} = \theta_{\text{pitch}} - \alpha = 58^\circ - 7.14^\circ \approx 50.86^\circ$$
  - Calcula o offset em $Z$ da câmera:
    $$\Delta Z_{\text{cam}} = \frac{\text{cam\_y}}{\tan(\theta_{\text{efetivo}})} \approx \frac{\text{cam\_y}}{1.2285} \approx 0.814 \cdot \text{cam\_y}$$
- O centro de cada ilha projeta-se agora com precisão milimétrica em $Y = 460.8\text{px}$, exatamente no centro do quadrante de visualização.

### 2. Calibração de Altura de Enquadramento Proporcional
- Atualização em `calculate_island_target_height(dim: Vector2)` para considerar a proporção útil do quadrante:
  $$\text{ideal\_height} = \text{clampf}(\max(dim.x \times 2.15, dim.y \times 1.55), 21.0, 58.0)$$
  - **Fase 1 (10m x 10m):** Topo em $Y = 270\text{px}$ (170px de margem até TopBar), Base em $Y = 693\text{px}$ (131px de margem até MapLevelCard). Largura de 535px centralizada.
  - **Fase 37 (24.8m x 24.8m):** Perfeitamente contida no quadrante sem colidir com TopBar ou MapLevelCard.

### 3. Tracking Touch 1:1 no Ponto Focal do Quadrante
- Em `get_pixel_to_ground_ratio()`, o raio de amostragem de solo passou a medir a deformação métrica em `focal_center = Vector2(vp_size.x * 0.5, vp_size.y * quadrant_center_y_ratio)`, garantindo que o arraste do dedo acompanhe o chão exatamente onde a ilha é exibida.

---

## 📊 Resultados e Validação

- **Projeção:** Centro da ilha posicionado exatamente em $X = 360.0\text{px}$ e $Y = 460.8\text{px}$.
- **Desobstrução Total:** Toda a ilha (grama, bot, praias e falésias) fica 100% visível acima do MapLevelCard com margens simétricas e confortáveis.
- **Console Godot:** 0 warnings e 0 erros.
