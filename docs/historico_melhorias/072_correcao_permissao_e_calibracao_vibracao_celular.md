# Melhoria 072: Correção de Permissão VIBRATE e Calibração Háptica no Celular 📳🤖

**Data:** 22/10/2026  
**Versão:** `v0.10.9-alpha` (Code: `1009`)  
**Status:** Concluído com Sucesso ✅  
**Arquivos Principais Afetados:**
- `export_presets.cfg`
- `scripts/core/game_manager.gd`
- `scripts/core/game_version.gd`
- `project.godot`
- `docs/04_sistemas_e_gameplay/GAME_FEEL_E_HAPTICS.md`
- `docs/05_arquitetura_e_desenvolvimento/PORTABILIDADE_ANDROID.md`

---

## 1. Motivação e Diagnóstico
O sistema de vibração móvel (`Input.vibrate_handheld`) não emitia nenhum retorno tátil quando o jogo era executado em smartphones Android. A análise do código e dos presets identificou três razões técnicas convergentes:
1. **Permissão Ausente no APK:** O arquivo `export_presets.cfg` continha `permissions/vibrate=false`. Por conseguinte, o manifesto do Android gerado pela Godot não declarava `<uses-permission android:name="android.permission.VIBRATE" />`, fazendo com que o Android SecurityManager bloqueasse qualquer requisição de vibração silenciosamente.
2. **Duração Abaixo da Inércia dos Motores Físicos:** O pulso de 15ms anterior ficava abaixo do tempo de subida (rise time / spin-up) dos atuadores ERM/LRA presentes em grande parte dos dispositivos comerciais, resultando em força nula ou descarte pelo driver de haptics.
3. **Cancelamento em Cascata por Múltiplos Cortes Consecutivos:** No `VegetationGrid`, cortar tufos em milissegundos adjacentes chamava `Input.vibrate_handheld` repetidamente sem intervalo. No Android, cada chamada a `vibrate` cancela a vibração corrente, gerando interrupções constantes antes que o motor pudesse se mover.

---

## 2. Ações Executadas

### A. Liberação da Permissão no Preset Android (`export_presets.cfg`)
- Alterado `permissions/vibrate=true` no preset oficial Android (`grasscutbot`).
- Sincronizados `version/name="0.10.9-alpha"` e `version/code=1009`.

### B. Calibração e Micro-Cooldown Háptico (`game_manager.gd`)
- Adicionadas constantes canônicas de vibração:
  - `HAPTIC_CUT_DURATION_MS = 30`: Pulso nítido e vigoroso suficiente para vencer a inércia do motor.
  - `HAPTIC_CUT_COOLDOWN_MS = 35`: Janela protetora de tempo que impede cancelamentos mútuos ao ceifar grama densa.
  - `HAPTIC_IMPACT_DURATION_MS = 65`: Pulso forte para colisão com rochas.
- Implementado controle de timestamp via `Time.get_ticks_msec()` para garantir que cada vibração de corte complete o ciclo mecânico, gerando o zumbido contínuo e satisfatório esperado ("brrr").
- Validação multi-plataforma com checagem segura para Android, iOS e ambientes móveis.

### C. Versionamento SemVer e Documentação
- Versão do projeto elevada para `0.10.9-alpha` em `GameVersion.gd` e `project.godot`.
- Documentação canônica atualizada em `GAME_FEEL_E_HAPTICS.md` e `PORTABILIDADE_ANDROID.md`.

---

## 3. Verificação e Resultados
- **Godot Headless Check:** 0 warnings e 0 erros de sintaxe nos scripts alterados.
- **Configuração de Exportação:** Permissão `android.permission.VIBRATE` agora garantida no manifesto compilado.
