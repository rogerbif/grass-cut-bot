# Registro de Melhoria 232: Pacote 4 — Catálogo Botânico Data-Driven e Auto-Descoberta de Espécies

**Data de Conclusão:** 11/11/2026  
**Versão SemVer:** `v0.12.186-alpha`  
**Tipo:** Arquitetura / Orientação a Dados (DOD) / Extensibilidade  
**Escopo:** `scripts/plants/plant_species_data.gd`, `data/species/*.tres`, `scripts/plants/plant_database.gd`, `scripts/plants/vegetation_grid.gd`, `tests/test_collection_system.gd`, `tests/test_species_auto_discovery.gd`.

---

## 🎯 1. Resumo Executivo e Objetivos

O **Pacote 4** consolida a migração do ecossistema botânico para uma abordagem **100% orientada a dados (Data-Driven Design)**, introduzindo **Auto-Descoberta Dinâmica de Recursos** em tempo de execução:
1. **Classe Tipada `PlantSpeciesData` (`Resource`):**
   - Encapsula metadados de identidade taxonômica (`key`, `category`, `name`, `icon`, `color`, `origin_level`, `hits`, `reward_coins`, `desc`, `milestones`).
   - Encapsula parâmetros de renderização (`mesh_path`, `material_path`, `clipping_color`, `particle_petal_color`, `particle_center_color`).
   - Implementa `to_dict() -> Dictionary` para interoperabilidade imediata com sistemas legados.
2. **Modularização em Recursos `.tres`:**
   - 13 instâncias canônicas salvas em `res://data/species/` (7 gramas, 1 cultura de trigo e 5 flores/canteiros).
3. **Auto-Descoberta Dinâmica no `PlantDatabase`:**
   - Varredura via `DirAccess` de `res://data/species/`.
   - Ao adicionar qualquer novo arquivo `.tres` na pasta, o jogo o descobre e assimila dinamicamente sem necessidade de alterar código GDScript.
   - APIs orientadas a recursos (`get_all_resources()`, `get_resource(key)`) coexistindo com as APIs originais (`get_all_species()`, `get_species(key)`).
4. **Desacoplamento Visual no `VegetationGrid`:**
   - `_resolve_clipping_color(v_type)` consulta diretamente `PlantDatabase.get_resource(v_type).clipping_color`, permitindo que novas plantas definam a cor de suas folhas fatiadas no próprio recurso.

---

## 🔬 2. Validação Automatizada

1. **Teste de Auto-Descoberta (`tests/test_species_auto_discovery.gd`):**
   - Cria uma nova espécie em tempo de execução (`res://data/species/test_crystal_flower.tres`).
   - Executa `PlantDatabase.reload_species()`.
   - Comprova expansão dinâmica de 13 para 14 espécies no catálogo de recursos e dicionários.
   - Remove o arquivo de teste e restaura as 13 espécies canônicas com 100% de integridade.
2. **Suíte Canônica de Testes:**
   - `tests/test_collection_system.tscn` -> **PASSOU (100%)**
   - `tests/test_vegetation_spatial_index.tscn` -> **PASSOU (GOLDEN_RESULT|PASS)**
   - `tests/test_all_botanical_variations.gd` -> **PASSOU (100%)**
   - `tests/test_blade_progression.tscn` -> **PASSOU (100%)**

---

## 📊 3. Tabela de Comparação

| Aspecto | Antes (v0.12.185-alpha) | Depois (v0.12.186-alpha) |
| :--- | :--- | :--- |
| **Definição de Espécies** | Arrays e Dicionários literais em GDScript | Recursos modulares `.tres` em `data/species/` |
| **Adição de Nova Planta** | Alteração em 4 scripts (`PlantDatabase`, `VegetationGrid`, etc.) | Criar 1 arquivo `.tres` em `data/species/` (Zero código) |
| **Aparas Caídas (Clippings)** | Cores hardcoded em `match` de 60 linhas | Lidas da propriedade `clipping_color` do recurso |
| **Suporte a Mods / Expansões** | Difícil (requer edição de scripts) | Imediato (basta colocar o `.tres` no pacote/pasta) |

---

## 🏁 4. Status de Guardrails

- **Zero Warnings Godot 4:** 0 warnings em headless import e testes de runtime.
- **Guardrail #14 (Tratamento Botânico Individual):** Preservada taxonomia 100% individual por espécie.
- **Guardrail #17 (Fases Procedurais):** Zero alterações em `data/levels/level_*.json`.
- **Game SemVer:** Atualizado para `v0.12.186-alpha` (code: 1386).
