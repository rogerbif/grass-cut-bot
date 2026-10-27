# Melhoria 117: Terreno Procedural de Ilhas por Polígono Vetorial Extrudado (Substituição de Tiles) 🏝️🌿📐

**Versão:** `v0.12.41-alpha`  
**Data:** 27/10/2026

---

## 1. Contexto e Motivação

Anteriormente, o terreno de cada fase era composto por dezenas de blocos modulares individuais instanciados (`tile_island_center.glb`, `tile_island_edge.glb`, `tile_island_corner_*.glb`), organizados em `MultiMeshInstance3D` ou nós avulsos. Embora funcionais, essa abordagem apresentava desvantagens arquiteturais:
1. **Frestas e Coplanaridade:** Risco residual de linhas de costura ou frestas microscópicas entre tiles adjacentes sob iluminação rasante.
2. **Multiplicidade de Draw Calls e Nós:** Cada tipo de tile exigia seu próprio nó de renderização e cálculo de transformações por instância.
3. **Restrição Topográfica:** O cenário ficava rigidamente amarrado a blocos quadrados de $0.80\text{m}$, dificultando curvas orgânicas ou formatos livres.
4. **Desconexão de Paradigma:** Enquanto a vegetação já utilizava desenho vetorial contínuo (`VectorGrassField`), o terreno ainda dependia de matrizes rígidas de blocos.

A solução adotada foi a implementação da **Abordagem 1: Ilha 3D Procedural por Polígono Vetorial Extrudado (*Procedural Polygon Extruded Island*)**.

---

## 2. Arquitetura e Alterações Implementadas

### 2.1. Novo Gerador Procedural: `IslandMeshBuilder` (`scripts/level/island_mesh_builder.gd`)
Biblioteca utilitária com métodos estáticos puros para geração atômica de malhas, espumas e colisões:
- **`build_island_mesh(polygons, holes)`:**
  - **Teto Superior Planalto ($Y = 0.0\text{m}$):** Triangulação plana com `Geometry2D.triangulate_polygon`, normais $(0, 1, 0)$ e UVs ortogonais no atlas `tile_island_center_Image_0.png` (`UV_GRASS_TOP = Vector2(0.82, 0.79)`).
  - **Chanfro Superior Low Poly ($Y = 0.0$ a $-0.06\text{m}$):** Lábio sutil rebaixado com avanço perimetral de $0.015\text{m}$ e normais inclinadas a $45^\circ$, simulando o chanfro suave do modelo original sem quinas cortantes de $90^\circ$.
  - **Falésias Verticais ($Y = -0.06\text{m}$ a $-0.72\text{m}$):** Quad strip perimetral com normais horizontais externas e mapeamento UV da rocha/terra do atlas (`UV_CLIFF_WALL = Vector2(0.19, 0.17)`).
  - **Malha Única em 1 Draw Call:** Todas as superfícies são consolidadas em 1 único commit de `SurfaceTool`, com acabamento fosco (`roughness = 0.92`, `specular_mode = DISABLED`).
- **`build_coastal_foam_mesh(polygons, foam_y = -0.692)`:**
  - Gera fita contínua de espuma costeira com normais radiais suaves ($C^1$), animada pelo shader `shaders/coastal_foam.gdshader` em duas faixas toon minimalistas.
- **`build_coastal_colliders(parent_body, polygons)`:**
  - Gera barreiras físicas verticais invisíveis na Camada 1 (`Layer 1: Ground & Limits`) de altura $1.2\text{m}$ ao longo de cada aresta do contorno perimetral, garantindo contenção física estanque sem necessidade de cercas.
- **`convert_tile_grid_to_polygons(terrain_list, width, height, cell_size = 0.80)`:**
  - Algoritmo de conversão retrocompatível que transforma listas de células em polígonos externos fechados através de sucessivas uniões booleanas (`Geometry2D.merge_polygons`).

### 2.2. Integração no Gameplay (`VegetationGrid` & `LevelJsonLoader`)
- **`vegetation_grid.gd`:**
  - Substituída a instanciação de dezenas de `TileMMI_island_*` por um único nó `MeshInstance3D` nomeado `IslandMesh`.
  - Integração da fita de espuma e dos colisores costeiros em `CoastalLimits`.
  - O sistema de decalque de corte de gramado (`_lawn_decal_mesh`) continua operando normalmente a $Y = 0.005\text{m}$ sobre a superfície unificada da ilha.
- **`level_json_loader.gd`:**
  - Adicionado método `get_island_polygons(data)` com suporte ao formato v4 (`island_polygons`) e fallback transparente para matrizes legadas (`terrain`).

### 2.3. Miniaturas 3D do Menu Principal (`IslandNode`)
- Substituída a criação de múltiplos `MiniTileMMI_*` por uma miniatura 3D unificada gerada por `IslandMeshBuilder.build_island_mesh()`.
- Otimização substancial de carregamento no mapa mundi de seleção de fases, com visual limpo e sem costuras.

### 2.4. Integração no Editor de Fases (`LevelEditor` & `LevelSerializer`)
- **`level_editor.gd`:**
  - A renderização do terreno na cena do editor agora gera a malha extrudada e a espuma contínua em tempo real na árvore de nós, espelhando com precisão absoluta o visual in-game.
- **`level_serializer.gd`:**
  - Gravação automática do campo `"island_polygons"` no JSON v4 de cada fase, preservando o campo `"terrain"` para total retrocompatibilidade.

### 2.5. Migração Canônica dos 20 Níveis do Jogo (`convert_levels_to_vector_island.gd`)
- Criado script de migração que converteu todos os 20 níveis (`level_01.json` a `level_20.json`) para o formato JSON v4 com polígonos fechados otimizados (totalizando 20 polígonos e 388 vértices perimetrais).

---

## 3. Verificação e Testes

- **Suíte de Testes Dedicada (`tests/test_island_mesh_builder.gd`):**
  - Validação de polígono quadrado básico: 100% aprovado (1 superfície).
  - Validação de ilha com furo interno (lago/reentrância): 100% aprovado.
  - Validação de fita contínua de espuma costeira: 100% aprovado.
  - Validação de colisores da Camada 1: 100% aprovado (4 barreiras perimetrais).
  - Validação em lote dos 20 níveis do jogo: 100% aprovado com malhas, espumas e colisores gerados sem erros.
- **Auditoria de Fases (`scripts/tools/verify_levels.gd`):**
  - Todos os 20 níveis carregados e verificados com 0 warnings e 0 erros.
- **SemVer:** Incrementado para `v0.12.41-alpha` (código 1241).
