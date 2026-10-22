# Melhoria 071: Detecção Perimétrica da Lâmina contra Rochas e Ricochete Ampliado

**Data:** 21 de Outubro de 2026  
**Versão:** `v0.10.8-alpha` (Build Code: `1008`)  
**Status:** Concluído com Sucesso  

---

## 1. Contexto e Motivação
Anteriormente, o sistema de colisão do robô com as pedras (`scenes/obstacles/rock.tscn`) dependia exclusivamente do `get_slide_collision()` do `CharacterBody3D`, que utilizava o colisor físico do chassi (`$BodyCollision`, cilindro de raio $0.30\text{m}$). Como a rocha possui raio cilíndrico de $0.36\text{m}$, o choque só era registrado quando a distância centro-a-centro ficava abaixo de $0.66\text{m}$.
Entretanto, a serra giratória possui raio base de $0.90\text{m}$ (e se expande até $1.35\text{m}$ com upgrades). Ao se aproximar de qualquer rocha, a serra penetrava visualmente até $0.60\text{m}$ para dentro da malha da pedra antes de qualquer colisão física ou reação do robô ser acionada, causando a ilusão de que a lâmina era "fantasma".

Adicionalmente, a força de ricochete anterior (`knockback_force = 5.0`) e tempo de stun (`0.18s`) eram discretos, não transmitindo a energia mecânica violenta de uma serra de rotação extrema colidindo com uma rocha maciça.

---

## 2. Alterações Implementadas

### 2.1 Detecção Perimétrica Serra-Rocha no `cutter.gd`
- Implementada varredura contínua no `_check_obstacle_collisions()` iterando sobre os nós do grupo `"obstacles"`:
  - Distância de alcance crítico calculada dinamicamente: `var blade_reach: float = _cached_blade_radius + 0.36`.
  - Quando a distância horizontal entre o centro do cortador e o obstáculo é inferior a `blade_reach`, calcula-se a normal de repulsão (`normal_3d`) e o ponto exato de fricção mecânica dente-de-serra (`spark_pt = global_position - normal_3d * (_cached_blade_radius * 0.85)`).
  - Bloqueio elástico instantâneo da posição horizontal do cortador (`global_position += normal_3d * overlap`), impedindo 100% qualquer penetração visual da lâmina para dentro da malha da pedra, mesmo que o jogador empurre o analógico continuamente contra ela.

### 2.2 Ricochete Ampliado (Arremesso para Longe)
- `knockback_force` elevado de `5.0` para `9.5 m/s`, arremessando o robô para trás a uma distância de aproximadamente $1.2\text{m}$ com o atrito reforçado da desaceleração.
- `stun_timer` aumentado de `0.18s` para `0.24s`, garantindo tempo para o impacto visual ser lido claramente pelo jogador antes que o joystick retome o controle linear.
- `_shock_cooldown` adicionado com duração de `0.32s` para evitar tremores caóticos ou múltiplos disparos consecutivos em frames vizinhos caso o jogador mantenha o analógico direcionado para a pedra.
- Afundamento de suspensão (`shock_compression = -0.07`), transmitindo o recuo mecânico bruto no chassi.

### 2.3 Feedback Sensorial e Efeito de Faíscas
- `spark_particles` configurado com `top_level = true` para emitir faíscas metálicas exatamente no ponto de fricção (`spark_pt`), sem ser arrastado pelo recuo inercial do chassi.
- Expressão de olhos com raio/raiva do robô acionada (`robot_eyes.trigger_obstacle_reaction()`).
- Vibração háptica de 60ms e camera shake de alta fidelidade via `GameManager.trigger_haptic_impact()`.

---

## 3. Arquivos Modificados
- [`scripts/cutter/cutter.gd`](../../scripts/cutter/cutter.gd): Adicionada detecção perimétrica de lâmina, cooldown de choque `_shock_cooldown`, bloqueio instantâneo de overlap, ponto dinâmico de faíscas metálicas e aumento do knockback para `9.5`.
- [`scripts/core/game_version.gd`](../../scripts/core/game_version.gd): Incrementado para `v0.10.8-alpha` (code `1008`).
- [`project.godot`](../../project.godot): Atualizado `config/version="0.10.8-alpha"`.
- [`export_presets.cfg`](../../export_presets.cfg): Atualizado `version/code=1008` e `version/name="0.10.8-alpha"`.

---

## 4. Verificação e Qualidade
- **Execução Headless Godot 4.7.1:** 0 warnings e 0 erros de compilação ou execução.
- **Game Feel:** Lâmina rebate na borda externa de qualquer rocha, lançando o robô para trás com faíscas, olhos vermelhos e vibração contínua.
