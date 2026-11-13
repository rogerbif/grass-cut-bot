# Relatório de Melhoria: Card de Tempo Recorde e Exibição de Tempo Total na Tela de Vitória

**Versão:** `v0.12.202-alpha`  
**Data:** 13/11/2026  
**Status:** Concluído com Sucesso

---

## 🎯 Objetivos Realizados

1. **Exibição Contínua de Tempo Total ao Lado do Tempo Atual:**
   - O card de tempo decorrido no `VictoryModal` agora sempre exibe o formato `tempo_decorrido / tempo_total` (ex: `0:34 / 2:00`), permitindo ao jogador comparar imediatamente seu desempenho com o limite da fase.
   - Legenda inferior `"Tempo Atual"` localizada (pt-BR, en-US, es).

2. **Novo Card Central de Tempo Recorde (`RecordCol`):**
   - Criação da coluna central no cabeçalho de vitória com cápsula chanfrada dourada (`badge_stat_pill_gold.svg`), troféu em ouro vibrante (`icon_trophy_gold.svg`), raio elétrico amarelo cyber (`icon_lightning_cyber.svg`) e legenda inferior `"Recorde!"`.
   - **Regra Condicional Estrita:** O card de recorde só é exibido se o jogador já tiver concluído a fase anteriormente (`times_completed > 1`), exibindo sempre a melhor marca histórica alcançada (menor tempo decorrido).
   - Na 1ª vitória de uma fase, o card de recorde permanece oculto e os dois cards ("Tempo Atual" e "Bônus") preenchem o espaço com proporção harmônica de 312px cada. Ao repetir a fase, as 3 colunas se ajustam automaticamente para ~208px cada, perfeitamente centralizadas.

3. **Persistência e Rastreamento de Recorde no SaveManager:**
   - Adicionados os campos `times_completed: int` e `best_time_taken: float` (menor tempo decorrido) ao dicionário persistido de cada fase em `levels[key]`.
   - Criados métodos de consulta: `get_level_best_time_taken(level_num)`, `get_level_completion_count(level_num)` e `has_level_record(level_num)`.
   - Mantida retrocompatibilidade completa com saves legados que utilizavam apenas `best_time_left`.

4. **Internacionalização (i18n):**
   - Adicionadas chaves ao `translations.csv` para os três cards:
     - `HUD_CURRENT_TIME`: "Tempo Atual" / "Current Time" / "Tiempo Actual"
     - `HUD_RECORD_TIME`: "Recorde!" / "Record!" / "¡Récord!"
     - `HUD_BONUS_LABEL`: "Bônus" / "Bonus" / "Bonificación"

---

## 📂 Arquivos Modificados / Criados

- `assets/ui/victory/badge_stat_pill_gold.svg`: Textura vetorial dourada da cápsula de recorde.
- `assets/icons/icon_trophy_gold.svg`: Ícone vetorial do troféu de ouro.
- `assets/icons/icon_lightning_cyber.svg`: Ícone vetorial de raio elétrico estilizado.
- `scenes/ui/hud.tscn`: Reestruturação de `StatsHBox` em 3 colunas (`TimeCol`, `RecordCol`, `CoinsCol`) com pills e sublabels.
- `scripts/ui/hud.gd`: Lógica de exibição condicional do recorde, formatação `mm:ss / mm:ss` e atualização de legendas no `_refresh_localized_ui()`.
- `scripts/core/save_manager.gd`: Gravação de `times_completed`, cálculo do menor `best_time_taken` e métodos helpers.
- `data/translations/translations.csv`: Chaves de tradução trilíngues.
- `docs/04_sistemas_e_gameplay/SISTEMA_DE_INTERFACE_HUD.md`: Documentação atualizada do VictoryModal.
- `docs/05_arquitetura_e_desenvolvimento/SISTEMA_DE_SAVE.md`: Documentação atualizada da estrutura de save.
- `project.godot`, `export_presets.cfg` e `scripts/core/game_version.gd`: Incremento Game SemVer para `v0.12.202-alpha`.
