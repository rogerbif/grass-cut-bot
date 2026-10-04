# Estrutura das Fases e Level Design 🗺️🌱

Este documento detalha o desenho dos estágios, a progressão de dificuldade, a curva de aprendizado e a arquitetura do gerador de fases em **Grass Cut Bot**.

---

## 1. Filosofia de Level Design Hiper-Casual

1. **Sessões Rápidas (1 a 2 Minutos):**
   - Os estágios são projetados para conclusão ágil durante pequenos intervalos diários.
2. **Crescimento Gradual de Complexidade:**
   - O jogador começa focado puramente na sensação do corte e na mecânica do joystick. Elementos de desafio cognitivo (evitar pedras e priorizar metas de colheita) são introduzidos passo a passo.
3. **Gratificação Imediata:**
   - A distribuição de plantas garante fluxo contínuo de cortes, sem áreas vazias excessivas que quebrem o ritmo do jogo.

---

## 2. Progressão Canônica dos Estágios

### Fase 1: MVP de Validação (O Básico do Corte)
- **Área do Cenário:** Retângulo compacto ($10 \times 6$ tufos com espaçamento de $1.1\text{m}$).
- **Composição:** 60 tufos de grama verde básica. Centro inicial livre para partida suave.
- **Metas do HUD:** Cortar 60 tufos de grama.
- **Cronômetro:** 90 segundos ($1:30$).
- **Obstáculos Internos:** Nenhum.
- **Foco de Design:** Calibração do joystick flutuante, sensação tátil do corte contínuo, verificação dos contadores e finalização com vitória.

### Fase 2: Introdução de Trigo e Primeiras Rochas
- **Área do Cenário:** $11 \times 8$ tufos.
- **Composição:** ~65 gramas e ~15 trigos maduros.
- **Metas do HUD:** Grama + Trigo.
- **Cronômetro:** 100 segundos ($1:40$).
- **Obstáculos Internos:** 3 rochas posicionadas estrategicamente, forçando mudanças de trajetória.
- **Foco de Design:** Apresentar a mecânica de vegetação resistente (trigo exige 2 golpes sem upgrade) e o feedback de choque contra obstáculos.

### Fase 3: Introdução de Flores Nobres
- **Área do Cenário:** $12 \times 10$ tufos.
- **Composição:** Mistura balanceada de grama, trigo e flores rosa/magenta.
- **Metas do HUD:** Cotas simultâneas de Grama, Trigo e Flores.
- **Cronômetro:** 110 segundos ($1:50$).
- **Obstáculos Internos:** 5 rochas formando pontos de afunilamento e curvas.
- **Foco de Design:** Gestão de prioridades visuais pelo jogador para bater as cotas antes do término do tempo.

### Fases 4 a 10: Modos Avançados e Progressão Contínua
- Geração procedural controlada:
  - Dimensões expandidas até $14 \times 12$.
  - Múltiplas metas simultâneas de colheita com quantidades expressivas.
  - Densidade aumentada de obstáculos e caminhos estreitos.
  - Necessidade direta de evolução do cortador na Oficina (raio expandido e velocidade extra para bater os tempos mais apertados).

---

## 3. Controlador de Níveis (`level_controller.gd`)

O gerenciamento de montagem dos estágios é centralizado no nó `LevelController`:
- Limpa nós anteriores de vegetação e obstáculos de forma assíncrona.
- Instancia os tufos corretos com variação procedural de escala e ângulo.
- Invoca `GameManager.start_level(current_level, goals, duration)` para inicializar os sistemas de HUD e regras de vitória/derrota com sincronismo perfeito.
