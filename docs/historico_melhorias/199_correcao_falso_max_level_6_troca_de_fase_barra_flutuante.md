# Melhoria 199: Correção de Falso Nível MAX ao Mudar de Fase no Nível 6

- **Data:** 08/11/2026
- **Versão:** `v0.12.154-alpha`
- **Autor:** Antigravity AI & Roger Bif
- **Status:** Concluído & Validado

---

## 🎯 Causa Raiz do Problema

Na expansão recente da lâmina para 10 níveis (`MAX_BLADE_LEVEL = 10`), a inicialização no método `_ready()` de `scripts/cutter/blade_progress_bar.gd` ainda possuía uma verificação residual estática herdada do sistema antigo de 6 níveis:

```gdscript
# Código anterior (com bug):
_on_blade_level_changed(UpgradeManager.blade_level, UpgradeManager.blade_level >= 6)
```

Como resultado, quando o jogador atingia o Nível 6 (ou superior) durante o gameplay e concluía ou reiniciava a fase, a nova cena instanciava `BladeProgressBar`, avaliando `UpgradeManager.blade_level >= 6` como `true`. Isso propagava `is_max = true` e fazia a barra flutuante exibir o visual temático de topo ("👑 NÍVEL MÁXIMO ⭐") já a partir do Nível 6, em vez de exibir "NÍVEL 6" (ou 7, 8, 9).

---

## 🛠️ Correções Realizadas

1. **Método Canônico `UpgradeManager.is_max_level()`:**
   - Adicionada a função defensiva `func is_max_level() -> bool` em `scripts/core/upgrade_manager.gd`, retornando `blade_level >= MAX_BLADE_LEVEL`.

2. **Inicialização Reativa em `BladeProgressBar` (`scripts/cutter/blade_progress_bar.gd`):**
   - No `_ready()`, substituída a checagem fixa `>= 6` por consulta dinâmica a `UpgradeManager.is_max_level()`:
     ```gdscript
     var is_max: bool = UpgradeManager.is_max_level() if UpgradeManager.has_method("is_max_level") else (UpgradeManager.blade_level >= UpgradeManager.MAX_BLADE_LEVEL)
     _on_blade_level_changed(UpgradeManager.blade_level, is_max)
     ```
   - Em `_on_blade_level_changed` e `_on_blade_xp_changed`, substituído o literal `10` pela constante canônica `UpgradeManager.MAX_BLADE_LEVEL`.

3. **Testes Automatizados de Regressão (`tests/test_blade_progression.gd`):**
   - Adicionadas asserções verificando que `UpgradeManager.is_max_level()` retorna `false` no Nível 6 e `true` apenas no Nível 10.
   - Adicionado teste instanciando diretamente `BladeProgressBar` no Nível 6, comprovando que `_is_max == false`, a label exibe `"NÍVEL 6"` e os ícones de coroa/estrela permanecem ocultos.
   - Adicionado teste instanciando `BladeProgressBar` no Nível 10, comprovando que `_is_max == true` e a coroa é ativada.

---

## 🧪 Validação

- `res://tests/test_blade_progression.tscn`: 48/48 asserções aprovadas com código 0.
- `res://tests/test_blade_pop_and_slash.tscn`: 100% aprovado com código 0.
