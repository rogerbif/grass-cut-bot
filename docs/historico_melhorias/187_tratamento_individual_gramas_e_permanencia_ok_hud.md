# Melhoria 187: Tratamento Individual de Gramas por Cor e Fix de Permanência do "OK" no HUD 🌿✨

**Data:** 06/11/2026  
**Tipo:** Bugfix / Gameplay / HUD / Level Design  
**Versão Alvo:** Game SemVer `v0.12.137-alpha` (Patch 137)  
**Status:** Concluído e Validado  

---

## 1. Visão Geral e Necessidade

Após a introdução da expansão para 40 fases e dos novos efeitos botânicos, foram reportadas duas inconsistências críticas de interface e lógica de objetivos:
1. **Sobrescrita do estado "OK" ao concluir meta no HUD:** Quando uma meta atingia zero, a função `_on_goal_completed` definia o texto como `"OK"`, a cor verde e o fundo canônico de sucesso. Porém, cortes subsequentes da mesma espécie (seja pela existência de tufos remanescentes no mapa ou durante o intervalo de celebração) disparavam `_on_goal_updated`, que sobrescrevia `card["count_label"].text` para `"0"`, removendo o `"OK"`.
2. **Tratamento de gramas de forma agrupada/genérica:** Nas fases 21 a 40, `generate_all_40_levels.gd` estava forçando `custom_goals = { "grass": ... }`, unificando as diversas variedades de grama em uma única meta genérica `"grass"`. Além disso, em `vegetation_grid.gd`, o fallback de contagem reduzia `grass_green` individual para `"grass"`.

---

## 2. Modificações Realizadas

### A. Fix de Permanência Estrita do "OK" no Top HUD (`scripts/ui/hud.gd`)
- Em `_create_goal_card()`, foi adicionada a chave `"is_completed": false` ao dicionário de metadados de cada card.
- Em `_on_goal_completed()`, o card é marcado como `card["is_completed"] = true`, o texto é firmado em `"OK"` e o fundo `BADGE_GOAL_DONE_BG` é aplicado.
- Em `_on_goal_updated()`, se `remaining <= 0` ou se `card.get("is_completed", false)` for verdadeiro, chama-se imediatamente `_on_goal_completed(plant_type)` e encerra a execução, impedindo qualquer sobrescrita numérica posterior por `"0"`.
- Proteção defensiva contra `null` adicionada em `goals_container.add_child(card_panel)`.

### B. Tratamento 100% Individual das Variedades de Grama (`scripts/plants/vegetation_grid.gd`)
- Removido o agrupamento que forçava `"grass"` genérico quando havia apenas uma cor ou verde comum.
- Cada variedade presente no mapa (`grass_green`, `grass_yellow`, `grass_blue`, `grass_purple`, `grass_red`, `grass_white`, `grass_black`) passa a ser registrada e contabilizada estritamente com sua chave individual, recebendo seu respectivo card e ícone botânico temático no HUD.
- Autoloads em chamadas de gameplay (`AudioManager`, `SaveManager`, `UpgradeManager`) foram encapsulados com `get_node_or_null` defensivo para prevenir erros de compilação em execuções headless ou em scripts standalone.

### C. Regeneração das Fases 21 a 40 sem Metas Forçadas (`scripts/tools/generate_all_40_levels.gd`)
- Removidos todos os 20 blocos de `custom_goals = { "grass": ... }`, permitindo que o cálculo natural `compute_goals` extraia exatamente as cores e quantidades reais de gramas e espécies florais de cada ilha.
- Corrigida a função `_add_grass_ring` para utilizar `vf.call("add_shape", type_name, outer, [inner])`, garantindo anéis concêntricos perfeitos com furos internos preservados via Clipper.
- Regenerados com sucesso todos os 20 arquivos JSON de `data/levels/level_21.json` até `level_40.json` com **0 erros**.

### D. Testes Automatizados Expandidos (`tests/test_progression_and_goal_effects.gd`)
- Adicionada validação de ausência total da chave `"grass"` genérica em todos os 40 arquivos de níveis.
- Adicionada validação de retenção do texto `"OK"` no HUD após chamadas consecutivas de cortes excedentes com `remaining = 0`.

---

## 3. Validação e Qualidade

- **Testes Automatizados:** `tests/test_progression_and_goal_effects.gd` executado com 100% de aprovação em todos os 8 blocos de teste.
- **Auditoria Headless:** Execução headless do motor (`--quit-after 60`): **0 erros e 0 warnings**.
- **Regeneração de Fases:** `generate_all_40_levels.gd` concluído com sucesso e 0 erros para todas as fases.
