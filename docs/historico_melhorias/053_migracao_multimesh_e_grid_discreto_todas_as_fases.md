# 053 - Migração Completa para MultiMeshInstance3D e Grid Discreto (0.40m) em Todas as Fases e Menu Inicial 🚀🌿

## 1. Contexto e Objetivo
Após validar na cena de teste (`perf_test.tscn`) a arquitetura da **Opção B (Grid Discreto + MultiMesh / GPU Instancing)** na Fase 20 — onde a contagem de nós caiu de `11.102` para **`211 nós` (-98%)** e o tempo de carregamento de `163 ms` para **`8.5 ms`** — aplicamos o novo motor `VegetationGrid` como padrão único em **todas as 20 fases canônicas do jogo** e nas miniaturas das ilhas do **Menu Inicial**, removendo o sistema antigo de instanciação individual em runtime.

---

## 2. Alterações Implementadas

### A. Motor `VegetationGrid` (`scripts/plants/vegetation_grid.gd`)
- **6 `MultiMeshInstance3D` de Vegetação:** Renderiza em lote todas as instâncias de `grass_green`, `grass_yellow`, `grass_blue`, `grass_purple`, `wheat` e `flower` (com malhas multi-superfície combinadas via `SurfaceTool` para trigo e flor em cache estático), com `cast_shadow = SHADOW_CASTING_SETTING_OFF`.
- **6 `MultiMeshInstance3D` de Terreno + Colisor de Piso Unificado:** Renderiza os blocos da ilha agrupados por `tile_id` (mantendo sombras nas falésias) e unifica o piso físico em 1 único `IslandFloorCollider` (`BoxShape3D`) junto aos colisores costeiros mesclados e `CoastalFoamRibbon`.
- **Corte Radial $\mathcal{O}(1)$ (`cut_in_circle`):** Particionamento espacial discreto em células de `0.40m` usando arrays contíguos SoA (`PackedVector3Array`, `PackedInt32Array`, `PackedByteArray`), eliminando todas as `Area3D` de plantas nas fases. Preserva os 2 golpes de vida (`max_health = 2`) do trigo e da flor com *squash* visual de `1.25x`, emissão no Pool Estático de Partículas e sincronização exata de metas e moedas com o `GameManager`.

### B. Aplicação em Todas as Fases e no Menu Inicial
- **`scripts/level/level_controller.gd`:** Refatorado para construir todas as fases (`level_01..20.json`) exclusivamente via `VegetationGrid`, desativando `BladeArea.monitoring = false` no cortador e removendo os geradores procedurais/cenas legadas.
- **`scripts/menu/island_node.gd`:** Miniaturas 3D das 20 ilhas no Menu Inicial migradas para `MultiMeshInstance3D` (terreno e vegetação), mantendo o controle de animação seletiva de vento (`set_grass_animated`) sobre os 4 `MultiMeshInstance3D` de grama.
- **Limpeza de Arquivos Legados:** Removidas as cenas antigas `scenes/levels/level_01.tscn`, `scenes/levels/level_02.tscn` e o script `scripts/level/base_level.gd`, além do modo legado em `perf_test.gd` / `perf_probe.gd`.

---

## 3. Resultados Validados
- **Árvore de Cena na Fase 20:** Reduzida de `11.102 nós` para **`~211 nós` (-98%)**.
- **Carregamento de Fase:** Reduzido para **`~8.5 ms`** (instantâneo ao clicar em Jogar ou Próxima Fase).
- **Zero Warnings / Zero Erros:** Validado via Godot 4.7.1 headless em `main_menu.tscn`, `main.tscn`, `perf_test.tscn` e `test_save_manager.tscn`.
