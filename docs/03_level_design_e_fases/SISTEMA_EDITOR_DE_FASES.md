# Sistema do Editor de Fases In-Game para PC (Ilhas 3D) 🏝️🛠️🌿

Este documento descreve a arquitetura, ferramentas, controles e fluxo de persistência do **Editor de Fases In-Game**, projetado para operar em **tela cheia no PC** (`1920x1080`) sem ser compilado nos pacotes de exportação mobile (Android).

---

## 1. Visão Geral e Filosofia de Design

1. **Execução Exclusiva em Desktop (Tela Cheia):**
   - Acessível diretamente via **F6** na cena `res://scenes/editor/level_editor.tscn` ou pelo atalho **`F2` / botão `🛠️ Editor [F2]`** na tela principal quando executado no PC.
   - Reconfigura dinamicamente a `Window` para `1920x1080` (`CONTENT_SCALE_ASPECT_EXPAND`) e `WINDOW_MODE_FULLSCREEN`, retornando automaticamente ao formato portrait mobile (`450x800` / `720x1280` `KEEP_WIDTH`) ao voltar ao jogo.
2. **Ilhas 3D Modulares sobre o Oceano (Zero Cercas):**
   - Os níveis são construídos como ilhas 3D sobre um oceano azul turquesa contínuo (`water_ocean.tscn`).
   - Cada bloco de ilha ($0.80\text{m} \times 0.80\text{m}$) possui topo de grama verde, paredão/falésia marrom escuro nas bordas costeiras e faixa de espuma clara na água.
   - **Contenção Invisível (`Layer 1`):** As faces voltadas para a água recebem colisores invisíveis na beira do barranco (`LevelJsonLoader.build_coastal_colliders_and_foam()`), impedindo que o cortador caia no mar sem necessidade de cercas visuais.
3. **Desacoplamento de Dados em JSON (`res://data/levels/level_XX.json`):**
   - Os mapas são salvos em arquivos JSON limpos e leves na pasta `res://data/levels/`.
   - O carregador runtime (`scripts/level/level_json_loader.gd`) reside em `scripts/level/`, permitindo que o APK mobile carregue os arquivos `.json` mesmo quando `scenes/editor/*` e `scripts/editor/*` são excluídos na exportação.

---

## 2. Camadas do Grid ($0.80\text{m} \times 0.80\text{m}$)

- **Camada 0 — Terreno (Ilha 3D):**
  - `auto_island`: Pincel inteligente Auto-Tile (`island_autotiler.gd`) que escolhe e rotaciona sozinho entre `island_center`, `island_edge`, `island_corner_out` e `island_corner_in`.
  - Peças manuais com suporte a giro de $90^\circ$ (`R`): `island_center`, `island_dirt`, `island_edge`, `island_corner_out`, `island_corner_in`.
- **Camada 1 — Objetos & Vegetação:**
  - 6 variações de plantas: `grass_green`, `grass_yellow`, `grass_blue`, `grass_purple`, `wheat` e `flower`.
  - Obstáculos e Marcadores: `rock` (`Layer 4`) e `cutter_spawn` (único por fase).

---

## 3. Pincéis e Carimbos de Formas (`brush_patterns.gd`)

O editor inclui 7 formatos matemáticos de pincel com escala ajustável (`1` a `4`) e preview holográfico em tempo real sobre a grade (`grid_overlay.gd`):
- `⏺️ Único (1x1)`
- `⬛ Quadrado`
- `⚪ Círculo`
- `🔶 Losango`
- `❤️ Coração` (Matrizes $5\times5$, $7\times7$ e $9\times9$)
- `⭐ Estrela` (Matrizes $5\times5$, $7\times7$ e $9\times9$)
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
