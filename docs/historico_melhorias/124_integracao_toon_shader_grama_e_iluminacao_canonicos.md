# Melhoria 124: Integração do Toon Shader Gradiente na Grama, Calibração Solar e Câmera Canônica 🎨🌿☀️

Este documento consolida a implementação e calibração oficial do **Toon / Cel Shader Gradiente com Rim Lighting** na vegetação do **Grass Cut Bot**, acompanhado da recalibração da iluminação solar e enquadramento da câmera isométrica no gameplay principal e menus.

---

## 🎯 1. Objetivos da Implementação

1. **Substituição da Iluminação PBR da Grama por Cel Shading Gradiente:**
   - Incorporar o algoritmo Toon Shader com controle de meio-tom (*Toon Ramp* suave estilo MinionsArt) e silhueta luminosa (*Rim Lighting*).
   - Preservar integralmente as animações procedurais de vento foliar e a curvatura reativa da serra (`global_cutter_pos`).
2. **Harmonização da Luz Solar e Luz Ambiente:**
   - Calibração do ângulo zenital do sol (`pitch = -37.0°`, `yaw = 40.0°`) com vetor `(-0.513, -0.602, -0.612)` e intensidade `1.30`.
   - Ajuste da luz ambiente para `0.20`, garantindo alto contraste cel-shaded sem lavar as sombras.
3. **Ajuste Isométrico de Câmera:**
   - Enquadramento na distância `7.40m` com `pitch = -40.3°` (`offset = Vector3(0.0, 4.78, 5.65)`), proporcionando leitura nítida da serra e do gramado no mobile.

---

## 🛠️ 2. Parâmetros Canônicos Calibrados

### Iluminação e Câmera
```gdscript
# DirectionalLight3D (Sol Canônico)
sun_rotation_deg = Vector3(-37.0, 40.0, 0.0)
sun_direction = Vector3(-0.513, -0.602, -0.612)
sun_energy = 1.30
ambient_energy = 0.20

# IsometricCamera (Câmera Canônica)
camera_rotation_deg = Vector3(-40.3, 0.0, 0.0)
camera_distance = 7.40
camera_offset = Vector3(0.0, 4.78, 5.65)
```

### Toon Shader Gradiente da Grama (`interactive_grass.gdshader`)
```gdscript
color_light = Color(0.42, 0.88, 0.46)
color_base = Color(0.12, 0.35, 0.18)
color_shadow = Color(0.18, 0.48, 0.25)
rim_color = Color(0.85, 1.00, 0.65)
toon_ramp_offset = 0.62
toon_ramp_smoothness = 0.72
vertical_gradient_mix = 0.72
rim_power = 1.00
rim_brightness = 1.00
roughness = 0.90
```

---

## 📂 3. Arquivos Modificados e Criados

1. **`shaders/interactive_grass.gdshader`:**
   - Adicionada função `light()` com Toon Ramp suave e cálculo de Rim Lighting nas pontas das lâminas.
   - O `fragment()` agora gera o gradiente vertical contínuo da raiz até o topo iluminado.
2. **`shaders/interactive_grass_material.tres`:**
   - Atualizado com os parâmetros canônicos de cores e gradientes cel.
3. **`scenes/main.tscn`:**
   - Sincronização da `DirectionalLight3D` (pitch $-37^\circ$, yaw $40^\circ$, energia 1.3), `WorldEnvironment` (ambiente 0.2) e `IsometricCamera` (offset $4.78\text{m} Y$, $5.65\text{m} Z$).
4. **`scripts/camera/isometric_camera.gd`:**
   - Atualização do `offset` padrão para `Vector3(0.0, 4.78, 5.65)`.
5. **`scenes/menu/main_menu.tscn`:**
   - Sincronização da iluminação solar e ambiente para paridade estética entre menu e gameplay.
6. **`docs/01_visao_geral_e_gdd/DIRECAO_DE_ARTE_E_VISUAL.md`:**
   - Documentação técnica atualizada com a nova especificação canônica.

---

## 🔍 4. Validação e Critérios de Aceite

- **Zero Warnings** no console do Godot.
- **Interação Física:** A grama continua curvando reativamente ao redor da lâmina do cortador via `global_cutter_pos`.
- **Desempenho Mobile:** O novo shader executa em $O(1)$ sem loops nem pós-processamento de tela cheia, preservando os 60 FPS cravados em Vulkan Mobile.
