# Histórico de Melhoria 224: Ajuste de Espaçamento Interno e Redistribuição de Paddings nos Cards de Metas do HUD

- **Versão:** `v0.12.177-alpha`
- **Data:** 10/11/2026
- **Status:** Concluído com 0 warnings e 0 erros
- **Autor:** Antigravity (Google DeepMind)

---

## 📋 Contexto e Diagnóstico

Após a ampliação do ícone botânico (56px) e da tipografia numérica (20px), observou-se uma folga vertical considerável entre a base do tufo de vegetação e o topo dos algarismos (cerca de 12px), causada pela área transparente inferior da ilustração vetorial combinada com a métrica de alinhamento vertical.
O usuário solicitou reduzir essa distância entre os dois elementos pela metade e redistribuir essa folga nos paddings superior e inferior do card.

---

## 🛠️ Modificações Realizadas

### 1. Redistribuição Vertical no TopBar HUD (`scripts/ui/hud.gd`)
- Em `_create_goal_card(plant_type: String, target: int)`:
  - Separação vertical do `VBoxContainer` calibrada para `-5px` (quando sem barra de progresso), encurtando o espaço vazio entre a base do solo e o número de 12px para ~6px (redução de exatamente 50%).
  - Margens verticais (`margin_top` e `margin_bottom`) aumentadas de `3px` para **`6px`** (+3px no topo e +3px na base, absorvendo integralmente a folga de 6px retirada do meio).
  - Garante um layout perfeitamente equilibrado: o tufo de grama ganha respiração adequada da borda superior, os números aproximam-se organicamente da base do solo e a base do card preserva margem confortável.

---

## 🧪 Validação e Testes

1. **Testes Automatizados:**
   - `tests/test_android_lifecycle_and_navigation.tscn`: 100% aprovado.
   - `tests/test_cyber_resource_badge.tscn`: 100% aprovado.
   - `scenes/menu/main_menu.tscn`: executado em modo headless com 0 erros e 0 warnings.
2. **Game SemVer:**
   - Atualizado para `v0.12.177-alpha` (`versionCode = 1377`) sincronizado em `project.godot`, `scripts/core/game_version.gd` e `export_presets.cfg`.
