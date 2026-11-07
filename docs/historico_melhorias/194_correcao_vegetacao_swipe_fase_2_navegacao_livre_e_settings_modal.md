# Histórico de Melhorias: 194. Correção da Vegetação 3D no Swipe de Fases, Navegação Livre e Abertura/Fechamento das Configurações 🌿⚙️

**Data:** 07 de Novembro de 2026  
**Versão:** `v0.12.144-alpha`  
**Escopo:** Menu Principal, Gestos de Swipe, Ilhas 3D (`IslandNode`), Hierarquia de Abas (`TabViews`/`TopBar`) e Modal de Configurações (`SettingsModal`).  

---

## 1. Contexto e Motivação

Após a introdução da navegação por gestos de swipe no Menu Principal (`v0.12.143-alpha`), foram identificados 4 pontos de atrito:
1. **Vegetação 3D Ausente ao Trocar de Fase:** Ao realizar swipe para a Fase 2 (ou fases seguintes), o robô teleportava e a ilha mudava, mas a grama e as flores 3D não apareciam, pois a nova ilha não recebia o estado `is_active_island = true`, mantendo a vegetação 3D oculta (`veg_3d_container.visible = false`).
2. **Navegação Restrita a Fases Desbloqueadas:** Havia uma trava que bloqueava a navegação para fases futuras (`target_lvl > max_unlocked + 1`), impedindo o jogador de espiar livremente as fases seguintes e seus objetivos.
3. **Botão de Configurações Inacessível com Abas Secundárias Ativas:** Ao acessar as abas Garagem, Coleção ou Loja, os nós raiz dessas abas cobriam a tela inteira (Preset 15) com `mouse_filter = STOP` por estarem desenhados sobre a `TopBar`, bloqueando o toque/clique no botão `SettingsButton` (`[⚙️]`).
4. **Fechamento do Modal de Configurações no Backdrop:** O `SettingsModal` não fechava ao tocar na área escura fora do painel central (backdrop click).

---

## 2. Implementações e Soluções Técnicas

### 2.1 Ativação Reativa da Vegetação 3D ao Mudar de Fase via Swipe
- No método `_navigate_level_by_delta(delta: int)` em `scripts/menu/main_menu.gd`, foi adicionada a chamada `_update_plaques_view_mode(false, true)` logo após `_update_islands_visibility(false, selected_level)`.
- Isso garante que a ilha recém-focada execute `island.set_view_mode(false, true)`, disparando `_ensure_3d_veg_built()`, tornando o `veg_3d_container.visible = true` e animando o vento no modelo 3D. As ilhas anteriores têm suas vegetações desativadas para economia de draw calls.

### 2.2 Navegação Livre por Todas as Fases do Arquipélago
- Removido o bloqueio restritivo `target_lvl > max_allowed`. O jogador agora pode navegar livremente entre a Fase 1 e a Fase `total_levels_count`.
- O `MapLevelCard` atualiza dinamicamente e exibe adequadamente o status de bloqueado, ícone de cadeado e botão desabilitado quando o jogador inspeciona fases ainda não conquistadas.

### 2.3 Desbloqueio do Botão de Configurações em Qualquer Aba Ativa
- Nas cenas das abas secundárias (`scenes/menu/tabs/tab_garage.tscn`, `tab_collection.tscn` e `tab_store.tscn`), foi configurado `mouse_filter = 2` (`MOUSE_FILTER_IGNORE`) no nó raiz de cada aba. Como o painel de conteúdo dessas abas inicia com margem superior (`offset_top >= 96px`), a faixa superior de topo fica 100% permeável aos eventos de clique.
- Na cena `scenes/menu/main_menu.tscn`, a `TopBar` foi posicionada após `TabViews` na árvore de nós do `CanvasLayer`, garantindo ordem de renderização prioritária sobre as abas, com `mouse_filter = 2` no container de margem e no `HBox`.

### 2.4 Fechamento Tátil de `SettingsModal` no Backdrop
- Em `scripts/ui/settings_modal.gd`, o nó `Backdrop` (`ColorRect`) foi vinculado via `gui_input`.
- Implementado o tratador `_on_backdrop_gui_input(event: InputEvent)`: ao detectar clique esquerdo ou toque no backdrop fora da área do `PanelContainer`, invoca `close_modal()`, executando a animação suave de fade out e emitindo `modal_closed`.

---

## 3. Arquivos Modificados

| Arquivo | Descrição das Modificações |
| :--- | :--- |
| `scripts/menu/main_menu.gd` | Adicionado `_update_plaques_view_mode(false, true)` e liberação de navegação entre 1 e `total_levels_count` em `_navigate_level_by_delta`. |
| `scripts/ui/settings_modal.gd` | Conexão de `gui_input` no nó `Backdrop` e tratador `_on_backdrop_gui_input` para fechamento por toque externo. |
| `scenes/menu/main_menu.tscn` | `TopBar` movida para depois de `TabViews` com `mouse_filter = 2` na margem e HBox. |
| `scenes/menu/tabs/tab_garage.tscn` | `mouse_filter = 2` no nó raiz `TabGarage`. |
| `scenes/menu/tabs/tab_collection.tscn` | `mouse_filter = 2` no nó raiz `TabCollection`. |
| `scenes/menu/tabs/tab_store.tscn` | `mouse_filter = 2` no nó raiz `TabStore`. |
| `project.godot` | Versão incrementada para `0.12.144-alpha`. |
| `scripts/core/game_version.gd` | Constante `PATCH` incrementada para `144`. |
| `export_presets.cfg` | Versão Android atualizada para `0.12.144-alpha` e code `1344`. |
| `docs/04_sistemas_e_gameplay/SISTEMA_DE_INTERFACE_HUD.md` | Documentação atualizada com a navegação livre, vegetação reativa e fechamento no backdrop. |
| `docs/historico_melhorias/INDICE_MELHORIAS.md` | Registro canônico da melhoria 194. |

---

## 4. Validação e Qualidade
- **Zero Warnings:** Execução limpa no Godot 4.7.1 sem warnings ou erros.
- **Testes Automatizados:** Testado e aprovado com script headless cobrindo:
  1. Ilha 1 iniciando com vegetação 3D visível.
  2. Swipe para Ilha 2 gerando e ativando vegetação 3D na ilha 2.
  3. Swipe para Ilha 3 permitindo navegação livre com vegetação 3D ativa.
  4. Abertura do modal de Configurações a partir da aba Garagem ativa.
  5. Fechamento do modal de Configurações via clique no Backdrop.
