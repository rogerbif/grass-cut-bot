# Game Design Document (GDD): Grass Cut Bot 🌿🤖

**Versão:** 0.12-alpha (Documento Vivo)  
**Plataforma Alvo:** Android (Mobile) & PC (Desenvolvimento e Editor de Fases)  
**Gênero:** Hiper-casual, Simulação Arcade, *Satisfying Game Feel*  
**Estilo Visual:** Low Poly com cores sólidas foscas (*Matte / Flat Shading*) sobre Oceano Toon  
**Orientação da Tela:** Vertical (*Portrait* 720x1280 base, proporção 9:16)  

---

## 1. Visão Geral do Produto

### 1.1 High Concept
Controlar o robô cortador **Cutter Bit** em perspectiva isométrica para ceifar gramados exuberantes em ilhas 3D flutuantes sobre o oceano, cumprindo metas específicas de colheita botânica contra o relógio e contornando rochas sólidas em partidas dinâmicas e táteis de um a dois minutos.

### 1.2 Proposta Única de Valor (USP)
Entrega imediata de relaxamento mecânico por meio de física responsiva, feedback háptico contínuo sincronizado com cada lote de vegetação ceifado, partículas de folhas em arco parabólico, números 3D cartoon flutuantes e o dinamismo de metas visuais objetivas com contagem decrescente no Top HUD.

### 1.3 Perfil do Usuário
Jogadores casuais de dispositivos móveis que buscam sessões rápidas de descompressão durante intervalos diários, utilizando apenas uma das mãos (*one-thumb play*) para navegar e jogar confortavelmente.

---

## 2. Core Loop e Controles

### 2.1 Loop Principal de Jogabilidade
1. **Entrada na Ilha:** O jogador entra no nível e visualiza a silhueta da ilha 3D, as cotas de plantas requeridas e o cronômetro regressivo no topo.
2. **Navegação One-Thumb:** Utiliza o joystick virtual flutuante na metade inferior da tela para conduzir o robô com movimentação ágil e omnidirecional.
3. **Corte e Colheita:** A serra circular contínua ceifa os tufos por contato radial, abatendo metas no HUD, gerando tocos aparados e espalhando aparas de grama cortada no chão.
4. **Desafio Tático:** Administrar o tempo decrescente e manobrar entre rochas sólidas para evitar interrupção de inércia e ricochetes.
5. **Resolução & Vitória:** Zerar todos os contadores das plantas exigidas antes do término do tempo, acionando a celebração com câmera heróica, estrelas em arco parabólico e moedas acumuladas.
6. **Evolução na Oficina:** Investir moedas verdes para aprimorar atributos (Raio da Lâmina, Potência e Fio, Velocidade da Serra e Multiplicador) e desbloquear novos Tiers visuais de lâminas estreladas.

```
       ┌────────────────────────┐
       │   1. Entrar na Ilha    │
       └───────────┬────────────┘
                   ▼
       ┌────────────────────────┐
       │  2. Navegação 1-Thumb  │ ◄─── Toque em qualquer ponto inferior
       └───────────┬────────────┘
                   ▼
       ┌────────────────────────┐
       │ 3. Corte Radial Satisf.│ ◄─── Vibração háptica + folhas em arco
       └───────────┬────────────┘
                   ▼
       ┌────────────────────────┐
       │  4. Bater as Metas ⏱️   │ ◄─── Grama (1x), Trigo (2x), Flores (5x)
       └───────────┬────────────┘
                   ▼
       ┌────────────────────────┐
       │  5. Oficina & Evolução │ ◄─── Raio, Potência, Velocidade e Lâminas
       └────────────────────────┘
```

### 2.2 Esquema de Entrada (Input)
- **Joystick Flutuante:** O toque inicial em qualquer ponto da metade inferior da tela (`anchor_top = 0.4`, `anchor_bottom = 1.0`) define a origem do controle dinamicamente.
- **Arrasto Direcional:** O deslocamento do dedo gera um vetor normalizado de direção e velocidade.
- **Zona Morta (`12.0 px`):** Pequeno raio central sem resposta para evitar movimentos acidentais por microtoques.
- **Suporte Híbrido Desktop:** Quando executado no PC, o jogo aceita simultaneamente teclas **WASD / Setas** e arrasto de mouse para desenvolvimento e testes ágeis.

---

## 3. Mecânicas de Jogo e Entidades

### 3.1 O Cortador (Cutter Bit)
- **Estrutura Mecânica:** Corpo robótico estilizado em ABS amarelo, monociclo com pneu tratorado de borracha profunda, visor frontal com display de LED e expressões faciais reativas, articulado dinamicamente com suspensão procedural (lean em curvas, pitch de aceleração/frenagem e bobbing vertical).
- **Rotor de Corte:** Serra circular alojada no `blade_container` reparentada sob o `Body`, sincronizada com o chassi e girando continuamente a alta velocidade ($1200^\circ/\text{s}$ em condução e $90^\circ/\text{s}$ em marcha lenta idle).
- **Mecânica de Corte Radial Omnidirecional:** Tocou na lâmina, cortou. A detecção opera por distância euclidiana radial a partir do centro da serra, indiferente ao sentido de condução.
- **Evolução Visual de Lâminas (Tiers):**
  - **Tier 1:** Lâmina Estelar Tripla (3 pontas em aço cinza).
  - **Tier 2:** Lâmina Estelar Quádrupla (cruz ninja de 4 pontas).
  - **Tier 3:** Lâmina Estelar de Titânio (estrela regular de 5 pontas).
  - **Tier 4:** Lâmina Estelar Hexagonal (hexagrama de 6 pontas).
- **Estado de Choque & Ricochete:** Colisão direta contra rochas sólidas interrompe a inércia momentaneamente, gera recuo elástico suave ($9.5\text{ m/s}$), compressão de suspensão, faíscas amarelas e tremor translacional de câmera.

### 3.2 Tipos de Vegetação e Regra de Lotes
- **Distribuição Orgânica Poisson Disk:** A vegetação é instanciada através de `MultiMeshInstance3D` sobre superfícies poligonais contínuas no plano $XZ$, sem rigidez de grid matricial.
- **Espécies Vegetais e Economia:**
  - **🌿 Grama Comum:** Vegetação fundamental de corte em 1 golpe. Disponível em 7 cores cosméticas (Verde, Amarela, Azul, Roxa, Branca, Vermelha, Preta).
  - **🌾 Trigo Maduro:** Cultura agrícola de tile (Camada 2) resistente de 2 golpes (exige duas passadas ou upgrade de Potência $\ge 2$). Meta direta 1:1 e alto valor econômico.
  - **🌸 Flores do Campo:** Vegetação nobre de 3 golpes com despetalação progressiva e alto valor econômico.
- **Regra Canônica de Colheita e Lotes:**
  - **Grama Comum:** 10 tufos físicos ceifados = 1 unidade abatida na meta do HUD = $+1$ moeda base (número flutuante branco `+1`).
  - **Trigo Maduro:** 1 tufo físico ceifado = 1 unidade abatida na meta do HUD = $+3$ moedas base (número flutuante dourado `+3`).
  - **Flores Nobres:** 1 tufo físico ceifado = 1 unidade abatida na meta do HUD = $+5$ moedas base (número flutuante magenta `+5`).
- **Efeito Visual de Grama Cortada:** Ao ceifar um lote, o tufo é removido, tocos aparados são revelados no solo e lâminas fatiadas deitadas horizontalmente surgem no chão (`_clipping_multimeshes`), criando o rastro autêntico de grama cortada.

### 3.3 Topografia: Ilhas 3D Sem Cercas & Limites Invisíveis
- **Ilhas 3D Modulares sobre o Oceano:** Blocos de terreno de $0.80\text{m} \times 0.80\text{m} \times 0.72\text{m}$ modelados no Blender 5.2 com topologia limpa (zero paredes internas entre blocos vizinhos), falésias marrons verticais, quinas arredondadas convexas ($R = 0.28\text{m}$) e quinas côncavas ($R = 0.20\text{m}$).
- **Oceano Turquesa Toon & Espuma Costeira:** Superfície d'água procedural sem texturas pesadas a $Y = -0.71\text{m}$ e faixa contínua de espuma costeira 2D animada (`coastal_foam.gdshader`) adaptada à silhueta dos tiles.
- **Contenção Física Costeira Invisível (`Layer 1`):** As bordas da ilha recebem colisores estáticos invisíveis na beira do barranco gerados pelo `LevelJsonLoader`, impedindo a queda do robô no mar e eliminando 100% da necessidade de cercas ou muretas visuais artificiais.
- **Obstáculos Sólidos (`Layer 4`):** Rochas low poly com acabamento em cinza ardósia, colisor cilíndrico calibrado ($R = 0.18\text{m}$) e detecção otimizada por cache em `cutter.gd`.

---

## 4. Interface do Usuário (HUD), Hub e Telas

### 4.1 Hub Principal (Menu Inicial)
- **Diorama 3D Heroico:** O Cutter Bit repousa sobre uma ilha de grama com movimentação autônoma charmosa, olhos vivos e iluminação de estúdio.
- **Câmera Dual & Mapa do Arquipélago:** Alternância suave entre a visão próxima do robô e a visão panorâmica aérea do mapa do arquipélago, com rolagem vertical touch 1:1, ziguezague de ilhas fiéis e teleporte 3D estilizado (`teleport_effect.gdshader`).
- **Barra de Navegação Inferior (4 Abas):**
  - `Garage 🛠️`: Oficina e customização do robô.
  - `Home 🏠`: Diorama principal e início de partida.
  - `Collection 🌿`: Herbário de espécies descobertas e conquistas.
  - `Store 🛒`: Moedas e itens especiais.
- **Modal de Configurações:** Ajuste independente de Música, Efeitos e Vibração Háptica com teste em tempo real, seleção de escala 3D e botão de reset de progresso com dupla confirmação.

### 4.2 Top HUD durante o Gameplay
- **Cronômetro Regressivo:** Exibe o tempo restante (`M:SS`). Fica vermelho vivo ao atingir $\le 15\text{s}$.
- **Contador de Moedas:** Exibe as moedas colhidas na partida em tempo real.
- **Cards Dinâmicos de Metas:** Criados conforme as espécies da fase, com animação elástica de *pop* a cada lote cortado e checkmark verde (`✔`) ao completar.
- **Botão de Pausa:** Congela a física e abre o modal de pausa com `process_mode = PROCESS_MODE_ALWAYS`.

### 4.3 Modais de Fim de Partida
- **Celebração Cinematográfica de Vitória:** Câmera heróica frontal aproximada em *glide zoom*, comemoração do robô com saltos em *squash & stretch*, 3 estrelas projetadas em arco parabólico com som sequencial, confetes coloridos, pílula de métricas e barra de ações inferior desobstruída (`Próxima Fase`, `Repetir`, `Menu Inicial`).
- **Reação Dramática de Derrota:** Quando o cronômetro esgota, o robô fica cabisbaixo com olhos tristes (`SAD`), baforadas cartoon de fumaça cinza e desaceleração suave da lâmina por inércia, seguida da tela de falha com opção de tentar novamente.

---

## 5. Game Feel, Haptics e Áudio

### 5.1 Efeitos Visuais & Juicy Game Feel
- **Partículas de Corte:** Pool estático de 16 emissores compartilhados ejetando 21 pedaços de folhas partidas estilizadas (`cut_leaf_piece.obj`) em anel com tumbling 3D sob gravidade natural.
- **Números Flutuantes Cartoon 3D:** Textos cel-shaded tridimensionais (`+1`, `+3`, `+5`) com contorno preto sólido de 14px e rastro contínuo gerados pelo `FloatingCoinManager`.
- **Câmera Isométrica com Translação Pura:** Altura $Y = 7.2\text{m}$, distância $Z = 8.5\text{m}$, pitch fixo de $40.2^\circ$ e FOV de $48^\circ$, eliminando rotações dinâmicas e náuseas em telas verticais.

### 5.2 Feedback Tátil (Haptics)
- **Corte de Vegetação:** Pulso háptico suave de $30\text{ms}$ a $25\%$ de intensidade com micro-cooldown de $35\text{ms}$.
- **Impacto em Rocha:** Pulso vigoroso de $65\text{ms}$ a $80\%$ de intensidade sincronizado com faíscas amarelas e camera shake.
- **Permissão VIBRATE:** Habilitada no manifesto Android para suporte nativo em qualquer fabricante.

### 5.3 Arquitetura de Áudio (AudioManager)
- Barramentos isolados `Master`, `Music` e `SFX`.
- Trilhas dinâmicas de Dyalla para Menu e Gameplay.
- Motor elétrico contínuo modulado proceduralmente por velocidade.
- 20 efeitos sonoros balanceados com controle estrito de *throttling* e debounce para evitar efeito metralhadora.

---

## 6. Level Design e Progressão

### 6.1 Matriz de 20 Fases Canônicas
O jogo conta com 20 fases serializadas em JSON v3 (`data/levels/level_XX.json`), organizadas em 5 Tiers de maestria:
1. **Tier 1 (Fases 1 a 4) — O Despertar do Jardineiro:** Ilhas amplas e acolhedoras, tutorial do joystick e introdução ao trigo e primeiras flores.
2. **Tier 2 (Fases 5 a 8) — Expansão Geográfica & Istmos:** Pontes estreitas de 2 blocos cercadas de água e metas triplas.
3. **Tier 3 (Fases 9 a 12) — Desafio Tático & Chicanes:** Penínsulas em "S", ilhas trevo e curvas fechadas.
4. **Tier 4 (Fases 13 a 16) — Labirintos & Alta Densidade:** Trigo pesado, corredores com rochas e ilhotas em degraus.
5. **Tier 5 (Fases 17 a 20) — O Grande Arquipélago Real:** Malha de xadrez, santuários solares e a épica *Grande Coroa Real* (Fase 20) com transição para o Ciclo Mestre.

### 6.2 Editor de Fases In-Game para PC
Ferramenta interna acessível via atalho `F2` em modo janela widescreen ($1600 \times 900$):
- Pincel livre de fitas poligonais suaves via Clipper C++ e amostragem Poisson Disk.
- Carimbos analíticos de formas matemáticas de 1x a 20x com rotação de $5^\circ$ em $5^\circ$ (`R`).
- Prancheta vetorial plana rápida com resposta $<0.5\text{ms}$.
- Cards de metas customizadas com CheckBox e SpinBox numérico.
- Playtest instantâneo com a física real da serra pressionando `F1`.
