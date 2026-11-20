# Histórico de Melhorias: Pacote 4 — Perfil Econômico (`"eco"`) Completo & Higiene Final da Suíte de Testes ⚡🌿

**Versão Associada:** `v0.12.210-alpha`  
**Data de Conclusão:** 20/11/2026  
**Status:** Concluído e Validado  

---

## 1. Visão Geral e Contexto do Problema

1. **Perfil Gráfico `"eco"` Incompleto:** Anteriormente, ao selecionar o perfil **Econômico (`"eco"`)** no `SettingsModal`, `GameManager.apply_graphics_quality()` reduzia apenas `viewport.scaling_3d_scale` para `0.70`, mantendo o Shadow Map da `DirectionalLight3D` ligado e o orçamento cheio de partículas de corte.
2. **Condição de Raiz do Trigo & Higiene em `tests/`:**
   - Em `assets/models/wheat_01.glb` (remodelado em `v0.12.178+`), `TEXCOORD_0` já chega ao Godot com `UV.y = 0.0` no solo e `UV.y = 1.0` no topo (após a inversão de eixo V do exportador glTF), enquanto `COLOR_0` está todo branco `(1, 1, 1)` (o gradiente foi gravado em `COLOR_1`, ignorado por `COLOR`). Como `interactive_wheat_material.tres` tinha `invert_height = true`, a regra anterior `invert_height ? (1.0 - UV.y) : UV.y` seguida de `if (invert_height && COLOR.r > 0.001) raw_h = COLOR.r;` fazia toda a malha de trigo receber `raw_h = 1.0` (sem ancoragem gradual da raiz ao topo).
   - `tests/test_wheat_shader.gd` ainda validava `1.0 - UV.y` sem ler `ARRAY_COLOR`.
   - `tests/test_menu_bot_teleport.gd` imprimia sucesso sem invocar `get_tree().quit(0)`.

---

## 2. Modificações Implementadas

### 2.1 Sombras Direcionais & Partículas Escaláveis no Perfil `"eco"`
- **`scripts/core/game_manager.gd`:**
  - Adicionados `var current_graphics_profile: String = "balanced"` e `func is_eco_graphics() -> bool`.
  - Atualizado `apply_graphics_quality(profile: String)` para armazenar `current_graphics_profile`, manter `scaling_3d_scale` (`1.0`, `0.85`, `0.70`) e propagar `_apply_shadow_quality_recursive(get_tree().root, current_graphics_profile != "eco")` para todas as `DirectionalLight3D` da árvore.
  - Em `_on_scene_node_added()`, novas `DirectionalLight3D` que entrem na árvore já recebem `shadow_enabled = (current_graphics_profile != "eco")`.
- **`scripts/level/level_controller.gd`:**
  - Após `ThemeDatabase.apply_theme_to_scene()`, assegura `sun.shadow_enabled = false` quando `GameManager.is_eco_graphics()` for verdadeiro (sem afetar `"balanced"` e `"high"`).
- **`scripts/plants/plant.gd`:**
  - Adicionado cache defensivo `static var _cached_gm: Node = null` (Mandamento 16).
  - Em `_emit_sub_burst()`, quando `is_eco_graphics()` estiver ativo, reduz `final_count` para `maxi(1, int(ceilf(float(count) * 0.5)))` e atualiza `emitter.amount` apenas quando alterado.

### 2.2 Âncora da Raiz do Trigo & Higiene de Testes
- **`shaders/interactive_grass.gdshader`:**
  - Alterada a base de `raw_h` para `float raw_h = UV.y;` (alinhando tanto `grass_01.glb` quanto `wheat_01.glb`, onde `UV.y = 0.0` no solo e `1.0` no topo), usando `if (invert_height && has_baked_attr) { raw_h = COLOR.r; }` quando houver atributos não-dummy assados em `COLOR_0`, e preservando `if (invert_height)` no final do `vertex()` para manter normais geométricas 3D nas espigas de trigo.
- **`tests/test_wheat_shader.gd`:**
  - Atualizado para ler `Mesh.ARRAY_COLOR` e espelhar a regra canônica `UV.y` (`COLOR.r` quando `has_baked_attr`), além de liberar `wheat_node` antes de sair.
- **`tests/test_menu_bot_teleport.gd`:**
  - Adicionado `get_tree().quit(0)` ao término dos asserts de teleporte.

---

## 3. Arquivos Modificados

| Arquivo | Modificação |
| :--- | :--- |
| `scripts/core/game_manager.gd` | Estado `current_graphics_profile`, `is_eco_graphics()`, propagação de `shadow_enabled` em `DirectionalLight3D`. |
| `scripts/level/level_controller.gd` | Garantia de `sun.shadow_enabled = false` no modo `"eco"` após `ThemeDatabase.apply_theme_to_scene`. |
| `scripts/plants/plant.gd` | Cache `_cached_gm` e corte de 50% de `amount` no pool `CPUParticles3D` quando em `"eco"`. |
| `shaders/interactive_grass.gdshader` | Regra `raw_h = UV.y` com override condicional `has_baked_attr -> COLOR.r` ancorando `y = 0.0` em `wheat_01.glb`. |
| `tests/test_wheat_shader.gd` | Inspeção de `Mesh.ARRAY_COLOR` + `UV.y` alinhada ao shader e `free()` antes de `quit()`. |
| `tests/test_menu_bot_teleport.gd` | Encerramento automático via `get_tree().quit(0)`. |
| `scripts/core/game_version.gd`, `project.godot`, `export_presets.cfg` | Bump SemVer `0.12.210-alpha` (`version/code=1410`). |
| `docs/05_arquitetura_e_desenvolvimento/PLANO_MESTRE_DE_PERFORMANCE.md` | Registro da tarefa 3.8 (Pacote 4) como concluída. |

---

## 4. Testes e Validação (Headless CLI)

Executados após a edição final na versão `v0.12.210-alpha` com **0 erros/warnings**:
- `res://tests/test_wheat_shader.gd` — **Aprovado** (`exit code 0`, `Base bend_factor = 0.0`, `Tip bend_factor = 1.0`).
- `res://tests/test_wheat_level_02.tscn` — **Aprovado** (`exit code 0`).
- `res://tests/test_menu_bot_teleport.tscn` — **Aprovado** (`exit code 0` automático).
- `res://tests/test_all_botanical_variations.gd` — **Aprovado** (`exit code 0`).
- `res://tests/test_flower_detach.gd` — **Aprovado** (`exit code 0`).
- `res://tests/test_vegetation_spatial_index.tscn` — **Aprovado** (`GOLDEN_RESULT|PASS`, `exit code 0`).
- `res://tests/test_android_lifecycle_and_navigation.tscn` — **Aprovado** (`exit code 0`).
- `res://scenes/main.tscn` (`--headless --quit`) — **Aprovado** (`exit code 0`).
