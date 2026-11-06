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
| **01** | *Fase 01* | Quadrado amplo $25 \times 25$ ($10\text{m} \times 10\text{m}$) | $25 \times 25$ | 0 | 🌿 94 Gramas | Tutorial inicial de condução e corte radial com mandala concêntrica verde e amarela. |
| **02** | *Fase 02* | Quadrado amplo $25 \times 25$ ($10\text{m} \times 10\text{m}$) | $25 \times 25$ | 0 | 🌿 118 Gramas | Introdução da grama azul combinada com verde e amarela. |
| **03** | *Fase 03* | Grande ilha agrícola | $29 \times 29$ | 0 | 🌿 124 Gramas<br>🌾 36 Trigos<br>🌸 4 Flores | Estreia do Trigo Maduro (2 hits) e primeiras flores. |
| **04** | *Fase 04* | Grande prado floral | $31 \times 31$ | 0 | 🌿 58 Gramas<br>🌼 52 Margaridas | Estreia da Margarida em grande canteiro nobre. |
| **05** | *Fase 05* | Mega-ilha floral | $47 \times 47$ | 8 Rochas | 🌿 141 Gramas<br>🌹 92 Rosas | Estreia da Rosa (preta e branca) e das primeiras rochas sólidas. |
| **06** | *O Primeiro Rochedo* | Retângulo alongado | $19 \times 11$ | 2 Rochas | 🌿 64 Gramas | 2 rochas sólidas laterais com ampla área de manobra. |
| **07** | *O Triângulo de Pedra* | Octógono | $17 \times 17$ | 3 Rochas | 🌿 73 Gramas | 3 rochas em formação triangular aberta. |
| **08** | *Caminho Dividido* | Ferradura em U | $19 \times 17$ | 2 Rochas | 🌿 85 Gramas<br>🌼 1 Margarida<br>🔔 1 Sino | Estreia da Flor Sino com bifurcação em U. |
| **09** | *Pomar Protegido* | Quadrado chanfrado | $17 \times 17$ | 4 Rochas | 🌿 71 Gramas<br>🌻 2 Girassóis<br>🌷 2 Tulipas | Estreia do Girassol e da Tulipa Real protegidos por pedras. |
| **10** | *O Labirinto de Trigo e Granito* | Labirinto com cruz | $19 \times 19$ | 4 Rochas | 🌿 104 Gramas<br>🌾 16 Trigos | Labirinto de paredes de trigo e 4 rochas nos vértices. |
| **11** | *Ilhotas Conectadas* | Duas ilhas com ponte | $21 \times 13$ | 3 Rochas | 🌿 77 Gramas<br>🔔 4 Sinos | Travessia entre ilhas conectadas por ponte de terra. |
| **12** | *Vulcânica* | Octógono de ardósia | $17 \times 17$ | 4 Rochas | 🌿 72 Gramas<br>🏵️ 4 Corolas | Estreia da Corola Nobre com grama preta e vermelha. |
| **13** | *O Relógio de Quatro Pilares* | Cruz em 4 quadrantes | $19 \times 19$ | 4 Rochas | 🌿 95 Gramas<br>🌹 4 Rosas | 4 quadrantes cardeais com 4 cores de grama e rosas. |
| **14** | *Serpente de Trigo* | Retângulo longo | $21 \times 13$ | 3 Rochas | 🌿 103 Gramas<br>🌾 12 Trigos | Slalom sinuoso contornando a serpente de trigo. |
| **15** | *O Parque Central de Canteiros* | Ilha orgânica chanfrada | $19 \times 17$ | 5 Rochas | 🌿 88 Gramas<br>🪻 6 Canteiros | Estreia do Canteiro Floral em disposição assimétrica. |
| **16** | *O Anel Exterior de Obstáculos*| Anel octogonal | $19 \times 19$ | 6 Rochas | 🌿 83 Gramas<br>🌻 6 Girassóis | Anel perimetral com girassóis e rochas. |
| **17** | *Alameda Imperial* | Ilha em H | $21 \times 17$ | 4 Rochas | 🌿 96 Gramas<br>🌾 8 Trigos<br>🌷 4 Tulipas | Alameda com boulevard central e colunas de trigo. |
| **18** | *O Labirinto dos Quatro Diamantes*| Diamante amplo | $19 \times 19$ | 4 Rochas | 🌿 33 Gramas<br>🌾 4 Trigos<br>🪻 4 Canteiros | Losango concêntrico com canteiros nas pontas. |
| **19** | *O Oásis Multicolorido* | Estrela de 8 pontas | $19 \times 19$ | 5 Rochas | 🌿 83 Gramas<br>🌸 5 Flores | Mandala estelar com 4 cores de grama e flores nobres. |
| **20** | *Arquipélago da Maestria* | Trevo de 4 folhas | $21 \times 21$ | 6 Rochas | 🌿 Grama<br>🌾 2 Trigos<br>🏵️ 2 Corolas<br>🌷 2 Tulipas | Clímax da primeira metade com todas as famílias botânicas. |
| **21** | *O Labirinto da Serpente Dourada*| Retângulo chanfrado (337 tiles)| $23 \times 23$ | 5 Rochas | 🌿 Grama<br>🌾 12 Trigos<br>🔔 6 Sinos | Início das grandes ilhas com listras diagonais e trigo sinuoso. |
| **22** | *O Grande Atol Esmeralda* | Octógono grande (277 tiles) | $23 \times 23$ | 6 Rochas | 🌿 Grama<br>🌼 8 Margaridas<br>🌻 6 Girassóis | Circuito circular com anéis concêntricos. |
| **23** | *As Ilhas Gêmeas de Safira* | Duas grandes ilhas (297 tiles) | $25 \times 21$ | 5 Rochas | 🌿 Grama<br>🌾 8 Trigos<br>🌷 8 Tulipas | Duas grandes massas conectadas por ponte de 5 tiles. |
| **24** | *O Bosque dos Três Canteiros* | Cruz arredondada (301 tiles) | $25 \times 25$ | 6 Rochas | 🌿 Grama<br>🪻 8 Canteiros<br>🌹 6 Rosas | 4 grandes quadrantes floridos. |
| **25** | *A Fortaleza de Granito* | Diamante gigante (221 tiles) | $25 \times 25$ | 7 Rochas | 🌿 Grama<br>🌾 12 Trigos<br>🏵️ 6 Corolas | Losangos concêntricos em degradê de ardósia. |
| **26** | *O Vale das Tulipas Imperiais*| H monumental (343 tiles) | $25 \times 25$ | 6 Rochas | 🌿 Grama<br>🌷 10 Tulipas<br>🌼 6 Margaridas | Avenidas amplas com canteiros de tulipas e margaridas. |
| **27** | *O Grande Lago Interior* | Ilha com lago central (456 tiles)| $27 \times 27$ | 6 Rochas | 🌿 Grama<br>🌾 16 Trigos<br>🌻 8 Girassóis | Anel de terra contornando grande lago de água nobre. |
| **28** | *A Espiral da Colheita* | Octógono monumental (385 tiles)| $27 \times 27$ | 6 Rochas | 🌿 Grama<br>🌾 20 Trigos<br>🔔 8 Sinos | Espiral agrícola concêntrica com muralhas de trigo. |
| **29** | *A Rosa dos Ventos* | Estrela de 8 pontas (397 tiles)| $27 \times 27$ | 6 Rochas | 🌿 Grama<br>🌹 8 Rosas<br>🏵️ 8 Corolas | Mandala monumental de 8 pontas em 4 tonalidades. |
| **30** | *O Arquipélago das Quatro Lagoas*| Trevo gigante (465 tiles) | $27 \times 27$ | 7 Rochas | 🌿 Grama<br>🌾 12 Trigos<br>🪻 6 Canteiros<br>🌻 6 Girassóis | 4 lobos monumentais com flores e gramas vibrantes. |
| **31** | *O Tridente Coralino* | 3 penínsulas ao norte (529 tiles)| $29 \times 29$ | 6 Rochas | 🌿 Grama<br>🔔 8 Sinos<br>🌷 8 Tulipas | Navegação em tridente com 3 longas avenidas marítimas. |
| **32** | *O Jardim Suspenso da Falésia*| Quadrado chanfrado (585 tiles)| $29 \times 29$ | 7 Rochas | 🌿 Grama<br>🪻 10 Canteiros<br>🌼 8 Margaridas | Amplo platô com canteiros floridos e margaridas. |
| **33** | *O Enclave dos Monólitos* | Octógono monumental (445 tiles)| $29 \times 29$ | 8 Rochas | 🌿 Grama<br>🌾 16 Trigos<br>🌹 8 Rosas | Círculo amplo de 8 monólitos e rosas nobres. |
| **34** | *O Mosaico Imperial* | Cruz monumental (433 tiles) | $29 \times 29$ | 7 Rochas | 🌿 Grama<br>🏵️ 8 Corolas<br>🌷 8 Tulipas | Cruz monumental com anéis concêntricos. |
| **35** | *A Encruzilhada das Quatro Estações*| 4 grandes ilhas (661 tiles) | $31 \times 31$ | 8 Rochas | 🌿 Grama<br>🌾 12 Trigos<br>🌻 6 Girassóis<br>🌹 6 Rosas<br>🌷 6 Tulipas | 4 quadrantes representando as 4 estações. |
| **36** | *O Labirinto dos Guardiões* | Mega-ilha com muralhas (689 tiles)| $31 \times 31$ | 8 Rochas | 🌿 Grama<br>🌾 24 Trigos<br>🪻 8 Canteiros | Labirinto de grande escala com muralhas de trigo. |
| **37** | *A Coroa de Ilhotas* | Ilha central + 4 satélites (461 tiles)| $31 \times 31$ | 8 Rochas | 🌿 Grama<br>🔔 8 Sinos<br>🌼 8 Margaridas | Núcleo octogonal com 4 ilhotas conectadas por istmos. |
| **38** | *O Grande Fiorde Selvagem* | Sinuoso em S longo (653 tiles)| $31 \times 31$ | 8 Rochas | 🌿 Grama<br>🌾 20 Trigos<br>🏵️ 10 Corolas | Fiorde oceânico largo com atmosfera vulcânica. |
| **39** | *O Santuário Botânico* | Estrela monumental (509 tiles)| $31 \times 31$ | 8 Rochas | 🌿 Grama<br>🌹 6 Rosas<br>🌻 6 Girassóis<br>🌷 6 Tulipas<br>🪻 6 Canteiros | Santuário com as 4 principais famílias de flores nobres. |
| **40** | *O Grande Arquipélago Mestre* 👑| Mega-arquipélago de 5 ilhas (513 tiles)| $31 \times 31$ | 8 Rochas | 🌿 Grama<br>🌾 16 Trigos<br>🌹 6 Rosas<br>🌷 6 Tulipas<br>🌻 6 Girassóis<br>🌼 6 Margaridas | **Clímax supremo do Mundo 1:** 5 grandes ilhas unidas por praças monumentais e as 6 metas canônicas. |

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
