# Diretrizes de Desenvolvimento, Terminal e Git 💻🛠️

Este documento define os protocolos operacionais para desenvolvimento com terminal Windows PowerShell, controle de versão Git e boas práticas de engenharia em **Grass Cut Bot**.

---

## 1. Diretrizes de Terminal Windows PowerShell

1. **Encadeamento com Ponto e Vírgula:** No Windows PowerShell, nunca utilize `&&` para encadear comandos; utilize exclusivamente `;` ou execute instruções em linhas separadas.
2. **Codificação Estrita UTF-8 sem BOM:** Ao manipular scripts e arquivos de texto via terminal, garanta codificação UTF-8 pura sem caracteres BOM (Byte Order Mark), que causam erros de parsing no compilador GDScript.
3. **Proteção de Nós Godot (`$Node`):** No PowerShell, a sintaxe `$NomeDoNo` é interpretada como uma variável de shell. Utilize blocos de aspas simples literais (`@' ... '@`) ao injetar ou editar código GDScript via scripts de terminal.

---

## 2. Padrão de Versionamento (Game SemVer)

O projeto segue versionamento semântico adaptado para jogos móveis (*Game SemVer*):

$$\text{v}\text{MAJOR}.\text{MINOR}.\text{PATCH}-\text{STAGE}$$

- **PATCH (+1):** Correções de bugs, polimento de física/shaders, ajustes visuais em UI e balanceamento de números.
- **MINOR (+1):** Novas variedades de vegetação, novas mecânicas de corte, blocos adicionais de fases ou novos modos de jogo.
- **MAJOR (+1):** Transição de ciclo de maturidade (MVP $\to$ Beta $\to$ 1.0 Release Gold Master).
- **STAGE:** Identificador de ciclo de maturidade (`pre-alpha`, `alpha`, `beta`, `rc`, `release`).

> Para diretrizes detalhadas de transição de maturidade, arquitetura da classe `GameVersion` e automação com `bump_version.gd`, consulte o documento canônico [Sistema de Versionamento](./SISTEMA_DE_VERSIONAMENTO.md).

---

## 3. Padrão de Mensagens Semânticas de Commit e Sincronização Obrigatória no GitHub

Todas as alterações no repositório devem seguir commits semânticos padronizados:
- `feat:` Nova mecânica, entidade, fase ou tela adicionada.
- `fix:` Correção de bug mecânico, colisão ou erro de script.
- `docs:` Atualizações na wiki, GDD ou histórico de melhorias.
- `style:` Ajustes puramente visuais em materiais, cores ou layout.
- `refactor:` Reorganização de código sem alteração no comportamento externo do jogo.
- `perf:` Otimizações de renderização, draw calls ou uso de memória mobile.

### Sincronização Contínua com o Repositório Remoto (GitHub)
- **Repositório Oficial:** `https://github.com/rogerbif/grass-cut-bot.git` (Branch principal: `main`).
- **Obrigatoriedade de Push:** A cada nova versão concluída (incremento de Game SemVer), correção ou refatoração finalizada, é obrigatório executar `git push origin main`, garantindo que o progresso nunca fique restrito apenas ao ambiente local.

---

## 4. Pipeline 3D: Blender para Godot 4

1. **Exportação glTF com Modificadores:** O operador padrão do Blender (`bpy.ops.export_scene.gltf`) não aplica modificadores por padrão (`export_apply=False`). Para garantir que modificadores essenciais (`Mirror`, `Subdivision`, `Bevel`) cheguem intactos ao jogo, sempre execute a exportação com `export_apply=True` e `export_yup=True`.
2. **Pivôs Anatômicos e Simetria:** Para peças com articulação mecânica (ex: `low_arm`, `neck`, `head`), altere o pivô do objeto sem mover a malha no mundo através de translação compensatória (`obj.location += offset; for v in mesh.vertices: v.co -= offset`). Em peças com `Mirror`, o pivô nunca deve se afastar do eixo de reflexão ($X=0$).
3. **Invalidação de Cache de Importação:** Quando um arquivo `.glb` for reexportado, apague o cache correspondente em `.godot/imported/<asset>.glb*` antes de abrir ou rodar a Godot, garantindo que o compilador gere o `.scn` atualizado sem manter transforms obsoletos.

---

## 5. Resolução de Concorrência Git com OneDrive (Windows)

1. **Bloqueio de Arquivo `.git/index.lock`:** Como o workspace está sincronizado via Microsoft OneDrive, processos em segundo plano de nuvem podem bloquear o arquivo de índice temporariamente.
2. **Protocolo de Recuperação:** Caso comandos `git add` ou `git commit` falhem com `Permission denied (.git/index.lock)`, execute a operação fora da camada restritiva da sandbox (`BypassSandbox: true`) mantendo rigorosamente os mesmos descritores de ação para contornar o bloqueio efêmero.

