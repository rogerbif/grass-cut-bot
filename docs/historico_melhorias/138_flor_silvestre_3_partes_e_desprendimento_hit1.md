# Melhoria 138: Flor Silvestre em 3 Partes e Desprendimento de 2 Pétalas + 1 Folha no 1º Hit 🌸🍃

## 🎯 Objetivo
Dividir o modelo da **Flor Silvestre** (`flower`, `flower_01.glb`) em 3 partes (pétalas, folhas e caule) e, no **1º hit** (3 → 2 HP), desprender **2 pétalas e 1 folha** que são lançadas para cima, caem, diminuem e desaparecem.

## 🛠️ Alterações Realizadas
- **Modelo (`assets/models/flower_01.glb`):** reexportado do Blender (`export_apply=True`, `export_yup=True`) com 3 malhas: `Flower_Stem`, `Flower_Leaves` (material 0) e `Flower_Petals` (material 1). Vertex color reconstruído: pétalas externas `R=0.5`, internas `R=1.0`, miolos `G=1.0`, peças a desprender `B=1.0` (2 pétalas externas + 1 folha).
- **Novo `assets/models/flower_detach_pieces.glb`:** malhas `Piece_Petal_A`, `Piece_Petal_B` e `Piece_Leaf` com pivô no centro de cada peça.
- **Shader `interactive_flower.gdshader`:** no estágio ≥ 1, vértices com `COLOR.b > 0.5` colapsam (somem da haste, mesmo em `MultiMesh`).
- **Novo material `interactive_flower_leaves_material.tres`:** folhas verdes usando o shader de flor (permite ocultar a folha marcada).
- **`flower_tuft.tscn`:** nós `Flower_Leaves`, `Flower_Petals` e `Flower_Stem` com seus materiais.
- **Novo `scripts/plants/flower_detach_piece.gd` (`FlowerDetachPiece`):** peça-detrito sem `RigidBody3D`: impulso vertical de 4 ~ 5 m/s, giro livre, gravidade de 14 m/s², ao tocar o solo encolhe em 0,4 s e executa `queue_free`.
- **`plant.gd`:** `spawn_flower_detach_pieces()` (apenas `plant_key == "flower"`), chamado no hit 1; `_apply_visual_material()` aplica o material customizável só em `Flower_Petals`.
- **`vegetation_grid.gd`:** o mesmo desprendimento no ramo `MultiMesh` (`new_hp == 2`).
- **Teste:** `tests/test_flower_detach.gd` (3 partes presentes, 3 peças lançadas e todas removidas em ≤ 3 s).

## ✅ Validação
- `godot --headless --import` sem erros; teste headless `RESULTADO: OK`; sem warnings de script.
- Versão `0.12.62-alpha`.
