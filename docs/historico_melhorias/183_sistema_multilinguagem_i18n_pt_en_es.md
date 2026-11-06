# Melhoria 183: Sistema Multilinguagem Canônico (i18n) em Português, Inglês e Espanhol

**Status:** Concluído  
**Data:** 2026-11-06  
**Versão:** v0.12.130-alpha  
**Autores:** DeepMind Agentic Coding Assistant (Antigravity) & rogerbif  

---

## 🎯 Objetivo

Implementar a arquitetura completa de internacionalização (i18n) e multilinguagem nativa para o **Grass Cut Bot** na Godot Engine 4, com suporte de lançamento aos idiomas:
- 🇧🇷 **Português (Brasil) - `pt_BR`** (Idioma de desenvolvimento canônico)
- 🇺🇸 **Inglês - `en`** (Idioma global / fallback universal)
- 🇪🇸 **Espanhol - `es`** (Suporte América Latina e Espanha)

A solução atende aos 13 Mandamentos Invariantes: 0 Warnings estritos, tipagem estática e desacoplamento de UI reativo a `NOTIFICATION_TRANSLATION_CHANGED`.

---

## 🏗️ Arquitetura Implementada

1. **Tabela Canônica CSV (`data/translations/translations.csv`):**
   - Centraliza todas as chaves semânticas de navegação, menus, configurações, gameplay, herbário e upgrades em UTF-8 sem BOM.
   - Compilada pela Godot em binários `.translation` otimizados (`translations.pt_BR.translation`, `translations.en.translation`, `translations.es.translation`).
   - Configurada na seção `[internationalization]` do [`project.godot`](../../project.godot).

2. **Gerenciamento & Detecção no [`SaveManager`](../../scripts/core/save_manager.gd):**
   - Detecção automática do idioma nativo do sistema via `OS.get_locale_language()`.
   - Persistência da preferência do usuário na chave `"locale"` de `savegame.json`.
   - Inicialização direta do `TranslationServer` da engine no boot (`SaveManager._ready()`).

3. **Seletor de Idiomas no [`SettingsModal`](../../scenes/ui/settings_modal.tscn):**
   - Linha de controle `LanguageRow` com ícone de globo (`icon_globe.svg`) e botões segmentados Cyber `[ PT ]`, `[ EN ]`, `[ ES ]`.
   - Destaque em tempo real no idioma selecionado com borda e brilho ciano/esmeralda neon (`Color(0.25, 0.95, 0.65)`).
   - Reatividade instantânea com `NOTIFICATION_TRANSLATION_CHANGED` em [`settings_modal.gd`](../../scripts/ui/settings_modal.gd).

4. **Migração Abrangente das Telas e Componentes:**
   - **Navegação:** [`CyberNavButton`](../../scripts/ui/cyber_nav_button.gd) e [`BottomNavBar`](../../scenes/menu/bottom_nav_bar.tscn) com chaves `NAV_HOME`, `NAV_WORKSHOP`, `NAV_HERBARIUM`, `NAV_STORE`.
   - **Home & Fases:** [`CyberPlayButton`](../../scripts/ui/cyber_play_button.gd) e [`TabHome`](../../scripts/menu/tabs/tab_home.gd) ("JOGAR - Fase %d", "FASES").
   - **Card de Fases:** [`MapLevelCard`](../../scripts/ui/map_level_card.gd) ("Fase %d", "Estrelas", "Bloqueada", "Objetivos:").
   - **Modais Ingame:** [`PauseModal`](../../scripts/ui/pause_modal.gd), [`DefeatModal`](../../scripts/ui/defeat_modal.gd) e [`ExitModal`](../../scripts/ui/exit_modal.gd).
   - **TopBar & HUD:** [`HUD`](../../scripts/ui/hud.gd) (comemoração de vitória, fase concluída, moedas ganhas).
   - **Herbário & Vegetação:** [`PlantDatabase`](../../scripts/plants/plant_database.gd) (método `get_species_name(species)`) e [`TabCollection`](../../scripts/menu/tabs/tab_collection.gd).

---

## 🧪 Validação Automatizada

- [`tests/test_translations.gd`](../../tests/test_translations.gd): Carregamento e resolução de chaves nos 3 idiomas.
- [`tests/test_settings_modal_localization.gd`](../../tests/test_settings_modal_localization.gd): Alternância interativa entre botões de idioma e resposta de UI.
- [`tests/test_save_manager.gd`](../../tests/test_save_manager.gd): Persistência em save e fallback automático.
- [`tests/test_ui_localization_integration.gd`](../../tests/test_ui_localization_integration.gd): Validação completa ponta a ponta dos subsistemas.
- Cenas `scenes/menu/main_menu.tscn` e `scenes/main.tscn` executadas sem nenhum erro ou aviso no console.
