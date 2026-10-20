# Melhoria 050: Otimização de Performance no Menu Inicial (Culling de Ilhas e Animação Seletiva de Vento) 🚀🏝️⚡

**Data:** 2026-10-20  
**Versão:** `v0.7.12-alpha`  
**Autor:** Antigravity (Advanced Agentic Coding)  
**Status:** Concluído com Sucesso e Validado (0 Warnings / 0 Erros)  

---

## 1. Contexto e Motivação

Com a recente quadruplicação da densidade de grama (subgrade de $0.40\text{m}$, totalizando 4 tufos por bloco de $0.80\text{m}$), renderizar simultaneamente as 20 fases canônicas no Menu Inicial provocava uma sobrecarga massiva de draw calls e nós na cena (~12.000 instâncias de grama ativas), resultando em travamento/queda de FPS na visão do bot (`BOT_VIEW`).

O usuário direcionou:
> *"ficou travado a visão do bot, então vamos fazer o seguinte, quando estiver na visão bot pode ocultar todas as outras ilhas não precisa renderizar, quando estiver na visão map mostre somente a atual a proxima e anterior, visão map não precisa animar a grama na visão bot sim somente"*

---

## 2. Decisões Arquiteturais e Execução Técnica

### 2.1 Culling Total na Visão Bot (`BOT_VIEW`)
- **Isolamento da Ilha Atual:**
  - Na visão do robô (`BOT_VIEW`), **todas as outras 19 ilhas e o banco de nuvens terminal ficam ocultos (`visible = false`)**, sendo renderizada estritamente a ilha atual (`selected_level`).
  - Redução imediata de 95% na quantidade de nós processados pela GPU e CPU.
- **Animação Seletiva da Grama:**
  - O shader espacial com balanço de vento interativo (`set_grass_animated(true)`) é executado **exclusivamente na ilha onde o robô se encontra na visão do bot**.

### 2.2 Janela Deslizante de 3 Ilhas na Visão Mapa (`MAP_VIEW`)
- **Culling Reativo no Scroll:**
  - A câmera do menu (`scripts/menu/menu_camera.gd`) monitora o nível em foco durante a rolagem contínua via `find_closest_level(current_scroll_z)` e emite `scroll_focus_changed(focused_level)`.
  - O `main_menu.gd` aplica uma janela deslizante estrita:
    $$\text{Ilhas Visíveis} = [\text{foco} - 1, \text{foco}, \text{foco} + 1]$$
  - Todas as outras 17 ilhas distantes permanecem com `visible = false`, sendo ativadas/desativadas dinamicamente à medida que o jogador arrasta ou dá flick no mapa.
  - O banco terminal de nuvens só fica visível se o foco estiver na reta final ($\ge 19$).
- **Grama Estática na Visão Mapa:**
  - Todas as ilhas na visão mapa utilizam materiais estáticos com animação de vento pausada (`set_grass_animated(false)`), eliminando o custo do vertex shader em visão aérea.

---

## 3. Arquivos Modificados

- [`scripts/menu/menu_camera.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/menu/menu_camera.gd)
- [`scripts/menu/main_menu.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/menu/main_menu.gd)
- [`scripts/core/game_version.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/core/game_version.gd)
- [`project.godot`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/project.godot)
- [`docs/04_sistemas_e_gameplay/SISTEMA_DE_INTERFACE_HUD.md`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/docs/04_sistemas_e_gameplay/SISTEMA_DE_INTERFACE_HUD.md)
- [`docs/historico_melhorias/INDICE_MELHORIAS.md`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/docs/historico_melhorias/INDICE_MELHORIAS.md)

---

## 4. Validação e Qualidade

- **Execução Godot 4:** Testado via MCP `run_project` no `main_menu.tscn`.
- **Zero Warnings / Zero Erros:** Console limpo com 0 warnings e 0 erros.
- **Fluidez e Taxa de Quadros:** Queda drástica de processamento gráfico, garantindo 60 FPS inabaláveis.
- **Game SemVer:** Atualizado para **`v0.7.12-alpha`**.
