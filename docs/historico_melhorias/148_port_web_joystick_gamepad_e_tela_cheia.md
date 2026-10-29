# Melhoria 148: Port Web (HTML5/Wasm), Tela Cheia Responsiva & Suporte a Joystick/Gamepad Físico 🌐🕹️

**Data:** 2026-10-29  
**Versão:** `v0.12.74-alpha`  
**Status:** Concluído com Sucesso ✅  
**Autor:** Antigravity AI  

---

## 1. Contexto e Motivação
Com o sucesso da jogabilidade mobile de **Grass Cut Bot**, surgiu a demanda de viabilizar um port oficial para Web (HTML5/WebAssembly) capaz de rodar diretamente em navegadores desktop e mobile, permitindo:
1. Jogabilidade com controles físicos (Gamepads Xbox, PlayStation, 8BitDo e genéricos via USB/Bluetooth) no PC e navegadores.
2. Formato de tela responsivo: preservação do formato celular vertical (9:16) centralizado com pillarbox elegante na Web de PC e tela cheia completa no mobile.
3. Alternância para Tela Cheia nativa do navegador via atalhos de teclado (`F11` / `Alt + Enter`).
4. Compatibilidade universal de hospedagem estática (sem exigência de cabeçalhos de isolamento de threads COOP/COEP).

---

## 2. Alterações Realizadas

### A. Suporte a Gamepad e Joystick Físico (`scripts/ui/floating_joystick.gd`)
- Adicionada leitura dos eixos do analógico esquerdo (`JOY_AXIS_LEFT_X`, `JOY_AXIS_LEFT_Y`) com deadzone configurada em `0.15` para proteção contra drift.
- Adicionada leitura alternativa do D-Pad direcional (`JOY_BUTTON_DPAD_*`).
- Integração transparente com o loop de movimentação do robô (`cutter.gd`), mantendo fallback ordenado: Toque/Mouse -> Gamepad Analógico/D-Pad -> Teclado WASD/Setas -> Repouso.

### B. Gerenciamento de Tela Cheia & Autoload (`scripts/core/game_manager.gd`)
- Implementado método `toggle_fullscreen()` via `DisplayServer.window_set_mode()`.
- Captura de eventos de tecla em `_unhandled_input()` para `KEY_F11` e `Alt + KEY_ENTER`, acionando a Fullscreen API do navegador na Web e tela cheia exclusiva/borderless no Desktop.

### C. Configurações de Renderização e Janela (`project.godot`)
- Adicionado override de renderizador para Web:
  ```ini
  [rendering]
  renderer/rendering_method="mobile"
  renderer/rendering_method.web="gl_compatibility"
  ```
- Adicionado override de aspecto para Web:
  ```ini
  [display]
  window/stretch/aspect="keep_width"
  window/stretch/aspect.web="keep"
  ```
  Isso mantém o comportamento flexível em smartphones enquanto na Web centraliza perfeitamente o formato 9:16 vertical com pillarbox lateral limpo.

### D. Preset Oficial de Exportação Web (`export_presets.cfg`)
- Configurado `[preset.1]` para a plataforma `Web` (HTML5/Wasm).
- Definido `variant/thread_support = false` (Single-Threaded) e `progressive_web_app/ensure_cross_origin_isolation_headers = false`, garantindo compatibilidade imediata com qualquer servidor (GitHub Pages, itch.io, Netlify, Vercel).
- Configurado `html/canvas_resize_policy = 2` (Adaptativo).

### E. Detecção Dinâmica de Edição na Interface (`scripts/ui/settings_modal.gd`)
- O rodapé do modal de configurações agora exibe dinamicamente `v0.12.74-alpha • Web Edition` quando executado na Web, `PC Edition` no desktop ou `Mobile Edition` no Android.

---

## 3. Validação e Testes
- **Headless Check:** Executado `godot_console.exe --headless --check-only` com 0 warnings e 0 erros.
- **Headless Import:** Executado `godot_console.exe --headless --import` com regeneração atômica completa dos recursos.
- **Exportação Web de Produção:** Build release executada com sucesso gerando os artefatos `index.html`, `index.js`, `index.pck` (31.8 MB) e `index.wasm` (39.5 MB) em `build/web/`.
