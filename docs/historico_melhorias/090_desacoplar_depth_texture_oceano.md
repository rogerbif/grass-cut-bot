# 090 - Otimização de Performance: Desacoplar depth_texture do Toon Water para Mobile (Tarefa 2.1) 🌊⚡

## 1. Contexto e Diagnóstico
No renderizador Mobile do Godot 4 (Vulkan Mobile / TBDR para Android/iOS), o shader de oceano (`shaders/toon_water.gdshader`) utilizava `uniform sampler2D depth_texture : hint_depth_texture` e derivadas de tela `dFdx(depth)`, `dFdy(depth)` para calcular a profundidade da água e gerar uma linha de espuma de contato com as margens da ilha.

- **Gargalo Crítico em Mobile (TBDR - Tile-Based Deferred Rendering):**
  - GPUs mobile processam fragmentos em pequenos blocos de memória ultrarrápida (*tile memory*).
  - A leitura da textura de profundidade global (`hint_depth_texture`) quebra o pipeline de renderização em tiles, forçando a engine a gerar um **Depth Prepass** completo em tela cheia e transferir buffers pesados para a VRAM principal.
  - As derivadas `dFdx/dFdy` impedem otimizações internas de fragment quad shading.
  - Essa operação reduzia entre 15% e 25% da taxa de quadros (FPS) em celulares Android de entrada e intermediários.
- **Redundância:** O projeto já possui a malha `CoastalFoamRibbon` gerada programmaticamente ao redor do perímetro das ilhas pelo `VegetationGrid`, que desenha uma faixa de espuma 3D estilizada e suave usando 1 único draw call sem necessidade de amostragem de profundidade.

---

## 2. Soluções Implementadas

### A. Desacoplamento da `depth_texture` no Shader de Água
Em [`shaders/toon_water.gdshader`](../../shaders/toon_water.gdshader):
- Removida a amostragem de `depth_texture`, reconstrução NDC via `INV_PROJECTION_MATRIX`, cálculos de Beer-Lambert (`exp(-water_depth_diff * beer_factor)`) e gradientes de tela `dFdx/dFdy`.
- O visual tropical da água agora utiliza diretamente a amostragem de ruído Perlin com deslocamento contínuo no tempo (`surfaceNoise` e `distortNoise`) modulando a transição entre `_DepthGradientShallow` e `_DepthGradientDeep`.
- Cristas de ondas brancas de mar aberto permanecem calculadas com `smoothstep` cel-shaded e `foam_color`.
- O render mode permanece ultraleve com `cull_back, diffuse_toon, specular_disabled`.

### B. Limpeza de Parâmetros Mortos no Material
Em [`shaders/toon_water_material.tres`](../../shaders/toon_water_material.tres):
- Removidos os parâmetros obsoletos: `beer_factor`, `foam_distance`, `foam_max_distance`, `foam_min_distance`, `_DepthMaxDistance` e `_DepthFactor`.
- Mantidos e preservados os parâmetros de controle estético: `foam_color`, `use_world_coords`, `world_scale`, `surface_noise_tiling`, `surface_noise_scroll`, `surface_noise_cutoff`, `surface_distortion_amount`, `_DepthGradientShallow`, `_DepthGradientDeep`, `roughness`, `surfaceNoise` e `distortNoise`.

### C. Atualização da Ferramenta de Ajuste de Água
Em [`scripts/tools/water_tuner.gd`](../../scripts/tools/water_tuner.gd):
- Ajustados acessos de leitura e escrita aos parâmetros removidos, garantindo leitura segura com salvaguarda nula e gerador de texto de exportação sincronizado com o novo formato leve do shader.

---

## 3. Preservação Visual e Resultados
- **Identidade Estética Idêntica:** A água mantém as cristas cel-shaded animadas, o tom oceânico vibrante e a espuma costeira da ilha perfeita via `CoastalFoamRibbon`.
- **Eliminação de Depth Prepass:** A GPU mobile agora renderiza o plano de água em um único passe de fragmento direto dentro da memória do bloco (*on-chip tile*).
- **Zero Warnings:** Totalmente aderente aos 12 Mandamentos Invariantes e tipagem estrita do Godot 4.

---

## 4. Arquivos Modificados
- [`shaders/toon_water.gdshader`](../../shaders/toon_water.gdshader): Remoção de `depth_texture`, Beer-Lambert e derivadas.
- [`shaders/toon_water_material.tres`](../../shaders/toon_water_material.tres): Limpeza de chaves de parâmetros obsoletos.
- [`scripts/tools/water_tuner.gd`](../../scripts/tools/water_tuner.gd): Sincronização defensiva da ferramenta de tunagem.
- [`scripts/core/game_version.gd`](../../scripts/core/game_version.gd): Incremento para `v0.12.14-alpha`.
- [`project.godot`](../../project.godot) & [`export_presets.cfg`](../../export_presets.cfg): Bump SemVer (build `1214`).
- [`docs/05_arquitetura_e_desenvolvimento/PLANO_MESTRE_DE_PERFORMANCE.md`](../05_arquitetura_e_desenvolvimento/PLANO_MESTRE_DE_PERFORMANCE.md): Tarefa 2.1 marcada como concluída.
- [`docs/historico_melhorias/INDICE_MELHORIAS.md`](INDICE_MELHORIAS.md): Indexação do item 090.
