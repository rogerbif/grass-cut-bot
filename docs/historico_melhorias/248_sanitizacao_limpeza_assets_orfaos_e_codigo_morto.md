# Melhoria 248: Sanitização Completa, Limpeza de Assets Órfãos e Código Morto (`v0.12.213-alpha`)

**Data:** 21 de Novembro de 2026  
**Versão:** `v0.12.213-alpha` (Build Code `1413`)  
**Status:** Concluído e Validado  

---

## 🎯 1. Resumo Executivo & Objetivos

A **Melhoria 248** consolida a faxina arquitetural e higienização profunda do projeto **Grass Cut Bot** delineada no item "Pacote Imediato: Sanitização e Limpeza de Código e Assets" de [`docs/MELHORIAS_FUTURAS.md`](../MELHORIAS_FUTURAS.md).

Após a expansão para 40 fases canônicas, introdução do sistema de ilha procedural contínua (`IslandMeshBuilder`) e otimização de rendering para dispositivos móveis, o repositório acumulou recursos de prototipagem, áudios descompactados de teste, malhas 3D de tiles pré-moldados e nós/funções que não possuíam mais referências no jogo ativo.

### Principais Ganhos:
- **Redução de ~17.5 MB no disco / ~4 MB no pacote comprimido (.aab):** Eliminação de `Water_splash.wav` (~16.92 MB uncompressed) e `Star_win.mp3` (~38 KB).
- **Remoção de 6 modelos 3D legados e 6 cenas modulares:** Purga de `assets/models/tiles/*` e `scenes/editor/tiles/*`, mantendo a textura de paleta procedural em `assets/textures/island_palette.png`.
- **Eliminação de 23 SVGs e PNGs órfãos e 3 arquivos `.uid` quebrados:** Higiene total das pastas `assets/icons/`, `assets/ui/defeat/`, `assets/ui/pause/`, `assets/ui/topbar/` e `tests/`.
- **Purga de Código GDScript Morto (Zero Warnings):** Remoção de 3 funções utilitárias não chamadas e 15 constantes obsoletas.
- **Blindagem do `export_presets.cfg` e Keystore:** Inclusão de `docs/*`, `assets/brand/screenshots/*` e `*.py` no `exclude_filter`, além de suporte à variável `$env:RELEASE_KEYSTORE_PASSWORD` nos scripts de automação.
- **Robustez de Áudio CLI/Headless (Mandamento 16):** Verificação defensiva de `is_inside_tree()` em `audio_manager.gd` impedindo erros de playback quando nós são chamados fora da árvore.

---

## 🔍 2. Detalhamento das Alterações

### A. Bloco 1: Eliminação de Áudios Desnecessários
- Excluído `assets/audio/sfx/Water_splash.wav` (16.92 MB) e `Star_win.mp3` (38 KB) com seus respectivos `.import`.
- Em `scripts/core/audio_manager.gd`:
  - Removido `const SFX_WATER_SPLASH` e `const SFX_STAR_WIN`.
  - Removido cooldown `"water_splash": 100` e mapeamento `"water_splash": SFX_WATER_SPLASH`.
  - Mantido `"star_win": SFX_LEVEL_COMPLETED` como alias retrocompatível seguro.

### B. Bloco 2: Migração de Textura & Exclusão de Tiles 3D Legados
- Copiado `assets/models/tiles/tile_island_center_Image_0.png` $\to$ `assets/textures/island_palette.png`.
- Atualizado `scripts/level/island_mesh_builder.gd` para referenciar a nova localização canônica `res://assets/textures/island_palette.png`.
- Removido o diretório `assets/models/tiles/` e todos os seus 6 modelos `.glb` e arquivos `.import`.
- Removido o diretório `scenes/editor/tiles/` e suas 6 cenas modulares `.tscn`.
- Excluídos os modelos órfãos `assets/models/terrain_tileset.glb`, `terrain_tileset_Image_0.png`, `cut_leaf_piece.glb`, `cut_petal_piece.glb` e seus `.import`.

### C. Bloco 3: Purga de SVGs Órfãos e Arquivos .uid Quebrados
- **`assets/icons/`:** Excluídos 9 arquivos vetoriais não referenciados (`icon_blade.svg`, `icon_cancel.svg`, `icon_close.svg`, `icon_flower.svg`, `icon_map.svg`, `icon_music.svg`, `icon_shop.svg`, `icon_speaker.svg`, `icon_wheat.svg`).
- **`assets/ui/defeat/`:** Excluídos 6 botões/cards obsoletos da UI de derrota substituídos na reestruturação visual (`btn_extra_time_normal.svg`, `btn_extra_time_pressed.svg`, `btn_retry_normal.svg`, `btn_retry_pressed.svg`, `card_defeat_bg.svg`, `icon_restart_orange.svg`).
- **`assets/ui/pause/`:** Excluídos 2 SVGs obsoletos (`icon_play_green.svg`, `icon_refresh_cyan.svg`).
- **`assets/ui/topbar/`:** Excluídos 2 botões obsoletos (`btn_plus_square.svg`, `btn_plus_square_pressed.svg`).
- **`tests/`:** Excluídos 3 arquivos `.uid` cujos scripts `.gd` já haviam sido removidos (`inspect_grass_mesh.gd.uid`, `test_editor_picker_and_ring.gd.uid`, `test_editor_selection_and_duplicate.gd.uid`).

### D. Bloco 4: Eliminação de Código GDScript Morto
- `scripts/editor/level_editor.gd`: Removidos `const ROCK_SCENE` e `func _rotate_active_step()`.
- `scripts/plants/vegetation_grid.gd`: Removida `func _spawn_cut_particles_at()`.
- `scripts/level/vector_terrain_field.gd`: Removida `func _is_point_in_any_outer()`.
- `scripts/editor/brush_patterns.gd`: Removidas as matrizes bitmap legadas `STAR_SMALL`, `STAR_MEDIUM`, `STAR_LARGE`.
- `scripts/level/level_json_loader.gd`: Removido o alias `const SCENE_MAP: Dictionary = OBJECT_SCENES`.
- `scripts/level/island_mesh_builder.gd`: Removidas as constantes `UV_DIRT_TOP` e `DIRT_COLOR`.
- `scripts/core/save_manager.gd`: Removida a constante `LIFE_REFILL_COST_COINS`.
- `scripts/ui/defeat_modal.gd`: Removidas `EXTRA_TIME_SECONDS` e `COL_LIFE_LOST`.

### E. Bloco 5: Segurança e Filtros de Build
- `export_presets.cfg`: Adicionados `docs/*`, `assets/brand/screenshots/*` e `*.py` ao `exclude_filter` de ambos os presets (Android e Web), garantindo que documentações internas e assets promocionais não inflem o `.aab` ou o pacote HTML5.
- `scripts/tools/build_android_aab.ps1` e `scripts/tools/generate_keystore.ps1`: Suporte prioritário à variável de ambiente `$env:RELEASE_KEYSTORE_PASSWORD`.

### F. Bloco 6: Defesa em Profundidade de Áudio & Testes
- Em `scripts/core/audio_manager.gd`: adicionada checagem defensiva de `is_inside_tree()` nos métodos de reprodução de música, engine e pooling de SFX, assegurando conformidade estrita com o Mandamento 16.
- Atualizado `tests/test_audio_manager.gd` para testar os 20 recursos canônicos de áudio e ciclo sem warnings.

---

## 🧪 3. Validação e Testes Automatizados

A suíte completa de testes unitários e de integração foi executada no modo `--headless`:
1. `tests/test_audio_manager.gd`: Passou com 100% de sucesso (20 recursos de áudio, pooling e mutes).
2. `tests/test_island_mesh_builder.gd`: Passou com 100% de sucesso (20 níveis validados, nova textura `island_palette.png` funcionando perfeitamente).
3. `tests/test_vegetation_chunking.gd`: Passou com 100% de sucesso (16 chunks MultiMesh).
4. `tests/test_performance_sampling_benchmark.gd`: Passou com 100% de sucesso (83.991 tufos amostrados nas 40 fases).
5. `tests/test_translations.gd`: Passou com 100% de sucesso (pt_BR, en, es).
6. `tests/test_theme_auto_discovery.gd`: Passou com 100% de sucesso.
7. `tests/test_obstacle_auto_discovery.gd`: Passou com 100% de sucesso.
8. `tests/test_species_auto_discovery.gd`: Passou com 100% de sucesso.
9. `tests/test_manifest_sync.gd`: Passou com 100% de sucesso (36 espécies, 6 obstáculos, 3 temas, 0 erros).
10. `tests/test_progression_and_goal_effects.gd`: Passou com 100% de sucesso (40 fases, metas data-driven, ícones stickers pré-assados).
11. `godot --headless --import`: Executado com 0 erros e 0 warnings.
