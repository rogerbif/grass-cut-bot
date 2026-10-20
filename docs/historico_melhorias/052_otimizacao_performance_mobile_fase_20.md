# 052 - Otimização de Performance Mobile na Fase 20 (Benchmark, Sombras Seletivas, Shader e Pool de Partículas) ⚡📱

## 1. Contexto e Diagnóstico em Dispositivo Android Real
Para diagnosticar com precisão o comportamento na maior fase do jogo (**Fase 20** — 1.296 tufos e 416 blocos de terreno), foi construída a cena de benchmark interativo `scenes/tools/perf_test.tscn` (`scripts/tools/perf_test.gd` e `scripts/tools/perf_probe.gd`), acessível via `F6` no PC ou tocando 3 vezes no rótulo de versão no `SettingsModal` no celular, com botões touch para alternar densidade, vegetação, sombras, `scaling_3d` e `VSync`.

### Medições Reais no Smartphone (Fase 20 - 1.296 tufos):
- **Estado Original (`veg ON | sombra ON | esc 1.00`):** `39.8 ~ 41.0 FPS` (mín. `28.9 FPS`, pior frame `34.6 ms`), `2.077 draw calls`, `654.886 primitivas`, `11.102 nós`.
- **Sem Vegetação (`veg OFF | sombra ON | esc 1.00`):** `60.0 FPS` cravados, `509 draw calls`, `22.946 primitivas`.
- **Com Vegetação e Sem Sombra (`veg ON | sombra OFF | esc 1.00`):** **`60.0 FPS` cravados (`16.7 ms`)**, **`815 draw calls` (-61%)**, **`159.706 primitivas` (-76%)**.

---

## 2. Soluções Implementadas (Execução Paralela Multiagente)

### A. Agente A — Shader Interativo e Iluminação Direcional
- **`shaders/interactive_grass.gdshader`:**
  - Eliminado o cálculo matricial `mat3(inverse(MODEL_MATRIX))` por vértice, substituído por projeção ortogonal direta usando as colunas XZ (`col_x`, `col_z`) ponderadas por `inv_scale_sq`.
  - Adicionado *early-out* por distância ao quadrado (`dist_sq < r_sq`) na deformação radial da lâmina, zerando o custo de `sqrt` e `smoothstep` fora do raio de corte.
  - Reduzida a curvatura de aproximação (`interact_power`) em 66% (`0.85 -> 0.29` nas gramas, `0.75 -> 0.26` no trigo, `0.70 -> 0.24` nas flores) para maior naturalidade visual.
- **`scenes/main.tscn`, `scenes/menu/main_menu.tscn` e `project.godot`:**
  - Configurada a `DirectionalLight3D` com `directional_shadow_mode = SHADOW_ORTHOGONAL` (1 único mapa de sombra ortogonal em vez de 4 cascatas PSSM) e `directional_shadow_max_distance = 28.0`.
  - Mapa de sombra ajustado para `1024` com `soft_shadow_filter_quality = 0`.

### B. Agente B — Cortador Reativo e Mesclagem de Colisores Costeiros
- **`scripts/cutter/cutter.gd`:**
  - Adicionado cache local de upgrades (`_cached_blade_radius`, `_cached_cutter_speed`, `_cached_cutter_power`).
  - Atualização dos parâmetros de shader (`_update_shader_globals()`) restrita apenas a quando o cortador se move (`distance_squared_to > 0.0004`).
  - Substituída a varredura `blade_area.get_overlapping_areas()` a cada frame por eventos reativos `area_entered` / `area_exited` com lista de persistência apenas para plantas resistentes (`max_health > 1`).
- **`scripts/level/level_json_loader.gd`:**
  - Implementada mesclagem gulosa (*greedy merge*) de segmentos colineares Norte/Sul e Leste/Oeste em `build_coastal_colliders_and_foam()`, reduzindo centenas de `CollisionShape3D` para ~40 caixas contínuas na Fase 20.

### C. Agente C — Sombra Seletiva nos Tufos e Pool Compartilhado de Partículas
- **Cenas `scenes/plants/*.tscn` e `scripts/plants/plant.gd`:**
  - Desativada a projeção de sombra apenas nas malhas das plantas (`cast_shadow = SHADOW_CASTING_SETTING_OFF`), preservando 100% das sombras do robô, das rochas e das falésias da ilha.
  - Removidos os 1.296 nós `CPUParticles3D` ociosos de dentro de cada cena de planta e substituídos por um **Pool Estático Compartilhado de 16 emissores** (`_particle_pool`) em `plant.gd`.
  - Liberação imediata do nó do tufo cortado ao término do Tween de `0.04s` (removendo os `SceneTreeTimer` de `1.0s`).

---

## 3. Resultados Obtidos
- **Taxa de Quadros no Android (Fase 20 em Escala 1.00):** Salto de `39.8 FPS` para **`60.0 FPS` cravados**.
- **Primitivas Renderizadas:** Redução de `654.886` para **`~159.700` (-76%)**.
- **Draw Calls:** Redução de `2.077` para **`~815` (-61%)**.
- **Contagem de Nós e Memória:** Redução de `11.102` para **`9.768` nós** (-1.334 nós de partículas/colisores) e memória estática reduzida para `79 MB`.
