# Melhoria 151: Caixa de Seleção, Mover e Duplicar (Ctrl+D / Ctrl+C / Ctrl+V) no Editor de Fases

**Versão:** `v0.12.77-alpha`  
**Data:** 29/10/2026  
**Tipo:** Feature / QoL / Level Editor  
**Status:** Concluído ✅  

---

## 📋 Contexto e Motivação

Com a adição da Pipeta e do Carimbo em Anel Circular, o fluxo de criação de composições florais e ilhas ganhou velocidade. Contudo, ao criar um jardim ou arranjo complexo (ex: anel de margaridas ou floresta de rochas), o level designer precisava redesenhá-lo repetidamente em diferentes pontos da ilha.

Para proporcionar alta produtividade (Major Project do roadmap de ferramentas do editor), foi implementado o sistema completo de **Caixa de Seleção Múltipla (Marquee Box Selection)** com suporte a **Mover por Arraste**, **Duplicação Imediata (`Ctrl+D`)**, **Copiar / Colar (`Ctrl+C` / `Ctrl+V`)**, **Deleção em Massa (`Delete`/`Backspace`)** e **Undo/Redo (`Ctrl+Z`/`Ctrl+Y`)**.

---

## 🛠️ Alterações Implementadas

### 1. Ferramenta de Seleção e Mover (`ToolMode.SELECT = 5`)
- **Atalhos Rápidos:**
  - Tecla **`6`** ou tecla **`M`** (Marquee / Move / Seleção).
  - Botão na barra de ferramentas: `📦 [6 / M] Seleção & Mover` (cor lilás `#e08cfa`).
  - Atualizado rótulo do painel para `FERRAMENTAS [1..6] / [Alt+Clique]`.

### 2. Caixa de Seleção Múltipla (Marquee Selection)
- **Clique e Arraste no Mapa:** Define um retângulo `selection_rect: Rect2i` entre a célula inicial e a célula atual do cursor.
- **Renderização Holográfica no `GridOverlay`:**
  - Novo método `update_selection_preview(rect, is_active, fill_col, line_col)`.
  - Desenha um quad translúcido lilás (`Color(0.85, 0.45, 1.0, 0.22)`) com contorno nítido e **cantoneiras reforçadas** para visual profissional.
  - Mantém a seleção visível de forma sutil mesmo se o usuário alternar para outras ferramentas.

### 3. Movimentação Física por Arraste
- Ao clicar dentro da área selecionada e arrastar o mouse:
  - Exibe o retângulo "fantasma" do destino em tempo real (`dest_rect`).
  - Ao soltar o botão esquerdo:
    - Registra snapshot no histórico de Undo (`_push_undo_snapshot()`).
    - Remove os elementos (terreno e objetos) da posição de origem.
    - Grava-os na nova coordenada de destino.
    - Notifica via toast: `📦 Seleção movida para [X, Z]!`.

### 4. Duplicação Instantânea (`Ctrl+D`) e Clipboard (`Ctrl+C` / `Ctrl+V`)
- **`Ctrl+D` (Duplicar em 1 Clique):**
  - Captura os dados da seleção atual com coordenadas relativas.
  - Entra automaticamente no modo de carimbo de colagem (`is_paste_mode = true`).
  - Mostra o preview verde holográfico da área a ser estampada sob o cursor.
  - Clicando no mapa, estampa uma cópia idêntica (terreno + flores + rochas) mantendo as origens intactas.
- **`Ctrl+C` / `Ctrl+V`:** Copia para a área de transferência do editor e permite colar em qualquer ponto da grade.
- **`Delete` / `Backspace`:** Deleta instantaneamente todo o conteúdo contido dentro da seleção com registro de Undo.
- **`Escape`:** Cancela a seleção ativa ou o modo de colagem.

---

## 🧪 Validação e Testes Automatizados

Criada a suíte [`tests/test_editor_selection_and_duplicate.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/tests/test_editor_selection_and_duplicate.gd) e `.tscn`, validando:
1. `ToolMode.SELECT == 5`.
2. Captura correta de terreno e flores relativas no `selection_clipboard`.
3. Duplicação e carimbo via `apply_paste_at` com integridade de dados.
4. Movimentação com limpeza da posição de origem e gravação no novo destino.
5. Deleção em massa com `delete_selection`.
6. Desfazer (`Ctrl+Z`) restaurando perfeitamente os elementos deletados.
7. Regressão executada com 100% de sucesso em todas as suítes anteriores (`test_editor_picker_and_ring`, `test_editor_camera_and_shortcuts`, `test_save_and_load_roundtrip`).
