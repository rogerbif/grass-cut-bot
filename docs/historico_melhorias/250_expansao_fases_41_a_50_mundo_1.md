# Expansão do Mundo 1: Fases 41 a 50 com Progressão Botânica do Herbário (`v0.12.217-alpha`)

## 🎯 Objetivo
Expandir o Mundo 1 (Ilhas Tropicais Diurnas) com **10 novas fases autorais e balanceadas (Fases 41 a 50)**, apresentando progressão gradual de dificuldade geométrica (istmos, pontes duplas, atol com lago vazado, tridente, cidadela e estrela imperial de 8 pontas) e introduzindo gradualmente as novas variações botânicas do Herbário.

---

## 🛠️ Alterações Realizadas

1. **Gerador Procedural (`scripts/tools/generate_procedural_levels.gd`):**
   - Adicionados os blocos específicos `41:` a `50:` dentro de `generate_level(lvl)`, respeitando integralmente os raios de segurança (`MIN_SPAWN_CLEAR_DIST = 1.47m`, `MIN_ROCK_SPACING = 2.80m` e clareiras `1.40m`/`0.90m`).
   - Integrado `VectorTerrainField` (`convert_from_tile_grid` e `carve_water` na Fase 46) para garantir a geração nativa do formato JSON v5 com cantos arredondados (`corner_radius = 0.28`, `island_polygons`, `base_island_polygons` e `island_holes`), mantendo paridade visual entre o Editor e o Gameplay.
   - Gerados os arquivos `data/levels/level_41.json` a `data/levels/level_50.json` com 0 erros de auditoria, preservando 100% intactas as Fases 01 a 40 (Mandamento 17).

2. **Introdução Gradual do Herbário (Fases 41 a 50):**
   - **Fase 41 (*O Prado das Margaridas Silvestres*):** `flower_daisy_bicolor`, `flower_daisy_pink`.
   - **Fase 42 (*O Istmo das Tulipas Roxas*):** `flower_tulip_purple` e `wheat`.
   - **Fase 43 (*O Jardim dos Pêssegos e Alabastro*):** `flower_rose_peach`, `flower_rose_white`.
   - **Fase 44 (*O Arquipélago Solar Duplo*):** `flower_sunflower`, `flower_bed_white`.
   - **Fase 45 (*O Castelo das Pétalas Escuras*):** `flower_rose_wine`, `flower_rose_black`, `wheat`.
   - **Fase 46 (*O Grande Atol da Alvorada*):** `flower_tulip_orange`, `flower_daisy_orange`, `wheat` (lago interior vazado 7x7).
   - **Fase 47 (*O Tridente do Oceano Safira*):** `flower_bed_blue`, `flower_rose_blue`, `flower_tulip_purple`.
   - **Fase 48 (*A Cidadela de Rubi e Trigo*):** `flower_daisy_red` e anel defensivo de `wheat` (24 tufos).
   - **Fase 49 (*O Trevo dos Ventos Cromáticos*):** `flower_turquoise`, `flower_sunset`, `flower_tulip_yellow`, `flower_daisy_yellow`.
   - **Fase 50 (*A Coroa Imperial da Mãe Natureza*):** Clímax estelar de 8 pontas com 11 metas botânicas (`wheat`, `flower_sunflower`, `flower_rose_peach`, `flower_rose_wine`, `flower_tulip_purple`, `flower_tulip_orange` e 5 cores de grama).

3. **Suporte de Runtime, Menu $O(1)$ e Smoke Test:**
   - `scripts/core/game_manager.gd` e `scripts/menu/main_menu.gd`: Atualizado o piso de detecção de `40` para `50` fases.
   - `scripts/level/level_card_data.gd`: Adicionados os metadados canônicos das Fases 41 a 50 em `CANONICAL_ISLAND_METAS` para carregamento $O(1)$ no boot splash.
   - `scripts/tools/verify_levels_integrity.gd`: Expandido para auditar todas as **50 fases** do projeto.

---

## ✅ Validação e Testes
- **Geração Headless:** `generate_procedural_levels.gd -- --start=41 --end=50` concluído com **0 erros** nas 10 fases.
- **Smoke Test de Integridade:** `verify_levels_integrity.gd` executado após todas as alterações, aprovando **50/50 fases** com 100% de integridade dimensional e metas botânicas válidas.
