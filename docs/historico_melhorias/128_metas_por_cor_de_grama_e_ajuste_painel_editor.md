# Melhoria 128: Metas Independentes por Cor de Grama, Restrições de Quantidade e Correção de Enquadramento do Painel Direito no Editor 🌿🎨✂️

> **Data:** 27 de Outubro de 2026  
> **Versão:** `v0.12.52-alpha`  
> **Status:** Concluído e Validado  
> **Tipo:** Level Editor / UI / Game Balance  

---

## 1. Contexto e Diagnóstico

No Editor de Fases PC (`scenes/editor/level_editor.tscn`):
1. **Corte Lateral do Painel Direito:** A largura fixa de $314\text{px}$ (`offset_left = -326`, `offset_right = -12`) somada à largura fixa de $144\text{px}$ dos botões em 2 colunas e aos textos longos do banner superior provocava transbordamento horizontal contra a barra de rolagem vertical, cortando textos e botões na lateral direita da tela.
2. **Gramas Agrupadas Indevidamente:** Na seção de metas, todas as cores de grama eram aglutinadas em uma única linha genérica (`/ 140 (green: 248, blue: 244...)`), ocupando centenas de pixels horizontais e empurrando o campo numérico para fora do enquadramento visível.
3. **Ausência de Campo Condicional e Restrições de Meta:** Não havia separação individual das 7 cores de grama para ativação seletiva como meta, o campo de edição não abria/fechava com base no estado do checkbox e os valores numéricos permitiam inserções arbitrárias descoladas da quantidade real de tufos existentes na fase.

---

## 2. Solução Técnica Implementada

### 2.1 Alargamento e Flexibilização do Painel Direito (`level_editor_ui.gd`)
- A largura do painel lateral direito foi expandida para **$364\text{px}$** (`offset_left = -376`, `offset_right = -12`), alinhando-se perfeitamente às margens superiores e inferiores da interface.
- Todos os botões da paleta nas 3 categorias (Terreno, Grama e Objetos) passaram a utilizar `size_flags_horizontal = Control.SIZE_EXPAND_FILL`, `custom_minimum_size = Vector2(0, 34)` e `clip_text = true`.
- O banner de camada ativa (`lbl_active_layer_banner`) recebeu `clip_text = true` e dimensionamento expansivo, eliminando qualquer corte de texto.

### 2.2 Separação Individual das Metas por Cor de Grama (`GOALS_CATALOG`)
Foi estabelecido o catálogo canônico `GOALS_CATALOG` contendo 9 variedades independentes:
- **7 Cores de Grama Cosmética:** `grass_green` (🌿 Verde), `grass_yellow` (🌼 Amarela), `grass_blue` (💠 Azul), `grass_purple` (🔮 Violeta), `grass_white` (🤍 Branca), `grass_red` (❤️ Vermelha), `grass_black` (🖤 Preta).
- **Culturas Agrícolas e Flores:** `wheat` (🌾 Trigo) e `flower` (🌸 Flores).

### 2.3 Exibição do Total de Tufos e Abertura Condicional do Campo de Edição
- **Contador em Tempo Real:** Cada card exibe a quantidade exata presente no mapa (ex: `248 tufos`, `8 trigos`, `4 flores`). Caso a quantidade seja 0, o texto é esmaecido e o CheckBox é desabilitado.
- **Abertura Condicional (SpinBox):**
  - Se a meta estiver **desmarcada**, o SpinBox fica fechado/oculto (`visible = false`), garantindo visual limpo.
  - Ao **marcar o CheckBox**, o campo de edição abre instantaneamente (`visible = true`).
- **Restrição Rigorosa de Valores ($1 \le \text{meta} \le \text{total}$):**
  - `spin.min_value = 1` (impossibilita zero ou números negativos).
  - `spin.max_value = total_count` (impossibilita valores superiores aos existentes na fase).
  - Defesa dupla via evento `value_changed` e `text_submitted` no `LineEdit` interno.
  - Caso o usuário apague vegetação no mapa e reduza o total abaixo da meta configurada, o SpinBox é reajustado automaticamente para o novo teto.

### 2.4 Execução 1:1 de Metas Personalizadas (`vegetation_grid.gd`)
- Introduzido o indicador `_has_custom_goals: bool` no `VegetationGrid`.
- Quando um nível contém metas customizadas salvas pelo editor (`data["goals"]`), o corte de tufos de grama abate **1 unidade de meta para cada tufo físico ceifado** (1:1), garantindo precisão matemática absoluta em relação ao número configurado no editor.
- Quando o nível não possui metas customizadas (as 20 fases canônicas da campanha), o agrupamento de 10 tufos = 1 unidade virtual é preservado com 100% de compatibilidade retroativa.

---

## 3. Validação e Testes Automatizados

Foi criado o teste automatizado `tests/test_editor_goals_and_panel.gd` (e cena `.tscn`):
1. **Inspeção de Controles:** Validação da criação dos 9 cards, inicialização com SpinBox fechado (`visible = false`).
2. **Detecção e Atualização de Totais:** Teste com mapa vetorial contendo 3 cores de grama, trigo e flores; confirmação de contagens separadas e desativação de itens com 0 tufos.
3. **Abertura Condicional:** Confirmação de que o SpinBox abre ao marcar o CheckBox e fecha ao desmarcar.
4. **Validação de Limites Numéricos:**
   - Tentativa de atribuir valor acima do total -> corrigido para `max_value`.
   - Tentativa de atribuir `0` ou negativo -> corrigido para `min_value = 1`.
   - Aceitação de valores no intervalo válido $[1, \text{total}]$.
5. **Persistência de Metas:** Validação de `get_configured_goals()` e `set_configured_goals()`.
6. **VegetationGrid 1:1:** Confirmação de ativação de `_has_custom_goals` e processamento correto de metas no carregamento de JSON.
7. **Execução Headless:** Suíte de testes e cenas principais executadas via console Godot 4 com `exit code 0` e 0 warnings.

---

## 4. Arquivos Modificados e Criados

| Arquivo | Descrição das Modificações |
| :--- | :--- |
| `scripts/editor/level_editor_ui.gd` | Alargamento do painel para 364px, flexibilização de botões, criação de `GOALS_CATALOG`, abertura condicional e restrições de SpinBox. |
| `scripts/editor/level_editor.gd` | Sincronização antecipada de metas no carregamento e injeção de `configured_goals` no playtest F1. |
| `scripts/plants/vegetation_grid.gd` | Adicionado `_has_custom_goals` e lógica de corte 1:1 para metas personalizadas com proteção anti-trava. |
| `tests/test_editor_goals_and_panel.gd` | Teste automatizado cobrindo os 9 tipos de metas, abertura de campos, restrições numéricas e VegetationGrid. |
| `tests/test_editor_goals_and_panel.tscn` | Cena do teste automatizado. |
| `docs/03_level_design_e_fases/SISTEMA_EDITOR_DE_FASES.md` | Atualização da documentação canônica do editor com o novo sistema de metas e painel. |
| `scripts/core/game_version.gd` | Versão elevada para `v0.12.49-alpha`. |
| `project.godot` | Atualização do parâmetro `config/version="0.12.49-alpha"`. |
| `export_presets.cfg` | Atualização de `version/name` e `version/code`. |
| `docs/historico_melhorias/INDICE_MELHORIAS.md` | Indexação da melhoria 124 no catálogo mestre. |
