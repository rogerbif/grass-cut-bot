# Registro de Melhoria 231: Pacote 3 — DOD, Índice Espacial CSR e Remoção de Código Morto

**Data de Conclusão:** 11/11/2026  
**Versão SemVer:** `v0.12.185-alpha`  
**Tipo:** Arquitetura / Performance / Refatoração DOD / Limpeza de Código Morto  
**Escopo:** `scripts/plants/vegetation_grid.gd`, `scripts/level/level_json_loader.gd`, `scripts/level/vegetation_field.gd`, remoção de `lawn_cut_trail.gd` e `lawn_base_decal.gdshader`.

---

## 🎯 1. Resumo Executivo e Objetivos

O **Pacote 3** da auditoria arquitetural consolidou o pipeline de vegetação e terreno com foco em **Data-Oriented Design (DOD)**, localidade espacial de memória (CPU cache friendliness) e saneamento rigoroso de código morto / subsistemas legados descontinuados.

Os principais avanços técnicos entregues incluem:
1. **Índice Espacial CSR (Compressed Sparse Row) Contíguo 1D:**
   - Eliminação do antigo `Dictionary` esparso (`_spatial_grid: Dictionary[int, Array[int]]`) em `VegetationGrid`.
   - Implementação de arrays contíguos 1D `PackedInt32Array`: `_grid_cell_start` (tamanho `cells + 1`) e `_grid_items` (tamanho exato `count`).
   - Construção por **Counting Sort estável** em $O(N)$, eliminando centenas de instâncias de arrays e nós de heap na inicialização de cada fase.
   - Localidade de cache em `cut_in_circle` e `resolve_rigid_plant_collision`: cada célula $2.0 \times 2.0\text{m}$ mapeada na AABB é iterada como uma fatia contígua (`slice`) de índices de tufo sem indireção ou hashing.
2. **Eliminação de Armazenamento Excedente de Transform3D:**
   - Removido o cache redundante de 48 bytes por tufo (`_cut_transforms`). O estado residual de grama cortada é derivado dinamicamente via `_get_cut_transform(p_idx)` somente sob demanda no momento do corte.
3. **Expurgo Completo de Subsistemas Legados de Vegetação / Rastro:**
   - Removido `_build_from_vegetation_field` (~320 linhas de rasterização legada) e mapeamento `_tuft_logical_cell`.
   - Removido o subsistema de rastro via decal/SubViewport: descontinuados `_setup_lawn_decal_and_trail`, `_lawn_cut_trail`, `_lawn_decal_mesh`, `to_density_image()`.
   - Excluídos fisicamente os arquivos obsoletos `scripts/level/lawn_cut_trail.gd` e `shaders/lawn_base_decal.gdshader` (substituídos definitivamente pelo clipping de aparas com `visible_instance_count`).
4. **Saneamento Arquitetural de `LevelJsonLoader`:**
   - Redução de 491 linhas para 168 linhas (-66% de peso).
   - Remoção de `TILE_SCENES` redundante, instanciadores legados de tiles com colisão manual e rotinas costeiras (`build_coastal_colliders_and_foam`, `_build_coastal_tile_edges`, etc.), cuja responsabilidade canônica já pertence a `IslandMeshBuilder` e `CoastalFoamRibbon`.

---

## 🔬 2. Validação Rigorosa & Golden Master Test

Para garantir zero regressão funcional, foi desenvolvido um teste de suíte de golden master:
- `tests/test_vegetation_spatial_index.gd` / `tests/test_vegetation_spatial_index.tscn`
- Validação automática de 5 níveis representativos (Level 01, Level 03, Level 12, Level 20 e Level 40):
  - Contagem total de tufos (ex: 3.884 no Level 40).
  - Sequência exata de cortes em trajetórias circulares e diagonais (hash de sequência idêntico).
  - Emissão de eventos `grass_cut` e colheitas de objetivos.
  - Distribuição e alocação de clippings (`visible_instance_count`).
  - Resolução física de colisão com plantas rígidas (hash de resoluções idêntico).
  - Reset completo e re-construção de fase.
- **Resultado:** `GOLDEN_RESULT|PASS` em 1.4s com 100% de paridade determinística bitwise.

---

## 📊 3. Impacto de Performance & Memória

| Métrica | Antes (v0.12.184-alpha) | Depois (v0.12.185-alpha) | Ganho |
| :--- | :--- | :--- | :--- |
| **Estrutura do Índice Espacial** | `Dictionary` com `Array[int]` por bucket | Flat Arrays 1D CSR (`PackedInt32Array`) | Zero overhead de hash table, contiguidade na CPU L1/L2 |
| **Linhas de Código em `LevelJsonLoader`** | 491 linhas | 168 linhas | **-66% de complexidade** |
| **Linhas de Código em `VegetationGrid`** | 1.150 linhas | ~830 linhas | **-28% de código morto / legado** |
| **Cache de Transform3D por Tufo** | 48 bytes * N tufos na RAM | 0 bytes armazenados (derivado on-the-fly) | Redução de alocação de heap |
| **Arquivos Órfãos no Projeto** | `lawn_cut_trail.gd`, `lawn_base_decal.gdshader` | Removidos | Projeto mais limpo e builds menores |

---

## 🏁 4. Status de Guardrails

- **Zero Warnings Godot 4:** 0 warnings em headless import e testes de runtime.
- **Guardrail #17 (Fases Procedurais):** Zero alterações em `data/levels/level_*.json`.
- **Game SemVer:** Atualizado para `v0.12.185-alpha` (code: 1385).
