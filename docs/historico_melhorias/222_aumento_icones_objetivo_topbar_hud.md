# Histórico de Melhoria 222: Aumento dos Ícones de Objetivo no TopBar HUD e Cards de Metas

- **Versão:** `v0.12.175-alpha`
- **Data:** 10/11/2026
- **Status:** Concluído com 0 warnings e 0 erros
- **Autor:** Antigravity (Google DeepMind)

---

## 📋 Contexto e Diagnóstico

Nas metas do TopBar HUD durante o gameplay, os ícones botânicos de objetivos (`GoalIconFactory.build_goal_icon`) estavam configurados com tamanho `41.0px`. Dentro dos cards de 74x82px, isso deixava um espaço vazio excessivo nas laterais e acima da contagem numérica, reduzindo a clareza visual dos detalhes da vegetação (tufos de grama, trigo e flores).
O usuário forneceu uma captura indicando com uma moldura vermelha a área desejada para o ícone, demandando que o tufo ocupasse de forma preenchida o quadrante superior da placa acima do número.

---

## 🛠️ Modificações Realizadas

### 1. Calibração do Tamanho do Ícone no HUD (`scripts/ui/hud.gd`)
- Em `_create_goal_card(plant_type: String, target: int)`:
  - O tamanho do container de ilustração (`GoalIconFactory.build_goal_icon`) foi aumentado de `41.0px` para **`56.0px`** (+36.5%).
  - Margens internas ajustadas para `left: 4, right: 4, top: 3, bottom: 3` e separação vertical do `VBoxContainer` para `1px`.
  - O tufo de vegetação agora preenche com riqueza visual e fidelidade a largura da placa chanfrada, alinhando-se com a área demarcada na solicitação.

### 2. Proporção Dinâmica no Card de Fase (`scripts/ui/map_level_card.gd`)
- Em `_make_goal_card(plant_type: String, amount: int, card_w: float)`:
  - Tamanho do ícone atualizado de `36.0px` fixo para escala proporcional dinâmica: `clampf(card_w - 14.0, 38.0, 44.0)`.
  - Garante ícones mais volumosos e legíveis em fases com 1 a 4 metas sem transbordar em grades mais densas.

---

## 🧪 Validação e Testes

1. **Testes Automatizados:**
   - Teste unitário em `tests/test_hud_goal_icon_size.gd` validou `icon_ctrl.custom_minimum_size == Vector2(56.0, 56.0)`.
   - `tests/test_android_lifecycle_and_navigation.tscn`: 100% aprovado.
   - `tests/test_cyber_resource_badge.tscn`: 100% aprovado.
   - `scenes/menu/main_menu.tscn` executado em modo headless com 0 erros e 0 warnings.
2. **Game SemVer:**
   - Atualizado para `v0.12.175-alpha` (`versionCode = 1375`) sincronizado em `project.godot`, `scripts/core/game_version.gd` e `export_presets.cfg`.
