# Sistema de Vegetação e Colheita 🌾🌸

Este documento define as especificações das espécies vegetais, mecânica de resistência, ciclo de vida dos tufos e geração de partículas em **Grass Cut Bot**.

---

## 1. Classificação das Espécies Vegetais

| Variedade | Cena | Saúde Base | Regra de Lote & Moedas | Partículas | Comportamento e Papel no Jogo |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Grama Verde Básica** | `grass_tuft.tscn` | 1 golpe | 10 físicos = 1 meta = 1 🪙 | Verde esmeralda | Vegetação fundamental presente em todos os estágios. Ceifada instantaneamente. |
| **Trigo Dourado** | `wheat_tuft.tscn` | 2 golpes | 10 físicos = 1 meta = 3 🪙 | Dourado ouro | Exige duas passadas ou lâmina com upgrade de potência $\ge 2$. Cota de colheita. |
| **Flores do Campo** | `flower_tuft.tscn` | 2 golpes | 1 físico = 1 meta = 5 🪙 | Pétalas magenta | Vegetação nobre com alto valor econômico. Cota de colheita nos níveis avançados. |

---

## 2. Arquitetura de Renderização e Corte em Lote (`VegetationGrid` & `VectorGrassField`)

Durante as fases de gameplay (e nas ilhas do Menu Inicial), toda a vegetação e os blocos visuais de terreno operam em lote via **`VegetationGrid` (`res://scripts/plants/vegetation_grid.gd`)** integrado ao campo vetorial contínuo **`VectorGrassField` (`res://scripts/level/vector_grass_field.gd`)**:
- **Campo de Vegetação Vetorial 2D (Coordenadas Contínuas em Metros):**
  - A grama é definida por polígonos fechados contínuos (`PackedVector2Array`) no plano $XZ$, sem restrições de matriz ou células mínimas de grid.
  - **Operações Booleanas com Clipper C++:** União automática (`Geometry2D.merge_polygons`) ao desenhar novas áreas e recorte analítico (`Geometry2D.clip_polygons`) com a borracha ou sobreposição de rochas.
  - **Amostragem Poisson Disk (Algoritmo de Bridson Otimizado):** Geração de tufos orgânicos com distribuição Blue Noise uniforme ($r = 0.22\text{m}$) acelerada por grade espacial, executando níveis densos em apenas $2\text{ ms} \dots 5\text{ ms}$.
  - **Afinamento Suave de Borda:** A distância de cada tufo amostrado até as arestas do polígono é mensurada por `Geometry2D.get_closest_point_to_segment()`, atenuando a escala dos tufos de borda ($0.50 \dots 1.0$) de forma gradual e orgânica.
  - **Malhas Planas Trianguladas de Piso:** Triangulação direta dos polígonos vetoriais via `Geometry2D.triangulate_polygon()`, gerando superfícies planas rente ao solo ($Y = 0.005$) com materiais foscos sólidos (`roughness = 0.90`) que desenham a base verde/dourada sob a vegetação.
- **GPU Instancing (`MultiMeshInstance3D`):**
  - Os tufos de vegetação são agrupados em até 9 `MultiMeshInstance3D` (`grass_green`, `grass_yellow`, `grass_blue`, `grass_purple`, `grass_white`, `grass_red`, `grass_black`, `wheat` e `flower`) com `cast_shadow = SHADOW_CASTING_SETTING_OFF`.
  - Micro-tufos densos com 21 folhas (+50% de volume foliar, 147 vértices e 105 faces) garantem visual exuberante e orgânico mantendo alta performance mobile via GPU Instancing.
- **Grade Espacial Lógica e Corte Circular Preciso:**
  - O corte ocorre por proximidade radial de micro-tufo sob o raio da lâmina da serra, conferindo uma borda de corte perfeitamente circular.
  - A contagem de colheita e premiação econômica é consolidada por célula lógica de $0.40\text{m}$, garantindo que nunca restem tufos órfãos visíveis sem contabilização da vitória.
- **Formato JSON v3:** As fases armazenam `grass_vectors` (lista de polígonos fechados e furos), com retrocompatibilidade automática com os formatos legados v2 (`vegetation.rows`) e v1 (`objects`).

---

## 3. Ciclo de Dano e Corte

1. **Golpe Parcial (Resistência Ativa):**
   - Se o tufo receber dano inferior à sua saúde restante (`health > power`):
   - Um Tween de squash & stretch rápido é acionado (`scale * 1.25` em 0.05s voltando ao normal), dando feedback imediato de que a planta sofreu impacto mas resistiu.
2. **Corte Concluído (`_perform_cut`):**
   - O colisor `Area3D` é desativado imediatamente para evitar múltiplos registros acidentais.
   - Um emissor do **Pool Estático Compartilhado (`_particle_pool`, 16 instâncias)** em `plant.gd` é posicionado no tufo e ejeta 21 pedaços de folhas partidas estilizadas (`cut_leaf_piece.obj`) distribuídas por anel (`emission_shape = RING`, raio $0.18\text{m}$), com cor sincronizada ao `color_top` do material da planta e giro 3D sob gravidade natural (`gravity = -9.8 m/s²`, voo de `0.55s`).
   - O `GameManager.register_cut(plant_key, coin_reward, cut_pos)` é notificado:
     - Incrementa as moedas da fase multiplicadas pelo multiplicador ativo da oficina.
     - Dispara o sinal `coin_popup_requested(cut_pos, earned, plant_type)` gerando os números flutuantes cartoon 3D (`+1`, `+3`, `+5`) com contorno preto e rastro contínuo (*number trail*) via `FloatingCoinManager`.
     - Dispara o pulso háptico suave no celular (`Input.vibrate_handheld(15)`).
     - Decrementa a cota pendente no Top HUD da partida.
   - **Aparas de Folhas Cortadas Deitadas no Solo (Clippings):** Ao ser cortada, a moita alta de vegetação desaparece imediatamente (`HIDDEN_TRANSFORM`), e uma malha de **6 lâminas fatiadas deitadas horizontalmente no plano do solo** ($Y \approx 0.005\text{m}$, com orientações em $360^\circ$ e tom contrastante mais escuro) surge no local via `_clipping_multimeshes`, reproduzindo com fidelidade o rastro salpicado de aparas de grama cortada deitado no chão da ilha.

---

## 4. Shader Interativo de Vegetação (Balanço Pendular Independente de Folhas)

As plantas utilizam o shader espacial `interactive_grass.gdshader`:
1. **Curvatura Elástica Não-Linear e Eixo Fixo na Base:**
   - **Ancoragem Rígida da Raiz:** No formato glTF, as coordenadas de textura possuem $UV.y = 0.0$ nas raízes e $UV.y = 1.0$ nas pontas. A altura normalizada é dada diretamente por $h = \text{clamp}(UV.y, 0.0, 1.0)$, e o fator de flexão por $\text{bend\_factor} = \text{smoothstep}(0.06, 1.0, h)^2$. Qualquer vértice na faixa de $0 \dots 6\%$ de altura (toda a base plantada) recebe rigorosamente `bend_factor = 0.0`, fixando a raiz 100% estática ao solo como um eixo/dobradiça inabalável, enquanto as pontas no topo recebem amplitude total ($1.0$).
   - Converte os vértices para o espaço de mundo ($XZ$), calcula o vetor de afastamento radial e projeta no espaço de modelo via `mat3(inverse(MODEL_MATRIX))`.
   - Aplica compressão elástica no eixo Y (`VERTEX.y -= power * interact_power * 0.14 * bend_factor`), simulando o achatamento da grama sob a carcaça da serra.
2. **Animação Pendular Independente por Folha (Atributos de Vértice `COLOR`):**
   - Cada uma das 56 folhas de cada tufo possui fase ($\phi$), orientação radial ($\theta$) e frequência natural assadas no atributo de vértice `COLOR` durante o export do Blender (`grass_01.blend`):
     - `COLOR.r`: Fase individual normalizada $[0.0, 1.0]$.
     - `COLOR.g`: Ângulo azimutal de orientação radial normalizado.
     - `COLOR.b`: Frequência natural ($0.85 \dots 1.15$).
   - O Vertex Shader decompõe a folha em dois vetores no plano horizontal: `dir_side` (perpendicular à lâmina) e `dir_fwd` (ao longo do crescimento).
   - **Pender Lateral ("de um lado para o outro"):** Oscilação senoidal suave `sway_side = sin(TIME * (wind_speed * blade_freq) + blade_phase)` aplicada ao longo de `dir_side`.
   - **Respiração Radial:** Oscilação secundária amortecida `sway_fwd = cos(...) * 0.35` ao longo de `dir_fwd`.
   - **Compensação de Arco:** Ao inclinar horizontalmente a partir da base imóvel, o topo sofre leve redução em Y (`VERTEX.y -= sway_displacement * 0.22`), preservando geometricamente o comprimento de haste.
   - Como cada folha opera com sua própria fase e orientação, as folhas vizinhas balançam em tempos e direções distintas de forma orgânica, eliminando completamente a sensação de bloco rígido.
   - **Custo Computacional Zero:** Calculado integralmente no Vertex Shader na GPU em uma única draw call por tufo (sem necessidade de nós ou objetos separados para cada folha).
   - Aplica gradiente fosco *Low Poly* da raiz (tom mais escuro e denso) até a ponta (mais viva e iluminada), mantendo `roughness = 0.9` e acabamento sem reflexos especulares plásticos.

---

## 5. Modelo 3D Estilizado Low Poly (`grass_01.glb`) e Cenas Base Coloridas

O arquivo de modelagem `grass_01.blend` contém rigorosamente **1 único modelo default neutro e limpo**, exportado para `assets/models/grass_01.glb`. A definição de cores, materiais de shader e partículas ocorre diretamente na engine através de cenas especializadas.

### A. Geometria Única no Blender (`grass_01.blend` & `grass_01.glb`)
- **Malha Base Otimizada:** `grass_01_mesh` densa e volumosa (147 vértices e 105 faces, compostos por 21 folhas conectadas independentes, representando um ganho de +50% em relação ao modelo anterior).
- **Densidade Perfeita no Grid 0.20m:** Com a sub-divisão do campo em micro-células de $0.20\text{m}$, essa geometria de 21 folhas gera uma densidade foliar visual de ~525 folhas/m², mantendo performance fluída de 60 FPS no mobile e silhueta orgânica rica.
- **Normalização e Origem:** Dimensões $1.01\text{m} \times 0.99\text{m} \times 1.025\text{m}$, coordenadas $(0.0, 0.0, 0.0)$ e base ancorada em $Z = 0.0$.
- **Atributos de Folha Assados:** Camada `blade_data` exportada como `COLOR_0` no glTF com `export_vertex_color='ACTIVE'` e `export_attributes=True`.
- **Material Neutro:** `M_Grama_Default` sem texturas e sem cores saturadas aplicadas diretamente no Blender.

### B. Cenas Base Especializadas por Cor (`scenes/plants/`)
No Godot, cada tipo vegetal é encapsulado em uma cena própria que instancia a malha única `grass_01.glb` aplicando seu respectivo `material_override` com o shader espacial `interactive_grass.gdshader`:

| Cena no Godot | Arquivo | Shader Material | Partículas de Corte (`cut_leaf_piece.obj`) | Bioma / Papel Visual |
| :--- | :--- | :--- | :--- | :--- |
| **Grama Verde** | `grass_tuft.tscn` / `grass_green.tscn` | `interactive_grass_material.tres` | Verde (`#40bf4d`) | Vegetação padrão da ilha |
| **Grama Amarela** | `grass_yellow.tscn` | `interactive_grass_yellow_material.tres` | Dourado (`#f2c726`) | Pastagem seca e campos ensolarados |
| **Grama Azul** | `grass_blue.tscn` | `interactive_grass_blue_material.tres` | Azul celeste (`#33a6f2`) | Bioma místico / flora gélida |
| **Grama Roxa** | `grass_purple.tscn` | `interactive_grass_purple_material.tres` | Magenta/Roxo (`#ad40f2`) | Vegetação exótica e mágica |
| **Grama Branca** | `grass_white.tscn` | `interactive_grass_white_material.tres` | Branco gelo (`#f5f7ff`) | Flora alpina / contraste luminoso |
| **Grama Vermelha** | `grass_red.tscn` | `interactive_grass_red_material.tres` | Vermelho rubi (`#f22e33`) | Flora carmesim vibrante |
| **Grama Preta (90%)** | `grass_black.tscn` | `interactive_grass_black_material.tres` | Cinza antracite escuro (`#1c1c21`) | Contraste escuro fosco (90% preto) |

### C. Animação de Vento e Interatividade com o Cortador no Modelo 3D
Conectamos a geometria única ao shader espacial `interactive_grass.gdshader`:
1. **Mapeamento UV e Ancoragem:** As coordenadas $UV.y$ da malha original variam exatamente de $1.0$ (na raiz em $Y=0.0$) a $0.0$ (no topo em $Y=1.025$). O shader calcula `height_factor = clamp(1.0 - UV.y, 0.0, 1.0)` e `bend_factor = pow(height_factor, 1.8)`, garantindo que as raízes permaneçam firmemente plantadas ao solo enquanto as pontas ondulam com o vento.
2. **Sincronização em Tempo Real:** O script `cutter.gd` atualiza continuamente `cutter_pos` e `cutter_interact_radius` em todos os materiais de grama, fazendo com que os tufos 3D se curvem suavemente e se comprimam para baixo com a aproximação da serra antes do corte.
3. **Performance Otimizada:** Cada tufo possui apenas 1 nó de malha ativo, eliminando 75% dos nós invisíveis na árvore de cena e permitindo arraste e duplicação direta no Viewport 3D da Godot.

