# Melhoria 184: Revisão Geral, Auditoria e Reatividade Completa do Sistema Multilinguagem (i18n) 🌐🌿

> **Versão:** `v0.12.131-alpha`  
> **Data:** 06/11/2026  
> **Status:** Concluído com 100% de Sucesso  
> **Idiomas:** Português (`pt_BR`), Inglês (`en`), Espanhol (`es`)

---

## 1. Visão Geral e Objetivos

Esta melhoria executou uma auditoria completa e exaustiva em **todas as telas, abas, HUD de gameplay, modais e mensagens do Grass Cut Bot**, eliminando 100% dos textos *hardcoded* restantes no projeto e estabelecendo reatividade em tempo real via `NOTIFICATION_TRANSLATION_CHANGED` em todos os nós da interface.

### Principais Ganhos:
- **Zero Strings Hardcoded:** Varredura detalhada em todas as 4 abas do menu (`TabHome`, `TabGarage`, `TabStore`, `TabCollection`), na placa 3D de fim de mapa (`CloudsEndNode`), na barra de nível da lâmina (`BladeProgressBar`), na oficina in-game do `HUD`, nos modais de resultado e nos toasts de feedback da `SettingsModal`.
- **Reatividade Instantânea em Tempo Real:** Todos os componentes (`TabGarage`, `TabStore`, `TabCollection`, `TabHome`, `MapLevelCard`, `CloudsEndNode`, `HUD`, `PauseModal`, `DefeatModal`, `ExitModal`, `SettingsModal`, `BladeProgressBar`) implementam o listener `NOTIFICATION_TRANSLATION_CHANGED`. Ao trocar o idioma nas configurações, todas as telas abertas ou em cache atualizam seus textos na hora sem necessidade de recarregar a cena ou reiniciar o jogo.
- **Validação Automatizada:** Testes em `tests/test_ui_localization_integration.gd` e `tests/test_translations.gd` verificam dinamicamente a troca entre `pt_BR`, `en` e `es` com asserções estritas e validação de 0 warnings e 0 erros.

---

## 2. Mapa de Alterações e Componentes Atualizados

### A. Banco Canônico de Traduções (`data/translations/translations.csv`)
Adição de 45 novas chaves cobrindo os três idiomas com suas respectivas compilações binárias `.translation`:
- **Home / Mapa:** `BTN_BOT_FOCUS`, `BIOME_TROPICAL_ISLAND`, `MAP_COMING_SOON_TITLE`, `MAP_COMING_SOON_SUB`.
- **Oficina / Garage:** `GARAGE_TITLE_HEADER`, `GARAGE_BANNER_EQUIPPED`, `GARAGE_TIER_FMT`, `GARAGE_TIER_MAX_FMT`, `BLADE_TIER_1` a `BLADE_TIER_4`, `BLADE_TIER_DEFAULT`, `GARAGE_COINS_FMT`, `GARAGE_BLADE_UPGRADE_TITLE`, `GARAGE_STATS_NEXT_FMT`, `GARAGE_STATS_INGAME_FMT`, `GARAGE_STATS_MAX_FMT`, `GARAGE_BTN_STORE_MAX`, `GARAGE_TIP`.
- **Loja do Arquipélago:** `STORE_TITLE`, `STORE_WELCOME_HEADER`, `STORE_WELCOME_DESC`, `STORE_CLAIM_FREE`, `STORE_CLAIMED`, `STORE_COIN_PACKS_SECTION`, `STORE_PACK_BAG_TITLE`, `STORE_PACK_CHEST_TITLE`, `STORE_COMING_SOON`.
- **Herbário e Coleção:** `HERBARIUM_FULL_TITLE`, `HERBARIUM_SUBTITLE`, `HERBARIUM_PROGRESS_FMT`, `HERBARIUM_CHIP_HARVEST_FMT`, `HERBARIUM_CHIP_MILESTONES_FMT`, `HERBARIUM_CLAIM_ALL_FMT`, `COLLECTION_TAG_DISC`, `COLLECTION_TAG_LOCK`, `COLLECTION_ORIGIN_LVL`, `COLLECTION_ATTR_FMT`, `COLLECTION_HITS_SINGULAR`, `COLLECTION_HITS_PLURAL`, `COLLECTION_COINS_SINGULAR`, `COLLECTION_COINS_PLURAL`, `COLLECTION_ATTR_LOCKED`, `COLLECTION_DESC_LOCKED`, `COLLECTION_HARVEST_COUNT_FMT`, `COLLECTION_MILESTONE_PROG_FMT`, `COLLECTION_MILESTONE_MAX`, `COLLECTION_CLAIM_BTN_FMT`, `COLLECTION_BADGE_LOCKED_FMT`, `COLLECTION_ACTION_COMPLETE`.
- **Gameplay, HUD e Modais:** `BLADE_LEVEL_MAX`, `BLADE_LEVEL_FMT`, `WORKSHOP_TITLE`, `WORKSHOP_COINS_FMT`, `WORKSHOP_COINS_BLADE_FMT`, `WORKSHOP_BACK_TO_GAME`, `UPGRADE_BLADE_POWER`, `UPGRADE_COIN_MULTIPLIER`, `UPGRADE_ITEM_LVL_FMT`, `BTN_MENU`, `BTN_REPEAT`.
- **Toasts do SettingsModal:** `TOAST_QUALITY_PERFORMANCE`, `TOAST_QUALITY_HIGH`, `TOAST_QUALITY_BALANCED`, `TOAST_MUSIC_ON`, `TOAST_MUSIC_OFF`, `TOAST_SFX_ON`, `TOAST_SFX_OFF`, `TOAST_VIB_ON`, `TOAST_VIB_OFF`, `TOAST_VIB_SYSTEM_HINT`, `TOAST_VIB_SYSTEM_ON`, `TOAST_VIB_SYSTEM_OFF`, `TOAST_ANDROID_ONLY`, `TOAST_SAVE_ERROR`, `TOAST_COMING_SOON_GPLAY`, `TOAST_COMING_SOON_FB`, `TOAST_SUPPORT_OPENING`, `TOAST_BENCHMARK_TAPS`.

### B. Scripts Atualizados
1. `scripts/core/upgrade_manager.gd`: `get_blade_tier_name()` retorna `tr("BLADE_TIER_X")`.
2. `scripts/menu/tabs/tab_garage.gd`: Implementação de `NOTIFICATION_TRANSLATION_CHANGED` e mapeamento de todos os rótulos de status, dica e botões da oficina.
3. `scripts/menu/tabs/tab_store.gd`: Implementação de `NOTIFICATION_TRANSLATION_CHANGED` e localização dos cards de pacotes de boas-vindas e moedas verdes.
4. `scripts/menu/tabs/tab_collection.gd`: Mapeamento de títulos, chips, tags, singular/plural de golpes e moedas e botões de resgate de marcos.
5. `scripts/menu/tabs/tab_home.gd`: Localização do botão de foco do bot (`tr("BTN_BOT_FOCUS")`).
6. `scripts/ui/map_level_card.gd`: Tradução dinâmica do bioma Ilha Tropical (`tr("BIOME_TROPICAL_ISLAND")`).
7. `scenes/menu/clouds_end_node.tscn`: Localização reativa da placa 3D (`Label3D`) de fim de arquipélago.
8. `scripts/cutter/blade_progress_bar.gd`: Localização de `NÍVEL MAX` e `NÍVEL %d` com escuta de `NOTIFICATION_TRANSLATION_CHANGED`.
9. `scripts/ui/hud.gd`: Atualização da oficina in-game, botões do modal de vitória e unificação do `_notification()` para back-request mobile e translation changed.
10. `scripts/ui/pause_modal.gd`: Suporte a `NOTIFICATION_TRANSLATION_CHANGED` com atualização dos botões de ação e dos toggles de SFX, Música e Vibração.
11. `scripts/ui/defeat_modal.gd`: Suporte a `NOTIFICATION_TRANSLATION_CHANGED` atualizando progresso do corte, subtítulo dinâmico e botões de ação.
12. `scripts/ui/exit_modal.gd`: Suporte a `NOTIFICATION_TRANSLATION_CHANGED` para título, corpo explicativo e botões de confirmação/cancelamento.
13. `scripts/ui/settings_modal.gd`: Tradução completa de todas as 18 mensagens de toast.

---

## 3. Validação e Testes Automatizados

- Executado `tests/test_ui_localization_integration.gd` com cobertura de instanciação de telas, troca a quente de locales e conferência de chaves:
  - `✔ Testes integrados de UI em pt_BR aprovados.`
  - `✔ Testes integrados de UI em en aprovados.`
  - `✔ Testes integrados de UI em es aprovados.`
  - `✔ Testes de instanciação e reatividade NOTIFICATION_TRANSLATION_CHANGED aprovados!`
- Execução de 60 frames em `scenes/menu/main_menu.tscn` e `scenes/main.tscn` sem qualquer warning ou erro no console.
- Sincronização SemVer: `0.12.131-alpha` em `project.godot`, `export_presets.cfg` (`code=1331`) e `GameVersion`.
