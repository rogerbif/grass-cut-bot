# Melhoria 074: Sistema de Áudio e Sonoplastia Completo 🎵🔊

**Data:** 22/10/2026  
**Versão:** `v0.11.0-alpha` (Code: `1100`)  
**Status:** Concluído com Sucesso ✅  
**Arquivos Principais Afetados:**
- `default_bus_layout.tres` [NEW]
- `scripts/core/audio_manager.gd` [NEW]
- `assets/audio/music/*` (2 trilhas) [NEW/MIGRATED]
- `assets/audio/sfx/*` (18 efeitos) [NEW/MIGRATED]
- `project.godot`
- `scripts/core/game_version.gd`
- `export_presets.cfg`
- `scripts/cutter/cutter.gd`
- `scripts/core/game_manager.gd`
- `scripts/core/upgrade_manager.gd`
- `scripts/ui/hud.gd`
- `scripts/ui/settings_modal.gd`
- `scripts/menu/main_menu.gd`
- `scripts/menu/tabs/tab_home.gd`
- `scripts/menu/tabs/tab_store.gd`
- `tests/test_audio_manager.gd` [NEW]
- `tests/test_audio_manager.tscn` [NEW]
- `docs/04_sistemas_e_gameplay/SISTEMA_DE_AUDIO_E_SFX.md` [NEW]
- `GEMINI.md`

---

## 1. Motivação e Objetivos
O jogo **Grass Cut Bot** operava até então em silêncio técnico, limitando o Game Feel ao retorno háptico de vibração e partículas visuais. Para elevar a imersão e atender à experiência sensorial de jogos casuais mobile premium, foi introduzido um ecossistema sonoro completo composto por **20 arquivos de áudio**, barramentos isolados, Singleton dedicado e controle anti-estouro (throttling com pitch randômico).

---

## 2. Ações Executadas

### A. Migração e Organização Canônica dos Recursos
- Criação das pastas canônicas:
  - `res://assets/audio/music/`
  - `res://assets/audio/sfx/`
- Migração de todos os 20 arquivos das pastas raízes antigas para o diretório canônico com reimportação automática da Godot Engine.

### B. Barramento de Áudio Dedicado (`default_bus_layout.tres`)
- **Bus 0 (Master):** Saída global.
- **Bus 1 (Music):** Volume base de `-3.0 dB` direcionado a `Master`.
- **Bus 2 (SFX):** Volume base de `0.0 dB` direcionado a `Master`.

### C. Autoload Singleton `AudioManager` (`scripts/core/audio_manager.gd`)
- Registrado em `project.godot` com `process_mode = Node.PROCESS_MODE_ALWAYS` para funcionar durante pausas e transições de tela.
- **Pooling Polifônico:** Pool de 8 nós `AudioStreamPlayer` para SFX gerais.
- **Debounce Anti-Estouro:** Controle de intervalo mínimo (35ms para cortes, 45ms para moedas, 800ms para alarme) evitando sobreposição ruidosa em ceifadas densas.
- **Variação Orgânica de Pitch:** Modulação aleatória entre `0.92x` e `1.08x` a cada golpe de serra.
- **Motor Elétrico Procedural:** Loop de `Electric_Engine.wav` com aceleração de pitch (`0.85x` a `1.25x`) e volume atrelado à velocidade do cortador.
- **Crossfade Musical:** Alternância suave entre a trilha de menu (`Dance By Yourself - Dyalla.mp3`) e a trilha de fases (`Groove - Dyalla.mp3`).

### D. Integração Completa nos Sistemas do Jogo
1. **Cortador (`cutter.gd`):** Inicialização e encerramento do motor, modulação contínua no `_physics_process` e som de impacto em rochas (`Slap_rock.wav`).
2. **Game Manager (`game_manager.gd`):** Transição de trilha musical, cortes comuns vs especiais (flores/trigo com `CutFruit.wav`), pingo de moedas (`coin_pickup.wav`), metas concluídas (`goal_completed.wav`), fanfarra de vitória (`Star_win.mp3`), desligamento do motor na derrota (`MachinePowerOff.ogg`) e sons de pausa/despausa.
3. **Oficina & Economia (`upgrade_manager.gd`):** Som de compra com sucesso (`Buy_sell.wav` + `Power_up.mp3`) e som de recusa por falta de moedas (`Denied.wav`).
4. **Interface & HUD (`hud.gd`):** Alerta nos 15s finais (`Timer_Countdown.wav`), estrelas progressivas no modal de vitória (`Star_pop.wav`), avançar de fase (`Fast_foward.mp3`) e cliques de navegação.
5. **Configurações (`settings_modal.gd`):** Mute/Unmute dinâmico nos barramentos de Music e SFX refletido no hardware de áudio.
6. **Menus (`main_menu.gd`, `tab_home.gd`, `tab_store.gd`):** Início da música de menu, cliques de abas e coleta de pacotes de recompensa.

### E. Suíte de Testes Automatizada (`tests/test_audio_manager.gd`)
- Validação completa com 7 baterias de testes aprovadas:
  1. Instanciação e ciclo de vida do `AudioManager`.
  2. Presença dos barramentos `Music` e `SFX` no `AudioServer`.
  3. Pré-carregamento dos 22 recursos de áudio.
  4. Execução de SFX e debounce.
  5. Ciclo do motor elétrico.
  6. Alternância de músicas.
  7. Mute e unmute via barramentos.

---

## 3. Verificação e Resultados
- **Logs da Engine:** `godot.log` confirmou 100% de sucesso em todos os testes sem avisos ou falhas.
- **Zero Warnings:** Tipagem estrita e convenções GDScript 4 rigorosamente respeitadas.
- **SemVer:** Incremento de MINOR: versão atualizada para `v0.11.0-alpha` (Code: `1100`).
