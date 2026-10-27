# Melhoria 126: Calibração de Luz, Toon Shader em 3 Tons e Diferenciação Nítida de Cores da Vegetação

**Data:** 27 de Outubro de 2026  
**Versão:** `v0.12.50-alpha`  
**Autor:** Antigravity  

---

## 1. Contexto e Motivação

Durante testes com o novo Toon/Cel Shader na cena de teste (`scenes/tools/toon_shader_tester.tscn`) e na fase real do jogo (`scenes/main.tscn`), foi identificada uma dificuldade em distinguir as diferentes espécies/cores de grama (especialmente na Fase 01, que possui 12 tufos de grama verde e 16 de grama amarela) e em visualizar a transição entre base, corpo sombreado e ponta iluminada nas lâminas individuais.

A análise revelou quatro causas fundamentais:
1. **Uniformes Desatualizados nos Materiais Não-Verdes:** Ao migrar `interactive_grass.gdshader` para a nova arquitetura Toon Shader, os parâmetros `color_light` e `color_shadow` foram introduzidos e `color_top` foi descontinuado. No entanto, os 6 materiais de grama não-verdes (`yellow`, `blue`, `purple`, `white`, `red`, `black`) e o material de trigo (`interactive_wheat_material.tres`) ainda continham apenas `color_top` e `color_base`, herdando os valores padrão do shader (`color_light` verde `vec4(0.42, 0.88, 0.46, 1.0)` e `color_shadow` verde `vec4(0.18, 0.50, 0.25, 1.0)`), fazendo com que 85% do corpo de qualquer grama ficasse verde no jogo.
2. **Escala de Brilho da Luz no Godot 4 (`LIGHT_COLOR / PI`):** No shader customizado de iluminação (`light()`), o Godot 4 fornece `LIGHT_COLOR` pré-multiplicado por $\pi \approx 3.14159$. A ausência da divisão por $\pi$ multiplicava o albedo por mais de $4.0\times$ nas regiões iluminadas sob `sun_energy = 1.30`, causando superexposição e forçando o uso de offsets extremos (`0.97`) que achatavam o gradiente.
3. **Cálculo de Normais em 360° por Lâmina (`grass_01.glb`):** A malha de grama possui 39 lâminas únicas com vetores normais voltados majoritariamente para cima ($+Y$). Ao construir uma normal radial 3D baseada no ângulo intrínseco de cada folha (`blade_angle` assado no canal de cor do Blender), as folhas voltadas para o sol recebem `color_light` e as folhas opostas entram fielmente no escalão de `color_shadow`.
4. **Contraste do Solo da Ilha com a Vegetação:** O topo procedural da ilha (`IslandMeshBuilder`) utilizava um verde saturado muito próximo ao albedo da grama verde. Um ajuste fino para um tom turf mais profundo (`Color(0.14, 0.45, 0.19)`) garantiu contraste imediato entre o piso, as raízes escuras e os tufos de grama.

---

## 2. Implementações Realizadas

### 2.1. Refatoração do Toon Shader (`shaders/interactive_grass.gdshader`)
- **Normalização por $\pi$:** Inclusão de `(LIGHT_COLOR / PI) * toon_ramp_tinting` na função `light()`, eliminando estouros brancos/neon e preservando com fidelidade as cores selecionadas.
- **Normal Radial 360° em Espaço de Visão:** Construção analítica da normal de cada folha no `vertex()`:
  ```gdshader
  vec3 world_blade_dir = normalize((MODEL_MATRIX * vec4(dir_fwd, 0.0)).xyz);
  vec3 blade_normal_world = normalize(mix(vec3(0.0, 1.0, 0.0), world_blade_dir, 0.80));
  v_geo_normal_view = normalize((VIEW_MATRIX * vec4(blade_normal_world, 0.0)).xyz);
  ```
- **Gradiente Vertical Quadrático (`grad_t`):** Curva suave `smoothstep(0.10, 0.92, h * h)` que preserva a raiz escura (`color_base`) visível nos primeiros 40% da altura da folha antes da transição para o topo.
- **Toon Ramp Equilibrado:** Padrão canônico com `toon_ramp_offset = 0.50` e `toon_ramp_smoothness = 0.28`.

### 2.2. Atualização e Padronização de Todos os 8 Materiais de Vegetação (`.tres`)
Atualização completa de todos os arquivos de material com paletas Toon vivas e contrastantes:
- **`interactive_grass_material.tres` (Verde):**
  - `color_light = Color(0.42, 0.88, 0.46)`
  - `color_shadow = Color(0.18, 0.50, 0.25)`
  - `color_base = Color(0.10, 0.30, 0.15)`
- **`interactive_grass_yellow_material.tres` (Amarela Solar):**
  - `color_light = Color(1.00, 0.84, 0.18)`
  - `color_shadow = Color(0.76, 0.52, 0.10)`
  - `color_base = Color(0.48, 0.30, 0.06)`
- **`interactive_grass_blue_material.tres` (Azul Celeste):**
  - `color_light = Color(0.24, 0.72, 1.00)`
  - `color_shadow = Color(0.14, 0.44, 0.78)`
  - `color_base = Color(0.08, 0.22, 0.48)`
- **`interactive_grass_purple_material.tres` (Roxa Mística):**
  - `color_light = Color(0.74, 0.34, 0.98)`
  - `color_shadow = Color(0.48, 0.18, 0.72)`
  - `color_base = Color(0.26, 0.08, 0.44)`
- **`interactive_grass_white_material.tres` (Branca Nevada):**
  - `color_light = Color(0.98, 0.99, 1.00)`
  - `color_shadow = Color(0.72, 0.78, 0.86)`
  - `color_base = Color(0.48, 0.54, 0.64)`
- **`interactive_grass_red_material.tres` (Vermelha Rubi):**
  - `color_light = Color(0.98, 0.30, 0.34)`
  - `color_shadow = Color(0.70, 0.16, 0.20)`
  - `color_base = Color(0.42, 0.08, 0.10)`
- **`interactive_grass_black_material.tres` (Preta Vulcânica):**
  - `color_light = Color(0.28, 0.30, 0.35)`
  - `color_shadow = Color(0.15, 0.16, 0.20)`
  - `color_base = Color(0.06, 0.06, 0.08)`
- **`interactive_wheat_material.tres` (Trigo Dourado):**
  - `color_light = Color(0.98, 0.82, 0.28)`
  - `color_shadow = Color(0.76, 0.56, 0.16)`
  - `color_base = Color(0.50, 0.34, 0.10)`

### 2.3. Sincronização de Partículas e Decalques
- Em `scripts/plants/vegetation_grid.gd` e `scripts/plants/plant.gd`, a recuperação de cor para efeitos de partículas agora consulta `"color_light"` prioritariamente com fallback para `"color_top"`.

### 2.4. Top HUD: Inicialização Imediata dos Cards de Metas
- Em `scripts/ui/hud.gd`, adicionada verificação defensiva em `_ready()` para instanciar imediatamente todos os Goal Cards caso `GameManager.goals` já tenha sido preenchido por `LevelController`, garantindo que todas as metas (ex: Verde, Amarela e Azul na Fase 02) fiquem visíveis desde o frame 0.

### 2.5. Estúdio Toon Shader (`scripts/tools/toon_shader_tester.gd`)
- Propagação de ajustes de sliders (`toon_ramp_offset`, `toon_ramp_smoothness`, `vertical_gradient_mix`, `roughness`, `use_rim`, `rim_power`, `rim_brightness`) em tempo real para todos os materiais em `VegetationGridScript.GRASS_MATERIALS`.
- Preset `"grass"` atualizado com as novas coordenadas canônicas.

---

## 3. Verificação Visual e GPU

- Capturas de viewport direto da GPU (`snap_lvl1_main.png`, `snap_lvl1_tester.png`, `snap_lvl2_main.png`) comprovaram:
  - Na **Fase 01**: separação cristalina entre o anel interno de grama verde esmeralda e o anel externo de grama amarela solar, com raízes escuras e solo em perfeito contraste.
  - Na **Fase 02**: distinção imediata entre as três cores (Verde, Amarela e Azul Celeste) e correspondência 1:1 com os 3 cards do Top HUD.
  - **Identidade Estúdio vs Jogo**: `toon_shader_tester.tscn` e `main.tscn` produzem imagens equivalentes em iluminação, geometria e sombreamento.
- **Validação Headless:** Execução com 0 erros e 0 warnings no console do Godot.
