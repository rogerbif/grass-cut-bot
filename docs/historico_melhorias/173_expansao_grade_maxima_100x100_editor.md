# Registro de Melhoria: Expansão do Limite Máximo da Grade para 100x100 e Câmera Panorâmica no Editor

## 1. Visão Geral e Contexto
- **Solicitação do Usuário:** O usuário questionou se o tamanho máximo da grade era 36x36 e solicitou poder redimensionar a grade até 100x100.
- **Diagnóstico:** 
  - Na interface (`level_editor_ui.gd`), os campos `SpinBox` já permitiam de 4 a 100.
  - No script central do editor (`level_editor.gd`), o manipulador `_on_grid_resize_requested` aplicava `clampi(..., 4, 36)`.
  - A câmera do editor (`editor_camera.gd`) tinha `max_distance = 28.0`, o que restringia o zoom out para visualizar ilhas muito grandes (ex: 100x100 = 40m x 40m).

## 2. Alterações Realizadas
1. **`scripts/editor/level_editor.gd`:**
   - Atualizado o limite máximo de `clampi` em `_on_grid_resize_requested` para `100` tanto para largura quanto para altura:
     ```gdscript
     grid_width = clampi(new_w, 4, 100)
     grid_height = clampi(new_h, 4, 100)
     ```
2. **`scripts/editor/editor_camera.gd`:**
   - Ampliado `max_distance` de `28.0` para `75.0`, permitindo que o zoom com scroll do mouse e o modo ortogonal top-down se afastem o suficiente para enquadrar perfeitamente a grade expandida de até 100x100 (40 metros).
3. **`tests/test_editor_goals_and_time_limit.gd`:**
   - Atualizado tempo esperado das fases para espelhar as alterações reais recentes salvas pelo usuário no editor.
4. **SemVer & Presets:**
   - Bump de versão para `0.12.119-alpha` (code 1319) em `project.godot` e `export_presets.cfg`.

## 3. Verificação e Testes
- `test_editor_goals_and_time_limit.tscn` executado com sucesso (0 erros).
- `test_save_and_load_roundtrip.tscn` executado com sucesso (0 erros).
- `test_editor_camera_and_shortcuts.tscn` executado com sucesso (0 erros).
- `test_multi_hit_continuous.tscn` executado com sucesso validando paridade com a nova versão `v0.12.119-alpha`.
