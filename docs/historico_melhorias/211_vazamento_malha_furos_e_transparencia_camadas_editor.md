# Melhoria 211: Vazamento Real de Furos na Malha da Ilha e Transparência de Foco por Camada no Editor 🏝️👁️

## 1. Contexto e Motivação
Dois refinamentos cruciais foram identificados no Editor de Fases:
1. **Furos Vazados na Malha 3D (`IslandMeshBuilder`):** Ao criar lagos ou recortar com a borracha no meio do terreno, `VectorTerrainField` registrava o furo com precisão em `holes`, porém o gerador de malha 3D (`build_island_mesh`) utilizava `Geometry2D.clip_polygons(outer, hole)` sem bissecção, fazendo com que o algoritmo de triangulação simples (`Geometry2D.triangulate_polygon`) preenchesse e cobrisse o furo com triângulos verdes de grama sólida. Como consequência visual, o solo parecia não abrir buraco e apenas a grama vetorial superior era recortada.
2. **Foco Visual por Camada com Transparência de 50%:** Para facilitar a visualização de qual camada está sendo manipulada e evitar confusão entre solo, gramas e objetos, o usuário solicitou que a camada ativa permaneça 100% opaca, enquanto as camadas inativas recebam 50% de transparência.

---

## 2. Implementação Técnica

### A. Subtração e Vazamento Real de Furos na Tampa Superior (`scripts/level/island_mesh_builder.gd`)
- Implementado o método estático `_clip_cap_with_holes(outer, holes)`:
  - Furos internos (`holes`) são subtraídos do polígono perimetral superior via **bissecção ortogonal** (dividindo verticalmente a área de terreno pelo centro do furo).
  - As metades resultantes tornam-se polígonos simples sem furos internos, os quais são perfeitamente triangulados pelo `Geometry2D.triangulate_polygon` sem cobrir nem fechar o lago.
  - O interior do lago torna-se 100% oco, permitindo que a água do oceano seja visível com suas falésias verticais, chanfro e fita de espuma costeira interna.

### B. Transparência Dinâmica de 50% nas Camadas Inativas (`scripts/editor/level_editor.gd`)
- Criado o sistema de foco por camada `_update_layers_transparency()`:
  - Quando **Camada 0 (Terreno/Solo)** está ativa: `island_tiles_container` e `coastal_limits_body` ficam com transparência `0.0` (opaco), enquanto `plants_container` (Grama) e `obstacles_container` (Objetos/Rochas/Flores) recebem `0.5` (50% de transparência).
  - Quando **Camada 1 (Grama)** está ativa: `plants_container` fica opaco (`0.0`), enquanto Terreno e Objetos recebem `0.5`.
  - Quando **Camada 2 (Objetos)** está ativa: `obstacles_container` fica opaco (`0.0`), enquanto Terreno e Grama recebem `0.5`.
- A transparência é propagada recursivamente via `_set_container_transparency` utilizando a propriedade nativa `GeometryInstance3D.transparency` presente nos `MeshInstance3D` e `MultiMeshInstance3D`, preservando os materiais compartilhados.
- Integração reativa automática em `_sync_all_ui()`, no término de `_rebuild_3d_world()` e no reset para `0.0` ao iniciar o Playtest (`_start_playtest`).

---

## 3. Testes Automatizados e Verificação
- Expandido `tests/test_terrain_hole_and_curvature.gd` para 7 testes automatizados:
  - O teste `[6/7]` inspeciona diretamente os triângulos gerados pelo `MeshDataTool` e comprova que o centro $(5, 5)$ de um furo esculpido não é coberto por nenhum triângulo de grama superior.
- Todos os 7 testes executados via Godot CLI Headless com **0 warnings e 0 erros**.

---

## 4. Governança e Versionamento
- Incremento Game SemVer: `v0.12.163-alpha` (code `1363`).
- Atualizados `scripts/core/game_version.gd`, `project.godot` e `export_presets.cfg`.
