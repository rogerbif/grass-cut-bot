# Melhoria 208: Feedback Sonoro Universal e Desacoplamento de Metas na Vegetação 🌿🔊

**Data:** 09/11/2026  
**Versão Canônica:** `v0.12.159-alpha`  
**Escopo:** Sonoplastia, Game Feel, `VegetationGrid`, Desacoplamento Físico de Metas.

---

## 1. Contexto & Diagnóstico da Falha

Ao testar a calibração de volume dos efeitos sonoros, foi observado que a **grama verde parecia estar sem som de corte**, enquanto a **grama vermelha tinha som normal**.

### Causa Raiz Identificada:
1. **Acoplamento Incorreto do Áudio às Metas da Fase:**
   - O disparo de áudio de corte (`AudioManager.play_cut_sfx`) para plantas ceifadas estava delegado exclusivamente dentro de `GameManager.register_cut()`.
   - No `VegetationGrid`, quando a fase possui metas customizadas (`_has_custom_goals = true`), o método `gm.register_cut()` só era invocado se a planta cortada fosse **explicitamente um dos objetivos da fase** (`if not _has_custom_goals or _has_goal_safe(target_goal)`).
   - Em fases onde a grama vermelha (ou outra variedade) é meta, mas a grama verde não é (estando no terreno apenas como vegetação insular ou decorativa), **a grama verde nunca invocava `register_cut`**, resultando em **zero som** e zero vibração háptica ao ser cortada.
2. **Throttling do Agrupador Canônico (6:1):**
   - Para gramas que eram meta, `register_cut` só disparava a cada 6 tufos acumulados (`acc >= GRASS_TUFTS_PER_UNIT`), deixando os 5 tufos intermediários silenciosos caso não houvesse disparo direto na malha.
3. **Flores e Plantas Resistentes:**
   - Já possuíam chamada direta em `VegetationGrid` no golpe parcial (`new_hp > 0`), acentuando a sensação de que espécies coloridas/vermelhas tinham som e a grama verde não.

---

## 2. Solução Implementada

- **Disparo Direto e Universal no Ponto de Corte:**
  - Em `scripts/plants/vegetation_grid.gd`, no momento em que qualquer tufo tem sua vida zerada (`new_hp <= 0`), foi injetada a chamada direta defensiva a `AudioManager.play_cut_sfx(false)` e `GameManager.trigger_haptic_cut()`.
- **Proteção por Cooldown Nativo (40ms):**
  - O `AudioManager` já possui controle de *debounce* rígido de 40ms (`CUT_COOLDOWN_MS = 40`), garantindo que o som de corte seja reproduzido com ritmo limpo, sem cacofonia ou sobreposição metálica, independentemente de quantas plantas sejam fatiadas no mesmo frame.

---

## 3. Validação

- Executado teste em `tests/test_audio_manager.tscn` e `tests/test_multi_hit_continuous.tscn` no Godot Headless 4.7.2.
- Agora, qualquer tipo de vegetação (seja grama verde, vermelha, azul, trigo ou flores), fazendo parte ou não dos objetivos da fase, sempre produz o som crocante e suave de corte e o feedback háptico.
