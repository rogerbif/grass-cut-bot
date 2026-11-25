# Histórico de Melhorias: Correção Definitiva de "Tilt", Quadrados Brancos e Listras Horizontais no Android (`v0.12.220-alpha`) 🛠️📱

**Versão Associada:** `v0.12.220-alpha` (`versionCode 1420`)  
**Data de Conclusão:** 24/11/2026  
**Status:** Concluído e Validado  

---

## 1. Diagnóstico e Causa-Raiz

A análise frame a frame de gravações em vídeo no Android revelou que os artefatos relatados ("quadrados brancos" mesmo com o robô parado e listras/piscadas ao ajustar o volume físico do celular) não eram causados por partículas ou compilação tardia de materiais, mas sim por **descarte e corrupção de blocos (*tiles*) de malhas 3D no pipeline Vulkan Mobile**:

1. **Bug de Driver Vulkan Mobile com Hardware Overlays (`#115217`, `#123370`, `#125576`):**
   - Em GPUs móveis Tile-Based (especialmente Qualcomm Adreno e Mali), combinar `renderer/rendering_method="mobile"` (Vulkan) com `scaling_3d_scale < 1.0` (0.85 no perfil `"balanced"`) e overlays de hardware do sistema Android (como a barra de volume ou gravador de tela) provoca falha de sincronização no *subpass / tile resolve*.
   - Como consequência, blocos retangulares do terreno (`IslandMesh`) e do oceano (`WaterOcean`) deixam de ser rasterizados por 1 frame — expondo o `background_color` claro (`Color(0.68, 0.85, 0.9, 1)`) de `shared_environment.tres` como um quadrado claro — ou a malha inteira da ilha pisca por 1 frame exibindo linhas brancas horizontais de ponta a ponta.
2. **Paridade 1:1 já existente para `gl_compatibility`:**
   - Todos os shaders (`toon_water.gdshader`, `interactive_grass.gdshader`, `interactive_flower.gdshader`) e builders (`IslandMeshBuilder`, `Cutter`, `MenuBot`) já possuíam calibração cromática completa para OpenGL ES 3.0 / WebGL2 (`OUTPUT_IS_SRGB` e `is_compat`) herdada da versão Web.
3. **Blindagem complementar de `AABB`, interpolação e shader baker:**
   - As malhas procedurais `ArrayMesh` de `IslandMeshBuilder` e a `PlaneMesh` plana do oceano (`WaterOcean`) não definiam `custom_aabb` no recurso de malha nem `extra_cull_margin`, e `BladeProgressBar` (`set_as_top_level(true)`) atualizada em `_process()` herdava `physics_interpolation_mode` ativo.

---

## 2. Alterações Implementadas

1. **Unificação do Renderizador para `gl_compatibility` ([`project.godot`](../../project.godot)):**
   - Alterado `config/features` para `PackedStringArray("4.7", "GL Compatibility")`.
   - Definidos `renderer/rendering_method="gl_compatibility"` e `renderer/rendering_method.mobile="gl_compatibility"`.
2. **Blindagem de `custom_aabb` e `extra_cull_margin` nas Malhas de Terreno, Espuma e Oceano:**
   - [`scripts/level/island_mesh_builder.gd`](../../scripts/level/island_mesh_builder.gd): adicionada constante `FIXED_MESH_AABB` atribuída diretamente aos recursos `ArrayMesh` retornados por `build_island_mesh()` e `build_coastal_foam_mesh()`.
   - [`scenes/level/water_ocean.tscn`](../../scenes/level/water_ocean.tscn): adicionado `custom_aabb = AABB(-65, -2, -65, 130, 4, 130)` em `PlaneMesh_ocean` e `extra_cull_margin = 32.0` em `SurfaceWater`.
   - [`scripts/plants/vegetation_grid.gd`](../../scripts/plants/vegetation_grid.gd): desativada `physics_interpolation_mode` em `WaterOcean`, `SurfaceWater` e `CoastalFoamRibbon`; adicionado `extra_cull_margin = 32.0` em `SurfaceWater` e `16.0` + `FIXED_ISLAND_AABB` em `IslandMesh` e `CoastalFoamRibbon`.
3. **Desacoplamento de Interpolação da Barra da Lâmina e `shader_baker`:**
   - [`scripts/cutter/blade_progress_bar.gd`](../../scripts/cutter/blade_progress_bar.gd): definido `physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF` e `reset_physics_interpolation()` no `_ready()`.
   - [`export_presets.cfg`](../../export_presets.cfg): habilitado `shader_baker/enabled=true` no preset Android.

---

## 3. Validação e Testes (Headless CLI — Godot 4.7.2)

- `godot --headless --path . --quit` — **Aprovado** (0 warnings GDScript / 0 erros de shader).
- `godot --headless --path . scenes/main.tscn --quit` — **Aprovado** (0 warnings GDScript / 0 erros de shader).
- `godot --headless --path . tests/test_android_lifecycle_and_navigation.tscn` — **Aprovado** (100% dos cenários de auto-pausa, safe area e botão voltar).
- `godot --headless --path . tests/test_blade_pop_and_slash.tscn` — **Aprovado** (100% dos asserts de slash/pop/choque).
- `godot --headless --path . -s tests/test_flower_materials_integrity.gd` — **Aprovado** (36/36 variedades botânicas e `MultiMeshInstance3D` íntegros).
- `godot --headless --path . -s scripts/tools/verify_levels_integrity.gd` — **Aprovado** (50/50 fases íntegras).
- Nota: `tests/test_vegetation_spatial_index.tscn` apresentou divergência pré-existente contra o gabarito congelado na `v0.12.207-alpha` devido ao chunking 2x2 e cantos arredondados introduzidos nas versões `v0.12.209`/`v0.12.212` (não relacionados a esta alteração).
