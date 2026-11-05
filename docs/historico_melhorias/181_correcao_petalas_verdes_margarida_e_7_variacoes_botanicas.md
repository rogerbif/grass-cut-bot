# Melhoria 181: Correção de Pétalas Verdes na Margarida e 7 Variações Botânicas com Metas (`v0.12.127-alpha`) 🌼🎨

## 1. Contexto e Motivação
A Margarida do Campo (`flower_daisy` / `flower_03_daisy.glb`) apresentava um bug visual onde um grupo de pétalas inferiores era renderizado em verde escuro em vez de branco. Além disso, foi solicitada a criação de 7 variações cromáticas botânicas reais de margaridas baseadas em referências fotográficas (excluindo a margarida africana), com suporte a cartões de variação com swatches no editor de fases e metas individualizadas por cor no sistema de objetivos.

---

## 2. Diagnóstico da Causa Raiz
Ao inspecionar a malha 3D `flower_03_daisy.glb` no Blender:
- O nó/objeto `Flower_Stem` continha 140 faces poligonais:
  - 47 faces correspondiam ao caule e sépalas verdes legítimos ($Y > 0$).
  - **93 faces** correspondiam a 5 pétalas inferiores ($Y < 0$, $Z \approx 0.74 \dots 0.89$) erroneamente agrupadas sob a malha de caule.
- Como o arquivo `scenes/plants/flower_daisy.tscn` e a engine aplicam o material verde do caule em `Flower_Stem` e o material de flor em `Flower_Petals`, essas 5 pétalas recebiam a coloração verde do caule.

---

## 3. Ações e Implementações Realizadas

### A. Reparo da Malha 3D no Blender 5.2 (`assets/models/flower_03_daisy.glb`)
1. **Transferência de Faces:**
   - As 93 faces das pétalas inferiores foram separadas da malha `Flower_Stem` e incorporadas cirurgicamente à malha `Flower_Petals`.
2. **Reconstituição de Vertex Colors e UVs:**
   - As novas faces receberam atributos de vértice idênticos às pétalas vizinhas: canal `Color` com $R \approx 0.503$, $G = 0.0$, $B = 0.0$ e $A \approx 0.27$, garantindo que o shader `interactive_flower.gdshader` as reconheça como pétalas (e não como miolo central ou sépala) e execute o colapso de despetalação progressiva sem distorções no Hit 1.
3. **Exportação Canônica e Reimportação:**
   - Exportado com `export_apply=True` e `export_yup=True` (Mandamento 12).
   - Recompilado via `godot_console.exe --headless --import` para reconstrução atômica do cache binário `.scn`.

### B. Criação dos 6 Novos Materiais Shaders de Variação
Foram criados 6 materiais `.tres` derivados de `interactive_flower.gdshader`:
1. `flower_daisy_blue_material.tres`: Margarida Azul Celeste (*Felicia amelloides*), pétalas azul celeste vibrante (`#5DB3F0`) com gradiente e miolo amarelo ouro (`#FFD11A`).
2. `flower_daisy_orange_material.tres`: Margarida Laranja (*Calendula officinalis*), pétalas laranja radiante (`#FF7315`) com gradiente e miolo amarelo âmbar (`#FFA812`).
3. `flower_daisy_yellow_material.tres`: Margarida Amarela (*Euryops pectinatus* / Solar), pétalas amarelo canário (`#FFDE1A`) com miolo dourado intenso (`#FFB703`).
4. `flower_daisy_red_material.tres`: Margarida Vermelha (*Tithonia rotundifolia* / Carmesim), pétalas vermelho carmesim (`#E62B2B`) com miolo amarelo calêndula (`#FF9E00`).
5. `flower_daisy_pink_material.tres`: Margarida Rosa Silvestre, pétalas rosa suave (`#F47CB8`) com miolo amarelo brilhante (`#FFE033`).
6. `flower_daisy_bicolor_material.tres`: Margarida Bicolor (*Glebionis coronaria* / Coroada), pétalas com pontas brancas e base amarela (`#F5E663`), reproduzindo fielmente a referência botânica.

### C. Integração ao Editor de Fases e Paleta (`tile_palette_db.gd` e `level_editor_ui.gd`)
- Registradas as 7 variações em `ITEM_VARIATIONS["flower_daisy"]`.
- Desenhado o ícone procedural de margarida de 8 pétalas circulares ao redor de um miolo esférico na classe `FlowerColorSwatch`.
- Adicionado dock contextual inferior com cards dinâmicos ao selecionar Margarida na paleta.
- Registradas 7 metas individuais no catálogo de metas do editor de fases (`flower_daisy`, `flower_daisy_blue`, `flower_daisy_orange`, `flower_daisy_yellow`, `flower_daisy_red`, `flower_daisy_pink`, `flower_daisy_bicolor`).

### D. Suporte em MultiMesh, Carregamento e Gameplay (`vegetation_grid.gd`, `level_json_loader.gd`, etc.)
- Injeção programática dos materiais canônicos em `FLOWER_MATERIALS` (Mandamento 13).
- Registro das variações em `VEG_TYPES`, `_ensure_meshes()`, `_resolve_clipping_color()` e geração de partículas dedicadas no corte.
- Mapeamento de instâncias avulsas e salvamento de fases em `level_json_loader.gd` e `level_editor.gd`.
- Registro no herbário/coleção de espécies em `plant_database.gd`.

---

## 4. Validação e Testes
- **Validação de Malha 3D:** Capturas renderizadas demonstraram eliminação 100% de qualquer vazamento de cor verde nas pétalas, com coroa circular branca perfeita e miolo amarelo destacado.
- **Validação de Shaders e Cores:** As 7 variações renderizadas lado a lado exibiram gradientes nítidos, acabamento fosco Toon e total fidelidade às fotos de referência.
- **Testes Unitários Automatizados:**
  - `tests/test_editor_goals_and_panel.tscn`: Aprovado (0 warnings).
  - `tests/test_rose_cutting_visual.tscn`: Aprovado (0 warnings).
  - `tests/test_flower_variations_editor.tscn`: Aprovado (0 warnings).
- **Zero Warnings:** Console Godot mantido em estrito 0 warnings.
