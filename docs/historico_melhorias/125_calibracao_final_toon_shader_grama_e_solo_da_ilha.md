# Histórico de Melhorias: 125. Calibração Final do Toon Shader da Grama e Solo da Ilha Procedural 🌿🏝️

**Data:** 27 de Outubro de 2026  
**Versão:** `v0.12.49-alpha`  
**Autor:** Antigravity (Google DeepMind) & RogerBif  
**Status:** Concluído e Validado ✅  

---

## 🎯 1. Contexto e Motivação

Após a introdução do estúdio de shaders F6 (`scenes/tools/toon_shader_tester.tscn`), o usuário calibrou os parâmetros finais da vegetação e observou uma discrepância entre o piso do estúdio e o solo da ilha procedural do jogo, que aparecia excessivamente escuro devido à amostragem de textura atlas legada (`tile_island_center_Image_0.png`) combinada com sombreamento difuso Burley.

Para alcançar consistência visual 100% fiel entre o estúdio de laboratório e a gameplay, foram implementados controles interativos do solo no estúdio F6 e aplicados os valores canônicos finais calibrados pelo usuário tanto na vegetação quanto no gerador procedural de ilhas.

---

## 🛠️ 2. Parâmetros Canônicos Calibrados

### 🌿 Toon Shader da Vegetação (`interactive_grass.gdshader` & `interactive_grass_material.tres`)
```gdscript
color_light = Color(0.42, 0.88, 0.46)
color_base = Color(0.12, 0.35, 0.18)
color_shadow = Color(0.18, 0.48, 0.25)
rim_color = Color(0.85, 1.00, 0.65)
toon_ramp_offset = 0.97
toon_ramp_smoothness = 1.00
vertical_gradient_mix = 0.81
rim_power = 1.00
rim_brightness = 1.00
roughness = 0.90
```

### 🏝️ Solo da Ilha Procedural (`island_mesh_builder.gd` & `terrain.tscn`)
```gdscript
ground_color = Color(0.14, 0.59, 0.22)
ground_brightness = 0.80
ground_diffuse_toon = true
# Cor final de albedo: Color(0.112, 0.472, 0.176)
```

---

## 🏗️ 3. Alterações Técnicas Realizadas

1. **`shaders/interactive_grass_material.tres` e `shaders/interactive_grass.gdshader`:**
   - Atualizados `toon_ramp_offset = 0.97`, `toon_ramp_smoothness = 1.0`, `vertical_gradient_mix = 0.81`, `roughness = 0.90`.
   - `use_rim = false` preservado para a grama fina de face única (evita sobre-exposição esbranquiçada nas lâminas).

2. **`scripts/level/island_mesh_builder.gd`:**
   - Incorporação de cores assadas por vértice na geração da malha única procedural (`SurfaceTool`):
     - Tampa superior de grama e chanfro: `st.set_color(ground_color * ground_brightness)`.
     - Falésias verticais: `st.set_color(CLIFF_COLOR)` (`Color(0.4667, 0.2431, 0.1451)`).
   - `get_island_material()` configurado com `vertex_color_use_as_albedo = true`, `diffuse_mode = BaseMaterial3D.DIFFUSE_TOON` e `roughness = 0.90`.
   - Remoção de dependência de textura de imagem no solo (`albedo_texture = null`), economizando amostragem de textura e banda de memória GPU nos celulares.

3. **`scenes/tools/toon_shader_tester.tscn` e `scripts/tools/toon_shader_tester.gd`:**
   - Adicionada seção interativa de Solo no Painel Direito com ColorPicker, Slider de Brilho, toggles de Toon Diffuse e aplicação no pedestal.
   - Presets atualizados com os novos valores calibrados de grama e solo.
   - Cópia unificada para a área de transferência incluindo parâmetros de solo.

4. **`scenes/level/terrain.tscn`:**
   - Material de fallback do chão alinhado com `diffuse_mode = 3` (Toon), `roughness = 0.90` e `albedo_color = Color(0.112, 0.472, 0.176)`.

---

## 🧪 4. Validação e Qualidade

- **Godot 4 Headless:** Execução com 0 erros e 0 warnings em `main.tscn`, `main_menu.tscn`, `toon_shader_tester.tscn` e `level_editor.tscn`.
- **SemVer:** Versão incrementada para `v0.12.49-alpha` em `project.godot` e `export_presets.cfg`.
