# Melhoria 111: Recalibração de Hits, Rigidez de Vegetação e Física do Cortador 🪚🌸

Este documento registra a implementação canônica da recalibração do sistema de hits, rigidez de plantas resistentes, redução de velocidade de rotação da lâmina e recuo de colisão com rochas em **Grass Cut Bot**, avançando a versão para `v0.12.35-alpha`.

---

## 1. Motivação e Objetivos

1. **Janela Tática de Cooldown por Hit (1.0s):** Plantas resistentes com mais de 1 vida (trigo com 2 HP e flores com 3 HP) agora exigem 1.0 segundo entre cada corte (`MULTI_HIT_COOLDOWN_SEC = 1.0`), tornando o corte mais cadenciado e tático.
2. **Micro-Tremor Mecânico Contínuo (~65Hz):** Enquanto a serra estiver em contato ativo com a planta resistente durante o cooldown de 1.0s, o tufo vibra com um tremor sutil ($\pm 0.022\text{m}$), transmitindo sensorialmente o atrito dos dentes de aço contra o caule duro antes da ceifa.
3. **Rigidez Física Ativa (Bloqueio sem Atravessar):** Plantas vivas com mais de 1 vida agora impedem que o corpo do robô avance por cima ou atravesse a célula (`resolve_rigid_plant_collision`), funcionando como barreiras e labirintos vivos até serem cortadas, com suporte a deslizamento suave nas bordas (`velocity.slide(normal)`).
4. **Velocidade de Rotação da Lâmina (-50%):** A velocidade ativa de rotação da serra em movimento foi reduzida pela metade (`rotation_speed: 1200.0 -> 600.0 °/s`), permitindo clara leitura visual das pontas da estrela cortando o gramado. A rotação em marcha lenta (`idle_rotation_speed = 90.0 °/s`) foi preservada.
5. **Afastamento/Knockback contra Pedras (-50%):** A força de ricochete ao tocar rochas foi reduzida pela metade (`knockback_force: 9.5 -> 4.75 m/s`), com `stun_timer = 0.18s` e `shock_compression = -0.045`, mantendo o robô no controle imediato.

---

## 2. Modificações Técnicas

### A. Grade de Vegetação (`scripts/plants/vegetation_grid.gd`)
* `MULTI_HIT_COOLDOWN_SEC = 1.0` (era 0.22s).
* Adicionado cache `_actively_shaking_tufts` para controle estrito e restauração atômica de transforms no `MultiMesh`.
* Implementado cálculo de micro-jitter procedural em `cut_in_circle()` para instâncias dentro do raio de colisão da serra aguardando o cooldown.
* Adicionado método `resolve_rigid_plant_collision()` que consulta a grade espacial $0.40\text{m}$ e projeta o corpo do robô para fora da planta ($R_{\text{body}} = 0.30\text{m} + R_{\text{plant}} = 0.18\text{m} = 0.48\text{m}$), ajustando `velocity` via projeção ortogonal.
* Implementado acesso defensivo ao `GameManager` via `_get_game_manager()`, eliminando acoplamentos rígidos e garantindo compilação headless limpa em scripts de ferramentas (`verify_levels.gd`).

### B. Planta Individual (`scripts/plants/plant.gd`)
* Adicionado `_last_hit_time` e verificação de 1.0s em `cut(power: int)` para nós individuais instanciados fora do MultiMesh.

### C. O Cortador (`scripts/cutter/cutter.gd`)
* `rotation_speed`: reduzido de `1200.0` para `600.0 °/s`.
* `idle_rotation_speed`: mantido rigorosamente em `90.0 °/s`.
* `knockback_force`: reduzido de `9.5` para `4.75 m/s`.
* `stun_timer`: calibrado para `0.18s` (era 0.24s) e `_shock_cooldown = 0.25s`.
* `shock_compression`: calibrado para `-0.045` (era -0.07).
* Integração direta de `resolve_rigid_plant_collision` após `move_and_slide()` no estado normal e atordoado (`is_stunned`).

---

## 3. Verificação e Conformidade

1. **Zero Warnings e Compilação Limpa:**
   * Execução do Godot headless no terminal (`godot.exe --headless --editor --quit`): 0 warnings e 0 erros.
2. **Verificação de Fases:**
   * Execução de `verify_levels.gd`: 20 fases canônicas verificadas e aprovadas com sucesso.
3. **Controle de Versão:**
   * Versão incrementada para `v0.12.35-alpha` (version code 1235) sincronizada em `game_version.gd`, `project.godot` e `export_presets.cfg`.
