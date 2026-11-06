# Estrutura das Fases e Level Design 🗺️🌱

Este documento detalha o desenho dos estágios, a arquitetura de dados JSON v4, a progressão de dificuldade, a curva de aprendizado e o catálogo oficial das **40 fases canônicas** em **Grass Cut Bot**, correspondentes ao **Mundo 1: Ilhas Tropicais (O Grande Arquipélago)**.

---

## 1. Filosofia de Level Design Hiper-Casual

1. **Sessões Rápidas e Dinâmicas (1 a 3 Minutos):**
   - Os estágios foram projetados para conclusão ágil durante pequenos intervalos diários no mobile (sessões *one-thumb*).
2. **Escalonamento Geográfico Gradual:**
   - As ilhas começam compactas e acolhedoras (~25 a 35 tiles nas primeiras fases) e escalonam de forma suave até mega-ilhas de até **100 tiles** nos estágios finais, aproveitando a câmera isométrica contínua com amortecimento suave.
3. **Cores de Grama Estéticas & Meta Unificada Limpa:**
   - O solo é enriquecido com mandalas, mosaicos, anéis e faixas em 7 cores estéticas (`grass_green`, `grass_yellow`, `grass_blue`, `grass_purple`, `grass_white`, `grass_red`, `grass_black`).
   - Todas as aparas de grama cortadas abatem uma **única meta unificada de grama 🌿 (`"grass"`)** no HUD.
   - O Top HUD permanece limpo e legível na proporção vertical 9:16, variando entre **1 e no máximo 6 objetivos simultâneos** mesmo no clímax final.
4. **Introdução Consciente de Rochas Sólidas:**
   - As **Fases 1, 2 e 3 são 100% livres de obstáculos rígidos**, garantindo foco na fluidez do joystick e no corte relaxante.
   - A primeira rocha (`rock`) estreia na **Fase 4**, com introdução progressiva de 1 a 10 rochas por ilha.
   - O espaçamento centro a centro entre quaisquer duas rochas adjacentes obedece estritamente ao raio de passagem seguro ($> 2.80\text{m}$).
5. **Zero Cercas & Ilhas Flutuantes 3D:**
   - Todas as fases são ilhas estilizadas sobre o oceano azul turquesa contínuo (`water_ocean.tscn`), com contenção invisível costeira (`Layer 1`) e espuma decorativa dinâmica gerada pelo `LevelJsonLoader`.

---

## 2. A Matriz Oficial das 40 Fases Canônicas (Mundo 1)

Todas as 40 fases residem em formato canônico JSON v4 na pasta `res://data/levels/level_%02d.json`:

| Fase | Nome Temático | Silhueta da Ilha | Grid ($W \times H$) | Qtd. Rochas | Metas do HUD | Foco e Progressão de Design |
| :---: | :--- | :--- | :---: | :---: | :--- | :--- |
| **01** | *Primeiros Passos* | Quadrado suave $5 \times 5$ | $11 \times 11$ | 0 | 🌿 Grama | Tutorial inicial de condução e corte radial básico. |
| **02** | *O Prado Dourado* | Quadrado chanfrado | $13 \times 13$ | 0 | 🌿 Grama | Faixas diagonais estéticas verde e amarela. |
| **03** | *O Primeiro Trigal* | Cruz com canteiros | $13 \times 13$ | 0 | 🌿 Grama<br>🌾 4 Trigos | Estreia do Trigo Maduro rígido (2 hits). |
| **04** | *O Canteiro de Margaridas* | Octógono suave | $13 \times 13$ | **1 Rocha** | 🌿 Grama<br>🌼 2 Margaridas | **Estreia da 1ª Rocha** e da Margarida (3 hits). |
| **05** | *A Enseada dos Sinos* | Ferradura compacta | $15 \times 15$ | 2 Rochas | 🌿 Grama<br>🌾 2 Trigos<br>🔔 2 Sinos | Estreia da Flor Sino com navegação em U. |
| **06** | *O Jardim das Rosas* | Retângulo alongado | $17 \times 11$ | 2 Rochas | 🌿 Grama<br>🌹 4 Rosas | Estreia da Rosa Nobre em canteiros laterais. |
| **07** | *Colina dos Girassóis* | Octógono amplo | $15 \times 15$ | 3 Rochas | 🌿 Grama<br>🌾 2 Trigos<br>🌻 3 Girassóis | Estreia do Girassol e rochas triangulares. |
| **08** | *Brisa das Tulipas* | Duas ilhas com ponte | $19 \times 13$ | 3 Rochas | 🌿 Grama<br>🌷 2 Tulipas<br>🌼 2 Margaridas | Estreia da Tulipa Real sobre ponte de terra. |
| **09** | *Círculo das Corolas* | Estrela de 6 pontas | $17 \times 17$ | 3 Rochas | 🌿 Grama<br>🌾 2 Trigos<br>🏵️ 3 Corolas | Estreia da Corola Nobre com grama roxa. |
| **10** | *O Parque de Canteiros* | Cruz arredondada | $17 \times 17$ | 4 Rochas | 🌿 Grama<br>🪻 4 Canteiros<br>🌹 2 Rosas | Estreia do Canteiro Floral (Hortênsia). |
| **11** | *As Ilhas Gêmeas* | Istmo central duplo | $21 \times 15$ | 3 Rochas | 🌿 Grama<br>🌼 2 Margaridas<br>🔔 2 Sinos | Travessia marítima entre duas grandes baías. |
| **12** | *Serpente de Trigo* | Sinuoso em "S" | $21 \times 15$ | 4 Rochas | 🌿 Grama<br>🌾 3 Trigos<br>🌹 2 Rosas | Slalom longo contornando paredes de rocha e trigo. |
| **13** | *O Relógio de Granito* | 4 quadrantes cardeais | $19 \times 19$ | 4 Rochas | 🌿 Grama<br>🌻 2 Girassóis<br>🌷 2 Tulipas | Setorização cromática e rochas nas diagonais. |
| **14** | *Baía da Ferradura* | Ferradura ampla | $21 \times 19$ | 4 Rochas | 🌿 Grama<br>🌾 2 Trigos<br>🏵️ 2 Corolas | Manobras nas pontas da falésia sobre o mar. |
| **15** | *Cruz dos Quatro Ventos* | Cruz monumental | $21 \times 21$ | 4 Rochas | 🌿 Grama<br>🪻 2 Canteiros<br>🔔 2 Sinos | Canteiros nobres nas extremidades dos 4 braços. |
| **16** | *O Trevo Imperial* | Trevo de 4 folhas | $21 \times 21$ | 5 Rochas | 🌿 Grama<br>🌾 2 Trigos<br>🌹 2 Rosas<br>🌷 2 Tulipas | Alta diversidade com 4 folhas floridas. |
| **17** | *Canal das Margaridas* | Lagoa central vazada | $21 \times 17$ | 5 Rochas | 🌿 Grama<br>🌼 4 Margaridas<br>🪻 1 Canteiro | Navegação ao redor de canal de água interno. |
| **18** | *Labirinto Solar* | Labirinto com anel | $21 \times 21$ | 6 Rochas | 🌿 Grama<br>🌾 2 Trigos<br>🌻 3 Girassóis | Paredes densas de granito e trigo dourado. |
| **19** | *Península Vulcânica* | Octógono de ardósia | $21 \times 21$ | 6 Rochas | 🌿 Grama<br>🏵️ 2 Corolas<br>🌹 2 Rosas | Atmosfera dramática com grama preta e vermelha. |
| **20** | *O Primeiro Grande Atol* | Anel oceânico fechado | $23 \times 23$ | 6 Rochas | 🌿 Grama<br>🌾 2 Trigos<br>🌷 2 Tulipas<br>🔔 1 Sino | Clímax do meio do jogo em circuito circular. |
| **21** | *Três Marias* | 3 ilhas com pontes | $25 \times 15$ | 6 Rochas | 🌿 Grama<br>🌾 2 Trigos<br>🌼 1 Margarida<br>🔔 1 Sino | Deslocamento tático entre 3 ilhas consecutivas. |
| **22** | *Boulevard de Outono* | Avenida central larga | $23 \times 19$ | 6 Rochas | 🌿 Grama<br>🌹 4 Rosas<br>🪻 2 Canteiros | Grande alameda floral de alta velocidade. |
| **23** | *A Fortaleza de Trigo* | Bastilha fortificada | $23 \times 21$ | 7 Rochas | 🌿 Grama<br>🌾 2 Trigos<br>🌻 2 Girassóis | Muralhas externas com núcleo de girassóis. |
| **24** | *Ilha do Zigue-Zague* | Slalom diagonal | $23 \times 17$ | 7 Rochas | 🌿 Grama<br>🌷 3 Tulipas<br>🏵️ 1 Corola | Curvas rápidas exigindo controle fino do joystick. |
| **25** | *O Vale das Quatro Flores*| Trevo de 4 espécies | $23 \times 23$ | 7 Rochas | 🌿 Grama<br>🌼 1 Marg.<br>🔔 1 Sino<br>🌹 1 Rosa<br>🌻 1 Gir. | 5 objetivos independentes nos 4 quadrantes. |
| **26** | *O Grande Diamante* | Losango monumental | $23 \times 23$ | 7 Rochas | 🌿 Grama<br>🌾 2 Trigos<br>🏵️ 2 Corolas<br>🪻 2 Canteiros | Desafio nas arestas pontiagudas do diamante. |
| **27** | *Arquipélago do Sol* | Ilha solar + 4 satélites | $25 \times 25$ | 8 Rochas | 🌿 Grama<br>🌾 2 Trigos<br>🌻 2 Girassóis<br>🌷 2 Tulipas | Núcleo solar com satélites de vegetação. |
| **28** | *Caminhos Cruzados* | Tabuleiro quadriculado | $23 \times 23$ | 8 Rochas | 🌿 Grama<br>🌹 2 Rosas<br>🔔 2 Sinos<br>🪻 2 Canteiros | Mosaico de trilhas de terra com rochas alternadas. |
| **29** | *O Santuário Esmeralda* | Anéis concêntricos | $23 \times 23$ | 8 Rochas | 🌿 Grama<br>🌾 2 Trigos<br>🌷 2 Tulipas<br>🏵️ 2 Corolas | Concentração de culturas nobres no centro. |
| **30** | *A Cidadela Costeira* | Fortaleza com bastiões | $25 \times 23$ | 8 Rochas | 🌿 Grama<br>🌾 2 Trigos<br>🌹 2 Rosas<br>🌻 2 Girassóis | Transição para as mega-ilhas com bastiões costeiros. |
| **31** | *O Labirinto de Minos* | Labirinto de 94 tiles | $25 \times 23$ | 8 Rochas | 🌿 Grama<br>🌾 2 Trigos<br>🌼 2 Margaridas<br>🪻 2 Canteiros | Extensa área exploratória com corredores amplos. |
| **32** | *Arquipélago em H* | Duas ilhas monumentais | $25 \times 23$ | 8 Rochas | 🌿 Grama<br>🌾 2 Trigos<br>🔔 2 Sinos<br>🌷 2 Tulipas | Conexão por passadiço triplo de alta densidade. |
| **33** | *O Grande Trevo Dourado*| Trevo de 96 tiles | $25 \times 25$ | 9 Rochas | 🌿 Grama<br>🌻 2 Girassóis<br>🌹 2 Rosas<br>🏵️ 2 Corolas | Pétalas monumentais com canteiros nobres. |
| **34** | *O Dragão dos Mares* | Silhueta em "S" gigante | $25 \times 23$ | 9 Rochas | 🌿 Grama<br>🌾 2 Trigos<br>🪻 2 Canteiros<br>🌷 2 Tulipas | Extensão máxima com curva contínua sobre o mar. |
| **35** | *O Tabuleiro dos Titãs* | Tabuleiro monumental | $25 \times 25$ | 9 Rochas | 🌿 Grama<br>🌾 2 Trigos<br>🌹 2 Rosas<br>🌼 1 Marg.<br>🔔 1 Sino | Desafio tático com 5 metas simultâneas. |
| **36** | *Oásis dos Cinco Reinos* | Estrela octogonal real | $25 \times 25$ | 10 Rochas | 🌿 Grama<br>🌹 1 Rosa<br>🌻 1 Gir.<br>🌷 1 Tul.<br>🏵️ 1 Cor. | Todas as espécies de flores nobres distribuídas. |
| **37** | *O Grande Atol Imperial* | Lagoa oceânica gigante | $25 \times 25$ | 8 Rochas | 🌿 Grama<br>🌾 2 Trigos<br>🪻 2 Canteiros<br>🔔 2 Sinos | Mega-circuito circular de alta velocidade. |
| **38** | *Constelação de Pedra* | Octógono monumental | $25 \times 25$ | 10 Rochas | 🌿 Grama<br>🌾 2 Trigos<br>🌻 2 Girassóis<br>🏵️ 2 Corolas | Campo de manobra entre 10 rochas e muito trigo. |
| **39** | *A Península do Infinito*| Símbolo do infinito $\infty$ | $25 \times 23$ | 10 Rochas | 🌿 Grama<br>🌾 2 Trigos<br>🌹 1 Rosa<br>🌷 1 Tulipa<br>🪻 2 Cant. | Travessia rápida em oito duplo sobre as águas. |
| **40** | *A Grande Coroa Real* 👑| **100 tiles exatos** | $25 \times 23$ | 4 Rochas | 🌿 Grama<br>🌾 2 Trigos<br>🌹 1 Rosa<br>🌻 1 Gir.<br>🌷 1 Tul.<br>🏵️ 1 Cor. | **Clímax supremo do Mundo 1:** As 6 metas canônicas e passagem triunfal para o Ciclo Mestre. |

---

## 3. Progressão de 4 Grandes Tiers do Mundo 1

1. **Tier 1 (Fases 01 a 10) — O Despertar do Cortador (~25 a ~48 tiles):**
   - Apresentação passo a passo do robô, joystick, trigo resistente (2 hits) e introdução individual de cada flor nobre.
   - 0 rochas até a Fase 3; 1ª rocha introduzida na Fase 4.
2. **Tier 2 (Fases 11 a 20) — Istmos, Pontes e Navegação Tática (~50 a ~66 tiles):**
   - Ilhas em U, H e passadiços sobre o mar azul.
   - Combinações ricas de 2 a 4 espécies botânicas e posicionamento tático de obstáculos.
3. **Tier 3 (Fases 21 a 30) — O Grande Arquipélago e Labirintos (~70 a ~85 tiles):**
   - Áreas amplas de corte e labirintos agrícolas, tornando vantajosos os upgrades de Raio e Potência da lâmina na Oficina.
4. **Tier 4 (Fases 31 a 40) — As Mega-Ilhas e a Maestria Suprema (~88 a 100 tiles):**
   - O ápice de escala do Mundo 1 com as maiores ilhas do jogo, terminando na monumental *Grande Coroa Real* (Fase 40).

---

## 4. Arquitetura Técnica e Scripts

- **Carregamento Runtime (`LevelController.gd` + `VegetationGrid.gd`):**
  - Carrega dinamicamente qualquer arquivo `res://data/levels/level_%02d.json` de 1 a 40.
  - O `VegetationGrid` instancia os tufos via `MultiMeshInstance3D` e grades espaciais discretas de $0.40\text{m}$, mantendo **60 FPS estáveis** mesmo em ilhas de 100 tiles.
- **Suporte Nativo a Metas Unificadas (`VegetationGrid.gd`):**
  - Quando a meta do HUD é `"grass"`, ceifar qualquer tufo de qualquer cor cosmética credita automaticamente o corte para a meta única de grama.
- **Detecção Automática no Hub (`main_menu.gd`):**
  - O mapa 3D do arquipélago escaneia dinamicamente até 100 fases, instanciando automaticamente todas as 40 ilhas em ziguezague com scroll vertical e teleporte.
- **Gerador Headless Canônico (`scripts/tools/generate_all_40_levels.gd`):**
  - Gera e audita todas as 40 fases com 0 erros de conformidade geométrica.
