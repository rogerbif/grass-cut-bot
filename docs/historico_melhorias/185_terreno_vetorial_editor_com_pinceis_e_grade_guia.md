# Melhoria 185: Terreno Vetorial no Editor de Fases com Pincéis, Borracha e Grade como Guia/Snap (`v0.12.135-alpha`) 🏝️📐

## 1. Contexto e Motivação
Anteriormente, o editor de fases gerenciava o terreno através de uma grade discreta de células (`terrain_grid: Dictionary[Vector2i, TileData]`). O usuário era obrigado a selecionar tiles discretos (`island_center`, `island_edge_n`, etc.) e desenhar em blocos rígidos, o que limitava o design a formatos angulares e amarrava o editor a dimensões fixas de grade.

Por outro lado, o subsistema de vegetação já utilizava desenho vetorial contínuo (`VectorGrassField`), permitindo carimbos, rotações e formas orgânicas processadas via Clipper em C++ (`Geometry2D.merge_polygons` e `clip_polygons`).

Esta melhoria migra o terreno para uma arquitetura **100% vetorial e contínua** através da nova classe `VectorTerrainField`. A edição na Camada 0 passa a utilizar as mesmas ferramentas de pincel (Círculo, Retângulo com Cantos Arredondados, Fita Livre e Carimbos Rápidos), com borracha para recortar terra e criar lagos ou baías. A **grade de células foi libertada do papel de contêiner de dados**, tornando-se um **guia visual métrico** com magnetismo (*Snap*) opcional (0.50m, 1.00m ou Livre), além de atalho `G` para alternar sua visibilidade.

---

## 2. O que foi Implementado

### 2.1. Classe `VectorTerrainField` (`scripts/level/vector_terrain_field.gd`)
- Armazena `outer_polygons: Array[PackedVector2Array]` (contornos externos das ilhas) e `holes: Array[PackedVector2Array]` (furos/lagos internos).
- **Operações Booleanas Clipper em C++:**
  - `add_land(poly)`: união booleana (`merge_polygons`) de terra firme, preenchendo automaticamente furos sobrepostos.
  - `carve_water(poly)`: recorte com borracha (`clip_polygons`), criando baías, canais ou furos de lagos.
  - `is_point_on_land(pt)`: verificação contínua 2D se o ponto está dentro de qualquer ilha e fora de todos os lagos.
  - `convert_from_tile_grid(...)`: conversão retrocompatível de grades de tiles legadas em polígonos contínuos.
  - `to_dict()` e `from_dict()`: serialização em JSON com snap métrico de 3 casas decimais (`0.001m`).

### 2.2. Suporte Completo a Furos e Lagos no `IslandMeshBuilder` (`scripts/level/island_mesh_builder.gd`)
- `build_island_mesh(polygons, holes)`: triangula o topo (com furos recortados) e ergue falésias verticais 3D chanfradas tanto na costa externa quanto nas margens internas dos lagos.
- `build_coastal_colliders(parent_body, polygons, holes)`: gera barreiras físicas invisíveis na Camada 1 para conter o robô tanto nas falésias externas quanto nas margens dos lagos.
- `build_coastal_foam_mesh(polygons, holes)`: projeta a fita contínua de espuma marinha em todo o contorno externo e nos lagos.

### 2.3. Grade como Guia Visual e Magnetismo (Snap) no Editor
- `GridOverlay` (`scripts/editor/grid_overlay.gd`):
  - Métodos `toggle_grid_visibility()`, `set_grid_visible()`, `is_grid_visible()`.
  - Atalho de teclado `G` para ligar/desligar a grade instantaneamente.
- Magnetismo (*Snap to Grid*):
  - Ciclo de modos de snap pelo botão superior ou tecla de atalho: `Snap: 0.50m` ➔ `Snap: 1.00m` ➔ `Snap: Livre`.
  - Suporte ao pressionamento de `Ctrl` para snap magnético temporário durante a pintura.

### 2.4. Unificação de Ferramentas na Interface (`level_editor_ui.gd`)
- Camada 0 renomeada para **"🏝️ Camada 0: Terreno (Vetorial)"**.
- Substituição dos 8 botões de tiles obsoletos por:
  - Botão de ação rápida: `🏝️ Gerar Ilha Base Retangular`.
  - Botão de ação rápida: `🌊 Limpar Terreno (Oceano Aberto)`.
  - Carimbos rápidos de ilha: Círculo, Retângulo Arredondado, Fita/Istmo e Estrela.
  - Dicas visuais dinâmicas no HUD.
- Botões de alternância da Grade e Snap integrados à barra superior com feedback de cor e texto.

### 2.5. Serialização Retrocompatível & Undo/Redo Completo
- `LevelSerializer.save_level_json()` e `bake_to_tscn()` atualizados para gravar `"island_polygons"` e `"island_holes"` (Versão 5).
- Gera automaticamente rasterização de segurança de `terrain` caso ferramentas antigas a consultem.
- `_push_undo_snapshot()` e `_restore_snapshot()` no `LevelEditor` agora empilham o estado de `vector_terrain`, garantindo desfazer/refazer instantâneo para pinceladas e recortes de terreno.

---

## 3. Validação e Testes Automatizados
- Criada a suíte de testes `tests/test_vector_terrain.gd` cobrindo:
  1. Adição básica de terra firme.
  2. Fusão de múltiplos polígonos adjacentes via Clipper.
  3. Recorte de baías e canais com a borracha.
  4. Serialização e desserialização sem perda de dados.
  5. Conversão atômica de fases legadas em polígonos.
  6. Geração da malha 3D, colisão costeira e fita de espuma marinha.
  7. Leitura e integridade com a Fase 01 existente.
- **Resultado dos Testes:** Todos os 7 testes passaram com 100% de êxito no Godot 4.7.2 headless.
- **Zero Warnings:** Inicialização do editor de fases e varredura do projeto com 0 warnings.
