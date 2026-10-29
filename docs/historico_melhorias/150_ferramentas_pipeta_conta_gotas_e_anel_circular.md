# Melhoria 150: Ferramentas de Pipeta (Conta-Gotas / Eyedropper) e Carimbo em Anel Circular no Editor de Fases

**Versão:** `v0.12.76-alpha`  
**Data:** 29/10/2026  
**Tipo:** Feature / QoL / Level Editor  
**Status:** Concluído ✅  

---

## 📋 Contexto e Motivação

Durante o fluxo de montagem de fases no editor PC fullscreen, foram identificadas duas necessidades de produtividade e refinamento artístico de alto impacto (Quick Wins):
1. **Conta-Gotas / Pipeta (Eyedropper):** A capacidade de inspecionar e amostrar qualquer elemento já posicionado no mapa com um único clique ou atalho, alternando instantaneamente a camada ativa (`EditLayer`), o item selecionado e a rotação, sem obrigar o level designer a navegar repetidamente pelas abas de Terreno, Grama ou Objetos.
2. **Carimbo de Distribuição em Anel Circular (`⭕ Anel Circular`):** O posicionamento de composições circulares de flores (como círculos de 6 a 12 margaridas/flores em volta de um centro vazio), rochas em semicírculos/anéis e faixas anulares de grama vetorial de forma harmônica e instantânea, mantendo o padrão invariante de flores voltadas para a câmera ($0^\circ$).

---

## 🛠️ Alterações Implementadas

### 1. Ferramenta de Pipeta (Conta-Gotas / Eyedropper)
- **Modo de Ferramenta:** Adicionado `ToolMode.PICKER = 4` em `LevelEditor`.
- **Atalhos Rápidos:**
  - `Alt + Clique Esquerdo`: Amostra imediatamente o elemento sob o cursor sem precisar trocar de ferramenta antes.
  - Tecla `5` ou tecla `I`: Seleciona a ferramenta Pipeta na barra de ferramentas.
- **Detecção Multicamadas Inteligente:**
  - **Objetos (`EditLayer.OBJECTS`):** Se houver uma flor, trigo, rocha ou spawn no bloco, seleciona a camada de Objetos, define o `active_object_id` e restaura o ângulo de rotação original (`current_rot_deg`).
  - **Grama Vetorial (`EditLayer.GRASS`):** Através do novo método `VectorGrassField.get_type_at_point(point: Vector2)`, detecta em $<0.01\text{ms}$ (via `Geometry2D.is_point_in_polygon` com exclusão de furos) a cor/tipo de grama sob a coordenada contínua XZ do mundo, selecionando a camada de Grama e o tipo correspondente.
  - **Terreno da Ilha (`EditLayer.TERRAIN`):** Amostra o tile do terreno (modo automático `auto_island` ou tile específico) e restaura sua rotação.
- **Retorno Automático:** Ao clicar com a ferramenta `PICKER` ativa, o editor amostra o item e retorna automaticamente para o modo `BRUSH` (Pincel) para pintura contínua imediata.
- **Feedback Sensorial:** Notificações toast estilizadas na UI (`ui.show_toast`) indicando com clareza o elemento capturado.

### 2. Carimbo de Distribuição em Anel Circular (`ShapeType.RING`)
- **Nova Forma Canônica:** Adicionado `ShapeType.RING = 7` e metadado `{ "id": ShapeType.RING, "name": "Anel Circular", "icon": "⭕" }` em `BrushPatterns.SHAPE_INFO`.
- **Distribuição Geométrica na Grade:**
  - Para camadas de Objetos e Terreno, `BrushPatterns.get_brush_offsets` distribui $N = \max(6, \text{brush\_size} \times 4)$ pontos uniformemente espaçados ao longo da circunferência de raio $R = \text{brush\_size} \times 2.0$ células ($0.8\text{m}$ a $4.8\text{m}$), mantendo o centro do anel rigorosamente oco.
  - **Flores Voltadas para a Câmera:** Todas as flores geradas no anel preservam `rot = 0` (frente para o Sul / câmera), atendendo ao padrão artístico do projeto.
  - **Proteção Anti-Choque:** Respeita o raio de clareira de $1.40\text{m}$ de qualquer rocha vizinha.
- **Grama Vetorial Anular:**
  - `BrushPatterns.get_ring_polygons(center, radius_m, thickness_m)` gera pares de polígonos (externo e furo interno), adicionando a faixa de grama anular diretamente via `VectorGrassField.add_shape` com a lista de furos (`holes_list`).
  - Preview holográfico em tempo real exibido perfeitamente no `GridOverlay`.

### 3. Interface e Barra de Status
- Adicionado botão `💉 [5 / I] Pipeta (Conta-Gotas)` ao painel esquerdo do editor com cor ciano (`Color(0.40, 0.85, 1.0)`).
- Rótulo de atalhos atualizado para `FERRAMENTAS [1..5] / [Alt+Clique]`.
- Botão de forma `⭕ Anel Circular` adicionado automaticamente à grade de formatos de carimbo.
- Barra inferior de status atualizada com o atalho `[Alt+Esq/5]: Pipeta`.

---

## 🧪 Validação e Testes Automatizados

Criada a suíte `tests/test_editor_picker_and_ring.gd` e `tests/test_editor_picker_and_ring.tscn`, validando:
1. `ShapeType.RING` presente em `BrushPatterns.SHAPE_INFO` com id 7 e ícone ⭕.
2. `get_brush_offsets` gerando anel oco com 6 e 8 células para escalas 1 e 2.
3. `get_ring_polygons` gerando polígonos externos e de furos válidos com $\ge 8$ vértices.
4. Pipeta capturando `flower_daisy` e alternando para camada 2 (`OBJECTS`).
5. Pipeta capturando `tile_sand` e rotação 90° e alternando para camada 0 (`TERRAIN`).
6. Pipeta em `ToolMode.PICKER` retornando automaticamente para `ToolMode.BRUSH`.
7. Carimbo em Anel gerando 7 flores voltadas para a câmera ($0^\circ$) com centro preservado oco.
8. Regressão executada com 100% de sucesso nas suítes `test_editor_camera_and_shortcuts.tscn` e `test_save_and_load_roundtrip.tscn`.
