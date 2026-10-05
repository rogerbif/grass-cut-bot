# Melhoria 005: Câmera Isométrica com Rotação Travada e Translação Pura (X e Z) 🎥🔒

Este documento consolida o plano de diagnóstico, implementação e walkthrough da eliminação de oscilações e rotações dinâmicas na câmera isométrica de **Grass Cut Bot**, garantindo enquadramento perfeitamente estável através de translação linear exclusiva nos eixos $X$ e $Z$.

---

## 📋 Resumo Executivo
- **Data da Conclusão:** Outubro de 2026
- **Versão SemVer:** `v0.2.5`
- **Domínio:** Game Feel, Câmera e Controles
- **Objetivo:** Corrigir a sensação de rotação/wobble da câmera durante a movimentação do cortador. A chamada contínua de `look_at()` no loop de processamento recalculava a orientação angular a cada frame enquanto a posição interpolava com atraso (`lerp`), gerando oscilações visuais indesejadas em curvas e acelerações.

---

## 🔍 Diagnóstico do Problema
1. **Chamada Contínua de `look_at()`:** No script [`isometric_camera.gd`](../../scripts/camera/isometric_camera.gd), a cada frame do `_process(delta)` executava-se:
   ```gdscript
   var look_target = target.global_position + Vector3(0, 0, -0.5)
   look_at(look_target, Vector3.UP)
   ```
2. **Deslocamento por Interpolação Linear:** Como a posição global da câmera acompanhava o cortador via amortecimento `lerp(desired_pos, follow_speed * delta)`, a câmera sempre ficava ligeiramente defasada da posição instantânea do alvo.
3. **Efeito Visual Resultante:** O vetor relativo entre a câmera e o `look_target` variava de direção continuamente conforme o jogador manobrava, girando a câmera em guinada (*yaw*) e arfagem (*pitch*), o que prejudicava a clareza e causava desconforto visual.

---

## 🎯 Arquitetura da Solução Técnica

1. **Rotação Rigidamente Travada:**
   - A orientação isométrica é estabelecida uma única vez no `_ready()` via `look_at_from_position()`.
   - A matriz de orientação da câmera (`basis`) permanece inalterada durante toda a partida, garantindo que o ângulo zenital nunca sofra micro-rotações.

2. **Translação Suave Exclusiva em $X$ e $Z$:**
   - Apenas as coordenadas horizontais ($X$ e $Z$) são interpoladas suavemente em relação ao cortador com fator seguro `clampf(follow_speed * delta, 0.0, 1.0)`.
   - A altura vertical $Y$ da câmera é mantida estritamente fixa (`target.global_position.y + offset.y`), sem subidas ou descidas repentinas.

3. **Camera Shake Puramente Translacional:**
   - O efeito de impacto com rochas/obstáculos foi mantido, mas perturba apenas o vetor de posição ($X$ e $Z$), preservando os ângulos de rotação intactos.

---

## 🛡️ Conformidade de Guardrails Invariantes
- **Zero Warnings:** 0 avisos no console Godot 4.
- **Tipagem Estrita:** Uso de `lerpf`, `clampf` e variáveis fortemente tipadas em GDScript 4.
- **Game Feel Isométrico Arcade:** Enquadramento clássico e sólido, ideal para jogos de corte em modo Portrait móvel.
