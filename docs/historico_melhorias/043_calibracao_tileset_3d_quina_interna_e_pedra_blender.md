# Melhoria 043: Calibração dos Tiles 3D de Terreno (Encaixe Estanque 0.000000m), Quina Interna, Ponta de Península e Rocha 3D Oficial [v0.7.5-alpha] 🏝️🪨📐

## 1. Contexto e Motivação
O usuário solicitou uma revisão aprofundada dos componentes de tiles 3D de terreno com base no ajuste realizado no Blender (`Tile_Cliff_Corner_Outer.002` e `Tile_Cliff_Straight`), eliminando frestas/costuras (*seams*) entre peças adjacentes, criando as variações necessárias com foco nos tiles de grama (especialmente quina interna côncava e pontas de caminhos 1x1) e substituindo as rochas primitivas `BoxMesh` do jogo pelo modelo 3D oficial do Blender (`Prop_Rock`), preservando o material cinza ardósia canônico.

---

## 2. Modificações Realizadas

### A. Diagnóstico Geométrico e Eliminação de Frestas (Tolerância Zero)
- **Causa das Frestas Anotadas pelo Usuário:**
  - O modelo original `Tile_Cliff_Corner_Outer` possuía a face traseira em $Y = 0.9843\text{m}$ (em vez de $1.0000\text{m}$), gerando uma descontinuidade de $1.57\text{cm}$ ao conectar com o piso de grama (`Tile_Ground_Grass`).
  - Assimetria entre a face conectora $X = 1.0\text{m}$ e a face conectora $Y = 1.0\text{m}$ gerava desalinhamento de $3.2\text{cm}$ de espuma e falésia ao girar peças $90^\circ$ ou conectá-las em pontas duplas.
- **Calibração Matemática no Blender (`enviroment.blend`):**
  - Ajustado `Tile_Cliff_Corner_Outer` com base em `Tile_Cliff_Corner_Outer.002`, forçando simetria diagonal estrita ($X = Y$).
  - Nivelamento da espuma em $Z = 0.0200\text{m}$ idêntica a `Tile_Cliff_Straight`.
  - Encaixe com `Tile_Cliff_Straight` e `Tile_Ground_Grass` validado com **distância máxima de fresta de $0.000000\text{m}$**.

### B. Novas Variações Modulares de Terreno
- **Quina Interna Côncava (`Tile_Cliff_Corner_Inner` / `tile_island_corner_in.glb`):**
  - Arco côncavo suave com raio $R = 0.50\text{m}$ (no grid 2m do Blender) e $R = 0.20\text{m}$ (no grid 0.80m do jogo) ligando duas falésias ortogonais.
  - Elimina cantos pontudos que invadiam o mar em curvas em "L" e reentrâncias.
- **Ponta de Península (`Tile_Cliff_End` / `tile_island_end.glb`):**
  - Extremidade arredondada para caminhos e promontórios de 1 tile ($0.80\text{m}$), com falésia e espuma em 3 lados e transição suave para a terra.
- **Sombreamento Otimizado:**
  - Superfícies superiores de grama configuradas estritamente com sombreamento plano (*flat normals* $\vec{n} = (0, 0, 1)$), eliminando sombras diagonais ou vincos artificiais, mantendo *smooth shading* exclusivamente no lábio cilíndrico de grama.

### C. Integração da Rocha 3D Oficial do Blender no Jogo (`rock.tscn`)
- Exportado o modelo facetado low-poly `Prop_Rock` do Blender para [`assets/models/rock.glb`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/assets/models/rock.glb) com `export_apply=True` e `export_yup=True`.
- Atualizada a cena [`scenes/obstacles/rock.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/obstacles/rock.tscn):
  - Removidos os dois blocos provisórios `BoxMesh` (`BaseRock` e `TopRock`).
  - Instanciado o modelo 3D `rock.glb` mantendo o material oficial do jogo `StandardMaterial3D` (`Color(0.42, 0.46, 0.5)` e `roughness = 0.95`).
  - Diâmetro de $0.70\text{m}$ perfeitamente contido no colisor físico `CylinderShape3D(radius = 0.36m, height = 0.8m)`.

### D. Exportação glTF e Suporte no Engine
- Reexportados todos os modelos em escala $0.80\text{m} \times 0.80\text{m} \times 0.36\text{m}$ para `assets/models/tiles/`:
  - `tile_island_center.glb`, `tile_island_dirt.glb`, `tile_island_edge.glb`, `tile_island_corner_out.glb`, `tile_island_corner_in.glb` e `tile_island_end.glb`.
- Reexportado o catálogo mestre [`assets/models/terrain_tileset.glb`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/assets/models/terrain_tileset.glb).
- Atualizadas as cenas de colisão física e barreiras invisíveis `scenes/editor/tiles/`.
- Atualizado o algoritmo `island_autotiler.gd` e `generate_levels.js` com detecção de quinas internas e pontas de península.

---

## 3. Validação e Qualidade
- **Verificação no Godot MCP:**
  - `res://scenes/main.tscn`: **0 Erros, 0 Warnings**.
  - `res://scenes/editor/level_editor.tscn`: **0 Erros, 0 Warnings**.
- **Inspeção Visual no Blender:**
  - `Ilha_Demonstracao` renderizada em ângulo superior: superfícies perfeitamente contínuas, transição côncava sem degraus e zero frestas visíveis.
