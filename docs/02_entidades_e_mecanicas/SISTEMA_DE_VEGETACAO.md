# Sistema de Vegetação e Colheita 🌾🌸

Este documento define as especificações das espécies vegetais, mecânica de resistência, ciclo de vida dos tufos e geração de partículas em **Grass Cut Bot**.

---

## 1. Classificação das Espécies Vegetais

| Variedade | Cena / Material | Saúde Base | Regra de Lote & Moedas | Partículas | Comportamento e Papel no Jogo |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Grama Verde Clássica** | `grass_green` | 1 golpe | 10 físicos = 1 meta = 1 🪙 | Verde esmeralda | Vegetação fundamental presente em todos os estágios. Ceifada instantaneamente. |
| **Grama Amarela Solar** | `grass_yellow` | 1 golpe | 10 físicos = 1 meta = 1 🪙 | Dourado solar | Variação estética cosmética (1x HP / 1 moeda). |
| **Grama Azul Celeste** | `grass_blue` | 1 golpe | 10 físicos = 1 meta = 1 🪙 | Azul ciano | Vegetação cosmética litorânea (Fases 06+). |
| **Grama Roxa Mística** | `grass_purple` | 1 golpe | 10 físicos = 1 meta = 1 🪙 | Roxo neon | Vegetação cosmética noturna / labiríntica (Fases 10+). |
| **Grama Branca Algodão** | `grass_white` | 1 golpe | 10 físicos = 1 meta = 1 🪙 | Branco puro | Variação cosmética de alto contraste. |
| **Grama Vermelha Rubi** | `grass_red` | 1 golpe | 10 físicos = 1 meta = 1 🪙 | Vermelho rubi | Variação cosmética para áreas intensas. |
| **Grama Preta Vulcânica** | `grass_black` | 1 golpe | 10 físicos = 1 meta = 1 🪙 | Grafite carvão | Variação cosmética dramática. |
| **Trigo Dourado (Meta 2x)** | `wheat` | 2 golpes | 1 físico = 1 meta = 3 🪙 | Dourado ouro | Cultura de tile (Camada 2). Exige 2 golpes ou upgrade de potência $\ge 2$. Meta direta 1:1 e 3 moedas. |
| **Flor Silvestre Nobre** | `flower` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Pétalas magenta | Modelo em 3 partes (`Flower_Stem`, `Flower_Leaves`, `Flower_Petals`). No Hit 1, 2 pétalas + 1 folha se desprendem (`FlowerDetachPiece`): sobem a 4~5 m/s, caem, encolhem em 0,4 s e somem (Melhorias 138/139). Despetalação em 2 levas (Hit 1 e 2). |
| **Rosa Encantada** | `flower_rose` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Pétalas carmim rubi | Modelo em 3 partes com gradiente escuro→claro. No Hit 1 ejeta 2 pétalas externas e 1 folha no ar. Despetalação externa (Hit 1) e interna (Hit 2). |
| **Margarida do Campo** | `flower_daisy` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Pétalas brancas | Modelo em 3 partes com miolo ouro vibrante. No Hit 1 ejeta 2 pétalas brancas e 1 folha no ar. Despetalação em 2 levas. |
| **Girassol Solar** | `flower_sunflower` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Pétalas amarelo solar | Modelo em 3 partes com disco central avelã e pétalas em leque dourado. No Hit 1 ejeta 2 pétalas e 1 folha no ar. Ceifa fatal no 3º golpe. |
| **Flor Sino (Campânula)** | `flower_bell` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Pétalas azul campânula | Modelo em 3 partes com pétalas em sino azul celeste. No Hit 1 ejeta 2 sinos e 1 folha no ar. Despetalação em 2 levas. |
| **Cravo Corola** | `flower_corolla` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Pétalas coral damasco | Modelo em 3 partes com coroa aberta. No Hit 1 ejeta 2 pétalas coral e 1 folha no ar. Despetalação progressiva. |
| **Tulipa Imperial** | `flower_tulip` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Pétalas vermelho rubi | Modelo em 3 partes com cálice imperial. No Hit 1 ejeta 2 cálices e 1 folha no ar. Despetalação externa e interna. |
| **Canteiro Florido** | `flower_bed` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Pétalas lilás violeta | Modelo em 3 partes com tufo largo rasteiro. No Hit 1 ejeta 2 florzinhas inteiras e 1 folha no ar. Ceifa rente ao solo no 3º hit. |

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
  - Micro-tufos densos com 39 lâminas e volume foliar farto garantem visual exuberante e orgânico mantendo alta performance mobile via GPU Instancing.
- **Grade Espacial Lógica e Corte Circular Preciso:**
  - O corte ocorre por proximidade radial de micro-tufo sob o raio da lâmina da serra, conferindo uma borda de corte perfeitamente circular.
  - A contagem de colheita e premiação econômica é consolidada por célula lógica de $0.40\text{m}$, garantindo que nunca restem tufos órfãos visíveis sem contabilização da vitória.
- **Formato JSON v3:** As fases armazenam `grass_vectors` (lista de polígonos fechados e furos), com retrocompatibilidade automática com os formatos legados v2 (`vegetation.rows`) e v1 (`objects`).

---

## 3. Ciclo de Dano e Corte

1. **Rigidez Física Ativa, Escala Visual (Trigo +100%, Flores +30%) & Mastigação Sem Knockback:**
   - **Trigo Ampliado em +100% (Escala Dobrada):** O modelo 3D de trigo (`wheat_01.glb`) opera com escala visual ampliada em **+100%** (`scale_y: 1.10..1.40`, `scale_xz: 0.68..0.92` em `VegetationGrid` e `IslandNode`, e `0.96..1.16` em `plant.gd`), conferindo espigas altas, fartas e volumosas com presença imponente de plantação sobre a ilha.
   - **Flores Ampliadas em +30%:** Todas as 8 espécies de flores nobres operam com escala visual ampliada em **+30%** (`0.52 -> 0.676` no `VegetationGrid` e `IslandNode`, e `0.624..0.754` em `plant.gd`), destacando suas silhuetas e cores sobre o gramado.
   - Plantas resistentes com mais de 1 ponto de vida (trigo e flores) atuam como corpos rígidos na grade espacial (`resolve_rigid_plant_collision`) enquanto estiverem vivas (`health > 0` e `is_cut == 0`).
   - O corpo do cortador ($R_{\text{body}} = 0.30\text{m}$) é impedido de avançar por cima da planta ($R_{\text{wheat}} = 0.18\text{m}$, $R_{\text{flower}} = 0.23\text{m}$). O robô desliza suavemente ao contornar, mas não consegue atravessar até destruí-la.
   - **Sem Knockback Reverso em Vegetação:** Diferente das rochas sólidas (que punem colisões com recuo e atordoamento), a vegetação resistente não arremessa o robô para trás nem aplica stun. Em vez disso, aplica apenas uma leve absorção mecânica na suspensão (`shock_compression = -0.016`), preservando o controle direcional do jogador e mantendo a lâmina em contato contínuo para mastigar a planta.
2. **Janela Ágil de Cooldown de 0.28s & Micro-Tremor Contínuo:**
   - Cada golpe subsequente opera com um intervalo rápido e dinâmico de **0.28 segundo** (`MULTI_HIT_COOLDOWN_SEC = 0.28`), permitindo que a lâmina processe cortes contínuos em frações de segundo ao ser mantida encostada.
   - Durante essa janela de 0.28s, enquanto a serra mantiver contato ativo com o tufo resistente, a planta vibra com um **micro-tremor procedural de alta frequência** ($\approx 65\text{Hz}$ e $\pm 0.022\text{m}$ de amplitude), simulando os dentes de aço mastigando o caule resistente antes do corte definitivo.
3. **Golpe Parcial (Resistência Ativa), Partículas e Despetalação:**
   - Ao desferir cada hit parcial (`health > power`):
   - Dispara imediatamente efeito sonoro de corte (`AudioManager.play_cut_sfx(false)`) e pulso háptico mobile suave (`GameManager.trigger_haptic_cut()`).
   - Um Tween de squash & stretch rápido é acionado (`scale * 1.25` em 0.05s voltando ao normal).
   - No trigo (`wheat`), ejeta uma nuvem parcial de fragmentos de palha (`spawn_grass_cut_particles`).
   - Nas flores, o estágio de despetalação (`instance_hit_stage` no shader) avança na GPU, acompanhado de fragmentos desprendíveis (`flower_detach_pieces`) e confetes voando em arco (`spawn_flower_petal_burst`).
4. **Corte Concluído & Sistema de Partículas Geométricas em Arco (`_perform_cut`):**
   - O colisor `Area3D` é desativado imediatamente para evitar múltiplos registros acidentais.
   - **Partículas Geométricas Voadoras com Física Parabólica:**
     - As peças não são mais hastes verticais rígidas: operam com rotação 3D livre (`particle_flag_rotate_y = false`), espalhamento hemisférico aberto (`spread = 82°`, velocidade $3.2 \dots 5.2\text{ m/s}$) e gravidade acentuada (`-14.0 m/s²`), criando um efeito espetacular de pedaços espirrando para os lados e caindo ao chão.
     - **Grama e Trigo:** Ejetam fragmentos geométricos estilizados de **triângulos** (8 unidades) e **quadrados** (6 unidades) tingidos na cor correspondente da vegetação com leve brilho próprio emissivo.
     - **Flores:** Ejetam uma explosão festiva composta por **círculos** da cor da pétala (8 unidades), **círculos** da cor do miolo (4 unidades), **quadrados** verdes representando o caule (3 unidades) e **triângulos** verdes representando folhas (3 unidades).
   - O `GameManager.register_cut(plant_key, coin_reward, cut_pos)` é notificado:
     - Incrementa as moedas da fase multiplicadas pelo multiplicador ativo da oficina.
     - Dispara o sinal `coin_popup_requested(cut_pos, earned, plant_type)` gerando os números flutuantes cartoon 3D (`+1`, `+3`, `+5`) com contorno preto e rastro contínuo (*number trail*) via `FloatingCoinManager`.
     - Dispara o pulso háptico suave no celular (`Input.vibrate_handheld(15)`).
     - Decrementa a cota pendente no Top HUD da partida.
   - **Aparas de Folhas Cortadas Deitadas no Solo (Clippings):** Ao ser cortada, a moita alta de vegetação desaparece imediatamente (`HIDDEN_TRANSFORM`), e uma malha de **6 lâminas fatiadas deitadas horizontalmente no plano do solo** ($Y \approx 0.005\text{m}$, com orientações em $360^\circ$ e tom contrastante mais escuro) surge no local via `_clipping_multimeshes`, reproduzindo com fidelidade o rastro salpicado de aparas de grama cortada deitado no chão da ilha. As aparas operam com controle dinâmico de `visible_instance_count` (Melhoria 093), garantindo que a GPU processe apenas os tufos efetivamente ceifados, mantendo 60 FPS estáveis mesmo ao final de fases densas.

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
| **Trigo Dourado** | `wheat_tuft.tscn` | `interactive_wheat_material.tres` | Dourado trigo (`#f5c430`) | Cultura nobre de tile (`wheat_01.glb`), espiga e folhas 3D |

### C. Modelo 3D Dedicado de Trigo (`wheat_01.glb`)
- **Geometria 3D Completa:** Extraído cirurgicamente como uma haste individual de trigo (`wheat_01_mesh`), contendo caule cilíndrico, folhas laterais e espiga no topo com grãos modelados em low poly (338 vértices e 165 faces).
- **Origem e Ancoragem:** Pivô rigorosamente ancorado no solo na base da haste em $(0.0, 0.0, 0.0)$, com dimensões calibradas para altura $1.10\text{m}$ e largura $0.36\text{m} \times 0.17\text{m}$, casando com o colisor cilíndrico de raio $0.18\text{m}$ e altura $0.55\text{m}$.
- **Mapeamento UV e Parâmetro `invert_height`:** Na malha `wheat_01.glb`, a coordenada $UV.y$ é orientada de $1.0$ na base/solo ($Y=0.0$) até $0.0$ no topo da espiga ($Y=1.10$). O material `interactive_wheat_material.tres` define `shader_parameter/invert_height = true`. O shader `interactive_grass.gdshader` computa `float raw_h = invert_height ? (1.0 - UV.y) : UV.y;`, garantindo:
  - **Base 100% Firme no Solo:** $bend\_factor = 0.0$ na raiz, impedindo qualquer deslocamento ou descolamento do solo.
  - **Espiga com Balanço Livre no Topo:** $bend\_factor = 1.0$ na ponta, balançando harmonicamente ao vento e flexionando-se quando o robô cortador se aproxima.
  - **Fase Orgânica por Posição de Mundo:** O shader detecta que a cor de vértice do trigo não possui rotação assada (`is_all_black`), atribuindo a cada tufo de trigo uma fase espacial única (`world_vert.x * 1.7 + world_vert.z * 2.3`).
  - **Gradiente Vertical Fiel:** O gradiente toon colore a base com âmbar terroso (`color_base`) e a espiga superior com dourado radiante (`color_light`).
- **Exportação Canônica:** Exportado do Blender para `assets/models/wheat_01.glb` com `export_apply=True` e `export_yup=True`.

### D. Animação de Vento e Interatividade com o Cortador no Modelo 3D
Conectamos a geometria única ao shader espacial `interactive_grass.gdshader`:
1. **Mapeamento UV e Ancoragem:** As coordenadas $UV.y$ da malha original variam exatamente de $1.0$ (na raiz em $Y=0.0$) a $0.0$ (no topo em $Y=1.025$). O shader calcula `height_factor = clamp(1.0 - UV.y, 0.0, 1.0)` e `bend_factor = pow(height_factor, 1.8)`, garantindo que as raízes permaneçam firmemente plantadas ao solo enquanto as pontas ondulam com o vento.
2. **Sincronização em Tempo Real:** O script `cutter.gd` atualiza continuamente `cutter_pos` e `cutter_interact_radius` em todos os materiais de grama, fazendo com que os tufos 3D se curvem suavemente e se comprimam para baixo com a aproximação da serra antes do corte.
3. **Performance Otimizada:** Cada tufo possui apenas 1 nó de malha ativo, eliminando 75% dos nós invisíveis na árvore de cena e permitindo arraste e duplicação direta no Viewport 3D da Godot.

