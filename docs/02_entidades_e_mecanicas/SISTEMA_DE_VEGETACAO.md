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

Cada tufo possui a seguinte árvore:
```
Tuft (Node3D - grupo "plants", script plant.gd)
├── Area3D (Layer 4, Mask 0, grupo "vegetation")
│   └── CollisionShape3D (Cylinder r=0.35m, h=0.6m)
├── VisualMesh (Node3D - malha Low Poly das folhas/espigas)
└── CutParticles (CPUParticles3D - emissão explosiva em arco)
```

- **Estrutura 3D Estilizada Low Poly:**
  - O tufo de grama básico (`grass_tuft.tscn`) utiliza o modelo 3D oficial `assets/models/grass_01.glb` (baseado na malha de 112 vértices e 80 faces `grass_varien_4_grass_0`).
  - O nó visual contém a cena instanciada `Grass01`, com suporte dinâmico no `plant.gd` via enum `@export var grass_variation: GrassVariation` (`GREEN`, `YELLOW`, `BLUE`, `PURPLE`, `RANDOM`), permitindo rápida personalização de biomas mantendo o verde clássico por padrão.
  - No `_ready()`, cada tufo recebe uma rotação aleatória no eixo Y (`0.0` a $2\pi$) e uma leve oscilação de escala (`0.85` a `1.15`), garantindo que o gramado pareça orgânico e variado por todo o cenário.

---

## 3. Ciclo de Dano e Corte

1. **Golpe Parcial (Resistência Ativa):**
   - Se o tufo receber dano inferior à sua saúde restante (`health > power`):
   - Um Tween de squash & stretch rápido é acionado (`scale * 1.25` em 0.05s voltando ao normal), dando feedback imediato de que a planta sofreu impacto mas resistiu.
2. **Corte Concluído (`_perform_cut`):**
   - O colisor `Area3D` é desativado imediatamente para evitar múltiplos registros acidentais.
   - O emissor `CutParticles` dispara 16 fragmentos em arco parabólico com gravidade natural.
   - O `GameManager.register_cut(plant_key, coin_reward)` é notificado:
     - Incrementa as moedas da fase multiplicadas pelo multiplicador ativo.
     - Dispara o pulso háptico suave no celular (`Input.vibrate_handheld(15)`).
     - Decrementa a cota pendente no Top HUD da partida.
   - O modelo 3D é achatado e encolhido a zero via Tween em 0.14s, revelando o piso limpo.
   - O nó aguarda o término das partículas e executa `queue_free()`.

---

## 4. Shader Interativo de Vegetação (Técnica Arnklit Refinada)

As plantas utilizam o shader espacial `interactive_grass.gdshader`:
1. **Curvatura Elástica Não-Linear e Compressão:**
   - Lê a posição global e o raio de interação do cortador via parâmetros de shader atualizados dinamicamente pelo cortador nos materiais compartilhados (`cutter_pos` e `cutter_interact_radius`).
   - Converte os vértices para o espaço de mundo ($XZ$), calcula o vetor de afastamento radial e projeta no espaço de modelo via `mat3(inverse(MODEL_MATRIX))`.
   - Aplica curvatura elástica exponencial `bend_factor = pow(height_factor, 1.6)`: a raiz permanece 100% ancorada ao solo enquanto a ponta se curva suavemente em arco sob a aproximação da lâmina.
   - Aplica compressão elástica no eixo Y (`VERTEX.y -= power * interact_power * 0.14 * bend_factor`), simulando o achatamento da grama sob a carcaça da serra.
2. **Vento Orgânico Multidirecional e Gradiente Fosco:**
   - Adiciona ondas de vento cruzadas senoidais no espaço de mundo projetadas de volta ao modelo, criando ondulações fluidas que percorrem todo o gramado.
   - Aplica gradiente fosco *Low Poly* da raiz (tom mais escuro e denso) até a ponta (mais viva e iluminada), mantendo `roughness = 0.9` e acabamento sem reflexos especulares plásticos.

---

## 5. Modelo 3D Estilizado Low Poly (`grass_01.glb`) e Variações Cromáticas

Originado do arquivo fonte de modelagem `grass_01.blend` e integrado como cena `scenes/plants/grass_01.tscn` (modelo `assets/models/grass_01.glb`), o tufo `grass_01` representa a evolução das malhas vegetais para geometria modelada tridimensional.

### A. Geometria e Otimização
- **Malha Base:** Selecionada da variante compacta `grass_varien_4_grass_0` (112 vértices, 80 faces em quads/tris de baixo custo de renderização).
- **Normalização de Escala:** Fator de calibração $s = 0.0242265$, adequando as dimensões para a escala padrão de jogo ($0.89\text{m} \times 0.89\text{m} \times 1.025\text{m}$).
- **Pivô no Solo:** Vértices inferiores alinhados estritamente em $Z = 0.0$, garantindo contato e ancoragem imediata com o piso do terreno.

### B. Variações Lado a Lado e Materiais Foscos (Mandamento 7)
Todas as texturas rasterizadas foram substituídas por materiais com cores sólidas vibrantes e acabamento fosco (`roughness = 0.88`, sem reflexos especulares plásticos):

| Objeto no Modelo | Posição no Blender ($X, Y, Z$) | Material | Cor Sólida (RGBA Linear) | Uso Previsto no Jogo |
| :--- | :--- | :--- | :--- | :--- |
| **`grass_green`** | $(-2.25, 0.0, 0.0)$ | `M_Grama_Verde` | `(0.18, 0.65, 0.12, 1.0)` | Gramado clássico temperado |
| **`grass_yellow`** | $(-0.75, 0.0, 0.0)$ | `M_Grama_Amarela` | `(1.00, 0.62, 0.02, 1.0)` | Campo seco / pastagem dourada |
| **`grass_blue`** | $(+0.75, 0.0, 0.0)$ | `M_Grama_Azul` | `(0.04, 0.45, 0.90, 1.0)` | Bioma místico / flora gélida |
| **`grass_purple`** | $(+2.25, 0.0, 0.0)$ | `M_Grama_Roxa` | `(0.48, 0.08, 0.85, 1.0)` | Flora exótica / vegetação mágica |

### C. Animação de Vento e Interatividade com o Cortador no Modelo 3D
Para que o modelo 3D estilizado não permaneça estático no cenário, conectamos a geometria ao shader espacial `interactive_grass.gdshader`:
1. **Mapeamento UV e Ancoragem:** As coordenadas $UV.y$ da malha original variam exatamente de $1.0$ (na raiz em $Y=0.0$) a $0.0$ (no topo em $Y=1.025$). O shader calcula `height_factor = clamp(1.0 - UV.y, 0.0, 1.0)` e `bend_factor = pow(height_factor, 1.6)`, garantindo que as raízes permaneçam firmemente plantadas ao solo enquanto as pontas ondulam com o vento.
2. **Quatro Materiais de Shader Interativo Dedicados:**
   - `interactive_grass_material.tres`: Grama verde vibrante (`color_base = #1f6b29`, `color_top = #33b338`).
   - `interactive_grass_yellow_material.tres`: Grama dourada/amarela (`color_base = #a66605`, `color_top = #ffa60d`).
   - `interactive_grass_blue_material.tres`: Grama mística azul (`color_base = #05479e`, `color_top = #0f85f2`).
   - `interactive_grass_purple_material.tres`: Grama exótica roxa (`color_base = #4d0d8c`, `color_top = #8c1fea`).
3. **Sincronização em Tempo Real:** O script `cutter.gd` atualiza continuamente `cutter_pos` e `cutter_interact_radius` em todos os materiais de grama, fazendo com que os tufos 3D se curvem suavemente e se comprimam para baixo com a aproximação da serra antes do corte.

