# Estrutura das Fases e Level Design 🗺️🌱

Este documento detalha o desenho dos estágios, a arquitetura de dados JSON v4, a progressão de dificuldade, a curva de aprendizado e o catálogo oficial das **40 fases canônicas** em **Grass Cut Bot**, correspondentes ao **Mundo 1: Ilhas Tropicais (O Grande Arquipélago)**.

---

## 1. Filosofia de Level Design Hiper-Casual

1. **Sessões Rápidas e Dinâmicas (1 a 3 Minutos):**
   - Os estágios foram projetados para conclusão ágil durante pequenos intervalos diários no mobile (sessões *one-thumb*).
2. **Escalonamento Geográfico Gradual:**
   - As ilhas mantêm a amplitude consagrada do jogo clássico (Fases 1 a 5 com grids de $25 \times 25$ a $47 \times 47$, 606 a 1.592 tiles; Fases 6 a 20 com 105 a 225 tiles) e escalonam de forma expansiva nas Fases 21 a 40 em grandes ilhas e mega-ilhas de **221 a 689 tiles** ($15.2\text{m} \times 15.2\text{m}$ até $21.6\text{m} \times 21.6\text{m}$), aproveitando a câmera isométrica contínua com amortecimento suave.
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
| **40** | *O Grande Arquipélago Mestre* 👑| Mega-arquipélago de 5 ilhas (513 tiles)| $31 \times 31$ | 8 Rochas | 🌿 Grama<br>🌾 16 Trigos<br>🌹 6 Rosas<br>🌷 6 Tulipas<br>🌻 6 Girassóis<br>🌼 6 Margaridas | **Clímax do Tier 4:** 5 grandes ilhas unidas por praças monumentais e as 6 metas canônicas. |
| **41** | *O Prado das Margaridas Silvestres* | Ilha chanfrada (505 tiles) | $27 \times 27$ | 6 Rochas | 🌿 Grama Verde/Amarela<br>🌼 8 Margaridas Bicolor<br>🌸 8 Margaridas Rosa | Listras diagonais e introdução das variações de margarida silvestre no Herbário. |
| **42** | *O Istmo das Tulipas Roxas* | H estilizado com istmo largo (445 tiles) | $27 \times 27$ | 6 Rochas | 🌿 Grama Púrpura/Azul/Verde<br>🌾 12 Trigos<br>🌷 10 Tulipas Roxas | Travessia tática entre blocos laterais com cultivo de trigo no istmo. |
| **43** | *O Jardim dos Pêssegos e Alabastro* | Octógono elegante (385 tiles) | $27 \times 27$ | 7 Rochas | 🌿 Grama Amarela/Branca/Verde<br>🧡 8 Rosas Pêssego<br>🤍 8 Rosas Brancas | Anéis concêntricos de grama e rosas nobres em tons pastéis. |
| **44** | *O Arquipélago Solar Duplo* | Duas ilhas com ponte larga (471 tiles) | $29 \times 25$ | 7 Rochas | 🌿 Grama Amarela/Verde/Branca<br>🌻 8 Girassóis<br>🤍 8 Canteiros Brancos | Ilhas gêmeas conectadas por ponte dupla de 5 tiles com rochas estratégicas. |
| **45** | *O Castelo das Pétalas Escuras* | Cruz grega arredondada (433 tiles) | $29 \times 29$ | 7 Rochas | 🌿 Grama Negra/Vermelha/Púrpura<br>🍷 8 Rosas Vinho<br>🖤 8 Rosas Negras<br>🌾 12 Trigos | Cruz monumental com flora escura e portais defensivos de trigo. |
| **46** | *O Grande Atol da Alvorada* | Atol com lago central vazado (536 tiles) | $29 \times 29$ | 8 Rochas | 🌿 Grama Amarela/Verde<br>🌷 8 Tulipas Laranja<br>🌼 8 Margaridas Laranja<br>🌾 12 Trigos | Lago interior vazado (7x7) exigindo contorno orbital contínuo. |
| **47** | *O Tridente do Oceano Safira* | Base sul + 3 pontas norte (585 tiles) | $31 \times 31$ | 8 Rochas | 🌿 Grama Azul/Branca/Púrpura/Verde<br>💙 8 Canteiros Azuis<br>💙 8 Rosas Azuis<br>🌷 6 Tulipas Roxas | Navegação em 3 penínsulas compridas com variedades azuis e roxas. |
| **48** | *A Cidadela de Rubi e Trigo* | Diamante com praça central (365 tiles) | $31 \times 31$ | 8 Rochas | 🌿 Grama Vermelha/Amarela/Verde<br>🌾 24 Trigos<br>❤️ 10 Margaridas Vermelhas | Muralha circular concêntrica de 24 trigos protegendo o núcleo rubi. |
| **49** | *O Trevo dos Ventos Cromáticos* | Trevo de 4 folhas amplo (441 tiles) | $31 \times 31$ | 8 Rochas | 🌿 Grama 4 Cores + Branca<br>💎 6 Flores Turquesa<br>🌅 6 Flores Pôr do Sol<br>💛 6 Tulipas Amarelas<br>💛 6 Margaridas Amarelas | Quatro lóbulos temáticos liberando espécies cromáticas raras do Herbário. |
| **50** | *A Coroa Imperial da Mãe Natureza* 👑 | Estrela de 8 pontas imperial (521 tiles) | $31 \times 31$ | 8 Rochas | 🌿 Grama 5 Cores<br>🌾 16 Trigos<br>🌻 6 Girassóis<br>🧡 6 Rosas Pêssego<br>🍷 6 Rosas Vinho<br>🌷 6 Tulipas Roxas<br>🌷 6 Tulipas Laranja | **Clímax do Tier 5:** Mandala estelar de 8 pontas reunindo 11 metas botânicas distintas. |

---

## 3. Progressão em Tiers e Horizonte Canônico de 100 Fases (Mundo 1)

1. **Tier 1 (Fases 01 a 10) — O Despertar do Cortador:**
   - Apresentação passo a passo do robô, joystick, trigo resistente (2 hits) e introdução individual de cada flor nobre.
   - Escala original ampla (Fase 1 com 625 tiles, $10\text{m} \times 10\text{m}$). 0 rochas até a Fase 3; 1ª rocha introduzida na Fase 4.
2. **Tier 2 (Fases 11 a 20) — Istmos, Pontes e Navegação Tática (105 a 225 tiles):**
   - Ilhas em U, H e passadiços sobre o mar azul ($13.6\text{m}$ a $16.8\text{m}$).
   - Combinações ricas de 2 a 4 espécies botânicas e posicionamento tático de obstáculos sólidos.
3. **Tier 3 (Fases 21 a 30) — O Grande Arquipélago e Labirintos (221 a 465 tiles):**
   - Áreas amplas de corte e labirintos agrícolas ($15.2\text{m} a $18.4\text{m}$ com `cell_size = 0.80m`), tornando indispensáveis os upgrades de Raio e Potência da lâmina na Oficina.
4. **Tier 4 (Fases 31 a 40) — As Mega-Ilhas e a Maestria Suprema (433 a 689 tiles):**
   - O ápice de escala do primeiro bloco do Mundo 1 com as maiores ilhas do jogo ($20.0\text{m}$ a $21.6\text{m}$), finalizando no *Grande Arquipélago Mestre* (Fase 40).
5. **Tier 5 (Fases 41 a 50) — Expansão Botânica do Herbário (365 a 585 tiles):**
   - Arquipélagos de 21.6m a 24.8m com cantos arredondados nativos (`corner_radius = 0.28`), lagos vazados e introdução gradual das variações ricas do Herbário (Margaridas Bicolor/Rosa/Laranja/Vermelha/Amarela, Tulipas Roxas/Laranja/Amarelas, Rosas Pêssego/Branca/Vinho/Negra/Azul, Canteiros Branco/Azul e Flores Turquesa/Pôr do Sol).
6. **Roteiro Canônico de Expansão (Fases 51 a 100 do Mundo 1):**
   - O Mundo 1 (Ilhas Tropicais Diurnas) compreenderá exatamente **100 fases autorais, criadas, balanceadas e revisadas**.
   - **Sem variantes atmosféricas no mesmo mundo:** Toda a progressão do Mundo 1 ocorre na ambientação diurna tropical clássica (sol a pino, mar turquesa e céu ciano limpo).
   - **Regra Canônica de Transição:** As variações de horário/atmosfera constituem mundos próprios. O **Mundo 2 (Sunset / Ilhas do Entardecer Dourado)** será criado **exclusivamente após atingir 100 fases criadas e revisadas no Mundo 1**. Seguido posteriormente pelo **Mundo 3 (Noite Tropical / Night World)** após 100 fases no Mundo 2.

---

## 4. Arquitetura Técnica e Scripts

- **Carregamento Runtime (`LevelController.gd` + `VegetationGrid.gd`):**
  - Carrega dinamicamente qualquer arquivo `res://data/levels/level_%02d.json` de 1 a 50 (com suporte arquitetural até 100).
  - O `VegetationGrid` instancia os tufos via `MultiMeshInstance3D` e grades espaciais discretas, mantendo **60 FPS estáveis**.
- **Detecção Automática no Hub (`main_menu.gd`):**
  - O mapa 3D do arquipélago escaneia dinamicamente até 100 fases, instanciando automaticamente todas as 50 ilhas em ziguezague com scroll vertical e teleporte.
- **Gerador Headless Canônico (`scripts/tools/generate_procedural_levels.gd`) & Smoke Test (`verify_levels_integrity.gd`):**
  - Gera e audita as fases de expansão mantendo imutabilidade das fases anteriores e validando 100% de integridade das 50 fases.
