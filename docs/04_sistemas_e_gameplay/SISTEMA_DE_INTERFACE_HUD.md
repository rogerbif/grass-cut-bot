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
   - Cada card possui o emoji da planta e a quantidade pendente:
     - `🌿` Grama Clássica e variantes cosméticas (`grass`)
     - `🌾` Trigo Maduro (`wheat`)
     - `🌸` Flor Silvestre (`flower`)
     - `🌹` Rosa Nobre (`flower_rose`)
     - `🌼` Margarida do Campo (`flower_daisy`)
     - `🌻` Girassol Solar (`flower_sunflower`)
     - `🔔` Flor Sino / Campânula (`flower_bell`)
     - `🏵️` Cravo Corola (`flower_corolla`)
     - `🌷` Tulipa Imperial (`flower_tulip`)
     - `🪻` Canteiro Florido (`flower_bed`)
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

### 2.2 Celebração de Vitória e Interface Desobstruída (`VictoryModal`)
- **Timer de Antecipação (1.0s):** Ao cortar a última planta exigida, o cronômetro para e o jogo concede 1.0s para o jogador acompanhar a finalização.
- **Enquadramento Heroico:** A câmera isométrica aproxima-se frontalmente do Cutter Bit em *glide zoom* (`offset = (0, 2.4, 3.8)`), enquanto o robô rotaciona para olhar de frente para a câmera e comemora com saltos em *squash & stretch*, confetes coloridos e fogos de artifício 3D.
- **Estrelas em Arco e Métricas Flutuantes:** Em vez de uma caixa modal obstrusiva no centro, as 3 estrelas são projetadas em arco parabólico no topo da tela com pop-in sequencial e som `star_pop`, acompanhadas de uma pílula translúcida com `⏱️ Tempo` e `🪙 +Moedas`.
- **Barra de Ações Inferior (Bottom Bar):** Desliza na base da tela mantendo 100% da ilha visível:
  - `Próxima Fase ➔`: Avança dinamicamente para o estágio seguinte (`GameManager.next_level()`). Na Fase 20, o botão se transforma em `"Ciclo Mestre (Fase 1) 👑"` e o título celebra `"🏆 Campeão do Jardim! 🏆"`.
  - `Repetir Fase 🔄`: Permite rejogar o nível atual para farmar moedas adicionais.
  - `Menu Inicial 🏠`: Retorna ao Hub Principal com visualização da ilha desbloqueada no mapa.

### 2.3 Reação Expressiva de Derrota (`GameOverModal`)
- Disparado caso o cronômetro atinja `0:00` antes de bater as cotas.
- O robô assume postura cabisbaixa (inclinação de $10^\circ$, cabeça baixa a $18^\circ$), olhos em `EyeExpression.SAD`, baforadas cartoon de fumaça cinza saindo do motor e desaceleração suave da lâmina por inércia.
- Após delay suave de 0.65s, surge a tela de derrota:
  - `Tentar Novamente 🔄`: Reinicia a fase imediatamente.
  - `Menu Inicial 🏠`: Retorna ao Hub Principal.

---

## 3. Menu Inicial / Hub Principal (`res://scenes/menu/main_menu.tscn`)

Inspirado nos títulos de maior sucesso do mercado mobile casual (*Archero*, *Royal Match*), o Hub Principal é construído em formato vertical portrait ($720 \times 1280$) com iluminação tropical suave e duas perspectivas de câmera integradas:

### 3.1 Câmera Dual e Robô Autônomo (`scripts/menu/menu_camera.gd` & `menu_bot.gd`)
1. **Visão Bot (`BOT_VIEW` - Padrão):**
   - Diorama 3D tropical com o robô cortador rigorosamente assentado com o fundo da mono-wheel na cota exata da linha do solo ($Y = -0.052\text{m}$, tocando a superfície plana em $Y = 0.0$ e imerso na base do gramado sem flutuações).
   - **Culling Total e Performance 60 FPS:** Na visão do bot, **todas as outras 19 ilhas e nuvens finais ficam ocultas (`visible = false`)**, renderizando exclusivamente a ilha atual onde o robô se encontra. Isso elimina 95% das draw calls e nós de cena.
   - **Animação Seletiva de Vento:** O shader espacial de vento interativo roda **exclusivamente na ilha atual na visão do bot**.
   - **Locomoção Autônoma:** O robô avança suavemente meio metro (+0.50m) com rotação física da roda e inclinação inercial frontal (`pitch`), faz curvas suaves exploratórias ($\pm 22^\circ$) e recua de marcha à ré para a base.
   - **Cabeça Expressiva e Olhos de LED:** Articulação autônoma da cabeça (olhar para os lados, cima e baixo), piscar orgânico e alternância randômica de humores (`NORMAL`, `HAPPY`, `ALERT`, `WINK`, `VICTORY`).
2. **Visão Mapa (`MAP_VIEW` - Overworld do Arquipélago):**
   - Transição suave via botão `[ 🗺️ MAP ]` para uma câmera aérea elevada com ângulo de pitch de $58^\circ$.
   - **Janela Deslizante de 3 Ilhas e Lazy Loading Inteligente:**
     - **Carregamento Inicial sob Demanda:** No boot do menu, são construídas apenas a ilha selecionada e suas vizinhas imediatas ($[foco - 1, foco, foco + 1]$). As demais ilhas têm apenas seus metadados de dimensões lidos instantaneamente sem instanciar nós 3D, garantindo boot ultra-rápido sem travamentos.
     - **Persistência em Memória (Sem Recarregar):** Uma vez que uma ilha é carregada via `ensure_content_loaded()`, ela **permanece viva em memória (`is_built = true`)** e nunca é destruída nem recarregada. Ao sair do campo de visão, ela é apenas ocultada (`visible = false`), eliminando qualquer engasgo ou latência ao rolar de volta.
     - **Culling Reativo:** Mostra **somente a ilha atual focada, a próxima e a anterior** ($[foco - 1, foco, foco + 1]$). Todas as outras ilhas distantes permanecem ocultas (`visible = false`).
   - **Abordagem Híbrida: Superfícies Vetoriais no Mapa e Grama 3D na Home:**
     - **Na Visão Mapa (`MAP_VIEW`):** Todas as ilhas usam exclusivamente superfícies planas vetoriais trianguladas diretamente das formas 2D (`VectorGrassField.generate_ground_meshes()`) a $Y = 0.005\text{m}$, com materiais foscos (`roughness = 0.90`) e sombras desativadas. A contagem de triângulos cai em mais de **99.8%** (de $\sim 90.000$ para $< 150$ tris por ilha) e o tempo de geração na CPU cai de $30\text{ms}$ para $< 0.4\text{ms}$, eliminando completamente qualquer travamento ou engasgo no swipe touch.
     - **Rochas em MultiMesh Único:** Todas as rochas da miniatura são consolidadas em 1 único `MultiMeshInstance3D` com sombras desligadas, reduzindo as draw calls a 1 por ilha.
     - **Culling Físico:** Ilhas fora da janela visível têm seus nós `Area3D` e `CollisionShape3D` desativados e `process_mode = PROCESS_MODE_DISABLED`, poupando ciclos de CPU no servidor de física.
     - **Na Visão Bot (`BOT_VIEW`):** A ilha ativa onde o robô está estacionado em close-up instancia e ativa a vegetação volumétrica 3D detalhada com balanço de vento procedural (`Veg3DContainer`), garantindo a máxima imersão visual no menu principal.
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

### 3.2 Teleporte do Cutter Bot no Mapa de Fases (Spatial Shader 3D)
Ao navegar entre as ilhas na Visão de Mapa (`MAP_VIEW`), o Cutter Bot executa uma rotina de teleporte com desintegração e materialização física orientada por shader espacial (`shaders/teleport_effect.gdshader`):
- **Gatilho Reativo:** Disparado quando a câmera se encaixa magneticamente em outra ilha após arraste/flick (`_on_camera_island_snapped`) ou no toque direto em qualquer ilha do arquipélago (`_on_island_clicked`).
- **Desaparecendo de Cima para Baixo ($0.54\text{s}$):** Um feixe de energia turquesa neon (`vec4(0.0, 1.02, 1.2, 1.0)`) com ruído de gradiente procedural varre o robô da antena à base, descartando os fragmentos com o SFX `fast_forward` suavizado a 25% de volume (`linear_to_db(0.25)`).
- **Aparecendo de Baixo para Cima ($0.60\text{s}$):** Na nova ilha, o robô materializa-se da base até a antena suavemente, restaurando os materiais normais e a tela de LED dos olhos (`_setup_eyes()`) ao término.
- **Sincronização de Foco:** Atualiza continuamente `menu_camera.set_bot_target()`, garantindo transição suave ao retornar para a Visão do Bot (`BOT_VIEW`).

### 3.3 Top Bar e Barra de Navegação Inferior (`BottomNavBar`)
- **Top Bar do Hub:** Exibe moedas, energia e o título da fase atual ("Ilha Tropical") com alinhamento à direita (`alignment = 2`, `horizontal_alignment = 2`), encostado elegantemente junto ao botão de configurações `[⚙️]`.
### 3.3 Enquadramento Bot View (`BOT_VIEW`) e Desobstrução Frontal Automática

Na aba `Home`, ao alternar a câmera para a visão aproximada do cortador (`BOT_VIEW`):
- **Câmera Isométrica Próxima:** A câmera desce e se aproxima do robô (`target_bot_pos + Vector3(0, 1.25, 4.0)` com pitch de $-8^\circ$), focando a lâmina, rodas e expressividade do bot.
- **Desobstrução Automática do Setor Frontal:** Para garantir que espigas de trigo volumosas, flores altas, tufos de grama densos ou rochas não fiquem na frente do robô nem cubram sua lâmina, olhos e botões da interface, o `IslandNode` aplica um filtro cônico/frontal estrito:
  - Qualquer elemento posicionado com $z > \text{bot.z} - 0.30\text{m}$ e $|x - \text{bot.x}| < 3.20\text{m}$ é desativado no `BOT_VIEW`.
  - Tufos de grama, flores e espigas de trigo são excluídos da geração da malha 3D (`veg_transforms_by_type`), mantendo apenas a vegetação ao redor e atrás do robô para profundidade de cena limpa.
  - Rochas na miniatura (`MiniRocksMMI`) situadas no setor frontal têm suas instâncias escaladas para zero e reposicionadas fora de cena via `_set_rocks_in_front_hidden(true)`.
  - Ao alternar para o modo mapa (`MAP_VIEW`), todos os elementos e rochas da ilha retornam normalmente ao estado original.

### 3.4 Barra de Navegação de 4 Abas (`BottomNavBar`)
  - Altura expandida para $104\text{px}$ com cantos arredondados ($r=22\text{px}$) e fundo translúcido escuro.
  - **Ícones Grandes em Destaque:** Emojis ampliados com `font_size = 28` centralizados em nós dedicados `IconLabel`.
  - **Legendas Rebaixadas:** Textos com `font_size = 13` rebaixados com espaçamento vertical confortável (`separation = 4`).
  - **Abas:**
    - `Garage` 🔧: Acesso direto à Oficina de Upgrades do `UpgradeManager` (Evolução Unificada da Lâmina até o Nível 5 com Moedas).
    - `Home` 🏠: Tela principal com o botão arcade/cyber heroico `"JOGAR - Fase X ▶"` (`CyberPlayButton`), alternância de câmera (`MAP` / `BOT`) e visão isométrica da ilha tropical.

### 3.5 Botões Heroicos da Home: Banners Arcade/Cyber (`CyberPlayButton` & `CyberToggleButton`)
- **Estética Visual Exclusiva:** Inspirado nos botões heroicos de jogos mobile arcade/cyberpunk, a barra de ações inferior combina dois botões estilizados que compartilham a mesma identidade visual e física:
  - **Botão Jogar (`CyberPlayButton`):**
    - **Corte Angular à Esquerda:** Chanfro inclinado a $\sim 62^\circ$ com cantos arredondados suaves.
    - **Ponta Chevron à Direita:** Formato de flecha/seta indicativa com vértice arredondado apontando para a direita.
    - **Gradiente Verde-Lima / Chartreuse:** Superfície superior vibrante com gradiente elétrico (`#f8ff0a` ➔ `#b6fa00`), reflexo especular vítreo superior em arco translúcido e contorno em verde floresta (`#70b000`).
    - **Base 3D Extrudada com Compressão Tátil:** Chanfro inferior espesso em verde-escuro folha (`#38b620` ➔ `#187212`) com flare estelar dourado no centro inferior.
    - **Molduras Cyber Tech Flutuantes:** Suporte angular no canto inferior esquerdo com linha de contorno ciano/lima neon (`#00f5a8`), e suporte angular superior-direito com aba e contorno em chevron no mesmo tom luminoso.
    - **Tipografia e Ícone de Alto Contraste:** Rótulo em negrito pesado (`font_weight = 900`, azul-marinho profundo `#071826`) `"JOGAR - Fase %d"` acompanhado de triângulo de play sólido `▶` de $24\text{px}$.
  - **Botão Alternar Visualização / Mapa (`CyberToggleButton`):**
    - **Design Compacto e Estreito:** Dimensões calibradas (`Vector2(254, 135)`) em proporção harmônica ao lado do botão de Jogar (`Vector2(415, 135)`).
    - **Gradiente Azul Ciano Elétrico:** Superfície superior em ciano vibrante (`#02f0ff` ➔ `#007afc`), reflexo superior vítreo e base 3D em azul cobalto profundo (`#0e78fe` ➔ `#0242a6`).
    - **Molduras Cyber Tech Estáticas:** Bracket inferior esquerdo idêntico com linha neon e suporte angular superior direito estático, permanecendo imóveis durante a interação para acentuar a profundidade.
    - **Ícone e Tipografia Canônicos:** Texto `"MAPA"` em branco puro (`#ffffff`) com sombra suave, acompanhado de ícone vetorial de mapa dobrado 3D com marcador de localização vazado (`icon_map_banner.svg`).
- **Mecânica Tátil 3D e Game Feel:**
  - **Compressão Mecânica:** Ao pressionar (`button_down`), a textura alterna instantaneamente para a versão comprimida (`btn_play_banner_pressed.svg` / `btn_map_banner_pressed.svg`) e o texto/ícone desloca-se $7\text{px}$ para baixo, simulando um botão físico de arcade sendo empurrado.
  - **Feedback Háptico e Áudio:** Dispara vibração tátil de $15\text{ms}$ (`Input.vibrate_handheld(15)`) e o SFX de confirmação (`AudioManager.play_sfx("confirm")`).
  - **Escala Elástica:** Ao clicar, aplica um tween de pulso sutil ($0.96 \times \rightarrow 1.0 \times$).
    - `Collection` 🌿: Herbário ilustrado com as espécies da ilha (Grama Verde, Amarela, Azul, Roxa, Trigo e Flores Nobres).
    - `Store` 🏪: Loja de pacotes de moedas e resgate de recompensas diárias.

### 3.4 Modal de Configurações (`SettingsModal`)
- Cobre ~85% da tela com fundo translúcido escuro.
- Toggles independentes: Música, Som FX e Vibração Háptica.
- Seção *Save Progress* e suporte ao jogador.

---

## 4. Barra Flutuante 3D de Evolução da Lâmina (`BladeProgressBar3D`)

Instanciada dinamicamente no topo do cortador (`scenes/cutter/blade_progress_bar.tscn`), a barra flutua sobre a cabeça do robô fornecendo telemetria em tempo real da evolução da serra:

- **Renderização e Projeção:** Desenvolvida em `SubViewport` (140x24 pixels) renderizado em um `Sprite3D` unshaded com `billboard = BILLBOARD_ENABLED` e sem culling de sombras, garantindo 60 FPS estáveis no mobile.
- **Tipografia Interna:** Texto `Lv. 1` a `Lv. 5` ou `MAX` centralizado **dentro da própria barra**, com fonte branca e contorno preto fino (`outline_size = 2`), garantindo legibilidade perfeita tanto sobre o fundo escuro quanto sobre o preenchimento verde-lima/dourado.
- **Reações Visuais e Game Feel:**
  - **Level Up:** Pulso elástico na escala da barra (`1.0` ➔ `1.35` ➔ `1.0`).
  - **Impacto em Rocha (Penalidade):** Piscar vermelho vivo (`#ff4747`) e *shake* horizontal rápido sincronizado ao recuo físico do bot.
  - **Nível 6 ("MAX"):** Barra 100% preenchida com gradiente dourado radiante e o texto "MAX" em destaque.

