# Melhoria 158: Verificação de Conformidade e Preparação Integral para Port Web (HTML5/WebAssembly)

## 📌 Contexto & Motivação
Revisão completa de todos os parâmetros técnicos, de performance, renderização, metadados e distribuição necessários para a publicação do **Grass Cut Bot** na Web (itch.io, GitHub Pages, portais de jogos casuais como Poki e CrazyGames ou hospedagem estática própria).

---

## 🛠️ Itens Verificados e Preenchidos

### 1. Renderizador Web Universal (`project.godot`)
- **Problema:** O projeto operava com `renderer/rendering_method="mobile"` globalmente, sem o override canônico para navegadores.
- **Correção:** Adicionado o override:
  ```ini
  renderer/rendering_method="mobile"
  renderer/rendering_method.web="gl_compatibility"
  ```
- **Impacto:** Garante que a compilação Web utilize WebGL2 / OpenGL ES 3.0 em qualquer navegador moderno (Chrome, Firefox, Safari, Edge) tanto em PC quanto em smartphones, sem falhas de driver Vulkan. Testado em 100 frames headless com `--rendering-driver opengl3` com 0 erros.

### 2. Cabeçalhos de Isolamento e Modo Single-Threaded (`export_presets.cfg`)
- **Problema:** A opção `progressive_web_app/ensure_cross_origin_isolation_headers` estava configurada como `true` no preset Web, apesar do jogo operar em modo Single-Threaded (`variant/thread_support=false`). Isso injetava scripts desnecessários que forçavam isolamento de thread e quebravam a execução dentro de iframes (como o player embutido do itch.io).
- **Correção:** Alterado para `false`. Agora o jogo roda de forma 100% estática e livre de restrições em qualquer servidor (itch.io, Vercel, Netlify, GitHub Pages) sem requerer cabeçalhos COOP/COEP especiais.

### 3. Metadados de SEO, Open Graph e Mobile Web App (`web_shell/shell.html`)
- Preenchidas tags cruciais na seção `<head>`:
  - `<meta name="description" ...>` com resumo e USP do jogo.
  - `<meta name="theme-color" content="#0b141d">` para integração estética com a barra de navegação/status do Chrome Android e Safari iOS.
  - `<meta name="mobile-web-app-capable" content="yes">` e `<meta name="apple-mobile-web-app-capable" content="yes">` para execução em tela cheia suave como web app.
  - Open Graph (`og:title`, `og:description`, `og:type`, `og:image`) para pré-visualização enriquecida ao compartilhar links em redes sociais, Discord e WhatsApp.

### 4. Compatibilidade de Hospedagem e Distribuição
- **GitHub Pages:** Adicionado arquivo `.nojekyll` em `build/web/`.
- **itch.io e Portais:** Gerado pacote compactado `build/grass-cut-bot-web.zip` com `index.html` na raiz, pronto para upload direto na plataforma.
- **Persistência de Save:** O `SaveManager` mapeia automaticamente `user://savegame.json` para o IndexedDB do navegador.
- **Controles Híbridos:** Joystick touch virtual, WASD no teclado, e suporte completo a Gamepads USB/Bluetooth via HTML5 Gamepad API.

---

## 🏷️ Versão & Validação
- **Game SemVer:** Incrementado para `v0.12.86-alpha`.
- **Godot Headless OpenGL3 Test:** 0 warnings e 0 erros.
- **Exportação Web:** Atualizada com sucesso em `build/web/` e compactada em `build/grass-cut-bot-web.zip`.
