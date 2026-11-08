# Histórico de Melhoria: Ajuste de Altura e Safe Area dos Cards das Páginas Abaixo dos Elementos do Topo

- **Versão:** `v0.12.153-alpha`
- **Data:** 08/11/2026
- **Status:** Concluído com 0 warnings e 0 erros
- **Autor:** Antigravity (Google DeepMind)

---

## 📋 Contexto e Diagnóstico

Ao navegar pelas abas secundárias do menu principal (`Oficina`, `Herbário` e `Loja`), especialmente em dispositivos móveis modernos (smartphones com recorte de notch/câmera frontal ou barras de status do Android), os elementos superiores do menu (`TopBar` contendo Badges de Moedas, Vidas e Botão de Configurações) colidiam diretamente sobre os cards de conteúdo:
1. Em dispositivos móveis, o cálculo de safe area (`_apply_safe_area`) deslocava a `TopBar` para baixo (`margin_top + top_inset`), estendendo o topo da barra para a região de Y ≈ 126px ~ 138px.
2. Os painéis principais das páginas (`TabCollection`, `TabGarage`, `TabStore`) possuíam `offset_top` estático em `96.0px` ou `104.0px`.
3. Consequentemente, o título "Herbário da Ilha & Itens", as ilustrações e os botões da barra superior ficavam sobrepostos. Além disso, a `VersionBadge` (`CanvasLayer/VersionBadge`) permanecia visível sob as abas, colidindo com o `CoinBadge`.

---

## 🛠️ Modificações Realizadas

### 1. Calibração do `offset_top` Base nos Painéis das Abas
- `scenes/menu/tabs/tab_collection.tscn`:
  - `offset_top`: ajustado de `96.0` para `120.0`.
  - `offset_bottom`: ajustado de `-104.0` para `-110.0`.
- `scenes/menu/tabs/tab_garage.tscn`:
  - `offset_top`: ajustado de `104.0` para `120.0`.
  - `offset_bottom`: ajustado de `-112.0` para `-110.0`.
- `scenes/menu/tabs/tab_store.tscn`:
  - `offset_top`: ajustado de `104.0` para `120.0`.
  - `offset_bottom`: ajustado de `-112.0` para `-110.0`.

No desktop (sem notch), isso estabelece uma folga elegante e uniforme de 34px entre a base da `TopBar` (86px) e o topo do card (120px), posicionando o título textual a 66px de distância dos badges.

### 2. Suporte Dinâmico à Safe Area (Notch / Cutouts) nos Cards
Em `scripts/menu/main_menu.gd` na rotina `_apply_safe_area()`:
- Quando `top_inset > 0.0` (dispositivos móveis):
  - Desloca dinamicamente os nós `Panel` de `tab_garage`, `tab_collection` e `tab_store` somando `roundf(top_inset)` a `offset_top`.
  - Desloca a `VersionBadge` para baixo em `roundf(top_inset)` para nunca colidir com o `CoinBadge`.

### 3. Exclusividade Visual da `VersionBadge` na Home
Em `scripts/menu/main_menu.gd` no método `_switch_tab(tab_idx)`:
- `version_badge.visible = (tab_idx == 0)`: a etiqueta de versão agora só é exibida na visão inicial 3D do Robô / Mapa (`TabHome`), ficando oculta nas telas de catálogo e oficina, proporcionando uma interface limpa.

---

## 🧪 Validação e Testes

1. **Testes Automatizados:**
   - `tests/test_android_lifecycle_and_navigation.tscn`: passou com 100% de sucesso (ciclo de vida Android, auto-pausa, hierarquia do botão voltar e navegação entre abas).
   - `tests/test_blade_progression.tscn`: passou com 100% de sucesso em todos os tiers e progressões de lâminas.
   - Execução headless de `scenes/menu/main_menu.tscn`: executou perfeitamente com 0 warnings e 0 erros.
2. **Game SemVer:**
   - Atualizado para `v0.12.153-alpha` (`versionCode = 1353`) sincronizado em `project.godot`, `scripts/core/game_version.gd` e `export_presets.cfg`.
