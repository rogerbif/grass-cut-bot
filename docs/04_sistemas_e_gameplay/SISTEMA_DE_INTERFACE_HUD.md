# Sistema de Interface, HUD e Menus 📊📱

Este documento especifica a interface de usuário (HUD), os componentes visuais de status, o fluxo de telas modais e o **Menu Inicial (Hub Principal)** em **Grass Cut Bot**.

---

## 1. Top HUD Durante a Partida

O Top HUD de gameplay utiliza estilo **Cyber-Mecha chanfrado a 45° sem overlay de fundo**, mantendo o mar e a ilha 100% visíveis no topo da tela e respeitando a zona segura mobile (`offset_top = 34`):

```
TopBar (Control - sem fundo opaco)
├── TopHBox (HBoxContainer, offset_top = 34)
│   ├── LeftCluster (VBoxContainer, separation = 10)
│   │   ├── TopStatsRow (HBoxContainer, separation = 10)
│   │   │   ├── TimerContainer (TextureRect: badge_coin_bg.svg) -> Ícone Relógio + TimerLabel ("1:30")
│   │   │   └── CoinsContainer (TextureRect: badge_coin_bg.svg) -> Ícone Moeda + CoinsLabel ("0")
│   │   └── GoalsContainer (HBoxContainer, separation = 10) -> Cards Chanfrados de Metas (badge_goal_card.svg)
│   ├── Spacer (Control, expand_fill)
│   └── PauseButton (TextureButton: btn_pause_cyber.svg / btn_pause_cyber_pressed.svg)
```

### Componentes em Destaque:
1. **Cronômetro Regressivo (`TimerContainer`) e Contador de Moedas (`CoinsContainer`):**
   - Utilizam a mesma plaqueta chanfrada cyber (`badge_coin_bg.svg`, `105x42` px) da TopBar da Home, alinhados lado a lado com espaçamento simétrico de `10px`.
   - Quando o tempo restante é menor ou igual a 10 segundos, o texto muda dinamicamente para vermelho vivo (`Color(1.0, 0.3, 0.3)`) e ativa o áudio regressivo de urgência (`AudioManager.play_countdown_alert()`), que é interrompido imediatamente em caso de vitória ou derrota.
   - O contador de moedas reflete o total acumulado na sessão via sinal `UpgradeManager.coins_changed`.
2. **Cards Dinâmicos de Metas (`GoalsContainer`):**
   - Posicionados logo abaixo de Tempo e Moedas (`LeftCluster`) com espaçamento simétrico de `10px` vertical e horizontal.
   - Utilizam moldura chanfrada cyber (`assets/ui/topbar/badge_goal_card.svg`, `54x62` px) e `badge_goal_card_done.svg` quando concluídos, compartilhando a mesma identidade visual (fundo `#060d18` e borda `#00d2ff` chanfrada a 45°) dos badges superiores.
   - Cada card exibe o ícone vetorial SVG da espécie (`assets/icons/icon_*.svg`) e a quantidade pendente (com agrupamento de **6 tufos visuais = 1 unidade de meta** para gramas, e 1:1 para trigo e flores).
   - **Efeito Visual de Pop:** A cada unidade contabilizada, o card correspondente sofre uma rápida animação de escala (`1.15x` -> `1.0x` em 0.1s).
   - **Meta Batida:** Ao zerar o contador, o texto muda para `"OK"` em verde luminoso (`Color(0.22, 1.0, 0.48)`) e a moldura alterna permanentemente para `badge_goal_done_bg.svg`. O estado de sucesso é imutável e retido contra sobrescritas por eventuais cortes excedentes da mesma espécie até a celebração final.
3. **Botão de Pausa (`PauseButton`):**
   - `TextureButton` estilizado como chip chanfrado (`btn_pause_cyber.svg` / `btn_pause_cyber_pressed.svg`, `54x48` px) no canto superior direito.

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

### 2.2 Celebração de Vitória e Interface Flutuante Cyber (`VictoryModal`)
- **Persistência Atômica Imediata:** No exato instante em que a vitória da fase é disparada, `GameManager` grava sincronamente a conquista, moedas, estrelas e desbloqueia a próxima fase via `SaveManager.record_level_victory()`, garantindo que o progresso nunca seja perdido mesmo se o jogador voltar ao Menu imediatamente.
- **Ocultação de HUD de Jogo:** A `TopBar` e a `BladeProgressBar3D` são ocultadas automaticamente ao iniciar a celebração.
- **Enquadramento Heroico:** A câmera isométrica aproxima-se frontalmente do Cutter Bit em *glide zoom*, enquanto o robô olha de frente para a câmera com olhos de estrela/coração (`★ ♥`) e comemora com saltos em *squash & stretch*, confetes coloridos e fogos de artifício 3D.
- **Cabeçalho Flutuante Sem Card Opaco (`TopBanner`):** Posicionado na faixa superior (`offset_top = 132`, `offset_bottom = 412`), sem qualquer painel de fundo que obstrua o cenário:
  - Título `"FASE XX CONCLUÍDA!"` com ícone vetorial de troféu neon ciano (`icon_trophy.svg`) e divisor luminoso (`header_cyber_divider.svg`).
  - Placa holográfica chanfrada (`stars_cyber_backplate.svg`, `390x92` px) com 3 estrelas douradas 3D (`star_3d_gold.svg`) animadas em arco com pop-in sequencial (`star_pop`).
  - Cápsulas largas chanfradas (`badge_stat_pill.svg` e `badge_stat_pill_right.svg`, `288x68` px cada) com abas superiores listradas, exibindo `⏱️ Tempo` (`icon_stopwatch_cyber.svg`) e `+ XXX MOEDAS`.
- **Barra de Ações Inferior Simétrica (`BottomBar`):** Desliza na base da tela (`560px` de largura centralizada, espaçamento vertical e horizontal unificado de `24px`):
  - Linha superior (`SecondaryRow`, `separation = 24`): botões `MENU` (`btn_menu_secondary.svg`, `268x66` px, azul-marinho com borda ciano) e `REPETIR` (`btn_repeat_secondary.svg`, `268x66` px, azul-violeta com borda roxa), alinhados exatamente com a largura total do botão inferior (`268 + 24 + 268 = 560px`).
  - Linha inferior: botão heroico verde-esmeralda neon `PRÓXIMA FASE ▶` (`btn_next_level.svg`, `560x96` px) com colchetes tecnológicos externos e texto em azul-petróleo escuro.

### 2.3 Modal de Derrota Cyberpunk Neon (`DefeatModal`)
- Componente modular `scenes/ui/defeat_modal.tscn` + `scripts/ui/defeat_modal.gd` (`process_mode = ALWAYS`, UI construída programaticamente, SVGs em `assets/ui/defeat/`), instanciado no `hud.tscn` e aberto por `HUD._on_level_lost()` após o delay de 0.65s (o robô mantém a reação expressiva de derrota: postura cabisbaixa, olhos `SAD`, fumaça e inércia da lâmina).
- Card chanfrado com borda vermelha/roxa neon, pulso sutil de brilho e animação **Grow + Fade In / Shrink + Fade Out**. O toque no backdrop **não fecha** (derrota exige decisão).
- Conteúdo dinâmico: título `Tempo Esgotado!` com cronômetro vermelho e alerta; subtítulo `Faltou pouco para concluir a fase!` (progresso ≥ 70%) ou `Continue tentando, você consegue!`; painel **Progresso do Corte** (% via `GameManager.get_progress_ratio()`, barra gradiente rosa→amarelo) e metas restantes com ícones da Coleção (`GameManager.get_remaining_goals()` + `GoalIconFactory`).
- Ações: `Repetir Fase` (reinicia), `Pegar Mais Tempo` (placeholder de anúncio recompensado: `GameManager.grant_extra_time(15.0)` retoma a fase com +15s, **1 uso por tentativa** via `can_grant_extra_time()`; oculto após usado) e `Menu Inicial`.
- Háptico curto (`Input.vibrate_handheld(40)`) ao abrir, respeitando `vib_enabled`.

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

### 3.4 Barra de Navegação de 4 Abas (`BottomNavBar`) e Painéis Cyber com Cantos Retos Chanfrados
  - **Encaixe Rentíssimo à Base (Sem Fresta Inferior):** O `BottomNavBar` (`scenes/menu/bottom_nav_bar.tscn`) e seu chassi vetorial (`assets/ui/navbar/nav_bar_chassis.svg`) estendem-se até a coordenada exata da borda inferior da viewport (`y = 92` no SVG e `offset_bottom = 2.0`), eliminando qualquer fresta de luz ou cenário na base da tela.
  - **Painéis Principais e Sub-elementos com Cantos Retos (45°):** Todas as abas (`TabCollection`, `TabGarage` e `TabStore`) utilizam molduras nine-patch com chanfros retos de 45° (`panel_cyber_main.svg`), chips de estatísticas chanfrados (`chip_stat_cyber.svg`), molduras de avatares (`icon_frame_cyber.svg` / `icon_frame_cyber_locked.svg`) e botões chanfrados (`badge_milestone_cyber.svg`, `btn_claim_cyber.svg`), erradicando bordas arredondadas (`corner_radius = 0`) em prol de uma estética cyber-mecha coesa.
  - **Abas (`CyberNavButton` em Atomic Design):**
    - `Home` 🏠: Tela principal com o botão arcade/cyber heroico `"JOGAR - Fase X ▶"` (`CyberPlayButton`), alternância de câmera (`MAP` / `BOT`) e visão isométrica da ilha tropical.
    - `Garage` 🔧: Acesso direto à Oficina de Upgrades do `UpgradeManager` (Evolução Unificada da Lâmina até o Nível 5 com Moedas).
    - `Collection` 🌿 (`TabCollection` - Herbário da Ilha & Itens):
      - **Cards Horizontais Completos:** Exibe cards horizontais de largura total (`card_herbarium_horizontal.svg` / `card_herbarium_horizontal_locked.svg`) contendo: moldura chanfrada à esquerda com ilustração botânica vetorial multicamadas (`illus_grass_base.svg` + `illus_grass_blades.svg`, `illus_wheat_bundle.svg`, `illus_flower_stems.svg` + `illus_flower_petals.svg`, ou cadeado neon `illus_locked_plant.svg`), badge angular de status (`✓ DESCOBERTA` ou `BLOQUEADO`), indicador `Fase X+`, nome da espécie, atributos (`Resistência • Recompensa`), descrição botânica, contador `Colhidos: X`, título de maestria (`Nv X/10: ...`) com barra de progresso chanfrada, e botão/badge lateral direito (`badge_milestone_cyber.svg` / `btn_claim_cyber.svg`) para resgate de moedas.
      - **Ordenação Estrita por Fase (`origin_level`):** Sem barra de filtros por categoria; todas as 15 espécies são listadas em ordem crescente da fase em que aparecem pela primeira vez (`origin_level` em `PlantDatabase.get_all_species()`).
    - `Store` 🏪: Loja de pacotes de moedas e resgate de recompensas diárias em painéis chanfrados.

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

### 3.4 Modal de Configurações (`SettingsModal`) & Sistema Multilinguagem
- **Layout Responsivo Cyber:** Painel modal cobrindo ~85% da tela com fundo translúcido escuro, moldura chanfrada neon e fechamento tátil pelo botão [X] ou toque no backdrop.
- **Preferências de Áudio e Feedback:** Toggles independentes para Música, Sons (FX) e Vibração Háptica (com detecção do sistema operacional para retorno tátil em dispositivos Android).
- **Seletor Visual de Idiomas (i18n):** Linha de controle com ícone vetorial de globo (`icon_globe.svg`) e 3 botões segmentados Cyber:
  - `[ PT ]`: Português do Brasil (`pt_BR`).
  - `[ EN ]`: Inglês (`en`).
  - `[ ES ]`: Espanhol (`es`).
- **Reatividade Dinâmica:** Ao alternar de idioma, o `SaveManager` persiste a preferência e sincroniza o `TranslationServer`. A engine emite `NOTIFICATION_TRANSLATION_CHANGED`, atualizando instantaneamente sem reload todos os textos do menu principal (todas as 4 abas: Início, Oficina, Herbário e Loja), toasts, botões da navbar, cartões de fase, placa 3D de arquipélago, barra da serra (Nível Máximo), oficina in-game e modais de vitória, derrota, pausa e saída.
- **Seção Save Progress & Reset:** Salvamento manual local, conectores para Google Play Games / Facebook e botão de confirmação com segurança de duplo toque para reset geral de progresso.

### 3.6 Navegação por Gestos (Swipe) no Menu Principal (`v0.12.143-alpha`)
- **Arquitetura Desacoplada (`MenuGestureDetector`):** Detector de gestos por toque e mouse com filtro polar de eixos ($1.30\times$ dominância), threshold de $45\text{px}$ e rejeição de diagonais acidentais ou toques estáticos longos ($> 0.85\text{s}$).
- **Troca de Fases Vertical (Opção B - Visão do Bot na Home):**
  - Deslizar para **baixo** ($\Delta Y > 0$) avança para a próxima fase ($N + 1$).
  - Deslizar para **cima** ($\Delta Y < 0$) retorna para a fase anterior ($N - 1$).
  - O robô executa teleporte holográfico entre ilhas, o `MapLevelCard` dispara animação elástica de bump (`play_bump_animation`), e tentativas de ultrapassar os limites (Fase 1 ou máxima desbloqueada) acionam feedback visual de squash/stretch (`play_boundary_bounce`) com som sutil.
- **Troca de Abas Horizontal (Todas as Abas do Menu):**
  - Deslizar para a **esquerda** ($\Delta X < 0$) avança para a aba da direita (`Home` ➔ `Oficina` ➔ `Coleção` ➔ `Loja`).
  - Deslizar para a **direita** ($\Delta X > 0$) retorna para a aba anterior.
  - Sincroniza a `BottomNavBar`, dispara transição suave de fade e **não interfere na rolagem vertical nativa** dos `ScrollContainer` das abas de Oficina, Coleção e Loja.

---

## 4. Barra Flutuante 3D de Evolução da Lâmina (`BladeProgressBar3D`)

Instanciada no cortador (`scenes/cutter/blade_progress_bar.tscn`), a barra posiciona-se **abaixo do robô na visão da câmera isométrica** (`position = Vector3(0.0, 0.12, 1.38)` em `scenes/cutter/cutter.tscn`, desacoplada do giro do chassi via `top_level = true`) fornecendo telemetria limpa e desobstruída da evolução da serra:

- **Renderização e Projeção:** Desenvolvida em `SubViewport` (`512x116` pixels) renderizado em um `Sprite3D` unshaded (`pixel_size = 0.0036`) com `billboard = BILLBOARD_ENABLED` e sem culling de sombras, garantindo 60 FPS estáveis no mobile.
- **Moldura Cyber e Estado NÍVEL MAX:** Utiliza frame chanfrado com degrau e risquinhos neon externos (`bar_frame_cyber.svg`, preenchimento `bar_fill_cyber.svg`), alternando automaticamente no Nível 6 para o banner dourado chanfrado `bar_max_cyber.svg` com estrelas e rótulo `"NÍVEL MAX"`.
- **Ocultação na Vitória:** Ocultada automaticamente quando a fase entra em celebração de vitória (`GameState.VICTORY`), mantendo o enquadramento heroico do robô 100% limpo.

