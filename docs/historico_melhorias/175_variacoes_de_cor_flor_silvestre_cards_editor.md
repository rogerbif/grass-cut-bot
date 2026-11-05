# Melhoria 175: Variações de Cor da Flor Silvestre e Dock de Cards no Editor de Fases 🌸🎨

**Versão:** `v0.12.121-alpha`  
**Data:** 05/11/2026  
**Status:** Concluído ✅

---

## 🎯 Objetivo e Contexto

Expandir o ecossistema botânico de flores do **Grass Cut Bot** criando variações de cores oficiais para o modelo da **Flor Silvestre** (`flower_01.glb`) e implementando um sistema contextual de **Cards de Variação de Cor** no **Editor de Fases PC Fullscreen** (`LevelEditorUI`).

Quando o usuário seleciona uma espécie que possui variações (como a Flor Silvestre) na paleta de objetos (Camada 2), o editor exibe dinamicamente uma prancheta inferior centralizada com cards contendo os ícones vetoriais coloridos de cada variação (com gradiente de pétala e miolo), selecionando uma variação padrão e permitindo alternar a cor de pintura no tile instantaneamente. Ao selecionar qualquer objeto sem variações (rochas, trigo, spawn) ou alternar para outra camada (Terreno, Grama), o dock oculta-se automaticamente.

---

## 🎨 Paleta Canônica de Variações da Flor Silvestre

Todas as variações compartilham o modelo em 3 partes (`Flower_Stem`, `Flower_Leaves`, `Flower_Petals`), desprendimento de 2 pétalas + 1 folha no 1º hit, e física de 3 hits / 5 moedas, diferenciando-se através de seus shaders de dois tons (`interactive_flower.gdshader`):

| ID | Nome da Variação | Ícone | Miolo Central (`center_color`) | Base Interna (`petal_inner_color`) | Ponta da Pétala (`petal_color`) | Material Tres |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| `flower` | **Rosa Silvestre** *(Padrão)* | 🌸 | Amarelo Dourado `(1.0, 0.88, 0.05)` | Magenta Profundo `(0.88, 0.10, 0.48)` | Rosa Claro `(1.0, 0.58, 0.80)` | `interactive_flower_material.tres` |
| `flower_blue` | **Azul Celeste** | 💠 | Amarelo Âmbar `(0.98, 0.82, 0.08)` | Azul Safira `(0.12, 0.28, 0.72)` | Ciano Pastel `(0.40, 0.90, 0.98)` | `interactive_flower_blue_material.tres` |
| `flower_sunset` | **Pôr do Sol** | 🌅 | Amarelo Queimado `(0.92, 0.72, 0.03)` | Carmim Escarlate `(0.78, 0.08, 0.24)` | Damasco/Pêssego `(0.99, 0.72, 0.42)` | `interactive_flower_sunset_material.tres` |
| `flower_purple` | **Lilás Encanto** | 🔮 | Branco Perolado `(0.96, 0.97, 0.99)` | Púrpura Imperial `(0.38, 0.12, 0.56)` | Lavanda Suave `(0.85, 0.70, 1.00)` | `interactive_flower_purple_material.tres` |
| `flower_white` | **Branca Suave** | 🤍 | Dourado Pastel `(0.92, 0.70, 0.03)` | Marfim Quente `(1.00, 0.92, 0.50)` | Branco Puro `(1.00, 1.00, 1.00)` | `interactive_flower_white_material.tres` |
| `flower_turquoise`| **Turquesa Mística** | 💎 | Âmbar Radiante `(0.96, 0.65, 0.04)` | Esmeralda Escura `(0.06, 0.48, 0.44)` | Turquesa Vibrante `(0.38, 0.94, 0.84)` | `interactive_flower_turquoise_material.tres` |

---

## 🛠️ Arquitetura e Implementação

### 1. `TilePaletteDB` (`scripts/editor/tile_palette_db.gd`)
- Criação do dicionário canônico `ITEM_VARIATIONS` mapeando `base_id` para listas de dicionários com dados de identificação, nome, cores de pétala, gradiente e miolo.
- Métodos utilitários:
  - `has_variations(base_id: String) -> bool`: verifica existência de variantes.
  - `get_variations(base_id: String) -> Array`: retorna a lista de variações para uma espécie base.
  - `get_base_id_for_variant(variant_id: String) -> String`: resolve qualquer id de variante (ex: `"flower_blue"`) de volta para sua espécie canônica base (`"flower"`).
  - `get_variation_data(variant_id: String) -> Dictionary`: retorna os metadados completos de cor de uma variante.

### 2. Dock Inferior de Cards no Editor (`LevelEditorUI`)
- **Posicionamento e Responsividade:** Ancorado com `PRESET_BOTTOM_WIDE`, `offset_left = 304`, `offset_right = -388`, `offset_top = -142`, `offset_bottom = -50`. Fica milimetricamente encaixado no vão entre o painel esquerdo (`offset_right = 292`), o painel direito (`offset_left = -376`) e acima da barra de status (`offset_top = -46`), impedindo colisões de UI em qualquer resolução (de 1280x720 a 4K).
- **Ícone Vetorial de Flor (`FlowerColorSwatch`):** Componente `Control` customizado que desenha em 2D 8 pétalas radiais utilizando interpolação linear de cores (`draw_polygon` com 4 vértices de gradiente de `inner_color` até `petal_color`) e um miolo circular central com `center_color` e contorno sombreado.
- **Card de Seleção:** Dimensões de `88x56px` com estilos normal, hover e selecionado (borda destacada em `petal_color`, fundo azul escuro acetinado `Color(0.16, 0.24, 0.32)` e texto na cor da pétala).
- **Fluxo de Seleção:**
  - Clicar em "Flor Silvestre" na paleta abre o dock com "Rosa Silvestre" selecionada por default.
  - Clicar em qualquer card de variante emite `object_item_selected` com o `variant_id` correspondente (`flower_blue`, `flower_sunset`, etc.).
  - O botão mestre "Flor Silvestre" no painel lateral direito permanece ativo enquanto qualquer variante estiver selecionada (`TilePaletteDB.get_base_id_for_variant(active_object_id) == oid_str`).
  - Selecionar outro item sem variantes (pedra, trigo, spawn) ou trocar de camada esconde o dock imediatamente.
  - Iniciar playtest esconde o dock junto com a UI do editor.

### 3. Visualização 3D e Persistência (`level_editor.gd`, `vegetation_grid.gd`, `level_json_loader.gd`)
- **Visualização 3D no Editor:** No método `_rebuild_3d_world()`, instâncias de flores verificam `VegetationGridScript.FLOWER_MATERIALS.has(o_type)` e injetam o `custom_material` respectivo no nó `Plant`.
- **Garantia de Atualização Reativa (`Plant`):** Implementado setter em `@export var custom_material: Material` em `plant.gd`, aplicando imediatamente as trocas de material nas malhas visuais `VisualMesh` mesmo após instanciação.
- **Persistência JSON:** As variantes são salvas no formato natural `{ "gx": x, "gz": z, "type": "flower_blue", "rot": 0 }`, sem necessidade de formatos intermediários ou migrações de esquema.
- **GPU MultiMesh Instancing no Gameplay:** `vegetation_grid.gd` registra todas as 6 variantes em `FLOWER_MATERIALS`, `VEG_TYPES`, com cache individual `_flower_variation_meshes` e cores de aparas (`_resolve_clipping_color`), permitindo colheita em lote com 60 FPS mobile.

---

## 🧪 Testes e Validação Automatizada

- **Teste Específico:** `tests/test_flower_variations_editor.tscn` executado via Godot Headless Console:
  - Validação de registro das 6 variações em `TilePaletteDB` e mapeamento reverso.
  - Validação da abertura do dock ao selecionar `flower` na camada 2.
  - Validação de seleção padrão e troca para `flower_blue`.
  - Validação de fechamento ao selecionar `rock` e ao trocar para a camada de grama.
  - Validação de instanciação no `LevelJsonLoader` e `VegetationGrid`.
  - **Resultado:** `100% de sucesso (0 falhas)`.
- **Suíte de Regressão:** `test_flower_detach.gd` (todas as 8 flores e desprendimento de peças passaram com sucesso), `test_editor_goals_and_time_limit.tscn` e `test_editor_camera_and_shortcuts.tscn` executados com 0 falhas e 0 warnings.
- **Zero Warnings:** Console Godot limpo sem avisos de tipagem ou identificadores sombreados.

---

## 📦 Arquivos Impactados

- `scripts/editor/tile_palette_db.gd`
- `scripts/editor/level_editor_ui.gd`
- `scripts/editor/level_editor.gd`
- `scripts/level/level_json_loader.gd`
- `scripts/plants/plant.gd`
- `scripts/plants/vegetation_grid.gd`
- `shaders/interactive_flower_blue_material.tres`
- `shaders/interactive_flower_sunset_material.tres`
- `shaders/interactive_flower_purple_material.tres`
- `shaders/interactive_flower_white_material.tres`
- `shaders/interactive_flower_turquoise_material.tres`
- `tests/test_flower_variations_editor.gd`
- `tests/test_flower_variations_editor.tscn`
- `project.godot`
- `scripts/core/game_version.gd`
- `export_presets.cfg`
