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
   - Diorama 3D tropical com o robô cortador assentado com a mono-wheel no solo da ilha (sem flutuação artificial).
   - **Locomoção Autônoma:** O robô avança suavemente meio metro (+0.50m) com rotação física da roda e inclinação inercial frontal (`pitch`), faz curvas suaves exploratórias ($\pm 22^\circ$) e recua de marcha à ré para a base.
   - **Cabeça Expressiva e Olhos de LED:** Articulação autônoma da cabeça (olhar para os lados, cima e baixo), piscar orgânico e alternância randômica de humores (`NORMAL`, `HAPPY`, `ALERT`, `WINK`, `VICTORY`).
2. **Visão Mapa (`MAP_VIEW` - Overworld do Arquipélago):**
   - Transição suave via botão `[ 🗺️ MAP ]` para uma câmera aérea elevada com ângulo de pitch de $58^\circ$.
   - **Miniaturas Fiéis das Fases:** O arquipélago 3D gera miniaturas geométricas reais para cada uma das 20 fases canônicas lendo os arquivos JSON (`data/levels/level_XX.json`) e instanciando os tiles 3D reais (`tile_island_center`, `edge`, `corner_out`, `corner_in`, etc.) a uma escala reduzida de $0.38\times$, preservando o formato e contorno idênticos aos estágios jogáveis.
   - **Placas de Fase Adaptativas:**
     - **Na Visão Mapa:** A placa repousa plana sobre o chão da ilha, com inclinação de $-58^\circ$ (perpendicular à linha de visão da câmera aérea), tornando o número do nível e a contagem de estrelas (⭐) perfeitamente legíveis do alto sem ocultar os tiles.
     - **Na Visão Bot:** A placa ergue-se em pé fincada no solo através de sua estaca de madeira, posicionada à frente e à esquerda do robô (`x = -1.15m`, `z = 0.85m`, rotação $15^\circ$), integrando-se naturalmente ao cenário.
   - **Rolagem Touch/Mouse Calibrada 1:1 & Gesto de Swipe:**
     - A taxa de deslocamento é calculada diretamente pela interseção geométrica do raio da câmera com o plano do solo ($Y=0$), garantindo que a ilha sob o dedo se mova exatamente na mesma velocidade do toque, sem acelerações ou descompassos.
     - Suporte a gesto de swipe/flick vertical rápido para avançar ou retornar fases com facilidade, além de snap magnético suave para a ilha mais próxima ao soltar o dedo lentamente.
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
