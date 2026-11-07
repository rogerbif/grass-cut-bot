# Melhoria 195: Blindagem Arquitetural das Fases 01-20, Guardrail 17 e Smoke Test de Integridade

- **Data:** 07/11/2026
- **Versão:** `v0.12.145-alpha`
- **Autor:** Antigravity AI
- **Status:** Concluído & Validado

---

## 🎯 Objetivo da Melhoria

Eliminar em definitivo a possibilidade de regressão ou corrupção acidental das **Fases 01 a 20** (desenhadas com carinho e geometria rica no Editor de Fases em escala real de 10.0m a 18.8m), blindar as diretrizes de desenvolvimento com um novo Mandamento Invariante no `GEMINI.md`, eliminar scripts legados de alto risco e implementar uma rotina automatizada de smoke test de integridade executável via linha de comando no Godot.

---

## 🔍 Diagnóstico e Causa Raiz

Durante ajustes na lógica de desbaste de vegetação ao redor de rochas e spawn do robô, a execução inadvertida do script `generate_all_20_levels.gd` regrediu os arquivos `level_01.json` a `level_20.json` para uma malha procedural obsoleta de 13x13 tiles (5.2m), destruindo os dados canônicos desenhados manualmente no Editor de Fases.

A análise arquitetural concluiu que:
1. **Regras de gameplay não pertencem a regeradores de JSON:** Parâmetros como o raio de clareira sob a pedra (`0.90m`) ou sob o spawn do robô (`1.40m`) devem ser calculados e aplicados dinamicamente em tempo de execução (`vegetation_grid.gd` e `island_node.gd`), sem tocar na persistência estática dos arquivos JSON das fases.
2. **Scripts obsoletos ofereciam risco perpétuo:** O arquivo `generate_all_20_levels.gd` não tinha mais razão de existir no projeto e funcionava como um vetor de regressão em massa.

---

## 🛠️ Implementações Realizadas

### 1. Restauração Canônica das Fases 01 a 20
- Todos os 20 arquivos JSON canônicos (`data/levels/level_01.json` até `data/levels/level_20.json`) foram restaurados ao seu estado íntegro original com dimensões reais de 10.0m a 18.8m e objetivos botânicos completos.

### 2. Remoção do Script de Risco e Isolamento do Gerador de Expansão
- O script prejudicial `scripts/tools/generate_all_20_levels.gd` foi permanentemente removido com `git rm`.
- O gerador de fases restantes foi renomeado para `scripts/tools/generate_expansion_levels_21_to_40.gd`, deixando seu escopo 100% explícito apenas para as fases 21 a 40 (>= 18m).

### 3. Instituição do 17º Mandamento Invariante no `GEMINI.md`
Foi formalizada no `GEMINI.md` a regra inviolável de soberania:
> **17. Imutabilidade e Soberania das Fases 01 a 20 (Zero Sobrescrita Procedural):** As fases 01 a 20 são níveis canônicos oficiais desenhados e refinados no Editor de Fases. É estritamente proibido rodar geradores procedurais ou sobrescrever os arquivos `data/levels/level_01.json` a `level_20.json` em massa via scripts automáticos. Ajustes de regras de gameplay (raios de corte de vegetação, spawn, colisão) devem ser sempre aplicados de forma dinâmica e não-destrutiva em tempo de execução via `vegetation_grid.gd` e `island_node.gd`.

### 4. Implementação do Smoke Test Automatizado (`verify_levels_integrity.gd`)
Criado o script `scripts/tools/verify_levels_integrity.gd` para validação CI/CLI:
- Itera sobre todas as 40 fases (`level_01.json` a `level_40.json`).
- Valida sintaxe JSON e integridade da estrutura de dicionários.
- Valida que as Fases 01 a 20 mantêm escala real (dimensões >= 8.0m e Fase 01 estritamente em 25x25 com 0.40m = 10.0m).
- Valida que as Fases 21 a 40 mantêm escala expandida (dimensões >= 18.0m).
- Valida que os dicionários de objetivos (`card_goals`/`goals`) não estão vazios.
- Retorna código de saída `quit(0)` em caso de 100% de conformidade e `quit(1)` caso qualquer regressão seja detectada.

---

## 🧪 Verificação e Resultados

Executado o smoke test via Godot Console Headless:
```
==================================================
🔍 INICIANDO SMOKE TEST DE INTEGRIDADE DAS FASES
==================================================
  [OK] Fase 01: 25x25 (10.0m x 10.0m) | Metas: 2 espécies
  [OK] Fase 02: 25x25 (10.0m x 10.0m) | Metas: 3 espécies
  ...
  [OK] Fase 20: 21x21 (16.8m x 16.8m) | Metas: 9 espécies
  [OK] Fase 21: 23x23 (18.4m x 18.4m) | Metas: 4 espécies
  ...
  [OK] Fase 40: 31x31 (24.8m x 24.8m) | Metas: 11 espécies
--------------------------------------------------
✅ [SUCESSO] Todas as 40 fases verificadas com 100% de integridade!
   Mandamento 17 (Imutabilidade Fases 01-20) e Fases 21-40 respeitados.
==================================================
```

O menu principal (`scenes/menu/main_menu.tscn`) também foi testado em modo headless por 3 segundos ininterruptos, operando de forma estável com **0 warnings e 0 erros**.
