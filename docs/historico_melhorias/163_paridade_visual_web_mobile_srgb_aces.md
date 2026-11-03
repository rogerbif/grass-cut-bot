# 163. Paridade Visual 1:1 Web ⇄ Mobile (Isolamento `OUTPUT_IS_SRGB` & `gl_compatibility`) e Ícones SVG em `NÍVEL MAX` (`v0.12.109-alpha`) 🌊🌿📱

## 1. Contexto e Diagnóstico
Na comparação entre a versão **Mobile (`renderer/rendering_method="mobile"`)** — que já apresentava as cores e o shader de água canônicos corretos — e a versão **Web (`renderer/rendering_method.web="gl_compatibility"`)**, identificaram-se as seguintes discrepâncias exclusivas do pipeline WebGL2 (`OUTPUT_IS_SRGB == true`):
1. **Shader da Água (`shaders/toon_water.gdshader`):** No Vulkan Mobile, as texturas `: source_color` (`PerlinNoise.png` e `WaterDistortion.png`) são decodificadas por hardware de sRGB para Linear ($x^{2.2}$), fazendo o `surface_noise_cutoff = 0.52` gerar apenas pequenos flocos discretos de espuma (~1,76% da área). No WebGL2 (`OUTPUT_IS_SRGB`), a amostragem ocorria em sRGB puro, fazendo ~36,3% do oceano virar manchas brancas e estourando o azul-turquesa (`#46E6FF`) para ciano claro (`#54FFFF`).
2. **Solo e Falésia (`scripts/level/island_mesh_builder.gd`):** A ausência do ACES Tonemap no modo `gl_compatibility` elevava o solo de `#30C34A` para `#3CF567` e saturava o canal vermelho da falésia, deslocando-a de terracota (`#F2AA64`) para amarelo-areia (`#FFDF8E`).
3. **Vegetação, Decalque e Serra (`interactive_grass.gdshader`, `interactive_flower.gdshader`, `lawn_base_decal.gdshader`, `cutter.gd`, `menu_bot.gd`):** O mix em sRGB sem ACES Tonemap lavava as sombras da grama e do trigo e clareava o aço da lâmina.
4. **Quadrados Tofu na Barra `NÍVEL MAX` (`BladeProgressBar`):** Os emojis Unicode `"👑 NÍVEL MAX ⭐"` apareciam como caixas de erro (`[01F451]` e `[2B50]`) no navegador Web.

---

## 2. Solução Implementada (0% de Impacto no Mobile)
- **`shaders/toon_water.gdshader`:** Adicionado bloco `if (OUTPUT_IS_SRGB)` que decodifica `distortNoise` e `surfaceNoise` para espaço Linear e calibra `waterColor.rgb`, reproduzindo exatamente `#46E6FF` e os mesmos flocos discretos de espuma do Mobile, mantendo o código `!OUTPUT_IS_SRGB` 100% intocado.
- **`scripts/level/island_mesh_builder.gd` e `scripts/menu/island_node.gd`:** Adicionada verificação `_is_compatibility_renderer()` em `get_final_ground_color()` e `get_final_cliff_color()`, cravando `#30C34A` no solo e `#F2AA64` na falésia no WebGL2 sem alterar o Mobile.
- **`shaders/interactive_grass.gdshader`, `shaders/interactive_flower.gdshader` e `shaders/lawn_base_decal.gdshader`:** Isolada em `if (OUTPUT_IS_SRGB)` a interpolação Linear + compensação ACES para grama, trigo, flores e decalque de base.
- **`scripts/cutter/cutter.gd` e `scripts/menu/menu_bot.gd`:** Calibração de `albedo_color` da serra (`_apply_compat_blade_tint`) restrita ao `gl_compatibility`.
- **`scenes/cutter/blade_progress_bar.tscn`, `scripts/cutter/blade_progress_bar.gd` e `assets/icons/icon_crown.svg`:** Substituídos os emojis Unicode por dois nós `TextureRect` vetoriais (`CrownIcon` com `icon_crown.svg` e `StarIcon` com `icon_star.svg`) ladeando `"NÍVEL MAX"`.
- **`project.godot`:** Restaurada a chave explícita `renderer/rendering_method.web="gl_compatibility"` e incrementada a versão para `v0.12.109-alpha`.

---

## 3. Verificação e Auditoria
- **Paridade Pixel a Pixel (`mobile` vs `gl_compatibility`):** Validada via captura determinística (`--write-movie`) confirmando 0 pixels alterados no renderizador `mobile` e paridade cromática 1:1 no `gl_compatibility` (Oceano `#46E6FF`, Solo `#30C34A`, Falésia `#F2AA64`, Grama `#4FE11C`/`#36BB11`, Trigo `#EED22E`/`#D9B324` e ícones SVG em `NÍVEL MAX`).
- **Zero Warnings:** Executado em modo headless sem erros ou avisos.
