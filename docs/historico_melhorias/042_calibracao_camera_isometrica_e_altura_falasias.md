# Melhoria 042: Calibração da Câmera Isométrica (Pitch 40°), Altura de Falésias e Remoção de Sobreposição de Grama [v0.7.5-alpha] 🎥🏝️🌿

## 1. Contexto e Motivação
A análise visual do jogo em comparação com a referência artística 3D revelou três desvios críticos:
1. **Ângulo da Câmera muito Íngreme (Zenital):** A câmera de gameplay operava com inclinação zenital excessiva de $55.7^\circ$ (`offset = Vector3(0, 11, 7.5)`), o que achata a perspectiva vertical das ilhas e transforma as falésias em uma faixa marrom quase imperceptível.
2. **Sobreposição Artificial de Borda Gramada (`lip_mesh_inst`):** No carregamento dos níveis (`LevelJsonLoader.gd`), eram instanciadas caixas verdes (`BoxMesh`) com material `lip_mat` sobre a borda dos tiles. Essa camada artificial criava quinas retangulares sobrepostas às quinas arredondadas dos modelos 3D, z-fighting na grama e cobria a porção superior da terra marrom.
3. **Altura Reduzida das Paredes de Falésia:** Os tiles modulares exportados possuíam altura de $0.36\text{m}$, menos da metade da proporção 1:1 ($2\text{m} \times 2\text{m}$) presente no modelo do Blender, enquanto o plano de água em $Y = -0.34\text{m}$ afogava a faixa de espuma natural da malha.

---

## 2. Modificações Realizadas

### A. Calibração Angular da Câmera Isométrica
- **Câmera de Gameplay (`scripts/camera/isometric_camera.gd` & `scenes/main.tscn`):**
  - Offset ajustado de `Vector3(0.0, 11.0, 7.5)` ($55.7^\circ$) para **`Vector3(0.0, 7.2, 8.5)`** ($\approx 40.2^\circ$).
  - Transform inicial recalculado para rotação em $X$ de $40.26^\circ$ (`Transform3D(1, 0, 0, 0, 0.763076, 0.64631, 0, -0.64631, 0.763076, 0, 7.2, 8.5)`).
  - Enquadramento cinematográfico idêntico à referência 3D, com visão frontal clara dos relevos e falésias sem perda de visibilidade da área de corte em orientação portrait (9:16).
- **Câmera do Editor de Fases (`scripts/editor/editor_camera.gd`):**
  - `play_offset` sincronizado para `Vector3(0.0, 7.2, 8.5)` durante playtest.
  - Inclinação padrão de perspectiva 3D calibrada de $56.0^\circ$ para $42.0^\circ$.

### B. Remoção de Sobreposições Procedurais e Correção de Topologia
- **Carregador de Fases (`scripts/level/level_json_loader.gd`):**
  - Removida a geração procedural de caixas de acabamento gramado (`lip_mesh_inst`) e espumas artificiais (`foam_mesh_inst`).
  - As malhas 3D modulares (`tile_island_edge.glb` e `tile_island_corner_out.glb`) já possuem acabamento de quina cilíndrica arredondada ($R = 0.28\text{m}$), lábio beveled de grama e espuma contínua modelados e texturizados na paleta atlas `GRADIENT`.
  - Preservados estritamente os colisores físicos invisíveis de costa na camada 1 (`Layer 1: Ground & Limits`).

### C. Escalonamento Vertical das Falésias e Nível do Oceano
- **Cenas de Tiles Modulares (`scenes/editor/tiles/`):**
  - `tile_island_edge.tscn`, `tile_island_corner_out.tscn`, `tile_island_center.tscn` e `tile_island_dirt.tscn`:
    - Adicionado escalonamento no eixo $Y$ da malha (`Transform3D(1, 0, 0, 0, 2, 0, 0, 0, 1, 0, 0, 0)`), elevando a altura de $0.36\text{m}$ para $0.72\text{m}$ (proporcional aos $0.80\text{m}$ de largura).
    - Piso superior preservado exatamente em $Y = 0.0\text{m}$ (pivô superior).
    - Colisores de piso e barreiras atualizados para cobrir a profundidade completa ($0.72\text{m}$).
- **Nível do Oceano (`scenes/level/water_ocean.tscn` e `scenes/level/terrain.tscn`):**
  - `SurfaceWater` reposicionado de $Y = -0.34\text{m}$ para **$Y = -0.71\text{m}$**, alinhando o plano de água perfeitamente com a faixa de espuma da base da malha 3D.
  - `DeepWater` reposicionado para $Y = -1.10\text{m}$.

---

## 3. Verificação e Resultados
- **Execução via Godot MCP:**
  - `res://scenes/main.tscn`: **0 Erros, 0 Warnings** (Conformidade com Guardrail 1).
- **Inspeção Visual (Screenshot de Gameplay):**
  - Falésias de terra marrom ricas, profundas e com volume vertical expressivo.
  - Gramado superior sem qualquer camada de corte quadrada ou artefatos de z-fighting.
  - Quinas externas perfeitamente arredondadas com espuma curva suave ao redor da costa.
