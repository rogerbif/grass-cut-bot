# Economia e Oficina de Upgrades 🪙⚙️

Este documento detalha o sistema econômico, a aquisição de moedas, a escalabilidade de custos e as 4 melhorias centrais do cortador em **Grass Cut Bot**.

---

## 1. Economia de Moedas Verdes

As moedas verdes são a moeda corrente do jogo e são obtidas diretamente pelo ato mecânico de corte e colheita. Em conformidade com a **Regra Canônica de Agrupamento em Lotes (Melhoria 082)**, a premiação econômica é consolidada por lote de colheita para manter legibilidade visual e evitar sobrecarga de números na tela:
- **Grama Comum (Qualquer das 7 Cores):** 10 tufos físicos ceifados = 1 lote de meta = 1 moeda base (número flutuante `+1` em branco puro com contorno preto).
- **Trigo Dourado (Meta 2x):** 10 tufos físicos ceifados = 1 lote de meta = 3 moedas base (número flutuante `+3` em amarelo ouro).
- **Flores do Campo (Nobre):** 1 tufo físico ceifado = 1 lote de meta = 5 moedas base (número flutuante `+5` em rosa magenta).

O rendimento por lote ceifado é calculado como:
$$\text{Moedas Ganhas} = \text{Moedas Base da Espécie} \times \text{Multiplicador Ativo da Oficina}$$

A cada lote ceifado, o valor final obtido surge como um número flutuante cartoon 3D (`FloatingCoinManager`) com contorno preto sólido de 14px e animação elástica, posicionado nas laterais do corpo do robô ($\pm 0.45\text{m}$) e subindo no ar com duração rápida de $0.34\text{s}$ em rastro suave (*number trail*).

---

## 2. As 4 Categorias de Upgrades da Oficina

| Atributo | Custo Base | Efeito por Nível | Impacto no Gameplay |
| :--- | :--- | :--- | :--- |
| **Raio da Lâmina** | 50 🪙 | $+0.10\text{m}$ no raio (base de $0.90\text{m}$) | Expande a área de corte radial, permitindo ceifar mais tufos simultaneamente em cada passada. |
| **Potência e Fio** | 100 🪙 | $+1$ ponto de dano por golpe | Corta plantas resistentes (trigo e flores) em uma só passada em vez de duas. |
| **Velocidade da Serra** | 60 🪙 | $+0.45\text{m/s}$ na velocidade linear (base de $3.25\text{m/s}$) | Acelera a translação do cortador pelo gramado, facilitando vencer os estágios contra o relógio. |
| **Multiplicador de Moedas** | 150 🪙 | $+1\times$ no ganho de cada tufo | Aumenta exponencialmente a receita de moedas para financiar upgrades mais caros. |

### Curva de Custo Exponencial
Para balancear a progressão e manter o interesse a longo prazo, o custo de cada nível subsequente segue a progressão geométrica:
$$\text{Custo}(n) = \lfloor \text{Custo Base} \times 1.6^{(n - 1)} \rfloor$$

---

## 3. Interface da Oficina (`WorkshopModal`)

Acessível a qualquer momento a partir dos menus de Pausa, Vitória ou Derrota:
- Mostra o saldo total de moedas no topo em destaque dourado.
- Lista os 4 cards com o nome, nível atual e botão de compra com o custo exato.
- Botões de compra desabilitados visualmente quando o saldo de moedas for insuficiente.
- Aplicação instantânea dos novos atributos à serra circular em tempo real via sinal `UpgradeManager.upgrade_purchased`.

---

## 4. Evolução Visual dos Modelos de Lâminas (Tiers)

Conforme o jogador adquire upgrades de **Raio da Lâmina** e **Potência e Fio**, o modelo 3D do rotor de corte alojado no `blade_container` transita dinamicamente entre 4 patamares tecnológicos da família de lâminas estreladas com arestas retas e acabamento em aço cinza:

| Tier | Modelo Visual | Requisito de Nível | Descrição Estética |
| :--- | :--- | :--- | :--- |
| **Tier 1** | **Lâmina Estelar Tripla** | Nível 1 a 2 | Estrela geométrica de 3 pontas com arestas retas, furo central e acabamento em aço cinza. |
| **Tier 2** | **Lâmina Estelar Quádrupla** | Nível 3 a 4 | Estrela geométrica de 4 pontas (cruz ninja) com arestas retas, furo central e aço cinza. |
| **Tier 3** | **Lâmina Estelar de Titânio** | Nível 5 a 6 | Estrela geométrica regular de 5 pontas com arestas retas, furo central e aço cinza. |
| **Tier 4** | **Lâmina Estelar Hexagonal** | Nível 7 ou superior | Estrela geométrica de 6 pontas (hexagrama) com arestas retas, furo central e aço cinza. |

O modelo atualmente equipado é exibido em tempo real no cabeçalho da Oficina: `"Lâmina: [Nome do Tier]"`.

