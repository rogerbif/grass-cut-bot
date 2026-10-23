# 086 - Separação Sonora de Objetivo Concluído (`goal_completed`) e Vitória da Fase (`level_completed`) 🎵🎉

## 1. Contexto e Motivação
Anteriormente, o áudio de conclusão de objetivo estava fundido ou causava sobreposição sonora confusa quando o corte concluía uma meta e encerrava a fase simultaneamente. O jogador separou fisicamente a sonoplastia em dois arquivos de áudio dedicados para entregar feedbacks sensoriais distintos:
1. Um som curto e melódico para quando **cada objetivo individual** for alcançado.
2. Uma fanfarra triunfal para quando **todos os objetivos da fase forem concluídos**, iniciando no momento exato em que o Cutter Bot comemora com fogos de artifício e confetes.

---

## 2. Solução Implementada

### A. Registro no `AudioManager`
Em [`scripts/core/audio_manager.gd`](../../scripts/core/audio_manager.gd):
- Pré-carregado o novo arquivo de som oficial:
  ```gdscript
  const SFX_LEVEL_COMPLETED: AudioStream = preload("res://assets/audio/sfx/level_completed.wav")
  ```
- Mapeado no catálogo `_sfx_map` com a chave `"level_completed"` (mantendo `"star_win"` como alias retrocompatível).

### B. Desacoplamento de Eventos no `GameManager`
Em [`scripts/core/game_manager.gd`](../../scripts/core/game_manager.gd):
- **Ao completar cada meta individual (`remaining == 0`):**
  Dispara `AudioManager.play_sfx("goal_completed")` (`assets/audio/sfx/goal_completed.wav`).
- **Ao completar todas as metas da fase e iniciar a celebração de vitória:**
  Em `_trigger_victory_celebration()`, no momento exato em que o estado transiciona para `VICTORY` e o robô aciona os emissores de fogos e confetes (`fireworks_particles` e `confetti_particles`), dispara `AudioManager.play_sfx("level_completed")` (`assets/audio/sfx/level_completed.wav`).

---

## 3. Arquivos Modificados
- [`scripts/core/audio_manager.gd`](../../scripts/core/audio_manager.gd): Pré-carregamento e mapeamento do SFX `level_completed.wav`.
- [`scripts/core/game_manager.gd`](../../scripts/core/game_manager.gd): Chamada de `level_completed` no disparo da comemoração de vitória com fogos.
- [`scripts/core/game_version.gd`](../../scripts/core/game_version.gd): Avanço de versão para `v0.12.10-alpha`.
- [`project.godot`](../../project.godot) & [`export_presets.cfg`](../../export_presets.cfg): Sincronização do versionamento SemVer (build `1210`).
