# Histórico de Melhoria: Restauração da Grama Vetorial nas Ilhas do Menu Inicial 🌿🏝️

**ID:** `062_restauracao_grama_vetorial_ilhas_menu`  
**Versão:** `v0.9.8-alpha`  
**Data:** 21/10/2026  
**Status:** Concluído e Validado (0 Warnings no Godot 4.7.1)  

---

## 1. Contexto e Diagnóstico

Após a migração dos níveis para o formato de vegetação vetorial v3 (`grass_vectors`), os tufos de grama e trigo deixaram de aparecer visualmente nas ilhas em miniatura do Menu Inicial (tanto na visão do bot na Home quanto na visão do mapa).

### Causa Raiz
No arquivo `scripts/menu/island_node.gd`, o método `build_miniature_from_json(lvl)` ainda utilizava exclusivamente a lógica antiga de leitura do formato v1/v2:
1. Buscava o nó `"vegetation"` com `"rows"` no JSON.
2. Como os níveis atuais foram convertidos para `"grass_vectors"`, a chave `"vegetation"` não existia.
3. O fallback tentava instanciar a partir de `"objects"`, mas este contém apenas rochas e flores de tile, deixando a grade de vegetação vazia (`0` tufos).
4. Em consequência, os nós `MiniVegMMI_*` não eram criados, exibindo apenas o piso verde liso do terreno sem nenhum tufo de grama ou trigo.

---

## 2. Implementação Realizada

### A. Suporte Híbrido ao Formato Vetorial v3 no `island_node.gd`
- Importados os recursos necessários:
  - `const VectorGrassFieldScript = preload("res://scripts/level/vector_grass_field.gd")`
  - `const BrushPatterns = preload("res://scripts/editor/brush_patterns.gd")`
  - `const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")`
- Na função `build_miniature_from_json`:
  - Se `data.has("grass_vectors") and data["grass_vectors"] is Array`:
    1. Instancia `VectorGrassFieldScript` e popula a partir de `data["grass_vectors"]`.
    2. Recorta automaticamente os polígonos sob rochas sólidas (`clip_shapes` com o carimbo circular de rocha).
    3. Amostra todos os tufos através de Poisson Disk (`sample_all_tufts`).
    4. Adiciona flores de tile discretas a partir de `"objects"`.
    5. Constrói os transforms 3D por tipo de vegetação (`grass_green`, `wheat`, `flower`, etc.) com rotação e escala orgânica com atenuação de borda.
  - Caso contrário: preserva o suporte retrocompatível ao modo legado `veg_field` (v1/v2).

### B. Otimização e Efeito de Vento
- Mantida a estrutura de agrupamento em `MultiMeshInstance3D` por tipo de vegetação (`MiniVegMMI_%s`) com `cast_shadow = OFF` para performance mobile impecável (60 FPS).
- Registro automático das instâncias em `grass_mesh_records` para que a animação seletiva de vento (`set_grass_animated`) funcione na ilha ativa da Home.

---

## 3. Validação e Testes

- Executado teste automatizado instanciando a ilha da Fase 2 (`setup_island(2, true, 0)`):
  - `MiniTileMMI_island_center`: 221 instâncias
  - `MiniTileMMI_island_edge`: 52 instâncias
  - `MiniVegMMI_grass_green`: 1.165 instâncias geradas e visíveis
  - `MiniVegMMI_wheat`: 278 instâncias de trigo maduro geradas e visíveis
- Testada a cena do menu principal (`scenes/menu/main_menu.tscn`) via Godot Debug Runner (MCP):
  - Console da engine retornou com **0 warnings e 0 erros**.
- Gramado e trigo agora aparecem fartos e vibrantes em todas as ilhas do Menu Inicial.

---

## 4. Arquivos Modificados

| Arquivo | Descrição das Modificações |
| :--- | :--- |
| `scripts/menu/island_node.gd` | Adicionado suporte completo à amostragem de `grass_vectors` v3 para geração dos `MultiMeshInstance3D` de vegetação. |
| `docs/historico_melhorias/INDICE_MELHORIAS.md` | Indexação da melhoria no catálogo mestre. |
| `scripts/core/game_version.gd`, `project.godot`, `export_presets.cfg` | Atualização SemVer para `v0.9.8-alpha` (code `908`). |
