# Melhoria 141: Calibração de Mastigação Contínua da Lâmina (0.28s) e Remoção de Knockback em Vegetação 🌿⚙️

## 🎯 Objetivo e Contexto
1. **Resolução da Percepção de Travamento / Não-Registro de Golpes em Plantas Resistentes:**
   - Anteriormente, plantas com mais de 1 ponto de vida (trigo com 2 HP e flores com 3 HP) possuíam um cooldown entre golpes de $1.0\text{ segundo}$ (`MULTI_HIT_COOLDOWN_SEC = 1.0`).
   - Somado a isso, no primeiro golpe contra o caule da planta, o cortador recebia um impulso reverso de knockback (`velocity = dir * 2.15 m/s`) com atordoamento temporário (`is_stunned = true` por $0.08\text{s}$).
   - Essa combinação gerava um forte atrito de jogabilidade: o jogador via a lâmina girando a $720^\circ/\text{s}$ colada na planta, mas ao segurar o joystick contra ela, ficava imobilizado por 1 segundo inteiro sem causar dano, criando a falsa impressão de que a colisão havia falhado e que era necessário recuar e investir novamente para desferir o segundo golpe.
2. **Implementação da Mecânica de Mastigação Contínua (Game Feel Satisfatório):**
   - Recalibração do intervalo de golpes para **$0.28\text{s}$**, transformando o contato prolongado em uma sequência rápida e ritmada de cortes sucessivos.
   - Remoção do knockback reverso e do atordoamento na vegetação: o robô não é mais arremessado para trás em plantas colhíveis (o knockback e stun passam a ser mecânicas estritamente punitivas de **rochas e obstáculos sólidos**).
   - Preservação da contenção física via colisão rígida (`resolve_rigid_plant_collision`), impedindo o robô de atravessar a planta enquanto ela estiver viva, enquanto a lâmina a fatia em frações de segundo.
   - Enriquecimento sensorial: golpes parciais em plantas resistentes agora disparam áudio de corte imediato, pulso háptico mobile suave e ejeção de fragmentos de palha (no trigo) e pétalas/desprendimento (nas flores).

---

## 🛠️ Alterações Realizadas

### 1. Grade Espacial e Ciclo de Corte (`scripts/plants/vegetation_grid.gd`)
- Redução da constante `MULTI_HIT_COOLDOWN_SEC` de **$1.0\text{s}$** para **$0.28\text{s}$**.
- No bloco de golpe parcial (`health > power`):
  - Inclusão de reprodução de SFX de corte imediato: `AudioManager.play_cut_sfx(false)`.
  - Disparo de pulso háptico suave: `gm.call("trigger_haptic_cut")`.
  - Emissão de partículas de palha para trigo em golpes parciais: `PlantScript.spawn_grass_cut_particles(...)`.

### 2. Entidade Individual de Planta (`scripts/plants/plant.gd`)
- Atualização do rate-limit de corte de $1.0\text{s}$ para **$0.28\text{s}$**.
- Inclusão de feedback sonoro (`AudioManager.play_cut_sfx(false)`), vibração háptica (`GameManager.trigger_haptic_cut()`) e ejeção de partículas de trigo em danos parciais.

### 3. Física do Cortador (`scripts/cutter/cutter.gd`)
- Em `_trigger_plant_first_hit_knockback(_normal: Vector3)`:
  - Removido `is_stunned = true` e `stun_timer = 0.08`.
  - Removido o impulso reverso de velocidade (`velocity = dir * 2.15`).
  - Mantida e suavizada a compressão elástica de suspensão (`shock_compression = -0.016`), transmitindo ao chassi a mordida mecânica do dente de serra no caule sem retirar a tração ou o controle direcional do jogador.

### 4. Documentação Canônica
- Atualizados os documentos canônicos [`docs/02_entidades_e_mecanicas/SISTEMA_DE_VEGETACAO.md`](../02_entidades_e_mecanicas/SISTEMA_DE_VEGETACAO.md) e [`docs/04_sistemas_e_gameplay/GAME_FEEL_E_HAPTICS.md`](../04_sistemas_e_gameplay/GAME_FEEL_E_HAPTICS.md) documentando a mastigação contínua de 0.28s e a separação conceitual entre choque de obstáculo (knockback/stun) vs corte de vegetação (colisão rígida sem recuo).

---

## ✅ Verificação e Testes
1. **Novo Teste Automatizado:** Criados `tests/test_multi_hit_continuous.gd` e `tests/test_multi_hit_continuous.tscn`:
   - Valida `MULTI_HIT_COOLDOWN_SEC == 0.28`.
   - Valida que o cortador não entra em `is_stunned` e mantém sua velocidade ao contatar plantas resistentes.
   - Valida compressão mecânica na suspensão (`shock_compression < 0.0`).
2. **Suíte Existente:** `tests/test_wheat_level_02.tscn` executado em modo headless com sucesso (0 erros, 100% dos testes concluídos).
