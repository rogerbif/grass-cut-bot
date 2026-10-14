# Melhoria 009: Lâmina 1.5x Maior e Correção da Orientação Frontal do Robô 🪚🤖🧭

Este documento consolida o diagnóstico e implementação das correções de orientação frontal da carcaça do robô e o escalonamento ampliado em 1.5x do conjunto de lâminas e container de corte em **Grass Cut Bot**.

---

## 📋 Resumo Executivo
- **Data da Conclusão:** Outubro de 2026
- **Versão SemVer:** `v0.3.2`
- **Domínio:** Gameplay, Entidades do Cortador e Modelagem 3D
- **Objetivos Entregues:**
  1. Correção da orientação angular de frente do robô: eliminação do erro de 180° que fazia o robô conduzir com a traseira apontada para a direção do movimento.
  2. Alinhamento de repouso: o robô inicia a partida olhando naturalmente para a frente (sentido -Z da ilha).
  3. Lâminas e deck 1.5x maiores no Blender: o `blade_container` e as 3 variantes de lâminas (`blade_tier_1`, `blade_tier_2`, `blade_tier_3`) foram expandidos em 1.5x nos eixos X e Y com escala aplicada (`Ctrl+A -> Scale`).
  4. Calibração da física de corte na Godot: raio base do `BladeArea` expandido para $0.98\text{m}$ (casando com o novo diâmetro visual das lâminas), com atualização em `UpgradeManager.get_blade_radius()` e nos shaders interativos de vegetação.

---

## 🔍 Diagnóstico do Cenário Anterior
1. **Frente Invertida ao Conduzir:** O cálculo `atan2(-move_dir.x, -move_dir.z)` em `cutter.gd` assumia que o modelo tinha a frente nativa em -Z. Como a malha exportada do Blender tinha a cabeça em +Z no padrão glTF, o robô rotacionava 180° ao contrário, dirigindo sempre de marcha-à-ré (olhando para trás).
2. **Proporção da Lâmina no Gramado:** Após o ajuste manual de escala das peças superiores do robô, o diâmetro da lâmina e da saia protetora precisavam de 1.5x de amplitude para garantir a imponência visual e o alcance radial característicos do concept art.

---

## 🎯 Solução Técnica Aplicada

### 1. Correção Angular de Condução (`cutter.gd`)
- **Fórmula de Direção Corrigida:**
  $$\theta_{\text{alvo}} = \text{atan2}(v_x, v_z)$$
  - Ao mover para cima/frente ($-Z$): $\theta = \pi$ (o robô vira a cabeça para frente).
  - Ao mover para a direita ($+X$): $\theta = \pi/2$ (cabeça aponta para a direita).
  - Ao mover para a esquerda ($-X$): $\theta = -\pi/2$ (cabeça aponta para a esquerda).
  - Ao mover para trás ($+Z$): $\theta = 0$ (cabeça aponta para a câmera).
- **Orientação Inicial:** No `_ready()`, `robot_body.rotation.y = PI` garante que o robô já comece a fase olhando para frente.
- **Rolagem da Roda:** Rotação do `wheel_mesh` com sinal ajustado para acompanhar o avanço físico linear.

### 2. Escala 1.5x das Lâminas e Deck (Blender e Godot)
- No Blender: `blade_container`, `blade_tier_1`, `blade_tier_2` e `blade_tier_3` escalonados em 1.5x nos eixos horizontais X e Y.
- Na Godot 4:
  - `CollisionShape3D` do `BladeArea`: raio atualizado para $0.98\text{m}$.
  - `UpgradeManager.get_blade_radius()`: raio base calibrado para $0.98\text{m} + (\text{nível} - 1) \times 0.18\text{m}$.
  - `cutter.gd`: `visual_scale = radius / 0.98` e raio de interação com o shader de grama ajustado.

---

## 🛡️ Conformidade de Guardrails Invariantes
- **Zero Warnings:** 0 avisos no console Godot 4.7.1.
- **Corte Radial Omnidirecional Preservado:** A correção da frente é puramente cosmética e não afeta a física omnidirecional em 360°.
- **Exportação glTF Limpa:** Arquivo GLB atualizado mantendo performance móvel de 60 FPS.
