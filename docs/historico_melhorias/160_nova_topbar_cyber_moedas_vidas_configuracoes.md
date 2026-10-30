# Melhoria 160: Nova TopBar Cyber com Badges de Moedas, Vidas e Configurações 🪙❤️⚙️

## 📋 Resumo da Solicitação
O usuário solicitou a recriação da barra superior (**TopBar**) do menu principal no estilo visual Cyber/Arcade das referências conceituais:
- Badges chamfrados para **Moedas** e **Vidas** no canto esquerdo.
- Cada badge possui um botão `+` violeta neon integrado que, ao ser tocado, navega diretamente para a aba **Loja** (`Store`).
- No lado oposto (canto direito), o botão de **Configurações** foi recriado com formato chanfrado octogonal assimétrico em estilo chip cyber, abrindo o modal de configurações (`SettingsModal`).
- Remoção do antigo rótulo de título no topo para manter a composição limpa e com visão desobstruída da ilha e do robô.

---

## 🛠️ Arquitetura e Implementação Técnica

### 1. Átomos (Atoms)
- **`assets/ui/topbar/badge_coin_bg.svg`**:
  - Cápsula chamfrada em dark navy com corte nos cantos superior-esquerdo e inferior-direito, contorno contínuo ciano luminoso (`#2bd9fe`).
- **`assets/ui/topbar/badge_life_bg.svg`**:
  - Placa dark com corte inclinado tipo paralelogramo/chevron à direita e borda azul-violeta elétrica (`#46a0fc` a `#8852ff`).
- **`assets/ui/topbar/btn_plus_square.svg` & `btn_plus_square_pressed.svg`**:
  - Botão quadrado arredondado em tom violeta índigo (`#4e35ab` a `#24165e`) com símbolo `+` em branco nítido. Na versão pressed, o símbolo desloca-se 2px com iluminação mecânica suave.
- **`assets/ui/topbar/btn_settings_cyber.svg` & `btn_settings_cyber_pressed.svg`**:
  - Botão octogonal chamfrado em estilo chip cyber com engrenagem tridimensional em relevo branco/aço.

### 2. Molécula: `CyberResourceBadge` (`scenes/ui/cyber_resource_badge.tscn` + `scripts/ui/cyber_resource_badge.gd`)
- Componente modular configurável com propriedades exportadas:
  - `icon_texture`, `bg_texture`, `initial_text`.
- Sinal customizado: `signal plus_pressed`.
- Feedback háptico de 15ms (`Input.vibrate_handheld(15)`) e áudio de confirmação (`AudioManager.play_sfx("confirm")`).

### 3. Organismo: `TopBar` em `scenes/menu/main_menu.tscn` & `scripts/menu/main_menu.gd`
- Layout unificado em `MarginContainer` sem sobrecarregar o topo.
- `CoinBadge` sincronizado reativamente com o `UpgradeManager.total_coins` e `UpgradeManager.coins_changed`.
- `LifeBadge` exibindo vidas atuais (ex: `5 Max`).
- Ambos os botões `+` conectados ao método `_on_badge_plus_pressed()`, alternando instantaneamente para a aba Loja (`bottom_nav.select_tab(3)`).
- `SettingsButton` acionando o `settings_modal.open_modal()`.

---

## 📸 Validação Visual em Tempo de Execução
- Captura de tela gerada com o motor Godot 4.7 (`topbar_preview.png`) confirmando fidelidade milimétrica com a arte de referência.
- Teste funcional de navegação para a Loja via botão `+` executado com sucesso (aba 3 ativada automaticamente).
- 0 warnings no console da Godot.

---

## 📦 Versionamento SemVer
- Versão incrementada para `0.12.90-alpha` (PATCH +1) em `project.godot`, `game_version.gd` e `export_presets.cfg`.
