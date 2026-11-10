# Melhoria 221: Nova Tela de Derrota Flutuante, Quebra no Nível 1 e Sistema de 5 Vidas (`v0.12.173-alpha`)

## 1. Contexto e Objetivo
Reformulação completa da Tela de Derrota (`DefeatModal`) para operar em formato **Cyber-Mecha Flutuante** sobre a cena 3D (com câmera em close-up focada no robô entristecido soltando fumaça e chorando no visor de LED), introdução das duas causas de derrota (**Tempo Esgotado** e **Robô Quebrado** ao bater em uma pedra estando no Nível 1) e implementação do **Sistema de 5 Vidas** com recarga automática de 20 minutos por vida e compra na Loja por 1.000 moedas.

## 2. Entregas Técnicas Realizadas
1. **Quebra no Nível 1 com "Última Chance" (`UpgradeManager` & `Cutter`):**
   - Colisões contra pedras no Nível 2 ou superior descontam `1.000 XP` mas travam no Nível 1 com `0 XP` sem quebrar na mesma batida ("última chance").
   - Colisões contra pedras quando o robô **já está no Nível 1** quebram o robô (`penalize_blade_hit()` retorna `true`), acionando `GameManager.trigger_robot_broken()` (`reason = "robot_broken"`).
2. **Enquadramento Close-Up 3D, Olhos Chorando e Fumaça Escura (`IsometricCamera`, `Cutter`, `eyes_atlas.svg`):**
   - `IsometricCamera` transiciona suavemente para o enquadramento frontal próximo ao receber `level_lost`.
   - `BladeProgressBar3D` é ocultada durante a derrota, mantendo a cena limpa.
   - `eyes_atlas.svg` atualizado no frame `2: SAD` com arcos tristes e gotas de lágrima nas extremidades externas.
   - `DefeatPuffParticles` calibrado com fumaça cinza-carvão contínua e fagulha âmbar na base.
3. **Nova UI Flutuante de Derrota (`DefeatModal` & `HUD`):**
   - **3 Placas Superiores (`TopCluster`):**
     - `banner_defeat_title.svg`: alterna entre `TEMPO ESGOTADO!` (`icon_stopwatch_red.svg`) e `ROBÔ QUEBRADO!` (`icon_robot_broken_red.svg`).
     - `banner_defeat_progress.svg`: exibe `« PROGRESSO DO CORTE: XX% »` e barra arredondada rosa com pontos digitais.
     - `banner_defeat_goals.svg`: exibe todas as metas da fase com ícone botânico e contagem `atual / total` (`54 / 60`).
   - **Barra Inferior Simétrica (`BottomBar`):**
     - Linha superior: `MENU` e `PEGAR MAIS TEMPO` (+15s) / `CONSERTAR ROBÔ` (1 uso por tentativa, devolvendo a vida da tentativa).
     - Linha inferior: botão heroico verde `REINICIAR ↻` (`icon_refresh_dark.svg`).
4. **Sistema de 5 Vidas, Recarga de 20 Minutos e Compra na Loja (`SaveManager`, `MainMenu`, `TabStore`):**
   - Cada derrota consome 1 vida (`MAX_LIVES = 5`).
   - Recarga automática de `+1 vida` a cada **20 minutos** (`LIFE_REGEN_SECONDS = 1200`) calculada por timestamp Unix persistente.
   - `LifeBadge` na TopBar da Home exibe `"5 Max"` ou `"%d/5"`, redirecionando para a Loja ao tentar jogar com `0/5`.
   - Card **Recarga de Vidas (+5 Vidas)** na Loja (`TabStore`) com cronômetro em tempo real e compra por **1.000 moedas**.

## 3. Verificação e Testes
- Validado com 0 warnings e 0 erros via CLI (`verify_defeat_and_lives.gd` -> `ALL_TESTS_PASSED_OK`) e capturas visuais em Vulkan Forward Mobile.
