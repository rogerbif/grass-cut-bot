# Melhoria 045: Correção da Malha do Tile de Canto, Espuma Animada do Mar e Espaçamento Estrito de Grama e Rochas 🌊🏝️🌿

**Data:** 19 de Outubro de 2026  
**Versão:** `v0.7.7-alpha`  
**Escopo:** Modelagem 3D Blender, Shaders Godot, Level Design das 20 Fases Canônicas e Regras de Segurança Costeira.

---

## 1. Contexto e Diagnóstico

A avaliação visual e de gameplay da ilha revelou 4 pontos cruciais de melhoria:
1. **Falha na Malha do Tile de Canto:**
   - O tile de quina (`Tile_Cliff_Corner_Outer`) apresentava uma aba/retângulo branco indesejado sob o lábio de grama na transição com tiles retos.
   - Diagnóstico no Blender e Godot revelou que:
     - As normais dos polígonos superiores estavam invertidas apontando para baixo ($Z = -1.0$).
     - As tampas de fechamento lateral (end-caps) tinham UVs mapeadas no atlas para a coordenada `(0.19, 0.17)`, que correspondia à cor branca da espuma ao invés da terra marrom da falésia.
2. **Perda da Espuma Costeira e Ausência de Movimento:**
   - Com a transição para ilhas 3D modulares geradas dinamicamente via JSON, a fita de espuma ao nível da água foi perdida, resultando em um encontro plano e estático da falésia com o oceano.
   - O usuário solicitou o retorno da espuma com um "vai e vem suave como o balanço do mar".
3. **Vegetação sobre Tiles de Borda:**
   - Tufos de grama estavam presentes em tiles costeiros, forçando o robô a cortar grama na beirada da falésia.
4. **Espaçamento e Posicionamento de Rochas:**
   - Rochas posicionadas nas bordas ou muito próximas umas das outras bloqueavam a passagem e a serra.
   - Regra estrita solicitada: **pelo menos 2 tiles livres** entre uma rocha e a borda, e **pelo menos 2 tiles livres** entre duas rochas quaisquer.

---

## 2. Implementação e Soluções

### A. Correção da Topologia e UVs no Blender
- **Recálculo de Normais:** Normais de `Tile_Cliff_Corner_Outer`, `Tile_Cliff_End` e `Tile_Cliff_Corner_Inner` recalculadas para o exterior (`bmesh.ops.recalc_face_normals`), com todas as normais de teto apontando para $+1.0$.
- **Remapeamento de End-Caps:** Todas as faces de tampas laterais verticais remapeadas para UV `(0.35, 0.45)`, eliminando qualquer vestígio de aba branca e integrando perfeitamente a cor marrom da falésia.
- **Exportação glTF Canônica:** Re-exportação dos 6 tiles (`tile_island_*.glb`) com `export_apply=True` e `export_yup=True`. Cache binário regenerado via `godot --headless --import`.

### B. Shader de Espuma Costeira Animada (`shaders/coastal_foam.gdshader`)
- Criado shader espacial otimizado para mobile com:
  - Deformação de vértices ao longo da normal externa modulada por seno: `VERTEX.xz += NORMAL.xz * wave * wave_amp * UV.y`.
  - Ancoragem fixa na base da falésia (`UV.y = 0.0`) e oscilação suave de vai e vem da maré na borda d'água (`UV.y = 1.0`).
  - Pulso suave de opacidade e cor entre branco brilhante de espuma e ciano aquático.
- Integrado diretamente ao `LevelJsonLoader.build_coastal_colliders_and_foam`, que agora gera uma fita contínua em `ArrayMesh` em torno de todo o arquipélago em $Y = -0.695\text{m}$ (apenas 1 draw call para a ilha inteira).

### C. Calibração Canônica das 20 Fases (`scripts/tools/calibrate_levels_layout.gd`)
- Processamento automatizado de todas as 20 fases (`data/levels/level_01.json` a `level_20.json`):
  1. **Zero Grama na Borda:** 100% dos tufos em células costeiras/fronteira foram removidos.
  2. **Zero Rochas na Borda:** Nenhuma rocha em células de costa.
  3. **Espaçamento $\ge 2$ Tiles Livres:** Toda rocha possui distância de Chebyshev $\ge 3$ de qualquer borda (mínimo de 2 tiles livres de grama entre a rocha e o mar).
  4. **Espaçamento $\ge 2$ Tiles entre Rochas:** Distância de Chebyshev $\ge 3$ entre quaisquer duas rochas (mínimo de 2 tiles livres de grama entre elas).
  5. **Expansão Dinâmica de Terreno:** Fases com labirintos e rochas foram ampliadas em +2 a +4 células com preenchimento interno de gramado contínuo e autotile das bordas.

---

## 3. Verificação e Resultados

- **Auditoria Automatizada (`verify_levels.gd`):**
  - **0 plantas na borda** em todos os 20 níveis.
  - **0 rochas na borda** em todos os 20 níveis.
  - Distância mínima entre cada rocha e a borda $\ge 3$ células (2 tiles livres).
  - Distância mínima entre quaisquer duas rochas $\ge 3$ células (2 tiles livres).
  - **Status: SUCESSO TOTAL (0 Erros).**
- **Console Godot:**
  - `res://scenes/main.tscn`: **0 warnings e 0 errors** (Guardrail 1).
- **Inspeção Visual:**
  - Quinas exteriores sem costuras ou abas brancas.
  - Margem limpa de segurança ao redor de toda a ilha.
  - Espuma da água viva, oscilando suavemente no ritmo das ondas ao redor do arquipélago.
