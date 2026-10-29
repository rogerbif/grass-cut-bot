# Melhoria 158: Recriação do Botão Cyber de Mapa na Tela Home 🗺️🤖

## 📋 Resumo da Solicitação
O usuário solicitou a recriação do botão de **Mapa** (`ToggleViewBtn`) na tela inicial (Home) no mesmo estilo cyber/arcade do botão de Jogar Fase:
- Reaproveitar a estética geométrica do botão de Jogar com corte angular à esquerda e ponta chevron à direita.
- Cor alterada para azul elétrico / ciano vibrante com base 3D em azul cobalto profundo.
- Formato mais estreito e compacto do que o botão de Jogar, perfeitamente dimensionado para a palavra "MAPA" e o ícone.
- Manter o ícone canônico de mapa dobrado com marcador de localização e o lado esquerdo com bracket cyber destacado.
- Preservação da compressão física tátil: ao pressionar o botão, a moldura cibernética externa permanece 100% estática enquanto o corpo interno afunda 7px.

---

## 🛠️ Arquitetura e Implementação Técnica

### 1. Criação dos Assets Vetoriais SVG (`assets/ui/`)
- **`btn_map_banner.svg`**:
  - Dimensões calibradas em `width="260" height="138" viewBox="0 10 260 138"`.
  - Gradiente superior do botão em ciano/azul elétrico (`#02f0ff` a `#007afc`).
  - Base 3D extrudada em azul cobalto profundo (`#0e78fe` a `#0242a6`) com linha de sombra (`#022464`).
  - Lens flare / glint central na borda inferior da lâmina em ciano e branco puro.
  - Bracket cibernético angular inferior esquerdo (`#07212e`) com linha neon ciano (`#00f5ff`, stroke-width=4).
  - Placa cyber de topo e chevron direito em navy escuro contornado por traços neon ciano.
- **`btn_map_banner_pressed.svg`**:
  - Moldura cibernética estática em coordenadas 100% idênticas às do estado normal.
  - Rebaixo mecânico do corpo da face azul e da base 3D em 7px para baixo (`y += 7`), simulando afundamento e compressão.

### 2. Criação do Ícone Vetorial de Mapa Canônico (`assets/icons/icon_map_banner.svg`)
- Vetor SVG de alta nitidez com mapa dobrado em perspectiva 3D e marcador de localização (*teardrop pin*) com orifício transparente vazado (`fill-rule="evenodd"`), traço escuro navy (`#061a29`, stroke-width=4.5) perfeitamente alinhado com a referência conceitual.
- Bounding box limpo (`viewBox="10 3 38 51"`), eliminando margens vazias e garantindo destaque visual.

### 3. Componente Dinâmico e Controle GDScript (`scripts/ui/cyber_toggle_button.gd`)
- Classe global `CyberToggleButton` (Button):
  - Conecta reativamente a `button_down`, `button_up` e `pressed`.
  - Alterna entre `BgNormal` e `BgPressed`.
  - Translada o container de conteúdo `HBoxToggle` em `+7px` no eixo Y ao pressionar e `-7px` ao soltar.
  - Emite feedback tátil háptico (`Input.vibrate_handheld(15)`) e áudio de confirmação (`AudioManager.play_sfx("confirm")`).
  - Métodos utilitários: `set_toggle_text(new_text)` e `set_toggle_icon(tex)`.

### 4. Integração na Cena `tab_home.tscn` e Script `tab_home.gd`
- Layout unificado em `BottomAction/HBox`:
  - `PlayBtn`: `custom_minimum_size = Vector2(415, 135)`.
  - `ToggleViewBtn`: `custom_minimum_size = Vector2(254, 135)`.
  - Ambos com altura uniforme de 135px, centralizados com espaçamento de 12px dentro da largura portrait de 720px.
- Em `HBoxToggle`:
  - `ToggleLabel`: Tipografia em negrito 900 (`SystemFont_button`), tamanho 28, cor branca pura (`#ffffff`) com sombra suave inferior (`Color(0, 0, 0, 0.35)`).
  - `ToggleIcon`: Textura `icon_map_banner.svg`, tamanho mínimo de 30x34.
- Em `scripts/menu/tabs/tab_home.gd`:
  - Atualizado para exibir o texto `"MAPA"` com o novo ícone `ICON_MAP = preload("res://assets/icons/icon_map_banner.svg")` no modo ilha, e alternar para `"BOT"` no modo mapa.

---

## 📸 Validação Visual e Qualidade
- **Zero Warnings Estrito (Mandamento 1):** Projeto compilou com 0 avisos no console Godot.
- **Importação Atômica:** Executado `godot --headless --editor --quit` gerando cache de importação binária `.scn` para todos os novos SVGs.
- **Captura de Tela em Tempo de Execução:** Validação realizada com screenshot nos estados normal e pressionado via Forward Mobile renderer (`bottom_bar_preview.png` e `bottom_bar_pressed_preview.png`).

---

## 📦 Versionamento SemVer
- Versão incrementada de `0.12.87-alpha` para `0.12.88-alpha` (PATCH +1) em:
  - `project.godot`
  - `scripts/core/game_version.gd`
  - `export_presets.cfg`
