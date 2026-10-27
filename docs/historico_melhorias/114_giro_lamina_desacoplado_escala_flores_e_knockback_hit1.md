# Melhoria 114: Giro da Lâmina (+20% e Desacoplado do Yaw), Flores +30% e Knockback Curto no 1º Hit 🪚🌸⚡

**Versão:** `v0.12.39-alpha`  
**Data:** 27/10/2026

---

## 1. Contexto e Motivação

O usuário solicitou quatro ajustes de Game Feel e leitura visual:
1. **Aumentar o giro da lâmina em +20%** tanto em stand (marcha lenta/idle) quanto ativa (em movimento).
2. **Desacoplar a velocidade de rotação da lâmina do giro do robô:** Como `blade_spinner` estava reparentada como filha de `robot_body`, quando o robô girava no sentido horário ou anti-horário (`robot_body.rotation.y`), a velocidade angular do chassi somava-se ou subtraía-se do giro da lâmina ($\omega_{\text{world}} = \omega_{\text{blade}} + \omega_{\text{body\_yaw}}$), fazendo a serra parecer acelerar ou desacelerar conforme a direção da curva.
3. **Aumentar o tamanho das flores em +30%** para maior presença visual e leitura das 8 espécies.
4. **Aplicar um knockback bem curto no primeiro hit** em plantas com mais de 1 vida (`wheat` e `flower_*`).

---

## 2. Alterações Implementadas

### 2.1. Velocidade de Giro da Lâmina (+20%) e Independência de Yaw (`cutter.gd` e `menu_bot.gd`)
- **`scripts/cutter/cutter.gd`**:
  - `rotation_speed`: ampliada de `600.0 °/s` para **`720.0 °/s`** (+20%).
  - `idle_rotation_speed`: ampliada de `90.0 °/s` para **`108.0 °/s`** (+20%).
  - `blade_spinner` permanece sob seu nó pai original (`$VisualPivot/GrassBot/Robot`, irmã de `Body`) em vez de sofrer `reparent(robot_body)`.
  - A função `_sync_blade_spinner_transform()` sincroniza a posição 3D da lâmina e seu plano de inclinação (`Quaternion(Vector3.UP, robot_body.basis.y.normalized())`) com o pitch, roll e suspensão de `robot_body`, mas aplica o ângulo acumulado da serra (`_blade_spin_angle`) de forma **100% independente do yaw (`rotation.y`) do corpo**.
- **`scripts/menu/menu_bot.gd`**:
  - `blade_rotation_speed`: ampliada de `75.0 °/s` para **`90.0 °/s`** (+20%) e sincronizada com o mesmo desacoplamento de yaw via `_sync_blade_spinner_transform()`.

### 2.2. Escala Visual das Flores (+30%) (`vegetation_grid.gd`, `island_node.gd`, `plant.gd`)
- **`scripts/plants/vegetation_grid.gd`** e **`scripts/menu/island_node.gd`**:
  - Escala base de todas as flores (`flower`, `flower_rose`, `flower_daisy`, `flower_sunflower`, `flower_bell`, `flower_corolla`, `flower_tulip`, `flower_bed`) ampliada em +30%: de `0.52` para **`0.676`**.
  - Raio de colisão rígida das flores em `resolve_rigid_plant_collision` ajustado proporcionalmente para **`0.23m`** (`0.18 * 1.30`), mantendo `0.18m` para o trigo.
- **`scripts/plants/plant.gd`**:
  - Escala randômica para instâncias `PlantType.FLOWER` (usadas no Editor de Fases e fallback) ampliada de `0.48..0.58` para **`0.624..0.754`** (+30%).

### 2.3. Knockback Curto no 1º Hit de Plantas Resistentes (`vegetation_grid.gd` e `cutter.gd`)
- **`scripts/plants/vegetation_grid.gd`**:
  - `cut_in_circle()` agora retorna um `Vector3` representando a direção normalizada de recuo quando qualquer planta com `_max_health[p_idx] > 1` sofre seu **primeiro golpe** (`old_hp == _max_health[p_idx]` e `new_hp > 0`).
- **`scripts/cutter/cutter.gd`**:
  - Adicionado `_trigger_plant_first_hit_knockback(normal: Vector3)` aplicando um recuo curto e tátil (`stun_timer = 0.08s`, `velocity = dir * 2.15 m/s`, `shock_compression = -0.022`).
  - Removido o bloqueio de deslocamento mínimo em `_process_cutting()` e mantida a execução de `_process_cutting()` durante `is_stunned` para que o tremor contínuo de 65Hz e os cortes subsequentes de 1.0s nunca sejam interrompidos quando o robô permanece encostado na planta.

---

## 3. Verificação e Validação

- Execução headless em `res://scenes/main.tscn` e `res://scenes/menu/main_menu.tscn` validada com **0 warnings e 0 erros**.
