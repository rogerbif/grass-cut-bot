# Melhoria 129: Câmera com Zoom Dinâmico por Nível da Lâmina (50% a 100%)

**Data:** 27 de Outubro de 2026  
**Versão:** `v0.12.52-alpha`  
**Autor:** Antigravity  

---

## 1. Contexto e Motivação

Até a versão anterior, a câmera isométrica mantinha distância estática de $7,40\text{m}$ (`offset = Vector3(0.0, 4.78, 5.65)`) independentemente do estágio da partida. Embora ideal para a lâmina gigante de nível 6 (MAX), essa distância deixava o robô visualmente pequeno no início da fase (Nível 1 com lâmina de $0,90\text{m}$ de raio), reduzindo a sensação de conexão com o cortador e o impacto visual da grama recém-ceifada.

Esta melhoria implementou um **sistema de zoom dinâmico adaptativo** que posiciona a câmera **50% mais próxima no Nível 1** ($3,70\text{m}$) e a afasta suave e gradualmente conforme o jogador corta vegetação e sobe o nível da lâmina, atingindo os **100% da distância canônica** ($7,40\text{m}$) no Nível 6 MAX.

---

## 2. Implementações Realizadas

### 2.1. Câmera Isométrica com Zoom Adaptativo (`scripts/camera/isometric_camera.gd`)
- **Proporção Linear por Nível:**
  - Nível 1: 50% ($3,70\text{m}$, `offset = Vector3(0.0, 2.390, 2.825)`).
  - Níveis 2 a 5: Incremento de +10% de distância por nível ($4,44\text{m}$, $5,18\text{m}$, $5,92\text{m}$, $6,66\text{m}$).
  - Nível 6 (MAX): 100% ($7,40\text{m}$, `offset = Vector3(0.0, 4.780, 5.650)`).
- **Transição Suave Desacelerada (`Tween`):**
  - Ao subir de nível (ou descer por choque com rochas), a câmera executa um `Tween` cúbico desacelerado de $0,75\text{s}$ (`TRANS_CUBIC`, `EASE_OUT`), garantindo zero solavancos.
- **Sincronização em Tempo Real:**
  - Conexão nativa ao sinal `UpgradeManager.blade_level_changed`.
  - Em `reset_cam()`, inicialização instantânea no offset correto sem atraso de animação.
  - Preservação integral da transição de vitória para o close-up heroico (`VICTORY_OFFSET = Vector3(0.0, 1.25, 4.0)`, pitch $-8^\circ$).

---

## 3. Verificação Visual e GPU

- Capturas diretas de viewport da GPU confirmaram:
  - **Lâmina Nível 1 (`snap_zoom_lv1.png`):** enquadramento aproximado e intimista a 50% da distância, destacando a textura, partículas e a serra compacta.
  - **Lâmina Nível 6 MAX (`snap_zoom_lv6.png`):** visão ampla panorâmica a 100% da distância, proporcionando excelente controle espacial com a serra estelar gigante.
- **Validação Headless:** Execução com 0 erros e 0 warnings no console do Godot.
