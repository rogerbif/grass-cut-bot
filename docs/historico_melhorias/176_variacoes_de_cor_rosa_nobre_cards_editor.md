# Melhoria 176: Variações de Cor da Rosa Nobre, Normalização Radial e Cards Dinâmicos no Editor 🌹🎨

**Versão:** `v0.12.122-alpha`  
**Data:** 05/11/2026  
**Status:** Concluído ✅

---

## 🎯 Objetivo e Contexto

Aprimorar visualmente a **Rosa Nobre** (`flower_rose`, `flower_02_rose.glb`) aplicando a mesma abordagem anatômica de gradiente radial duplo de cores utilizada na Flor Silvestre, criando **6 variações de cores oficiais** (Vermelha Nobre, Branca Imperial, Amarela Dourada, Azul Mística, Rosa Negra Veludo e Pêssego Salmão) e integrando os novos cards temáticos ao dock contextual do **Editor de Fases PC Fullscreen** (`LevelEditorUI`).

---

## 🎨 Paleta Canônica de Variações da Rosa Nobre

Todas as variações utilizam o modelo procedural em 3 partes (`Flower_Stem`, `Flower_Leaves`, `Flower_Petals`), desprendimento no 1º Hit (2 pétalas e 1 folha via `FlowerDetachPiece`) e resistência de 3 hits / 5 moedas:

| ID | Nome da Variação | Ícone | Base Interna (`petal_inner_color`) | Ponta das Pétalas (`petal_color`) | Núcleo Central (`center_color`) | Material Tres |
| :--- | :--- | :---: | :--- | :--- | :--- | :--- |
| `flower_rose` | **Vermelha Nobre** *(Padrão)* | 🌹 | Vinho Carmim Profundo `(0.43, 0.02, 0.11)` | Vermelho Rubi Aveludado `(1.0, 0.13, 0.32)` | Carmim Intenso `(0.55, 0.0, 0.13)` | `flower_rose_material.tres` |
| `flower_rose_white` | **Branca Imperial** | 🤍 | Marfim Quente `(0.85, 0.79, 0.68)` | Branco Pérola `(1.0, 1.0, 1.0)` | Dourado Pastel `(0.92, 0.84, 0.56)` | `flower_rose_white_material.tres` |
| `flower_rose_yellow` | **Amarela Dourada** | 💛 | Âmbar Alaranjado `(0.85, 0.35, 0.0)` | Amarelo Solar `(1.0, 0.87, 0.0)` | Ouro Intenso `(1.0, 0.72, 0.0)` | `flower_rose_yellow_material.tres` |
| `flower_rose_blue` | **Azul Mística** | 💙 | Azul Safira Profundo `(0.06, 0.16, 0.43)` | Azul Celeste / Ciano `(0.28, 0.69, 1.0)` | Índigo Noturno `(0.10, 0.23, 0.55)` | `flower_rose_blue_material.tres` |
| `flower_rose_black` | **Rosa Negra Veludo** | 🖤 | Vinho Quase Negro `(0.09, 0.03, 0.07)` | Bordô Escuro Aveludado `(0.36, 0.09, 0.21)` | Grafite Preto Carbono `(0.14, 0.13, 0.16)` | `flower_rose_black_material.tres` |
| `flower_rose_peach` | **Pêssego Salmão** | 🧡 | Terracota Coral `(0.72, 0.25, 0.15)` | Pêssego Salmão Pastel `(1.0, 0.66, 0.52)` | Damasco Dourado `(0.91, 0.51, 0.23)` | `flower_rose_peach_material.tres` |

---

## 🛠️ Arquitetura e Implementação

### 1. Calibração e Normalização 3D do Modelo (`flower_02_rose.glb`)
- **Normalização Radial no Canal Alpha ($A \in [0.0, 1.0]$):** Através do Blender 5.2 (script headless `scratch/export_rose.py`), calculou-se a distância tridimensional exata $d = \|\mathbf{v} - \mathbf{c}_{core}\|$ de cada um dos 1.144 vértices de `Flower_Petals` até o centro do miolo da rosa (`rose_center` $\approx (0, -0.047, 0.994)$).
- **Gradiente Parabólico Aveludado:** $A = \mathrm{clamp}((d - d_{min}) / (d_{max} - d_{min}), 0.0, 1.0)^{0.9}$, proporcionando uma transição suave da base interna escura das pétalas concêntricas para as bordas externas luminosas.
- **Preservação R, G e B:** Mantidos rigorosamente os canais $R=0.5$ (pétalas externas, Hit 1), $R=1.0$ (pétalas internas, Hit 2), $G=1.0$ (miolo central) e $B=1.0$ (peças destacáveis de detrito).
- **Exportação Canônica:** Exportado com `export_apply=True` e `export_yup=True`, seguido de `godot --headless --import` para reconstrução do cache `.godot/imported/`.

### 2. Ícones Vetoriais Concéntricos de Rosa (`FlowerColorSwatch`)
- A classe de desenho 2D `FlowerColorSwatch` em `level_editor_ui.gd` foi aprimorada com o modo `is_rose`:
  - **Camada Externa:** 6 pétalas maiores com interpolação de cor linear suave (`inner_color` $\to$ `petal_color`).
  - **Camada Interna:** 5 pétalas intermediárias defasadas em rotação angular (+20°).
  - **Miolo Rosette:** Botão central circular com espiral interna concêntrica traçada em `inner_color`.
- Ao selecionar a Rosa Nobre no editor, o dock projeta o título `"🎨 VARIAÇÕES DE COR (ROSA NOBRE):"` com os 6 cards de rosa desenhados fielmente.

### 3. Integração com Gameplay, LevelJsonLoader e VegetationGrid
- **`TilePaletteDB`:** Mapeamento bidirecional completo em `ITEM_VARIATIONS["flower_rose"]` e resolução dinâmica de `goal_key` para `"flower_rose"`.
- **`Plant` (`plant.gd`):** Cores de partículas registradas em `get_flower_colors()` e suporte nativo em `_ensure_detach_meshes` e `spawn_flower_detach_pieces` reconhecendo o prefixo `flower_rose_*`.
- **`VegetationGrid` (`vegetation_grid.gd`):** Registro de todas as 6 variações em `FLOWER_MATERIALS`, `VEG_TYPES`, cache em `_flower_variation_meshes` e aparas cortadas em `_resolve_clipping_color`.
- **`LevelJsonLoader` (`level_json_loader.gd`):** Suporte direto em `OBJECT_SCENES` e injeção atômica de `custom_material`.
- **`LevelEditor` (`level_editor.gd`):** Instanciação 3D com `o_type.begins_with("flower_rose")` no `_rebuild_3d_world()`.

---

## 🧪 Validação e Testes Automatizados

- **`tests/test_flower_variations_editor.tscn`:**
  - 6 variações de `flower` e 6 variações de `flower_rose` validadas.
  - Sincronização do dock, título contextual, alternância de cards e ocultação em itens sem variação.
  - Instanciação de nós 3D com `custom_material` como `ShaderMaterial`.
  - **Resultado:** 100% de sucesso (0 falhas).
- **`tests/test_flower_detach.gd`:**
  - Suíte de desprendimento das 8 flores e peças executada com sucesso total (0 erros, 0 vazamentos de lógica).
- **Godot Console:** 0 warnings e 0 erros de compilação.

---

## 📦 Arquivos Impactados

- `assets/models/flower_02_rose.glb`
- `shaders/flower_rose_material.tres`
- `shaders/flower_rose_white_material.tres`
- `shaders/flower_rose_yellow_material.tres`
- `shaders/flower_rose_blue_material.tres`
- `shaders/flower_rose_black_material.tres`
- `shaders/flower_rose_peach_material.tres`
- `scripts/editor/tile_palette_db.gd`
- `scripts/editor/level_editor_ui.gd`
- `scripts/editor/level_editor.gd`
- `scripts/plants/plant.gd`
- `scripts/plants/vegetation_grid.gd`
- `scripts/level/level_json_loader.gd`
- `tests/test_flower_variations_editor.gd`
- `project.godot`
- `scripts/core/game_version.gd`
- `export_presets.cfg`
