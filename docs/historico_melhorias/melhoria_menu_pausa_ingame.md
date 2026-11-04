# Relatório de Melhoria: Novo Menu de Pausa Ingame (Cyberpunk Neon & Refinamentos) ⏸️🤖

**Versão:** `v0.12.117-alpha`  
**Data:** 04/11/2026  
**Status:** Concluído com Sucesso

---

## 🎯 Objetivos Realizados

1. **Substituição do Modal Legado de Pausa:**
   - Criada a cena modular [`scenes/ui/pause_modal.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/ui/pause_modal.tscn) controlada por [`scripts/ui/pause_modal.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/ui/pause_modal.gd), substituindo o painel genérico cinza em [`scenes/ui/hud.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/ui/hud.tscn).
   - Configuração estrita de `process_mode = PROCESS_MODE_ALWAYS` (Node 3) para permitir interatividade completa com a árvore pausada (`get_tree().paused = true`), em total conformidade com o **Guardrail 9**.

2. **Design Visual Cyberpunk Neon & Novos Ícones Canônicos:**
   - **Placa Principal:** Fundo escuro azul-noite profundo com chanfros nos 4 cantos, contorno com gradiente neon ciano para roxo (`assets/ui/pause/card_pause_bg.svg`) e as 3 ranhuras diagonais decorativas (`///`) no topo direito.
   - **Cabeçalho:** Ícone duplo `||` em ciano neon vibrante, tipografia `"Jogo Pausado"` e **botão de fechar `[X]`** em ciano neon no canto superior direito (`assets/ui/pause/btn_close_x.svg`).
   - **Botão Continuar:** Moldura verde neon com o **triângulo de play oficial** do botão de início de fase em verde neon (`assets/ui/pause/icon_play_triangle_green.svg`).
   - **Botão Reiniciar Fase:** Moldura ciano/azul com a **nova seta circular de refresh** no mesmo padrão geométrico e limpo (`assets/ui/pause/icon_restart_cyber.svg`).
   - **Botão Menu Inicial:** Moldura roxo/magenta com o **ícone oficial da casinha da barra de navegação inferior** (`assets/icons/navbar/nav_icon_home.svg`).

3. **Alinhamento e Proximidade de Ícones:**
   - Ícone e texto centralizados juntos no miolo de cada botão com distância justa de `12px`, eliminando o espaçamento vazio excessivo.

4. **Interação com Backdrop e Animações Dinâmicas:**
   - **Toque Fora:** Clicar ou tocar no backdrop semi-transparente fora do card fecha o menu e retoma o gameplay instantaneamente.
   - **Grow + Fade In:** Ao abrir, escala de `0.85 -> 1.0` com curva elástica `TRANS_BACK` e fade de opacidade.
   - **Shrink + Fade Out:** Ao fechar, escala de `1.0 -> 0.85` com curva `TRANS_CUBIC` e fade out de opacidade.
   - Ambos os tweens utilizam `TWEEN_PAUSE_PROCESS` para fluidez com a árvore de nós pausada.

5. **Padding Inferior Compacto:**
   - Altura do card calibrada para 470px (`content_margin_bottom = 14.0`), eliminando a sobra de fundo azul e equilibrando a distância da base com as margens laterais.

6. **Trio de Mini-Cards Inferiores (Toggles Rápidos):**
   - Mini-cards chanfrados verticais para **FX**, **Música** e **Vibrar**.
   - Switches tipo pílula ciano neon (ON à direita / OFF à esquerda) sincronizados com [`AudioManager`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/core/audio_manager.gd), [`SaveManager`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/core/save_manager.gd) e retorno tátil (`Input.vibrate_handheld(25)`).

---

## 📂 Arquivos Modificados e Criados

- `assets/ui/pause/`: Criação de novos assets vetoriais (`icon_play_triangle_green.svg`, `icon_restart_cyber.svg`, `btn_close_x.svg`, placas e botões neon).
- `scripts/ui/pause_modal.gd`: Implementação do botão [X], alinhamento agrupado ícone+label, animações Grow/Shrink e fechamento por toque no backdrop.
- `project.godot` e `scripts/core/game_version.gd`: Incremento de versão para `0.12.117-alpha`.
- `docs/historico_melhorias/INDICE_MELHORIAS.md`: Atualização no índice canônico.
