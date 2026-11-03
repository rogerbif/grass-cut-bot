# Registro de Melhoria: TopBar Cyber de Gameplay, Vitória Flutuante, Números Flutuantes 6:1 e Coleção Horizontal Cyber 🏆🌿✨

- **Versão:** `v0.12.106-alpha` (Ciclo `v0.12.98-alpha` a `v0.12.106-alpha`)
- **Data:** 03/11/2026
- **Status:** Concluído e Validado
- **Domínios:** Interface & HUD, Vegetação & Colheita, Game Feel, Persistência & Gameplay

---

## 🎯 1. Objetivos da Implementação

1. **TopBar Moderna de Gameplay e Cards Chanfrados Simétricos (`hud.tscn` / `hud.gd`):**
   - Remoção do overlay retangular translúcido de fundo no topo do HUD de gameplay, mantendo o mar e a ilha 100% visíveis.
   - Posicionamento em `offset_top = 34` com espaçamento simétrico de `10px` entre os badges superiores (`badge_coin_bg.svg` para Tempo e Moedas) e a fileira inferior de Cards de Objetivo (`GoalsContainer`).
   - Cards de Objetivo padronizados com molduras chanfradas a 45° (`badge_goal_card.svg` e `badge_goal_card_done.svg`), seguindo a mesma identidade visual dos badges de cima.
   - Botão de Pausa atualizado com `TextureButton` estilizado em chip chanfrado (`btn_pause_cyber.svg` / `btn_pause_cyber_pressed.svg`).
   - Barra de nível da lâmina (`BladeProgressBar`) reposicionada mais abaixo do robô (`position = Vector3(0.0, 0.12, 1.38)` em `scenes/cutter/cutter.tscn`) para nunca sobrepor as pontas inferiores da serra.

2. **Tela de Sucesso Flutuante Sem Card Opaco e Persistência Atômica Imediata (`VictoryModal`):**
   - Eliminação de qualquer card central ou painel com base que ocultava o cenário e o robô, mantendo os elementos flutuantes diretamente sobre o robô comemorando.
   - Cabeçalho flutuante rebaixado (`offset_top = 132`, `offset_bottom = 412`) composto por:
     - Ícone vetorial de troféu neon ciano (`icon_trophy.svg`), título em fonte bold (`"FASE 01 CONCLUÍDA!"`) e linha divisória luminosa (`header_cyber_divider.svg`).
     - Placa holográfica chanfrada de fundo das estrelas (`stars_cyber_backplate.svg`) com faíscas douradas e trio de estrelas 3D chanfradas (`star_3d_gold.svg`) animadas em arco.
     - Cápsulas largas chanfradas (`badge_stat_pill.svg` / `badge_stat_pill_right.svg`, `288x68` px) com abas superiores listradas, ícone de cronômetro cyber (`icon_stopwatch_cyber.svg`) e texto em caixa alta (`+ XXX MOEDAS`).
   - Barra de Ações flutuante inferior simétrica (`560px` de largura, `separation = 24`):
     - `MENU` (`btn_menu_secondary.svg`, `268x66` px) e `REPETIR` (`btn_repeat_secondary.svg`, `268x66` px) alinhados exatamente à largura total do botão inferior (`268 + 24 + 268 = 560px`).
     - Botão verde-esmeralda neon de destaque `PRÓXIMA FASE ▶` (`btn_next_level.svg`, `560x96` px) com colchetes tecnológicos externos e correção de atribuição de textura em `TextureButton`.
   - Gravação síncrona imediata via `SaveManager.record_level_victory()` ao disparar a celebração e avanço imediato de `last_played_level = level_num + 1`.

3. **Números Flutuantes 3D Desacoplados no Espaço Global e Agrupamento 6:1 na Grama:**
   - **Desacoplamento Global (`top_level`):** Os números flutuantes (`FloatingCoinManager`) são instanciados com `label.set_as_top_level(true)` na posição global exata do corte (`cutter.global_position + local_offset`), subindo verticalmente (`+1.32m`) no ponto onde nasceram sem acompanhar o deslocamento do robô.
   - **Apenas Esquerda ou Direita + POP e Fade-Out Imediato:** Remoção do spawn central; aparição com efeito **POP** (`0.15x -> 1.65x -> 1.0x` em `0.20s`) seguido imediatamente pelo fade-out (`delay = 0.20s`, `duration = 0.45s`), ficando invisível ao atingir o topo da subida (`0.65s`).
   - **Agrupamento 6:1 (`GRASS_TUFTS_PER_UNIT = 6`):** Cada 6 tufos visuais de grama cortados contabilizam **1 unidade de meta e 1 número flutuante `+1`** em `VegetationGrid` e `LevelEditorUI` (redução de 83% na poluição de números na tela), mantendo trigo e flores em `1:1` e migrando as metas das fases JSON.

4. **Aba Coleção (`TabCollection`) com Cards Horizontais Cyber, Ilustrações Multicamadas e Ordenação por Fase:**
   - Restauração dos cards horizontais de largura total (`card_herbarium_horizontal.svg` / `card_herbarium_horizontal_locked.svg`) exibindo todas as informações originais: badge angular de status (`✓ DESCOBERTA` / `BLOQUEADO`), `Fase X+`, nome da espécie, `Resistência • Recompensa`, descrição botânica, `Colhidos: X`, barra e título de marco (`Nv X/10`) e botão/badge lateral de resgate (`badge_milestone_cyber.svg` / `btn_claim_cyber.svg`).
   - Ilustrações botânicas vetoriais multicamadas em `assets/ui/collection/` (`illus_grass_base.svg` + `illus_grass_blades.svg`, `illus_wheat_bundle.svg`, `illus_flower_stems.svg` + `illus_flower_petals.svg`, `illus_locked_plant.svg`).
   - Remoção dos botões de filtro e ordenação estrita por fase de aparição (`origin_level`) em `PlantDatabase`.

5. **Painéis Principais com Cantos Retos Chanfrados a 45° e Alinhamento Rente da Navbar:**
   - Aplicação do chassi `panel_cyber_main.svg` (cantos retos chanfrados a 45°, `corner_radius = 0`) nos painéis principais de `TabCollection`, `TabGarage` e `TabStore`, além de chips (`chip_stat_cyber.svg`) e molduras de ícones (`icon_frame_cyber.svg`).
   - Ajuste de `BottomNavBar` (`scenes/menu/bottom_nav_bar.tscn` e `assets/ui/navbar/nav_bar_chassis.svg`) para encostar 100% rente à borda inferior da tela, eliminando qualquer fresta abaixo da barra.

---

## 🛠️ 2. Arquivos Modificados e Criados

- `assets/ui/topbar/btn_pause_cyber.svg`, `btn_pause_cyber_pressed.svg`, `badge_goal_card.svg`, `badge_goal_card_done.svg`: Novos assets chanfrados do HUD de gameplay.
- `assets/ui/victory/*`: Assets vetoriais completos da tela de vitória flutuante (`stars_cyber_backplate.svg`, `star_3d_gold.svg`, `header_cyber_divider.svg`, `badge_stat_pill.svg`, `badge_stat_pill_right.svg`, `icon_stopwatch_cyber.svg`, `icon_home_cyan.svg`, `icon_repeat_cyber.svg`, `btn_menu_secondary.svg`, `btn_repeat_secondary.svg`, `btn_next_level.svg`).
- `assets/ui/collection/*`: Molduras nine-patch com cantos retos chanfrados (`panel_cyber_main.svg`, `card_herbarium_horizontal.svg`, `card_herbarium_horizontal_locked.svg`, `chip_stat_cyber.svg`, `icon_frame_cyber.svg`, `icon_frame_cyber_locked.svg`, `badge_milestone_cyber.svg`, `btn_claim_cyber.svg`) e ilustrações botânicas vetoriais multicamadas.
- `assets/ui/navbar/nav_bar_chassis.svg` e `scenes/menu/bottom_nav_bar.tscn`: Encaixe rente à borda inferior da tela.
- `scenes/ui/hud.tscn` e `scripts/ui/hud.gd`: TopBar cyber sem overlay, cards de objetivo chanfrados e VictoryModal flutuante simétrico.
- `scripts/ui/floating_coin_manager.gd`: Números flutuantes desacoplados no mundo (`set_as_top_level(true)`), emissão apenas esquerda/direita, efeito POP e fade-out imediato.
- `scripts/plants/vegetation_grid.gd`, `scripts/editor/level_editor_ui.gd` e `data/levels/level_01..04.json`: Agrupamento 6:1 (`GRASS_TUFTS_PER_UNIT = 6`) para tufos de grama.
- `scripts/plants/plant_database.gd`, `scenes/menu/tabs/tab_collection.tscn` e `scripts/menu/tabs/tab_collection.gd`: Cards horizontais cyber ordenados por `origin_level`.
- `scenes/menu/tabs/tab_garage.tscn`, `scripts/menu/tabs/tab_garage.gd`, `scenes/menu/tabs/tab_store.tscn` e `scripts/menu/tabs/tab_store.gd`: Padronização de cantos retos chanfrados a 45°.
- `project.godot`, `scripts/core/game_version.gd`, `export_presets.cfg`: Sincronização SemVer em `v0.12.106-alpha`.

---

## 🧪 3. Validação e Qualidade

- **Zero Warnings Estrito:** O console da Godot 4 manteve 0 warnings e 0 erros durante os testes headless de `scenes/main.tscn`, `scenes/menu/main_menu.tscn` e `tests/test_editor_goals_and_panel.gd`.
- **Persistência e Coerência Visual:** Validada a gravação imediata de vitória, o comportamento independente dos números flutuantes no mundo 3D, a contagem 6:1 de grama e a estética cyber de cantos retos chanfrados em todas as abas do Hub.
