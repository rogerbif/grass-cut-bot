# Game Design Document (GDD): Projeto Grass Cut Bot

**Versão:** 0.2 (Documento Vivo)  
**Plataforma Alvo:** Android (Mobile)  
**Gênero:** Hiper casual, Simulação Arcade, Satisfying  
**Estilo Visual:** Low Poly com cores sólidas e acabamento fosco (Matte / Flat Shading)  
**Orientação da Tela:** Vertical (Portrait)

---

## 1. Visão Geral do Produto

### 1.1 High Concept
Controlar um cortador em perspectiva isométrica para limpar gramados em cenários compactos, cumprindo metas específicas de colheita contra o relógio e desviando de obstáculos em partidas táteis de um a dois minutos.

### 1.2 Proposta Única de Valor (USP)
Entrega imediata de relaxamento mecânico por meio de física responsiva, feedback háptico sincronizado com cada tufo de grama ceifado, somado ao dinamismo de metas visuais objetivas com contagem regressiva.

### 1.3 Perfil do Usuário
Jogadores casuais de dispositivos móveis que buscam sessões rápidas de descompressão durante intervalos diários, utilizando apenas uma das mãos (one-thumb play) para navegar e jogar.

---

## 2. Core Loop e Controles

### 2.1 Loop Principal de Jogabilidade
1. **Entrada:** O jogador entra no nível e visualiza o formato do gramado, as cotas de plantas requeridas e o cronômetro no topo.
2. **Ação:** Utiliza o joystick flutuante para movimentar a serra circular e cortar a vegetação alvo.
3. **Desafio:** Administrar o tempo decrescente e contornar obstáculos sem travar a máquina.
4. **Resolução:** Zerar todos os contadores das plantas exigidas antes do término do tempo para vencer a fase.
5. **Recompensa:** Acúmulo de moedas geradas pelos cortes para adquirir melhorias na oficina.

### 2.2 Esquema de Entrada (Input)
- **Joystick Flutuante:** O toque inicial em qualquer ponto da metade inferior da tela define a origem do controle.
- **Arrasto Direcional:** O deslocamento do dedo gera um vetor normalizado de direção e velocidade.
- **Zona Morta:** Pequeno raio central sem resposta para evitar movimentos acidentais por microtoques.

---

## 3. Mecânicas de Jogo e Entidades

### 3.1 O Cortador (Serra Circular)
- **Formato e Estrutura:** Uma base circular única no estilo disco de serra dentada, posicionada rente ao solo e com rotação contínua de alta velocidade.
- **Movimentação:** Deslocamento ágil pelo cenário guiado pelo joystick flutuante, sem frente ou traseira fixa, mantendo corte uniforme em qualquer sentido de condução (omnidirecional).
- **Mecânica de Corte por Contato:**
  - *Princípio Geral:* Tocou na lâmina, cortou. A verificação ocorre com base no raio de contato radial do disco.
  - *Sistema de Dureza e Eficiência:* A lâmina inicial pode exigir mais de uma passada ou tempo de contato contínuo sobre vegetações mais densas ou resistentes (como arbustos, trigo e flores altas), abrindo espaço para progressão direta via melhorias de fio e potência do disco.
- **Estado de Choque:** Colisão direta com obstáculos sólidos (rochas ou troncos) interrompe a inércia momentaneamente e gera recuo leve com faíscas visuais.

### 3.2 Tipos de Vegetação e Gramado
- **Densidade:** Malha de tufos distribuídos em espaçamento regular sobre o terreno.
- **Categorias de Plantas:**
  - **Grama Verde Básica:** Vegetação comum de corte imediato presente em todos os níveis.
  - **Trigo e Flores:** Plantas de valor especial que funcionam como cotas de colheita no HUD e podem apresentar maior resistência ao disco inicial.
- **Estados da Vegetação:**
  - **Intacta:** Tufo visível com volume tridimensional e sombra.
  - **Cortada:** Tufo removido do cenário, atualizando o contador do HUD, revelando o piso aparado e disparando partículas.

### 3.3 Obstáculos e Limites
- **Bordas do Terreno:** Barreiras que delimitam a ilha do cenário, impedindo que o cortador saia da área útil de jogo.
- **Obstáculos Internos:** Pedras, troncos e elementos que causam ricochete/choque e impedem a passagem.

---

## 4. Interface do Usuário (HUD) e Fluxos de Telas

### 4.1 Top HUD durante a Partida
- **Cronômetro Decrescente:** Posicionado no canto superior esquerdo dentro de um anel circular, exibindo tempo restante no formato Minutos e Segundos (ex: `1:56`).
- **Painel Central de Metas de Plantas:**
  - Exibe os ícones das variedades vegetais exigidas no estágio.
  - Apresenta a quantidade pendente abaixo de cada ícone (ex: 46 flores, 42 trigos).
  - A cada tufo cortado, o valor numérico reduz em tempo real até atingir zero e exibir confirmação visual de meta batida.
- **Botão de Pausa:** Fixado no canto superior direito da tela.

### 4.2 Modal de Pausa (Pop-up)
Ao acionar o botão de pausa, a física e o cronômetro são congelados, exibindo uma janela sobreposta com três ações:
- **Play (Continuar):** Fecha a janela e retoma a partida exatamente do ponto interrompido.
- **Reiniciar Fase:** Recarrega o estágio atual, restaurando o tempo e reposicionando a serra na coordenada inicial.
- **Home:** Retorna o jogador ao menu principal ou seletor de fases.

### 4.3 Condições de Fim de Partida
- **Vitória:** Todas as metas numéricas de plantas chegam a zero antes do esgotamento do tempo, abrindo a tela de celebração com moedas e botão de avançar.
- **Derrota (Game Over):** O cronômetro atinge `0:00` com qualquer meta pendente no painel superior, exibindo a tela de falha com opção de tentar novamente.

---

## 5. Game Feel e Feedback Sensorial

### 5.1 Efeitos Visuais
- **Partículas de Corte:** Lançamento de fragmentos verdes ou pétalas coloridas em arco parabólico a cada corte realizado.
- **Suavização de Câmera:** Câmera isométrica elevada acompanhando a serra circular com amortecimento suave (smooth follow) para manter fluidez.

### 5.2 Feedback Tátil (Haptics)
- **Pulso Curto Contínuo:** Vibração suave no aparelho a cada tufo ceifado em sequência.
- **Impacto Seco:** Vibração mais forte e curta ao bater frontalmente contra pedras e obstáculos.

---

## 6. Progressão e Metagame

### 6.1 Economia Básica
- **Moedas Verdes:** Concedidas a cada tufo ceifado e computadas ao término da fase.
- **Upgrades Centrais da Oficina:**
  - **Raio da Lâmina:** Expande o diâmetro do disco de serra.
  - **Potência e Fio:** Permite cortar vegetações resistentes de primeira passada.
  - **Velocidade da Serra:** Aumenta a velocidade máxima de translação.
  - **Multiplicador de Moedas:** Incrementa o rendimento econômico por planta colhida.

### 6.2 Estrutura dos Níveis
- **Fase 1 (MVP de Validação):**
  - *Composição:* Área retangular compacta coberta por grama verde básica.
  - *Meta do HUD:* Coleta de uma cota inicial de grama verde com cronômetro generoso (ex: cortar 60 tufos em 1:30).
  - *Obstáculos:* Ausência de barreiras internas, foco total na calibragem do joystick flutuante, fluidez do corte e contagem do HUD.
- **Fases 2 e 3:** Inclusão gradual de pequenas rochas e introdução de uma segunda variedade de planta.
- **Fases 4 a 10:** Níveis com múltiplos coletores simultâneos (trigo, flores roxas), gramas de alta resistência, caminhos estreitos e curvas desafiadoras.
