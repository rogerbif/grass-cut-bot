# Melhoria 196: Gerador Procedural Agnóstico de Fases e Guardrail de Confirmação Prévia

- **Data:** 07/11/2026
- **Versão:** `v0.12.146-alpha`
- **Autor:** Antigravity AI
- **Status:** Concluído & Validado

---

## 🎯 Objetivo da Melhoria

1. **Ajuste do Mandamento Invariante 17 no `GEMINI.md`:** Substituir a proibição estática por uma regra ativa de proteção com consentimento: **sempre formular uma pergunta expressa de confirmação ao usuário** antes de executar qualquer geração ou alteração procedural em arquivos de fases (`data/levels/level_*.json`).
2. **Gerador Procedural Agnóstico:** Transformar o antigo script amarrado às fases 21-40 em uma ferramenta universal (`generate_procedural_levels.gd`), capaz de gerar qualquer intervalo de fases via linha de comando ou variáveis (fase inicial e final, ou quantidade de fases a partir de um ponto inicial), com geração procedural algorítmica para qualquer nível.

---

## 🛠️ Implementações Realizadas

### 1. Novo Mandamento 17 no `GEMINI.md`
O Mandamento Invariante 17 foi atualizado para:
> **17. Confirmação Prévia Obrigatória para Alterações Procedurais de Fases:** É estritamente obrigatório formular uma pergunta de confirmação ao usuário e obter sua autorização expressa antes de executar qualquer script ou gerador procedural que modifique, sobrescreva ou crie arquivos de fases (`data/levels/level_*.json`). O agente deve especificar com clareza quais fases serão afetadas (números ou intervalo) e os impactos pretendidos antes de rodar qualquer rotina de geração em lote.

### 2. Gerador Procedural Agnóstico (`scripts/tools/generate_procedural_levels.gd`)
- O script foi renomeado e desacoplado de intervalos fixos.
- **Suporte a Parâmetros CLI e Fallbacks:**
  - `--start=X`: define a fase inicial (ex: `--start=21`, `--start=1`, `--start=41`).
  - `--end=Y`: define a fase final (ex: `--end=40`, `--end=50`).
  - `--count=K`: define a quantidade de fases a gerar a partir de `--start` (ex: `--start=41 --count=10` gera fases 41 a 50).
- **Geração Algorítmica Procedural para Níveis Arbitrários:**
  - Preserva os designs ricos dedicados para níveis 21 a 40.
  - Para outros níveis (ex: 1 a 20 quando solicitado, ou 41+ para novas expansões), gera proceduralmente nomes temáticos, formas de ilha (chanfrada, octogonal, cruz, diamante, trevo), paletas botânicas balanceadas, rochas com espaçamento regulamentar (`MIN_ROCK_SPACING = 2.80m`), clareira de spawn (`1.40m`), clareira sob pedras (`0.90m`) e tempo auditado.

---

## 🧪 Verificação e Resultados

1. **Verificação de Compilação GDScript:**
   - `generate_procedural_levels.gd` compilou com 0 erros e 0 warnings via `--check-only`.
2. **Smoke Test de Integridade:**
   - `verify_levels_integrity.gd` validou as 40 fases ativas do jogo com 100% de sucesso.
3. **Game SemVer:** Atualizado para `v0.12.146-alpha`.
