# Melhoria 172: Correção do Atalho Ctrl+S e Clamping Imediato no Campo de Tempo do Editor ⏱️💾

## 🎯 Objetivo e Contexto
O usuário relatou: *"tem algum problema eu recem havia salvado a fase 1 com 30 segundos, revise o salvamento"*.
Ao auditar o arquivo `data/levels/level_01.json`, verificou-se que o valor gravado ainda era `60.0`, e a data de modificação indicava que o salvamento recente não havia sido persistido.

Na investigação detalhada do código de entrada e eventos do editor:
1. **Bloqueio do Atalho Ctrl+S:** No método `_input(event)` de [`scripts/editor/level_editor.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/editor/level_editor.gd), a condição `if not is_playtesting and not ui.has_text_focus():` impedia a execução do `Ctrl+S` se o cursor estivesse ativo dentro da caixa de texto do `SpinBox` (`spin_time`). Como o usuário acabou de digitar o tempo (ex: `30`), o `LineEdit` ainda estava focado, fazendo com que o atalho `Ctrl+S` fosse totalmente ignorado pelo editor!
2. **Clamping no `text_changed`:** O `text_changed` do `spin_time` emitia o valor float puro sem o clamp aos limites `[min_value, max_value]` (15s a 600s), permitindo descompassos temporários antes do blur.

---

## 🛠️ Alterações Realizadas

### 1. Desacoplamento do Atalho Ctrl+S do Foco de Texto
- Em [`scripts/editor/level_editor.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/editor/level_editor.gd):
  - O atalho `Ctrl+S` foi promovido para fora da guarda `not ui.has_text_focus()`.
  - Agora, mesmo que o usuário esteja com o cursor ativo no campo de tempo (ou em qualquer outro `SpinBox`), pressionar `Ctrl+S` invoca `save_current_level_json()` imediatamente.
  - A guarda `not ui.has_text_focus()` foi mantida exclusivamente para atalhos de ferramentas com uma única letra (`B`, `E`, `F`, `S`, `R`, `1`, `2`, `3`, `4`, `Ctrl+Z`, `Ctrl+Y`), evitando conflito com digitação de texto.

### 2. Clamping Imediato em `spin_time`
- Em [`scripts/editor/level_editor_ui.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/editor/level_editor_ui.gd):
  - No evento `text_changed` do `spin_time`, o valor digitado agora passa por `clampf(val, min_value, max_value)` antes de emitir `time_limit_changed`.
  - Isso garante que a variável interna `time_limit` do editor seja atualizada instantaneamente a cada tecla digitada dentro da faixa permitida.

---

## 🧪 Testes e Validação
- Testes automatizados executados via Godot Console headless:
  - `tests/test_editor_goals_and_time_limit.tscn` -> 100% de sucesso.
  - `tests/test_save_and_load_roundtrip.tscn` -> 100% de sucesso.
  - `tests/test_editor_camera_and_shortcuts.tscn` -> 100% de sucesso.
- 0 erros e 0 warnings no console da engine.

---

## 📦 Game SemVer e Sincronização
- **Versão anterior:** `v0.12.117-alpha`
- **Nova versão:** `v0.12.118-alpha`
- **Arquivos modificados:**
  - `scripts/editor/level_editor.gd`
  - `scripts/editor/level_editor_ui.gd`
  - `project.godot`
  - `export_presets.cfg`
