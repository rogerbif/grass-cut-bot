# Melhoria 218: Calibração de Aparas de Grama Picada (Meia Folha, Altura -20% e Queda Deitada Estilo Pétalas) 🌿✂️

## 1. Visão Geral e Contexto
Após a implementação das partículas procedurais de corte de grama, observou-se que as aparas geradas estavam desproporcionalmente grandes (chegando a ultrapassar $1.0\text{m}$ de altura), atingindo altitudes excessivas no campo de visão e voando/caindo em pé verticalmente como estacas/lanças.

Esta melhoria calibra e refina a física e geometria das partículas de corte:
- **Tamanho de Meia Folha Picada:** Redução para $\approx 0.12\text{m}$ (comprimento) e $\approx 0.03\text{m}$ (largura), reproduzindo aparas fatiadas finas de cortador de grama.
- **Altura de Voo 20% Mais Baixa:** Redução do impulso vertical inicial de $2.8 \dots 5.2\text{ m/s}$ para $2.2 \dots 4.1\text{ m/s}$ com aceleração gravitacional ajustada a $-9.8\text{ m/s²}$.
- **Queda Deitada (Estilo Pétalas):** Geometria procedimental modelada no plano horizontal $XZ$ com curvatura/vinco central e normais para cima ($+Y$), combinada com rotações angulares no ar para que as aparas girem e caiam deitadas como pétalas.

---

## 2. Implementação Técnica

### 2.1 Remodelagem Procedural das Malhas de Aparas (`scripts/plants/plant.gd`)
- **`_grass_blade_mesh` (Apara de Meio de Folha):**
  - Malha low-poly chanfrada de 4 vértices e 4 triângulos deitada no plano horizontal $XZ$.
  - Vinco longitudinal em $Y = 0.005\text{m}$, comprimento $Z \in [-0.06\text{m}, +0.06\text{m}]$ ($0.12\text{m}$) e largura $X \in [-0.015\text{m}, +0.015\text{m}]$ ($0.03\text{m}$).
  - Face ampla de perfil horizontal, visível deitada a partir da câmera isométrica.
- **`_grass_blade_tip_mesh` (Apara de Ponta de Folha):**
  - Malha chanfrada de 3 vértices afilada deitada no plano horizontal $XZ$.
  - Comprimento $Z \in [-0.045\text{m}, +0.045\text{m}]$ ($0.09\text{m}$) e largura de base $0.024\text{m}$.

### 2.2 Calibração do Pool de Partículas (`_init_particle_pool`)
- `initial_velocity_min = 2.2` e `initial_velocity_max = 4.1` (redução de ~21% na velocidade vertical).
- `gravity = Vector3(0.0, -9.8, 0.0)` para trajetória parabólica dinâmica e ágil.
- `scale_amount_min = 0.85` e `scale_amount_max = 1.15` (eliminando a escala inflada anterior de até 1.85x).
- `angular_velocity_min = -280.0` e `angular_velocity_max = 280.0` com variação angular em `angle_min = -180.0` e `angle_max = 180.0`.
- `lifetime = 0.72s` e curva de escala suave mantendo o tamanho das aparas estável durante o voo e desvanecendo apenas no assentamento no solo.

---

## 3. Verificação e Validação
- Teste visual standalone executado com sucesso e captura salva em `test_grass_particles_visual.png`, comprovando que as aparas voam com tamanho proporcional de grama picada, mantêm arco contido e caem deitadas suavemente.
- Console Godot validado com **0 erros e 0 warnings** (Mandamento 1).
