# Melhoria 149: Ícones SVG Nativos & Tela de Loading Personalizada na Web 🎨⏳

**Data:** 2026-10-29  
**Versão:** `v0.12.76-alpha`  
**Status:** Concluído ✅

---

## 1. Problema
- Na Web, emojis em `Label` apareciam como caixas com código hexadecimal (ex.: `01F527`), pois a sandbox WebAssembly não acessa as fontes de emoji do sistema.
- O download de ~65 MB (`.pck` + `.wasm`) exibia apenas a barra cinza padrão da Godot, sem feedback.

## 2. Solução

### Ícones vetoriais SVG (`assets/icons/`)
`icon_coin`, `icon_blade`, `icon_wrench`, `icon_home`, `icon_leaf`, `icon_store`, `icon_gear`, `icon_play`, `icon_map`, `icon_star`, `icon_pause`, `icon_restart`, `icon_heart`, `icon_wheat`, `icon_flower`.

Substituições de emoji por `TextureRect`/`Button.icon`:
- `bottom_nav_bar.tscn`: Oficina, Home, Coleção e Loja.
- `main_menu.tscn`: moeda, lâmina (energia) e engrenagem de configurações.
- `tab_home.gd`: botões Play e Mapa (ícones via código).
- `hud.tscn` / `hud.gd`: moeda, botão de pausa e cards de metas (folha tingida por cor, trigo, flor).
- Textos de modais, abas e configurações limpos de emojis (`settings_modal.gd/.tscn`, `tab_*.tscn`, `island_node.gd`).

### Custom HTML Shell (`web_shell/shell.html`)
- Tela de loading com ícone do jogo pulsando, barra de progresso esmeralda com porcentagem real (`onProgress`), dica de controles (WASD/gamepad/F11) e fade-out ao iniciar.
- Vinculado em `export_presets.cfg` (`html/custom_html_shell="res://web_shell/shell.html"`, `export_path="build/web/index.html"`).

## 3. Validação
- `godot_console --headless --import`: sem warnings/erros.
- `godot_console --headless --export-release "Web"`: build gerada; `index.html` contém o shell customizado.
- UIDs inválidos em `ext_resource` removidos (usam path de texto) para manter **0 warnings**.

## 4. Pendência de verificação visual
Confirmar no navegador (`build/web/index.html` via servidor local) os ícones nítidos e a tela de loading.
