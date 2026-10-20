# Sistema de Vegetação e Colheita 🌾🌸

Este documento define as especificações das espécies vegetais, mecânica de resistência, ciclo de vida dos tufos e geração de partículas em **Grass Cut Bot**.

---

## 1. Classificação das Espécies Vegetais

| Variedade | Cena | Saúde Base | Moedas Ganhas | Partículas | Comportamento e Papel no Jogo |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Grama Verde Básica** | `grass_tuft.tscn` | 1 golpe | 1 moeda | Verde esmeralda | Vegetação fundamental presente em todos os estágios. Ceifada instantaneamente. |
| **Trigo Dourado** | `wheat_tuft.tscn` | 2 golpes | 3 moedas | Dourado ouro | Exige duas passadas ou lâmina com upgrade de potência $\ge 2$. Cota de colheita. |
| **Flores do Campo** | `flower_tuft.tscn` | 2 golpes | 5 moedas | Pétalas magenta | Vegetação nobre com alto valor econômico. Cota de colheita nos níveis avançados. |

---

## 2. Estrutura do Nó de Vegetação (`plant.tscn`)

Cada tufo possui a seguinte árvore enxuta (as partículas de corte operam em um Pool Estático Compartilhado de 16 emissores em `plant.gd`, evitando instanciar milhares de `CPUParticles3D` ociosos):
```
Tuft (Node3D - grupo "plants", script plant.gd)
├── Area3D (Layer 4, Mask 0, grupo "vegetation")
│   └── CollisionShape3D (Cylinder r=0.18m, h=0.45m)
└── VisualMesh (Node3D - malha Low Poly das folhas/espigas com cast_shadow = OFF)
```

- **Estrutura 3D Estilizada Low Poly e Gramado Condensado:**
  - O tufo de grama básico (`grass_tuft.tscn`) utiliza o modelo 3D oficial `assets/models/grass_01.glb` (baseado na malha de 112 vértices e 80 faces `grass_varien_4_grass_0`).
  - **Calibração de Escala Condensada:** No `_ready()`, cada tufo recebe uma rotação aleatória no eixo Y (`0.0` a $2\pi$) e uma calibração proporcional precisa: altura compacta no eixo Y reduzida em 25% (`0.53` a `0.64`) e diâmetro horizontal reduzido em 50% (`0.40` a `0.45m`).
  - **Grade de Célula Reduzida (0.40m):** A célula de vegetação passa a medir exatamente $0.40\text{m} \times 0.40\text{m}$, coincidindo com o diâmetro do tufo. Cada bloco de terreno de $0.80\text{m} \times 0.80\text{m}$ acomoda perfeitamente uma subgrade $2 \times 2$ com 4 células de vegetação, garantindo um gramado contínuo, farto, denso e condensado.
  - **Flores e Trigo em Slots de Tufo:** Flores e trigo ocupam 1 célula de $0.40\text{m}$ na mesma cota do tufo de grama, com as demais células do bloco preenchidas por grama.
  - **Rochas Livres de Grama:** As rochas mantêm seu tamanho físico original (raio $0.36\text{m}$) e onde há rocha nenhuma grama é gerada sob ou dentro da sua área.

---

## 3. Ciclo de Dano e Corte

1. **Golpe Parcial (Resistência Ativa):**
   - Se o tufo receber dano inferior à sua saúde restante (`health > power`):
   - Um Tween de squash & stretch rápido é acionado (`scale * 1.25` em 0.05s voltando ao normal), dando feedback imediato de que a planta sofreu impacto mas resistiu.
2. **Corte Concluído (`_perform_cut`):**
   - O colisor `Area3D` é desativado imediatamente para evitar múltiplos registros acidentais.
   - Um emissor do **Pool Estático Compartilhado (`_particle_pool`, 16 instâncias)** em `plant.gd` é posicionado no tufo e ejeta 14 pedaços de folhas partidas estilizadas (`cut_leaf_piece.obj`) distribuídas por anel (`emission_shape = RING`, raio $0.18\text{m}$), com cor sincronizada ao `color_top` do material da planta e giro 3D sob gravidade natural (`gravity = -9.8 m/s²`, voo de `0.55s`).
   - O `GameManager.register_cut(plant_key, coin_reward)` é notificado:
     - Incrementa as moedas da fase multiplicadas pelo multiplicador ativo.
     - Dispara o pulso háptico suave no celular (`Input.vibrate_handheld(15)`).
     - Decrementa a cota pendente no Top HUD da partida.
   - O modelo 3D do tufo é fatiado e achatado instantaneamente via Tween em 0.04s (`scale * (1.05, 0.05, 1.05)`), gerando um corte seco e limpo e executando `queue_free()` imediatamente ao final do Tween (0.04s).

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

### A. Geometria Única no Blender (`grass_01.blend`)
- **Malha Base:** `grass_01_mesh` refinada e enriquecida volumetricamente (392 vértices e 280 faces, divididos em 56 folhas conectadas independentes).
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

### C. Animação de Vento e Interatividade com o Cortador no Modelo 3D
Conectamos a geometria única ao shader espacial `interactive_grass.gdshader`:
1. **Mapeamento UV e Ancoragem:** As coordenadas $UV.y$ da malha original variam exatamente de $1.0$ (na raiz em $Y=0.0$) a $0.0$ (no topo em $Y=1.025$). O shader calcula `height_factor = clamp(1.0 - UV.y, 0.0, 1.0)` e `bend_factor = pow(height_factor, 1.8)`, garantindo que as raízes permaneçam firmemente plantadas ao solo enquanto as pontas ondulam com o vento.
2. **Sincronização em Tempo Real:** O script `cutter.gd` atualiza continuamente `cutter_pos` e `cutter_interact_radius` em todos os materiais de grama, fazendo com que os tufos 3D se curvem suavemente e se comprimam para baixo com a aproximação da serra antes do corte.
3. **Performance Otimizada:** Cada tufo possui apenas 1 nó de malha ativo, eliminando 75% dos nós invisíveis na árvore de cena e permitindo arraste e duplicação direta no Viewport 3D da Godot.

