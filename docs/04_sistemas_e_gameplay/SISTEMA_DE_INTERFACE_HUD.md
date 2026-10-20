# Sistema de Interface, HUD e Menus 📊📱

Este documento especifica a interface de usuário (HUD), os componentes visuais de status, o fluxo de telas modais e o **Menu Inicial (Hub Principal)** em **Grass Cut Bot**.

---

## 1. Top HUD Durante a Partida

O Top HUD é posicionado na parte superior da tela e utiliza estilo *flat matte* com cantos arredondados:

```
TopBar (PanelContainer)
├── TimerContainer (PanelContainer) -> TimerLabel ("1:30")
├── CoinsContainer (PanelContainer) -> Ícone Moeda + CoinsLabel ("0")
├── GoalsContainer (HBoxContainer)  -> Cards Dinâmicos de Metas (🌿 60, 🌾 15, 🌸 8)
└── PauseButton (Button)            -> Ícone "⏸"
```

### Componentes em Destaque:
1. **Cronômetro Regressivo:**
   - Exibe o tempo restante no formato Minutos e Segundos (`M:SS`).
   - Alerta Crítico: Quando o tempo restante é menor ou igual a 15 segundos, o texto muda dinamicamente para vermelho vivo (`Color(1.0, 0.3, 0.3)`), sinalizando urgência.
2. **Cards Dinâmicos de Metas:**
   - Criados sob demanda pelo `HUD` conforme as espécies exigidas no nível atual.
   - Cada card possui o emoji da planta e a quantidade pendente.
   - **Efeito Visual de Pop:** A cada tufo ceifado, o card correspondente sofre uma rápida animação de escala (`1.15x` -> `1.0x` em 0.1s).
   - **Meta Batida:** Ao zerar o contador, o número é substituído por um check verde (`✔`) e o fundo do card ganha tonalidade verde esmeralda.
3. **Contador de Moedas:**
   - Reflete o total de moedas acumuladas pelo jogador na sessão, atualizado em tempo real via sinal `UpgradeManager.coins_changed`.

---

## 2. Modais e Telas de Fim de Partida

Todos os modais rodam com `process_mode = PROCESS_MODE_ALWAYS` para continuar respondendo a toques mesmo quando a árvore do jogo está pausada (`get_tree().paused = true`).

### 2.1 Modal de Pausa (`PauseModal`)
- Acionado pelo botão de pausa no Top HUD.
- Congela física e cronômetro.
- **Ações:**
  - `Continuar ▶`: Despausa o jogo e fecha o modal.
  - `Reiniciar Fase 🔄`: Recarrega o estágio restaurando a contagem de tempo e metas.
  - `Oficina ⚙`: Abre a oficina para compra de melhorias imediatas.
  - `Menu Inicial 🏠`: Retorna ao Hub Principal preservando as moedas obtidas.

### 2.2 Modal de Vitória (`VictoryModal`)
- Disparado automaticamente quando todas as metas chegam a zero antes do tempo expirar.
- Desativa imediatamente a rotação, corte e movimentação da lâmina, além de ocultar e desativar o joystick virtual.
- Exibe o bônus de moedas obtidas na fase.
- **Ações:**
  - `Próxima Fase ➔`: Avança dinamicamente para o estágio seguinte (`GameManager.next_level()`). Na Fase 20, o botão se transforma em `"Ciclo Mestre (Fase 1) 👑"` e o título celebra `"🏆 Campeão do Jardim! 🏆"`.
  - `Repetir Fase 🔄`: Permite rejogar o nível atual para farmar moedas adicionais.
  - `Menu Inicial 🏠`: Retorna ao Hub Principal com visualização da ilha desbloqueada no mapa.

### 2.3 Modal de Derrota (`GameOverModal`)
- Disparado caso o cronômetro atinja `0:00` antes de bater as cotas.
- Desativa imediatamente a rotação, corte e movimentação da lâmina e oculta o joystick virtual.
- Exibe mensagem explicativa de falha ("Tempo Esgotado!").
- **Ações:**
  - `Tentar Novamente 🔄`: Reinicia a fase imediatamente.
  - `Menu Inicial 🏠`: Retorna ao Hub Principal.

---

## 3. Menu Inicial / Hub Principal (`res://scenes/menu/main_menu.tscn`)

Inspirado nos títulos de maior sucesso do mercado mobile casual (*Archero*, *Royal Match*), o Hub Principal é construído em formato vertical portrait ($720 \times 1280$) com iluminação tropical suave e duas perspectivas de câmera integradas:

### 3.1 Câmera Dual e Robô Autônomo (`scripts/menu/menu_camera.gd` & `menu_bot.gd`)
1. **Visão Bot (`BOT_VIEW` - Padrão):**
   - Diorama 3D tropical com o robô cortador rigorosamente assentado com o fundo da mono-wheel na cota exata da linha do solo ($Y = -0.059\text{m}$, tocando a superfície plana em $Y = 0.0$ e imerso na base do gramado sem flutuações).
   - **Locomoção Autônoma:** O robô avança suavemente meio metro (+0.50m) com rotação física da roda e inclinação inercial frontal (`pitch`), faz curvas suaves exploratórias ($\pm 22^\circ$) e recua de marcha à ré para a base.
   - **Cabeça Expressiva e Olhos de LED:** Articulação autônoma da cabeça (olhar para os lados, cima e baixo), piscar orgânico e alternância randômica de humores (`NORMAL`, `HAPPY`, `ALERT`, `WINK`, `VICTORY`).
2. **Visão Mapa (`MAP_VIEW` - Overworld do Arquipélago):**
   - Transição suave via botão `[ 🗺️ MAP ]` para uma câmera aérea elevada com ângulo de pitch de $58^\circ$.
   - **Ilhas em Escala Real (1:1), Grama Oficial com Shaders & Animação Seletiva de Vento:**
     - O arquipélago 3D gera as 20 fases canônicas em **escala física real ($1.0\times$)** idêntica à do gameplay, preservando as dimensões exatas de cada ilha e o robô cortador em escala $0.62\times$ (idêntico ao `Cutter`), eliminando qualquer discrepância visual ou desproporção.
     - **Visual 100% Equalizado com o Gameplay:** Todos os tufos de grama utilizam os shaders espaciais oficiais (`interactive_grass_*.tres`), com gradiente vertical contínuo da raiz ao topo (base escura e topo vibrante) e entrelaçamento orgânico de folhas (rotação randômica e escala horizontal $0.96 \sim 1.10\times$ e vertical $0.72 \sim 0.85\times$), criando o mesmo tapete contínuo e denso do jogo.
     - **Animação de Vento Seletiva (Economia Mobile):** O balanço suave de vento das folhas é ativado **exclusivamente na ilha onde o robô estiver** na visão do bot (`BOT_VIEW`). Todas as demais 19 ilhas no fundo (e todas as ilhas na visão de mapa aéreo) utilizam materiais estáticos com vento pausado (`wind_strength = 0.0`), poupando ciclos de GPU e garantindo 60 FPS inabaláveis.
   - **Placas de Fase Adaptativas:**
     - **Na Visão Mapa:** A placa repousa plana no canto inferior direito de cada ilha sobre a grama ($+X$, $+Z$, cota $Y=0.25\text{m}$), com inclinação de $-58^\circ$ (perpendicular à linha de visão da câmera aérea), desobstruindo totalmente o centro do mapa e tornando o número do nível e as estrelas (⭐) límpidos e elegantes.
     - **Na Visão Bot:** A placa permanece oculta (`visible = false`) para manter o enquadramento limpo e o foco estético 100% direcionado ao robô cortador no diorama da Home.
   - **Rolagem Touch/Mouse Calibrada 1:1, Centralização Automática em X e Enquadramento Adaptativo:**
     - **Enquadramento Dinâmico por Ilha:** A câmera calcula em tempo real a altura de visualização ideal ($Y = 25\text{m} \sim 36\text{m}$) e o offset de mira em $Z$ ($\Delta Z = Y / \tan(58^\circ)$) com base na extensão real ($W \times H$) de cada fase em foco. Fases compactas recebem um enquadramento mais próximo e acolhedor, enquanto fases maiores e o arquipélago terminal de nuvens recebem altitude expandida com margens de oceano confortáveis na tela portrait (9:16).
     - **Centralização Automática em X na Reta:** A câmera interpola continuamente sua coordenada horizontal ($X$) através dos waypoints de cada ilha ao longo do ziguezague tropical via curva cúbica Hermite (`smoothstep`), de modo que cada fase que entra na mira/reta do scroll fique perfeitamente centralizada no meio da tela portrait.
     - O deslocamento acompanha o sentido natural: arrastar para baixo faz o mapa descer acompanhando o dedo; arrastar para cima faz o mapa subir.
     - Roda do mouse no sentido visual natural: rolagem para baixo avança para a próxima fase; rolagem para cima recua para a fase anterior.
     - A taxa de deslocamento é calculada diretamente pela interseção geométrica do raio da câmera com o plano do solo ($Y=0$), garantindo que a ilha sob o dedo se mova exatamente na mesma velocidade do toque, sem acelerações ou descompassos.
     - Suporte a gesto de swipe/flick vertical na direção do movimento (swap para baixo avança para a próxima fase; swap para cima volta para a anterior), com snap magnético suave para a ilha mais próxima na soltura lenta.
   - Revela as 20 fases com estrelas (concluídas), robô posicionado sobre a fase atual e ilha final de nuvens com a placa *"Em breve mais fases..."*.

### 3.2 Top Bar e Barra de Navegação Inferior (`BottomNavBar`)
- **Top Bar do Hub:** Exibe moedas, energia e o título da fase atual ("Ilha Tropical") com alinhamento à direita (`alignment = 2`, `horizontal_alignment = 2`), encostado elegantemente junto ao botão de configurações `[⚙️]`.
- **Barra de Navegação de 4 Abas (`BottomNavBar`):**
  - Altura expandida para $104\text{px}$ com cantos arredondados ($r=22\text{px}$) e fundo translúcido escuro.
  - **Ícones Grandes em Destaque:** Emojis ampliados com `font_size = 28` centralizados em nós dedicados `IconLabel`.
  - **Legendas Rebaixadas:** Textos com `font_size = 13` rebaixados com espaçamento vertical confortável (`separation = 4`).
  - **Abas:**
    - `Garage` 🔧: Acesso direto à Oficina de Upgrades do `UpgradeManager` (Raio, Potência, Velocidade e Multiplicador).
    - `Home` 🏠: Tela principal com botão em destaque `"Level X ▶"` e alternância de Câmera (`MAP` / `BOT`).
    - `Collection` 🌿: Herbário ilustrado com as espécies da ilha (Grama Verde, Amarela, Azul, Roxa, Trigo e Flores Nobres).
    - `Store` 🏪: Loja de pacotes de moedas e resgate de recompensas diárias.

### 3.3 Modal de Configurações (`SettingsModal`)
- Cobre ~85% da tela com fundo translúcido escuro.
- Toggles independentes: Música, Som FX e Vibração Háptica.
- Seção *Save Progress* e suporte ao jogador.
