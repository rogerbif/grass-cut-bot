# Histórico de Melhorias: Pacote 1 — Limpeza de Loops Ociosos de CPU (60Hz) e Geometria Oculta 📦⚡

**Versão Associada:** `v0.12.206-alpha`  
**Data de Conclusão:** 17/11/2026  
**Status:** Concluído e Validado  

---

## 1. Visão Geral e Contexto do Problema

Análise de desempenho voltada para smartphones Android de entrada identificou três fontes de desperdício de CPU rodando 60 vezes por segundo no loop de física/renderização e duas geometrias 3D/física 100% ocultas mantidas na cena principal:

1. **`Cutter._process_cutting()` + `VegetationGrid.cut_in_circle()`:** Invocavam a consulta espacial CSR 60x/s mesmo quando o robô estava completamente parado, além de executar 4 buscas `get_node_or_null("/root/...")` na `SceneTree` por tick.
2. **`Cutter._update_blade_slash_intensity()`:** Reenviava a uniform `slash_intensity` para o shader a 60Hz mesmo com velocidade constante.
3. **`BladeProgressBar._on_blade_xp_changed()`:** Matava e instanciava um novo `Tween` a cada tufo cortado e solicitava `SubViewport.UPDATE_ONCE` em micro-incrementos sub-pixel.
4. **Geometria e Nós Ocultos:** `water_ocean.tscn` mantinha o plano `DeepWater` (`160×160m` em `Y = -1.10`) sob o oceano 100% opaco `SurfaceWater` (`Y = -0.71`), e `LevelController` apenas ocultava o `Terrain` legado (`visible = false`) mantendo suas 4 malhas e 5 `CollisionShape3D`.

---

## 2. Modificações Implementadas

### 2.1 Early-Exit Estacionário, Cache de Autoloads e `slash_intensity` (`scripts/cutter/cutter.gd`, `scripts/plants/vegetation_grid.gd`)
- Em `Cutter`:
  - Adicionado `_last_slash_intensity` com atualização condicional (`>= 0.002`) em `_update_blade_slash_intensity()`.
  - Em `_process_cutting()`, quando posição e raio da lâmina permanecem constantes e não há planta multi-hit em contato ativo (`_has_active_multihit_contact == false`), o tick pula `cut_in_circle()`.
  - Variáveis `_last_cut_pos`, `_last_cut_radius` e `_last_slash_intensity` são resetadas em `reset_orientation_to_camera()`.
- Em `VegetationGrid`:
  - Adicionadas referências cacheadas `_gm_ref`, `_am_ref`, `_sm_ref` e `_um_ref` com validação defensiva `is_instance_valid()`.
  - Adicionada a flag `_has_active_multihit_contact`, ativada enquanto houver planta resistente viva (`_health[p_idx] > 0`) dentro do raio de corte (em tremor ou após hit parcial) e resetada em `_clear_state()`, `reset_all_plants()` e fora do estado `PLAYING`.

### 2.2 Throttle de `Tween` e `SubViewport` (`scripts/cutter/blade_progress_bar.gd`)
- Adicionado `_last_rendered_progress` para disparar `SubViewport.UPDATE_ONCE` somente quando a variação atingir `>= 0.4%` (ou na chegada exata aos extremos `0%` / `100%`).
- Em `_on_blade_xp_changed()`, incrementos contínuos menores que `2.5%` atualizam diretamente sem recriar `Tween` a cada tufo.

### 2.3 Remoção de Geometria Oculta e Terreno Legado (`scenes/level/water_ocean.tscn`, `scripts/level/level_controller.gd`)
- Removido o nó `DeepWater` e seus sub-recursos (`StandardMaterial3D_deep` e `PlaneMesh_deep`) de `water_ocean.tscn`.
- Em `LevelController.generate_level()`, `default_terrain` legado passa a ser desativado e liberado com `queue_free()` (`default_terrain = null`).

---

## 3. Arquivos Modificados

| Arquivo | Modificação |
| :--- | :--- |
| `scripts/cutter/cutter.gd` | Early-exit estacionário em `_process_cutting()` e cache de `slash_intensity`. |
| `scripts/plants/vegetation_grid.gd` | Cache de Autoloads (`_gm_ref`, `_am_ref`, `_sm_ref`, `_um_ref`) e flag `_has_active_multihit_contact`. |
| `scripts/cutter/blade_progress_bar.gd` | Atualização direta sem `Tween` para micro-passos (`< 2.5%`) e filtro de redraw (`>= 0.4%`). |
| `scenes/level/water_ocean.tscn` | Remoção de `DeepWater` (`160×160m`) coberto pelo `SurfaceWater` opaco. |
| `scripts/level/level_controller.gd` | Liberação de `default_terrain` legado com `queue_free()`. |
| `scripts/core/game_version.gd`, `project.godot`, `export_presets.cfg` | Bump SemVer `0.12.206-alpha` (`version/code=1406`). |
| `docs/05_arquitetura_e_desenvolvimento/PLANO_MESTRE_DE_PERFORMANCE.md` | Registro da tarefa 3.5 (Pacote 1) como concluída. |

---

## 4. Testes e Validação (Headless CLI)

Executados após a edição final de código com 0 warnings GDScript:
- `res://tests/test_multi_hit_continuous.tscn` — **Aprovado** (exit code `0`).
- `res://tests/test_blade_progression.tscn` — **Aprovado** (exit code `0`, todas as etapas Lv 1..10 e `BladeProgressBar`).
- `res://tests/test_blade_pop_and_slash.tscn` — **Aprovado** (exit code `0`, pop/shockwave e `slash_intensity` 0.45 / 0.85).
- `res://scenes/main.tscn` (`--headless --quit`) — **Aprovado** (exit code `0`, sem erro de `remove_child` no `_ready()`).
- `res://tests/test_vegetation_spatial_index.tscn` — Todos os totais de corte, `rem_grass`, `rem_phys`, `coll_hash` e `after_reset` conferiram em todos os 5 níveis (`1, 3, 12, 20, 40`), apresentando apenas o desalinhamento pré-existente de índices no vetor `clip_counts` do arquivo `tests/golden_vegetation_spatial_index.txt` (congelado desde `v0.12.187-alpha`, antes da reordenação do manifesto no `PlantDatabase` em `v0.12.196-alpha`).
