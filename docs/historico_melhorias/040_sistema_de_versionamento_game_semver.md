# Melhoria 040: Sistema de Versionamento Game SemVer, Classe Central GameVersion e Sincronização de Build 🏷️🌿

## 1. Visão Geral e Contexto
Até o momento, o versionamento do projeto operava com identificadores dispersos e dessincronizados: `project.godot` continha `0.7.2` sem identificador de estágio (`STAGE`), `export_presets.cfg` registrava `0.7.1` (com `version/code=7`), e a tela de configurações mantinha texto fixo e estático `v0.5.6`. Além disso, o savegame não carimbava a versão da build em que os dados eram serializados, e não havia uma fonte única de verdade no código para consulta dinâmica.

Nesta melhoria, foi estabelecido o padrão canônico **Game SemVer** (inspirado na maturidade do Rover Raid), diagnosticando a fase atual do jogo como **ALPHA (`v0.7.2-alpha`)**, criando a classe central `GameVersion`, integrando a versão na UI e no `SaveManager`, e criando a ferramenta de bump atômico `bump_version.gd`.

---

## 2. Diagnóstico de Maturidade: Pre-Alpha, Alpha ou Beta?
- **Pre-Alpha (`v0.1.0` a `v0.2.x`):** Concluído. O corte básico radial e movimentação já foram validados.
- **Alpha (`v0.7.2-alpha`) [FASE ATUAL]:** O loop central é sólido (20 fases canônicas, robô 3D articulado com expressões LED, shader de grama Arnklit, editor de fases PC e persistência de estrelas), porém é considerado *Feature Incomplete*, já que as abas Loja e Coleção estão pendentes, o áudio ainda não foi integrado e o balanceamento econômico não foi fechado.
- **Beta (`v0.9.0`+):** Será atingido assim que o jogo for *Feature Complete* (todas as 4 abas e áudio funcionais).
- **RC / Release 1.0:** Fase final para freeze e lançamento na Google Play Store.

---

## 3. Implementações Realizadas

### 3.1. Classe Central `GameVersion` (`scripts/core/game_version.gd`)
- Fonte única de verdade contendo `MAJOR = 0`, `MINOR = 7`, `PATCH = 2`, `STAGE = "ALPHA"`, `BUILD_TYPE = "dev"`.
- Métodos estáticos:
  - `get_version_string() -> String`: Retorna `"v0.7.2-alpha"`.
  - `get_raw_version() -> String`: Retorna `"0.7.2-alpha"` (para `project.godot`).
  - `get_display_name() -> String`: Retorna `"Grass Cut Bot v0.7.2-alpha"`.
  - `get_version_code() -> int`: Retorna `702` (para `versionCode` do Android).
  - Métodos booleanos: `is_pre_alpha()`, `is_alpha()`, `is_beta()`, `is_rc()`, `is_release()`.
  - `get_full_info() -> Dictionary`: Dicionário completo de metadados.

### 3.2. Sincronização do Motor e Presets de Exportação
- `project.godot`: Atualizado para `config/version="0.7.2-alpha"`.
- `export_presets.cfg`: Atualizado para `version/code=702` e `version/name="0.7.2-alpha"`.

### 3.3. Integração na Interface de Usuário (UI)
- **Settings Modal (`scripts/ui/settings_modal.gd`):** O `VersionLabel` agora é atualizado dinamicamente no `_ready()` via `GameVersion.get_display_name()`, exibindo `"Grass Cut Bot v0.7.2-alpha • Mobile Edition"`.
- **Menu Principal (`scenes/menu/main_menu.tscn` & `scripts/menu/main_menu.gd`):** Adicionado nó `VersionBadge` (`Label`) discreto sob a barra superior no canto esquerdo, atualizado via `GameVersion.get_version_string()`.

### 3.4. Rastreabilidade no SaveGame (`scripts/core/save_manager.gd`)
- Inclusão dos campos `"game_version": GameVersion.get_version_string()` e `"game_version_code": GameVersion.get_version_code()` em `get_default_save()`, `save_game()` e `_merge_with_defaults()`, garantindo compatibilidade e auditoria de saves.

### 3.5. Ferramenta de Incremento Automatizado (`scripts/tools/bump_version.gd`)
- Script `@tool extends EditorScript` executável com `Ctrl+Shift+X` no Script Editor para avançar PATCH, MINOR ou STAGE (Alpha $\to$ Beta $\to$ RC $\to$ Release), regravando atomicamente `game_version.gd`, `project.godot` e `export_presets.cfg`.

### 3.6. Documentação Canônica
- Criado [`docs/05_arquitetura_e_desenvolvimento/SISTEMA_DE_VERSIONAMENTO.md`](../05_arquitetura_e_desenvolvimento/SISTEMA_DE_VERSIONAMENTO.md).
- Atualizado [`docs/05_arquitetura_e_desenvolvimento/DIRETRIZES_DE_DESENVOLVIMENTO.md`](../05_arquitetura_e_desenvolvimento/DIRETRIZES_DE_DESENVOLVIMENTO.md).
- Atualizada matriz roteadora do [`GEMINI.md`](../../GEMINI.md).

---

## 4. Validação e Qualidade
- **Zero Warnings:** Verificado via execução em tempo de execução na Godot 4.7.1, com console retornando 0 warnings e 0 erros.
- **Prevenção de Sombra de Variáveis:** Identificadores globais mantidos sem sombreamento local.
- **Sincronia Total:** `game_version.gd`, `project.godot`, `export_presets.cfg`, UI e SaveManager perfeitamente alinhados em `v0.7.2-alpha`.
