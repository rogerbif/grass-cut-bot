# Histórico de Melhorias: Pacote 2 — Otimização de Shaders na GPU (Vertex ALU & TBDR Mobile) e Atualização do Gabarito Golden 🎨⚡

**Versão Associada:** `v0.12.207-alpha`  
**Data de Conclusão:** 19/11/2026  
**Status:** Concluído e Validado  

---

## 1. Visão Geral e Contexto do Problema

Para aliviar o orçamento de fragment shader e evitar penalidades de *Early-Z / Hidden Surface Removal (HSR)* em GPUs móveis Tile-Based (Mali, Adreno e PowerVR), o **Pacote 2** otimizou os três shaders mais frequentes durante o gameplay e sincronizou o gabarito de regressão espacial:

1. **`shaders/interactive_grass.gdshader`:** Executava `smoothstep()`, múltiplas misturas de cor (`mix()`), compensação `pow()` sRGB e divisão vetorial `color_shadow / color_light` para cada fragmento/pixel de grama e trigo (amplificado por *overdraw* com `cull_disabled`).
2. **`shaders/interactive_flower.gdshader`:** Calculava movimento de vento (`sin`/`cos`) e interação com a serra (`sqrt`) mesmo para vértices de pétalas já colapsadas em `VERTEX = vec3(0.0)`, além de repetir a seleção de miolo/gradiente por pixel no `fragment()`.
3. **`shaders/blade_slash.gdshader`:** Usava 3 instruções `discard` dentro de um shader transparente (`blend_mix`, `depth_draw_never`) e calculava `pow(t, inner_curve_power)` 3 vezes por pixel.
4. **`tests/golden_vegetation_spatial_index.txt`:** Mantinha índices de `clip_counts` congelados na `v0.12.187-alpha`, antes da reordenação do manifesto em `PlantDatabase` (`v0.12.196-alpha`).

---

## 2. Modificações Implementadas

### 2.1 Shaders de Grama e Trigo (`shaders/interactive_grass.gdshader`)
- Substituído `varying float v_leaf_h;` por `varying vec3 v_base_surface;`, `varying vec3 v_shadow_ratio;` e `varying float v_rim_h_mask;`.
- Movidos o gradiente vertical (`smoothstep(0.04, 0.88, h)` + ramo `OUTPUT_IS_SRGB`), o cálculo de `v_shadow_ratio` (`color_shadow / color_light`) e `v_rim_h_mask = h * h` para o `vertex()`.
- Reduzido o `fragment()` à atribuição direta de `v_base_surface`, `roughness` e `specular`, e atualizado o `light()` para reutilizar `v_shadow_ratio` e `v_rim_h_mask`.

### 2.2 Shader de Flores (`shaders/interactive_flower.gdshader`)
- Adicionado `varying vec3 v_base_col;`.
- No `vertex()`, vértices de pétalas/folhas colapsadas nos estágios 1 e 2 (`VERTEX = vec3(0.0); v_base_col = vec3(0.0);`) são encerrados no bloco `if (...) { ... } else { ... }`, pulando matrizes, vento e interação radial com a serra (respeitando a proibição de `return` em funções processadoras da Godot Shading Language).
- Para vértices ativos, o cálculo de `v_base_col` (gradiente por `COLOR.a`, seleção de miolo `COLOR.g > 0.5` e ajuste `OUTPUT_IS_SRGB`) passou para o `vertex()`, deixando o `fragment()` com atribuição direta.

### 2.3 Shader de Rastro da Lâmina (`shaders/blade_slash.gdshader`)
- Removidas as 3 instruções `discard;` (estruturado via blocos `if (...)` com saída `ALPHA = 0.0;`), preservando otimizações *Early-Z / HSR* em GPUs mobile TBDR.
- Pré-calculados `float t_curve = pow(max(t, 0.0001), inner_curve_power);` e `float one_minus_t = max(1.0 - t, 0.0001);` uma única vez por pixel visível, eliminando 2 chamadas `pow()` redundantes por fragmento.

### 2.4 Atualização do Gabarito Golden (`tests/golden_vegetation_spatial_index.txt`)
- Executado `test_vegetation_spatial_index.tscn -- write-golden` para alinhar as posições de `clip_counts` e `seq_hash` ao manifesto atual do `PlantDatabase` (mantendo idênticos todos os totais `tufts`, `cut_total`, `cut_events`, `rem_grass`, `rem_phys`, `coll_hash` e `after_reset`).

---

## 3. Arquivos Modificados

| Arquivo | Modificação |
| :--- | :--- |
| `shaders/interactive_grass.gdshader` | Pré-cálculo de `v_base_surface`, `v_shadow_ratio` e `v_rim_h_mask` no `vertex()`. |
| `shaders/interactive_flower.gdshader` | Ramo `if/else` pulando vento/interação em vértices colapsados + `v_base_col` no `vertex()`. |
| `shaders/blade_slash.gdshader` | Remoção dos 3 `discard;` por fluxo condicional com `ALPHA = 0.0` e `pow()` único `t_curve`. |
| `tests/golden_vegetation_spatial_index.txt` | Regravação do gabarito alinhado à ordem do `PlantDatabase`. |
| `scripts/core/game_version.gd`, `project.godot`, `export_presets.cfg` | Bump SemVer `0.12.207-alpha` (`version/code=1407`). |
| `docs/05_arquitetura_e_desenvolvimento/PLANO_MESTRE_DE_PERFORMANCE.md` | Registro da tarefa 3.6 (Pacote 2) como concluída. |

---

## 4. Testes e Validação (Headless CLI)

Executados após a edição final com 0 erros/warnings de compilação de shaders:
- `res://tests/test_vegetation_spatial_index.tscn` — **`GOLDEN_RESULT|PASS`** (exit code `0`).
- `res://tests/test_flower_materials_integrity.gd` — **Aprovado** (exit code `0`, 36 variedades botânicas íntegras).
- `res://tests/test_rose_cutting_visual.tscn` — **Aprovado** (exit code `0`, 3 hits com despetalação).
- `res://tests/test_all_botanical_variations.gd` — **Aprovado** (exit code `0`, 40 fases e variações íntegras).
- `res://tests/test_blade_pop_and_slash.tscn` — **Aprovado** (exit code `0`, `blade_slash_mesh` e `slash_intensity`).
- `res://scenes/main.tscn` (`--headless --quit` padrão e `--rendering-driver opengl3`) — **Aprovado** (exit code `0`).
- `res://tests/test_wheat_shader.gd` — Falha pré-existente (exit code `1`: `Base bend factor must be 0.0 at the ground!`), pois o script do teste calcula `1.0 - UV.y` sobre a malha `wheat_01.glb` remodelada na `v0.12.178-alpha` (que passou a usar `COLOR.r` para altura normalizada).
