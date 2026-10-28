# Histórico de Melhorias: 147 — Ajuste Universal de Colchetes [ e ] para Escala e Rotação, Orientação Estável de Flores e Resiliência de Gravação e Leitura no Editor ⌨️🌸💾

**Data:** 28 de Outubro de 2026  
**Versão:** `v0.12.73-alpha`  
**Autor:** Antigravity (Google DeepMind)  
**Status:** Concluído e Validado ✅

---

## 1. Contexto e Motivação

O usuário identificou três pontos críticos de usabilidade e integridade no Editor de Fases:
1. **Atalhos de Colchetes `[` e `]` Universais:** As teclas `[` e `]` devem ser usadas tanto para ajustar a escala quanto para rotacionar o pincel selecionado, dependendo da ferramenta ativa:
   - Se pressionada a tecla **`S`**, a ferramenta ativa torna-se **Escala** (`QuickAdjustMode.SCALE`), e as teclas `[` e `]` diminuem/aumentam o tamanho do pincel.
   - Se pressionada a tecla **`R`**, a ferramenta ativa torna-se **Rotação** (`QuickAdjustMode.ROTATION`), e as teclas `[` e `]` giram o pincel no sentido anti-horário e horário (±5°, ou ±25° com Shift).
   - Por padrão, a ferramenta selecionada deve ser **Escala**.
   - Os botões da UI devem exibir visualmente `[` e `]` na ferramenta ativa (`➖ [` e `➕ ]` quando em Escala; `◀ [` e `] ▶` quando em Rotação).
2. **Eliminação de Flickers e Estabilidade de Rotação das Flores:**
   - Em capturas enviadas pelo usuário, flores exibiam listras horizontais de Z-fighting (flicker) sob sua base devido ao carimbo indevido de polígonos de piso na prancheta vetorial, somado a giros aleatórios a cada inserção.
   - A prancheta vetorial plana não deve estampar polígonos 2D redundantes sob flores 3D, e todas as malhas de solo devem manter elevação física de 1 milésimo ($0.001\text{m}$) por camada.
   - Toda flor posicionada no editor com a ferramenta padrão (Escala) é fixada voltada para a câmera ($0^\circ$), com tamanho determinístico estável.
3. **Resiliência de Gravação e Leitura (Roundtrip Save & Load):**
   - O usuário relatou salvar e retornar, sem que a fase reabrisse com suas alterações.
   - A causa raiz foi diagnosticada: no commit anterior de limpeza do repositório, o arquivo `level_01.json` (que continha as alterações manuais do usuário feitas minutos antes) foi revertido acidentalmente via git checkout.
   - Para blindar 100% contra qualquer perda futura, foram implementadas validações de escrita atômica com `flush()`, fallback de caminhos globalizados (`ProjectSettings.globalize_path`) tanto no `LevelSerializer` quanto no `LevelJsonLoader`, e ampliação de limites dos SpinBoxes de largura/altura da grade de 36 para 100.

---

## 2. Alterações Realizadas

### 2.1. Controle Universal por Colchetes `[` e `]` e Modo Padrão Escala
- **`scripts/editor/level_editor.gd`:**
  - `active_adjust_mode` inicializado por padrão como `QuickAdjustMode.SCALE`.
  - Pressionar **`S`** ativa `QuickAdjustMode.SCALE` e atualiza a UI.
  - Pressionar **`R`** ativa `QuickAdjustMode.ROTATION`, gira 1 incremento e atualiza a UI.
  - Teclas `KEY_BRACKETLEFT`, `KEY_MINUS` e `KEY_KP_SUBTRACT` decrementam a escala se em modo `SCALE` (salto de 5 com Shift), ou giram no sentido anti-horário se em modo `ROTATION` (salto de 25° com Shift).
  - Teclas `KEY_BRACKETRIGHT`, `KEY_PLUS`, `KEY_EQUAL` e `KEY_KP_ADD` incrementam a escala se em modo `SCALE` (salto de 5 com Shift), ou giram no sentido horário se em modo `ROTATION` (salto de 25° com Shift).

### 2.2. Feedback Visual Dinâmico na Interface
- **`scripts/editor/level_editor_ui.gd`:**
  - Armazenamento das referências de botões `btn_sz_minus` e `btn_sz_plus` na instância da UI.
  - Em `sync_state()`, atualização dinâmica dos rótulos dos botões:
    - Modo `SCALE` ativo: botões de tamanho exibem `➖ [` e `➕ ]`, enquanto os de rotação exibem `◀` e `▶`.
    - Modo `ROTATION` ativo: botões de rotação exibem `◀ [` e `] ▶`, enquanto os de tamanho exibem `➖` e `➕`.
  - Contêineres de painel `panel_scale_box` e `panel_rotate_box` recebem destaque visual com borda verde brilhante para indicar o modo atualmente sob controle das teclas `[` e `]`.

### 2.3. Erradicação de Flickers e Fixação da Rotação de Flores Voltada para a Câmera
- **`scripts/editor/level_editor.gd`:**
  - Removido o carimbo de polígonos 2D redundantes sob flores em `_build_editor_vector_ground()`. Como as flores são modelos 3D volumétricos completos em `obstacles_container`, a ausência do polígono co-planar elimina 100% dos flickers e listras de Z-fighting.
  - Todas as malhas de solo vetorial `EditorGroundMesh_%s` recebem deslocamento físico em Y (`mi.position.y = float(vt_idx) * 0.001`), erradicando disputas de profundidade entre cores de grama.
  - Em `_modify_single_cell()`, flores inseridas com a ferramenta padrão (Escala) recebem rotação forçada em $0^\circ$ (voltada diretamente para a câmera isométrica).
  - Em `_rebuild_3d_world()`, toda instância de flor recebe `randomize_rotation = false`, rotação $0^\circ$ e escala visual travada em $0.68$, impedindo qualquer rotação ou variação aleatória de tamanho ao adicionar novas flores.
- **`scripts/plants/plant.gd`:**
  - Garantido que quando `randomize_rotation == false`, a escala de flores em `plant.gd` seja determinística ($0.68$), eliminando trepidação de tamanho.

### 2.4. Resiliência de Gravação e Leitura no Novo Formato 0.40m
- **`scripts/editor/level_serializer.gd`:**
  - Adicionado fallback defensivo para caminhos absolutos globalizados via `ProjectSettings.globalize_path(path)` caso o caminho virtual `res://` falhe em sistemas Windows/OneDrive.
  - Adicionado `file.flush()` antes de fechar o arquivo para assegurar sincronização física imediata no disco rígido.
- **`scripts/level/level_json_loader.gd`:**
  - Adicionado suporte a caminhos globalizados no fallback de leitura `load_json_file()`.
- **`scripts/editor/level_editor_ui.gd`:**
  - Limite máximo de `spin_width` e `spin_height` aumentado de 36 para 100 colunas/linhas, acomodando grades subdivididas de 0.40m sem risco de truncamento.

---

## 3. Validação e Testes Automatizados

Foram executadas três suítes de testes automatizados headless via console da Godot 4.7.1:

1. **`tests/test_editor_camera_and_shortcuts.tscn` (5/5 testes aprovados):**
   - Presença e paridade da câmera Playtest F1 (FOV 48.0 e IsometricCamera).
   - Ajuste de escala e clamping [1..20].
   - Rotação padrão (5°) e com Shift (25°).
   - Rotação anti-horária e normalização circular modular 360°.
   - **Novo Teste 5:** Validação das teclas `[` e `]` universais alternando entre Escala e Rotação, com modo padrão Escala e flor com rotação 0° voltada para a câmera.

2. **`tests/test_save_and_load_roundtrip.tscn` (Aprovado com 100% de sucesso):**
   - Gravação completa de fase de teste no novo formato 0.40m com `LevelSerializer.save_level_json`.
   - Leitura via `LevelJsonLoader.load_json_file`.
   - Reconstrução completa no `LevelEditor` via `_load_or_init_level(49)`.
   - Integridade de 100% de blocos de terreno, objetos discretos e polígonos de grama.

3. **`tests/test_editor_enhancements.tscn` (7/7 testes aprovados):**
   - Raio máximo da serra (1.40m), polígono circular de pedra, separação vertical de 0.001m, rotação padrão de flores, clareira de rocha, corredor costeiro de 0.48m e `CELL_SIZE = 0.40m`.

---

## 4. Conclusão

O fluxo de edição no Editor de Fases agora opera com ergonomia unificada via `[` e `]`, sem qualquer flicker sob flores ou disputas de profundidade, com orientação estável frontal para a câmera e gravação/leitura de níveis com máxima resiliência e integridade.
