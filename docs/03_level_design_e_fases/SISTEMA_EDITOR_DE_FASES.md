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

## 2. Sistema de Grade de Dupla Resolução (Terreno 0.80m vs. Vegetação Orgânica 0.20m)

Para garantir liberdade criativa, silhuetas fluidas e desempenho impecável, o editor opera com arquitetura de grade em duas camadas complementares:

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

- **Camada 1 — Vegetação Orgânica em Campo Fino ($0.20\text{m} \times 0.20\text{m}$):**
  - Cada bloco de $0.80\text{m}$ possui $4 \times 4 = 16$ micro-células de $0.20\text{m}$.
  - A pintura de plantas ocorre diretamente no campo analítico `VegetationField`, permitindo traços suaves, curvas detalhadas e formas livres.
  - **Auto-Geração de Terreno:** Ao pintar vegetação sobre células de mar/vazio, o editor gera automaticamente o terreno de ilha de $0.80\text{m}$ correspondente por baixo, com atualização instantânea do auto-tile.
  - **Variedades Suportadas:** 9 tipos de vegetação (`grass_green`, `grass_yellow`, `grass_blue`, `grass_purple`, `grass_white`, `grass_red`, `grass_black`, `wheat` e `flower`).
  - **Entidades e Marcadores:** `rock` (`Layer 4`, mantida na grade discreta) e `cutter_spawn` (posição inicial do robô).

- **Persistência Híbrida JSON v2:**
  - O formato JSON salva a vegetação em bloco analítico compacto `"vegetation": { "res": 0.2, "width": W, "height": H, "rows": [...] }`, reduzindo o tamanho em disco e mantendo suporte automático a carregamento e conversão de mapas legados em formato v1 (`objects`).

---

## 3. Pincéis e Carimbos de Formas Analíticas (`brush_patterns.gd`)

O editor inclui formatos matemáticos com escala ajustável (`1` a `4`), suporte a offsets em passos de $0.20\text{m}$ para vegetação orgânica e preview holográfico em tempo real sobre a grade (`grid_overlay.gd`):
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
| **Girar Tile ($90^\circ$)** | `R` | Alterna a orientação entre $0^\circ, 90^\circ, 180^\circ, 270^\circ$. |
| **Escala do Pincel** | `[` e `]` (ou `Alt + Scroll`) | Diminui ou aumenta o tamanho do carimbo. |
| **Alternar Câmera** | `V` | Alterna entre Visão Isométrica 3D ($56^\circ$) e Visão Top-Down 2D ($86^\circ$). |
| **Mover Câmera (Pan)** | `WASD` / Botão Meio / Botão Direito | Desloca o foco sobre o mapa. |
| **Zoom da Câmera** | `Scroll do Mouse` | Aproxima ou afasta a câmera ($5.5\text{m}$ a $28.0\text{m}$). |
| **Desfazer / Refazer** | `Ctrl + Z` / `Ctrl + Y` | Histórico de até 30 operações. |
| **Salvar Fase (JSON)** | `Ctrl + S` | Grava `res://data/levels/level_%02d.json`. |
| **Playtest In-Editor** | `F1` ou `F5` (e `ESC` p/ sair) | Spawna o robô cortador para teste real e restaura a ilha intacta ao sair. |
