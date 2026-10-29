# Sistema do Editor de Fases In-Game para PC (Ilhas 3D) 🏝️🛠️🌿

Este documento descreve a arquitetura, ferramentas, controles e fluxo de persistência do **Editor de Fases In-Game**, projetado para operar em **modo janela widescreen no PC** (`WINDOW_MODE_WINDOWED`, $1600 \times 900$ centralizada) sem ser compilado nos pacotes de exportação mobile (Android).

---

## 1. Visão Geral e Filosofia de Design

1. **Execução Exclusiva em Desktop (Modo Janela Widescreen):**
   - Acessível diretamente via **F6** na cena `res://scenes/editor/level_editor.tscn` ou pelo atalho **`F2` / botão `🛠️ Editor [F2]`** na tela principal quando executado no PC.
   - Reconfigura dinamicamente a `Window` para `WINDOW_MODE_WINDOWED` ($1600 \times 900$ centralizada no monitor, com escala base `1920x1080` `CONTENT_SCALE_ASPECT_EXPAND`), retornando automaticamente ao formato portrait mobile (`450x800` / `720x1280` `KEEP_WIDTH`) ao voltar ao jogo.
2. **Ilhas 3D Modulares sobre o Oceano (Zero Cercas):**
   - Os níveis são construídos como ilhas 3D sobre um oceano azul turquesa contínuo (`water_ocean.tscn`).
   - Cada bloco de ilha ($0.80\text{m} \times 0.80\text{m}$) possui topo de grama verde, paredão/falésia marrom escuro nas bordas costeiras e faixa de espuma clara na água.
   - **Contenção Invisível (`Layer 1`):** As faces voltadas para a água recebem colisores invisíveis na beira do barranco (`LevelJsonLoader.build_coastal_colliders_and_foam()`), impedindo que o cortador caia no mar sem necessidade de cercas visuais.
3. **Desacoplamento de Dados em JSON (`res://data/levels/level_XX.json`):**
   - Os mapas são salvos em arquivos JSON limpos e leves na pasta `res://data/levels/`.
   - O carregador runtime (`scripts/level/level_json_loader.gd`) reside em `scripts/level/`, permitindo que o APK mobile carregue os arquivos `.json` mesmo quando `scenes/editor/*` e `scripts/editor/*` são excluídos na exportação.

---

## 2. Sistema de Três Camadas de Edição (Terreno vs. Grama Fina vs. Objetos no Tile)

Para garantir liberdade criativa, precisão no posicionamento e facilidade na edição (incluindo exclusão pontual de pedras e flores), o editor opera com arquitetura em 3 camadas independentes:

- **Camada 0 — Terreno (Ilha 3D Procedural por Polígono Extrudado `IslandMeshBuilder`):**
  - O terreno da ilha é renderizado como uma **malha procedural contínua única** (`ArrayMesh` - 1 Draw Call), sem frestas ou emendas entre peças.
  - No editor, a grade atua como uma **régua de alinhamento inteligente (*Snapping Grid*)**:
    - Carimbar ou pintar terreno funde automaticamente os formatos via união booleana (`Geometry2D.merge_polygons`).
    - As paredes de falésia descem até $Y = -0.72\text{m}$ e o teto superior de grama/terra fica em $Y = 0.0\text{m}$.
    - A fita de espuma costeira (`CoastalFoamRibbon`) e as barreiras invisíveis de contenção física (`Layer 1: Ground & Limits`) são reconstruídas em tempo real acompanhando o perímetro da ilha.
  - **Borracha / Clique Direito:** Recorta e subtrai partes do terreno via `Geometry2D.clip_polygons()`, permitindo abrir baías, canais ou apagar blocos, removendo automaticamente qualquer objeto contido na área apagada.
  - **Persistência:** Salva tanto a lista de blocos quanto o polígono contínuo fechado (`island_polygons`) no formato JSON v4.

- **Camada 1 — Grama Orgânica por Coordenadas Vetoriais 2D (`VectorGrassField`):**
  - Desenho vetorial contínuo no plano $XZ$ em metros, sem qualquer amarração a matrizes quadriculadas de grid.
  - **Pincel Livre (Freehand Ribbon):** Arrastar o mouse gera uma fita poligonal suave com cantos e pontas arredondadas (`create_ribbon_polygon`), unindo-se automaticamente a outras manchas da mesma cor via Clipper C++ (`Geometry2D.merge_polygons`).
  - **Largura Dinâmica do Traço:** As teclas `[` e `]` ajustam em tempo real o diâmetro do pincel (de 1 a 4, correspondendo a $0.30\text{m} \dots 1.00\text{m}$ de largura).
  - **Auto-Geração de Terreno:** Ao pintar grama sobre áreas de mar/vazio, o editor gera automaticamente o terreno de ilha de $0.40\text{m}$ correspondente por baixo, com atualização instantânea do auto-tile.
  - **Corredor Costeiro Perimetral ($0.48\text{m}$):** Ao pintar grama, o traço é automaticamente recortado contra um polígono de segurança recuado da borda da ilha (`Geometry2D.offset_polygon(island_poly, -0.48)`), garantindo um calçadão perimetral desimpedido para o cortador manobrar sem risco de vegetação caindo no mar.
  - **Elevação Vertical Anti-Flick ($0.001\text{m}$ por Forma):** Formas vetoriais sobrepostas recebem escalonamento de altura de um milésimo de metro ($Y = 0.005 + \text{idx} \times 0.001\text{m}$) e `sorting_offset`, eliminando 100% de Z-fighting (flicker) entre camadas de cores distintas.
  - **Amostragem Orgânica Poisson Disk:** A densidade foliar é gerada por algoritmo de Poisson Disk ($r = 0.22\text{m}$), conferindo visual vivo e uniforme sem artefatos de grade.
  - **Visual Limpo sem Decalque Artificial:** O solo permanece com o material e textura naturais dos blocos 3D de terreno (`tile_island_*`), sendo a vegetação composta exclusivamente pelos tufos 3D de grama/trigo/flor; nenhuma malha plana de cor sólida é colada sobre o solo.
  - **Variedades Suportadas:** As 7 cores de grama cosmética (`grass_green`, `grass_yellow`, `grass_blue`, `grass_purple`, `grass_white`, `grass_red`, `grass_black`), com regra de lotes de 10 cortes = 1 meta.
  - **Borracha / Clique Direito:** Recorta e subtrai qualquer polígono vetorial via `Geometry2D.clip_polygons()`.

- **Camada 2 — Objetos & Obstáculos na Grade Subdividida ($0.40\text{m} \times 0.40\text{m}$):**
  - **Subdivisão em 4 Quadrantes ($0.40\text{m}$):** Cada bloco clássico de $0.80\text{m}$ é subdividido em 4 sub-células de $0.40\text{m}$, permitindo quadruplicar a resolução de posicionamento de pedras, flores e trigo sem alterar a física de corte do jogo.
  - **`rock` (Rocha Sólida 🪨) & Clareira de Segurança ($1.40\text{m}$):** Obstáculo rígido da `Layer 4` com física de choque/ricochete.
    - Ao posicionar ou passar o mouse com uma pedra, uma zona circular de $1.40\text{m}$ (equivalente ao raio máximo da lâmina Nível 6 do robô, `UpgradeManager.MAX_BLADE_RADIUS`) é demarcada.
    - O editor limpa automaticamente qualquer grama sob e ao redor da rocha nesse raio de $1.40\text{m}$, além de expulsar e impedir o posicionamento de qualquer flor ou trigo dentro dessa área de colisão.
  - **Família de Flores Nobres (3 hits, 5 moedas):**
    - **Orientação Canônica Padrão ($0^\circ$):** Todas as flores nascem por padrão voltadas para a câmera isométrica ($0^\circ$), conferindo leitura frontal acolhedora imediata.
    - **Imunidade de Rotação (`randomize_rotation = false`):** O editor desativa a aleatorização de giro ao reconstruir nós 3D, garantindo que adicionar novas flores ou objetos não altere a rotação das flores já existentes.
    - Variedades de flores suportadas:
      - **`flower` (Flor Silvestre 🌸):** Duas hastes inclinadas com 16 pétalas intercaladas.
      - **`flower_rose` (Rosa Nobre 🌹):** Arbusto nobre com caule folhoso e rosa em camadas.
      - **`flower_daisy` (Margarida do Campo 🌼):** Haste alta com miolo ouro e 36 pétalas radiais.
      - **`flower_sunflower` (Girassol Solar 🌻):** Disco central avelã e pétalas em leque dourado.
      - **`flower_bell` (Flor Sino / Campânula 🔔):** Formato em sino pendente azul celeste com 16 pétalas.
      - **`flower_corolla` (Cravo Corola 🏵️):** Flor espalmada aberta em tom coral damasco.
      - **`flower_tulip` (Tulipa Imperial 🌷):** Cálice ereto em taça vermelha rubi.
      - **`flower_bed` (Canteiro Florido 🪻):** Tufo horizontal salpicado com folhagem verde e 9 florzinhas lilás violeta.
    - **`wheat` (Trigo Maduro 🌾):** Cultura agrícola dourada de 2 hits (3 moedas) com contagem direta 1:1 na meta do HUD.
    - **`cutter_spawn` (Spawn do Robô 🤖):** Marcador de início do robô cortador (único por fase).
  - **Borracha / Clique Direito Direto:** Ao usar a borracha ou clicar com o botão direito na Camada de Objetos (ou clicar com a borracha direto sobre uma pedra, flor ou trigo em qualquer camada), o objeto é removido imediatamente da célula discreta (`object_grid.erase(cell)`), permitindo apagar itens instantaneamente!

- **Persistência Híbrida JSON v3 e Blindagem de Bake (`LevelSerializer`):**
  - O formato JSON v3 salva os polígonos contínuos em `"grass_vectors": [ { "id": 1, "type": "grass_green", "polygon": [...], "holes": [...] } ]` e os objetos de tile discretos em `"objects": [ { "gx": ..., "gz": ..., "type": "rock"|"flower"|"wheat", "rot": ... } ]`.
  - **Blindagem Defensiva contra Sobrescrita:** A rotina de exportação `bake_to_tscn` recebe e repassa `vector_field` obrigatoriamente; caso `vector_field` seja nulo mas o arquivo existente em disco já contenha `"grass_vectors"`, o serializador preserva os dados existentes sem reverter para `version: 2` vazia.

- **Painel Direito Contextual e Sistema de Metas Customizadas por Cor de Grama:**
  - **Largura Expandida e Zero Cortes:** Painel lateral direito calibrado com largura expandida de $364\text{px}$ (`offset_left = -376`, `offset_right = -12`) com botões flexíveis (`SIZE_EXPAND_FILL` e `clip_text = true`), eliminando qualquer corte ou sobreposição no lado direito da tela.
  - **Botões e Tipografia Equalizados:** Botões da paleta em 2 colunas auto-ajustáveis com altura de $34\text{px}$ e fonte de $12\text{px}$, proporcionando conforto visual e encaixe sem transbordar.
  - **Filtro Contextual por Camada:** O painel lateral direito adapta seus componentes dinamicamente à camada selecionada no painel esquerdo:
    - *Camada 0 (Terreno):* Exibe exclusivamente a paleta de blocos de ilha (`auto_island`, `island_center`, `island_dirt`, `island_edge`, etc.), ocultando gramas e objetos.
    - *Camada 1 (Grama):* Exibe a paleta com as 7 cores cosméticas (Verde, Amarela 1x, Azul, Violeta, Branca, Vermelha, Preta) em grade de 2 colunas auto-ajustáveis.
    - *Camada 2 (Objetos):* Exibe a paleta de objetos e culturas no tile (Rocha `rock`, Flor `flower`, Trigo `wheat`, Spawn `cutter_spawn`) em grade de 2 colunas.
  - **Cards de Metas Independentes por Espécie e Cor (9 Variedades):**
    - Cada variedade colhível possui seu próprio card com cor e ícone dedicados:
      - As 7 cores de grama: `🌿 Grama Verde`, `🌼 Grama Amarela`, `💠 Grama Azul`, `🔮 Grama Violeta`, `🤍 Grama Branca`, `❤️ Grama Vermelha`, `🖤 Grama Preta`.
      - Culturas e flores: `🌾 Trigo`, `🌸 Flores`.
    - **Exibição do Total de Tufos na Fase:** Exibe em tempo real o total físico exato presente no mapa (ex: `248 tufos`, `8 trigos`, `4 flores`). Se a quantidade for 0, o total é esmaecido e o CheckBox é desabilitado.
    - **Ativação Dinâmica da Meta:** CheckBox individual para ligar ou desligar aquela variedade como objetivo de vitória.
    - **Abertura Condicional do Campo de Edição (SpinBox):**
      - Se a meta estiver **desmarcada**, o campo de edição permanece fechado/oculto (`visible = false`), mantendo a UI limpa e compacta.
      - Se a meta for **marcada**, o campo abre instantaneamente (`visible = true`).
    - **Restrição Estrita de Quantidade:**
      - O valor editável é rigidamente limitado ao intervalo $[1, \text{total}]$: não pode ser zero, não pode ser negativo e não pode exceder o total de tufos existentes na fase.
      - Se o jogador apagar tufos no mapa reduzindo o total abaixo da meta configurada, o SpinBox ajusta-se automaticamente ao novo teto.
    - **Execução 1:1 de Metas Personalizadas:** No `VegetationGrid`, fases com metas customizadas (`"goals"`) abatem 1 unidade de meta para cada tufo físico ceifado (em vez do agrupamento legado de 10), garantindo correspondência exata entre o número definido no editor e a contagem de vitória do jogo.
    - **Métricas Informativas de Construção:** Exibe no rodapé as quantidades de obstáculos (`🪨 Rochas`) e solo construído (`🏝️ Blocos Ilha`).

### 2.3 Prancheta Vetorial no Modo Edição vs. Grama 3D no Playtest (F1) com Câmera Oficial
- **Modo Edição (Prancheta Vetorial):** A vegetação é exibida exclusivamente através de superfícies vetoriais planas coloridas (`VectorGrassField.generate_ground_meshes()`) a $Y = 0.005\text{m}$, com materiais foscos (`roughness = 0.90`) e recorte exato sob as rochas. O tempo de resposta ao pintar com pincel ou carimbo cai de $\sim 35\text{ms}$ para **$< 0.5\text{ms}$** (zero lag), mantendo a grade, o spawn e os encaixes de blocos 100% visíveis.
- **Modo Playtest ([F1] ou [F5]) com Paridade Total de Câmera:** Ao acionar o teste, o `VegetationGrid` oficial 3D volumétrico (com física de corte, partículas em arco, moedas e colheitadeira) é instanciado na hora.
  - **Câmera Oficial do Jogo (`PlaytestGameCamera`):** O editor alterna da câmera livre de prancheta (`EditorCamera`) para a câmera canônica de gameplay ([`IsometricCamera`](../04_sistemas_e_gameplay/GAME_FEEL_E_HAPTICS.md)), garantindo **100% de paridade visual com o jogo real**:
    - Campo de visão idêntico: $\text{FOV} = 48.0$.
    - Distância calibrada pelo nível de lâmina atual ($6.0\text{m}$ no Lv 1 até $12.0\text{m}$ no Lv 6 MAX).
    - Inclinação rígida isométrica de $-40.23^\circ$ em `_physics_process` sem distorção ou wobble ao mover.
    - Suporte a `camera_shake` em impactos com rochas e transições cinematográficas de vitória.
  - Ao sair pressionando `ESC` ou `F1`, a vegetação e o robô de teste são liberados da memória e a câmera retorna suavemente ao ponto e zoom exatos de edição anterior.

---

## 3. Pincéis e Carimbos de Formas Analíticas (`brush_patterns.gd`)

O editor inclui formatos matemáticos com escala ajustável (`1` a `20`), suporte a offsets em passos de $0.20\text{m}$ para vegetação orgânica e preview holográfico em tempo real sobre a grade (`grid_overlay.gd`):
- `⏺️ Único (1x1)`
- `⬛ Quadrado`
- `⚪ Círculo Analítico` (projeção contínua $dx^2 + dz^2 \le R^2$, eliminando pontas em cruz)
- `🔶 Losango` ($|dx| + |dz| \le R$)
- `❤️ Coração` (Equação implícita cardióide contínua)
- `⭐ Estrela` (Modulação radial de 5 pontas)
- `➕ Cruz`
- `⭕ Anel Circular` (Distribuição em circunferência uniforme com centro oco para flores, rochas ou grama)

---

## 4. Tabela de Atalhos e Comandos

| Comando | Atalho | Função |
| :--- | :---: | :--- |
| **Pincel / Carimbo** | `1` ou `B` | Pinta na camada ativa com o formato de pincel selecionado. |
| **Borracha** | `2`, `E` ou **Clique Direito** | Apaga células da camada ativa (cava água no terreno ou remove plantas). |
| **Retângulo (Box Fill)** | `3` ou `F` | Arraste de $A \to B$ para preencher uma área retangular. |
| **Posicionar Spawn** | `4` | Define a célula inicial do robô cortador. |
| **Pipeta (Conta-Gotas / Eyedropper)** | `5`, `I` ou `Alt + Clique Esquerdo` | Amostra o objeto, grama vetorial ou terreno sob o cursor e troca automaticamente para a camada e item correspondente. |
| **Modo Escala do Pincel (Padrão)** | `S` | Seleciona o modo de ajuste de **Escala** (ferramenta padrão inicial) e direciona os atalhos `[` e `]` para tamanho. |
| **Modo Rotação** | `R` | Seleciona o modo de **Rotação** e direciona os atalhos `[` e `]` para giro ($+5^\circ$, ou $+25^\circ$ com `Shift`; $+90^\circ$ no terreno). |
| **Diminuir Escala / Girar Esquerda** | `[` (ou `-`, `Numpad -`) | **Se Modo Escala:** diminui tamanho do pincel ($-1$, ou $-5$ com `Shift`).<br>**Se Modo Rotação:** gira para a esquerda ($-5^\circ$, ou $-25^\circ$ com `Shift`; $-90^\circ$ no terreno). |
| **Aumentar Escala / Girar Direita** | `]` (ou `+`, `=`, `Numpad +`) | **Se Modo Escala:** aumenta tamanho do pincel ($+1$, ou $+5$ com `Shift`).<br>**Se Modo Rotação:** gira para a direita ($+5^\circ$, ou $+25^\circ$ com `Shift`; $+90^\circ$ no terreno). |
| **Alternar Câmera** | `V` | Alterna entre Visão Isométrica 3D (Perspectiva $42^\circ$) e Visão Top-Down 2D (Ortogonal pura de topo). |
| **Mover Câmera (Pan)** | `Setas` / Botão Meio / Botão Direito | Desloca o foco sobre o mapa de forma desobstruída. |
| **Zoom da Câmera** | `Scroll do Mouse` | Aproxima ou afasta a câmera ($5.5\text{m}$ a $28.0\text{m}$). |
| **Desfazer / Refazer** | `Ctrl + Z` / `Ctrl + Y` | Histórico de até 30 operações. |
| **Salvar Fase (JSON)** | `Ctrl + S` | Grava `res://data/levels/level_%02d.json`. |
| **Playtest In-Editor** | `F1` ou `F5` (e `ESC` p/ sair) | Spawna o robô cortador sob a câmera oficial de gameplay para teste real e restaura a ilha intacta ao sair. |

---

## 5. Roadmap Futuro: Editor Mobile "Bot Arquiteto"

Para viabilizar a criação de fases diretamente no celular sem depender da interface de janelas do PC, está planejado o **Modo Construtor Mobile** (ver especificações completas em [`docs/MELHORIAS_FUTURAS.md`](../MELHORIAS_FUTURAS.md#44-modo-construtor-mobile-bot-arquiteto-editor-de-fases-jogável-one-thumb)):
- **Editor Diegético:** O jogador controla o Bot com o joystick virtual de uma mão (*one-thumb*), terraformando ilhas sobre o oceano, semeando grama/trigo por onde passa e ejetando rochas.
- **Auto-Tile Dinâmico:** Os blocos de terra e falésias se adaptam em tempo real ao rastro do robô.
- **Playtest Imediato em 1 Toque:** Alterna instantaneamente entre o modo semeador e a lâmina de corte.
