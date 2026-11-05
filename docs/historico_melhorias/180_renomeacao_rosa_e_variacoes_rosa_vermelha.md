# Melhoria 180: Padronização Nominal da Rosa e Variação Rosa Vermelha (`v0.12.126-alpha`) 🌹✨

## 1. Contexto e Motivação
A espécie botânica `flower_rose` era historicamente rotulada como "Rosa Nobre". Para simplificar e harmonizar a taxonomia da vegetação conforme orientação de design, o nome canônico da espécie base passa a ser simplesmente **Rosa**, e sua variante vermelha principal (e default) passa a ser denominada especificamente **Rosa Vermelha**.

---

## 2. Ajustes Realizados

### A. Paleta de Objetos e Dock de Variações (`tile_palette_db.gd`)
- **Espécie Base no Catálogo de Objetos:**
  - `id`: `"flower_rose"`
  - `name`: `"Rosa"` (anteriormente `"Rosa Nobre"`)
  - `icon`: `"🌹"`
- **Variações Oficiais (`ITEM_VARIATIONS["flower_rose"]`):**
  - `flower_rose`: `"Rosa Vermelha"`
  - `flower_rose_white`: `"Rosa Branca"`
  - `flower_rose_yellow`: `"Rosa Amarela"`
  - `flower_rose_blue`: `"Rosa Azul"`
  - `flower_rose_wine`: `"Rosa Vinho"`
  - `flower_rose_black`: `"Rosa Negra"`
  - `flower_rose_peach`: `"Rosa Pêssego"`
- **Título do Dock Inferior:** O título do dock de variações agora exibe dinamicamente:
  `🎨 VARIAÇÕES DE COR (ROSA):`

### B. Catálogo de Metas do Editor (`level_editor_ui.gd`)
- O card da meta principal em `GOALS_CATALOG` foi atualizado:
  - `{ "key": "flower_rose", "name": "🌹 Rosa Vermelha", "color": Color(1.0, 0.15, 0.32), "unit": "rosas" }`

### C. Catálogo de Espécies da Coleção (`plant_database.gd`)
- A espécie `flower_rose` na Coleção botânica agora possui `"name": "Rosa"`.

---

## 3. Verificação e Testes
- **`tests/test_flower_variations_editor.tscn`**:
  - Testado o dock de variações com o novo título `ROSA`.
  - Validada a detecção das 7 rosas com nomes padronizados e metas separadas.
  - Execução headless: **100% aprovado (0 falhas, 0 warnings)**.
- **`tests/test_editor_goals_and_panel.tscn`**:
  - Validada a criação e contagem individual das metas: **100% aprovado**.
