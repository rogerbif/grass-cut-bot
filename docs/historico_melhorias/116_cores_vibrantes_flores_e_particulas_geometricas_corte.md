# Melhoria 116: Cores Vibrantes das Flores e Sistema de Partículas Geométricas em Arco 🌸✨📐

**Versão:** `v0.12.40-alpha`  
**Data:** 27/10/2026

---

## 1. Contexto e Motivação

O usuário identificou duas necessidades centrais de Game Feel e direção de arte:
1. **Cores das Flores Muito Pálidas:** Sob a iluminação ambiente e o tonemap filmic da cena, as flores apresentavam aspecto lavado e opaco, necessitando de tons muito mais vibrantes, alegres e saturados.
2. **Partículas de Corte Rígidas e Verticais:** As partículas anteriores utilizavam uma malha vertical de 21cm com rotação travada no eixo Y (`particle_flag_rotate_y = true`), fazendo os fragmentos parecerem estiletes subindo e descendo estritamente em linha reta vertical.
3. **Morfologia Específica por Espécie:**
   - **Grama/Trigo:** Os pedaços cortados devem ser **triângulos** e **quadrados** com a cor da vegetação correspondente.
   - **Flores:** Devem ejetar **círculos** nas cores da flor (pétala e miolo), somados a fragmentos verdes de **quadrado** (representando pedaços de caule) e **triângulo** (representando folhas da haste).
   - As peças devem voar em arco parabólico aberto e cair de forma orgânica e satisfatória.

---

## 2. Alterações Implementadas

### 2.1. Cores Vivas e Vibrância nas Flores (`interactive_flower.gdshader` e Materiais)
- **Shader Espacial Toon (`interactive_flower.gdshader`):**
  - Adicionado parâmetro `uniform float vibrancy : hint_range(0.0, 1.0) = 0.18;`.
  - No `fragment()`, injeta auto-iluminação toon `EMISSION = base_col * vibrancy;`, impedindo que sombras difusas ou luz ambiente esbranquiçada lavem as pétalas e miolos.
- **Suíte de Materiais Rebalanceada:**
  - `flower_rose_material.tres`: Vermelho rubi vivo (`#ff1459`) com miolo carmim intenso (`#cc052e`).
  - `flower_daisy_material.tres`: Branco puro luminoso (`#ffffff`) com miolo ouro radiante (`#ffd900`).
  - `flower_sunflower_material.tres`: Amarelo solar dourado (`#ffe000`) com miolo chocolate aveludado (`#7a380a`).
  - `flower_bell_material.tres`: Azul celeste elétrico (`#1fa6ff`) com miolo safira vivo (`#0d61eb`).
  - `flower_corolla_material.tres`: Laranja tangerina quente (`#ff800d`) com miolo carmim fogo (`#f2260d`).
  - `flower_tulip_material.tres`: Vermelho tulipa escarlate (`#ff143d`) com miolo rubi profundo (`#ad0d26`).
  - `flower_bed_material.tres`: Magenta violeta radiante (`#e04dff`) com miolo púrpura intenso (`#8c14cc`).
  - `interactive_flower_material.tres` e variantes: Tons fúcsia, ciano, roxo e amarelo devidamente saturados.
- Sincronização em `vegetation_grid.gd` (`_resolve_type_particle_color`) e `tile_palette_db.gd` (paleta do editor).

### 2.2. Novas Primitivas Procedurais e Emissão Especializada (`plant.gd`)
- **Três Malhas Geométricas Planas Criadas Proceduralmente:**
  - `_triangle_mesh`: Triângulo plano equilátero centrado (3 vértices, normal frontal, UV mapeada).
  - `_square_mesh`: Quadrado plano centrado (4 vértices, 2 triângulos).
  - `_circle_mesh`: Disco plano cartoon de 10 segmentos (10 triângulos em leque).
- **Física Parabólica Realista de Pedaços Voando e Caindo:**
  - `particle_flag_rotate_y = false`: Desbloqueia a rotação completa nos 3 eixos, permitindo tumbling e giros caóticos rápidos no ar (`angular_velocity = ±720 °/s`).
  - `emission_shape = EMISSION_SHAPE_SPHERE` ($R=0.12\text{m}$): Dispersão volumétrica no ponto do corte.
  - `direction = Vector3(0, 1, 0)` com `spread = 82°`: Cone hemisférico amplo cobrindo 360° no plano horizontal.
  - `initial_velocity = 3.2 .. 5.2 m/s`: Explosão inicial de alta energia.
  - `gravity = Vector3(0, -14.0, 0)`: Gravidade acentuada puxando os pedaços rapidamente para o chão em arco parabólico.
  - `radial_accel` e `tangential_accel`: Espalhamento lateral simulando a turbulência centrífuga da serra.
  - `scale_amount_curve`: Curva de escala que surge instantaneamente, atinge ápice no voo e encolhe ao pousar no solo.
  - `material_override`: Materiais com `cull_mode = CULL_DISABLED` e leve auto-iluminação emissiva (`0.22`), garantindo visibilidade total de ambos os lados da face em movimento.
- **Diferenciação por Espécie:**
  - **Grama/Trigo (`spawn_grass_cut_particles`):** Dispara 8 triângulos e 6 quadrados tingidos na cor da vegetação.
  - **Flores (`spawn_flower_cut_particles`):** Dispara 8 círculos da cor da pétala, 4 círculos da cor do miolo, 3 quadrados verdes de caule e 3 triângulos verdes de folha.
  - **Despetalação Parcial (`spawn_flower_petal_burst`):** Dispara 6 círculos de pétala e 2 triângulos verdes de folha.
- **Pool de Emissores Expandido:** `POOL_SIZE = 36` para suportar cortes múltiplos e densos sem novas alocações no heap em runtime.

### 2.3. Integração com o `VegetationGrid` (`vegetation_grid.gd`)
- Em `cut_in_circle()`, a destruição de qualquer tufo detecta se é flor (`p_key.begins_with("flower")`) para chamar `PlantScript.spawn_flower_cut_particles`, ou vegetação comum para `PlantScript.spawn_grass_cut_particles`.
- Hits intermediários em flores chamam `PlantScript.spawn_flower_petal_burst`.

---

## 3. Verificação e Validação

- Execução com script autônomo `test_cut_particles.gd` confirmou o disparo de partículas para todas as 8 flores e grama sem nenhum warning ou erro.
- Execução headless de `scenes/main.tscn`, `scenes/menu/main_menu.tscn` e `scenes/tools/perf_test.tscn` aprovada com **0 warnings e 0 erros**.
