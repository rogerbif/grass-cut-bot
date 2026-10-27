# Melhoria 118: Ajuste de Corner Radius no Carimbo Quadrado e Metas Independentes por Cor de Grama 📐🌿🎨

**Versão:** `v0.12.42-alpha`  
**Data:** 27/10/2026

---

## 1. Contexto e Motivação

Duas necessidades de design e precisão mecânica foram apontadas:
1. **Curvatura das Quinas no Pincel Quadrado:**
   - Ao carimbar ou preencher com a ferramenta Quadrada (`ShapeType.SQUARE`), as quinas eram retas em $90^\circ$ ou não possuíam controle de raio.
   - O tile canônico original de canto (`tile_island_corner_out.glb`) possuía curvatura de $R = 0.28\text{m}$.
   - O usuário solicitou que houvesse uma opção para ajustar o `corner_radius`, deixando a curvatura original ($R = 0.28\text{m}$) como padrão (*default*).
2. **Contabilização Independente por Cor de Grama:**
   - Anteriormente, todas as 7 variantes de cores de grama (`grass_green`, `grass_yellow`, `grass_blue`, etc.) eram agrupadas sob uma única chave genérica `"grass"`.
   - O usuário solicitou que gramas de cores diferentes sejam contabilizadas separadamente, gerando metas e cards independentes no HUD e resumo discriminado no editor.

---

## 2. Alterações Implementadas

### 2.1. Corner Radius no Carimbo Quadrado (`BrushPatterns` & `LevelEditorUI`)
- **`BrushPatterns.get_vector_stamp_polygon()` (`scripts/editor/brush_patterns.gd`):**
  - Adicionado parâmetro opcional `corner_radius: float = 0.28`.
  - Para `ShapeType.SQUARE`:
    - Se `corner_radius <= 0.001`: gera retângulo reto com 4 vértices.
    - Se `corner_radius > 0.001`: gera retângulo arredondado perfeito com 4 arcos cilíndricos nos cantos (raio $cr = \min(corner\_radius, h \times 0.95)$ e 5 passos por arco, totalizando 24 vértices) que triangulam suavemente em 22 triângulos.
- **Interface do Editor (`scripts/editor/level_editor_ui.gd`):**
  - Adicionado container contextual `corner_radius_container` abaixo dos formatos de pincel.
  - Exibido automaticamente apenas quando a ferramenta Quadrado (`ShapeType.SQUARE`) está selecionada.
  - Controle numérico com `SpinBox` (intervalo de `0.00m` a `0.80m`, passo `0.02m`, padrão `0.28m`).
  - Botões de preset rápido: `[0m (Reto)]`, `[0.28m (Padrão)]` e `[0.40m]`.
- **Sincronização no Editor (`scripts/editor/level_editor.gd`):**
  - Adicionada variável `current_corner_radius: float = 0.28`, conectada ao sinal `ui.corner_radius_changed` e propagada ao carimbo e ao hover preview vetorial.

### 2.2. Contabilização e Metas Independentes por Cor de Grama (`VegetationGrid`, `GameManager` & `HUD`)
- **`VegetationGrid` (`scripts/plants/vegetation_grid.gd`):**
  - Removido o hardcode que forçava `own_plant_key = "grass"` para todas as gramas. Cada tufo agora preserva sua cor real (`_plant_keys.append(v_type)`).
  - Na geração de metas (`_build_from_vector_field` e `_build_from_vegetation_field`):
    - Se o nível contiver mais de uma cor de grama (ex: verde e amarelo) OU se a única cor presente não for verde comum, cada cor gera sua meta individual: `goals["grass_green"] = X`, `goals["grass_yellow"] = Y`, etc.
    - Se houver apenas grama verde comum, mantém a chave canônica `goals["grass"] = X` para total retrocompatibilidade.
  - No corte em círculo (`cut_in_circle()`):
    - Implementados dicionários per-tipo `_remaining_grass_by_type` e `_grass_cut_accumulator_by_type`.
    - Cada lote de 10 cortes daquela cor registra o avanço na meta daquela cor específica.
    - Proteção anti-trava recalibrada para varrer e garantir a conclusão de cada cor individual.
- **`GameManager` (`scripts/core/game_manager.gd`):**
  - No `register_cut()`, suporta tanto a meta específica por cor (`grass_yellow`, `grass_blue`, etc.) quanto o fallback para `"grass"` caso a fase utilize a chave genérica.
- **`HUD` (`scripts/ui/hud.gd`):**
  - No `_create_goal_card()`, mapeadas todas as cores de grama com o ícone `🌿` e modulação de cor correspondente:
    - `grass_green`: Verde esmeralda vivo (`Color(0.35, 0.95, 0.40)`)
    - `grass_yellow`: Amarelo ouro solar (`Color(0.98, 0.88, 0.25)`)
    - `grass_blue`: Azul ciano tropical (`Color(0.35, 0.75, 1.00)`)
    - `grass_purple`: Roxo ametista (`Color(0.85, 0.45, 1.00)`)
    - `grass_white`: Branco neve puro (`Color(0.95, 0.95, 0.95)`)
    - `grass_red`: Vermelho rubi quente (`Color(1.00, 0.35, 0.35)`)
    - `grass_black`: Cinza ardósia grafite (`Color(0.40, 0.40, 0.45)`)
- **Resumo no Editor de Fases (`LevelEditorUI`):**
  - O resumo de metas no painel esquerdo agora discrimina os tufos por espécie quando há mais de uma cor presente (ex: `"/ 25 (verde: 150, amarelo: 100)"`).

---

## 3. Verificação e Testes

- **Novo Teste Automatizado (`tests/test_corner_and_multigrass.gd`):**
  - Validação de quadrado reto ($R = 0.0\text{m}$): 4 vértices exatos.
  - Validação de quadrado arredondado ($R = 0.28\text{m}$): 24 vértices e triangulação completa.
  - Validação de retrocompatibilidade de fase monofolha verde (`goals["grass"]`).
  - Validação de fase com múltiplas cores (`goals["grass_green"]` e `goals["grass_yellow"]` separados).
  - Resultado: **100% de testes aprovados**.
- **Auditoria dos 20 Níveis (`scripts/tools/verify_levels.gd`):**
  - Todas as 20 fases canônicas exibem suas metas ricas discriminadas por cor com 0 erros e 0 warnings.
- **SemVer:** Incrementado para `v0.12.42-alpha` (código 1242).
