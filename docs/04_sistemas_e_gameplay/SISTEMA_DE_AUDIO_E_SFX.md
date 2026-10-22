# Sistema de Áudio e Sonoplastia 🎵🔊

Este documento estabelece as diretrizes canônicas, arquitetura de barramentos e regras de implementação do subsistema de áudio de **Grass Cut Bot**.

---

## 1. Visão Geral e Filosofia de Áudio

O design de áudio do **Grass Cut Bot** segue os pilares de **relaxamento tátil ("satisfying"), dinamismo arcade e zero fadiga auditiva**:
- **Clareza e Espaçamento:** Efeitos de corte repetitivo utilizam controle rígido de *throttling* (debounce de 35ms) e variação sutil e orgânica de pitch (`0.92 ~ 1.08`) para evitar sobreposições desagradáveis (machine gun effect).
- **Desacoplamento Total:** Toda a reprodução é orquestrada centralizadamente pelo Autoload `AudioManager` (`scripts/core/audio_manager.gd`), com `process_mode = PROCESS_MODE_ALWAYS` para suportar transições e sons de interface mesmo durante pausa.
- **Barramentos Nativos e Isolados:** O layout [`default_bus_layout.tres`](../../default_bus_layout.tres) divide o fluxo em `Master`, `Music` e `SFX`, possibilitando mutar e calibrar volumes de música e efeitos de forma atômica.

---

## 2. Barramentos de Áudio (`default_bus_layout.tres`)

| Barramento (Bus) | Volume Base | Destino (Send) | Papel no Ecossistema |
| :--- | :--- | :--- | :--- |
| **`Master`** | `0.0 dB` | Saída do Dispositivo | Barramento mestre do jogo. |
| **`Music`** | `-3.0 dB` | `Master` | Trilhas sonoras em loop (Menu e Gameplay). |
| **`SFX`** | `0.0 dB` | `Master` | Efeitos mecânicos, impactos, motor elétrico e UI. |

---

## 3. Mapeamento de Recursos (`assets/audio/`)

### Trilhas Sonoras (`assets/audio/music/`)
- `Dance By Yourself - Dyalla.mp3`: Trilha suave e descontraída tocada no Menu Principal, Garagem, Coleção e Loja.
- `Groove - Dyalla.mp3`: Trilha dinâmica e animada tocada durante o gameplay das fases.

### Efeitos Sonoros (`assets/audio/sfx/`)
1. **Corte e Vegetação:**
   - `Grass-cut.ogg`: Corte padrão de tufos de grama comum (com pitch randômico e debounce de 35ms).
   - `CutFruit.wav`: Corte especial para flores (`flower_tuft`) e trigo (`wheat_tuft`).
2. **Impactos e Física:**
   - `Slap_rock.wav`: Choque seco com rochas e obstáculos sólidos, sincronizado com tremor de câmera e faíscas.
   - `Water_splash.wav`: Borrifo de água costeira ao aproximar-se da borda do oceano.
3. **Motor Elétrico Procedural:**
   - `Electric_Engine.wav`: Loop contínuo do motor da serra, modulado proceduralmente por velocidade (repouso a `0.85x` pitch / aceleração até `1.25x` pitch).
4. **Economia e Recompensas:**
   - `coin_pickup.wav`: Ganho de moedas e feedback imediato a cada ceifada.
   - `Buy_sell.wav`: Transações comerciais realizadas com sucesso.
   - `Power_up.mp3`: Evolução de atributos (raio, potência, velocidade, multiplicador).
   - `Denied.wav`: Ação recusada / moedas insuficientes.
5. **Vitória, Derrota e Metas:**
   - `Star_win.mp3`: Fanfarra triunfal ao concluir todas as metas do nível.
   - `Star_pop.wav`: Revelação progressiva de cada estrela (1, 2, 3) no modal de vitória.
   - `MachinePowerOff.ogg`: Desligamento mecânico do robô quando o tempo esgota.
   - `goal_completed.wav`: Chime comemorativo quando uma meta específica de planta atinge 100%.
   - `Timer_Countdown.wav`: Alerta auditivo de urgência nos últimos 15 segundos da fase.
6. **Interface e Modais:**
   - `Confirm.wav`: Clique padrão de navegação e abas.
   - `Close.wav`: Fechar janelas e modais.
   - `Pause.wav`: Abertura do menu de pausa.
   - `Unpause.wav`: Retomada da partida.
   - `Fast_foward.mp3`: Botão "Próxima Fase ➔".
   - `Use_item.wav`: Equipar lâminas / skins na Garagem.

---

## 4. API Pública do `AudioManager`

```gdscript
# Trilhas Musicais
AudioManager.play_menu_music(fade_duration: float = 0.4) -> void
AudioManager.play_gameplay_music(fade_duration: float = 0.4) -> void
AudioManager.stop_music(fade_duration: float = 0.4) -> void

# Efeitos Sonoros Gerais
AudioManager.play_sfx(key: String, pitch_range: float = 0.0, volume_offset_db: float = 0.0) -> void

# Gameplay Especial com Throttling
AudioManager.play_cut_sfx(is_special: bool = false) -> void
AudioManager.play_coin_sfx() -> void
AudioManager.play_countdown_alert() -> void

# Motor Elétrico Contínuo
AudioManager.start_engine() -> void
AudioManager.stop_engine() -> void
AudioManager.update_engine_speed(speed_ratio: float) -> void # ratio de 0.0 a 1.0

# Barramentos e Configurações
AudioManager.set_music_enabled(enabled: bool) -> void
AudioManager.set_sfx_enabled(enabled: bool) -> void
AudioManager.is_music_enabled() -> bool
AudioManager.is_sfx_enabled() -> bool
```
