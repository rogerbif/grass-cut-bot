# Melhoria 027: Rotação Suave em Marcha Lenta (Idle) da Lâmina [v0.4.10] 🪚⏳

## 1. Visão Geral e Contexto
O usuário solicitou um refinamento no comportamento da serra circular do robô quando parado:
- *"outra melhoria quando o robo não estiver se movendo a lamina deve girar bem lenta"*

Anteriormente, a lâmina girava continuamente em velocidade máxima constante ($1200^\circ/\text{s}$, ~200 RPM) mesmo quando o jogador não tocava no joystick. Esta melhoria implementa uma velocidade de marcha lenta (*idle*) bem suave ($90^\circ/\text{s}$) quando o robô está imóvel, com aceleração imediata para a rotação de corte quando em movimento e desaceleração inercial suave ao parar.

---

## 2. Implementações Técnicas

### A. Novo Parâmetro Exportado de Rotação em Idle (`idle_rotation_speed = 90.0`)
- Adicionado `@export var idle_rotation_speed: float = 90.0` em [`cutter.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/cutter/cutter.gd).
- A velocidade de $90^\circ/\text{s}$ corresponde a 1 rotação completa a cada 4 segundos (15 RPM), permitindo observar nitidamente as pontas da lâmina girando de forma calma, mecânica e relaxante enquanto o robô aguarda comandos.

### B. Transição Dinâmica e Aceleração/Desaceleração Inercial
- Adicionada a variável de estado `current_blade_speed: float = 90.0`, inicializada no `_ready()` com o valor de `idle_rotation_speed`.
- No ciclo de física `_physics_process`:
  - **Detecção de Movimento:** Verifica se o cortador possui velocidade linear relevante ou entrada no joystick (`velocity.length_squared() > 0.01 or input_direction.length_squared() > 0.01`).
  - **Velocidade Alvo:** Alterna entre `rotation_speed` ($1200^\circ/\text{s}$) e `idle_rotation_speed` ($90^\circ/\text{s}$).
  - **Aceleração Instantânea no Toque:** Ao receber entrada de condução, a lâmina ganha velocidade rapidamente com taxa de `12.0 * delta`, atingindo velocidade máxima de corte em menos de 0.15s.
  - **Desaceleração Inercial no Repouso:** Ao soltar o joystick, a lâmina desliza e desacelera suavemente com taxa de `3.5 * delta` ao longo de ~0.8s, simulando o efeito inercial de volante mecânico até repousar na rotação de marcha lenta.
  - **Pausa e Fim de Fase:** Mantida a desativação total (`current_blade_speed = 0.0`) quando o jogo não estiver no estado ativo `PLAYING`.

---

## 3. Arquivos Modificados
- [`scripts/cutter/cutter.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/cutter/cutter.gd)
- [`docs/02_entidades_e_mecanicas/SISTEMA_DO_CORTADOR.md`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/docs/02_entidades_e_mecanicas/SISTEMA_DO_CORTADOR.md)
- [`docs/historico_melhorias/INDICE_MELHORIAS.md`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/docs/historico_melhorias/INDICE_MELHORIAS.md)
- [`project.godot`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/project.godot)

---

## 4. Validação e Qualidade
- **Zero Warnings / Zero Erros:** Validado em execução direta via Godot MCP (`run_project` e `get_debug_output`).
- **Game SemVer:** Atualizado para **`v0.4.10`** em `project.godot`.
