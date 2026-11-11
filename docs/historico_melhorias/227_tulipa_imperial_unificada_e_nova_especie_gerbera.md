# Melhoria 227: Unificação de Modelo da Tulipa Imperial e Criação da Nova Espécie Gérbera Tropical (6 Variações) (`v0.12.181-alpha`)

## 1. Contexto e Motivação
Durante inspeções visuais no Editor de Fases e no gameplay, observou-se que as variações cromáticas da **Tulipa Imperial** (*Solar*, *Real* e *Chama*) exibiam um modelo 3D diferente da Tulipa original (*Rubi*): enquanto a Tulipa Rubi utilizava o cálice fechado autêntico de tulipa (`flower_07_tulip.glb`), as demais variações apareciam com pétalas abertas radiadas em formato de margarida/estrela (`flower_01.glb`).

O usuário solicitou:
1. Que **todas as variações de Tulipa Imperial** utilizem rigorosamente o mesmo modelo anatômico original de tulipa (`flower_07_tulip.glb`), variando unicamente as cores.
2. Que o modelo 3D radiado de pétalas abertas (`flower_01.glb`) seja transformado em uma **nova espécie botânica oficial** do catálogo do jogo, com identidade própria, variações de cores e suporte completo no gameplay e editor.
3. O usuário aprovou a denominação oficial da nova espécie como **Gérbera** (🌺).

---

## 2. Diagnóstico e Causa Raiz
Na análise do código em `scripts/editor/level_editor.gd` (linha 1377):
```gdscript
# Código anterior com falha:
elif o_type == "flower_tulip":
    sc = FLOWER_TULIP_SCENE
elif o_type == "flower_bed":
    sc = FLOWER_BED_SCENE
else:
    sc = FLOWER_SCENE # flower_01.glb (fallback!)
```
As variações cromáticas de Tulipa no editor utilizam sufixos como `flower_tulip_yellow`, `flower_tulip_purple` e `flower_tulip_orange`. Devido à comparação estrita de igualdade (`==`), todas as variações falhavam no teste e caíam no `else`, instanciando indevidamente `FLOWER_SCENE` (`flower_01.glb`).

---

## 3. Implementação e Solução Técnica

### A. Correção da Instanciação no Editor de Fases (`scripts/editor/level_editor.gd`)
A verificação foi corrigida para prefixos com `begins_with()`, e a cena oficial de Gérbera foi incorporada:
```gdscript
const FLOWER_GERBERA_SCENE: PackedScene = preload("res://scenes/plants/flower_gerbera.tscn")
...
elif o_type.begins_with("flower_tulip"):
    sc = FLOWER_TULIP_SCENE
elif o_type.begins_with("flower_gerbera"):
    sc = FLOWER_GERBERA_SCENE
elif o_type.begins_with("flower_bed"):
    sc = FLOWER_BED_SCENE
```

### B. Criação da Nova Espécie Botânica: Gérbera Tropical (`flower_gerbera` 🌺)
1. **Modelo 3D:** `flower_01.glb` (3 flores por tufo em disposição triangular com pétalas abertas em estrela, botão central e folhas pontiagudas).
2. **Cena Base:** `scenes/plants/flower_gerbera.tscn` com colisor cilíndrico de raio $0.18\text{m}$, altura $0.55\text{m}$ e nó de colheita `Plant`.
3. **6 Materiais Cel-Shaded Canônicos:**
   - `shaders/flower_gerbera_material.tres`: **Gérbera Rubi / Coral** (`albedo_color = #FF1F47`, miolo dourado âmbar `#C4720D`).
   - `shaders/flower_gerbera_yellow_material.tres`: **Gérbera Solar** (`albedo_color = #FFE00D`, miolo castanho avelã `#6B3B0C`).
   - `shaders/flower_gerbera_purple_material.tres`: **Gérbera Real** (`albedo_color = #D926CC`, miolo carmim profundo `#590A38`).
   - `shaders/flower_gerbera_orange_material.tres`: **Gérbera Chama** (`albedo_color = #FF730D`, miolo âmbar escuro `#8A3805`).
   - `shaders/flower_gerbera_pink_material.tres`: **Gérbera Rosa Tropical** (`albedo_color = #FF66B2`, miolo amarelo dourado `#B88A00`).
   - `shaders/flower_gerbera_white_material.tres`: **Gérbera Branca Pura** (`albedo_color = #FFFFFF`, miolo amarelo ouro `#CC9900`).

### C. Integração no Ecossistema da Engine
1. **Grade MultiMesh Otimizada (`scripts/plants/vegetation_grid.gd`):**
   - Mapeamento de todas as 6 chaves em `FLOWER_MATERIALS`.
   - Inclusão no dicionário `VEG_TYPES` com `resistance: 3` e `reward_coins: 5`.
   - Cache de malha `_flower_gerbera_mesh` e geração em lote MultiMesh em `_build_from_vector_field()` e `_rebuild_from_positions_direct()`.
   - Paleta de cores para fragmentos de corte em `_resolve_type_particle_color()`.
2. **Entidade Interativa e Efeitos (`scripts/plants/plant.gd`):**
   - Configuração de despetalação progressiva (Hit 1 e 2) em `DETACH_CONFIG_BY_TYPE`.
   - Cores primárias e secundárias para partículas em `get_flower_colors()`.
3. **Catálogo e Herbário (`scripts/plants/plant_database.gd`):**
   - Cadastro de `flower_gerbera` ("Gérbera Tropical", nível de introdução 11, resistência 3, recompensa 5 moedas).
4. **Paleta e UI do Editor de Fases (`scripts/editor/tile_palette_db.gd` & `level_editor_ui.gd`):**
   - Ícone 🌺 adicionado em `OBJECT_ITEMS` com cor temática `Color(1.0, 0.35, 0.15)`.
   - 6 variações registradas em `ITEM_VARIATIONS["flower_gerbera"]`.
   - Suporte a metas botânicas individuais na interface e carregamento/salvamento JSON.
5. **Loader de Fases e Menus (`scripts/level/level_json_loader.gd`, `island_node.gd`, `map_level_card.gd`):**
   - Pré-carregamento das 6 variantes em `OBJECT_SCENES`.
   - Ordem canônica de objetivos (`GOAL_ORDER`) no card de fase do Mapa Mundi.
   - Suporte a MultiMesh de Gérbera nas miniaturas das ilhas do menu.

---

## 4. Verificação e Resultados
- **Teste Unitário Botânico Completo (`tests/test_all_botanical_variations.gd`):** Todas as 6 famílias florais (Rosa, Margarida, Girassol, Tulipa Imperial, Gérbera Tropical e Canteiro) validadas com 100% de sucesso e 0 warnings.
- **Captura In-Game (`test_tulip_and_gerbera_godot.png`):**
  - Todas as 4 variações da Tulipa Imperial (*Rubi*, *Solar*, *Real*, *Chama*) renderizam com perfeição o modelo autêntico em taça/cálice (`flower_07_tulip.glb`).
  - Todas as 4 variações de Gérbera (*Rubi*, *Solar*, *Real*, *Chama*) renderizam o modelo com pétalas radiadas abertas (`flower_01.glb`).
- **Zero Warnings:** Console Godot mantido estritamente com 0 warnings e 0 erros.
