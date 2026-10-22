# Melhoria 072: Correção de Permissão VIBRATE e Calibração Háptica no Celular 📳🤖

**Data:** 22/10/2026  
**Versão:** `v0.11.3-alpha` (Code: `1103`)  
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
- Sincronizados `version/name="0.11.3-alpha"` e `version/code=1103`.

### B. Calibração e Balanceamento de Amplitudes (`game_manager.gd`)
- Calibração de amplitudes e durações personalizadas:
  - `HAPTIC_CUT_AMPLITUDE = 0.25` (25%) e `40ms`: Micro-pulso suave e confortável ao ceifar grama contínua.
  - `HAPTIC_IMPACT_AMPLITUDE = 0.80` (80%) e `80ms`: Impacto vigoroso e pesado ao bater em pedras.
  - `HAPTIC_UI_AMPLITUDE = 0.35` (35%) e `25ms`: Feedback sutil e responsivo ao tocar em botões da UI.
  - `HAPTIC_MENU_AMPLITUDE = 1.00` (100%) e `200ms`: Confirmação firme de ativação nas configurações.
- Implementado hook global em `GameManager` escutando `get_tree().node_added` para conectar automaticamente todo e qualquer `BaseButton` adicionado à árvore ao método `trigger_haptic_ui()`.
- Micro-cooldown de 40ms para corte e 50ms para cliques da UI.

### C. Sincronização Inteligente do Retorno Tátil com o Sistema (`settings_modal.gd`)
- **Inicialização Defensiva:** Se o retorno tátil do sistema estiver desligado no Android (`haptic_feedback_enabled == 0`), o jogo inicializa com `vib_enabled = false` (`📳 Vibração: OFF`), refletindo a realidade física do aparelho.
- **Transição Condicional para ON:** Quando o jogador tenta ligar a vibração no menu (`OFF -> ON`), se o sistema do celular ainda estiver desativado, o jogo:
  1. Mantém a vibração como `OFF`.
  2. Dispara o Intent nativo `ACTION_SOUND_SETTINGS` abrindo os ajustes de Som e Vibração do Android para o jogador.
  3. Exibe o toast explicativo: *"Ative 'Retorno Tátil' nas configurações do celular!"*.
- **Detecção Reativa no Retorno (`NOTIFICATION_APPLICATION_FOCUS_IN`):**
  - Ao voltar das configurações do Android, o jogo reavalia o estado do sistema.
  - Se o usuário ativou o retorno tátil: comuta automaticamente para `📳 Vibração: ON`, grava no `SaveManager`, aciona o pulso teste de 200ms com amplitude 1.0 e exibe *"Retorno Tátil ativado! Vibração ON 📳"*.
  - Se não ativou: mantém `OFF` e alerta o jogador.

---

## 3. Verificação e Resultados
- **Godot Headless Check:** 0 warnings e 0 erros de sintaxe nos scripts alterados.
- **Configuração de Exportação:** Permissão `android.permission.VIBRATE` agora garantida no manifesto compilado.
