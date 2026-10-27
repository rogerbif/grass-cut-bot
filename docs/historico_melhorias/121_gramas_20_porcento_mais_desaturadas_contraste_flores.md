# Melhoria 121: Gramas 20% Mais Pálidas / Desaturadas para Máximo Contraste com as Flores 🌿🌸

**Versão:** `v0.12.46-alpha`  
**Data:** 27/10/2026

---

## 1. Contexto e Motivação

O usuário refinou a direção artística do ecossistema vegetal:  
*"desculpe falei errado quero que seja mais palidas , mais 20% desaturadas do que o valor anteior, para dar mais destaque as flores e contraste"*.

Com as flores nobres recém-enriquecidas com cores vivas e auto-iluminação toon (`vibrancy = 0.18`), o tapete de grama atua como o pano de fundo visual da ilha. Ao tornar os tons de grama 20% mais pálidos e desaturados ($S_{\text{new}} = S_{\text{orig}} \times 0.80$) e desativar emissão na grama (`vibrancy = 0.0`), cria-se uma estética pastel suave e agradável no solo, proporcionando contraste e fazendo com que as 8 espécies de flores nobres saltem aos olhos do jogador como os verdadeiros tesouros do jardim.

---

## 2. Alterações Implementadas

### 2.1. Shader Espacial de Grama (`interactive_grass.gdshader`)
- Parâmetro `vibrancy` configurado para `0.0`, mantendo o gramado como superfície fosca sem emissão para não competir com as pétalas das flores.

### 2.2. Materiais de Grama e Trigo (`shaders/interactive_grass_*.tres` e `interactive_wheat_material.tres`)
- **Grama Verde (`interactive_grass_material.tres`):**
  - `color_base`: `Color(0.18, 0.42, 0.21, 1)` (saturação 0.57)
  - `color_top`: `Color(0.30, 0.70, 0.32, 1)` (saturação 0.57)
  - `vibrancy`: `0.0`
- **Grama Amarela (`interactive_grass_yellow_material.tres`):**
  - `color_base`: `Color(0.65, 0.45, 0.15, 1)` / `color_top`: `Color(1.0, 0.72, 0.24, 1)`
  - `vibrancy`: `0.0`
- **Grama Azul (`interactive_grass_blue_material.tres`):**
  - `color_base`: `Color(0.14, 0.35, 0.62, 1)` / `color_top`: `Color(0.24, 0.61, 0.95, 1)`
  - `vibrancy`: `0.0`
- **Grama Violeta (`interactive_grass_purple_material.tres`):**
  - `color_base`: `Color(0.35, 0.15, 0.55, 1)` / `color_top`: `Color(0.62, 0.28, 0.92, 1)`
  - `vibrancy`: `0.0`
- **Grama Branca (`interactive_grass_white_material.tres`):**
  - `color_base`: `Color(0.70, 0.73, 0.78, 1)` / `color_top`: `Color(0.97, 0.98, 1.0, 1)`
  - `vibrancy`: `0.0`
- **Grama Vermelha (`interactive_grass_red_material.tres`):**
  - `color_base`: `Color(0.52, 0.15, 0.17, 1)` / `color_top`: `Color(0.95, 0.33, 0.35, 1)`
  - `vibrancy`: `0.0`
- **Trigo Dourado (`interactive_wheat_material.tres`):**
  - `color_base`: `Color(0.65, 0.53, 0.25, 1)` / `color_top`: `Color(0.96, 0.82, 0.34, 1)`
  - `vibrancy`: `0.0`

### 2.3. Sincronização de Clippings, Terreno Plano e Editor
- **Clippings de corte (`vegetation_grid.gd`):** Resíduos no piso harmonizados com os tons desaturados.
- **Pisos 2D (`level_editor.gd` & `island_node.gd`):** Cores de albedo dos materiais 2D atualizadas para as novas tonalidades pastel.
- **Paleta de Criação (`tile_palette_db.gd`):** Cores de botões do editor alinhadas ao novo esquema.

---

## 3. Validação e Qualidade Técnica

1. **Zero Warnings e Sem Erros:** Validação com Godot 4.7.1 headless em `perf_test.tscn` e `main.tscn`.
2. **Game Feel e Contraste Visual:** O contraste relativo entre gramado e flores nobres aumentou substancialmente, facilitando a identificação imediata das flores em movimento rápido da câmera isométrica.
