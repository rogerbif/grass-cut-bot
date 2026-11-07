# Game Feel, Haptics e Câmera Isométrica ✨📳

Este documento detalha os elementos sensoriais que constroem a sensação de relaxamento, prazer tátil e polimento (*Juicy Game Feel*) em **Grass Cut Bot**.

---

## 1. Os Três Pilares do "Satisfying Game Feel"

1. **Resposta Mecânica Imediata:** Não há atraso entre a passagem da lâmina e a remoção da grama. O corte ocorre no exato instante do contato radial.
2. **Recompensa Sensorial Multissensorial:** Cada corte aciona simultaneamente:
   - Resposta visual (folhas partidas estilizadas voando em cone com gravidade real e tumbling 3D + toco 3D de grama aparada revelado no solo + piso limpo).
   - Resposta de interface (card de metas com animação de pop + incremento de moedas).
   - Resposta tátil (pulso háptico no motor de vibração do smartphone).
3. **Fluidez de Movimento:** O cortador possui inércia equilibrada, permitindo deslizamento suave sem sensação de atrito excessivo.

---

## 2. Sistema de Feedback Tátil (Haptics)

O motor do jogo utiliza a API nativa da Godot para dispositivos móveis (`Input.vibrate_handheld`), com autorização obrigatória da permissão `android.permission.VIBRATE` no preset Android (`export_presets.cfg`):

| Ação do Jogo | Duração do Pulso | Força (Amplitude) | Cooldown / Rate-Limit | Sensação no Aparelho |
| :--- | :--- | :--- | :--- | :--- |
| **Corte de Tufo Vegetal** | `40 ms` | `25%` (`0.25`) | `40 ms` | Micro-pulso suave e relaxante, ideal para ceifar fileiras contínuas sem cansar a mão do jogador. |
| **Colisão com Obstáculo Sólido** | `80 ms` | `80%` (`0.80`) | Imediato (prioritário) | Impacto seco e vigoroso transmitindo rigidez física da rocha e sinalizando o ricochete da lâmina. |
| **Feedback em Botões da UI** | `25 ms` | `35%` (`0.35`) | `50 ms` | Toque tátil sutil em cada clique de botão da interface (BaseButton hook global no GameManager). |
| **Teste no Menu de Configurações** | `200 ms` | `100%` (`1.0`) | 1 disparo | Pulso firme e longo confirmando a ativação bem-sucedida da vibração. |

> [!NOTE]
> **Diferenciação Tátil: Obstáculo vs Vegetação Resistente (Melhoria 141):**
> Colisões contra rochas e paredes sólidas aplicam recuo forte (*knockback* de $4.75\text{ m/s}$), atordoamento temporário ($0.18\text{s}$) e penalidade de nível da lâmina. Em contraste, plantas resistentes (trigo e flores) **não aplicam knockback reverso nem stun** — elas apenas barram o avanço físico do robô via colisão rígida enquanto a lâmina as mastiga em ticks ágeis contínuos de $0.28\text{s}$ com micro-pulsos hápticos e partículas a cada golpe parcial, mantendo o *flow state* ininterrupto.

---

## 3. Câmera Isométrica com Zoom Dinâmico por Nível da Lâmina

- **Zoom Dinâmico Adaptativo (8.4m no Lv 1 até 12.0m no Lv 10 MAX):**
  - **Nível 1 (Base):** Distância em $8.4\text{m}$ (`offset = Vector3(0.0, 5.4258, 6.4133)`), mantendo ângulo de pitch de $-40.3^\circ$. Proporciona enquadramento 40% mais recuado/afastado para visão panorâmica confortável do início da partida.
  - **Níveis 2 a 9:** Afastamento gradual linear (+0.40m por nível) com transição suave via Tween ($0.75\text{s}$, curva cúbica desacelerada `TRANS_CUBIC` `EASE_OUT`):
    - Lv 1: $8.40\text{m}$ (`Vector3(0.0, 5.4258, 6.4133)`)
    - Lv 2: $8.80\text{m}$ (`Vector3(0.0, 5.6841, 6.7187)`)
    - Lv 3: $9.20\text{m}$ (`Vector3(0.0, 5.9425, 7.0241)`)
    - Lv 4: $9.60\text{m}$ (`Vector3(0.0, 6.2009, 7.3295)`)
    - Lv 5: $10.00\text{m}$ (`Vector3(0.0, 6.4592, 7.6349)`)
    - Lv 6: $10.40\text{m}$ (`Vector3(0.0, 6.7176, 7.9403)`)
    - Lv 7: $10.80\text{m}$ (`Vector3(0.0, 6.9760, 8.2457)`)
    - Lv 8: $11.20\text{m}$ (`Vector3(0.0, 7.2344, 8.5511)`)
    - Lv 9: $11.60\text{m}$ (`Vector3(0.0, 7.4927, 8.8565)`)
    - Lv 10 (MAX): $12.00\text{m}$ (`Vector3(0.0, 7.7511, 9.1619)`)
  - **Nível 10 (MAX):** Distância canônica máxima de $12.0\text{m}$ (`offset = Vector3(0.0, 7.7511, 9.1619)`), conferindo ampla visão panorâmica para manusear com total destreza e segurança a serra estelar de $1.40\text{m}$ de raio.
  - **Penalidade de Rochas:** Reaproximação suave e imediata caso o nível seja reduzido por perda de XP após impacto contra obstáculos sólidos.
- **Posicionamento e Orientação Fixa:**
  - Orientação angular travada com pitch de $-40.3^\circ$ (sem chamada de `look_at()` no `_process()`), eliminando qualquer oscilação ou giro dinâmico quando o cortador manobra.
  - FOV de $48^\circ$, proporcionando excelente amplitude, destaque vertical para as falésias de terra marrom e profundidade da ilha sem distorção excessiva de perspectiva em telas verticais (Portrait).
- **Amortecimento com Interpolação Linear (`lerp`) nos Eixos X, Y e Z:**
  - A câmera translada suavemente acompanhando a coordenada do cortador com `follow_speed = 8.0 * delta`, ajustando dinamicamente $Y$ e $Z$ ao offset de zoom ativo.
- **Camera Shake Procedural Translacional:**
  - Em impactos com obstáculos, o `GameManager` emite um sinal de tremor com intensidade $0.35$ e duração $0.20\text{s}$.
  - A perturbação aplica offsets aleatórios de translação apenas em $X$ e $Z$, preservando a rotação 100% rígida e sem náuseas visuais.
- **Transição Cinematográfica de Vitória (Enquadramento Idêntico à Home):**
  - Na vitória da fase (`GameManager.level_won`), a câmera executa um tween cúbico desacelerado de $0.85\text{s}$ interpolando simultaneamente posição e rotação para o enquadramento canônico do robô na tela Home:
    - Offset relativo ao robô: `Vector3(0.0, 1.25, 4.0)`
    - Rotação: `Vector3(-8.0, 0.0, 0.0)` (pitch suave de $-8^\circ$)
    - FOV: `48.0°` (completamente desobstruído para arcos de estrelas superiores e bottom bar de ações)

---

## 4. Feedback Sensorial de Level UP da Lâmina (Pop, Flash, Choque e Slash)

A evolução da lâmina durante a partida é celebrada com uma cascata harmônica de micro-eventos táteis e visuais (Melhoria 135):
1. **Pop Elástico com Squash & Stretch:** Punch de escala $1.38\times$ na serra em $0.07\text{s}$ com retorno em mola amortecida ($0.30\text{s}$, `TRANS_BACK`), transmitindo fisicamente o ganho instantâneo de diâmetro e dentes de aço.
2. **Flash Momentâneo e Brilho:** Pico emissivo instantâneo ($2.5\times$) decaindo suavemente para o repouso.
3. **Onda de Choque Radial no Solo:** Anel fino de luz dourada aditiva que surge no centro da lâmina e expande pelo chão em alta velocidade até ultrapassar as pontas cortantes, dissipando-se em $0.32\text{s}$ com fade exponencial.
4. **Shader de Slash Giratório Multi-Ponta Afilado por Lâmina:** Rastro vetorial 100% analítico na GPU (zero texturas VRAM) associado a cada ponta da lâmina ativa (3, 4, 5 ou 6 dentes). O rastro inicia largo na ponta da lâmina e afina até uma terminação em agulha enquanto transiciona para transparência total, ganhando brilho extra e intensidade luminosa dinâmica com a velocidade de rotação e picos de Level Up.
5. **Haptics no Mobile:** Vibração curta e precisa de $25\text{ms}$ (`Input.vibrate_handheld(25)`), marcando fisicamente a conquista do jogador.

---

## 5. Animação Procedural do Robô (Suspensão e Inclinação)

Para evitar que o robô pareça uma estátua rígida sobre o terreno, um conjunto de forças e molas procedurais dá vida e peso à máquina:
1. **Lean em Curvas:** O chassi inclina suavemente para o lado da curva em rotações com o joystick ($\pm 4.5^\circ$), conferindo sensação de aderência mecânica.
2. **Pitch de Aceleração e Frenagem:** Ao arrancar, o bico inclina para frente ($\pm 6^\circ$); ao soltar o joystick ou colidir, ele recua com amortecimento natural.
3. **Bobbing e Absorção de Solo:** O corpo oscila sutilmente verticalmente ($\pm 0.022\text{m}$) enquanto o pneu e braços absorvem o relevo.
4. **Vida na Cabeça e Pescoço:** Pequenos atrasos elásticos e micro-reações ao virar fazem o robô "olhar" na direção do corte.

---

## 5. Expressões Faciais e Reações Emocionais dos Olhos de LED 🤖✨

As expressões digitais do robô complementam o *Game Feel* adicionando carisma, legibilidade imediata de estado e reforço sensorial:
1. **Piscar Orgânico Autônomo:** Em estado de repouso ou deslocamento padrão, o robô pisca aleatoriamente a cada 3~6 segundos via interpolação do parâmetro `blink` no shader, quebrando a rigidez mecânica.
2. **Reação Cômica a Choques (Modo Bravo):** Ao colidir contra uma rocha, o robô fecha os olhos em ângulo agressivo em vermelho vivo com ruído elétrico (*glitch*), acompanhado do tremor de câmera, estalo de faíscas e recuo de suspensão.
3. **Sono em Inatividade (Idle):** Quando o jogador larga o joystick por mais de 5.5s, o robô entra em modo dormindo/descanso (`— —`), acordando imediatamente no primeiro toque na tela.
4. **Olhar Direcional (Eye Tracking):** As pupilas deslizam suavemente na direção do vetor do joystick (`look_offset`), criando a percepção de que o robô está focalizando a grama que irá cortar.
5. **Recompensa Eufórica de Vitória:** Ao zerar as metas da fase, o visor transita para Estrelas e Corações (`★ ♥`) com pulso luminoso de sobre-emissão.

---

## 6. Números Flutuantes Cartoon 3D Desacoplados no Mundo 💥🪙

Para proporcionar gratificação imediata estilo *arcade casual* sem poluição visual, o jogo conta com um sistema de números 3D flutuantes cel-shaded gerenciado pelo `FloatingCoinManager` (`scripts/ui/floating_coin_manager.gd`):
1. **Tipografia Arcade, Agrupamento 6:1 na Grama e Contorno de Alto Contraste:**
   - Formato puro sem ícones obstrutivos: `+1`, `+3`, `+5`;
   - Na grama (`grass_*`), cada **6 tufos visuais ceifados** emitem 1 único número `+1` (`GRASS_TUFTS_PER_UNIT = 6`), evitando empilhamento excessivo; trigo e flores emitem 1 número por planta cortada;
   - Contorno preto sólido de 14px (`outline_size = 14`, `outline_modulate = Color(0, 0, 0, 1)`) sobre preenchimento cel-shaded;
   - Cores dinâmicas por espécie: Branco (`#FFFFFF`) para grama comum, Dourado (`#FFE633`) para trigo e Magenta (`#FF4090`) para flores silvestres;
   - Reflete o valor real multiplicado pela oficina (`+2`, `+6`, `+10`).
2. **Emissão Lateral (Somente Esquerda ou Direita) e Desacoplamento no Espaço Global (`top_level`):**
   - Os números são instanciados com `label.set_as_top_level(true)` na coordenada global exata do momento do corte (`cutter.global_position + local_offset`), **permanecendo estacionários no mundo enquanto sobem** (não acompanham o robô quando ele se move);
   - O spawn central foi removido para nunca cobrir o chassi/cabeça do robô: os números surgem exclusivamente nas laterais **Esquerda** ou **Direita** da serra ($R \approx 0.44\text{m} \dots 0.56\text{m}$, $Y = 0.28\text{m}$), escolhidas conforme o lado do corte relativo ao robô.
3. **Coreografia com Efeito POP e Fade-Out Imediato:**
   - **Efeito POP na Aparição:** Surge com escala inicial `0.15x`, expande com overshoot elástico (`TRANS_BACK`, `EASE_OUT`) até `1.65x` em `0.12s` e assenta em `1.0x` nos `0.08s` seguintes (total do POP = `0.20s`);
   - **Subida Vertical no Ponto de Emissão:** Sobe `+1.32m` no eixo $Y$ global ao longo de `0.65s` (`TRANS_CUBIC`, `EASE_OUT`);
   - **Fade-Out Imediato Pós-POP:** Assim que o efeito POP termina (`delay = 0.20s`), inicia imediatamente o fade-out de opacidade (`1.0 -> 0.0` ao longo dos `0.45s` restantes), tornando-se totalmente invisível ao atingir o topo da subida (`0.65s`).
4. **Pool Estático de 32 Nós:**
   - Pré-alocação no `FloatingCoinManager` garantindo 0 coletas de lixo (GC) e 60 FPS cravados no mobile.

