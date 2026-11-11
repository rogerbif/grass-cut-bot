# 230 — Pacote 2: Quick Wins de Performance (CPU, GPU, Memória e I/O) (`v0.12.184-alpha`)

## Contexto e Motivação
Na auditoria de performance do **Grass Cut Bot**, foram mapeados pontos de trabalho redundante por frame e no carregamento de fases:
1. O `SubViewport` (340×100) do `BladeProgressBar` estava configurado com `render_target_update_mode = UPDATE_ALWAYS` (4), re-renderizando a UI 2D da barra da lâmina a 60 FPS mesmo com o XP estático.
2. O `FloatingCoinManager` executava `_sync_to_cutter()` tanto em `_process` quanto em `_physics_process` a 60 Hz, embora todos os 64 `Label3D` do pool utilizem `top_level = true` e o próprio `_on_coin_popup_requested` já sincronize a posição sob demanda.
3. O `GoalIconFactory` armazenava o cache de silhuetas flood-fill por `plant_type` (~36 chaves) em vez de por categoria `cat` (`"grass"`, `"crop"`, `"flower"` — 3 silhuetas únicas).
4. O `VegetationGrid` instanciava e combinava 6 modelos `.glb` de tiles antigos (`TILE_MODELS` / `_tile_meshes`) no startup sem nunca utilizá-los, alocava 72 nós `MultiMeshInstance3D` mesmo para espécies ausentes na fase (`count == 0`), inicializava `ClippingsMMI_*` com `visible_instance_count = -1` no `_build_from_vector_field()`, e realizava buscas `get_node_or_null` e loops de dicionário anti-trava para cada tufo individualmente dentro de `cut_in_circle()`.
5. O `SaveManager.save_game()` era disparado de forma síncrona no meio do gameplay ao subir de nível ou colidir com rochas.
6. O `FlowerDetachPiece._process()` executava `.orthonormalized()` em todos os frames durante o voo curto das pétalas.

## Alterações Executadas
1. **`BladeProgressBar` (`scenes/cutter/blade_progress_bar.tscn` & `scripts/cutter/blade_progress_bar.gd`):**
   - Alterado `render_target_update_mode` para `UPDATE_ONCE` (1), acionado sob demanda via `_request_viewport_update()` apenas durante o tween de XP ou mudança de nível/idioma.
2. **`FloatingCoinManager` (`scripts/effects/floating_coin_manager.gd`):**
   - Removidos `_process` e `_physics_process` ociosos, mantendo a sincronização sob demanda em `_on_coin_popup_requested`.
3. **`GoalIconFactory` (`scripts/ui/goal_icon_factory.gd`):**
   - Chave de `_silhouette_cache` unificada por categoria `cat`, reduzindo em até 12x o processamento de imagem e o uso de texturas.
4. **`VegetationGrid` (`scripts/plants/vegetation_grid.gd`):**
   - Removidos `TILE_MODELS` e `_tile_meshes` obsoletos.
   - Ignorada a criação de `VegMMI_*` e `ClippingsMMI_*` quando `count <= 0` para a espécie na fase.
   - Ativado `clip_mm.visible_instance_count = 0` no carregamento vetorial com empacotamento contíguo via `_clipping_counts[mmi_idx]` no corte.
   - Cache de Autoloads (`AudioManager`, `SaveManager`, `UpgradeManager`), acúmulo de XP (`xp_gained_this_frame`) e verificação anti-trava movidos para fora do loop interno de tufos em `cut_in_circle()`.
5. **`SaveManager` & `UpgradeManager` (`scripts/core/save_manager.gd`, `scripts/core/upgrade_manager.gd`):**
   - Implementado `save_game_deferred()` com coalescência por frame (`call_deferred("_flush_deferred_save")`) e flush garantido no `_notification` de pausa/saída.
6. **`FlowerDetachPiece` (`scripts/plants/flower_detach_piece.gd`):**
   - Removida a ortonormalização redundante por frame durante o voo curto.
