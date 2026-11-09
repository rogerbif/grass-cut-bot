# Histórico de Melhoria: Reformulação Botânica, Remoção de Sino e Corola, Alto Contraste (Tulipa, Canteiro, Trigo) e Lâminas Voando no Corte de Grama 🌿🌷🌾

- **Identificador:** `214_reformulacao_botanica_remocao_sino_corola_contraste_tulipa_canteiro_trigo_e_corte_grama`
- **Versão SemVer:** `v0.12.166-alpha`
- **Data de Conclusão:** 09/11/2026
- **Status:** ✅ Concluído e Validado

---

## 🎯 Objetivos e Motivação

1. **Remoção de Flor Sino (`flower_bell`) e Cravo Corola (`flower_corolla`):**
   - Eliminar espécies obsoletas do catálogo botânico, paletas do editor, cenas e modelos 3D.
   - Migrar com segurança estrita todas as 12 fases existentes que utilizavam essas flores (`level_11`, `12`, `19`, `20`, `21`, `25`, `28`, `29`, `31`, `34`, `37`, `38`), substituindo-as pelas flores nobres Tulipa Imperial, Rosa, Margarida ou Girassol sem alterar metas nem contagens (em estrito cumprimento do Mandamento Invariante 17).
2. **Tulipa Imperial (`flower_tulip`):**
   - Normalizar o canal `Color.a` da malha 3D (`flower_07_tulip.glb` e peças desprendíveis) cobrindo $0.0 \to 1.0$ da base da taça até as pontas das pétalas.
   - Ativar `petal_inner_color` com tom vinho/bordeaux escuro profundo (`Color(0.35, 0.02, 0.06)`) em gradiente contra vermelho rubi vivo (`Color(1.0, 0.12, 0.28)`), replicando o alto contraste aprovado na Flor Silvestre.
   - Criar 4 variações botânicas cromáticas: Rubi (padrão), Solar (ouro), Real (violeta) e Chama (tangerina).
3. **Canteiro Florido (`flower_bed`):**
   - No Blender, alongar a base das hastes (`Flower_Stem`) em +50% e elevar a altura total das flores de $0.67\text{m}$ para **$1.18\text{m}$**, tornando o canteiro visivelmente mais alto e imponente que a grama circundante ($1.04\text{m}$).
   - Normalizar o gradiente de corola e criar 3 variações cromáticas: Misto (padrão), Celeste (azul/ciano) e Alvorada (branco pérola).
4. **Trigo Maduro (`wheat_01`):**
   - No Blender, identificar as 145 ilhas da malha e calcular para cada folha individual o gradiente normalizado de altura local ($0.0 \to 1.0$) gravado em `Color.r`.
   - Atualizar `interactive_grass.gdshader` e `interactive_wheat_material.tres` para renderizar o gradiente individual folha a folha (âmbar profundo na inserção $\to$ ouro solar vivo na ponta).
5. **Efeito de Corte da Grama (Lâminas e Folhas Voando):**
   - Elevar o limite de emissão de partículas por frame de 2 para 8 em `vegetation_grid.gd`.
   - Ampliar a geometria de `cut_leaf_piece.obj` e `_grass_blade_mesh` em 3.5x (de 4cm para ~48cm de comprimento e ~10cm de largura), garantindo perfeita visibilidade na câmera isométrica.
   - Suavizar a gravidade de $-14.0$ para $-8.2$ e aumentar o lifetime para $0.85\text{s}$, fazendo com que as lâminas de grama cortadas voem em arco e planem antes de pousar e diminuir no solo.

---

## 🛠️ Arquivos Modificados e Criados

| Arquivo | Status | Descrição |
| :--- | :--- | :--- |
| `assets/models/flower_07_tulip.glb` | Modificado | Normalização do canal `Color.a` no Blender ($0.0 \to 1.0$ da base até o topo das pétalas). |
| `assets/models/flower_07_tulip_detach.glb` | Modificado | Normalização do canal `Color.a` das peças desprendíveis da tulipa. |
| `assets/models/flower_08_bed.glb` | Modificado | Alongamento de +50% na haste e elevação das flores para $1.18\text{m}$ no Blender. |
| `assets/models/flower_08_bed_detach.glb` | Modificado | Escala e elevação das peças desprendíveis do canteiro. |
| `assets/models/wheat_01.glb` | Modificado | Gradiente folha a folha assado em `Color.r` para cada ilha da malha. |
| `assets/models/cut_leaf_piece.obj` | Modificado | Malha 3D ampliada em 3.5x para lâminas de grama cortada altamente visíveis. |
| `shaders/flower_tulip_material.tres` | Modificado | Ativação de `petal_inner_color` com alto contraste bordeaux/rubi. |
| `shaders/flower_tulip_yellow_material.tres` | **Novo** | Variação Tulipa Imperial Solar (âmbar $\to$ ouro vivo). |
| `shaders/flower_tulip_purple_material.tres` | **Novo** | Variação Tulipa Imperial Real (amora $\to$ violeta). |
| `shaders/flower_tulip_orange_material.tres` | **Novo** | Variação Tulipa Imperial Chama (carmesim $\to$ tangerina). |
| `shaders/flower_bed_material.tres` | Modificado | Ativação de `petal_inner_color` orquídea magenta sobre base ameixa. |
| `shaders/flower_bed_blue_material.tres` | **Novo** | Variação Canteiro Florido Celeste (marinho $\to$ ciano elétrico). |
| `shaders/flower_bed_white_material.tres` | **Novo** | Variação Canteiro Florido Alvorada (verde menta $\to$ branco perolado). |
| `shaders/interactive_grass.gdshader` | Modificado | Suporte a gradiente local de folha via `COLOR.r` assado no vértice. |
| `shaders/interactive_wheat_material.tres` | Modificado | Alto contraste âmbar $\to$ ouro solar vivo com mix de 95%. |
| `scripts/plants/plant.gd` | Modificado | Escala ampliada das partículas de corte, gravidade $-8.2$, lifetime $0.85\text{s}$, novas cores em `get_flower_colors`. |
| `scripts/plants/vegetation_grid.gd` | Modificado | Limpeza de `flower_bell`/`corolla`, registro de novos materiais e aumento do limite de spawn por frame (8). |
| `scripts/plants/plant_database.gd` | Modificado | Limpeza de espécies obsoletas e consolidação para 5 espécies nobres. |
| `scripts/editor/tile_palette_db.gd` | Modificado | Remoção de espécies obsoletas e cadastro de variações de Tulipa (4) e Canteiro (3). |
| `scripts/editor/level_editor.gd` | Modificado | Remoção de referências obsoletas e suporte a variações. |
| `scripts/editor/level_editor_ui.gd` | Modificado | Atualização da paleta de objetivos e ícones com `begins_with`. |
| `scripts/level/level_json_loader.gd` | Modificado | Limpeza de cenas obsoletas e preloads das novas variações. |
| `scripts/menu/island_node.gd` | Modificado | Suporte dinâmico a variações de Tulipa e Canteiro no arquipélago. |
| `scripts/ui/map_level_card.gd` | Modificado | Atualização de `GOAL_ORDER` com as novas variações. |
| `tests/test_flower_detach.gd` | Modificado | Teste atualizado para as 6 espécies oficiais (Flor Silvestre, Rosa, Margarida, Girassol, Tulipa, Canteiro). |
| `tests/test_all_botanical_variations.gd` | **Novo** | Teste automatizado validando as 27 variações botânicas e 0 referências em todas as 40 fases. |
| `project.godot` & `game_version.gd` | Modificado | Bump de versão SemVer para `v0.12.166-alpha`. |

---

## 🧪 Validação e Testes

1. **Testes Headless Automatizados:**
   - `test_flower_detach.gd`: Sucesso (6/6 flores passam no desprendimento do 1º hit).
   - `test_all_botanical_variations.gd`: Sucesso com 0 falhas (todas as variações de Tulipa, Canteiro, Margarida, Rosa e Flor Silvestre validadas no editor e no `VegetationGrid`).
   - Todas as 40 fases validadas com 0 ocorrências de espécies obsoletas.
2. **Zero Warnings Estrito:**
   - Compilação e importação headless do Godot 4.7.2 com 0 erros e 0 warnings no console.
3. **Renderização 3D de Preview:**
   - Render salvo em `preview_botanical_improvements.png` confirmando a nova altura do Canteiro Florido, o contraste da Tulipa Imperial, o gradiente folha a folha do Trigo Maduro e a proporção harmônica da vegetação.
