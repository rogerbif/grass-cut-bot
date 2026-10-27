# Melhoria 112: Recriação das 20 Primeiras Fases Canônicas com Progressão Estruturada 🗺️🏝️🌾

Este documento registra a implementação canônica da nova progressão de 20 fases canônicas de **Grass Cut Bot**, com parametrização estrita de distâncias, segurança de spawn central e introdução escalonada de elementos do ecossistema, avançando a versão para `v0.12.36-alpha`.

---

## 1. Motivação e Objetivos de Design

1. **Spawn Seguro Central:** Em todas as 20 fases, o miolo de spawn possui raio circular livre $R \ge 1.47\text{m} \approx 1.50\text{m}$ ($1.05 \times \text{raio da lâmina nível 6}$), 100% isento de qualquer obstáculo rígido (`rock`, `wheat`, `flower_*`), garantindo que o bot jamais inicie colidindo.
2. **Espaçamento entre Rochas (> 2.80m):** A distância mínima centro a centro entre rochas adjacentes é estritamente superior a $2.80\text{m}$ ($> 2 \times \text{raio da serra nível 6}$), permitindo a passagem folgada do robô mesmo no maior alcance de corte.
3. **Regra de Desbloqueio Progressivo de Obstáculos:**
   * **Fases 1 a 5 (O Jardim):** Estritamente **0 rochas**. O foco é a ceifa instantânea, diferenciação visual em setores, primeiro contato com trigo (2 hits e tremor) e primeiras flores nobres (3 hits e despetalação).
   * **Fases 6 a 20:** Introdução gradual de rochas sólidas (Layer 8) e espécies florais de alto valor (Rosa, Margarida, Girassol, Flor Sino, Cravo Corola, Tulipa Imperial e Canteiro Florido).
4. **Layouts de Ilha Únicos e Autotile:** Cada fase possui silhueta própria (retângulo, octógono, hexágono, cruz, U, H, diamante, estrela, istmos e trevo de 4 folhas), com resolução automática de falésias e quinas arredondadas via `IslandAutotiler`.

---

## 2. A Nova Matriz das 20 Fases Canônicas

| Fase | Nome Temático | Grid | Geometria da Ilha | Composição de Vegetação | Rochas | Metas do HUD | Tempo |
| :---: | :--- | :---: | :--- | :--- | :---: | :--- | :---: |
| **01** | *Boas-Vindas ao Jardim* | $12 \times 12$ | Quadrado suave $8 \times 8$ | `grass_green` + `grass_yellow` | 0 | 🌿 44 Gramas | 75s |
| **02** | *O Prado Bicolor* | $14 \times 14$ | Quadrado chanfrado $10 \times 10$ | `grass_green` + `yellow` + `blue` | 0 | 🌿 25 Gramas | 80s |
| **03** | *Introdução à Resistência* | $14 \times 14$ | Ilha com cruz `island_dirt` | `grass_green` + `wheat` | 0 | 🌿 50 Gramas, 🌾 26 Trigos | 85s |
| **04** | *O Jardim Nobre* | $14 \times 14$ | Octógono regular | `grass_blue` + `purple` + `daisy` + `bell` | 0 | 🌿 59 Gramas, 🌸 23 Flores | 90s |
| **05** | *Mandala Floral Mista* | $16 \times 16$ | Cruz arredondada ampla | `white` + `green` + `wheat` + `rose` + `sunflower` | 0 | 🌿 78 Gramas, 🌾 28 Trigos, 🌸 6 Flores | 100s |
| **06** | *O Primeiro Rochedo* | $18 \times 10$ | Retângulo alongado | `grass_green` + `grass_yellow` | 2 | 🌿 89 Gramas | 90s |
| **07** | *O Triângulo de Pedra* | $16 \times 14$ | Hexágono aberto | `grass_blue` + `grass_white` | 3 | 🌿 76 Gramas | 90s |
| **08** | *Caminho Dividido* | $18 \times 16$ | Formato de U bifurcado | `green` (centro) + `purple` + `red` | 2 | 🌿 76 Gramas | 95s |
| **09** | *Pomar Protegido* | $16 \times 16$ | Quadrado com cantos recortados | `yellow` + `flower_tulip` + `sunflower` | 4 | 🌿 69 Gramas, 🌸 13 Flores | 100s |
| **10** | *O Labirinto de Trigo e Granito* | $18 \times 18$ | Ilha ampla com trilhas | `grass_yellow` + corredores de `wheat` | 4 | 🌿 154 Gramas, 🌾 52 Trigos | 110s |
| **11** | *Ilhotas Conectadas* | $20 \times 12$ | 2 ilhas unidas por istmo | `grass_blue` + `flower_bell` | 3 | 🌿 55 Gramas, 🌸 11 Flores | 105s |
| **12** | *Vulcânica* | $16 \times 16$ | Círculo irregular acidentado | `grass_black` + `red` + `corolla` | 4 | 🌿 130 Gramas, 🌸 22 Flores | 105s |
| **13** | *O Relógio de Quatro Pilares* | $18 \times 18$ | Cruz simétrica em 4 quadrantes | 4 cores de grama + `flower_rose` | 4 | 🌿 112 Gramas, 🌸 4 Flores | 110s |
| **14** | *Serpente de Trigo* | $22 \times 12$ | Retângulo longo | `grass_white` + trilha de `wheat` | 3 | 🌿 112 Gramas, 🌾 37 Trigos | 110s |
| **15** | *O Parque Central de Canteiros* | $18 \times 16$ | Ilha orgânica irregular | `grass_green` + canteiros `flower_bed` | 5 | 🌿 98 Gramas, 🌸 15 Flores | 115s |
| **16** | *O Anel Exterior de Obstáculos* | $18 \times 18$ | Grande anel circular | `yellow` (centro) + `red` + `sunflower` | 6 | 🌿 145 Gramas, 🌸 18 Flores | 115s |
| **17** | *Alameda Imperial* | $20 \times 16$ | Ilha em H com 2 avenidas | `grass_green` + `wheat` + `tulip` | 4 | 🌿 109 Gramas, 🌾 25 Trigos, 🌸 11 Flores | 120s |
| **18** | *O Labirinto dos Quatro Diamantes* | $20 \times 20$ | Diamante amplo | `purple` + `white` + `flower_bed` | 4 | 🌿 168 Gramas, 🌸 16 Flores | 120s |
| **19** | *O Oásis Multicolorido* | $20 \times 20$ | Estrela com pontas suaves | Degradê concêntrico (4 gramas) + 3 flores | 5 | 🌿 324 Gramas, 🌸 17 Flores | 125s |
| **20** | *Arquipélago da Maestria* | $22 \times 22$ | Trevo de 4 folhas interligado | Todas as espécies do catálogo | 6 | 🌿 308 Gramas, 🌾 28 Trigos, 🌸 10 Flores | 135s |

---

## 3. Implementação e Automação

* **Script Gerador (`scripts/tools/generate_all_20_levels.gd`):** Gerou deterministicamente as 20 fases em JSON v3 com autotile, recorte de grama sob rochas e validação de segurança.
* **Prioridade de Célula Lógica (`vegetation_grid.gd`):** Flores e trigos discretos são registrados antes dos tufos de grama amostrados, garantindo contagem exata e 100% de integridade das metas do HUD.
* **Suporte Completo a Flores no Serializador (`level_serializer.gd`):** Atualizada a condição de exportação para `obj_type.begins_with("flower")`, assegurando persistência de todas as 8 espécies no editor in-game.

---

## 4. Verificação

1. **Validação Automática das 20 Fases:** Executado `verify_levels.gd` com aprovação total de 100% dos níveis (`ALL LEVELS VERIFIED!`).
2. **Zero Warnings na Engine:** Executado `godot.exe --headless --editor --quit` com 0 warnings e 0 erros.
3. **Game SemVer:** Incrementado para `v0.12.36-alpha` (código 1236) sincronizado em `game_version.gd`, `project.godot` e `export_presets.cfg`.
