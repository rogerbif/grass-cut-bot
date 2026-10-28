# Melhoria 144: Correção Definitiva de Materiais de Flores e Margaridas Brancas no Mobile 🌿🌼

## 🎯 Objetivo e Contexto
1. **Diagnóstico e Resolução do Problema das Margaridas Rosas no Android:**
   - No PC (Godot Editor / Debug), as margaridas (`flower_daisy`) eram exibidas com pétalas brancas e miolo amarelo. No celular (APK compilado), as mesmas margaridas apareciam com pétalas cor-de-rosa vibrante.
   - A investigação forense revelou que o compilador de exportação binária do Godot (`EditorExportPlatform`) descarta silenciosamente propriedades `surface_material_override` em nós filhos de cenas 3D importadas (`.glb`).
   - Com o override nulo no APK compilado, o Godot Mobile recorria ao material nativo embutido no modelo `flower_03_daisy.glb` (`Mat_Flower_Petals`), cujo albedo gravado no arquivo era `Color(0.964, 0.5064, 0.7858, 1.0)` (rosa-choque).
   - O método `_apply_visual_material` de `plant.gd` nunca rodava para MultiMesh porque a instância da flor é criada fora da SceneTree (`add_child` não é chamado), não disparando o `_ready()`.
2. **Blindagem Programática Universal para Todas as 8 Espécies Botânicas:**
   - Injeção programática direta de materiais nas superfícies combinadas do `MultiMeshInstance3D` através de um mapeamento canônico `FLOWER_MATERIALS`, tornando a renderização 100% imune a qualquer bug de serialização do exportador da Godot.
3. **Sincronização de Metas e Ícone do HUD:**
   - Atualização da meta da Fase 04 de `"flower": 8` para `"flower_daisy": 8`, fazendo o Top HUD exibir o ícone canônico 🌼 (Margarida) com pétalas brancas em vez do ícone genérico 🌸.

---

## 🛠️ Alterações Realizadas

### 1. `scripts/plants/vegetation_grid.gd`
- Adicionadas as tabelas canônicas pré-carregadas de materiais:
  ```gdscript
  const FLOWER_MATERIALS: Dictionary = {
      "flower": preload("res://shaders/interactive_flower_material.tres"),
      "flower_rose": preload("res://shaders/flower_rose_material.tres"),
      "flower_daisy": preload("res://shaders/flower_daisy_material.tres"),
      "flower_sunflower": preload("res://shaders/flower_sunflower_material.tres"),
      "flower_bell": preload("res://shaders/flower_bell_material.tres"),
      "flower_corolla": preload("res://shaders/flower_corolla_material.tres"),
      "flower_tulip": preload("res://shaders/flower_tulip_material.tres"),
      "flower_bed": preload("res://shaders/flower_bed_material.tres")
  }
  const FLOWER_LEAVES_MATERIAL: Material = preload("res://shaders/interactive_flower_leaves_material.tres")
  const FLOWER_STEM_MATERIAL: Material = preload("res://shaders/interactive_grass_material.tres")
  ```
- Criada a função dedicada `_build_flower_combined_mesh(flower_type: String, packed_scene: PackedScene) -> ArrayMesh` e seu auxiliar `_append_flower_meshes_recursive()`:
  - Identifica explicitamente cada nó da flor e injeta o material canônico na criação das superfícies via `SurfaceTool`:
    - `Flower_Petals` $\rightarrow$ `FLOWER_MATERIALS[flower_type]`
    - `Flower_Leaves` $\rightarrow$ `FLOWER_LEAVES_MATERIAL`
    - `Flower_Stem` $\rightarrow$ `FLOWER_STEM_MATERIAL`
- Atualizado o método `_ensure_static_meshes()` para construir as 8 espécies de flores através desse pipeline blindado.

### 2. `scripts/plants/plant.gd`
- No método `_apply_visual_material(target: Node)`:
  - Adicionado suporte programático explícito para `Flower_Leaves` e `Flower_Stem`, garantindo que flores instanciadas como entidades isoladas também possuam os materiais corretos mesmo se os overrides da cena `.scn` forem nulos.

### 3. `shaders/interactive_flower.gdshader`
- Alterada a cor padrão do uniform fallback de rosa para branco neutro puro:
  ```glsl
  uniform vec4 petal_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
  ```

### 4. `data/levels/level_04.json`
- Atualizada a meta de `"flower": 8` para `"flower_daisy": 8`. O Top HUD agora apresenta o card de meta com o emoji 🌼 e contagem 8, perfeitamente sincronizado com a espécie presente na ilha.

### 5. Testes Automatizados
- Criado o teste unitário `tests/test_inspect_daisy.tscn` / `test_inspect_daisy.gd`, que valida a integridade das 3 superfícies da malha da margarida, confirmando `petal_color == Color(1, 1, 1, 1)` e `center_color == Color(1, 0.85, 0, 1)`.

---

## ✅ Verificação e Qualidade
1. **Teste Automatizado de Inspeção de Malha:**
   - `tests/test_inspect_daisy.tscn`: Executado em modo headless com sucesso:
     - `Petal Color: (1.0, 1.0, 1.0, 1.0)`
     - `Center Color: (1.0, 0.85, 0.0, 1.0)`
     - `SUCESSO: Margarida configurada com pétalas brancas e materiais canônicos!`
2. **Teste de Simulação de APK Exportado:**
   - Cenas `.scn` extraídas de dentro de APKs exportados sem overrides foram submetidas ao novo `_build_flower_combined_mesh`, confirmando atribuição correta e imediata dos materiais canônicos em todas as superfícies.
3. **Suíte Automatizada de Detritos de Flores:**
   - `tests/test_flower_detach.gd`: Executado para as 8 espécies com `RESULTADO FINAL 8 FLORES: OK`.
4. **Verificação de Regressão e Zero Warnings:**
   - `tests/test_island_node_lvl4.tscn` e `scenes/menu/main_menu.tscn`: Executados em modo headless com **0 avisos de GDScript**.
