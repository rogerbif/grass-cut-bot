# Economia e Oficina de Upgrades 🪙⚙️

Este documento detalha o sistema econômico, a aquisição de moedas, a escalabilidade de custos e a evolução da lâmina em **Grass Cut Bot**.

---

## 1. Economia de Moedas

As moedas são obtidas diretamente pelo ato mecânico de corte e colheita:
- **Grama Comum (Qualquer das 7 Cores):** 10 tufos ceifados = 1 lote de meta = 1 moeda base.
- **Trigo Dourado:** 1 tufo ceifado = 1 unidade de meta = 3 moedas base.
- **Flores do Campo:** 1 tufo ceifado = 1 lote de meta = 5 moedas base.

A cada lote ceifado, o valor final obtido surge como um número flutuante cartoon 3D (`FloatingCoinManager`) com contorno preto sólido e animação elástica, posicionado nas laterais do corpo do robô e subindo suavemente.

---

## 2. Sistema Unificado de Lâmina e Velocidade

A evolução do cortador é unificada e opera em duas frentes complementares:
1. **No Gameplay:** Cada corte concede experiência (XP) que preenche a barra flutuante acima da cabeça do bot. A serra cresce dinamicamente do **Nível 1** até o **Nível 10 ("MAX")**. Bater em rochas penaliza com perda de **1.000 XP** (com cooldown de proteção de 1.2s), rebaixando o nível apenas se a dedução esgotar a barra do nível atual.
2. **Na Garagem / Oficina:** O jogador pode investir suas moedas para comprar níveis de lâmina diretamente até o **Nível 8**. Os Níveis 9 e 10 ("MAX") são exclusivos de gameplay através da colheita contínua em partida.

### Tabela de Níveis, Raio, Velocidade e Custos
| Nível | Raio da Lâmina | Velocidade do Bot | Tier Visual | Custo na Garagem | XP para Próximo Nível | XP Total Acumulado |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **1** | **0.90 m** | **1.95 m/s** | Tier 1 (Tripla) | Inicial (Grátis) | 200 XP | 0 XP |
| **2** | **0.96 m** | **2.13 m/s** | Tier 1 (Tripla) | 100 🪙 | 350 XP | 200 XP |
| **3** | **1.01 m** | **2.31 m/s** | Tier 1 (Tripla) | 250 🪙 | 550 XP | 550 XP |
| **4** | **1.07 m** | **2.49 m/s** | Tier 2 (Quádrupla) | 500 🪙 | 800 XP | 1.100 XP |
| **5** | **1.12 m** | **2.67 m/s** | Tier 2 (Quádrupla) | 900 🪙 | 1.200 XP | 1.900 XP |
| **6** | **1.18 m** | **2.85 m/s** | Tier 2 (Quádrupla) | 1.500 🪙 | 1.700 XP | 3.100 XP |
| **7** | **1.23 m** | **3.03 m/s** | Tier 3 (Titânio) | 2.400 🪙 | 2.400 XP | 4.800 XP |
| **8** | **1.29 m** | **3.21 m/s** | Tier 3 (Titânio) | 3.800 🪙 | 3.300 XP | 7.200 XP |
| **9** | **1.34 m** | **3.39 m/s** | Tier 4 (Hexagonal) | *Exclusivo Gameplay* | 4.800 XP | 10.500 XP |
| **10 (MAX)** | **1.40 m** | **3.57 m/s** | Tier 4 (Hexagonal) | *Exclusivo Gameplay* | **0 XP (Barra Cheia / MAX)** | **12.000 XP (Total 12k)** |

---

## 3. Interface da Garagem (`tab_garage.tscn`)

Acessível na aba "Oficina" do Menu Principal:
- Saldo de moedas em destaque dourado no topo.
- Banner visual exibindo o nome e tier da lâmina equipada.
- Card de **Upgrade da Lâmina** exibindo nível atual, raio, velocidade e botão de compra até o Nível 8 (com botão desativado e texto "MÁX LOJA" no nível 8 e "MAX ✔" no nível 10).
- Dica de gameplay lembrando que colidir com rochas subtrai 1.000 XP da lâmina.

---

## 4. O Herbário Botânico & Recompensas de Maestria (`tab_collection.tscn`)

Acessível na aba "Coleção" do Menu Principal:
- **Catálogo Canônico de 15 Espécies (`PlantDatabase`):**
  - **7 Gramas:** Verde Esmeralda, Dourada Solar, Azul Costeira, Violeta Crepúsculo, Branca Cristalina, Carmesim Vulcânica e Negra Obsidiana.
  - **1 Cultura Agrícola:** Trigo Dourado Enraizado.
  - **7 Flores Nobres & Canteiros:** Margarida Silvestre, Flor de Sino Cerúlea, Rosa Rubra Encantada, Girassol Radiante, Tulipa Imperial, Corola Vulcânica e Canteiro de Flores Mistas.
- **Rastreamento Dinâmico no `SaveManager`:**
  - Descoberta automática no primeiro corte de cada tufo físico (`record_plant_harvest`).
  - Total vitalício de tufos ceifados por espécie e carreira global.
- **10 Níveis de Marcos de Maestria por Espécie:**
  - Cada uma das 15 espécies possui 10 níveis de meta com títulos temáticos e recompensas crescentes em moedas (ex: 50 a 10.000 para gramas, 15 a 2.200 para trigo e 10 a 1.300 para flores).
  - Botão interativo `COLETAR +X 🪙` em destaque verde quando a meta é alcançada, com feedback de áudio (`"buy"`) e vibração tátil ao resgatar.
- **Filtros Ágeis:** Botões de alternância `Todas (15)`, `Gramas (7)`, `Culturas (1)` e `Flores (7)`.

