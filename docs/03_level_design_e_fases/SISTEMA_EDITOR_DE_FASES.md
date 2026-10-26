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

- **Camada 0 — Terreno (Ilha 3D Modular em $0.80\text{m} \times 0.80\text{m}$):**
  - Modelos 3D estilizados em `assets/models/tiles/*.glb` integrados nas cenas `scenes/editor/tiles/`:
    - `auto_island`: Pincel inteligente Auto-Tile (`island_autotiler.gd`) que resolve automaticamente entre `island_center`, `island_edge`, `island_corner_out`, `island_corner_in` e `island_end`.
    - `island_corner_out`: Canto convexo arredondado em arco cilíndrico ($R = 0.28\text{m}$) com acabamento macio (*smooth normals*) e encaixe estanque sem frestas.
    - `island_corner_in`: Quina interna côncava em arco suave ($R = 0.20\text{m}$) para reentrâncias e baías em "L".
    - `island_end`: Ponta de península e promontórios de 1 tile com 3 lados de falésia arredondada e espuma.
    - `island_edge`: Borda de falésia reta com lábio superior de grama sobreposto e espuma ciano na base.
    - `island_center`: Piso plano de grama verde esmeralda.
    - `island_dirt`: Piso plano de terra/trilha alaranjada quente.
  - Todas as peças manuais possuem suporte a giro de $90^\circ$ (`R`).
  - **Borracha / Clique Direito:** Remove o bloco de terreno (transforma em mar aberto) e apaga automaticamente qualquer objeto ou vegetação contida naquela célula.

- **Camada 1 — Grama Orgânica por Coordenadas Vetoriais 2D (`VectorGrassField`):**
  - Desenho vetorial contínuo no plano $XZ$ em metros, sem qualquer amarração a matrizes quadriculadas de grid.
  - **Pincel Livre (Freehand Ribbon):** Arrastar o mouse gera uma fita poligonal suave com cantos e pontas arredondadas (`create_ribbon_polygon`), unindo-se automaticamente a outras manchas da mesma cor via Clipper C++ (`Geometry2D.merge_polygons`).
  - **Largura Dinâmica do Traço:** As teclas `[` e `]` ajustam em tempo real o diâmetro do pincel (de 1 a 4, correspondendo a $0.30\text{m} \dots 1.00\text{m}$ de largura).
  - **Auto-Geração de Terreno:** Ao pintar grama sobre áreas de mar/vazio, o editor gera automaticamente o terreno de ilha de $0.80\text{m}$ correspondente por baixo, com atualização instantânea do auto-tile.
  - **Amostragem Orgânica Poisson Disk:** A densidade foliar é gerada por algoritmo de Poisson Disk ($r = 0.22\text{m}$), conferindo visual vivo e uniforme sem artefatos de grade.
  - **Visual Limpo sem Decalque Artificial:** O solo permanece com o material e textura naturais dos blocos 3D de terreno (`tile_island_*`), sendo a vegetação composta exclusivamente pelos tufos 3D de grama/trigo/flor; nenhuma malha plana de cor sólida é colada sobre o solo.
  - **Variedades Suportadas:** As 7 cores de grama (`grass_green`, `grass_yellow`, `grass_blue`, `grass_purple`, `grass_white`, `grass_red`, `grass_black`) e `wheat` (trigo maduro).
  - **Borracha / Clique Direito:** Recorta e subtrai qualquer polígono vetorial via `Geometry2D.clip_polygons()`.

- **Camada 2 — Objetos & Obstáculos no Tile ($0.80\text{m} \times 0.80\text{m}$):**
  - Itens discretos centralizados por bloco de terreno:
    - **`rock` (Rocha Sólida):** Obstáculo rígido da `Layer 4` com física de choque/ricochete. Limpa automaticamente a grama sob a rocha no campo vetorial com corte circular para não atravessar a pedra.
    - **`flower` (Flor Nobre):** Vegetação de alto valor econômico (2 hits, 5 moedas) posicionada no centro do tile de $0.80\text{m}$.
    - **`cutter_spawn` (Spawn do Robô):** Marcador de início do robô cortador (único por fase).
  - **Borracha / Clique Direito Direto:** Ao usar a borracha ou clicar com o botão direito na Camada de Objetos (ou clicar com a borracha direto sobre uma pedra/flor em qualquer camada), o objeto é removido imediatamente da célula discreta (`object_grid.erase(cell)`), permitindo apagar pedras e flores instantaneamente!

- **Persistência Híbrida JSON v3 e Blindagem de Bake (`LevelSerializer`):**
  - O formato JSON v3 salva os polígonos contínuos em `"grass_vectors": [ { "id": 1, "type": "grass_green", "polygon": [...], "holes": [...] } ]` e os objetos de tile discretos em `"objects": [ { "gx": ..., "gz": ..., "type": "rock"|"flower", "rot": ... } ]`.
  - **Blindagem Defensiva contra Sobrescrita:** A rotina de exportação `bake_to_tscn` recebe e repassa `vector_field` obrigatoriamente; caso `vector_field` seja nulo mas o arquivo existente em disco já contenha `"grass_vectors"`, o serializador preserva os dados existentes sem reverter para `version: 2` vazia.

- **Painel Direito Contextual e Sistema de Metas Customizadas:**
  - **ScrollContainer e Responsividade:** Painéis laterais operam dentro de `ScrollContainer` ancorados com margens dinâmicas, garantindo navegação suave e impedindo qualquer corte de botões em telas ou resoluções inferiores a 1080p.
  - **Botões e Tipografia Equalizados:** Botões da paleta padronizados em altura de $34\text{px}$ a $36\text{px}$ com fonte de $13\text{px}$, proporcionando conforto no clique e alta legibilidade em conjunto com banner de contexto dinâmico no topo.
  - **Filtro Contextual por Camada:** O painel lateral direito adapta seus componentes dinamicamente à camada selecionada no painel esquerdo:
    - *Camada 0 (Terreno):* Exibe exclusivamente a paleta de blocos de ilha (`auto_island`, `island_center`, `island_dirt`, `island_edge`, etc.), ocultando gramas e objetos.
    - *Camada 1 (Grama):* Exibe a paleta estruturada em duas seções nítidas:
      - `🌿 Gramas Comuns (1x HP - 1 Moeda)`: Grade 2 colunas com as 7 cores cosméticas (Verde, Amarela 1x, Azul, Violeta, Branca, Vermelha, Preta).
      - `🌾 Vegetação de Meta (2x HP - 3 Moedas)`: Botão de destaque largo para `🌾 Trigo Maduro (Meta 2x)` e botão de ação rápida `🔄 Converter Grama Amarela ➔ Trigo` (converte retroativamente polígonos amarelos desenhados por engano para trigo canônico).
    - *Camada 2 (Objetos):* Exibe a paleta de objetos discretos no tile (Rocha `rock`, Flor `flower`, Spawn `cutter_spawn`) em grade harmoniosa de 3 colunas de $94\text{px}$.
  - **Cards de Metas Personalizadas (CheckBox + SpinBox):**
    - Cada vegetação colhível (`🌿 Grama`, `🌾 Trigo`, `🌸 Flores`) possui seu próprio card com:
      - **CheckBox:** Define se aquele item é ou não meta obrigatória da fase. Se desmarcado, a planta pode existir no mapa para corte e economia de moedas, mas não é exigida para a condição de vitória!
      - **Contador Total:** Indica em tempo real a quantidade física total presente no mapa (`/ Total`).
      - **SpinBox Editável:** Permite calibrar a quantidade exata necessária para a vitória (ex: 30 trigos de um total de 60). Edições manuais congelam a meta sem sobrescrever na pintura.
    - **Persistência em JSON v3 (`"goals"`):** O dicionário de metas configurado é serializado no JSON do nível e respeitado tanto no Playtest quanto no jogo final (`VegetationGrid.build_from_level_json()`).
    - **Métricas Informativas de Construção:** Exibe no rodapé as quantidades de obstáculos (`🪨 Rochas`) e solo construído (`🏝️ Blocos Ilha`).

### 2.3 Prancheta Vetorial no Modo Edição vs. Grama 3D no Playtest (F1)
- **Modo Edição (Prancheta Vetorial):** A vegetação é exibida exclusivamente através de superfícies vetoriais planas coloridas (`VectorGrassField.generate_ground_meshes()`) a $Y = 0.005\text{m}$, com materiais foscos (`roughness = 0.90`) e recorte exato sob as rochas. O tempo de resposta ao pintar com pincel ou carimbo cai de $\sim 35\text{ms}$ para **$< 0.5\text{ms}$** (zero lag), mantendo a grade, o spawn e os encaixes de blocos 100% visíveis.
- **Modo Playtest ([F1] ou [F5]):** Ao acionar o teste, o `VegetationGrid` oficial 3D volumétrico (com física de corte, partículas em arco, moedas e colheitadeira) é instanciado na hora. Ao sair pressionando `ESC` ou `F1`, a vegetação de teste é liberada da memória e o editor retorna instantaneamente à prancheta vetorial limpa com a fase intacta.

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

---

## 4. Tabela de Atalhos e Comandos

| Comando | Atalho | Função |
| :--- | :---: | :--- |
| **Pincel / Carimbo** | `1` ou `B` | Pinta na camada ativa com o formato de pincel selecionado. |
| **Borracha** | `2`, `E` ou **Clique Direito** | Apaga células da camada ativa (cava água no terreno ou remove plantas). |
| **Retângulo (Box Fill)** | `3` ou `F` | Arraste de $A \to B$ para preencher uma área retangular. |
| **Posicionar Spawn** | `4` | Define a célula inicial do robô cortador. |
| **Girar Pincel / Tile** | `R` | Rotaciona em sentido horário de $5^\circ$ em $5^\circ$ (Pincel/Vegetação) ou $90^\circ$ (Tiles de Terreno). |
| **Escala do Pincel** | `[` e `]` (ou `Alt + Scroll`) | Diminui ou aumenta o tamanho do carimbo. |
| **Alternar Câmera** | `V` | Alterna entre Visão Isométrica 3D (Perspectiva $42^\circ$) e Visão Top-Down 2D (Ortogonal pura de topo). |
| **Mover Câmera (Pan)** | `WASD` / Botão Meio / Botão Direito | Desloca o foco sobre o mapa. |
| **Zoom da Câmera** | `Scroll do Mouse` | Aproxima ou afasta a câmera ($5.5\text{m}$ a $28.0\text{m}$). |
| **Desfazer / Refazer** | `Ctrl + Z` / `Ctrl + Y` | Histórico de até 30 operações. |
| **Salvar Fase (JSON)** | `Ctrl + S` | Grava `res://data/levels/level_%02d.json`. |
| **Playtest In-Editor** | `F1` ou `F5` (e `ESC` p/ sair) | Spawna o robô cortador para teste real e restaura a ilha intacta ao sair. |

---

## 5. Roadmap Futuro: Editor Mobile "Bot Arquiteto"

Para viabilizar a criação de fases diretamente no celular sem depender da interface de janelas do PC, está planejado o **Modo Construtor Mobile** (ver especificações completas em [`docs/MELHORIAS_FUTURAS.md`](../MELHORIAS_FUTURAS.md#44-modo-construtor-mobile-bot-arquiteto-editor-de-fases-jogável-one-thumb)):
- **Editor Diegético:** O jogador controla o Bot com o joystick virtual de uma mão (*one-thumb*), terraformando ilhas sobre o oceano, semeando grama/trigo por onde passa e ejetando rochas.
- **Auto-Tile Dinâmico:** Os blocos de terra e falésias se adaptam em tempo real ao rastro do robô.
- **Playtest Imediato em 1 Toque:** Alterna instantaneamente entre o modo semeador e a lâmina de corte.
