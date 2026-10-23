# 087 - Otimização de Performance: SubViewport da Trilha de Solo Sob Demanda (Tarefa 1.2) 🎨⚡

## 1. Contexto e Diagnóstico
A máscara contínua de solo aparado sob os tufos ceifados (`LawnCutTrail`) é pintada dinamicamente através de um nó `SubViewport` (256x256) em `scripts/level/lawn_cut_trail.gd`.
- **Gargalo Anterior:** O viewport estava configurado com `render_target_update_mode = SubViewport.UPDATE_ALWAYS`.
- **Consequência:** A engine e a GPU executavam a renderização desse canvas secundário em todos os 60 frames por segundo (3.600 vezes por minuto), gerando trocas de contexto de renderização (*framebuffer switches*) e draw calls ociosas mesmo quando o cortador estava parado, manobrando sem cortar ou com o jogo pausado.

---

## 2. Solução Implementada

### A. Renderização Sob Demanda (`UPDATE_ONCE`)
Em [`scripts/level/lawn_cut_trail.gd`](../../scripts/level/lawn_cut_trail.gd):
- Na inicialização (`_ready()`), o viewport é colocado em `SubViewport.UPDATE_ONCE`.
- No método `paint()`, quando um novo ponto mundano é adicionado à fila `_points_to_draw` (após passar pelo limiar de distância de 0.005m²), aciona-se:
  ```gdscript
  if viewport != null:
      viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
  ```
- O Godot renderiza exatamente 1 único quadro off-screen da máscara cumulativa e retorna automaticamente para o modo ocioso (`UPDATE_DISABLED`).

### B. Limpeza Atômica no `reset_trail()`
Ao reiniciar a fase ou resetar o benchmark:
- `viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE` combinado com `viewport.render_target_update_mode = SubViewport.UPDATE_ONCE` assegura que o canvas seja esvaziado em 1 frame e permaneça em repouso ocioso em seguida.

---

## 3. Preservação Visual e Ganhos
- **Estética Inalterada:** O solo mantém a mesma transição suave para o tom verde claro mowed (`mowed_color`) e acumulação orgânica permanente (`CLEAR_MODE_NEVER`).
- **Custo Zero em Ociosidade:** Eliminação de 100% dos ciclos ociosos de renderização secundária da GPU quando o jogador não estiver ativamente ceifando novo solo.

---

## 4. Arquivos Modificados
- [`scripts/level/lawn_cut_trail.gd`](../../scripts/level/lawn_cut_trail.gd): Implementação do ciclo sob demanda (`UPDATE_ONCE`).
- [`scripts/core/game_version.gd`](../../scripts/core/game_version.gd): Avanço para `v0.12.11-alpha`.
- [`project.godot`](../../project.godot) & [`export_presets.cfg`](../../export_presets.cfg): Sincronização do versionamento SemVer (build `1211`).
