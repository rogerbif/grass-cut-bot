# Melhoria 023: Ancoragem Rígida da Base das Folhas e Calibração de Partículas de Corte [v0.4.6] 🌿🎯

## 1. Visão Geral e Contexto
O usuário solicitou três refinamentos fundamentais de física e game feel:
- *"vamos para mais um ajuste quando a grama corta aumente as folhas picadas que voam em 50%"*
- *"elas não precisam ir tão lomje reduza o alcance do lançamento"*
- *"o movimento das folhas a base deve ficar parada como o eixo fosse na base"*

---

## 2. Implementações Técnicas

### A. Ancoragem Rígida da Base como Eixo de Dobradiça (`interactive_grass.gdshader`)
- **Correção da Inversão de Coordenadas no glTF:**
  - Na convenção oficial glTF 2.0, o exportador inverte o eixo vertical das coordenadas de textura, de modo que $UV.y = 0.0$ corresponde às raízes e $UV.y = 1.0$ corresponde às pontas das folhas.
  - O shader utilizava anteriormente `1.0 - UV.y`, o que invertia o comportamento (aplicava força máxima na raiz e travava a ponta).
  - Corrigido diretamente para `float h = clamp(UV.y, 0.0, 1.0)`.
  - Aplicado `bend_factor = smoothstep(0.06, 1.0, h)^2`: a base ($0 \dots 6\%$) recebe rigorosamente `0.0` de deformação, fixando a raiz ao solo com 100% de estabilidade.
- **Movimento em Dobradiça com Compensação de Arco:**
  - O topo das folhas oscila livremente no ápice com amplitude plena.
  - Aplicada compensação vertical geométrica `VERTEX.y -= sway_displacement * 0.22`: conforme o topo se curva lateralmente, ele desce suavemente em arco, preservando o comprimento natural da folha sem esticar a malha.

### B. Calibração e Expansão das Partículas de Corte (`CPUParticles3D`)
- **Aumento de 50% no Volume:**
  - Quantidade ampliada de 20 para **30 folhas partidas** (`amount = 30`) em todas as variantes de cena.
- **Redução do Alcance e Dispersão:**
  - Velocidade inicial reduzida de `3.8 ~ 5.6 m/s` para `2.4 ~ 3.8 m/s`.
  - Abertura cônica do lançamento reduzida de `50.0°` para `32.0°`, concentrando a fonte de folhas partidas próxima ao ponto exato da colheita.
  - Gravidade física ajustada para `gravity = Vector3(0, -10.5, 0)`.
  - Duração de voo calibrada para `0.65s` com encolhimento ágil ao atingir o solo.
- **Cenas Atualizadas:**
  - [`grass_tuft.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/plants/grass_tuft.tscn)
  - [`grass_green.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/plants/grass_green.tscn)
  - [`grass_yellow.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/plants/grass_yellow.tscn)
  - [`grass_blue.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/plants/grass_blue.tscn)
  - [`grass_purple.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/plants/grass_purple.tscn)

---

## 3. Validação e Qualidade
- **Zero Warnings / Zero Erros:** Verificado em execução de debug contínua via Godot MCP (`run_project` e `get_debug_output`).
- **SemVer:** Incrementado para **`v0.4.6`** em `project.godot`.
