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

| Fase | Nome Temático | Silhueta / Geometria da Ilha | Grid ($W \times H$) | Tipos de Vegetação | Qtd. Rochas | Metas do HUD | Tempo | Lição / Foco de Design |
| :---: | :--- | :--- | :---: | :--- | :---: | :--- | :---: | :--- |
| **01** | *Praia Inicial* | Retângulo Amplo Acolhedor | $14 \times 10$ | Grama Verde | 0 | 🌿 59 Gramas | 90s | Tutorial de toque e fluxo de corte contínuo. |
| **02** | *Baía Amarela* | Ovalada com Enseada Sul | $15 \times 12$ | Verde + Amarela | 2 | 🌿 62 Gramas | 85s | Variação estética e primeiras rochas isoladas. |
| **03** | *Campos Dourados* | Retângulo chanfrado com Terra | $16 \times 12$ | Verde + Trigo | 4 | 🌿 42 Gramas<br>🌾 29 Trigos | 85s | Mecânica de 2 golpes do trigo. |
| **04** | *Jardim das Orquídeas* | Cruz Grega com Pátio Central | $15 \times 15$ | Verde + Trigo + Flor | 4 | 🌿 20 Gramas<br>🌾 24 Trigos<br>🌸 36 Flores | 80s | Introdução das Flores Nobres e meta tripla. |
| **05** | *Ilhas Gêmeas* | 2 Círculos Unidos por Ponte de Terra | $18 \times 11$ | Verde + Amarela + Trigo | 3 | 🌿 66 Gramas<br>🌾 8 Trigos | 85s | Navegação em istmos estreitos (2 blocos). |
| **06** | *Lagoa Serena* | Atol Circular em Anel (Donut) | $16 \times 16$ | Verde + Azul + Flor | 6 | 🌿 83 Gramas<br>🌸 14 Flores | 80s | Circulação orbital e introdução da grama azul. |
| **07** | *Vale da Ampulheta* | 2 Platôs com Gargalo Central | $16 \times 16$ | Amarela + Trigo + Flor | 2 | 🌿 67 Gramas<br>🌾 30 Trigos<br>🌸 8 Flores | 80s | Planejamento de rota (limpar antes de transitar). |
| **08** | *Três Picos* | Arquipélago Tríade em "Y" | $19 \times 17$ | Verde + Amarela + Azul + Trigo + Flor | 7 | 🌿 67 Gramas<br>🌾 11 Trigos<br>🌸 8 Flores | 85s | Tomada de decisão em encruzilhada tripla. |
| **09** | *Serpentina de Coral* | Península Longa em "S" | $18 \times 17$ | Verde + Amarela + Trigo | 6 | 🌿 109 Gramas<br>🌾 44 Trigos | 80s | Curvas fechadas com o joystick sem bater. |
| **10** | *Labirinto das Pedras* | Ilha Quadrada com Muretas de Pedra | $17 \times 17$ | Roxa + Trigo + Flor | 15 | 🌿 123 Gramas<br>🌾 14 Trigos<br>🌸 16 Flores | 85s | Introdução da grama roxa; evitar choques. |
| **11** | *Trevo da Sorte* | Ilha Trevo de 4 Pétalas | $18 \times 18$ | 4 Cores de Grama + Trigo + Flor | 8 | 🌿 79 Gramas<br>🌾 28 Trigos<br>🌸 8 Flores | 85s | Varredura por quadrantes e retorno ao hub. |
| **12** | *Estrela do Oceano* | Estrela de 5 Pontas | $19 \times 19$ | Azul + Roxa + Trigo + Flor | 3 | 🌿 27 Gramas<br>🌾 25 Trigos<br>🌸 22 Flores | 80s | Risco vs Recompensa nas pontas estreitas. |
| **13** | *Tridente de Netuno* | Base Sul com 3 Corredores ao Norte | $18 \times 17$ | Verde + Trigo Denso + Flor | 10 | 🌿 50 Gramas<br>🌾 51 Trigos<br>🌸 25 Flores | 80s | Densidade de trigo; upgrade de potência ajuda. |
| **14** | *Coração Selvagem* | Formato de Coração Grande | $18 \times 18$ | Roxa + Trigo + Flor | 6 | 🌿 92 Gramas<br>🌾 35 Trigos<br>🌸 16 Flores | 80s | Movimentação cardioide fluida e rítmica. |
| **15** | *Passadiço dos Abismos* | 4 Ilhotas em Degraus Lineares | $22 \times 12$ | Amarela + Azul + Trigo + Flor | 5 | 🌿 41 Gramas<br>🌾 17 Trigos<br>🌸 11 Flores | 85s | Sprint linear de alta velocidade entre passagens. |
| **16** | *Fortaleza Espiral* | Espiral em Caracol (do mar ao centro) | $18 \times 18$ | Verde + Roxa + Trigo + Flor Nobre | 8 | 🌿 91 Gramas<br>🌾 44 Trigos<br>🌸 4 Flores | 85s | Movimento centrípeto com raio decrescente. |
| **17** | *Tabuleiro Proibido* | Grade Xadrez de 9 Ilhotas e Lagoas | $19 \times 19$ | Amarela + Azul + Trigo + Flor | 4 | 🌿 44 Gramas<br>🌾 36 Trigos<br>🌸 32 Flores | 90s | Controle fino em malha de micro-pontes. |
| **18** | *Santuário Solar* | Disco Solar com 8 Satélites Radiais | $20 \times 20$ | 4 Cores de Grama + Trigo + Flor | 8 | 🌿 79 Gramas<br>🌾 24 Trigos<br>🌸 36 Flores | 90s | Priorização de raios externos de alta pontuação. |
| **19** | *Labirinto do Minotauro* | Malha de Corredores e Ruelas | $19 \times 19$ | Roxa + Trigo Pesado + Flor | 28 | 🌿 128 Gramas<br>🌾 52 Trigos<br>🌸 16 Flores | 95s | Destreza máxima no joystick e reflexos contra ricochete. |
| **20** | *A Grande Coroa Real* | Coroa Imperial (5 Torres + Pátio) | $22 \times 20$ | Todas as Gramas + Trigo + Flores | 15 | 🌿 90 Gramas<br>🌾 103 Trigos<br>🌸 29 Flores | 110s | Clímax épico com chuva de moedas e coroação! |

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

- **Carregamento Runtime (`LevelController.gd`):**
  - Prioridade 1 para `res://data/levels/level_%02d.json`.
  - Mapeia automaticamente as metas no HUD via nó `$PlantsContainer` e propriedade `plant_key` de cada tufo.
  - Spawna o robô cortador no ponto exato `spawn` da fase.
- **Gerador Automatizado (`scripts/tools/generate_levels.js`):**
  - Recalcula matematicamente o Autotile canônico (`IslandAutotiler`) de cada célula.
  - Validador embutido (`scripts/tools/verify_levels.js`) que audita a integridade geométrica, limites de grid e ausência de sobreposições em todas as 20 fases.
- **Ciclo de Vitória & Progressão (`GameManager.gd` & `hud.gd`):**
  - Botão de "Próxima Fase ➔" integrado no modal de vitória.
  - Ao vencer a Fase 20, o HUD exibe o troféu "🏆 Campeão do Jardim! 🏆" e possibilita iniciar o "Ciclo Mestre (Fase 1) 👑" preservando todas as moedas e upgrades da Oficina.
