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

- **Variação Orgânica e Estrutura em Leque:**
  - O tufo de grama básico (`grass_tuft.tscn`) é modelado volumetricamente com **5 lâminas PrismMesh** (`subdivide_height = 4`) dispostas em formato de cálice/leque radial:
    - `BladeCenter`: Haste central mais alta (0.72m) e esguia, orientada quase verticalmente para garantir volume central.
    - `Blade1` a `Blade4`: Lâminas periféricas com alturas entre 0.52m e 0.64m, inclinadas radialmente para fora (pitch de 13° a 16°) e distribuídas em ângulos de yaw espaçados, conferindo volume 360° em qualquer perspectiva de câmera.
  - No `_ready()`, cada tufo recebe uma rotação aleatória no eixo Y (`0` a $2\pi$) e uma leve oscilação de escala (`0.85` a `1.15`), garantindo que o gramado pareça natural mesmo em malha densa.

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
