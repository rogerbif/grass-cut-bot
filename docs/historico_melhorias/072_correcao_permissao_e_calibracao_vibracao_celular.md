# Melhoria 072: Correção de Permissão VIBRATE e Calibração Háptica no Celular 📳🤖

**Data:** 22/10/2026  
**Versão:** `v0.11.1-alpha` (Code: `1101`)  
**Status:** Concluído com Sucesso ✅  
**Arquivos Principais Afetados:**
- `export_presets.cfg`
- `scripts/core/game_manager.gd`
- `scripts/ui/settings_modal.gd`
- `scripts/core/game_version.gd`
- `project.godot`
- `docs/04_sistemas_e_gameplay/GAME_FEEL_E_HAPTICS.md`
- `docs/05_arquitetura_e_desenvolvimento/PORTABILIDADE_ANDROID.md`

---

## 1. Motivação e Diagnóstico
O sistema de vibração móvel (`Input.vibrate_handheld`) não emitia retorno tátil em smartphones Android. A análise do código, dos presets e um diagnóstico com `dumpsys vibrator_manager` no aparelho físico revelaram as seguintes causas:
1. **Permissão Ausente no APK:** O arquivo `export_presets.cfg` continha `permissions/vibrate=false`. Por conseguinte, o manifesto do Android gerado pela Godot não declarava `<uses-permission android:name="android.permission.VIBRATE" />`, fazendo com que o Android SecurityManager bloqueasse qualquer requisição de vibração silenciosamente.
2. **Duração Abaixo da Inércia dos Motores Físicos:** O pulso de 15ms anterior ficava abaixo do tempo de subida (rise time / spin-up) dos atuadores ERM/LRA presentes em dispositivos comerciais, resultando em força nula ou descarte pelo driver de haptics.
3. **Cancelamento em Cascata por Múltiplos Cortes Consecutivos:** No `VegetationGrid`, cortar tufos em milissegundos adjacentes chamava `Input.vibrate_handheld` repetidamente sem intervalo. No Android, cada chamada a `vibrate` cancela a vibração corrente, gerando interrupções constantes.
4. **Configuração Global do Sistema Android (Retorno Tátil Desativado):** O Android classifica as chamadas de vibração da Godot (`Input.vibrate_handheld`) sob `Usage=TOUCH`. No aparelho de teste, a configuração do sistema `haptic_feedback_enabled` estava em `0` (`TOUCH=(OFF,default:MEDIUM)`), fazendo o Android descartar as vibrações com `status: ignored_for_settings`.

---

## 2. Ações Executadas

### A. Liberação da Permissão no Preset Android (`export_presets.cfg`)
- Alterado `permissions/vibrate=true` no preset oficial Android (`grasscutbot`).
- Sincronizados `version/name="0.11.1-alpha"` e `version/code=1101`.

### B. Calibração e Micro-Cooldown Háptico (`game_manager.gd`)
- Adicionadas constantes canônicas de vibração:
  - `HAPTIC_CUT_DURATION_MS = 30`: Pulso nítido e vigoroso suficiente para vencer a inércia do motor.
  - `HAPTIC_CUT_COOLDOWN_MS = 35`: Janela protetora de tempo que impede cancelamentos mútuos ao ceifar grama densa.
  - `HAPTIC_IMPACT_DURATION_MS = 65`: Pulso forte para colisão com rochas.
- Implementado controle de timestamp via `Time.get_ticks_msec()` para garantir que cada vibração de corte complete o ciclo mecânico, gerando o zumbido contínuo e satisfatório esperado ("brrr").
- Validação multi-plataforma com checagem segura para Android, iOS e ambientes móveis.

### C. Abertura Direta dos Ajustes de Som do Android (`settings_modal.gd`)
- Utilizando `JavaClassWrapper` e `AndroidRuntime`, o jogo agora detecta em tempo real se o "Retorno Tátil" está desligado no sistema Android (`haptic_feedback_enabled == 0`).
- Adicionado botão interativo no modal de configurações:
  - Emite aviso em caso de retorno tátil desligado: `⚠️ Retorno Tátil desligado no Android (Abrir ⚙️)`.
  - Ao ser clicado, dispara o Intent nativo `android.provider.Settings.ACTION_SOUND_SETTINGS`, abrindo a tela de Som e Vibração do Android para o usuário com 1 toque.
  - No evento `NOTIFICATION_APPLICATION_FOCUS_IN`, o estado do botão é automaticamente atualizado quando o jogador retorna das configurações do celular.
  - O botão de teste do modal agora dispara pulso firme de 200ms (`Input.vibrate_handheld(200)`).

### D. Versionamento SemVer e Documentação
- Versão do projeto elevada para `0.11.1-alpha` em `GameVersion.gd` e `project.godot`.
- Documentação canônica atualizada em `GAME_FEEL_E_HAPTICS.md` e `PORTABILIDADE_ANDROID.md`.

---

## 3. Verificação e Resultados
- **Godot Headless Check:** 0 warnings e 0 erros de sintaxe nos scripts alterados.
- **Configuração de Exportação:** Permissão `android.permission.VIBRATE` agora garantida no manifesto compilado.
