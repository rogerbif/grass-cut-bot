# Melhoria 044: Correção da Orientação Espacial Canônica dos Tiles 3D de Terreno no Godot 4 🧭🌿

**Data:** 19 de Outubro de 2026  
**Versão:** `v0.7.6-alpha`  
**Escopo:** Pipeline 3D Blender -> glTF -> Godot 4, Autotiler de Ilhas e Níveis 3D.

---

## 1. Contexto e Diagnóstico

Após a modelagem e calibração estanque dos tiles modulares de terreno 3D no Blender (`Tile_Cliff_Straight`, `Tile_Cliff_Corner_Outer.002`, `Tile_Cliff_Corner_Inner`, etc.), o usuário reportou que as peças no jogo estavam viradas ("ficaram viradas as peças no jogo verifique e corrija"), apresentando um vão/desfiladeiro côncavo entre o gramado central e as bordas exteriores da ilha:

1. **Eixo de Coordenadas Godot vs Blender glTF:**
   - No Godot 3D, a convenção espacial canônica adotada em `island_autotiler.gd` e nos colisores de barreira (`BarrierNorth` em `tile_island_edge.tscn` a $Z = -0.38\text{m}$) define que para `rot = 0`:
     - **Norte ($-Z$):** Face exterior de falésia (mar/vazio).
     - **Sul ($+Z$):** Face traseira reta e plana de grama (conexão interna).
     - **Leste ($+X$):** Face lateral.
     - **Oeste ($-X$):** Face lateral.
   - Na exportação glTF com `export_yup=True`, o eixo $Y$ do Blender é mapeado para $-Z$ no Godot ($Z_{\text{gltf}} = -Y_{\text{blender}}$).
   - Os modelos anteriormente exportados possuíam a face de falésia voltada para $+Z$ no Godot (Sul), fazendo com que as bordas da ilha ficassem invertidas em 180°, voltadas para dentro do gramado central da ilha em vez de para fora em direção ao mar.

---

## 2. Implementação e Ajustes Executados

### A. Reorientação Canônica dos Modelos no Blender
Utilizando script Python automatizado via MCP no Blender, os pivôs e orientações foram ajustados e exportados com `export_apply=True` e `export_yup=True`:
1. **`tile_island_edge.glb`:** Rotacionado em 180° no eixo Z no Blender para que a face de falésia fique em $-Z$ no Godot (Norte) em `rot = 0`, com a face de grama contínua plana estanque em $+Z = +0.40\text{m}$.
2. **`tile_island_corner_out.glb`:** Rotacionado em 180° no eixo Z no Blender para que a quina convexa exterior aponte para Norte ($-Z$) e Leste ($+X$) em `rot = 0`, com as faces planas traseiras conectando em Sul ($+Z = +0.40\text{m}$) e Oeste ($-X = -0.40\text{m}$).
3. **`tile_island_corner_in.glb`:** Invertido no eixo Y no Blender para que o corte côncavo e a coluna de colisão fiquem alinhados com o quadrante Noroeste ($-X, -Z$).
4. **`tile_island_end.glb`:** Alinhado para que a ponta da península aponte para o Leste ($+X$) com falésias em Norte e Sul, conectando à terra em Oeste ($-X$).
5. **`tile_island_center.glb` e `tile_island_dirt.glb`:** Re-exportados simetricamente em $0.80\text{m} \times 0.80\text{m} \times 0.36\text{m}$.

### B. Regeneração do Cache de Importação do Godot
- Execução do Godot em modo headless (`godot.exe --headless --import`) para forçar a reimportação e compilação dos binários `.scn` em `.godot/imported/` de todos os 6 modelos `.glb` e suas texturas atlas associadas.
- Limpeza dos caches temporários para garantir consistência estrita.

### C. Validação e Inspeção Visual / Mecânica
- Inspeção vetorial programática dos vértices de cada malha dentro do Godot via `MeshDataTool`, confirmando que os limites de AABB e as faces de corte correspondem com exatidão matemática à matriz do `island_autotiler.gd`.
- Captura de frame no runtime da Godot (`capture_level.gd`) comprovando a união 100% contínua e sem frestas ou desfiladeiros na ilha de gameplay, com a falésia externa voltada para o oceano.
- Execução do Godot com **0 warnings e 0 errors**.

---

## 3. Arquivos Envolvidos

- `assets/models/tiles/tile_island_edge.glb`
- `assets/models/tiles/tile_island_corner_out.glb`
- `assets/models/tiles/tile_island_corner_in.glb`
- `assets/models/tiles/tile_island_end.glb`
- `assets/models/tiles/tile_island_center.glb`
- `assets/models/tiles/tile_island_dirt.glb`
- `enviroment.blend`
- `scripts/core/game_version.gd`
- `project.godot`
- `export_presets.cfg`
- `docs/historico_melhorias/044_correcao_orientacao_espacial_tiles_terreno_3d.md`
- `docs/historico_melhorias/INDICE_MELHORIAS.md`
