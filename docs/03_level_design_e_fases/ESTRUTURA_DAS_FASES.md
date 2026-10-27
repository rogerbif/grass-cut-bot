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
* **Spawn Seguro Central:** Área circular central com raio livre $R \ge 1.47\text{m}$ ($1.05 \times \text{raio da lâmina nível 6}$ de $1.40\text{m}$). O miolo inicial permanece 100% livre de qualquer obstáculo rígido (`rock`, `wheat`, `flower_*`), além de possuir uma clareira sutil de $0.72\text{m}$ na grama para evitar cortes automáticos no frame 0 antes do primeiro toque do jogador.
* **Espaçamento entre Rochas:** Distância mínima centro a centro entre duas rochas sempre superior a $2.80\text{m}$ ($> 2 \times \text{raio da lâmina nível 6}$), garantindo passagem folgada mesmo com o maior alcance de corte.
* **Regra de Desbloqueio de Obstáculos:** As **Fases 1 a 5** contêm estritamente 0 rochas (apenas vegetações e flores). As rochas sólidas (`rock`) são introduzidas progressivamente a partir da **Fase 6**.
* **Recorte Costeiro e Folga Interna:** Todos os polígonos vetoriais de grama são automaticamente intersectados com a máscara interna da ilha (`0.34m` de recuo das bordas costeiras, garantindo 0 tufos sobre a água ou na inclinação da falésia). Todos os objetos (`rock`, `wheat`, `flower_*`) residem em células internas planas, e todas as rochas possuem os 8 vizinhos (incluindo diagonais) dentro da ilha para impedir estrangulamento contra a parede invisível costeira.
* **Contabilização 1:1 Exata de Trigo e Flores:** Tufos de grama mantêm clareira de $0.26\text{m}$ ao redor do caule de flores e trigos, e cada instância de `wheat` e `flower_*` é contabilizada de forma 1:1 direta nas metas do HUD.

| Fase | Nome Temático | Silhueta / Geometria da Ilha | Grid ($W \times H$) | Tipos de Vegetação | Qtd. Rochas | Metas do HUD | Tempo | Lição / Foco de Design |
| :---: | :--- | :--- | :---: | :--- | :---: | :--- | :---: | :--- |
| **01** | *Boas-Vindas ao Jardim* | Quadrado suave $9 \times 9$ | $13 \times 13$ | `grass_green` + `grass_yellow` | 0 | 🌿 34 Gramas | 75s | Tutorial de corte básico; ceifa instantânea e movimentação fluida. |
| **02** | *O Prado Bicolor* | Quadrado chanfrado $9 \times 9$ | $13 \times 13$ | `grass_green` + `yellow` + `blue` | 0 | 🌿 48 Gramas | 80s | Diferenciação visual com faixas diagonais e manchas azuis sem sobreposição. |
| **03** | *Introdução à Resistência* | Ilha quadrada com cruz `island_dirt` | $15 \times 15$ | `grass_green` + `wheat` | 0 | 🌿 48 Gramas<br>🌾 8 Trigos | 85s | Primeiro contato com trigo rígido (2 hits, tremor mecânico). |
| **04** | *O Jardim Nobre* | Octógono regular $11 \times 11$ | $15 \times 15$ | `grass_blue` + `purple` + `daisy` + `bell` | 0 | 🌿 48 Gramas<br>🌸 8 Flores | 90s | Flores nobres de 3 hits (+5 moedas) e despetalação progressiva. |
| **05** | *Mandala Floral Mista* | Cruz arredondada ampla $13 \times 13$ | $17 \times 17$ | `white` + `green` + `yellow` + `wheat` + `rose` + `sunflower` | 0 | 🌿 81 Gramas<br>🌾 8 Trigos<br>🌸 4 Flores | 95s | Clímax do primeiro mundo sem rochas; anéis concêntricos de resistência. |
| **06** | *O Primeiro Rochedo* | Retângulo alongado $15 \times 7$ | $19 \times 11$ | `grass_green` + `grass_yellow` | 2 | 🌿 49 Gramas | 90s | Primeira aparição de rochas (Layer 8); choque, faíscas e recuo de 4.75 m/s. |
| **07** | *O Triângulo de Pedra* | Octógono amplo $13 \times 13$ | $17 \times 17$ | `grass_blue` + estrela `grass_white` | 3 | 🌿 62 Gramas | 90s | Navegação entre 3 rochas triangulares abertas ao redor do spawn. |
| **08** | *Caminho Dividido* | Formato de U bifurcado | $19 \times 17$ | `green` (base) + `purple` + `red` | 2 | 🌿 63 Gramas | 95s | Penínsulas gêmeas de 5 blocos de largura com rochas nos acessos. |
| **09** | *Pomar Protegido* | Quadrado chanfrado $13 \times 13$ | $17 \times 17$ | `green` + `yellow` + `tulip` + `sunflower` | 4 | 🌿 70 Gramas<br>🌸 4 Flores | 100s | Coleta de flores raras cercadas por anel de rochas protetoras. |
| **10** | *O Labirinto de Trigo e Granito* | Ilha quadrada com trilhas de terra | $19 \times 19$ | `grass_yellow` + `green` + `wheat` | 4 | 🌿 75 Gramas<br>🌾 16 Trigos | 105s | Labirinto híbrido: paredes temporárias de trigo e pilares de granito. |
| **11** | *Ilhotas Conectadas* | Duas ilhas unidas por istmo largo | $21 \times 13$ | `grass_blue` + `white` + `flower_bell` | 3 | 🌿 64 Gramas<br>🌸 4 Flores | 100s | Precisão de alinhamento ao cruzar o istmo sobre o oceano. |
| **12** | *Vulcânica* | Octógono vulcânico $13 \times 13$ | $17 \times 17$ | `grass_black` + `red` + `corolla` | 4 | 🌿 67 Gramas<br>🌸 4 Flores | 105s | Atmosfera dramática; 4 rochas cardeais e flores corola rígidas. |
| **13** | *O Relógio de Quatro Pilares* | Cruz simétrica em 4 quadrantes | $19 \times 19$ | 4 cores de grama + `flower_rose` | 4 | 🌿 77 Gramas<br>🌸 4 Flores | 110s | Setorização em 4 quadrantes com marcos divisórios de rocha. |
| **14** | *Serpente de Trigo* | Retângulo comprido $17 \times 9$ | $21 \times 13$ | `grass_white` + `green` + trilha `wheat` | 3 | 🌿 80 Gramas<br>🌾 12 Trigos | 110s | Zigue-zague contínuo com rochas no lado interno de cada curva. |
| **15** | *O Parque Central de Canteiros* | Quadrado chanfrado $15 \times 13$ | $19 \times 17$ | `grass_green` + `yellow` + `flower_bed` | 5 | 🌿 77 Gramas<br>🌸 6 Flores | 115s | Micro-recompensas rápidas em 6 canteiros floridos decorativos. |
| **16** | *O Anel Exterior de Obstáculos* | Octógono amplo $15 \times 15$ | $19 \times 19$ | `yellow` (centro) + `red` + `sunflower` | 6 | 🌿 78 Gramas<br>🌸 6 Flores | 115s | Centro livre para velocidade; precisão nas bordas com 6 girassóis. |
| **17** | *Alameda Imperial* | Ilha em H com duas avenidas | $21 \times 17$ | `grass_green` + `yellow` + `wheat` + `tulip` | 4 | 🌿 84 Gramas<br>🌾 8 Trigos<br>🌸 4 Flores | 120s | Corredores cerimoniais ladeados por trigo e tulipas nobres. |
| **18** | *O Labirinto dos Quatro Diamantes*| Diamante amplo $17 \times 17$ | $19 \times 19$ | `purple` + `white` + `wheat` + `flower_bed` | 4 | 🌿 83 Gramas<br>🌾 4 Trigos<br>🌸 4 Flores | 120s | Desafio geométrico com 4 rochas e facetas diagonais de trigo. |
| **19** | *O Oásis Multicolorido* | Estrela octogonal $15 \times 15$ | $19 \times 19$ | Degradê concêntrico (4 gramas) + 5 flores | 5 | 🌿 85 Gramas<br>🌸 5 Flores | 125s | Composição exuberante com pentágono aberto de rochas e 5 espécies de flor. |
| **20** | *Arquipélago da Maestria* | Trevo de 4 folhas $17 \times 17$ | $21 \times 21$ | `yellow` + `white` + `green` + `wheat` + `tulip` + `corolla` | 6 | 🌿 102 Gramas<br>🌾 6 Trigos<br>🌸 4 Flores | 135s | Clímax supremo integrando reflexos, resistência e navegação fina. |

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
