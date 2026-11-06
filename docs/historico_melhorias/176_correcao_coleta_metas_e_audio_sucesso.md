# Registro de Melhoria: Correção da Coleta Antecipada de Metas, Não-Repetição do Áudio de Sucesso e Padronização das 20 Fases

## 1. Visão Geral e Contexto
- **Problema Reportado:** Ao ceifar feixes de grama adicionais após já ter batido a meta da espécie, o som de meta concluída continuava tocando repetidamente. Além disso, nas primeiras fases (especialmente Fase 3 e Fase 4), a fase dava por concluída a meta antes de coletar toda a vegetação presente no mapa.
- **Diagnóstico:**
  1. No `GameManager.gd` (`register_cut`), a verificação de som era `if remaining == 0: tocar_som`. Quando a meta já havia sido alcançada e o jogador continuava cortando tufos extras daquela mesma planta, `remaining` continuava igual a `0`, fazendo com que `goal_completed` e o SFX tocassem repetidamente a cada corte adicional.
  2. No `VegetationGrid.gd` (`build_from_level_json`), para fases que tinham metas salvas no JSON (`custom_goals`), o código executava uma re-divisão indevida (`raw_val / GRASS_TUFTS_PER_UNIT`) se o valor salvo fosse maior que a contagem agrupada máxima. Como nas Fases 3 e 4 o JSON ainda continha valores brutos antigos (ex: 59 e 53), a meta era dividida por 6 novamente (virando 10 e 9), concluindo a fase quando o jogador tinha cortado menos de 20% do mapa.
  3. Foi realizada uma auditoria completa em todas as 20 fases do jogo, confirmando que trigos e flores são discretos (1:1) e que a grama deve sempre operar no padrão canônico de 6 tufos físicos = 1 unidade de meta.

## 2. Alterações Realizadas
1. **`scripts/core/game_manager.gd`:**
   - Adicionada checagem da transição de conclusão de objetivo (`was_completed`):
     ```gdscript
     var was_completed: bool = int(goal_info["current"]) >= int(goal_info["target"])
     goal_info["current"] += 1
     var remaining: int = maxi(0, int(goal_info["target"]) - int(goal_info["current"]))
     goal_updated.emit(goal_key, remaining, goal_info["target"])

     if not was_completed and remaining == 0:
         goal_completed.emit(goal_key)
         if AudioManager != null:
             AudioManager.play_sfx("goal_completed")
     ```
   - Agora, cortes extras de uma espécie cuja meta já foi alcançada não tocam mais o áudio de vitória da meta.

2. **`scripts/plants/vegetation_grid.gd`:**
   - Removida a divisão dupla em `custom_goals` para grama:
     ```gdscript
     if k_str == "grass" or k_str.begins_with("grass_"):
         var phys_cnt: int = _total_physical_grass if k_str == "grass" else int(_remaining_grass_by_type.get(k_str, 0))
         var max_grouped: int = maxi(1, int(ceilf(float(phys_cnt) / float(GRASS_TUFTS_PER_UNIT))))
         goals[k_str] = clampi(raw_val, 1, max_grouped)
     else:
         goals[k_str] = raw_val
     ```

3. **Arquivos de Dados de Fases (`data/levels/level_03.json`, `level_04.json`, `level_05.json`):**
   - **Fase 03:** Metas ajustadas para o total físico real: `flower: 4`, `grass_green: 82`, `grass_yellow: 42`, `wheat: 36`.
   - **Fase 04:** Metas ajustadas para o total físico real: `flower_daisy: 52`, `grass_green: 37`, `grass_white: 21`.
   - **Fase 05:** Metas ajustadas para o total físico real: `flower_rose_black: 33`, `flower_rose_white: 59`, `grass_black: 22`, `grass_blue: 99`, `grass_red: 20`.

4. **Novo Teste Automatizado:**
   - Criado `tests/test_goal_sound_and_collection.tscn` que valida:
     - Que cortes adicionais da mesma espécie já concluída não disparam `goal_completed` nem repetem áudio.
     - Que todas as primeiras fases possuem paridade de 100% entre a vegetação física gerada e as metas entregues ao `GameManager`.

5. **SemVer & Presets:**
   - Versão incrementada para `v0.12.129-alpha` (code 1328) em `project.godot` e `export_presets.cfg`.

## 3. Verificação e Testes
- `test_goal_sound_and_collection.tscn` executado e aprovado com 100% de sucesso.
- `test_editor_goals_and_time_limit.tscn` aprovado (0 erros).
- `test_editor_goals_and_panel.tscn` aprovado (0 erros).
- `test_wheat_level_02.tscn` aprovado (0 erros).
- `test_save_and_load_roundtrip.tscn` aprovado (0 erros).
- `test_multi_hit_continuous.tscn` aprovado (0 erros).
