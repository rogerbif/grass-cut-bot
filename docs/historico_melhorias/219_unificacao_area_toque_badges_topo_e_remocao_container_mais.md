# Histórico de Melhoria 219: Unificação da Área de Toque dos Badges da TopBar e Remoção do Container do '+'

- **Versão:** `v0.12.171-alpha`
- **Data:** 10/11/2026
- **Status:** Concluído com 0 warnings e 0 erros
- **Autor:** Antigravity (Google DeepMind)

---

## 📋 Contexto e Diagnóstico

Na TopBar da tela inicial (`Main Menu`), os badges de recursos (Moedas e Vidas) utilizam o componente `CyberResourceBadge`. Anteriormente:
1. O badge consistia em um `PanelContainer` com tamanho de 140x52px.
2. No entanto, a interação de toque ficava confinada a um pequeno `TextureButton` (`BtnPlus`) de 32x32px, que desenhava uma caixinha roxa com bordas (`btn_plus_square.svg`).
3. Tocar em qualquer outra parte da placa externa (no ícone da moeda/coração ou no texto numérico) não produzia qualquer reação.
4. O usuário solicitou remover o container quadrado do `+`, deixando o símbolo de adição integrado diretamente dentro da placa externa do badge e transformando toda a placa externa na área de toque interativa.

---

## 🛠️ Modificações Realizadas

### 1. Novo Ícone Vetorial Puro de Adição
- Criado `assets/icons/icon_plus.svg` (24x24px):
  - Traçado branco nítido (`#ffffff`) com pontas arredondadas (`stroke-linecap="round"` e `stroke-width="3.2"`).
  - Sombra projetada sutil inferior (`#000000` a 45%) para manter paridade estética exata com o `ValueLabel`.
  - Remoção definitiva do container quadrado roxo (`<rect>`), integrando o `+` naturalmente à placa do badge.

### 2. Reformulação do `CyberResourceBadge` (`Button`)
- `scenes/ui/cyber_resource_badge.tscn`:
  - O nó raiz foi convertido de `PanelContainer` para `Button` (com `flat = true` e `StyleBoxEmpty` em todos os estados).
  - Dimensão calibrada para `custom_minimum_size = Vector2(144, 52)`.
  - Configurado `mouse_filter = MOUSE_FILTER_IGNORE` (2) em todos os nós internos (`Background`, `MarginContainer`, `HBoxContainer`, `Icon`, `ValueLabel` e `PlusIcon`). Dessa forma, 100% da superfície de 144x52px recebe eventos de toque e clique de maneira unificada.
  - O antigo `BtnPlus` (`TextureButton`) foi substituído por `PlusIcon` (`TextureRect`), utilizando `icon_plus.svg`.

### 3. Game Feel, Haptics e Compatibilidade
- `scripts/ui/cyber_resource_badge.gd`:
  - Herança atualizada para `extends Button`.
  - Ao pressionar (`_on_btn_down`):
    - Reduz a escala para `0.96` com tween suave e `pivot_offset` centralizado.
    - Aplica leve realce cromático `Color(0.85, 0.90, 1.0)`.
  - Ao soltar (`_on_btn_up`):
    - Retorna elastiamente para `scale = Vector2(1.0, 1.0)` via `Tween.TRANS_BACK`.
  - Ao acionar o botão (`_on_btn_pressed` / `_pressed`):
    - Dispara vibração háptica curta de 15ms (`Input.vibrate_handheld(15)`).
    - Executa som `confirm` via `AudioManager.play_sfx("confirm")`.
    - Emite `plus_pressed` (preservando total compatibilidade com `main_menu.gd`) e `badge_pressed`.

---

## 🧪 Validação e Testes

1. **Testes Automatizados:**
   - Novo teste unitário dedicado: `tests/test_cyber_resource_badge.tscn` validando herança de `Button`, disparo de `plus_pressed`/`badge_pressed` e substituição de `BtnPlus` por `PlusIcon`.
   - `tests/test_android_lifecycle_and_navigation.tscn`: aprovado com 100% de sucesso.
   - Execução headless de `scenes/menu/main_menu.tscn`: 0 warnings e 0 erros.
2. **Game SemVer:**
   - Atualizado para `v0.12.171-alpha` (`versionCode = 1371`) sincronizado em `project.godot`, `scripts/core/game_version.gd` e `export_presets.cfg`.
