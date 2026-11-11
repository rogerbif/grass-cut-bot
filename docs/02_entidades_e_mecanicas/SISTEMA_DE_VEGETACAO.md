# Sistema de Vegetação e Colheita 🌾🌸

Este documento define as especificações das espécies vegetais, mecânica de resistência, ciclo de vida dos tufos, GPU Instancing e geração de partículas em **Grass Cut Bot**.

---

## 1. Classificação das Espécies Vegetais

| Variedade | Cena / Material | Saúde Base | Regra de Lote & Moedas | Partículas | Comportamento e Papel no Jogo |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Grama Verde Clássica** | `grass_green` | 1 golpe | 6 visuais = 1 meta = 1 🪙 | Verde esmeralda | Vegetação fundamental presente em todos os estágios. Ceifada instantaneamente (`GRASS_TUFTS_PER_UNIT = 6`). |
| **Grama Amarela Solar** | `grass_yellow` | 1 golpe | 6 visuais = 1 meta = 1 🪙 | Dourado solar | Variação estética cosmética (1x HP / 1 moeda a cada 6 tufos visuais). |
| **Grama Azul Celeste** | `grass_blue` | 1 golpe | 6 visuais = 1 meta = 1 🪙 | Azul ciano | Vegetação cosmética litorânea (Fases 04+). |
| **Grama Roxa Mística** | `grass_purple` | 1 golpe | 6 visuais = 1 meta = 1 🪙 | Roxo neon | Vegetação cosmética noturna / labiríntica (Fases 06+). |
| **Grama Branca Cristalina** | `grass_white` | 1 golpe | 6 visuais = 1 meta = 1 🪙 | Prata / gelo cristalino | Tom nobre prateado/alpino (`Light: 0.82, 0.88, 0.92`, `Base: 0.24, 0.32, 0.40`). Toon shading rico que evita superexposição e mantém volume 3D fosco elegante. |
| **Grama Vermelha Rubi** | `grass_red` | 1 golpe | 6 visuais = 1 meta = 1 🪙 | Vermelho rubi | Variação cosmética para áreas intensas (Fases 12+). |
| **Grama Preta Vulcânica** | `grass_black` | 1 golpe | 6 visuais = 1 meta = 1 🪙 | Grafite carvão | Variação cosmética dramática (Fases 15+). |
| **Trigo Dourado (Meta 2x)** | `wheat` | 2 golpes | 1 físico = 1 meta = 3 🪙 | Dourado ouro | Cultura de tile (Camada 2). Exige 2 golpes ou upgrade de potência $\ge 2$. Meta direta 1:1 e 3 moedas. |
| **Flor Silvestre Nobre** | `flower` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Miolo amarelo e pétalas rosa (gradiente escuro→claro) | Modelo em 3 partes (`Flower_Stem`, `Flower_Leaves`, `Flower_Petals`). No Hit 1, 2 pétalas + 1 folha se desprendem (`FlowerDetachPiece`). Despetalação progressiva em 2 levas (Hit 1 e 2). |
| **Flor Silvestre (Azul Celeste)** | `flower_blue` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Miolo amarelo âmbar e pétalas ciano pastel com base safira | Variação cromática oficial com shader dedicado e GPU instancing. |
| **Flor Silvestre (Pôr do Sol)** | `flower_sunset` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Miolo amarelo queimado e pétalas damasco/pêssego com base escarlate | Variação cromática oficial com shader dedicado e GPU instancing. |
| **Flor Silvestre (Lilás Encanto)** | `flower_purple` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Miolo branco perolado e pétalas lavanda suave com base púrpura | Variação cromática oficial com shader dedicado e GPU instancing. |
| **Flor Silvestre (Branca Suave)** | `flower_white` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Miolo dourado pastel e pétalas brancas com base marfim quente | Variação cromática oficial com shader dedicado e GPU instancing. |
| **Flor Silvestre (Turquesa Mística)** | `flower_turquoise` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Miolo âmbar radiante e pétalas turquesa com base esmeralda | Variação cromática oficial com shader dedicado e GPU instancing. |
| **Rosa Nobre (Vermelha)** | `flower_rose` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Miolo carmim escuro e pétalas rubi com base vinho profundo | Modelo em 3 partes com gradiente de alta definição. Hit 1 ejeta 2 pétalas externas e 1 folha. |
| **Rosa Branca Imperial** | `flower_rose_white` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Miolo dourado e pétalas branco pérola com base âmbar quente | Variação cromática nobre oficial com alto contraste base-ponta. |
| **Rosa Amarela Dourada** | `flower_rose_yellow` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Miolo laranja intenso e pétalas amarelo solar com base fogo âmbar | Variação cromática nobre oficial com alto contraste base-ponta. |
| **Rosa Azul Mística** | `flower_rose_blue` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Miolo índigo profundo e pétalas azul celeste com base safira noturno | Variação cromática nobre oficial com alto contraste base-ponta. |
| **Rosa Vinho Nobre** | `flower_rose_wine` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Miolo bordô escuro e pétalas vinho aveludado com base rubi escuro | Variação cromática nobre oficial com alto contraste base-ponta. |
| **Rosa Preta Vulcânica** | `flower_rose_black` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Miolo obsidiana escuro e pétalas ônix grafite com base púrpura noturna | Variação cromática nobre oficial com alto contraste base-ponta. |
| **Rosa Pêssego Solar** | `flower_rose_peach` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Miolo terracota suave e pétalas damasco claro com base coral quente | Variação cromática nobre oficial com alto contraste base-ponta. |
| **Margarida Clássica** | `flower_daisy` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Miolo amarelo ouro e pétalas branco puro com base marfim | Variação botânica oficial de margarida com 3 superfícies. |
| **Margarida Azulada** | `flower_daisy_blue` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Miolo âmbar radiante e pétalas azul bebê com base ciano profundo | Variação cromática oficial com alto contraste base-ponta. |
| **Margarida Laranja Solar** | `flower_daisy_orange` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Miolo castanho dourado e pétalas tangerina com base laranja fogo | Variação cromática oficial com alto contraste base-ponta. |
| **Margarida Amarela Sol** | `flower_daisy_yellow` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Miolo laranja abóbora e pétalas amarelo canário com base âmbar | Variação cromática oficial com alto contraste base-ponta. |
| **Margarida Vermelha** | `flower_daisy_red` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Miolo vinho escuro e pétalas vermelho coral com base rubi | Variação cromática oficial com alto contraste base-ponta. |
| **Margarida Rosa Bebê** | `flower_daisy_pink` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Miolo amarelo damasco e pétalas rosa chiclete com base magenta suave | Variação cromática oficial com alto contraste base-ponta. |
| **Margarida Bicolor** | `flower_daisy_bicolor` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Miolo dourado, pétalas base laranja e pontas amarelo pastel | Variação cromática premium com gradiente duplo em pétalas. |
| **Girassol Radiante** | `flower_sunflower` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Miolo marrom aveludado e pétalas amarelo âmbar com base laranja | Modelo grande imponente com floração circular de alto impacto. |
| **Tulipa Escarlate** | `flower_tulip` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Pétalas carmim em cálice com base vinho profundo | Modelo de tulipa fechada com elegância formal. |
| **Tulipa Amarela** | `flower_tulip_yellow` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Pétalas amarelo solar com base dourada quente | Variação cromática nobre para canteiros imperiais. |
| **Tulipa Roxa Mística** | `flower_tulip_purple` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Pétalas púrpura real com base violeta profunda | Variação cromática noturna para fases místicas. |
| **Tulipa Laranja Coral** | `flower_tulip_orange` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Pétalas tangerina viva com base âmbar avermelhada | Variação cromática vibrante de pôr do sol. |
| **Canteiro Florido (Magenta)** | `flower_bed` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Flores magenta/violeta com base verde escura | Canteiro ornamental multi-flores em agrupamento denso. |
| **Canteiro Florido (Azul)** | `flower_bed_blue` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Flores azul safira com base anil profunda | Variação ornamental para bordas litorâneas e costeiras. |
| **Canteiro Florido (Branco)** | `flower_bed_white` | 3 golpes | 1 físico = 1 meta = 5 🪙 | Flores branco perolado com base verde menta profunda | Variação ornamental oficial para jardins reais. |

---

## 2. Arquitetura de Renderização e Corte em Lote (`VegetationGrid` & `VectorGrassField`)

Durante as fases de gameplay (e nas ilhas do Menu Inicial), toda a vegetação e os blocos visuais de terreno operam em lote via **`VegetationGrid` (`res://scripts/plants/vegetation_grid.gd`)** integrado ao campo vetorial contínuo **`VectorGrassField` (`res://scripts/level/vector_grass_field.gd`)**:
- **Campo de Vegetação Vetorial 2D (Coordenadas Contínuas em Metros):**
  - A grama é definida por polígonos fechados contínuos (`PackedVector2Array`) no plano $XZ$, sem restrições de matriz ou células mínimas de grid.
  - **Operações Booleanas com Clipper C++:** União automática (`Geometry2D.merge_polygons`) ao desenhar novas áreas e recorte analítico (`Geometry2D.clip_polygons`) com a borracha ou sobreposição de rochas.
  - **Amostragem Poisson Disk (Algoritmo de Bridson Otimizado):** Geração de tufos orgânicos com distribuição Blue Noise uniforme ($r = 0.22\text{m}$) acelerada por grade espacial, executando níveis densos em apenas $2\text{ ms} \dots 5\text{ ms}$.
  - **Afinamento Suave de Borda:** A distância de cada tufo amostrado até as arestas do polígono é mensurada por `Geometry2D.get_closest_point_to_segment()`, atenuando a escala dos tufos de borda ($0.50 \dots 1.0$) de forma gradual e orgânica.
  - **Malhas Planas Trianguladas de Piso:** Triangulação direta dos polígonos vetoriais via `Geometry2D.triangulate_polygon()`, gerando superfícies planas rente ao solo ($Y = 0.005$) com materiais foscos sólidos (`roughness = 0.90`) que desenham a base verde/dourada sob a vegetação.
- **GPU Instancing e Imunidade Multi-Superfície (`MultiMeshInstance3D`):**
  - Os tufos de vegetação são agrupados em nós `MultiMeshInstance3D` indexados pelas variedades registradas no `PlantDatabase`.
  - **Flores e Trigo:** Constroem um `ArrayMesh` combinando 3 superfícies independentes (`Surface 0: Flower_Leaves`, `Surface 1: Flower_Petals`, `Surface 2: Flower_Stem`). O nó `MultiMeshInstance3D` mantém rigorosamente `material_override = null`, permitindo que cada superfície utilize seu shader/material específico sem que pétalas sobrescrevam caules e folhas com cores erradas.
  - **Gramas:** Utilizam malha única combinada com `material_override` apontando para seu respectivo `ShaderMaterial` Toon com gradiente vertical.
- **Grade Espacial Lógica, Agrupamento 6:1 (`GRASS_TUFTS_PER_UNIT = 6`) e Corte Circular Preciso:**
  - O corte ocorre por proximidade radial de micro-tufo sob o raio da lâmina da serra, conferindo uma borda de corte perfeitamente circular.
  - Para todas as 7 variantes de grama (`grass_*`), **cada 6 tufos visuais ceifados contabilizam 1 unidade de meta e disparam 1 número flutuante (`+1`)** (`GRASS_TUFTS_PER_UNIT = 6` em `VegetationGrid` e `LevelEditorUI`), reduzindo em 83% a poluição visual de números na tela enquanto preserva a densidade visual do tapete de grama. Todas as variedades presentes na ilha são tratadas individualmente por cor (`grass_green`, `grass_yellow`, etc.), gerando cards e ícones botânicos próprios no Top HUD sem aglutinação em meta genérica.
  - Trigo (`wheat`) e todas as 28 variedades de flores mantêm proporção direta `1:1` (cada unidade física cortada = 1 meta e 1 número flutuante).

---

## 3. Ciclo de Dano e Corte

1. **Rigidez Física Ativa, Escala Visual (Trigo +100%, Flores +30%) & Mastigação Sem Knockback:**
   - **Trigo Ampliado em +100% (Escala Dobrada):** O modelo 3D de trigo (`wheat_01.glb`) opera com escala visual ampliada em **+100%** (`scale_y: 1.10..1.40`, `scale_xz: 0.68..0.92`), conferindo espigas altas, fartas e volumosas com presença imponente de plantação sobre a ilha.
   - **Flores Ampliadas em +30%:** Todas as espécies de flores nobres operam com escala visual ampliada em **+30%** (`0.676` no `VegetationGrid`), destacando suas silhuetas e cores sobre o gramado.
   - Plantas resistentes com mais de 1 ponto de vida (trigo e flores) atuam como corpos rígidos na grade espacial (`resolve_rigid_plant_collision`) enquanto estiverem vivas (`health > 0` e `is_cut == 0`).
   - O corpo do cortador ($R_{\text{body}} = 0.30\text{m}$) é impedido de avançar por cima da planta ($R_{\text{wheat}} = 0.18\text{m}$, $R_{\text{flower}} = 0.23\text{m}$). O robô desliza suavemente ao contornar, mas não consegue atravessar até destruí-la.
   - Durante o contato contínuo com a serra, plantas resistentes sofrem leve vibração/tremor visual em alta frequência (jitter procedural em $XZ$), comunicando esforço mecânico contínuo de corte sem expulsar ou desacelerar bruscamente o robô.
