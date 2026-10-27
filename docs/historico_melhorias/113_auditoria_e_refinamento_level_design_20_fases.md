# Melhoria 113: Auditoria e Refinamento de Level Design das 20 Fases Canônicas

**Data:** 26 de Outubro de 2026  
**Versão:** `v0.12.38-alpha`  
**Domínio:** Level Design, Vegetação Vetorial, Metas de HUD & Miniaturas do Hub Principal

---

## 1. Diagnóstico e Problemas Encontrados na Revisão

Durante a auditoria profunda das 20 fases geradas (`level_01.json` a `level_20.json`) e de sua integração com `VegetationGrid`, `GameManager` e `island_node.gd`, foram identificados e solucionados 6 pontos críticos de experiência de Level Design:

1. **Polígonos de Grama e Objetos Extrapolando Silhuetas Não-Retangulares (Água / Falésias):**
   - Em ilhas recortadas (Cruz nas Fases 5 e 13, Istmo na Fase 11, Ilha em H na Fase 17, Diamante na Fase 18, Estrela na Fase 19 e Trevo na Fase 20), anéis e retângulos de grama ou objetos (`rock`, `wheat`, `flower_*`) invadiam quadrantes de água ou repousavam sobre a borda chanfrada da falésia (`island_edge` / `island_corner_out`), tornando tufos ou flores inacessíveis atrás da contenção costeira invisível (`CoastalLimits`).
2. **Sobreposição de Camadas de Cores Distintas (`add_shape` vs `merge_or_add_shape`):**
   - Ao desenhar manchas secundárias (ex.: círculos azuis sobre faixas diagonais na Fase 2, retângulo amarelo sobre verde na Fase 6, estrela branca sobre azul na Fase 7), o uso direto de `add_shape` empilhava duas cores no mesmo espaço 3D, dobrando a densidade de tufos.
3. **Auto-Corte Involuntário no Frame 0 (Ausência de Clareira de Spawn):**
   - Tufos posicionados exatamente sob a coordenada inicial do robô (`spawn_cell`) eram cortados automaticamente no frame 0 do carregamento da cena antes de qualquer interação do jogador.
4. **Contaminação de Célula Lógica (`0.40m`) entre Grama, Trigo e Flores:**
   - Em `vegetation_grid.gd`, tufos de grama amostrados dentro da mesma célula lógica (`0.40m`) de um `wheat` ou `flower_*` herdavam `_cell_keys[cell_idx]`, inflando artificialmente as metas do HUD (ex.: 8 trigos na Fase 3 viravam 26; 8 flores na Fase 4 viravam 23) e gerando folhas de grama atravessando o caule das flores.
5. **Atualização Unitária (1:1) de Flores Específicas no Top HUD:**
   - Quando o jogador cortava uma espécie específica (`flower_daisy`, `flower_rose`, etc.), `GameManager.register_cut()` recebia o identificador da espécie enquanto `GameManager.goals` armazenava a chave unificada `"flower"`, atrasando o decremento visual do card no HUD.
6. **Fidelidade Visual e Posição do Robô nas Ilhas do Menu Principal (`island_node.gd`):**
   - No Hub Principal, `island_node.gd` verificava apenas `type == "flower"` (omitindo as 7 novas espécies de flores e o `wheat` da camada de objetos) e mantinha o `BotAnchor` fixo em `(0, -0.052, 0)`, o que na Fase 8 (Ilha em U) posicionava o robô sobre a enseada de água.

---

## 2. Soluções Implementadas

### 2.1 Recorte Costeiro Automático e Validador de 6 Regras (`scripts/tools/generate_all_20_levels.gd`)
- **`_clip_vector_field_to_island()`:** Constrói a união geométrica exata de todos os tiles da ilha com recuo costeiro de `0.34m` nas bordas voltadas para o mar e chanfro nas quinas externas, intersectando todos os polígonos do `VectorGrassField` contra essa máscara segura. Resultado: **0 tufos na água ou em encostas de falésia** em todas as 20 fases.
- **Clareira de Spawn (`SPAWN_GRASS_CLEAR_RADIUS = 0.72m`):** Recorta um círculo sutil no ponto exato de spawn para que a partida inicie com 0 cortes automáticos no frame 0.
- **Substituição Booleana Limpa (`merge_or_add_shape`):** Todas as composições multicoloridas utilizam operações booleanas Clipper (`Geometry2D`), além de faixas diagonais rotacionadas em $45^\circ$ ortogonais na Fase 2.
- **Validação Estrita de 6 Regras no Gerador:**
  1. Spawn em tile interno com todos os 8 vizinhos em `terrain_grid`.
  2. Raio livre de spawn $\ge 1.47\text{m}$ sem nenhum obstáculo rígido.
  3. Fases 1 a 5 com estritamente `0` rochas.
  4. `100%` dos objetos (`rock`, `wheat`, `flower_*`) posicionados em tiles internos (4 vizinhos cardeais em `terrain_grid`).
  5. `100%` das rochas com folga diagonal completa (todos os 8 vizinhos em `terrain_grid`), eliminando qualquer risco de estrangulamento contra a parede invisível costeira.
  6. Distância centro a centro entre rochas $\ge 2.80\text{m}$ e `0` tufos fora de `terrain_grid`.

### 2.2 Contabilização 1:1 Exata e Clareira de Caule (`scripts/plants/vegetation_grid.gd` & `scripts/core/game_manager.gd`)
- Adicionada clareira de `0.26m` ao redor de cada `tile_flowers` e `tile_wheat` durante a filtragem de `sampled_tufts`, impedindo que folhas de grama nasçam dentro do caule das flores/trigos.
- `_plant_keys` passa a registrar a categoria própria de cada instância (`"wheat"`, `v_type` para flores, `"grass"` para gramas), garantindo correspondência exata `1:1` entre os objetos da fase e a meta do HUD.
- `GameManager.register_cut()` resolve automaticamente qualquer `flower_*` para a meta `"flower"` quando unificada, garantindo efeito *pop* imediato a cada flor cortada.

### 2.3 Sincronização das Miniaturas 3D no Hub Principal (`scripts/menu/island_node.gd`)
- `bot_anchor` passa a ler a coordenada `spawn` do JSON de cada fase, posicionando o robô sempre sobre solo firme na visão `BOT_VIEW`.
- Suporte completo às 8 espécies de flores e ao trigo nas malhas vetoriais (`MAP_VIEW`) e nos `MultiMeshInstance3D` (`BOT_VIEW`).
