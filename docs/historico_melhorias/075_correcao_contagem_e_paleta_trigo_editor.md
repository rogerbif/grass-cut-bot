# Histórico de Melhoria: Correção da Contagem e Reestruturação da Paleta de Trigo no Editor de Fases 🌾🎨

**ID:** `075_correcao_contagem_e_paleta_trigo_editor`  
**Versão:** `v0.11.4-alpha`  
**Data:** 22/10/2026  
**Status:** Concluído e Validado (0 Warnings no Godot 4.7.1)  

---

## 1. Contexto e Diagnóstico

Ao editar a Fase 02 no Editor de Fases PC, o usuário relatou que os trigos não estavam sendo contabilizados no painel de metas em tempo real (`🌾 Trigo: 0`), mesmo com as 4 estrelas amarelas desenhadas no mapa.

### Diagnóstico Técnico:
1. **Ambiguidade na Paleta de Cores:**  
   Na paleta de vegetação orgânica, existiam lado a lado duas opções amarelas:
   - `Grama Dourada` (`grass_yellow`), uma cor cosmética de grama comum (1x HP, 1 moeda, meta de `grass`).
   - `Trigo Maduro (2x)` (`wheat`), o elemento nobre de gameplay (2x HP, 3 moedas, meta de `wheat`).
   O usuário selecionou `Grama Dourada` por estar no topo da grade (ao lado de `Grama Verde`), desenhando as estrelas da Fase 02 como polígonos de `grass_yellow`.
2. **Contabilização de Metas:**  
   Como os polígonos foram gravados como `grass_yellow`, a função `update_goals_summary()` contabilizava-os no totalizador de `🌿 Grama: 563`, mantendo `🌾 Trigo: 0`.
3. **Falta de Ação de Conversão Retroativa:**  
   Não havia como o level designer converter polígonos de grama amarela já pintados em trigo de forma automática sem ter que redescobrir e repintar toda a área manualmente.

---

## 2. Soluções Implementadas

### A. Reestruturação Visual e Ergonômica da Paleta (`level_editor_ui.gd` & `tile_palette_db.gd`)
- Em [`scripts/editor/tile_palette_db.gd`](../../scripts/editor/tile_palette_db.gd):
  - Renomeada `Grama Dourada` para **`Grama Amarela (1x)`** (`id: grass_yellow`), eliminando a confusão de nomes com o trigo.
  - Renomeado `Trigo Maduro (2x)` para **`Trigo Maduro (Meta 2x)`** (`id: wheat`).
  - Adicionado método estático `get_item_by_id(id_str: String) -> Dictionary` com busca defensiva em todas as categorias.
- Em [`scripts/editor/level_editor_ui.gd`](../../scripts/editor/level_editor_ui.gd):
  - Dividida a Camada 1 (Grama) em duas subseções visualmente claras:
    - **`🌿 GRAMA COMUM (1x HP - CAMPO 0.2m)`**: Grade compacta de 2 colunas com as 7 cores cosméticas (Verde, Amarela 1x, Azul, Violeta, Branca, Vermelha, Preta).
    - **`🌾 VEGETAÇÃO DE META (2x HP - 3 MOEDAS)`**: Botão largo e destacado (`262x34`) em tom âmbar brilhante para seleção inequívoca do **`🌾 Trigo Maduro (Meta 2x)`**.
  - Adicionado o botão utilitário de ação rápida **`🔄 Converter Grama Amarela ➔ Trigo`**.

### B. Método de Conversão de Tipos Vetoriais (`vector_grass_field.gd` & `level_editor.gd`)
- Em [`scripts/level/vector_grass_field.gd`](../../scripts/level/vector_grass_field.gd):
  - Implementado o método `convert_shapes_type(from_type: String, to_type: String) -> int` para converter dinamicamente o atributo `type` dos polígonos vetoriais registrados.
- Em [`scripts/editor/level_editor.gd`](../../scripts/editor/level_editor.gd):
  - Conectado o sinal `convert_yellow_to_wheat_requested` ao método `_on_convert_yellow_to_wheat()`.
  - Ao acionar o botão, o editor converte os polígonos `grass_yellow` em `wheat`, gera snapshot de Undo, reconstrói o mundo 3D com os novos MultiMeshes e atualiza imediatamente o resumo de metas e o toast.

### C. Correção Canônica da Fase 02 (`data/levels/level_02.json`)
- Atualizadas as 4 formas de estrelas desenhadas pelo usuário (IDs 9, 10, 11 e 12) de `"type": "grass_yellow"` para `"type": "wheat"`.
- Agora a Fase 02 reflete imediatamente os trigos na contagem de metas tanto no Editor quanto no Playtest (`[F1]`) e no jogo principal.

---

## 3. Validação Técnica (0 Warnings / 0 Erros)

- **Godot 4.7.1 Debug Runner (MCP):**
  - Execução de `scenes/editor/level_editor.tscn`: **0 warnings e 0 erros**.
  - Execução de `scenes/main.tscn`: **0 warnings e 0 erros**.
- **Testes de Contagem e UI:**
  - `data/levels/level_02.json` carregado no editor exibe a contagem correta de Trigo e Grama.
  - Seleção do botão `🌾 Trigo Maduro (Meta 2x)` opera com destaque e pinta exclusivamente na camada de trigo.
  - Botão de conversão retroativa testado com sucesso.
