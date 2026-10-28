# Melhoria 145: Grade Subdividida (0.40m), Elevação Anti-Flick (0.001m), Clareira de Rocha (1.40m), Corredor Costeiro e Alinhamento de Flores 🌿📐🪨🌼

**Data:** 28 de Outubro de 2026  
**Versão:** `v0.12.71-alpha`  
**Status:** Concluído com Sucesso e Testado (100% Aprovado)

---

## 1. Contexto e Objetivos

O Editor de Fases In-Game para PC passou por uma grande evolução de precisão, usabilidade e qualidade visual a partir de 5 demandas essenciais:

1. **Eliminação de Flicks (Z-Fighting) entre Formas Vetoriais:** Quando múltiplas formas vetoriais de grama se sobrepunham no mesmo plano horizontal ($Y = 0.005\text{m}$), ocorriam faixas visíveis de cintilação (Z-fighting stripes / *flicks*). A solução requisitada foi separar fisicamente as formas em altura por um milésimo de metro ($0.001\text{m}$).
2. **Subdivisão da Grade ($0.80\text{m} \rightarrow 0.40\text{m}$):** Cada quadrado clássico da grade foi subdividido em 4 sub-quadrantes ($0.40\text{m} \times 0.40\text{m}$), quadruplicando a precisão de posicionamento de obstáculos, rochas, flores e trigo sem alterar a física de corte do robô.
3. **Avaliação Crítica de Performance Mobile:** Análise aprofundada comprovando que a subdivisão lógica no editor não penaliza a performance no Android, pois a vegetação runtime é agrupada em `MultiMeshInstance3D` (1 Draw Call por tipo) e o terreno consolidado em malha extrudada contínua única (`IslandMeshBuilder`).
4. **Clareira de Segurança da Rocha ($1.40\text{m}$):** Ao colocar uma pedra ou passar o mouse sobre ela com o pincel, foi estabelecido um raio de exclusão de $1.40\text{m}$ (correspondente ao raio máximo da lâmina Nível 6, `UpgradeManager.MAX_BLADE_RADIUS`). Dentro dessa clareira, nenhuma grama, trigo ou flor pode existir ou ser posicionada, garantindo manobra livre para a serra.
5. **Corredor Costeiro Perimetral ($0.48\text{m}$):** Ao pintar grama, o traço agora respeita um calçadão/corredor desimpedido recuado da borda da ilha (`Geometry2D.offset_polygon(..., -0.48)`), impedindo que tufos sejam gerados caindo no mar ou bloqueando o perímetro costeiro.
6. **Alinhamento Frontal e Estabilidade de Rotação das Flores:**
   - Todas as flores criadas vêm por padrão voltadas para a câmera isométrica ($0^\circ$).
   - Correção do bug onde adicionar uma nova flor fazia com que todas as flores existentes girassem aleatoriamente devido à chamada de `_ready()` com `randf_range(0, TAU)`. Com `randomize_rotation = false` no editor, a rotação canônica é 100% preservada.

---

## 2. Análise de Performance Mobile (Grade 0.40m & Elevação 0.001m)

| Métrica | Comportamento Anterior (0.80m) | Novo Comportamento (0.40m & 0.001m) | Impacto no Android (60 FPS) |
| :--- | :--- | :--- | :--- |
| **Draw Calls Terreno** | 1 Draw Call (`IslandMeshBuilder`) | 1 Draw Call (`IslandMeshBuilder`) | **Zero impacto:** A fusão booleana Clipper unifica todas as faces superiores e falésias em uma única malha contínua. |
| **Draw Calls Vegetação** | 1 Draw Call por tipo (`MultiMeshInstance3D`) | 1 Draw Call por tipo (`MultiMeshInstance3D`) | **Zero impacto:** Instâncias continuam no mesmo buffer GPU. |
| **Z-Buffer & Flicks** | Cintilação visível por coplanaridade | $0.001\text{m}$ de separação vertical ($1\text{mm}$) | **Excelente:** Elimina Z-fighting sem artefatos visuais no ângulo isométrico ($42^\circ$). |
| **Memória JSON de Fases** | Células discretas de 0.80m | Células discretas de 0.40m | **Desprezível:** Arquivos JSON passam de ~12KB para ~25KB, sem qualquer pressão sobre a RAM. |
| **Poisson Disk de Grama** | $r = 0.22\text{m}$ sobre área poligonal contínua | $r = 0.22\text{m}$ sobre área poligonal contínua | **Zero alteração:** A contagem de tufos gerados depende da área do polígono contínuo em $\text{m}^2$, não da grade. |

---

## 3. Alterações Implementadas por Arquivo

1. **`scripts/core/upgrade_manager.gd`:**
   - Adicionada constante canônica `const MAX_BLADE_RADIUS: float = 1.40`.
   - Adicionado método estático `static func get_max_blade_radius() -> float`.

2. **`scripts/editor/brush_patterns.gd`:**
   - Implementado gerador estático de polígono circular: `static func get_circle_polygon(center: Vector2, radius_m: float, segments: int = 24) -> PackedVector2Array`.

3. **`scripts/level/vector_grass_field.gd`:**
   - Em `generate_ground_meshes()`, cada forma vetorial sobreposta recebe elevação escalonada: `var y_level: float = 0.005 + float(maxi(0, s_idx)) * 0.001`.
   - Erradicação completa do efeito de flickering listrado entre polígonos de grama sobrepostos.

4. **`scripts/plants/plant.gd`:**
   - Adicionada propriedade `@export var randomize_rotation: bool = true`.
   - No `_ready()`, o giro aleatório só é executado se `randomize_rotation` for verdadeiro; caso contrário, `visual_mesh.rotation.y = 0.0`.

5. **`scripts/editor/grid_overlay.gd`:**
   - `rebuild_grid()` agora opera com `cell_size = 0.40m` por padrão.
   - Renderização de linhas primárias a cada $0.80\text{m}$ com opacidade $0.35$ e subdivisões a cada $0.40\text{m}$ com opacidade $0.16$.
   - `update_brush_preview()` suporta `clearance_radius: float = 0.0`, desenhando um anel amarelo de $1.40\text{m}$ ao posicionar pedras.

6. **`scripts/plants/vegetation_grid.gd`:**
   - `_build_from_vector_field()` atualizado para receber `tile_rocks: Dictionary = {}` e filtrar automaticamente flores e trigo a menos de $1.40\text{m}$ de qualquer rocha.
   - MultiMesh de flores agora respeita a propriedade `"rot"` do JSON e garante alinhamento frontal com a câmera ($0^\circ$).

7. **`scripts/menu/island_node.gd`:**
   - Substituído recorte fixo de $0.50\text{m}$ por `BrushPatterns.get_circle_polygon(..., 1.40)` em ambas as rotas de carregamento.

8. **`scripts/editor/level_editor.gd`:**
   - `CELL_SIZE = 0.40`, `COASTAL_GRASS_CORRIDOR = 0.48`, `ROCK_CLEARANCE_RADIUS = 1.40`.
   - Ao selecionar flores na paleta, `current_rot_deg = 0` por padrão.
   - Implementado `_get_safe_coastal_island_polygons()` via `Geometry2D.offset_polygon(..., -COASTAL_GRASS_CORRIDOR)`.
   - Pinceladas de grama são recortadas contra o corredor seguro da ilha.
   - Posicionamento de rocha expurga grama em disco de $1.40\text{m}$ e remove flores/trigo pré-existentes no raio.
   - Tentativa de colocar flores/trigo a menos de $1.40\text{m}$ de uma pedra é rejeitada com aviso Toast sonoro na UI.
   - `_rebuild_3d_world()` instancia flores com `randomize_rotation = false` e `rotation_degrees.y = rot`, eliminando o bug de rotação coletiva.
   - Auto-subdivisão transparente de fases legadas de $0.80\text{m}$ para $0.40\text{m}$ ao abrir no editor.

9. **`scripts/editor/level_serializer.gd`:**
   - Atualizado `const CELL_SIZE: float = 0.40`.
   - `save_level_json` e `bake_to_tscn` suportam e persistem `cell_size: 0.40`.

10. **`tests/test_editor_enhancements.gd` & `.tscn`:**
    - Suíte com 7 testes cobrindo raio da lâmina, polígono de clareira, elevação vertical anti-flick, rotação canônica de flores, filtragem de clareira de rocha no VegetationGrid, cálculo de corredor costeiro e serialização da grade.

---

## 4. Resultados da Validação

- **Suite Dedicada:** `tests/test_editor_enhancements.tscn` executada e aprovada com **100% de sucesso (7 de 7 testes)**.
- **Suite de Regressão:** `tests/test_save_manager.tscn`, `tests/test_blade_progression.tscn` e `tests/test_editor_goals_and_panel.tscn` aprovadas com **100% de sucesso**.
- **Godot Console:** 0 warnings e 0 erros de script.
