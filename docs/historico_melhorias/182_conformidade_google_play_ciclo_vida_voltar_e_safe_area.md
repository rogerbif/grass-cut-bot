# Melhoria 182: Conformidade Google Play, Ciclo de Vida Android, Botão Voltar e Safe Area Dinâmica (`v0.12.129-alpha`) 📱🛡️

## 1. Contexto e Motivação
Como parte da preparação do **Grass Cut Bot** para publicação na **Google Play Store**, foi realizada uma auditoria técnica de conformidade com as diretrizes do *Google Play Core App Quality*. A experiência em dispositivos móveis Android exigia:
1. **Tratamento do Botão/Gesto Voltar (`NOTIFICATION_WM_GO_BACK_REQUEST`):** O jogo encerrava repentinamente ou ignorava o gesto do sistema ao navegar em modais, gameplay ou abas do menu.
2. **Pausa Automática na Perda de Foco:** Ao receber chamadas telefônicas ou alternar entre aplicativos, o cronômetro do gameplay continuava rodando, podendo gerar derrotas injustas em segundo plano.
3. **Respeito à Safe Area Dinâmica (Notches & Cutouts):** Compensação da barra superior (`TopBar`) em smartphones com entalhes e recortes de câmera frontal.

---

## 2. Ações e Implementações Realizadas

### A. Auto-Pausa do Gameplay em `scripts/core/game_manager.gd`
- Adicionado tratamento para as notificações do sistema operacional:
  - `NOTIFICATION_APPLICATION_PAUSED`
  - `NOTIFICATION_APPLICATION_FOCUS_OUT`
- Se a partida estiver ativa (`current_state == GameState.PLAYING`), `GameManager.toggle_pause()` é acionado automaticamente, pausando a árvore de cena (`get_tree().paused = true`), disparando o som e abrindo o modal de pausa.

### B. Hierarquia do Botão Voltar e Safe Area no Gameplay (`scripts/ui/hud.gd`)
- Implementada a função `_handle_back_request()` para `NOTIFICATION_WM_GO_BACK_REQUEST` e `ui_cancel` (teclado/gamepad):
  1. Se o modal da oficina estiver aberto: fecha o modal.
  2. Se o modal de pausa estiver aberto: retoma a partida (`toggle_pause`).
  3. Se em tela de vitória ou derrota: retorna ao menu principal (`main_menu.tscn`).
  4. Se a partida estiver em andamento: abre o menu de pausa.
- Implementado `_apply_safe_area()` que calcula a margem superior segura via `DisplayServer.get_display_safe_area()`, duplicando o `StyleBoxFlat` da barra superior e compensando o `content_margin_top` e `offset_bottom` sem quebrar o layout.

### C. Navegação do Botão Voltar e Câmera no Menu Principal (`scripts/menu/main_menu.gd` & `menu_camera.gd`)
- Implementada a hierarquia de retorno no menu:
  1. Se `SettingsModal` estiver aberto: aciona `close_modal()`.
  2. Se a câmera estiver na visão panorâmica do arquipélago 3D (`CameraMode.MAP_VIEW`): retorna suavemente à visão focada no robô (`switch_to_bot_view()`).
  3. Se estiver em aba secundária (Garagem, Coleção ou Loja): retorna à aba Home (índice 0).
  4. Se o modal de confirmação de saída (`ExitModal`) estiver aberto: fecha o modal (cancela a saída).
  5. Se já estiver na tela inicial do robô: abre o modal cyberpunk de confirmação (`ExitModal`) perguntando "SAIR DO JOGO?", com opções "CONTINUAR JOGANDO" (verde neon) e "SAIR DO APLICATIVO" (vermelho cyber que salva e encerra via `get_tree().quit()`).
- Em `menu_camera.gd`: habilitada a interrupção suave de transições ativas (`active_tween.kill()`) ao chamar `switch_to_bot_view()`, permitindo retorno imediato sem travas.
- Em `settings_modal.gd`: adicionada flag `_is_closing`, método `is_open() -> bool` e suporte a `ui_cancel` para cancelamento instantâneo.

---

## 3. Validação e Testes Automatizados
- Criada a suíte de testes `tests/test_android_lifecycle_and_navigation.tscn`:
  - **Auto-Pausa:** Validada a transição imediata para `GameState.PAUSED` e `get_tree().paused = true` em `NOTIFICATION_APPLICATION_PAUSED` e `NOTIFICATION_APPLICATION_FOCUS_OUT`.
  - **Safe Area:** Validado cálculo dinâmico de margem sem distorções no Viewport.
  - **Hierarquia HUD:** Validada a ordem estrita (Oficina -> Pausa -> Gameplay).
  - **Hierarquia Menu:** Validada a ordem estrita (Configurações -> Câmera Mapa -> Aba Secundária -> Home).
- Console Godot mantido com **0 warnings** e 100% dos testes aprovados.

---

## 4. Atualização Canônica e SemVer
- Versão incrementada para **`v0.12.129-alpha`** (Version Code: `1329`) em `project.godot`, `export_presets.cfg` e `scripts/core/game_version.gd`.
- `export_presets.cfg` atualizado com `package/name = "Grass Cut Bot"`.
- Documentação canônica atualizada em `docs/05_arquitetura_e_desenvolvimento/PORTABILIDADE_ANDROID.md`.
