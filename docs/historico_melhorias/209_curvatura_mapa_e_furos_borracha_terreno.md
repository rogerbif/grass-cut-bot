# Melhoria 209: Curvatura Angular do Mapa e Furos Internos na Borracha de Terreno 🏝️📐

## 1. Contexto e Motivação
Durante o uso do Editor de Fases em Modo Vetorial Contínuo, dois comportamentos necessitavam de refinamento arquitetural:
1. **Pincel Quadrado Reto e Curvatura do Mapa:** Anteriormente, o controle de quina arredondada aplicava-se diretamente à geometria do pincel quadrado durante a pintura. O design correto exigido é que o carimbo quadrado (`ShapeType.SQUARE`) seja sempre retilíneo e pontiagudo (4 vértices puros), enquanto o parâmetro de curvatura (`corner_radius`) deve ser uma propriedade global do mapa/terreno, permitindo suavizar dinamicamente os cantos angulares (como quinas de 90°) da ilha sem distorcer vértices já curvos.
2. **Furos Internos com a Ferramenta Borracha (Deletar):** Ao esculpir um plano de terreno, o uso da borracha (`carve_water`) no interior da massa de terra não criava furos/lagos internos, pois o algoritmo anterior invertia a orientação dos recortes para horário e os reduzia de volta à terra externa (`outer_polygons`), neutralizando o furo.

---

## 2. Implementação Técnica

### A. Pincel Quadrado 100% Reto (`scripts/editor/brush_patterns.gd`)
- `get_vector_stamp_polygon`: A primitiva `ShapeType.SQUARE` agora gera sempre 4 vértices ortogonais estritos ($(-r, -r)$ a $(+r, +r)$) rotacionados pelo ângulo ativo, ignorando `corner_radius` no carimbo.

### B. Gestão de Polígonos Base e Derivados com Curvatura Idempotente (`scripts/level/vector_terrain_field.gd` & `scripts/level/island_mesh_builder.gd`)
- `VectorTerrainField` agora mantém:
  - `base_outer_polygons` e `base_holes`: geometria base poligonal sem arredondamento.
  - `outer_polygons` e `holes`: malha derivada gerada por `_update_derived_polygons()`.
- Se `corner_radius <= 0.001`, as listas derivadas são cópias idênticas da base.
- Se `corner_radius > 0.001`, aplica `IslandMeshBuilder.round_polygon_corners(..., corner_radius, 5, 0.75)`. O parâmetro `max_dot = 0.75` garante que apenas esquinas angulares (≤ 138°) sejam arredondadas, preservando facetas de arcos já suaves sem inflar ou degradar a geometria.
- Persistência atualizada em `to_dict()` e `from_dict()` salvando `"corner_radius"`, `"island_polygons"` e `"island_holes"`.

### C. Recorte e Gestão Robusta de Furos Internos (`VectorTerrainField.carve_water`)
- Ao recortar com a borracha, se houver sobreposição com furos existentes, eles são unidos preventivamente com o carimbo (`Geometry2D.merge_polygons`).
- `Geometry2D.clip_polygons` separa automaticamente terra perimetral e furos: qualquer sub-polígono cujos vértices estejam inteiramente contidos dentro de outro sub-polígono é identificado como furo interno (`holes`).
- Furos são mantidos com orientação anti-horária (`is_polygon_clockwise = false`), compatível com o Clipper e o `IslandMeshBuilder`.
- Validação contínua com `_is_hole_inside_any_outer`: se um furo for expandido até atingir a margem externa da ilha (abrindo um canal para o mar), ele é automaticamente absorvido pelo oceano aberto, transformando-se em baía externa sem deixar furos fantasmas.

### D. Interface e Sincronização do Editor (`scripts/editor/level_editor_ui.gd` & `level_editor.gd`)
- Rótulo renomeado para `"📐 Curvatura do Mapa:"` no painel lateral esquerdo.
- Visibilidade reconfigurada para permanecer ativo sempre que a camada `TERRAIN` (camada 0) estiver selecionada, independentemente do formato do pincel.
- Adicionado `set_corner_radius(r)` e conexão de sinal que executa `vector_terrain.call("set_corner_radius", r)` e `_rebuild_3d_world()` em tempo real.
- Sincronização automática na carga de fase (`_load_level`) e restauração de snapshots (Undo/Redo).

---

## 3. Testes Automatizados e Verificação
- Desenvolvido `tests/test_terrain_hole_and_curvature.gd` cobrindo 5 suítes:
  1. Verificação do carimbo quadrado com 4 vértices estritos.
  2. Curvatura angular dinâmica e idempotência de vértices.
  3. Criação e expansão/fusão de furos internos no meio do terreno.
  4. Abertura de canal conectando furo ao mar e conversão para baía.
  5. Serialização e desserialização (`to_dict` / `from_dict`) com preservação da curvatura e furos.
- Todos os testes headless executados com 0 warnings e 0 erros.

---

## 4. Governança e Versionamento
- Incremento Game SemVer: `v0.12.160-alpha` (code `1360`).
- Atualizados `scripts/core/game_version.gd`, `project.godot` e `export_presets.cfg`.
