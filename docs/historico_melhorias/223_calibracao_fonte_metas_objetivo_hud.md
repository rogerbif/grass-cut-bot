# Histórico de Melhoria 223: Calibração da Tipografia dos Objetivos no HUD (Font Size 20px)

- **Versão:** `v0.12.176-alpha`
- **Data:** 10/11/2026
- **Status:** Concluído com 0 warnings e 0 erros
- **Autor:** Antigravity (Google DeepMind)

---

## 📋 Contexto e Diagnóstico

Após a ampliação dos ícones botânicos de objetivos no TopBar HUD (para 56px), a tipografia numérica das metas em `font_size = 16` ficou visualmente pequena em relação à presença gráfica dos tufos de vegetação, deixando espaço vertical ocioso no terço inferior do card.
O usuário solicitou aumentar a fonte do objetivo de forma moderada ("um pouco"), delimitando com uma moldura vermelha a área útil inferior do badge.

---

## 🛠️ Modificações Realizadas

### 1. Calibração da Tipografia do HUD (`scripts/ui/hud.gd`)
- Em `_create_goal_card(plant_type: String, target: int)`:
  - Tamanho da fonte (`count_lbl`) aumentado de `16` para **`20`** (+25%).
  - Dimensão do card ajustada para `custom_minimum_size = Vector2(74, 84)` e `pivot_offset = Vector2(37, 42)`.
  - Proporciona leitura imediata do contador e estado "OK" a qualquer distância visual, mantendo peso 900 (`SystemFont`) e sombra de 1px.

### 2. Equalização no Card de Fases do Menu (`scripts/ui/map_level_card.gd`)
- Em `_make_goal_card(plant_type: String, amount: int, card_w: float)`:
  - Tamanho da fonte ajustado de `16` para **`18`**, harmonizando a hierarquia textual em cartões compactos de 70px de altura.

---

## 🧪 Validação e Testes

1. **Testes Automatizados:**
   - `tests/test_android_lifecycle_and_navigation.tscn`: 100% aprovado.
   - `tests/test_cyber_resource_badge.tscn`: 100% aprovado.
   - `scenes/menu/main_menu.tscn`: executado em modo headless com 0 erros e 0 warnings.
2. **Game SemVer:**
   - Atualizado para `v0.12.176-alpha` (`versionCode = 1376`) sincronizado em `project.godot`, `scripts/core/game_version.gd` e `export_presets.cfg`.
