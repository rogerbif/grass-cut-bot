# Melhoria 108: Migração do Trigo Maduro para a Camada 2 (Objetos no Tile) e Resolução da Contabilização na Fase 02 🌾🛠️

## 1. Contexto e Motivação
Durante o playtest na Fase 02, ao ceifar 100% do trigo maduro presente na ilha, o contador de trigo no HUD congelava em `🌾 145`, impedindo a conclusão da meta. 

A investigação técnica revelou uma discrepância arquitetural:
1. No gameplay (`vegetation_grid.gd`), a cada 10 cortes físicos de trigo, o jogo chamava `register_cut("wheat")` 1 vez (regra de lote de 10).
2. O editor de fases havia salvo em `level_02.json` a quantidade física bruta de tufos (`"wheat": 162`), o que exigiria 1.620 cortes para zerar.
3. Além disso, a presença simultânea de `grass_yellow` (grama amarela cosmética 1x) e `wheat` (trigo 2x) na Camada 1 gerava ambiguidade visual no editor.

## 2. Decisão Arquitetural e Mudanças Realizadas
Adotou-se a separação estrita de domínios:
- **Camada 1 — Gramado Contínuo (Pincel Vetorial 2D):** Restrita às **7 cores de grama cosmética** (`grass_green`, `grass_yellow`, `grass_blue`, `grass_purple`, `grass_white`, `grass_red`, `grass_black`). Opera com a regra de lotes de 10 cortes físicos = 1 unidade de meta para manter fluidez visual e evitar sobrecarga de números na tela.
- **Camada 2 — Objetos e Culturas no Tile ($0.80\text{m} \times 0.80\text{m}$):**
  - `🪨 rock`: Rocha sólida (obstáculo da Layer 4).
  - `🌸 flower`: Flor Nobre (2 hits, 5 moedas, meta 1:1).
  - `🌾 wheat`: Trigo Maduro (2 hits, 3 moedas, **meta 1:1 direta**).
  - `🤖 cutter_spawn`: Ponto de início do robô cortador.

### 2.1 Banco de Dados da Paleta (`scripts/editor/tile_palette_db.gd`)
- `wheat` removido de `GRASS_ITEMS` e integrado a `OBJECT_ITEMS` como categoria `"plant"`, meta `"wheat"` e cor dourada.

### 2.2 Interface do Editor (`scripts/editor/level_editor_ui.gd`)
- Removido o botão de trigo e o botão legado "Converter Grama Amarela ➔ Trigo" da seção de grama.
- Grade de objetos reorganizada em 2 colunas nítidas de 144px (Rocha, Flor, Trigo, Spawn).
- `update_goals_summary()` atualizado para contar o trigo como objeto discreto de tile (`object_grid`), exibindo a contagem 1:1 exata na meta, e calculando lotes de 10 para o gramado contínuo.

### 2.3 Editor 3D e Serializador (`level_editor.gd` & `level_serializer.gd`)
- Suporte a `"wheat"` no `object_grid`, permitindo posicionar e apagar trigos no tile com a borracha.
- Instanciação de `WHEAT_SCENE` em `obstacles_container` durante o modo de edição para visualização 3D instantânea.
- Inclusão de `"wheat"` no array `"objects"` do JSON v3 gerado pelo serializador.

### 2.4 Motor de Corte e Metas (`scripts/plants/vegetation_grid.gd`)
- Parsing de `o_type == "wheat"` a partir de `"objects"`, posicionando trigos nos centros dos tiles correspondentes com escala destacada ($1.25\text{x}$) e 2 pontos de saúde (`max_hp = 2`).
- **Contagem 1:1 Direta:** Cada tufo de trigo ceifado chama `GameManager.register_cut("wheat", 3, p_pos)` imediatamente, concedendo 3 moedas e decrementando exatamente 1 unidade no HUD.
- **Anti-trava por Categoria Independente:** Se o último tufo de trigo for cortado, qualquer pendência residual de trigo é imediatamente liquidada no GameManager, sem travar nem depender do corte simultâneo de todo o gramado verde.

### 2.5 Sincronização dos Dados da Fase 02 (`data/levels/level_02.json`)
- Os 4 agrupamentos de trigo foram convertidos em **36 objetos de trigo de tile** no array `"objects"` (4 estrelas simétricas de 9 tiles cada).
- Polígonos de trigo removidos de `grass_vectors`, deixando o piso limpo para o gramado.
- Metas configuradas para `goals: { "grass": 25, "wheat": 36 }`, funcionando perfeitamente em proporção 1:1.

## 3. Verificação e Validação
- **Teste Unitário Automatizado (`tests/test_wheat_level_02.tscn`):**
  - Carregamento da Fase 02 via `VegetationGridScript.build_from_level_json`.
  - Verificação de meta inicial de trigo = 36.
  - Simulação de cortes: 1 corte reduz a meta para 35; 36 cortes zeram a meta com sucesso (`remaining == 0`).
  - Execução via `godot_console.exe --headless` finalizada com **Exit Code 0 e Zero Warnings**.
