# 216 — Pacote 5: Pincéis Paramétricos Customizáveis & Carimbos por Imagem P&B no Editor (`v0.12.168-alpha`)

**Data:** 09/11/2026
**Versão:** `v0.12.168-alpha` (`version/code = 1368`)
**Arquivos Modificados:**
- `scripts/editor/brush_patterns.gd`
- `scripts/editor/grid_overlay.gd`
- `scripts/editor/level_editor_ui.gd`
- `scripts/editor/level_editor.gd`
- `tests/test_editor_pacote5.gd`

---

## 🎯 Contexto e Objetivo
O **Pacote 5** expande o sistema de pincéis e carimbos do Editor de Fases em duas frentes solicitadas pelo usuário:
1. **Pincéis Paramétricos Editáveis em Tempo Real:** permitir customizar o número de pontas da Estrela (`3` a `16`), a profundidade das pontas (incluindo conversão em Polígono Regular), a espessura dos braços da Cruz e um novo pincel de **Anel / Rosquinha (`🍩`)** com controle do tamanho do furo central.
2. **Sistema de Pincéis por Imagem Preto e Branco (`🖼️ Imagem P&B`):** permitir usar máscaras de imagem P&B (ou PNGs com transparência) convertidas automaticamente em polígonos vetoriais via `BitMap.opaque_to_polygons`, suportando **formas compostas** (múltiplas ilhas ou manchas separadas em 1 clique), 6 presets embutidos e importação de arquivos `.png`/`.jpg`/`.webp` do computador.

---

## 🛠️ Alterações Implementadas

### 1. Motor Paramétrico e Vetorização `BitMap` (`brush_patterns.gd`)
- Adicionados `ShapeType.RING = 7` (`🍩 Anel / Furo`) e `ShapeType.IMAGE_STAMP = 8` (`🖼️ Imagem P&B`).
- Criado `get_vector_stamp_polygons(...) -> Array[PackedVector2Array]` para suportar formas compostas e anéis vazados.
- **Estrela Customizável (`ShapeType.STAR`):** suporta `star_points` (`3..16`) e `star_inner_ratio` (`0.15..1.00`, gerando polígonos regulares de $N$ lados quando `>= 0.99`).
- **Cruz Customizável (`ShapeType.CROSS`):** suporta `cross_thickness` (`0.15..0.75`).
- **Anel (`ShapeType.RING`):** retorna o círculo externo e o círculo interno (`ring_hole_ratio` de `0.20..0.85`) para vazamento automático em 1 clique.
- **Imagem P&B (`ShapeType.IMAGE_STAMP`):** usa `BitMap.opaque_to_polygons(Rect2i(0, 0, w, h), epsilon)` com cache estático $O(1)$ (`_image_polygon_cache`), 6 presets P&B em alta nitidez (`paw`, `spiral`, `moon`, `bolt`, `clover`, `puzzle`), carregamento de arquivos externos, inversão P&B e ajuste de `epsilon`.

### 2. Preview Multi-Polígono (`grid_overlay.gd`) e Aplicação no Editor (`level_editor.gd`)
- `grid_overlay.update_vector_polygons_preview()` triangula e desenha todos os sub-polígonos de uma imagem P&B ou os dois anéis concêntricos do `RING` no preview holográfico em tempo real.
- `_apply_brush_at()` aplica todos os polígonos de `IMAGE_STAMP` e recorta automaticamente o miolo de `RING` tanto no Terreno Vetorial quanto na Grama Vetorial, além de amostrar o mesmo formato na Camada de Objetos.

### 3. Subpainel Contextual na UI (`level_editor_ui.gd`)
- Adicionado `brush_custom_params_box` no painel esquerdo, exibindo contextualmente os controles de `STAR`, `CROSS`, `RING` ou `IMAGE_STAMP` (com `FileDialog` para importar PNGs do PC).

---

## ✅ Verificação e Testes
- Executada a suíte `res://tests/test_editor_pacote5.gd` junto com `test_editor_pacote1..4.gd` e `verify_levels_integrity.gd` via Godot 4.7.2 CLI: **100% de aprovação, 0 warnings e 0 erros**.
