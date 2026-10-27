# Estrutura das Fases e Level Design 🗺️🌱

Este documento detalha o desenho dos estágios, a arquitetura de dados JSON, a progressão de dificuldade, a curva de aprendizado e o catálogo oficial das **primeiras 20 fases** em **Grass Cut Bot**.

---

## 1. Filosofia de Level Design Hiper-Casual

1. **Sessões Rápidas (1 a 2 Minutos):**
   - Os estágios são projetados para conclusão ágil durante pequenos intervalos diários no mobile.
2. **Crescimento Gradual de Complexidade:**
   - O jogador começa focado puramente na sensação do corte e na mecânica do joystick. Elementos de desafio cognitivo (evitar pedras, desviar de cotovelos de água, priorizar metas de colheita e trigo resistente de 2 hits) são introduzidos passo a passo.
3. **Gratificação Imediata:**
   - A distribuição de plantas garante fluxo contínuo de cortes, sem áreas vazias excessivas que quebrem o ritmo do jogo.
4. **Zero Cercas & Ilhas Flutuantes 3D:**
   - Todas as fases são ilhas estilizadas sobre o oceano azul turquesa contínuo (`water_ocean.tscn`), com contenção invisível costeira (`Layer 1`) e espuma decorativa dinâmica gerada pelo `LevelJsonLoader`.

---

## 2. A Matriz Oficial das 20 Fases Canônicas

Todas as 20 fases residem em formato canônico JSON na pasta `res://data/levels/level_%02d.json` e são carregadas dinamicamente com prioridade 1 pelo `LevelController`:

### Parâmetros Técnicos de Dimensionamento Invariantes
* **Spawn Seguro Central:** Área circular central com raio livre $R \ge 1.47\text{m}$ ($1.05 \times \text{raio da lâmina nível 6}$ de $1.40\text{m}$). O miolo inicial permanece 100% livre de qualquer obstáculo rígido (`rock`, `wheat`, `flower_*`).
* **Espaçamento entre Rochas:** Distância mínima centro a centro entre duas rochas sempre superior a $2.80\text{m}$ ($> 2 \times \text{raio da lâmina nível 6}$), garantindo passagem folgada mesmo com o maior alcance de corte.
* **Regra de Desbloqueio de Obstáculos:** As **Fases 1 a 5** contêm estritamente 0 rochas (apenas vegetações e flores). As rochas sólidas (`rock`) são introduzidas progressivamente a partir da **Fase 6**.

| Fase | Nome Temático | Silhueta / Geometria da Ilha | Grid ($W \times H$) | Tipos de Vegetação | Qtd. Rochas | Metas do HUD | Tempo | Lição / Foco de Design |
| :---: | :--- | :--- | :---: | :--- | :---: | :--- | :---: | :--- |
| **01** | *Boas-Vindas ao Jardim* | Quadrado suave $12 \times 12$ | $12 \times 12$ | `grass_green` + `grass_yellow` | 0 | 🌿 44 Gramas | 75s | Tutorial de corte básico; ceifa instantânea e movimentação fluida. |
| **02** | *O Prado Bicolor* | Quadrado chanfrado $14 \times 14$ | $14 \times 14$ | `grass_green` + `yellow` + `blue` | 0 | 🌿 25 Gramas | 80s | Diferenciação visual com faixas diagonais e estrelas nas quinas. |
| **03** | *Introdução à Resistência* | Ilha quadrada com cruz `island_dirt` | $14 \times 14$ | `grass_green` + `wheat` | 0 | 🌿 50 Gramas<br>🌾 26 Trigos | 85s | Primeiro contato com trigo rígido (2 hits, tremor mecânico). |
| **04** | *O Jardim Nobre* | Octógono regular $14 \times 14$ | $14 \times 14$ | `grass_blue` + `purple` + `daisy` + `bell` | 0 | 🌿 59 Gramas<br>🌸 23 Flores | 90s | Flores nobres de 3 hits (+5 moedas) e despetalação progressiva. |
| **05** | *Mandala Floral Mista* | Cruz arredondada ampla $16 \times 16$ | $16 \times 16$ | `white` + `green` + `wheat` + `rose` + `sunflower` | 0 | 🌿 78 Gramas<br>🌾 28 Trigos<br>🌸 6 Flores | 100s | Clímax do primeiro mundo sem rochas; resistência mista. |
| **06** | *O Primeiro Rochedo* | Retângulo alongado $18 \times 10$ | $18 \times 10$ | `grass_green` + `grass_yellow` | 2 | 🌿 89 Gramas | 90s | Primeira aparição de rochas (Layer 8); choque, faíscas e recuo de 4.75 m/s. |
| **07** | *O Triângulo de Pedra* | Plataforma hexagonal $16 \times 14$ | $16 \times 14$ | `grass_blue` + `grass_white` | 3 | 🌿 76 Gramas | 90s | Navegação entre 3 rochas triangulares abertas ao redor do spawn. |
| **08** | *Caminho Dividido* | Formato de U bifurcado (`island_end`) | $18 \times 16$ | `green` (centro) + `purple` + `red` | 2 | 🌿 76 Gramas | 95s | Penínsulas gêmeas; rochas nas entradas com vão central generoso. |
| **09** | *Pomar Protegido* | Quadrado com cantos recortados | $16 \times 16$ | `yellow` + `flower_tulip` + `sunflower` | 4 | 🌿 69 Gramas<br>🌸 13 Flores | 100s | Coleta de flores raras cercadas por anel de rochas protetoras. |
| **10** | *O Labirinto de Trigo e Granito* | Ilha quadrada com trilhas de terra | $18 \times 18$ | `grass_yellow` + `wheat` | 4 | 🌿 154 Gramas<br>🌾 52 Trigos | 110s | Labirinto híbrido: paredes temporárias de trigo e pilares de granito. |
| **11** | *Ilhotas Conectadas* | Duas ilhas unidas por istmo largo | $20 \times 12$ | `grass_blue` + `flower_bell` | 3 | 🌿 55 Gramas<br>🌸 11 Flores | 105s | Precisão de alinhamento ao cruzar o istmo sobre o oceano. |
| **12** | *Vulcânica* | Círculo irregular com falésias | $16 \times 16$ | `grass_black` + `red` + `corolla` | 4 | 🌿 130 Gramas<br>🌸 22 Flores | 105s | Atmosfera dramática; 4 rochas cardeais e flores corola rígidas. |
| **13** | *O Relógio de Quatro Pilares* | Cruz simétrica em 4 quadrantes | $18 \times 18$ | 4 cores de grama + `flower_rose` | 4 | 🌿 112 Gramas<br>🌸 4 Flores | 110s | Setorização em 4 quadrantes com marcos divisórios de rocha. |
| **14** | *Serpente de Trigo* | Retângulo comprido $22 \times 12$ | $22 \times 12$ | `grass_white` + trilha de `wheat` | 3 | 🌿 112 Gramas<br>🌾 37 Trigos | 110s | Zigue-zague contínuo com rochas no lado interno de cada curva. |
| **15** | *O Parque Central de Canteiros* | Ilha orgânica irregular $18 \times 16$ | $18 \times 16$ | `grass_green` + `flower_bed` | 5 | 🌿 98 Gramas<br>🌸 15 Flores | 115s | Micro-recompensas rápidas em canteiros floridos decorativos. |
| **16** | *O Anel Exterior de Obstáculos* | Anel circular largo $18 \times 18$ | $18 \times 18$ | `yellow` (centro) + `red` + `sunflower` | 6 | 🌿 145 Gramas<br>🌸 18 Flores | 115s | Centro livre para velocidade; precisão nas bordas falésicas. |
| **17** | *Alameda Imperial* | Ilha em H com duas avenidas | $20 \times 16$ | `grass_green` + `wheat` + `tulip` | 4 | 🌿 109 Gramas<br>🌾 25 Trigos<br>🌸 11 Flores | 120s | Corredores cerimoniais ladeados por trigo e tulipas nobres. |
| **18** | *O Labirinto dos Quatro Diamantes*| Diamante amplo $20 \times 20$ | $20 \times 20$ | `purple` + `white` + `flower_bed` | 4 | 🌿 168 Gramas<br>🌸 16 Flores | 120s | Desafio geométrico com 4 rochas como pivôs naturais de curva. |
| **19** | *O Oásis Multicolorido* | Estrela com pontas suaves $20 \times 20$ | $20 \times 20$ | Degradê concêntrico (4 gramas) + 3 flores | 5 | 🌿 324 Gramas<br>🌸 17 Flores | 125s | Composição densa e exuberante com pentágono aberto de rochas. |
| **20** | *Arquipélago da Maestria* | Trevo de 4 folhas interligado $22 \times 22$ | $22 \times 22$ | Todas as espécies do catálogo | 6 | 🌿 308 Gramas<br>🌾 28 Trigos<br>🌸 10 Flores | 135s | Clímax supremo integrando reflexos, resistência e navegação fina. |

---

## 3. Progressão de 5 Tiers de Dificuldade

1. **Tier 1 (Fases 1 a 4) — O Despertar do Jardineiro:**
   - Áreas amplas, livres de gargalos perigosos.
   - Apresentação gradativa da grama amarela, trigo e primeiras flores.
2. **Tier 2 (Fases 5 a 8) — Expansão Geográfica & Istmos:**
   - Introdução de passadiços e pontes estreitas cercadas por água azul.
   - Grama azul costeira e primeiras metas simultâneas de três tipos de vegetação.
3. **Tier 3 (Fases 9 a 12) — Desafio Tático & Chicanes:**
   - Geometrias sinuosas e bifurcações acentuadas.
   - Grama roxa exótica e posicionamento de rochas em vértices de curvas fechadas.
4. **Tier 4 (Fases 13 a 16) — Maestria & Economia:**
   - Alta densidade de Trigo (2 hits), tornando os upgrades de Potência e Raio da Oficina muito vantajosos.
   - Desafios lineares e espirais com tempos calibrados de forma competitiva.
5. **Tier 5 (Fases 17 a 20) — Níveis Épicos & Clímax:**
   - Grandes cenários monumentais (Tabuleiro, Santuário Solar, Labirinto Fortificado e Coroa Real).
   - Recompensas massivas de moedas e conclusão com acesso ao Ciclo Mestre.

---

## 4. Arquitetura Técnica e Scripts

- **Carregamento Runtime (`LevelController.gd` + `VegetationGrid.gd`):**
  - Carrega `res://data/levels/level_%02d.json` e constrói a ilha e a vegetação em lote via `VegetationGrid` (`MultiMeshInstance3D` por tipo de tile e por espécie vegetal + Grade Espacial Discreta `0.40m`).
  - Mapeia automaticamente as metas no HUD e posiciona o robô cortador no ponto `spawn` da fase em menos de `10 ms`.
- **Gerador Automatizado (`scripts/tools/generate_levels.js`):**
  - Recalcula matematicamente o Autotile canônico (`IslandAutotiler`) de cada célula.
  - Validador embutido (`scripts/tools/verify_levels.js`) que audita a integridade geométrica, limites de grid e ausência de sobreposições em todas as 20 fases.
- **Ciclo de Vitória & Progressão (`GameManager.gd` & `hud.gd`):**
  - Botão de "Próxima Fase ➔" integrado no modal de vitória.
  - Ao vencer a Fase 20, o HUD exibe o troféu "🏆 Campeão do Jardim! 🏆" e possibilita iniciar o "Ciclo Mestre (Fase 1) 👑" preservando todas as moedas e upgrades da Oficina.
