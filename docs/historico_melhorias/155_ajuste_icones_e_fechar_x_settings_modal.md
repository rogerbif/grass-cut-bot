# Melhoria 155: Ícone de Fechar (X) e Agrupamento Compacto no Modal de Configurações

## 📌 Contexto & Motivação
No modal de configurações (`SettingsModal`):
1. O botão de fechar utilizava anteriormente o ícone de proibido/cancelar (`icon_cancel.svg` com barra diagonal 🚫). O design exigia um 'X' vermelho limpo e nítido.
2. Os botões de alternância ("Música: ON", "Sons FX: ON") e de ação ("Resetar Progresso") possuíam espaçamento excessivo entre o ícone à esquerda e o texto centralizado, decorrente do layout nativo de botões na Godot em painéis largos.

---

## 🛠️ Alterações Implementadas

### 1. Novo Ícone de Fechar em 'X' (`icon_close.svg` & `icon_cancel.svg`)
- Criado o arquivo vetorial `assets/icons/icon_close.svg` em estilo Flat Color Icons com geometria de 'X' arredondada e moderna na cor vermelha (`#FF334B`).
- Atualizado o botão `CloseBtn` no cabeçalho do modal com fundo circular suave (`StyleBoxFlat_btn_close`) e `icon_max_width = 22`.

### 2. Agrupamento Centralizado Ícone + Label (`settings_modal.tscn` & `settings_modal.gd`)
- Em `MusicBtn`, `SfxBtn` e `ResetBtn`, a estrutura interna foi convertida para `HBoxContainer` centralizado (com `mouse_filter = MOUSE_FILTER_IGNORE`):
  - **Música:** Ícone de nota musical (`icon_music.svg`) a 10px do texto "Música: ON/OFF".
  - **Sons FX:** Ícone de alto-falante (`icon_speaker.svg`) a 10px do texto "Sons FX: ON/OFF".
  - **Resetar Progresso:** Ícone de reload/refresh (`icon_refresh.svg`) a 8px do texto "Resetar Progresso" em vermelho suave.
- Em `settings_modal.gd`, o gerenciador de visuais (`_update_toggle_visuals` e `_on_reset_pressed`) atualiza diretamente as labels filhas, eliminando duplicações e garantindo 100% de responsividade visual.

---

## 🏷️ Versão & Validação
- **Game SemVer:** Incrementado para `v0.12.81-alpha`.
- **Godot Headless Import & Test:** 0 warnings e 0 erros.
- **Exportação Web:** Build atualizada com sucesso em `build/web/`.
