# 095 - Otimização de Performance: Refinamento de Ciclos Ociosos de CPU no HUD, Olhos, Joystick e Corte (Tarefa 3.3) ⚡🧠

## 1. Contexto e Diagnóstico
Em jogos mobile casual com alvo estrito de 60 FPS contínuos, micro-desperdícios a cada tick de 60Hz somam milissegundos preciosos de tempo de quadro e provocam aquecimento térmico do processador.
Na **Tarefa 3.3**, foram eliminados quatro padrões de processamento ocioso identificados no loop principal:

1. **HUD (`hud.gd`):** O texto do cronômetro (`timer_label.text`) era reformatado a cada frame (`"%d:%02d" % [min, sec]`), gerando 59 alocações de string idênticas por segundo e disparando recálculos de layout e rasterização de fontes.
2. **Olhos do Robô (`robot_eyes.gd`):** O uniform de shader `look_offset` era enviado para a GPU a 60Hz mesmo com o robô parado e as pupilas estáticas.
3. **Joystick Flutuante (`floating_joystick.gd`):** Em celulares Android (`OS.has_feature("mobile")`), o loop `_process()` realizava polling repetido de teclas físicas de teclado (WASD / Setas).
4. **Corte da Serra (`cutter.gd`):** Se o robô permanecesse parado no mesmo ponto, o método `_process_cutting()` continuava varrendo a grade espacial 2D de vegetação e invocando a pintura da trilha a cada 1/60s.

---

## 2. Soluções Implementadas

### A. HUD: Atualização do Cronômetro Estritamente 1x por Segundo
Em [`scripts/ui/hud.gd`](../../scripts/ui/hud.gd):
- Adicionada a variável de controle `_last_displayed_total_seconds: int = -1`.
- Em `_on_time_updated(time_left)`:
  ```gdscript
  var total_sec: int = int(ceilf(time_left))
  if total_sec == _last_displayed_total_seconds:
      return
  _last_displayed_total_seconds = total_sec
  ```
- A reformatação de texto e ajustes visuais ocorrem rigorosamente **uma única vez por segundo**, poupando 59 recálculos e alocações de string por segundo.

### B. RobotEyes: Early-Exit de Shading em Repouso
Em [`scripts/cutter/robot_eyes.gd`](../../scripts/cutter/robot_eyes.gd):
- Adicionada a variável `_last_applied_look_offset: Vector2 = Vector2(-999.0, -999.0)`.
- No `_process(delta)`, a interpolação só executa se houver diferença perceptível (`not _current_look_offset.is_equal_approx(_target_look_offset)`) e a chamada C++ `set_shader_parameter("look_offset", ...)` só é emitida se o deslocamento exceder o limiar de $0.000004$. Em repouso, zero chamadas à GPU.

### C. FloatingJoystick: Supressão de Polling de Teclado no Mobile
Em [`scripts/ui/floating_joystick.gd`](../../scripts/ui/floating_joystick.gd):
- Cacheado `_is_mobile = OS.has_feature("mobile")` no `_ready()`.
- No `_process()`, o teste de fallback de teclas físicas só é consultado em plataformas desktop (`if not is_active and not _is_mobile:`).

### D. Cutter: Early-Exit de Ceifa quando Estacionário
Em [`scripts/cutter/cutter.gd`](../../scripts/cutter/cutter.gd):
- Adicionadas as variáveis de rastreamento `_last_cut_pos` e `_last_cut_radius`.
- No `_process_cutting()`, se o robô não se deslocou mais de 2cm (`distance_squared < 0.0004`) e o raio da lâmina não foi alterado por upgrade, a varredura da grade espacial é imediatamente ignorada.

---

## 3. Preservação do Game Feel e Resultados
- **Resposta Instantânea Preservada:** O robô ceifa imediatamente no primeiro milissegundo de movimento. O cronômetro exibe os segundos com precisão exata. Os olhos acompanham as manobras com fluidez perfeita.
- **Alívio Global de CPU:** Eliminação de dezenas de alocações e chamadas nativas redundantes por segundo, reduzindo a temperatura do aparelho e estabilizando os 60 FPS.
- **Zero Warnings:** Totalmente aderente às regras de GDScript 4 defensivo.

---

## 4. Arquivos Modificados
- [`scripts/ui/hud.gd`](../../scripts/ui/hud.gd): Throttle de segundo no cronômetro.
- [`scripts/cutter/robot_eyes.gd`](../../scripts/cutter/robot_eyes.gd): Early-exit de look_offset.
- [`scripts/ui/floating_joystick.gd`](../../scripts/ui/floating_joystick.gd): Supressão de polling de teclado em mobile.
- [`scripts/cutter/cutter.gd`](../../scripts/cutter/cutter.gd): Early-exit de ceifa estacionária.
- [`scripts/core/game_version.gd`](../../scripts/core/game_version.gd): Incremento para `v0.12.19-alpha`.
- [`project.godot`](../../project.godot) & [`export_presets.cfg`](../../export_presets.cfg): Bump SemVer (build `1219`).
- [`docs/05_arquitetura_e_desenvolvimento/PLANO_MESTRE_DE_PERFORMANCE.md`](../05_arquitetura_e_desenvolvimento/PLANO_MESTRE_DE_PERFORMANCE.md): Tarefa 3.3 marcada como concluída.
- [`docs/historico_melhorias/INDICE_MELHORIAS.md`](INDICE_MELHORIAS.md): Indexação do item 095.
