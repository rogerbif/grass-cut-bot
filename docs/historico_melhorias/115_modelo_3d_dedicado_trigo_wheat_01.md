# Melhoria 115: Extração e Substituição pelo Modelo 3D Dedicado de Trigo (`wheat_01.glb`) 🌾✨

**Versão:** `v0.12.40-alpha`  
**Data:** 27/10/2026

---

## 1. Contexto e Motivação

O usuário solicitou:
> *"pegue somente um trigo do arquivo wheat que esta aberto no blender e subistitua pelo nosso modelo de trigo"*

Anteriormente, a cultura de trigo (`wheat`) no jogo utilizava temporariamente a malha de grama (`assets/models/grass_01.glb`) com uma variação de cor e shader amarelo/dourado (`interactive_wheat_material.tres`). No arquivo `wheat.blend` aberto no Blender (contendo uma plantação de trigo estilizada low poly do Google Poly), havia um campo com diversas plantas agrupadas.

---

## 2. Alterações Implementadas

### 2.1. Extração e Otimização do Trigo no Blender (`wheat.blend` -> `wheat_01.glb`)
- **Isolamento de Uma Única Haste Canônica:** Identificada a planta mais completa e vertical (Plant 14), contendo caule cilíndrico, folhas laterais fletidas e a espiga de grãos no topo (338 vértices e 165 faces).
- **Alinhamento do Pivô Ancorado no Solo:** Pivô de coordenadas centralizado exatamente na base da haste em $(0.0, 0.0, 0.0)$, garantindo que o caule se fixe rente ao solo na ilha.
- **Calibração de Proporções Low Poly:** Altura ajustada para $1.10\text{m}$ (porte maduro em escala perfeita com a grama de $1.05\text{m}$), com proporções laterais estilizadas ($0.36\text{m} \times 0.17\text{m}$) para visibilidade e leitura nítida na câmera isométrica mobile portrait.
- **Mapeamento UV Gradiente (Compatibilidade Arnklit Shader):** Camada `UVMap` gerada com $UV.y \in [0.0, 1.0]$ da raiz à ponta da espiga, garantindo sincronização nativa com `interactive_grass.gdshader`:
  - $V = 0.0$: Raiz fixa no solo com deslocamento zero.
  - $V \in [0.06, 1.0]$: Curvatura parabólica quadrática suave impulsionada pelo vento e cortador.
  - Fragment Shader: Gradiente da cor base âmbar/ouro (`color_base`) para o topo radiante da espiga (`color_top`).
- **Material Fosco Low Poly:** Criado material `M_Wheat_Default` com `roughness = 0.90`, `specular = 0.15` e tom amarelo dourado (`#f5c430`).
- **Exportação glTF:** Exportado via `bpy.ops.export_scene.gltf` com `export_apply=True` e `export_yup=True` para `assets/models/wheat_01.glb`.

### 2.2. Integração e Atualização na Cena do Godot (`wheat_tuft.tscn`)
- Atualizada a cena base `scenes/plants/wheat_tuft.tscn`:
  - `ext_resource` apontando para `res://assets/models/wheat_01.glb` (`uid="uid://dbgvk2a8xwnxu"`).
  - Nó `VisualMesh` instanciando `Wheat01` e aplicando `material_override = ExtResource("3_wheat_mat")`.
  - Como `vegetation_grid.gd` e `island_node.gd` extraem dinamicamente a malha `_wheat_mesh` de `WHEAT_SCENE.instantiate()`, todas as instâncias de trigo em gameplay (`MultiMeshInstance3D`), no Editor de Fases e nas miniaturas de ilha do Menu Principal adotaram automaticamente o novo modelo 3D dedicado.

---

## 3. Verificação e Validação

1. **Reimportação Atômica:** Executado `Godot --headless --import` com sucesso, gerando o cache `.scn` de `wheat_01.glb`.
2. **Teste Automatizado de Trigo:** `res://tests/test_wheat_level_02.tscn` executado com **100% de sucesso**, validando o carregamento da malha de trigo, a meta 1:1 e a mecânica de ceifa.
3. **Gameplay e Menus:** Execução headless em `res://scenes/main.tscn` e `res://scenes/menu/main_menu.tscn` aprovada com **0 warnings e 0 erros**.
