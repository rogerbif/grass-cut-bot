# Diretrizes de Desenvolvimento, Terminal e Git 💻🛠️

Este documento define os protocolos operacionais para desenvolvimento com terminal Windows PowerShell, controle de versão Git e boas práticas de engenharia em **Grass Cut Bot**.

---

## 1. Diretrizes de Terminal Windows PowerShell

1. **Encadeamento com Ponto e Vírgula:** No Windows PowerShell, nunca utilize `&&` para encadear comandos; utilize exclusivamente `;` ou execute instruções em linhas separadas.
2. **Codificação Estrita UTF-8 sem BOM:** Ao manipular scripts e arquivos de texto via terminal, garanta codificação UTF-8 pura sem caracteres BOM (Byte Order Mark), que causam erros de parsing no compilador GDScript.
3. **Proteção de Nós Godot (`$Node`):** No PowerShell, a sintaxe `$NomeDoNo` é interpretada como uma variável de shell. Utilize blocos de aspas simples literais (`@' ... '@`) ao injetar ou editar código GDScript via scripts de terminal.

---

## 2. Padrão de Versionamento (Game SemVer)

O projeto segue versionamento semântico adaptado para jogos móveis:

$$\text{v}\text{MAJOR}.\text{MINOR}.\text{PATCH}$$

- **PATCH (+1):** Correções de bugs, polimento de física, ajustes cosméticos em UI e balanceamento de números.
- **MINOR (+1):** Novas variedades de vegetação, novas mecânicas de corte, blocos adicionais de fases ou novos modos de jogo.
- **MAJOR (+1):** Transição de ciclo de maturidade (MVP -> Beta -> 1.0 Release).

---

## 3. Padrão de Mensagens Semânticas de Commit (Git)

Todas as alterações no repositório devem seguir commits semânticos padronizados:
- `feat:` Nova mecânica, entidade, fase ou tela adicionada.
- `fix:` Correção de bug mecânico, colisão ou erro de script.
- `docs:` Atualizações na wiki, GDD ou histórico de melhorias.
- `style:` Ajustes puramente visuais em materiais, cores ou layout.
- `refactor:` Reorganização de código sem alteração no comportamento externo do jogo.
- `perf:` Otimizações de renderização, draw calls ou uso de memória mobile.
