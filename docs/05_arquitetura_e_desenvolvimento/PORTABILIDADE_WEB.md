# Portabilidade e Otimização para Web (HTML5 / WebAssembly) 🌐🚀

Este documento reúne os requisitos técnicos, presets de exportação e diretrizes de execução suave de **Grass Cut Bot** no ecossistema Web moderno (Navegadores desktop e mobile).

---

## 1. Arquitetura de Renderização e WebGL2

- **Renderizador Canônico (`gl_compatibility`):**
  - Configurado via override dinâmico em `project.godot`:
    ```ini
    renderer/rendering_method="mobile"
    renderer/rendering_method.web="gl_compatibility"
    ```
  - Enquanto o APK Android utiliza a API Vulkan Mobile de alta performance (pipeline Linear + ACES Tonemap), a compilação Web utiliza automaticamente WebGL2 / OpenGL ES 3.0 (`OUTPUT_IS_SRGB == true`).
  - **Paridade Visual e Cromática 1:1 (Isolada por Backend):**
    - Nos shaders (`toon_water.gdshader`, `interactive_grass.gdshader`, `interactive_flower.gdshader`, `lawn_base_decal.gdshader`), blocos condicionais `if (OUTPUT_IS_SRGB)` decodificam texturas de ruído (`sRGB -> Linear`) e compensam a ausência do ACES Tonemap no WebGL2 sem tocar em 1 único pixel do pipeline Mobile (`!OUTPUT_IS_SRGB`).
    - Em `IslandMeshBuilder`, `cutter.gd` e `menu_bot.gd`, a calibração de cores de vértice/superfície para `gl_compatibility` garante que o solo (`#30C34A`), a falésia (`#F2AA64`) e o aço da lâmina (`#868C8C`) sejam idênticos à versão Mobile.
- **CPUParticles3D Otimizadas:**
  - O pool estático de partículas (`CPUParticles3D`) em `plant.gd` evita o uso de compute shaders ou transform feedback exigentes do WebGL2, garantindo 60 FPS estáveis mesmo em navegadores modestos.

---

## 2. Proporção de Tela, Responsividade e Tela Cheia (Fullscreen)

- **Modo Retrato Centralizado (Pillarbox Elegante):**
  - `window/stretch/mode = "canvas_items"`
  - `window/stretch/aspect.web = "keep"` (enquanto no Android opera com `keep_width`).
  - No navegador em computadores (telas widescreen 16:9), a janela de 720x1280 do jogo é centralizada com margens pretas limpas nas laterais, preservando a experiência estética e tátil original de mobile casual (padrão de portais como Poki, CrazyGames e itch.io).
- **Atalho e Alternância de Tela Cheia:**
  - O jogador pode alternar para tela cheia nativa a qualquer momento pressionando **`F11`** ou **`Alt + Enter`**.
  - O runtime do Godot invoca a Fullscreen API do navegador (`DisplayServer.window_set_mode()`), ocultando abas e barra de tarefas.

---

## 3. Controles Físicos (HTML5 Gamepad API)

- O Godot 4 mapeia nativamente a **Gamepad API** dos navegadores.
- `floating_joystick.gd` processa:
  - Analógico esquerdo (`JOY_AXIS_LEFT_X`, `JOY_AXIS_LEFT_Y`) com deadzone de `0.15`.
  - D-Pad direcional (`JOY_BUTTON_DPAD_*`).
  - Suporte imediato a controles Xbox, PlayStation, Nintendo Switch e controles genéricos USB/Bluetooth plugados no PC.

---

## 4. Persistência de Save via IndexedDB

- O `SaveManager` grava o progresso em `user://savegame.json`.
- Na Web, o runtime do Emscripten mapeia o sistema de arquivos virtual `user://` automaticamente para o **IndexedDB** do navegador.
- As moedas, upgrades e fases desbloqueadas persistem permanentemente entre abas e recarregamentos de página sem necessidade de backend externo.

---

## 5. Preset de Exportação Single-Threaded

- **Configuração no `export_presets.cfg` (`[preset.1]`):**
  - `variant/thread_support = false`
  - `progressive_web_app/ensure_cross_origin_isolation_headers = false`
- **Vantagem Estrutural:** Não exige cabeçalhos COOP (`Cross-Origin-Opener-Policy: same-origin`) nem COEP (`Cross-Origin-Embedder-Policy: require-corp`), permitindo hospedagem imediata em qualquer servidor web estático (GitHub Pages, itch.io, Vercel, Netlify, Apache, Nginx).

---

## 6. Ícones SVG e Tela de Loading

- **Nunca use emojis em `Label`/`Button` para a UI:** na Web as fontes de emoji do sistema não existem e o texto vira caixas hexadecimais ("tofu"). Use os SVGs de `assets/icons/` via `TextureRect` ou `Button.icon`.
- **Loading customizado:** `web_shell/shell.html` (preset Web, `html/custom_html_shell`) exibe logo, barra de progresso com porcentagem real e dicas, com fade-out ao iniciar. Mantenha os placeholders `$GODOT_URL`, `$GODOT_CONFIG`, `$GODOT_PROJECT_NAME` e `$GODOT_HEAD_INCLUDE`.

---

## 7. Pipeline de Publicação Automatizada no itch.io (Butler CLI)

O itch.io utiliza a ferramenta oficial **Butler CLI** para envio contínuo e atualizações binárias (`wharf`).

- **Canal Canônico:** `html5` (WebAssembly jogável no navegador).
- **Slug Oficial:** `bifgames/grass-cut-bot`.
- **URL Pública:** [`https://bifgames.itch.io/grass-cut-bot`](https://bifgames.itch.io/grass-cut-bot).
- **Instalação do Butler:**
  ```powershell
  .\scripts\tools\setup_butler.ps1
  butler login   # Executar uma única vez para autorizar a conta
  ```
- **Comandos de Deploy:**
  - Envio direto exclusivo para itch.io:
    ```powershell
    .\scripts\tools\publish_itch.ps1
    ```
  - Envio integrado via pipeline mestre com bump SemVer:
    ```powershell
    .\publish.ps1 -Target Itch -Bump Patch
    ```
  - Envio simultâneo para Google Play + itch.io:
    ```powershell
    .\publish.ps1 -Target All -Bump Patch
    # Ou o atalho com switch:
    .\publish.ps1 -Itch
    ```
- **Configuração no Painel do itch.io:**
  - Kind of project: **HTML**.
  - No canal `html5`, a build Web é automaticamente marcada para execução direta no navegador.
  - Viewport recomendada: Dimensões fixas ou responsivas orientadas ao modo retrato (`720x1280` ou ratio 9:16).
