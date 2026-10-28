# Melhoria 139: Divisão das 7 Flores em 3 Partes, Desprendimento de Pétalas/Folhas no Hit 1 e Pintura de Faces com Gradiente 🌸🎨

## 🎯 Objetivo e Contexto
Expansão completa da mecânica introduzida na Melhoria 138 para todas as **8 espécies de flores nobres** do jogo:
1. **Divisão Anatômica em 3 Malhas:** Decomposição de cada modelo `.glb` em 3 nós independentes (`Flower_Stem`, `Flower_Leaves` e `Flower_Petals`), preservando pivôs no solo e centro de massa anatômico.
2. **Correção de Cores de Faces (Vertex Color):** Identificação e correção do defeito onde as flores `flower_02` a `flower_08` possuíam vertex color puramente branco `(1, 1, 1)`, fazendo com que o shader interpretasse todas as pétalas como miolo (`COLOR.g > 0.5`), pintando erroneamente com `center_color`.
3. **Pintura com Gradiente Escuro → Claro:** Aplicação de gradiente vertical e radial suave no canal alfa do vertex color (`COLOR.a`), escurecendo sutilmente a base das pétalas e clareando as pontas (`mix(0.55, 1.0, COLOR.a)`).
4. **Desprendimento Físico no 1º Hit (3 → 2 HP):** Ao receber o 1º golpe, cada espécie ejeta no ar 2 pétalas externas e 1 folha características (`FlowerDetachPiece`), com impulso vertical de 4.0 ~ 5.0 m/s, giro tridimensional, queda por gravidade (-14.0 m/s²) e encolhimento suave ao tocar o chão até desaparecer.

---

## 🛠️ Alterações Realizadas

### 1. Pipeline de Modelagem e Exportação 3D (Blender 5.2)
- **Script Canônico Reutilizável (`tools/split_flower_model.py`):**
  - Automação via Blender headless para decomposição em ilhas de conectividade topológica.
  - Classificação refinada por material, altura ($Z$) e raio radial ($R$) em relação ao centro da cabeça da flor.
  - Atribuição canônica de Vertex Color (`COLOR_0`, float RGBA):
    - `R`: Estágio de despetalação (`0.0` para caule/folhas/miolo, `0.5` para pétalas externas/hit 1, `1.0` para pétalas internas/hit 2).
    - `G`: Sinalizador do miolo central (`1.0` para miolo, `0.0` para pétalas e folhas).
    - `B`: Sinalizador de desprendimento no 1º hit (`1.0` para as 2 pétalas e 1 folha a ejetar).
    - `A`: Gradiente de tonalidade escuro $\rightarrow$ claro normalizado ($0.0$ na base $\rightarrow 1.0$ no ápice).
  - Exportação de cada flor com `export_apply=True`, `export_yup=True` e `export_vertex_color='ACTIVE'`.
  - Exportação de 7 novos arquivos de peças soltas:
    - `assets/models/flower_02_rose_detach.glb`
    - `assets/models/flower_03_daisy_detach.glb`
    - `assets/models/flower_04_sunflower_detach.glb`
    - `assets/models/flower_05_bell_detach.glb`
    - `assets/models/flower_06_corolla_detach.glb`
    - `assets/models/flower_07_tulip_detach.glb`
    - `assets/models/flower_08_bed_detach.glb`

### 2. Shader Espacial de Flores (`shaders/interactive_flower.gdshader`)
- Atualização do `fragment()`:
  - Multiplicação do albedo pelo fator de gradiente: `float shade = mix(0.55, 1.0, clamp(COLOR.a, 0.0, 1.0));`
  - Aplicação correta de `center_color` exclusivamente onde `COLOR.g > 0.5` e `petal_color` em todo o restante da corola.

### 3. Cenas das Flores (`scenes/plants/`)
- Atualização das 7 cenas (`flower_rose.tscn`, `flower_daisy.tscn`, `flower_sunflower.tscn`, `flower_bell.tscn`, `flower_corolla.tscn`, `flower_tulip.tscn`, `flower_bed.tscn`):
  - Substituição do nó antigo unificado (`<X>_Export`) pela tríade padronizada:
    - `Flower_Leaves`: `surface_material_override/0 = ExtResource("interactive_flower_leaves_material.tres")`
    - `Flower_Petals`: `surface_material_override/0 = ExtResource("<material_específico_da_flor>.tres")`
    - `Flower_Stem`: `surface_material_override/0 = ExtResource("interactive_grass_material.tres")`

### 4. Entidades e Lógica de Gameplay (`scripts/plants/plant.gd`)
- Expansão de `DETACH_CONFIG_BY_TYPE` com modelos e offsets espaciais calibrados para cada uma das 8 espécies de flores.
- Cache inteligente sob demanda das malhas de peças soltas (`_ensure_detach_meshes(flower_type)`).
- Função `spawn_flower_detach_pieces()` universalizada, instanciando `FlowerDetachPiece` com materiais coloridos fiéis a cada variedade botânica.

### 5. Suíte de Testes Automatizados (`tests/test_flower_detach.gd`)
- Teste sequencial headless que itera sobre as 8 cenas de flor:
  - Valida a presença dos nós `Flower_Stem`, `Flower_Leaves` e `Flower_Petals`.
  - Desfere golpe inicial (`cut(1)`).
  - Mede pico de 3 peças ejetadas (`FlowerDetachPiece`).
  - Aguarda o ciclo de queda, encolhimento e liberação de memória (`queue_free`).
  - Confirma HP remanescente em 2 e 0 instâncias vazadas.

---

## 📊 Tabela de Cores e Anatomia Botânica Canônica

| Espécie | Chave | Pétalas (`petal_color`) | Miolo (`center_color`) | Detalhes do Desprendimento |
| :--- | :--- | :--- | :--- | :--- |
| **Flor Silvestre** | `flower` | Magenta `(1.0, 0.18, 0.65)` | Dourado `(1.0, 0.85, 0.05)` | 2 pétalas externas + 1 folha |
| **Rosa Encantada** | `flower_rose` | Carmim `(1.0, 0.08, 0.35)` | Rubi Profundo `(0.80, 0.02, 0.18)` | 2 pétalas externas + 1 folha |
| **Margarida do Campo**| `flower_daisy` | Branco Puro `(1.0, 1.0, 1.0)`| Ouro Solar `(1.0, 0.85, 0.0)` | 2 pétalas periféricas + 1 folha |
| **Girassol Solar** | `flower_sunflower`| Dourado `(1.0, 0.88, 0.0)` | Avelã `(0.48, 0.22, 0.05)` | 2 pétalas em leque + 1 folha |
| **Flor Sino** | `flower_bell` | Azul Celeste `(0.12, 0.65, 1.0)`| Azul Real `(0.05, 0.38, 0.92)` | 2 sinos externos + 1 folha |
| **Cravo Corola** | `flower_corolla` | Laranja Coral `(1.0, 0.50, 0.05)`| Vermelho Fogo `(0.95, 0.15, 0.05)` | 2 pétalas abertas + 1 folha |
| **Tulipa Imperial** | `flower_tulip` | Vermelho Rubi `(1.0, 0.08, 0.24)`| Bordô `(0.68, 0.05, 0.15)` | 2 cálices externos + 1 folha |
| **Canteiro Florido** | `flower_bed` | Lilás `(0.88, 0.30, 1.0)` | Violeta `(0.55, 0.08, 0.80)` | 2 florzinhas inteiras + 1 folha |

---

## ✅ Verificação e Qualidade
- **Importação Headless:** Executada sem erros no Godot 4.
- **Teste Unitário Automatizado:** 8/8 flores aprovadas (`RESULTADO FINAL 8 FLORES: OK`).
- **Zero Warnings:** 0 SCRIPT ERROR e 0 USER WARNING.
