# 046 - Revisão Geral de Iconografia de UI e Eliminação Total de Tofu

**Data:** 29 de Outubro de 2026  
**Versão:** `v0.12.79-alpha`  
**Escopo:** Interface & HUD, Arte Vetorial (SVG/ThorVG), Portabilidade Web & Mobile

---

## 1. Contexto & Objetivos

Após a primeira rodada de atualização de ícones, foi realizada uma auditoria exaustiva em todos os componentes de interface (`main_menu.tscn`, `bottom_nav_bar.tscn`, `tab_home.tscn`, `tab_garage.tscn`, `tab_collection.tscn`, `tab_store.tscn`, `hud.tscn` e `settings_modal.tscn`) para identificar:
1. Nós que usavam caracteres de texto ou símbolos crus no lugar de ícones (`$`, `+`, `✕`, `>`, `01F527`).
2. Botões em modais de jogo sem ícones ilustrativos.
3. Emojis Unicode residuais em código e cenas que causavam caracteres tofu na WebAssembly.

---

## 2. Implementações Realizadas

### A. HUD e Modais de Jogo (`scenes/ui/hud.tscn` & `scripts/ui/hud.gd`)
- **Estrelas da Vitória (`StarsArc`):**
  - Os nós `Star1`, `Star2` e `Star3` foram convertidos de `Label` (com texto Unicode `⭐`/`☆`) para `TextureRect` vinculados a `icon_star.svg`.
  - A animação no `hud.gd` agora modula a textura diretamente: estrelas conquistadas brilham em `Color(1, 1, 1, 1)` com escala pop-in suave e estrelas não conquistadas recebem tom de silhueta translúcida `Color(0.25, 0.32, 0.42, 0.45)`.
- **Botões do Menu de Pausa (`PauseModal`):**
  - "Continuar": Adicionado `icon_play.svg` com `icon_max_width = 22`.
  - "Reiniciar Fase": Adicionado `icon_refresh.svg` com `icon_max_width = 22`.
  - "Oficina": Adicionado `icon_wrench.svg` com `icon_max_width = 22`.
  - "Menu Inicial": Adicionado `icon_home.svg` com `icon_max_width = 22`.
- **Barra de Ações da Vitória (`VictoryModal/BottomBar`):**
  - "Menu": Adicionado `icon_home.svg`.
  - "Repetir": Adicionado `icon_refresh.svg`.
  - "Próxima Fase": Adicionado `icon_play.svg` alinhado à direita (`icon_alignment = 2`), eliminando o caractere cru `>`.
- **Modal de Derrota (`GameOverModal`):**
  - "Repetir Fase": Adicionado `icon_refresh.svg`.
  - "Menu Inicial": Adicionado `icon_home.svg`.
- **Oficina In-Game (`WorkshopModal`):**
  - Botões de compra dos 4 cards de upgrades atualizados para exibir o valor numérico com `icon_coin.svg` vetorial em vez de emoji `🪙`.
  - "Voltar ao Jogo": Adicionado `icon_play.svg`.

### B. Modal de Configurações (`scenes/ui/settings_modal.tscn`)
- **Botão Fechar (`CloseBtn`):** Substituído o texto `"✕"` pelo ícone vetorial oficial `icon_cancel.svg`.
- **Botões de Áudio e Feedback:**
  - `MusicBtn`: Adicionado `icon_music.svg`.
  - `SfxBtn`: Adicionado `icon_speaker.svg`.
  - `ResetBtn`: Adicionado `icon_refresh.svg`.

### C. Aba Loja (`scenes/menu/tabs/tab_store.tscn` & `scripts/menu/tabs/tab_store.gd`)
- **Bolsa de Moedas (`Pack1`):** Substituído o Label de texto `"$"` por `TextureRect` com `icon_coin.svg`.
- **Baú de Moedas (`Pack2`):** Substituído o Label de texto `"+"` por `TextureRect` com `icon_safe.svg` (cofre oficial Icons8).
- **Banner de Boas-Vindas:** Botão de resgate com `icon_coin.svg` e estado pós-coleta com `icon_checkmark.svg`, removendo o emoji `✔`.

### D. Aba Oficina / Garage (`scenes/menu/tabs/tab_garage.tscn` & `scripts/menu/tabs/tab_garage.gd`)
- **Saldo de Moedas:** Adicionado `TextureRect` com `icon_coin.svg` à esquerda de `CoinsValLabel`.
- **Botão de Compra (`BuyBtn`):** Exibe o custo com `icon_coin.svg` e quando maximizado exibe `icon_checkmark.svg`.
- **Textos:** Substituído o caractere de seta especial `➔` por `->`.

### E. Aba Coleção / Herbário (`scripts/menu/tabs/tab_collection.gd`)
- **Avatar das Espécies:** O Label que continha emojis botânicos (`🌱`, `🌾`, `🌼`, `❓`) foi substituído por `TextureRect` que carrega a silhueta vetorial correspondente (`icon_flower.svg`, `icon_wheat.svg`, `icon_leaf.svg`) colorida dinamicamente pela cor botânica canônica da espécie (`theme_col`).
- **Textos Limpos:** Removidos emojis `⭐`, `🔒`, `🪙`, `👑` de títulos de maestria e badges.

### F. Placas 3D (`clouds_end_node.tscn` & `island_node.tscn`)
- Removidos emojis `🔒☁️` da placa de final de mapa e `⭐⭐⭐` da placa base de ilhas.

---

## 3. Validação & Verificação

1. **Importação Headless:**
   - Executado `godot_console.exe --headless --import` com sucesso absoluto: **0 erros e 0 warnings**.
2. **Compilação Web:**
   - Gerado pacote Web atualizado em `build/web/index.html`.
