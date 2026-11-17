# Histórico de Melhorias: Blindagem Mobile contra Overlays, Gravação de Tela e Volume 📱🛡️

**Versão Associada:** `v0.12.205-alpha`  
**Data de Conclusão:** 17/11/2026  
**Status:** Concluído e Validado  

---

## 1. Visão Geral e Contexto do Problema

Durante gravações de tela e ajustes dos botões físicos de volume em dispositivos Android, o jogo apresentava quedas bruscas para 15 FPS, pausas involuntárias no meio da partida, micro-travamentos por gravação síncrona em disco, chamadas JNI redundantes em segundo plano, oscilações de buffer no motor de áudio e conflitos de entrada tátil no joystick virtual.

O diagnóstico na base de código revelou 5 causas combinadas disparadas quando o Android exibe overlays passageiros do sistema (`VolumeDialog`, contador/bolha flutuante de gravação de tela ou captura de áudio interno):

1. **`GameManager` (`NOTIFICATION_APPLICATION_FOCUS_OUT`):** Tratava perda temporária de foco de janela causada por overlays de sistema da mesma forma que minimização real, reduzindo o teto para `FPS_BACKGROUND` (`15 FPS`) e pausando a partida, além de não limitar picos de `delta` do cronômetro durante o início do codificador de vídeo.
2. **`SaveManager` (`NOTIFICATION_APPLICATION_FOCUS_OUT`):** Executava `save_game()` síncrono na main thread (gravação de `.tmp`, cópia `.bak` e substituição de `.json`) toda vez que um overlay de volume ou gravação aparecia.
3. **`SettingsModal` (`NOTIFICATION_APPLICATION_FOCUS_IN`):** Mesmo oculto/fechado (`visible == false`), executava consultas JNI via `JavaClassWrapper` ao `Settings.System` do Android toda vez que o foco retornava após fechar a barra de volume.
4. **`AudioManager` (`update_engine_speed`):** Reatribuía `pitch_scale` e `volume_db` a 60 Hz mesmo em velocidade estável, gerando trabalho redundante no `AudioServer` durante captura de áudio interno (`AudioPlaybackCapture`) e rampas de volume do Android.
5. **`FloatingJoystick` e `MenuGestureDetector`:** Escutavam eventos sintéticos de mouse (`emulate_mouse_from_touch`) junto com os eventos nativos de touch no mobile e não resetavam o estado ativo caso um overlay do SO interceptasse o evento de soltura do dedo.

---

## 2. Modificações Implementadas

### 2.1 Ciclo de Vida Inteligente e Proteção de Delta (`scripts/core/game_manager.gd`)
- Em `_notification(what)`: no Android (`OS.has_feature("android")`), a auto-pausa e a redução para `FPS_BACKGROUND` (15 FPS) passam a responder estritamente a `NOTIFICATION_APPLICATION_PAUSED`, ignorando `NOTIFICATION_APPLICATION_FOCUS_OUT` isolado de overlays de volume/gravação. Em Desktop/Web, o comportamento original foi mantido integralmente.
- Em `_process(delta)`: o desconto no relógio da fase usa `var safe_delta: float = minf(delta, 0.1)`, protegendo o tempo restante contra eventuais picos de frame na inicialização de gravadores de tela.

### 2.2 Persistência Resiliente Sem Stutter em Overlays (`scripts/core/save_manager.gd`)
- Adicionada variável `_last_lifecycle_save_msec: int = -1000`.
- Em `_notification(what)`: no Android, `NOTIFICATION_APPLICATION_FOCUS_OUT` isolado é ignorado; o salvamento automático em `NOTIFICATION_APPLICATION_PAUSED` utiliza debounce de `500ms` para evitar gravações duplicadas no mesmo ciclo de suspensão, mantendo `NOTIFICATION_WM_CLOSE_REQUEST` e chamadas explícitas a `save_game()` sempre imediatas.

### 2.3 Eliminação de JNI Ocioso em Background (`scripts/ui/settings_modal.gd`)
- Em `_notification(NOTIFICATION_APPLICATION_FOCUS_IN)`: retorno antecipado imediato quando `not visible and not _waiting_for_android_haptic_toggle`.
- No `_ready()`, `android_vib_hint_btn.visible` já inicia sincronizado com `not system_haptic_on`; em `open_modal()`, `_update_toggle_visuals()` é chamado após `visible = true`, e `_update_toggle_visuals()` só consulta `_is_android_haptic_feedback_enabled()` quando `visible` for `true`.

### 2.4 Deadband de Modulação do Motor (`scripts/core/audio_manager.gd`)
- Em `update_engine_speed(speed_ratio)`: aplicadas bandas mortas de `0.005` para `pitch_scale` e `0.08 dB` para `volume_db`, interpolando suavemente durante acelerações/desacelerações e cravando no valor alvo sem reatribuições redundantes no `AudioServer` quando a velocidade estabiliza.

### 2.5 Blindagem de Toque Mobile (`scripts/ui/floating_joystick.gd`, `scripts/menu/menu_gesture_detector.gd`, `scripts/menu/main_menu.gd`)
- `FloatingJoystick` passa a detectar `_is_mobile` via `mobile`, `android` ou `ios`, ignora `InputEventMouseButton` e `InputEventMouseMotion` no mobile e reseta o joystick ativo em `_notification()` ao receber `NOTIFICATION_APPLICATION_PAUSED`, `NOTIFICATION_APPLICATION_FOCUS_OUT` ou `NOTIFICATION_WM_WINDOW_FOCUS_OUT`.
- `MenuGestureDetector` descarta eventos sintéticos de mouse no mobile, e `MainMenu._notification()` chama `_gesture_detector.reset()` ao perder foco ou pausar o app.

---

## 3. Arquivos Modificados e Documentação Atualizada

| Arquivo | Alteração |
| :--- | :--- |
| `scripts/core/game_manager.gd` | Diferenciação Android `APPLICATION_PAUSED` vs `FOCUS_OUT` e clamp `minf(delta, 0.1)` no timer. |
| `scripts/core/save_manager.gd` | Ignora `FOCUS_OUT` no Android e aplica debounce de `500ms` nas notificações de ciclo de vida. |
| `scripts/ui/settings_modal.gd` | Pula JNI em `FOCUS_IN` quando oculto e atualiza toggle visual ao abrir modal. |
| `scripts/core/audio_manager.gd` | Deadband em `update_engine_speed()` com convergência limpa para o alvo. |
| `scripts/ui/floating_joystick.gd` | Descarte de mouse sintético no mobile e auto-reset em perda de foco/pausa. |
| `scripts/menu/menu_gesture_detector.gd` | Descarte de mouse sintético no mobile. |
| `scripts/menu/main_menu.gd` | Reset defensivo do `_gesture_detector` em perda de foco/pausa. |
| `scripts/core/game_version.gd`, `project.godot`, `export_presets.cfg` | Bump SemVer `0.12.205-alpha` (`version/code=1405`). |
| `docs/05_arquitetura_e_desenvolvimento/PORTABILIDADE_ANDROID.md` | Documentação da distinção de overlays, clamp de delta e JNI sob demanda. |
| `docs/05_arquitetura_e_desenvolvimento/SISTEMA_DE_SAVE.md` | Documentação dos gatilhos no Android e debounce de ciclo de vida. |
| `docs/04_sistemas_e_gameplay/SISTEMA_DE_CONTROLES_TOUCH.md` | Documentação do descarte de mouse sintético e reset em perda de foco. |
| `docs/04_sistemas_e_gameplay/SISTEMA_DE_AUDIO_E_SFX.md` | Documentação do deadband em `update_engine_speed()`. |

---

## 4. Testes e Validação (Headless CLI)

Executados após a edição final com código de retorno `0` e **0 warnings GDScript**:
- `res://tests/test_android_lifecycle_and_navigation.tscn` — Aprovado (auto-pausa, safe area, botão voltar no HUD e menu).
- `res://tests/test_save_manager.tscn` — Aprovado (defaults, settings/locale, estrelas, persistência e recuperação `.bak`).
- `res://tests/test_save_and_load_roundtrip.tscn` — Aprovado (roundtrip completo JSON e `LevelEditor`).
- `res://tests/test_audio_manager.tscn` — Aprovado (barramentos, 22 recursos, throttling, motor contínuo, músicas e mute).
- `res://scenes/main.tscn` (`--headless --quit`) — Carregamento limpo sem warnings ou vazamentos.
