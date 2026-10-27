# Melhoria 120: Arredondamento Padrão dos Cantos das 20 Fases Canônicas ($R = 0.28\text{m}$) 🏝️📐

**Versão:** `v0.12.44-alpha`  
**Data:** 27/10/2026

---

## 1. Contexto e Motivação

O usuário solicitou: *"atualize as fases para que tenham os cantos padrões"*.

Na arquitetura anterior de migração para o sistema procedural de ilhas por polígono extrudado (`IslandMeshBuilder`), os polígonos perimetrais dos níveis 01 a 20 (`data/levels/level_*.json`) foram gerados a partir da união discreta de quadrados da grade, resultando em quinas vivas de 90° nos vértices externos. No sistema clássico de tiles (`tile_island_corner_out.glb`), os cantos externos sempre possuíam raio de curvatura canônico de $R = 0.28\text{m}$.

Para devolver a identidade visual acolhedora, orgânica e fluida das ilhas flutuantes, foi desenvolvido e integrado um algoritmo analítico de arredondamento de cantos convexos (`round_polygon_corners()`) e todas as 20 fases canônicas foram migradas com sucesso para polígonos de contorno suave com $R = 0.28\text{m}$.

---

## 2. Solução e Implementação Técnica

### 2.1. Algoritmo Analítico de Arredondamento (`IslandMeshBuilder.round_polygon_corners`)
- Localizado em `scripts/level/island_mesh_builder.gd`:
  - **Constantes Padrão:** `DEFAULT_CORNER_RADIUS = 0.28` e `DEFAULT_CORNER_ARC_STEPS = 5`.
  - **Normalização de Orientação:** Garante que o polígono esteja no sentido horário (`Geometry2D.is_polygon_clockwise`).
  - **Classificação de Vértices:** Calcula o produto vetorial 2D ($cross = d_{in}.x \cdot d_{out}.y - d_{in}.y \cdot d_{out}.x$) entre as arestas adjacentes:
    - Cantos convexos (voltados para fora da ilha, rumo ao oceano): $cross < -0.01$.
    - Arestas retas ou reentrâncias côncavas: $cross \ge -0.01$ (são preservados intactos para não criar auto-interseções com o solo interior).
  - **Tangência e Arcos de Círculo:**
    - Distância de tangência segura limitada a 45% do menor segmento adjacente ($d_{tan} = \min(R, \min(L_{in}, L_{out}) \times 0.45)$), impedindo que arcos vizinhos colidam.
    - Geração de 5 segmentos circulares interpolados suavemente ao redor do centro do arco.
  - **Preservação de Orientação:** Reverte ao sentido original caso o polígono de entrada tenha sido fornecido em sentido anti-horário.

### 2.2. Integração no Conversor de Níveis (`convert_tile_grid_to_polygons` e Ferramenta)
- `IslandMeshBuilder.convert_tile_grid_to_polygons()` passa a aceitar opcionalmente `corner_radius: float = DEFAULT_CORNER_RADIUS` e `arc_steps: int = DEFAULT_CORNER_ARC_STEPS`, aplicando o arredondamento automaticamente ao final da fusão booleana Clipper.
- Execução do script `scripts/tools/convert_levels_to_vector_island.gd` sobre os 20 arquivos de fases em `data/levels/level_01.json` até `level_20.json`, regenerando todos os polígonos `"island_polygons"` com as curvaturas canônicas.

---

## 3. Resultados das 20 Fases Atualizadas

| Fase | Topologia da Ilha | Contorno Anterior (Quinas Retas) | Contorno Atual (Suave $R=0.28\text{m}$) |
| :---: | :--- | :---: | :---: |
| **01** | Retângulo Simples | 4 vértices | 24 vértices |
| **02** | Ilha em L | 16 vértices | 80 vértices |
| **03** | Retângulo Simples | 4 vértices | 24 vértices |
| **04** | Cruz Simétrica | 16 vértices | 80 vértices |
| **05** | Retângulo com Reentrâncias | 16 vértices | 80 vértices |
| **06** | Retângulo Simples | 4 vértices | 24 vértices |
| **07** | Arquipélago com Baías | 22 vértices | 108 vértices |
| **08** | Trapézio Angulado | 8 vértices | 38 vértices |
| **09** | Ferradura / U | 16 vértices | 80 vértices |
| **10** | Retângulo Estendido | 4 vértices | 24 vértices |
| **11** | Labirinto com Quinas | 10 vértices | 52 vértices |
| **12** | Formato H | 22 vértices | 108 vértices |
| **13** | Diamante Chanfrado | 16 vértices | 80 vértices |
| **14** | Retângulo com Ilhotas | 4 vértices | 24 vértices |
| **15** | Estrela de 4 Pontas | 16 vértices | 80 vértices |
| **16** | Cruz Dupla | 28 vértices | 136 vértices |
| **17** | Corredor Curvo | 10 vértices | 52 vértices |
| **18** | Trevo de 4 Folhas | 52 vértices | 248 vértices |
| **19** | Complexo Sinuoso | 28 vértices | 136 vértices |
| **20** | Grande Arquipélago Mestre | 16 vértices | 80 vértices |

---

## 4. Validação e Qualidade Técnica

1. **Triangulação e Malha Estanque:**
   - 100% das 20 fases triangulam com sucesso via `Geometry2D.triangulate_polygon`, sem triângulos invertidos ou degenerados.
   - Suíte de testes `tests/test_island_mesh_builder.gd` validou 20 polígonos e 1558 vértices com malha do platô, chanfro de borda, falésias verticais, fita de espuma e colisores sem erros.
2. **Auditoria de Vegetação e Metas:**
   - `scripts/tools/verify_levels.gd` carregou as 20 fases e confirmou que todos os tufos físicos foram instanciados dentro dos contornos arredondados, com metas de vegetação correspondentes.
3. **Zero Warnings Estrito:**
   - Console da Godot 4.7.1 headless com 0 warnings e 0 erros durante a geração e execução.
