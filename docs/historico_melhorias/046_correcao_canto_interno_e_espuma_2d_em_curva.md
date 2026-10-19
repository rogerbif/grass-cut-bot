# 046 — Correção Definitiva do Bloco de Canto Interno (`tile_island_corner_in`) e Shader de Água/Espuma 2D Minimalista em Curva

**Data:** 19/10/2026  
**Versão:** `v0.7.8-alpha`  
**Domínio:** Level Design, Pipeline 3D (Blender $\to$ Godot) e Shaders Costeiros

---

## 1. Contexto e Diagnóstico da Causa Raiz

Ao inspecionar o canto côncavo das ilhas (ex.: Fase 12, `level_12.json`), foram identificados quatro problemas técnicos combinados:

1. **Inversão de Normais por Escala Negativa (`tile_island_corner_in.glb`):**
   - O modelo `Tile_Cliff_Corner_Inner` havia sido transformado no Blender com `scale = (0.40, -0.40, 0.18)` ($\det(M) < 0$), invertendo a ordem dos vértices (*winding order*) e todas as normais da malha para dentro.
   - Com o *Backface Culling* ativo na Godot, o topo de grama verde e a parede curva marrom ficavam invisíveis, deixando um vão quadrado aberto para a água e expondo as faces internas de fechamento com UVs não mapeadas (triângulos brancos).
2. **Polígonos Internos de Fundo e Tampas Laterais nos Tiles:**
   - Os polígonos inferiores de aba de espuma embutida (`z <= 0.02`, `UV = (0.25, 0.17)`) e tampas laterais com UV incorreta (`(0.35, 0.45)`) geravam artefatos nas junções.
3. **Escala Vertical (`scale.y`) em `tile_island_corner_in.tscn` e `tile_island_end.tscn`:**
   - Enquanto `tile_island_edge.tscn` e `tile_island_corner_out.tscn` usavam `scale.y = 2.0` ($0.72\text{m}$ de profundidade até a linha d'água em $Y = -0.71\text{m}$), `tile_island_corner_in.tscn` e `tile_island_end.tscn` estavam com `scale.y = 1.0` ($0.36\text{m}$).
4. **Geometria da Espuma Retangular vs. Contorno Curvo do Terreno:**
   - A malha anterior de `CoastalFoamRibbon` gerava quads retangulares alinhados aos eixos da célula, formando pontas quadradas nas quinas arredondadas (`island_corner_out`) e omitindo a espuma nas quinas côncavas (`island_corner_in`).

---

## 2. Solução Implementada

### 2.1. Exportação com Rotação Pura e Limpeza de Malha no Blender (`enviroment.blend`)
- Substituída a escala negativa por **rotação pura** (`rot_z_deg = -90`) com escala estritamente positiva `(0.40, 0.40, 0.18)` ($\det(M) > 0$) para `Tile_Cliff_Corner_Inner`, posicionando o recorte côncavo no quadrante Noroeste ($-X, -Z$) no Godot com 100% das normais apontando para fora.
- Removidas as faces inferiores do recorte de água e reconstruídas as tampas laterais de 6 vértices com `UV = (0.19, 0.83)` (marrom da falésia) em todos os tiles costeiros.
- Reimportação atômica executada via `godot --headless --import --quit`.
- Ajustadas as cenas `scenes/editor/tiles/tile_island_corner_in.tscn` e `scenes/editor/tiles/tile_island_end.tscn` para `scale.y = 2.0` no nó `$Model` e `FloorCollision` com altura `0.72m` em `y = -0.36`.

### 2.2. Malha de Espuma em Curva Exata (`scripts/level/level_json_loader.gd`)
- Atualizado `LevelJsonLoader.build_coastal_colliders_and_foam()` (e `level_controller.gd`) para gerar a fita costeira `CoastalFoamRibbon` seguindo a equação paramétrica exata da base de cada tile:
  - `island_edge`: segmento reto em $Z = -0.20\text{m}$ ($X \in [-0.40, +0.40]$).
  - `island_corner_out`: arco circular convexo de 10 subdivisões com centro em $(-0.12, +0.12)$ e raio $R = 0.32\text{m}$ conectado aos segmentos tangentes.
  - `island_corner_in`: arco circular côncavo de 10 subdivisões com centro em $(-0.40, -0.40)$ e raio $R = 0.20\text{m}$ com normal radial apontando para o recorte de água.
  - `island_end`: semicírculo de 12 subdivisões ($180^\circ$) com raio $R = 0.20\text{m}$.
- Todas as subdivisões compartilham normais radiais suaves por vértice ($C^1$), garantindo que o deslocamento no *vertex shader* ocorra sem rachaduras entre segmentos ou fronteiras de tiles.

### 2.3. Shader 2D Minimalista Low Poly (`shaders/coastal_foam.gdshader`)
- Migrado para `render_mode unshaded, blend_mix, depth_draw_never, cull_disabled`, eliminando sombreamento acinzentado sobre a espuma.
- Implementadas duas faixas concêntricas estilo 2D Toon/Minimalista (`smoothstep` de transição nítida):
  1. **Faixa Costeira Principal (`shore_foam_color`):** Branca pura colada ao contorno curvo da falésia.
  2. **Anel de Maré Secundário (`ripple_foam_color`):** Linha fina paralela à curva que oscila suavemente no vai e vem do mar (`sin(TIME * wave_speed)`).

---

## 3. Verificação e Validação
- Captura visual renderizada na Fase 12 (`level_12.json`) confirmando o encaixe sólido do bloco `tile_island_corner_in` (sem triângulos brancos ou buracos) e a espuma 2D minimalista contornando suavemente todas as curvas côncavas e convexas.
- Execução via Godot MCP (`run_project` / `get_debug_output`) validada com **0 warnings e 0 errors**.
