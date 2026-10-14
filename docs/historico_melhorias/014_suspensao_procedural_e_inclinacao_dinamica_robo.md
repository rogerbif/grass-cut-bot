# Melhoria 014: Suspensão Procedural, Inclinação Dinâmica e Articulações do Robô [v0.3.7] 🚜⚙️

## 1. Visão Geral e Objetivos
Implementação de um sistema de física procedural e animação secundária para o robô cortador no Godot 4, dotando o veículo de peso, inércia, suspensão reativa e expressividade mecânica contínua:
1. **Suspensão Vertical Reativa:** Efeito de *bobbing* suave sincronizado à rotação da mono-wheel e absorção de desníveis pelo chassi e roda.
2. **Reação dos Braços Articulados:** Oscilação mecânica sutil de contra-reação para `low_arm` e `up_arm` acompanhando o curso da suspensão.
3. **Inclinação Dinâmica (Pitch & Roll / Lean):**
   - **Pitch:** O chassi inclina suavemente para frente na aceleração frontal e empina sutilmente em frenagens/marcha ré.
   - **Roll:** O chassi aderna lateralmente para dentro das curvas com base na taxa angular (*turn rate* / yaw delta) do joystick.
4. **Articulação de Cabeça e Pescoço (`head` e `neck`):**
   - **Pescoço:** Estabilização sutil contra o pitch do chassi para manter o horizonte do olhar.
   - **Cabeça:** Inércia/antecipação angular de yaw nas curvas fechadas, sem desconectar as malhas.
5. **Absorção de Impacto (Knockback Shock):** Compressão vertical súbita da suspensão ao colidir com obstáculos sólidos/rochas com retorno amortecido.

---

## 2. Ações Executadas

### 2.1. Calibração Anatômica de Pivôs no Blender (`grass_bot_00.blend`)
Para permitir rotações e articulações naturais sem separação de peças ou deformação de malha:
- `neck`: Pivô ajustado para $(0.0, -0.185, 1.200)$, alinhado à base do pescoço com o chassi.
- `head`: Pivô ajustado para $(0.0, -0.250, 1.480)$, alinhado ao encaixe superior com o pescoço.
- `low_arm`: Pivô ajustado para $(0.0, 0.007, 0.620)$, coincidente ao eixo central da roda.
- `up_arm`: Pivô ajustado para $(0.0, 0.120, 1.150)$, na fixação superior do chassi.
- Preservação estrita dos modificadores `Mirror` e exportação glTF com `export_apply=True` para `assets/models/grass_bot.glb`.

### 2.2. Implementação da Física Procedural no Godot (`scripts/cutter/cutter.gd`)
- Criação do grupo `@export_group("Procedural Motion")`:
  - `max_pitch_deg: float = 6.0` (inclinação frontal/traseira)
  - `max_roll_deg: float = 4.5` (adernamento lateral em curvas)
  - `tilt_responsiveness: float = 9.0` (taxa de interpolação do chassi)
  - `suspension_bob_amp: float = 0.022` (amplitude de oscilação vertical)
  - `suspension_frequency: float = 14.0` (frequência associada à velocidade linear)
  - `head_lag_factor: float = 0.28` (sensibilidade da inércia do olhar)
- Implementação de `_process_procedural_motion(delta, target_speed)` executada a cada frame de física:
  - Cálculo de `forward_speed` via produto escalar com a orientação do chassi.
  - Cálculo de `turn_rate` a partir do `yaw_delta` do chassi.
  - Deformação vertical do chassi `robot_body.position.y` e contra-reação oposta da roda `wheel_mesh.position.y`.
  - Rotação compensatória dos braços em `rotation.x`.
  - Estabilização do pescoço e antecipação angular da cabeça.
  - Compressão rápida de impacto `shock_compression = -0.045` em `_trigger_obstacle_shock()`.

### 2.3. Atualização Documental e Canônica
- Atualização de `docs/02_entidades_e_mecanicas/SISTEMA_DO_CORTADOR.md` com a subseção de física procedural e parâmetros de suspensão.
- Atualização de `docs/04_sistemas_e_gameplay/GAME_FEEL_E_HAPTICS.md` com a Seção 4 detalhando a física de peso e inércia do robô.
- Registro no índice de melhorias `docs/historico_melhorias/INDICE_MELHORIAS.md`.

---

## 3. Validação e Qualidade
- **Zero Warnings / Zero Erros:** Verificado via Godot MCP (`run_project` e `get_debug_output`) em Godot 4.7.1.
- **Tipagem Estática:** 100% das variáveis e métodos com tipagem GDScript 4 estrita.
- **Game Feel Aprimorado:** O robô exibe movimentação fluida, peso mecânico evidente e sensação tátil aprimorada sem quebras visuais nas articulações.
