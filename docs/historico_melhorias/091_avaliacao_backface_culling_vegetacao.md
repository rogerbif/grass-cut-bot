# 091 - Otimização de Performance: Avaliação e Ativação de Backface Culling nas Aparas de Solo e Shaders (Tarefa 2.2) 🌿📐

## 1. Contexto e Diagnóstico
A rasterização de faces traseiras (*backfaces*) em GPUs móveis consome fill-rate e ciclos de shading desnecessários quando polígonos possuem faces orientadas em sentido oposto à visão da câmera.
Na **Tarefa 2.2**, realizamos uma auditoria geométrica completa das malhas de vegetação e aparas fatiadas no chão para avaliar a aplicabilidade de `cull_back`:

- **Aparas de Grama no Chão (`vegetation_grid.gd`):**
  - Milhares de instâncias no `MultiMeshInstance3D` caídas no solo a $Y = 0.005\text{m}$.
  - A malha gerada programaticamente via `SurfaceTool` possui normais estritamente apontando para cima (`Vector3.UP`) e ordem dos vértices anti-horária (Counter-Clockwise - CCW) quando vista do topo.
  - Como a câmera isométrica filma de cima para baixo (inclinações de $-40^\circ$ e $-58^\circ$), a face inferior das aparas está encostada na terra e nunca é visível.
  - **Gargalo Anterior:** O material utilizava `mat.cull_mode = BaseMaterial3D.CULL_DISABLED`, forçando a GPU a rasterizar a face de baixo oculta.
- **Tufo de Grama Viva (`grass_01.glb` & `interactive_grass.gdshader`):**
  - A malha canônica restaurada (Melhoria 084) possui 39 lâminas e 105 triângulos (~2.7 triângulos por folha).
  - Trata-se de uma malha plana de face única (*single-sided*).
  - Forçar `cull_back` na grama viva faria a GPU descartar cerca de 50% das lâminas de cada tufo (aquelas orientadas de costas para a câmera), gerando buracos graves no gramado e cintilação (*flickering*) com o balanço do vento.

---

## 2. Soluções Implementadas

### A. Ativação de `cull_back` nas Aparas Caídas no Solo
Em [`scripts/plants/vegetation_grid.gd`](../../scripts/plants/vegetation_grid.gd):
- O material das aparas caídas no solo foi reconfigurado de `CULL_DISABLED` para `CULL_BACK`:
  ```gdscript
  var leaf_color: Color = _resolve_clipping_color(v_type)
  var mat := StandardMaterial3D.new()
  mat.albedo_color = leaf_color
  mat.roughness = 0.90
  mat.cull_mode = BaseMaterial3D.CULL_BACK
  st.set_material(mat)
  ```
- **Ganho:** Descarte imediato de 50% dos testes e rasterização de fragmentos de todas as aparas no solo.

### B. Preservação Canônica e Calibração da Grama Viva
Em [`shaders/interactive_grass.gdshader`](../../shaders/interactive_grass.gdshader):
- Preservada a diretiva `cull_disabled` com documentação canônica de salvaguarda de volume foliar e adição explícita de `diffuse_toon`:
  ```glsl
  shader_type spatial;
  // cull_disabled é essencial para preservar o volume foliar das 39 lâminas de face única (grass_01.glb)
  // sem falhas de transparência e sem flickering ao balançar no vento.
  render_mode cull_disabled, diffuse_toon;
  ```

---

## 3. Preservação do Game Feel e Resultados
- **Estética 100% Preservada:** A grama viva e o trigo mantêm sua envergadura de 1.10m, fechamento de solo farto e balanço orgânico sob o vento sem perda de folhas ou cintilações.
- **Alívio de GPU:** As aparas caídas no chão deixam de renderizar a face inferior em direção ao centro da Terra.
- **Zero Warnings:** Total conformidade com as diretrizes e tipagem GDScript 4.

---

## 4. Arquivos Modificados
- [`scripts/plants/vegetation_grid.gd`](../../scripts/plants/vegetation_grid.gd): `cull_mode = BaseMaterial3D.CULL_BACK` em `_get_or_create_clippings_mesh`.
- [`shaders/interactive_grass.gdshader`](../../shaders/interactive_grass.gdshader): Documentação e calibração de `render_mode`.
- [`scripts/core/game_version.gd`](../../scripts/core/game_version.gd): Incremento para `v0.12.15-alpha`.
- [`project.godot`](../../project.godot) & [`export_presets.cfg`](../../export_presets.cfg): Bump SemVer (build `1215`).
- [`docs/05_arquitetura_e_desenvolvimento/PLANO_MESTRE_DE_PERFORMANCE.md`](../05_arquitetura_e_desenvolvimento/PLANO_MESTRE_DE_PERFORMANCE.md): Tarefa 2.2 marcada como concluída.
- [`docs/historico_melhorias/INDICE_MELHORIAS.md`](INDICE_MELHORIAS.md): Indexação do item 091.
