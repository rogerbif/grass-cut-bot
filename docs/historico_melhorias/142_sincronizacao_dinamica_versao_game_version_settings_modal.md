# Melhoria 142: Sincronização Dinâmica de Versão em GameVersion e SettingsModal 🏷️📱

## 🎯 Objetivo e Contexto
1. **Eliminação do Descompasso de Versão:**
   - Anteriormente, o arquivo `scripts/core/game_version.gd` mantinha constantes estáticas (`MAJOR: 0, MINOR: 12, PATCH: 59`).
   - Embora `project.godot` e `export_presets.cfg` fossem incrementados a cada entrega, `game_version.gd` dependia de intervenção manual ou do script `bump_version.gd`.
   - Com isso, a interface em `SettingsModal` (menu Configurações) e `MainMenu` continuava exibindo `v0.12.59-alpha`, induzindo o desenvolvedor e o usuário ao engano de que o build ou o celular não haviam sido atualizados.
2. **Arquitetura de Sincronização Dinâmica:**
   - Implementação de leitura dinâmica direta em runtime de `ProjectSettings.get_setting("application/config/version")` dentro de `GameVersion`.
   - Garantia de que qualquer alteração em `project.godot` (`config/version`) seja refletida instantaneamente em toda a UI (Menu Principal, Modal de Configurações, saves e telemetria) sem necessidade de recompilar scripts ou alterar constantes estáticas manualmente.
   - Atualização do método `open_modal()` em `SettingsModal` para sempre reavaliar e repintar o label de versão toda vez que o modal for aberto pelo jogador.

---

## 🛠️ Alterações Realizadas

### 1. `scripts/core/game_version.gd`
- `get_raw_version()` agora consulta prioritariamente `ProjectSettings.get_setting("application/config/version", "")`.
- `get_version_string()`, `get_display_name()`, `get_version_code()` e `get_full_info()` operam com base nessa versão dinâmica única.
- Atualizadas as constantes estáticas de fallback para `MAJOR: 0, MINOR: 12, PATCH: 68`.

### 2. `scripts/ui/settings_modal.gd`
- No método `open_modal()`, adicionada a reatribuição explícita:
  `version_label.text = "%s • Mobile Edition" % GameVersion.get_display_name()`.

### 3. Automação e Ferramental
- Atualizado o gerador de código em `scripts/tools/bump_version.gd` para gerar a classe `GameVersion` com o padrão de leitura dinâmica de `ProjectSettings`.
- Atualizado o procedimento canônico na skill `.agent/skills/atualizar-documentacao/SKILL.md`.
- Sincronizados `project.godot` e `export_presets.cfg` com a versão canônica **`v0.12.68-alpha`** (code `1268`).

---

## ✅ Verificação e Testes
1. **Teste Automatizado em Godot Headless:** Executado `tests/test_multi_hit_continuous.tscn` validando:
   - `GameVersion.get_version_string()` retorna `"v0.12.68-alpha"`.
   - `GameVersion.get_display_name()` retorna `"Grass Cut Bot v0.12.68-alpha"`.
   - Sincronização automática com `ProjectSettings`.
   - 0 erros e 0 warnings.
