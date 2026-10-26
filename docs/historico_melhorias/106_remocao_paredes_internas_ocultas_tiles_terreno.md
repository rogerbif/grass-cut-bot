# 106 — Remoção de Paredes Internas e Faces Ocultas dos Tiles de Terreno 3D 🏝️✂️

**Versão:** `v0.12.31-alpha` (código `1231`)  
**Data:** 25/10/2026  

---

## 1. Contexto e Diagnóstico

Os 6 modelos 3D modulares de ilha (`assets/models/tiles/tile_island_*.glb` e `assets/models/terrain_tileset.glb`) possuíam **paredes verticais internas de fechamento ("tampas / end-caps")** nos planos limítrofes da grade ($X = \pm 0.40\text{m}$ e $Z = \pm 0.40\text{m}$) onde um tile conecta diretamente com seu vizinho, além de **faces inferiores submersas** ($Y_{\text{Godot}} = -0.72\text{m}$ / $Z_{\text{Blender}} = -0.36\text{m}$) voltadas para baixo sob o oceano e 2 triângulos colineares degenerados de área zero em `tile_island_end.glb`.

Essas faces nunca aparecem para a câmera isométrica ou de menu e causavam:
1. **Faces Coplanares Internas e Risco de Z-Fighting:** Cada linha de grade interna da ilha possuía duas paredes verticais coplanares sobrepostas, cuja aresta superior em $Y = 0.0\text{m}$ disputava precisão no *Depth Buffer* com a superfície de grama em ângulos rasos.
2. **Custo Desnecessário de Vértices e Triângulos nos `MultiMeshInstance3D`:** Nos blocos internos (`tile_island_center` e `tile_island_dirt`), 10 dos 12 triângulos (83,3%) eram paredes internas e fundo invisível.

---

## 2. Solução Implementada (Pipeline Blender 5.2 -> Godot 4)

1. **Remoção Cirúrgica com Preservação Bit-Exata de Normais Customizadas (`normals_split_custom_set`):**
   - Processamos via script automatizado no **Blender 5.2** os 6 modelos em `assets/models/tiles/` e os 6 objetos correspondentes em `assets/models/terrain_tileset.glb`.
   - Removemos exclusivamente:
     - Faces de fundo submersas ($Z_{\text{Blender}} \le -0.359$, normal $n_z < -0.9$).
     - Paredes e tampas verticais internas nas fronteiras com vizinhos ($X = \pm 0.40\text{m}$ com normal $\pm X$, e $Y_{\text{Blender}} = \pm 0.40\text{m}$ com normal $\pm Y_{\text{Blender}}$).
     - Triângulos degenerados de área zero (`area < 1e-6`).
     - Arestas e vértices órfãos resultantes.
   - Reaplicamos os vetores exatos de `corner_normals`, `UVMap`, `use_smooth` e material `GRADIENT` em todas as faces visíveis preservadas (`max_norm_diff < 5e-7`, `max_uv_diff < 3e-8`).
   - Reexportamos todos os `.glb` com `export_apply=True` e `export_yup=True` (Mandamento #12).

2. **Resultado por Modelo (`assets/models/tiles/`):**
   - `tile_island_center.glb`: **12 $\to$ 2 triângulos** (24 $\to$ 4 vértices, **-83,3%**)
   - `tile_island_dirt.glb`: **12 $\to$ 2 triângulos** (24 $\to$ 4 vértices, **-83,3%**)
   - `tile_island_edge.glb`: **20 $\to$ 8 triângulos** (36 $\to$ 16 vértices, **-60,0%**)
   - `tile_island_corner_out.glb`: **72 $\to$ 56 triângulos** (114 $\to$ 92 vértices, **-22,2%**)
   - `tile_island_corner_in.glb`: **56 $\to$ 44 triângulos** (92 $\to$ 72 vértices, **-21,4%**)
   - `tile_island_end.glb`: **84 $\to$ 71 triângulos** (128 $\to$ 114 vértices, **-15,5%**)

3. **Reimportação Atômica e Validação Headless:**
   - Cache `.godot/imported/tile_island_*.glb*` e `terrain_tileset.glb*` limpo e regenerado via `godot --headless --path . --import`.
   - Contagem de triângulos verificada via GDScript nas cenas `scenes/editor/tiles/*.tscn` com 100% de precisão e `0 warnings`.
