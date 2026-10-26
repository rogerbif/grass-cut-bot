# Histórico de Melhorias: 105 - Blindagem de Números Flutuantes em Espaço Local e Estabilidade de Renderização 3D 🛡️🌿

**Data:** 25 de Outubro de 2026  
**Versão:** `v0.12.30-alpha`  
**Escopo:** Números Flutuantes (`scripts/effects/floating_coin_manager.gd`), Cortador (`scripts/cutter/cutter.gd`), Grade de Vegetação e MultiMeshes (`scripts/plants/vegetation_grid.gd`, `scripts/plants/plant.gd`), Terreno Fase 02 (`data/levels/level_02.json`) e Renderizador Mobile (`scripts/core/game_manager.gd`, `project.godot`).

---

## 1. Diagnóstico de Causa-Raiz (Por que ocorria mesmo com a menor lâmina `0.90m`?)

1. **Flash Fantasma de Interpolação Física (`common/physics_interpolation=true`) + Contorno Preto Opaco (`outline_modulate.a = 1.0`):**
   - Com `common/physics_interpolation=true` ativo em `project.godot`, os 64 `Label3D` do pool e os 16 `CPUParticles3D` de folhas cortadas nasciam em `(0, 0, 0)` (centro da Fase 1) e eram reposicionados dentro do `_physics_process` sem `reset_physics_interpolation()` e com `outline_modulate.a = 1.0`.
   - No primeiro frame de renderização do tick físico, o `RenderingServer` interpolava o `Label3D` a partir de `transform_prev` (`(0,0,0)` ou a posição antiga distante onde terminou a animação anterior com `scale = 1.0`) exibindo o contorno escuro de `14px` (idêntico a um número "quase finalizando" longe do robô!).
2. **`outline_modulate:a` Independente no Fade-Out do `Label3D`:**
   - Na Godot 4, `modulate.a` não altera `outline_modulate.a`. Nos últimos frames do fade-out, o preenchimento colorido sumia, mas o contorno preto permanecia 100% opaco, escurecendo o número no fim da vida.
3. **Números Órfãos no Espaço de Mundo:**
   - Os labels ficavam parados na coordenada `XZ` do mundo onde nasceram enquanto o robô avançava, ficando para trás na grama durante o fade-out.
4. **Raio de Corte Físico `30cm` Maior que a Serra Visual Nível 1 (`0.90m`) e Conflito de `MultiMesh`:**
   - No nível 1 (`radius = 0.90m`), a escala visual `0.90 / 1.18` sob `VisualPivot (0.62)` gerava raio visual `0.78m`, enquanto `hit_radius` cortava até `1.08m` (`0.90 + 0.18`).
   - Além disso, `HIDDEN_TRANSFORM` usava `Basis.ZERO` singular (gerando `NaN` na matriz normal do shader Vulkan), `ClippingsMMI` tinha dupla indexação (`c_idx` vs `inst_idx`) e altura `y = 0.005m` (*Z-fighting*), e `TileMMI`/`WaterOcean`/`CoastalFoamRibbon` projetavam sombras desnecessárias no shadow map de `1024px`.

---

## 2. Soluções Implementadas

### A. Blindagem em Espaço Local do `FloatingCoinManager` (`floating_coin_manager.gd` & `cutter.gd`)
- `physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF` aplicado no `FloatingCoinManager` e em cada `Label3D` do pool.
- O nó `FloatingCoinManager` sincroniza continuamente sua `global_position` com `cutter.global_position` em `_process` e `_physics_process`, enquanto todos os `Label3D` operam exclusivamente em **coordenadas locais (`label.position`)** travadas a `<= 0.48m` do chassi (`get_body_side_local_offset`). Assim, os números acompanham o robô em movimento e jamais podem surgir ou ficar longe do corpo.
- `outline_modulate:a` agora inicia em `0.0` e sofre fade-in (`0.03s`) e fade-out (`0.10s`) em paralelo exato com `modulate:a`, eliminando o aspecto escuro no final da animação.

### B. Partículas de Grama, Calibração 1:1 da Lâmina e MultiMesh (`plant.gd`, `vegetation_grid.gd`, `cutter.gd`)
- Emissores `CPUParticles3D` (`PooledCutParticles` e `SparkParticles`) configurados com `physics_interpolation_mode = OFF`, `emitting = false` e `reset_physics_interpolation()` antes de cada `restart()`.
- Escala visual da lâmina calibrada para `radius / 1.03` e `TUFT_HIT_RADIUS_BONUS = 0.0`, alinhando `1:1` a ponta dos dentes da serra com o corte físico desde o nível 1 (`0.90m`).
- `HIDDEN_TRANSFORM` alterado para escala não-singular `0.0001`, `FIXED_ISLAND_AABB` atribuído a todos os `MultiMeshInstance3D`, indexação de `ClippingsMMI` unificada por `inst_idx` a `y = 0.016m`, e sombras desativadas em `TileMMI`, `CoastalFoamRibbon` e `WaterOcean`.
- Nivelamento automático de `pitch` e `roll` (`rotation:x = 0`, `rotation:z = 0`) na comemoração de vitória (`play_victory_celebration`) e limite geométrico de mergulho em `_process_procedural_motion`.

### C. Correção do Canto Superior Direito na Fase 02 (`data/levels/level_02.json`)
- Restaurado o tile de canto `(gx=16, gz=0)` (`island_corner_out, rot=0`) e atualizados `(15, 0)`, `(15, 1)` e `(16, 1)` na Fase 02.

---

## 3. Validação e Testes

- **Suíte `tests/test_floating_coin_manager.tscn`:** 100% aprovada (ancoragem local, acompanhamento com o robô em movimento, `outline_modulate.a == modulate.a` e `physics_interpolation_mode == OFF`).
- **Suíte `tests/test_blade_inclination.tscn`:** 100% aprovada (coplanaridade da serra e nivelamento na vitória).
- **Zero Warnings Estrito:** Validado via `godot_console.exe --headless --path . --editor --quit` com **0 warnings** (incluindo correção do `SCALING_3D_MODE_BILINEAR` para o renderizador Mobile).
