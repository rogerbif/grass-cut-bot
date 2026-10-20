# Melhoria 051: Lazy Loading de Ilhas sob Demanda e Persistência em Memória no Menu Inicial ⚡🏝️💾

**Data:** 2026-10-20  
**Versão:** `v0.7.13-alpha`  
**Autor:** Antigravity (Advanced Agentic Coding)  
**Status:** Concluído com Sucesso e Validado (0 Warnings / 0 Erros)  

---

## 1. Contexto e Motivação

Anteriormente, o Menu Inicial instanciava todos os blocos 3D e milhares de tufos de grama das 20 fases canônicas simultaneamente durante o frame de abertura (`_ready()`), gerando um atraso inicial e sobrecarga desnecessária.

O usuário apontou a solução perfeita:
> *"acho que esta descarregando e carregando cada mapa, talvez possamos fazer um lazy loading carregando inicialmente somente o atual o anterior e o proximo, deixe carregados só oculte para não renderizar"*

---

## 2. Decisões Arquiteturais e Execução Técnica

### 2.1 Desacoplamento de Metadados e Construção 3D (`scripts/menu/island_node.gd`)
- **Leitura Rápida de Metadados (`read_island_metadata`):**
  - No `setup_island`, são lidos instantaneamente apenas os parâmetros métricos do JSON (`width`, `height`, `cell_size`), calculando `island_dimensions` e `map_plaque_pos` para alimentar os waypoints e o enquadramento de altitude da câmera em frações de milissegundo, **sem instanciar malhas 3D**.
- **Carregamento sob Demanda (`ensure_content_loaded`):**
  - Cada ilha possui a flag de estado `is_built: bool = false`.
  - Quando a ilha precisa ser exibida pela primeira vez, `ensure_content_loaded()` é chamado, executando `build_miniature_from_json(lvl)` e marcando `is_built = true`.
- **Persistência Absoluta em Memória:**
  - Se a ilha já foi construída (`is_built == true`), chamadas subsequentes não reconstroem nem recarregam nada. A ilha permanece viva e montada em memória.
  - Para economizar GPU, a ilha é simplesmente ocultada (`visible = false`) quando fora da área de visão. Ao retornar, `visible = true` é imediato e sem engasgos.

### 2.2 Gerenciamento do Lazy Loading no Menu (`scripts/menu/main_menu.gd`)
- **Inicialização Ultra-Rápida:**
  - No boot (`_detect_levels_and_build_archipelago`), o menu chama `_load_surrounding_islands(selected_level)`, construindo inicialmente apenas a ilha ativa e seus vizinhos imediatos ($[\text{foco} - 1, \text{foco}, \text{foco} + 1]$).
- **Alimentação Contínua da Janela Deslizante:**
  - Conforme o usuário rola a câmera na visão mapa, o sinal `scroll_focus_changed` aciona `_load_surrounding_islands(focal_level)`. Qualquer fase nova que se aproxime da janela é carregada sob demanda e persiste em memória.
- **Modo Bot Focado:**
  - Na visão bot (`BOT_VIEW`), garante o carregamento da ilha atual e oculta todas as outras com `visible = false`.

---

## 3. Arquivos Modificados

- [`scripts/menu/island_node.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/menu/island_node.gd)
- [`scripts/menu/main_menu.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/menu/main_menu.gd)
- [`scripts/core/game_version.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/core/game_version.gd)
- [`project.godot`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/project.godot)
- [`docs/04_sistemas_e_gameplay/SISTEMA_DE_INTERFACE_HUD.md`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/docs/04_sistemas_e_gameplay/SISTEMA_DE_INTERFACE_HUD.md)
- [`docs/historico_melhorias/INDICE_MELHORIAS.md`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/docs/historico_melhorias/INDICE_MELHORIAS.md)

---

## 4. Validação e Qualidade

- **Execução Godot 4:** Testado via MCP `run_project` no `main_menu.tscn`.
- **Zero Warnings / Zero Erros:** Console limpo com 0 warnings e 0 erros.
- **Boot Instantâneo:** Carregamento inicial do Menu Inicial sem engasgos.
- **Game SemVer:** Atualizado para **`v0.7.13-alpha`**.
