# Relatório de Melhoria: Navegação por Gestos (Swipe) no Menu Principal 📱🌿

**Versão:** `v0.12.143-alpha`  
**Data:** 07/11/2026  
**Status:** Concluído com Sucesso e 100% Testado  

---

## 🎯 Objetivos Realizados

1. **Detector Modular de Gestos (`MenuGestureDetector`):**
   - Criada a classe desacoplada [`scripts/menu/menu_gesture_detector.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/menu/menu_gesture_detector.gd) com suporte híbrido a touch (`InputEventScreenTouch`/`ScreenDrag`) e mouse (`InputEventMouseButton`/`MouseMotion`).
   - Implementada discriminação estrita de eixo ($1.30\times$ dominância) e threshold mínimo de $45\text{px}$ (ou flick $> 380\text{px/s}$) para erradicar conflitos com cliques acidentais ou movimentos diagonais.

2. **Navegação Vertical de Fases (Opção B - Visão do Bot na Home):**
   - Na tela inicial com a visão aproximada do robô (`BOT_VIEW`), arrastar para **baixo** avança para a próxima fase ($N + 1$) e arrastar para **cima** retorna para a fase anterior ($N - 1$).
   - O robô executa teleporte holográfico entre ilhas e o `MapLevelCard` executa animação elástica de *bump* (`play_bump_animation`).
   - Tentativas de extrapolar a Fase 1 ou a fase máxima permitida disparam feedback visual elástico de *squash & stretch* (`play_boundary_bounce`) com som sutil.

3. **Alternância Horizontal de Abas em Todo o Menu:**
   - Deslizar para a **esquerda** avança para a aba seguinte (`Home [0]` ➔ `Oficina [1]` ➔ `Coleção [2]` ➔ `Loja [3]`).
   - Deslizar para a **direita** retorna para a aba anterior.
   - Sincronização automática com a `BottomNavBar` e transição sutil em fade (`0.14s`).
   - **Zero conflito com listas:** As listas verticais (`ScrollContainer`) de Oficina, Coleção e Loja continuam operando sua rolagem vertical nativa sem qualquer interferência.

---

## 📂 Arquivos Modificados & Criados

- `scripts/menu/menu_gesture_detector.gd` [NOVO]: Classe modular para detecção e discriminação de swipes touch/mouse.
- `scripts/menu/main_menu.gd`: Integração do detector de gestos, métodos `_navigate_level_by_delta`, `_on_gesture_swipe_horizontal`, transição suave entre abas e checagem de modais abertos.
- `scripts/ui/map_level_card.gd`: Métodos `play_bump_animation` e `play_boundary_bounce` (squash & stretch).
- `project.godot` e `scripts/core/game_version.gd`: Incremento de versão Game SemVer para `0.12.143-alpha`.
- `docs/04_sistemas_e_gameplay/SISTEMA_DE_INTERFACE_HUD.md`: Documentação canônica da seção 3.6.
- `docs/04_sistemas_e_gameplay/SISTEMA_DE_CONTROLES_TOUCH.md`: Documentação canônica da seção 5.
- `docs/historico_melhorias/INDICE_MELHORIAS.md`: Indexação no catálogo mestre.

---

## 🧪 Validação & Testes

- **Suíte de Testes Automatizados:** Teste simulado completo executado via `--script` validando:
  1. Swipe vertical para baixo na Home avança de Fase 1 para Fase 2.
  2. Swipe vertical para cima na Home retorna de Fase 2 para Fase 1.
  3. Swipe horizontal para esquerda avança abas (Home ➔ Garagem ➔ Coleção).
  4. Swipe vertical na Coleção é ignorado pelo detector e não altera a fase.
  5. Swipe horizontal para direita retorna abas (Coleção ➔ Garagem ➔ Home).
- **Compilação e Estabilidade:** Validação em modo headless com **Zero Warnings** e **Zero Erros** GDScript.
