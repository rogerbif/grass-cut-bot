# Melhoria 107: Flores em 3 Hits com Despetalação Progressiva via Vertex Color, Cores Customizáveis e Integração ao Editor de Fases 🌸🪚

## 🎯 Objetivo e Contexto
Modernização completa do subsistema de **Flores Nobres (`FlowerTuft`)** para:
1. **Mecânica em 3 Golpes:** Exigir 3 hits para ceifar o tufo (`max_health = 3`).
2. **Despetalação Progressiva com Partículas:**
   - **Hit 1 ($3 \rightarrow 2$ HP):** A 1ª metade das pétalas (8 pétalas externas) colapsa e é ejetada em burst de partículas de pétala coloridas.
   - **Hit 2 ($2 \rightarrow 1$ HP):** A 2ª metade das pétalas (8 pétalas internas) colapsa e voam mais partículas de pétala, restando apenas os miolos e o caule/folhas verdes.
   - **Hit 3 ($1 \rightarrow 0$ HP - Fatal):** O caule é ceifado rente ao solo, saem miolos e folhas verdes, concedendo +5 moedas e fechando a meta.
3. **Caule/Folhas Sempre Verdes + Cores Dinâmicas:** Separação anatômica em 2 slots de material no modelo único `.glb` (Slot 0: Caule/Folhas Verde Fixo, Slot 1: Pétalas/Miolo via `interactive_flower.gdshader`), permitindo flores de qualquer cor (vermelho, amarelo, azul, roxo, branco) duplicando apenas materiais `.tres`.
4. **Integração no Editor de Fases:** Objeto de primeira classe na camada de Objetos com instanciação 3D imediata no mapa, resumo de metas e persistência JSON.

---

## 🛠️ Alterações Realizadas

### 1. Modelagem 3D & Exportação (Blender Pipeline)
- **Anatomia Identificada e Assada:** O modelo aberto no Blender (`FlowerY1_GRADIENT_0`) de 306 vértices e 46 ilhas foi processado via script:
  - 28 ilhas de caule e folhas da base $\rightarrow$ Material 0 (`Mat_Flower_StemLeaves`), Vertex Color $R = 0.0$.
  - 2 ilhas de miolos $\rightarrow$ Material 1 (`Mat_Flower_Petals`), Vertex Color $R = 0.0, G = 1.0$.
  - 16 pétalas alternadas angularmente $\rightarrow$ 8 pétalas externas com $R = 0.5$ (Hit 1) e 8 pétalas internas com $R = 1.0$ (Hit 2).
- **Exportação Canônica:** `assets/models/flower_01.glb` exportado com `export_apply=True` e `export_yup=True`.
- **Malha Leve de Partícula:** Extração e exportação de `assets/models/cut_petal_piece.glb` (8 faces, base centrada no pivô) para o pool de partículas de pétala.

### 2. Shaders e Materiais
- **`shaders/interactive_flower.gdshader`:**
  - Balanço pendular orgânico com vento (`wind_speed`, `wind_strength`).
  - Interação física com a serra (`global_cutter_pos`, `global_cutter_interact_radius`).
  - **Colapso Seletivo de Pétalas na GPU:** `stage = max(INSTANCE_CUSTOM.r, instance_hit_stage)`. No Hit 1 ($R = 0.5$) e Hit 2 ($R = 1.0$), `VERTEX = vec3(0.0)`.
  - Diferenciação de cor entre pétalas (`petal_color`) e miolo (`center_color` via $G > 0.5$).
- **Materiais Criados:**
  - `shaders/interactive_flower_material.tres` (Rosa/Magenta)
  - `shaders/interactive_flower_red_material.tres` (Vermelho Rubi)
  - `shaders/interactive_flower_yellow_material.tres` (Amarelo Solar)
  - `shaders/interactive_flower_blue_material.tres` (Azul Celeste)
  - `shaders/interactive_flower_purple_material.tres` (Roxo Místico)
  - `shaders/interactive_flower_white_material.tres` (Branco Algodão)

### 3. Cenas e Entidades
- **`scenes/plants/flower_tuft.tscn`:** Atualizado com `flower_01.glb`, `max_health = 3`, `coin_reward = 5`, `type = PlantType.FLOWER`, `collision_layer = 4`.
- **`scripts/plants/plant.gd`:**
  - `_get_petal_mesh()` com fallback para `cut_petal_piece.glb`.
  - Tratamento de hits parciais com `_apply_flower_damage_stage()`, atualizando `instance_hit_stage` no shader e disparando `_spawn_petal_burst(6)`.
  - Proteção em `_apply_visual_material()` para manter o slot 0 (caule) sempre verde.

### 4. GPU Instancing MultiMesh (`VegetationGrid`)
- **`scripts/plants/vegetation_grid.gd`:**
  - `mm.use_custom_data = true` ativado para o MultiMesh de flores.
  - `max_hp` calibrado para 3 quando `v_type == "flower"`.
  - No `cut_in_circle()`: nos hits 1 e 2, `mm.set_instance_custom_data(inst_idx, Color(stage, 0, 0, 0))` e disparo de partículas coloridas de pétala.
  - No hit 3 (fatal): ceifa total, apara deitada no solo e premiação no `GameManager`.

### 5. Editor de Terreno / Fases (Nível de Objetos)
- **`scripts/editor/level_editor.gd`:**
  - `FLOWER_SCENE` pré-carregada.
  - Em `_rebuild_3d_world()`, instanciação visual 3D em tempo real de `FLOWER_SCENE` quando `o_type == "flower"` em `object_grid`.
- **`scripts/editor/level_editor_ui.gd` & `tile_palette_db.gd`:**
  - Ícone `🌸 Flor Nobre` de primeira classe na paleta de objetos.
  - Contabilização no resumo de metas (`🌸 Flores: N`) e persistência no JSON v3.

---

## 🧪 Validação
1. **Reimportação Atômica:** Executado `godot --headless --import` com compilação bem-sucedida de `flower_01.glb` e `cut_petal_piece.glb`.
2. **Execução Headless & Engine Check:** Projeto rodou em modo de depuração com 0 erros e 0 warnings no console.
3. **Editor de Fases:** Cena `level_editor.tscn` validada com flores 3D posicionadas e responsivas.
4. **Game SemVer:** Incrementado para `v0.12.32-alpha`.
