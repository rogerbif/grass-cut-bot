# Melhoria 160: Ajuste da Paleta de Cores da Grama e do Solo Conforme Referência Visual 🌿🎨

## 🎯 Objetivo e Contexto
O usuário forneceu uma captura de referência (`media_1793374611808_fe13fe6e.jpg`) com a seguinte instrução:
*"Quero que ajuste a cor da grama do solo para a mesma cor desse exemplo e a grama também para o mesmo tom de grama no gradiente de mais escuro na base para mais claro"*

Na análise pixel-a-pixel da imagem de referência:
1. **Solo / Grama do Terreno (Área limpa e aparada ao redor do cortador):**
   - Apresenta um verde limão vívido, quente e luminoso (amostrado entre `#87CD4D` e `#9AD762`, média normalizada `RGB(0.53, 0.81, 0.30)`).
   - O solo anterior do jogo utilizava um tom escuro e frio de verde floresta (`Color(0.14, 0.45, 0.19)` com brilho 0.80, resultando em ~`#1C5C26`), que criava um contraste excessivamente sombrio e opaco.
2. **Grama Vertical 3D (Tufos com Gradiente Base -> Topo):**
   - **Base (mais escura):** Amostrada em `#2D800E` a `#379A12`, correspondendo a `RGB(0.12, 0.44, 0.05)` a `RGB(0.18, 0.56, 0.08)`. Verde profundo e foliar, sem preto saturado.
   - **Corpo e Topo (mais claro / vibrante):** Amostrado em `#48CD18` / `#49CF19`, correspondendo a `RGB(0.28, 0.81, 0.10)`. Verde folha fresco e ensolarado com leve toque de amarelo.
   - O material anterior usava `Color(0.10, 0.30, 0.15)` na base e `Color(0.42, 0.88, 0.46)` no topo (tendendo ao tom esmeralda/ciano pastel).

---

## 🛠️ Alterações Realizadas

### 1. Calibração da Cor do Solo da Ilha e Decalque de Gramado
- Em [`scripts/level/island_mesh_builder.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/level/island_mesh_builder.gd):
  - `ground_base_color` atualizado para `Color(0.53, 0.81, 0.30, 1.0)`.
  - `ground_brightness` calibrado para `0.95`.
  - O teto de grama da ilha 3D agora reproduz com fidelidade a cor verde-limão vibrante da referência.
- Em [`shaders/lawn_base_decal.gdshader`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/shaders/lawn_base_decal.gdshader):
  - `lawn_color` ajustado para `vec4(0.22, 0.65, 0.12, 0.55)` (área de sombra sob o tufo).
  - `mowed_color` ajustado para `vec4(0.53, 0.81, 0.30, 0.40)` (trilha de gramado recém-cortado alinhada ao novo piso).

### 2. Calibração do Gradiente da Grama Verde 3D
- Em [`shaders/interactive_grass_material.tres`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/shaders/interactive_grass_material.tres):
  - `color_light` (ponta iluminada): ajustado para `Color(0.28, 0.81, 0.10, 1.0)`.
  - `color_base` (raiz ancorada mais escura): ajustado para `Color(0.12, 0.44, 0.05, 1.0)`.
  - `color_shadow` (lado sombreado): ajustado para `Color(0.18, 0.56, 0.08, 1.0)`.
  - Arquivo gravado em UTF-8 puro sem BOM para evitar advertências no parser de recursos textuais do Godot.

### 3. Sincronização nos Bancos de Dados e Paletas da UI
- Em [`scripts/plants/plant_database.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/plants/plant_database.gd):
  - Cor canônica de `grass_green` atualizada para `Color(0.28, 0.81, 0.10, 1.0)`.
- Em [`scripts/editor/tile_palette_db.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/editor/tile_palette_db.gd):
  - Cor do botão de `grass_green` na paleta do editor atualizada para `Color(0.28, 0.81, 0.10)`.
- Em [`scripts/editor/level_editor_ui.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/editor/level_editor_ui.gd):
  - `GOALS_CATALOG` atualizado com a cor harmonizada `Color(0.28, 0.81, 0.10)` para os cartões de meta de grama verde.

---

## 🧪 Testes e Validação
- Executada suíte de testes automatizados headless via Godot Console:
  - `tests/test_editor_goals_and_time_limit.tscn` -> 100% de sucesso.
  - `tests/test_editor_goals_and_panel.tscn` -> 100% de sucesso.
  - `tests/test_save_and_load_roundtrip.tscn` -> 100% de sucesso.
  - `tests/test_island_node_lvl4.tscn` -> 100% de sucesso.
  - `tests/test_editor_camera_and_shortcuts.tscn` -> 100% de sucesso.
- Zero erros de sintaxe e zero warnings no console da Godot Engine.

---

## 📦 Game SemVer e Sincronização
- **Versão anterior:** `v0.12.91-alpha`
- **Nova versão:** `v0.12.92-alpha`
- **Arquivos modificados:**
  - `scripts/level/island_mesh_builder.gd`
  - `shaders/interactive_grass_material.tres`
  - `shaders/lawn_base_decal.gdshader`
  - `scripts/plants/plant_database.gd`
  - `scripts/editor/tile_palette_db.gd`
  - `scripts/editor/level_editor_ui.gd`
  - `project.godot`
  - `export_presets.cfg`
