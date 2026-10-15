# Melhoria 022: Animação Pendular Independente de Folhas e Partículas de Corte em Pedaços [v0.4.5] 🌿✂️

## 1. Visão Geral e Contexto
O usuário solicitou uma reformulação na movimentação da grama e no efeito de corte:
- *"não estou gostando da animação da grama, conseguimos fazer ela pender suavemente de uma lado para o outro cada folha independente? teria que ser cada folha um objeto para poder controlar?"*
- *"e quando cortar gostaria que as folhas voassem para cima partidas e caissem com a gravidade desaparecendo"*

Esta melhoria implementa a oscilação pendular individual por folha inteiramente no Vertex Shader através de atributos assados no modelo, e reformula as partículas de corte com malha 3D estilizada de folhas partidas, gravidade física e tumbling tridimensional.

---

## 2. Implementações Técnicas

### A. Análise e Resposta Arquitetural
- **Não fragmentar em nós individuais:** Criar nós Godot para cada folha (56 folhas por tufo $\times$ centenas de tufos) geraria dezenas de milhares de nós e draw calls, degradando drasticamente o desempenho mobile.
- **Solução via Vertex Shader na GPU:** A identidade de cada folha é gravada como atributo de vértice no arquivo 3D e processada em uma única draw call por tufo.

### B. Atributos de Vértice Assados no Blender (`grass_01.blend` -> `grass_01.glb`)
- Identificados os 56 componentes desconectados (folhas) que compõem o tufo refinado de 392 vértices.
- Criada a camada de atributos de vértice `blade_data` (`COLOR_0`), codificando:
  - `COLOR.r`: Fase aleatória individual ($\phi \in [0.0, 1.0]$).
  - `COLOR.g`: Ângulo azimutal de orientação radial normalizado ($\theta \in [0.0, 1.0]$).
  - `COLOR.b`: Frequência natural ligeiramente variável ($0.85 \dots 1.15$).
- Exportação glTF 2.0 executada com `export_vertex_color='ACTIVE'`, `export_apply=True` e `export_yup=True`.

### C. Shader Espacial Reescrito (`interactive_grass.gdshader`)
- **Pender Lateral ("de um lado para o outro"):** Oscilação senoidal suave `sway_side = sin(TIME * (wind_speed * blade_freq) + blade_phase)` projetada no vetor perpendicular `dir_side`.
- **Respiração Radial:** Oscilação secundária amortecida ao longo do crescimento da folha (`dir_fwd`).
- **Ancoragem e Flexibilidade:** Curvatura com `bend_factor = pow(height_factor, 1.8)`, mantendo raízes firmes ao solo enquanto as pontas ondulam com liberdade.
- **Fallback Gracioso:** Caso uma malha sem atributos de cor seja renderizada, um cálculo procedural baseado no ângulo do vértice assume sem quebras.
- **Interação Preservada:** Afastamento radial e compressão vertical elástica sob a serra continuam ativos.

### D. Novo Efeito de Corte com Folhas Partidas (`cut_leaf_piece.obj`)
- **Malha Estilizada:** Modelada e exportada malha Low Poly chanfrada de folha cortada (`cut_leaf_piece.obj`, 5 vértices, acabamento sem culling de faces).
- **Física Gravitacional (`CPUParticles3D`):**
  - Ejeção em cone ascendente (`spread = 50.0`, velocidade `3.8 ~ 5.6 m/s`).
  - Gravidade física real: `gravity = Vector3(0, -9.8, 0)`.
  - Tumbling 3D: Rotação tridimensional contínua (`angular_velocity = 180° ~ 540°/s`).
  - Curva de escala: Mantém escala 1.0 durante a ascensão e queda, encolhendo suavemente a zero no impacto com o solo.
  - Atualizadas todas as 5 variantes: `grass_tuft.tscn`, `grass_green.tscn`, `grass_yellow.tscn`, `grass_blue.tscn`, `grass_purple.tscn`.

---

## 3. Validação e Qualidade
- **Zero Warnings / Zero Erros:** Verificado em execução de debug contínua via Godot MCP (`run_project` e `get_debug_output`).
- **SemVer:** Incrementado para **`v0.4.5`** em `project.godot`.
