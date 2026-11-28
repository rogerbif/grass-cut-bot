# Melhoria 252: Grafo de Símbolos Godot 4 e Otimização de Tokens (`v0.12.223-alpha`) 🗺️⚡

## Resumo Executivo
Implementação de um ecossistema local de economia de tokens equivalente ao CodeGraph para **Godot 4 (GDScript + `.tscn`)**, reduzindo o custo fixo de contexto por turno e evitando leituras amplas de arquivos durante sessões com o agente.

---

## Alterações Implementadas

### 1. Gerador Local de Grafo GDScript & Cenas (`tools/build_gd_graph.py`)
- Criado o script Python `tools/build_gd_graph.py` com varredura estrutural de `scripts/` (excluindo `tests/`) e `scenes/`.
- **Extração de Scripts (`.gd`):** `class_name`, `extends`, `signals`, constantes principais e todas as funções (`func` / `static func`) com intervalo exato de linhas (`L<inicio>-L<fim>`).
- **Extração de Cenas (`.tscn`):** nó raiz, script anexado e subcenas instanciadas.
- **Modo CLI (`--query <termo>`):** busca instantânea por símbolos, classes, sinais e cenas retornando apenas arquivo e intervalo exato de linhas.
- Gerado o índice canônico [`docs/05_arquitetura_e_desenvolvimento/MAPA_DE_SIMBOLOS.md`](../05_arquitetura_e_desenvolvimento/MAPA_DE_SIMBOLOS.md) cobrindo **72 scripts** (1.004 funções, 85 signals) e **52 cenas**.

### 2. Enxugamento Cirúrgico do `GEMINI.md`
- Compactada a redação dos **18 Mandamentos Invariantes** em `GEMINI.md` (reduzindo ~32% do tamanho do arquivo carregado automaticamente em todos os turnos), preservando integralmente todas as 18 regras críticas.
- Detalhes operacionais extensos de exportação 3D/glTF e overrides `.scn` foram consolidados na skill [`.agent/skills/atualizar-documentacao/SKILL.md`](../../.agent/skills/atualizar-documentacao/SKILL.md).

### 3. Diretriz de Economia de Contexto & Subagente `research`
- Adicionada à Matriz Roteadora e ao Protocolo Operacional do `GEMINI.md` a obrigatoriedade de consultar `MAPA_DE_SIMBOLOS.md` ou `python tools/build_gd_graph.py --query <termo>` antes de ler scripts completos, além de delegar investigações multi-arquivo (3+ arquivos) ao subagente `research`.
- Atualizada a skill `atualizar-documentacao` para regenerar `MAPA_DE_SIMBOLOS.md` automaticamente quando scripts `.gd` ou cenas `.tscn` forem alterados.
- Documentados `tools/build_gd_graph.py` e `MAPA_DE_SIMBOLOS.md` em [`docs/05_arquitetura_e_desenvolvimento/ARQUITETURA_DO_PROJETO.md`](../05_arquitetura_e_desenvolvimento/ARQUITETURA_DO_PROJETO.md).

---

## Validação
- Executado `python tools/build_gd_graph.py` e `python tools/build_gd_graph.py --query cut_in_circle` com saída exata (`L1133-L1345` em `scripts/plants/vegetation_grid.gd`).
- Versão incrementada para `v0.12.223-alpha` (`version/code=1423`) em `scripts/core/game_version.gd`, `project.godot` e `export_presets.cfg`.
