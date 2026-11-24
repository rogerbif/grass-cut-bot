# Sistema de Bônus Diário de 7 Dias (`v0.12.218-alpha`)

## 🎯 Objetivo
Implementar o sistema de **Bônus Diário (Daily Login Bonus)** com ciclo de 7 dias por calendário civil local, modal Cyber-Mecha dedicado, indicador de notificação na `TopBar`, localização trilíngue e persistência atômica no `SaveManager`.

---

## 🛠️ Alterações Realizadas

1. **Persistência e Regras de Sequência ([save_manager.gd](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/core/save_manager.gd)):**
   - Adicionado o bloco `"daily_bonus"` (`streak`, `last_claim_day`, `total_claims`) ao esquema padrão do save, com merge retrocompatível e reset em `reset_to_defaults()`.
   - Implementada tabela de recompensas crescentes: `50 / 100 / 150 / 250 / 350 / 500 / 1.000` moedas verdes, com recarga completa de vidas no **Dia 7** (`refill_lives_full()`).
   - Lógica de calendário civil local (meia-noite `00:00`), bloqueio de resgate duplicado no mesmo dia, reinício automático após o Dia 7 e reset de sequência ao pular um dia inteiro.

2. **Modal Cyber-Mecha ([daily_bonus_modal.gd](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/ui/daily_bonus_modal.gd) / [daily_bonus_modal.tscn](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/ui/daily_bonus_modal.tscn)):**
   - Interface construída programaticamente com grade 3x2 (Dias 1–6) + card de destaque para o Dia 7, destaque pulsante no dia atual, selos de resgatado (`✔`), contagem regressiva `HH:MM:SS` quando já coletado no dia, som (`buy`) e vibração háptica.

3. **Integração na `TopBar` e `MainMenu` ([main_menu.gd](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/menu/main_menu.gd) / [main_menu.tscn](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/menu/main_menu.tscn)):**
   - Adicionado botão de presente ([icon_gift.svg](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/assets/icons/icon_gift.svg)) com ponto indicador vermelho/dourado quando há recompensa disponível.
   - Abertura automática suave após o fade-in inicial apenas quando o bônus do dia estiver disponível.

4. **Localização ([translations.csv](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/data/translations/translations.csv)):**
   - Adicionadas 7 chaves `DAILY_BONUS_*` em `pt_BR`, `en` e `es`, com reimportação dos binários `.translation`.

---

## ✅ Validação e Testes
- [test_daily_bonus.tscn](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/tests/test_daily_bonus.tscn) / [test_daily_bonus.gd](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/tests/test_daily_bonus.gd): **5/5 grupos de teste aprovados** (primeiro resgate, bloqueio no mesmo dia, ciclo completo 1..7 com refil de vidas, reinício no Dia 8, reset por dia pulado e instanciação das cenas `DailyBonusModal` e `MainMenu`).
- Regressão em `test_save_manager.tscn` e `test_translations.gd`: **100% aprovados**.
