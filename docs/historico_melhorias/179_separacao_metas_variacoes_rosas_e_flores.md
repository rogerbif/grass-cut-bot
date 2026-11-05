# Melhoria 179: Separação de Metas para Variações de Rosas e Flores no Editor e Gameplay (`v0.12.125-alpha`) 🌹🎯

## 1. Contexto e Diagnóstico
Ao posicionar as 7 variações cromáticas da Rosa Nobre no mapa através do Editor de Fases, observou-se uma anomalia na detecção e exibição de objetivos:
- Apenas a Rosa Vermelha (`flower_rose`) era contabilizada como "Rosa Nobre".
- As outras 6 variações de rosas (`flower_rose_white`, `flower_rose_yellow`, `flower_rose_blue`, `flower_rose_wine`, `flower_rose_black`, `flower_rose_peach`) começavam com o prefixo `"flower"` e, por não estarem registradas individualmente no catálogo estático de metas `GOALS_CATALOG`, caíam no fallback genérico:
  ```gdscript
  elif t.begins_with("flower"):
      flower_by_type["flower"] = int(flower_by_type.get("flower", 0)) + 1
  ```
  Resultando em uma contagem distorcida onde as rosas apareciam como "Flor Silvestre (6 flores)" e apenas "Rosa Nobre (1 rosas)".
- Além disso, o usuário solicitou explicitamente que cada variação de flor opere como meta independente na fase, permitindo que fases tenham objetivos refinados por cor/variante com cards e contagens dedicadas.

---

## 2. Implementação e Solução Técnica

### A. Expansão Integral do `GOALS_CATALOG` (`level_editor_ui.gd`)
Cadastradas todas as 6 variações da Flor Silvestre e todas as 7 variações da Rosa Nobre em `GOALS_CATALOG`:
- **Flores Silvestres:**
  - `flower`: 🌸 Flor Silvestre
  - `flower_blue`: 💠 Flor Azul Celeste
  - `flower_sunset`: 🌅 Flor Pôr do Sol
  - `flower_purple`: 🔮 Flor Lilás
  - `flower_white`: 🤍 Flor Branca
  - `flower_turquoise`: 💎 Flor Turquesa
- **Rosas Nobres:**
  - `flower_rose`: 🌹 Rosa Nobre
  - `flower_rose_white`: 🤍 Rosa Branca
  - `flower_rose_yellow`: 💛 Rosa Amarela
  - `flower_rose_blue`: 💙 Rosa Azul
  - `flower_rose_wine`: 🍷 Rosa Vinho
  - `flower_rose_black`: 🖤 Rosa Negra
  - `flower_rose_peach`: 🧡 Rosa Pêssego

### B. Correção da Amostragem e Contagem no Editor (`update_goals_summary`)
1. **Contagem Específica:** O dicionário `flower_by_type` agora mapeia diretamente todas as chaves de variações. Cada flor colocada incrementa sua respectiva meta individual.
2. **Fallback Hierárquico Inteligente:** Caso surja uma variação desconhecida, ela agora resolve sua espécie base via `TilePaletteDB.get_base_id_for_variant(t)`, evitando que rosas caiam em Flor Silvestre.
3. **Cards Filtrados:** Como o editor oculta automaticamente cards com contagem zero (`total_count > 0`), fases normais continuam com painel limpo e compacto, enquanto fases com rosas exibem os cards coloridos dedicados de cada variante presente.

### C. Suporte a Metas no Gameplay e Fallback Gracioso (`GameManager`)
No `GameManager._on_plant_cut` e `get_remaining_goal`:
- Se a fase definiu uma meta específica para a variação (ex: `goals.has("flower_rose_white")`), o corte abate diretamente essa meta.
- Se a fase definiu apenas a meta pai (ex: `goals.has("flower_rose")`), o corte de qualquer rosa abate a meta da espécie pai via `TilePaletteDB.get_base_id_for_variant`.
- Se a fase definiu meta genérica (`flower`), qualquer flor continua abatendo a meta genérica.

### D. Ilustrações e Cores Canônicas no HUD e Card de Fase (`GoalIconFactory` & `PlantDatabase`)
- `PlantDatabase.get_species()` agora consulta variações em `TilePaletteDB.get_variation_data(key)` quando solicitado, retornando metadados botânicos completos e cores de pétalas fiéis.
- `GoalIconFactory.build_goal_icon()` colore as pétalas da ilustração vetorial com a cor exata de cada variação (ex: dourado para rosa amarela, azul royal para rosa azul, vinho escuro para rosa vinho, preto aveludado para rosa negra).
- `MapLevelCard.GOAL_ORDER` atualizado para ordenar as variações de forma simétrica e elegante.

### E. Persistência de Progresso no Herbário (`SaveManager`)
Em `SaveManager.record_plant_harvest()`, ao colher uma variação, além de registrá-la, o progresso da espécie base correspondente também é incrementado automaticamente, garantindo avanço contínuo nas 15 espécies principais da Coleção.

---

## 3. Verificação e Testes
- **`tests/test_flower_variations_editor.tscn`**:
  - Testada a inserção das 7 rosas simultâneas na grade.
  - Verificado que `flower` ("Flor Silvestre") permanece com contagem **0** (card oculto).
  - Verificado que cada uma das 7 rosas possui exatamente **1** tufo detectado e card ativo.
  - Execução headless: **100% aprovado (0 erros, 0 warnings)**.
- **`tests/test_editor_goals_and_time_limit.tscn`**:
  - Validada a persistência de metas e individualidade de tempos: **100% aprovado**.
- **`tests/test_rose_cutting_visual.tscn`**:
  - Validado o corte de 3 hits da rosa com caule de alto contraste: **100% aprovado**.
- **Validação Visual:**
  - Gerada captura de tela confirmando cards com cores, ícones, checkboxes e spinboxes ativos para todas as 7 rosas no painel lateral direito.
