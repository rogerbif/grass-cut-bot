# Melhoria 159: Tempo Individual por Fase no Editor, Exibição Imediata ao Carregar e Persistência Isolada ⏱️🏝️

## 🎯 Objetivo e Contexto
O usuário solicitou: *"cada fase deve ter seu tempo, ao carregar deve mostrar o valor e deve ser salvo individualmente"*.
Ao inspecionar o fluxo de carregamento de fases no `level_editor.gd`, identificou-se que o método `_sync_all_ui()` continha uma leitura reversa que sobrescrevia a variável de estado `time_limit` com o valor do `SpinBox` da fase anterior (`time_limit = ui.get_configured_time_limit()`). Dessa forma, ao carregar a Fase 2 (80s), a rotina de sincronização imediatamente restaurava o tempo da Fase 1 (60s), fazendo com que todas as fases parecessem herdar o tempo uma da outra e perdessem seus limites originais.

---

## 🛠️ Alterações Realizadas

### 1. Eliminação da Sobrescrita Reversa em `_sync_all_ui()`
- Em [`scripts/editor/level_editor.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/editor/level_editor.gd), removida a atribuição reversa `time_limit = ui.get_configured_time_limit()`.
- O método `_sync_all_ui()` agora opera exclusivamente como propagador unidirecional de estado do modelo para a interface visual.

### 2. Método Dedicado `set_level_time_limit()` e Atualização Forçada de Header
- Em [`scripts/editor/level_editor_ui.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/editor/level_editor_ui.gd):
  - Adicionado `set_level_time_limit(new_time: float)`: libera qualquer foco residual do `LineEdit`, formata a string numérica diretamente e atualiza `spin_time.set_value_no_signal(new_time)`.
  - Expandido `update_level_header(..., force_time_sync: bool = false)`: ao carregar um nível (`force_time_sync = true`), o valor do tempo é forçado no `SpinBox` e no `LineEdit` mesmo se houvesse foco residual de digitação.
  - No campo de seleção de fase `spin_level`, conectado o sinal `text_submitted` do `LineEdit` para que pressionar Enter no número da fase dispare o carregamento imediato.

### 3. Sincronização e Feedback Visual no Carregamento e Salvamento
- No carregamento em `_load_or_init_level(lvl_id)`:
  - O valor `time_limit` é extraído fielmente do JSON (`level_XX.json`).
  - Chama `ui.set_level_time_limit(time_limit)` e `ui.update_level_header(..., force_time_sync = true)`.
  - Toast informativo atualizado para exibir o tempo carregado: `📂 Fase XX carregada (⏱️ YYs)`.
- No salvamento em `save_current_level_json()` e `bake_current_level_tscn()`:
  - Persiste o tempo configurado diretamente no arquivo JSON e TSCN individual da fase aberta.
  - Toast informativo exibe confirmação clara: `💾 Fase XX salva! (⏱️ YYs)`.

---

## 🧪 Testes Automatizados Validados
- **`tests/test_editor_goals_and_time_limit.gd` / `.tscn`:**
  - `test_time_limit_saving_and_sync`: Valida alteração manual, digitação com foco e substituição forçada em carregamento.
  - `test_level_time_limits_from_json`: Valida que cada fase canônica no diretório `res://data/levels/` preserva seu tempo individual único (Fase 1 com 60s, Fase 2 com 80s, Fase 5 com 135s, Fase 10 com 150s, Fase 20 com 190s) e que a UI reflete exatamente o valor ao carregar.
  - `test_default_active_goals_with_total_count`: Valida metas marcadas por padrão com valor total.
  - `test_individual_flowers_in_vegetation_grid`: Valida flores 100% individualizadas.
- Todos os testes executados com 0 erros e 0 warnings no Godot Console headless.

---

## 📦 Game SemVer e Checkpoint
- **Versão anterior:** `v0.12.88-alpha`
- **Nova versão:** `v0.12.89-alpha`
- **Arquivos modificados:**
  - `scripts/editor/level_editor.gd`
  - `scripts/editor/level_editor_ui.gd`
  - `tests/test_editor_goals_and_time_limit.gd`
  - `project.godot`
  - `export_presets.cfg`
