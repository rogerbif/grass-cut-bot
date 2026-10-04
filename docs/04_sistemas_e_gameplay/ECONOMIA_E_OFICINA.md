# Economia e Oficina de Upgrades 🪙⚙️

Este documento detalha o sistema econômico, a aquisição de moedas, a escalabilidade de custos e as 4 melhorias centrais do cortador em **Grass Cut Bot**.

---

## 1. Economia de Moedas Verdes

As moedas verdes são a moeda corrente do jogo e são obtidas diretamente pelo ato mecânico de corte:
- **Grama Verde:** 1 moeda base.
- **Trigo Dourado:** 3 moedas base.
- **Flores do Campo:** 5 moedas base.

O rendimento por corte é calculado como:
$$\text{Moedas Ganhas} = \text{Moedas Base da Planta} \times \text{Multiplicador Ativo}$$

---

## 2. As 4 Categorias de Upgrades da Oficina

| Atributo | Custo Base | Efeito por Nível | Impacto no Gameplay |
| :--- | :--- | :--- | :--- |
| **Raio da Lâmina** | 50 🪙 | $+0.12\text{m}$ no raio do disco | Expande a área de corte radial, permitindo ceifar mais tufos simultaneamente em cada passada. |
| **Potência e Fio** | 100 🪙 | $+1$ ponto de dano por golpe | Corta plantas resistentes (trigo e flores) em uma só passada em vez de duas. |
| **Velocidade da Serra** | 60 🪙 | $+0.75\text{m/s}$ na velocidade linear | Acelera a translação do cortador pelo gramado, facilitando vencer os estágios contra o relógio. |
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
