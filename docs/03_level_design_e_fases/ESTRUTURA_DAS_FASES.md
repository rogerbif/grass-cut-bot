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

### Fase 1: MVP de Validação (Cena `scenes/levels/level_01.tscn`)
- **Cena Própria no Godot:** Montada como cena autônoma `scenes/levels/level_01.tscn`, permitindo que o level designer selecione, mova, duplique ou exclua tufos diretamente no Viewport 3D da Godot.
- **Área do Cenário:** Ilha com terreno próprio (`terrain.tscn`) e muretas limítrofes.
- **Composição Inicial:** 56 tufos de grama verde estilizada 3D (`grass_tuft.tscn`), distribuídos em grid retangular ($10 \times 6$) com o centro livre para spawn do cortador (`CutterSpawn` em $(0, 0.1, 0)$).
- **Detecção Automática de Metas:** O script `base_level.gd` varre o nó `$Plants` em tempo de execução e registra automaticamente as metas no `GameManager`. Qualquer tufo adicionado ou removido manualmente na cena tem sua meta sincronizada instantaneamente sem necessidade de alterar código.
- **Cronômetro:** 90 segundos ($1:30$).
- **Obstáculos Internos:** Nó `$Obstacles` preparado para futuras adições manuais.

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

## 3. Controlador de Níveis e Cenas (`level_controller.gd` & `base_level.gd`)

O gerenciamento de estágios combina montagem visual por cena com compatibilidade procedural:
1. **Carregamento Automático de Cenas:** O `LevelController` busca por `res://scenes/levels/level_%02d.tscn`. Se a cena existir, ela é instanciada dinamicamente sob a hierarquia de jogo.
2. **Fallback Procedural Suave:** Caso o nível solicitado ainda não possua cena própria montada, o sistema ativa os geradores procedurais anteriores (`_build_level_2()`, `_build_procedural_level()`), garantindo continuidade ininterrupta do ciclo de jogo.
3. **Ponto de Spawn e Câmera:** O robô cortador é reposicionado automaticamente no marcador `CutterSpawn` da fase.
4. **Execução Standalone (F6):** Ao executar diretamente a cena do nível no editor via F6, o script `base_level.gd` intercepta a chamada e direciona para a cena mestre `main.tscn` configurando o nível correspondente.
