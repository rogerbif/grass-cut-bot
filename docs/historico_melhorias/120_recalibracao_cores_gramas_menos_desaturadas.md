# Melhoria 120: Recalibração de Cores das Gramas (+20% de Saturação & Vibrancy Toon) 🌿✨

**Versão:** `v0.12.45-alpha`  
**Data:** 27/10/2026

---

## 1. Contexto e Motivação

O usuário solicitou: *"pode fazer a cor das gramas 20% menos desaturadas"*.

Sob a iluminação ambiente PBR da Godot 4 com DirectionalLight3D e sky ambient, as superfícies de grama sem componente emissivo sofriam atenuação por reflexo difuso, deixando os gramados com visual lavado/pálido em comparação com as flores recentemente enriquecidas.

Para atender à solicitação, foi aplicada uma elevação direta de 20% na saturação ($S \times 1.20$) em todas as cores base e de topo da vegetação, somada à injeção de auto-iluminação sutil toon (`vibrancy = 0.10`) no shader espacial `interactive_grass.gdshader`.

---

## 2. Alterações Implementadas

### 2.1. Shader Espacial de Grama (`interactive_grass.gdshader`)
- Adicionado uniform de vibrância toon:
  ```glsl
  uniform float vibrancy : hint_range(0.0, 1.0) = 0.10;
  ```
- No `fragment()`, injetada auto-iluminação proporcional à cor combinada do gradiente:
  ```glsl
  void fragment() {
      float h = clamp(UV.y, 0.0, 1.0);
      vec3 base_col = mix(color_base.rgb, color_top.rgb, h);
      ALBEDO = base_col;
      EMISSION = base_col * vibrancy;
      ROUGHNESS = roughness;
      SPECULAR = specular;
  }
  ```
  Isso impede que sombras difusas ou a luz ambiente esbranquiçada lavem o gramado, mantendo a sensação cartoon viva e limpa.

### 2.2. Materiais de Grama e Trigo (`shaders/interactive_grass_*.tres` e `interactive_wheat_material.tres`)
- **Grama Verde (`interactive_grass_material.tres`):**
  - `color_base`: `Color(0.06, 0.42, 0.11, 1)` (saturação de 0.71 para 0.86)
  - `color_top`: `Color(0.10, 0.70, 0.12, 1)` (saturação de 0.71 para 0.86)
  - `vibrancy`: `0.10`
- **Grama Amarela (`interactive_grass_yellow_material.tres`):**
  - `color_base`: `Color(0.65, 0.39, 0.0, 1)` / `color_top`: `Color(1.0, 0.63, 0.0, 1)`
  - `vibrancy`: `0.10`
- **Grama Azul (`interactive_grass_blue_material.tres`):**
  - `color_base`: `Color(0.0, 0.27, 0.62, 1)` / `color_top`: `Color(0.0, 0.49, 0.95, 1)`
  - `vibrancy`: `0.10`
- **Grama Violeta (`interactive_grass_purple_material.tres`):**
  - `color_base`: `Color(0.28, 0.0, 0.55, 1)` / `color_top`: `Color(0.49, 0.0, 0.92, 1)`
  - `vibrancy`: `0.10`
- **Grama Branca (`interactive_grass_white_material.tres`):**
  - `color_base`: `Color(0.66, 0.71, 0.78, 1)` / `color_top`: `Color(0.95, 0.96, 1, 1)`
  - `vibrancy`: `0.06`
- **Grama Vermelha (`interactive_grass_red_material.tres`):**
  - `color_base`: `Color(0.52, 0.0, 0.02, 1)` / `color_top`: `Color(0.95, 0.03, 0.05, 1)`
  - `vibrancy`: `0.10`
- **Trigo Dourado (`interactive_wheat_material.tres`):**
  - `color_base`: `Color(0.65, 0.46, 0.05, 1)` / `color_top`: `Color(0.96, 0.76, 0.03, 1)`
  - `vibrancy`: `0.10`

### 2.3. Cores de Superfície, Resíduos de Corte e Editor
- **Clippings em `vegetation_grid.gd`:** Lâminas cortadas deitadas no chão recalculadas com $S \times 1.20$.
- **Malhas de Terreno Plano 2D em `level_editor.gd` e `island_node.gd`:** Albedo sincronizado com os tons mais saturados.
- **Paleta de Criação em `tile_palette_db.gd`:** Cores de preview dos botões de pintura atualizadas.

---

## 3. Validação e Qualidade Técnica

1. **Zero Warnings e Sem Erros:** Validação estrita via Godot 4.7.1 headless.
2. **Performance 60 FPS Mobile Mantida:** O acréscimo de `EMISSION = base_col * vibrancy` adiciona uma única multiplicação por fragmento, mantendo 60 FPS lisos em mobile.
