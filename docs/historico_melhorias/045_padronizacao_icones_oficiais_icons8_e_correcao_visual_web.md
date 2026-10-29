# 045 - Padronização de Ícones Oficiais Icons8, Correção Visual e Ajustes Web

**Data:** 29 de Outubro de 2026  
**Versão:** `v0.12.78-alpha`  
**Escopo:** Interface & HUD, Arte Vetorial (SVG/ThorVG), Portabilidade Web & Mobile

---

## 1. Contexto & Objetivos

Durante a execução na Web e testes visuais com o novo shell, identificou-se que:
1. O saldo de moedas utilizava a etiqueta de preço verde (`price_tag_usd`) ao invés de uma moeda de ouro.
2. O botão de configurações no TopBar exibia um velocímetro (`dashboard`) ao invés de uma engrenagem/gear.
3. O botão de MAP apresentava um alfinete (`pin.svg`) excessivamente grande que ocupava quase toda a altura do botão.
4. O badge de energia/vidas mostrava uma lâmina/ventilador ao invés de um coração (`heart`).
5. A aba Garage na barra inferior utilizava uma maleta ao invés de uma ferramenta mecânica de oficina (`wrench`).
6. Textos nos modais de oficina e configurações ainda continham emojis Unicode (`🪙`, `📳`, `💾`, `🗑️`, `🔄`) que geravam caracteres tofu ("01F527", etc.) na WebAssembly.

---

## 2. Implementações Realizadas

### A. Integração de SVGs Canônicos Oficiais Icons8
Foram baixados e integrados do repositório oficial [icons8/flat-color-icons](https://github.com/icons8/flat-color-icons):
- **Configurações (`icon_gear.svg`):** Engrenagem mecânica clássica de 8 dentes em ardósia/cinza (`#607D8B` e `#455A64`).
- **Vidas / Energia (`icon_heart.svg`):** Coração vermelho vibrante (`#F44336`), do asset canônico `like.svg`.
- **Garage (`icon_wrench.svg`):** Chave mecânica de boca/inglesa em aço fosco (`#607D8B`), do asset `support.svg`.
- **MAP (`icon_map.svg`):** Mapa dobrado em 3 painéis (`#AED581`, `#8BC34A`, `#7CB342`) com alfinete de localização integrado (`#D32F2F`) e dimensionamento refinado no botão (`icon_max_width = 26`, `expand_icon = false`).
- **Saldo de Moedas (`icon_coin.svg`):** Moeda circular dourada em alta resolução vetorial na paleta canônica Icons8 (`#FFA000`, `#FFC107`, `#FFD54F`, `#E65100`).
- **Assets Adicionais Importados:** `icon_globe.svg`, `icon_speaker.svg`, `icon_music.svg`, `icon_shop.svg`, `icon_cancel.svg`, `icon_checkmark.svg` e `icon_refresh.svg`.

### B. Ajustes nas Cenas e Scripts
- `scenes/menu/main_menu.tscn`:
  - `CoinsContainer`: Utiliza o novo `icon_coin.svg`.
  - `EnergyContainer`: Substituída a lâmina pelo `icon_heart.svg` (coração).
  - `SettingsButton`: Utiliza `icon_gear.svg` (engrenagem).
- `scenes/menu/tabs/tab_home.tscn` & `scripts/menu/tabs/tab_home.gd`:
  - `ToggleViewBtn`: Definido `expand_icon = false` e `icon_max_width = 26` para manter o ícone de mapa em tamanho equilibrado e elegante.
- `scenes/menu/bottom_nav_bar.tscn`:
  - `BtnGarage`: Atualizado com a ferramenta mecânica `icon_wrench.svg`.
- `scripts/ui/hud.gd`:
  - Removido o caractere `🪙` do modal da oficina (`CoinsBanner` e `BuyBtn`), garantindo texto limpo.
- `scripts/ui/settings_modal.gd`:
  - Removidos todos os emojis restantes de vibração, salvamento, confirmação e reset (`📳`, `💾`, `🗑️`, `🔄`).

---

## 3. Validação & Verificação

1. **Importação Headless:**
   - Executado `godot_console.exe --headless --import` com sucesso absoluto: **0 erros e 0 warnings**.
2. **Compilação Web:**
   - Gerado pacote Web com sucesso em `build/web/index.html` via `godot_console.exe --headless --export-release "Web" "build/web/index.html"`.
