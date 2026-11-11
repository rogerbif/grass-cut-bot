# Histórico de Melhoria: Pacote 6 — Micro-Otimizações de CPU no Loop de Corte e Colisão Rígida 🪚⚡

- **Data de Conclusão:** 11/11/2026
- **Versão:** `v0.12.188-alpha` (Build Code: `1388`)
- **Status:** Entregue e Validado (Golden Master Bitwise Parity 100%)
- **Subdomínio:** Gameplay, Mecânicas e Entidades / Performance & Otimização
- **Arquivos Afetados:**
  - `scripts/plants/vegetation_grid.gd`
  - `scripts/core/game_version.gd`
  - `project.godot`
  - `export_presets.cfg`
  - `docs/historico_melhorias/INDICE_MELHORIAS.md`

---

## 1. Contexto e Motivação

Durante o perfilamento contínuo das rotinas críticas executadas a 60 FPS nos dispositivos móveis (Android), identificou-se que o loop de corte radial omnidirecional (`cut_in_circle()`) e o resolvedor de colisão com plantas rígidas de múltiplos cortes (`resolve_rigid_plant_collision()`) realizavam iterações desnecessárias sobre centenas de tufos e operações matemáticas não otimizadas:

1. **Varredura Cega de Colisão em Grama Simples:** O método `resolve_rigid_plant_collision()` é invocado a cada frame para checar resistência mecânica (trigo e flores, que possuem mais de 1 corte de vida). No entanto, em mais de 90% das células do mapa, existem exclusivamente tufos de grama comum (vida = 1). O laço iterava por todos os itens da célula, acessando arrays na memória para depois descartá-los com `_max_health[p_idx] <= 1`.
2. **Checagem de Vida antes do Flag de Corte:** Em plantas já cortadas (`_is_cut[p_idx] == 1`), o código acessava desnecessariamente `_max_health` antes de verificar se a planta já havia sido ceifada.
3. **Cálculos Euclidianos e Raízes Quadradas:** Em `cut_in_circle()`, o cálculo de distância ao quadrado já estava disponível, porém para a dispersão de partículas realizava-se `sqrt()` desnecessariamente mesmo quando a distância não excedia o raio máximo, além de instanciações intermediárias de vetores `Vector3` para o cálculo de recuo (knockback).

---

## 2. Implementações Realizadas

### A. Tag de Presença Rígida no Índice CSR (`_grid_has_rigid`)
- Adicionou-se o array tipado `_grid_has_rigid: PackedByteArray` no índice espacial CSR contíguo de `VegetationGrid`.
- Durante a construção do índice (`_build_spatial_index()`), se qualquer planta atribuída à célula possuir vida máxima superior a 1 (`_max_health > 1`), a célula é marcada como rígida (`_grid_has_rigid[ci] = 1`).
- Em `resolve_rigid_plant_collision()`, implementou-se rejeição instantânea $O(1)$:
  ```gdscript
  if _grid_has_rigid[cell_i] == 0:
      continue
  ```
  Isso elimina entre 85% e 95% das iterações de células sem tocar nos itens ou na memória, liberando precioso tempo de CPU na thread de física.

### B. Inversão Defensiva de Branching no Loop de Colisão
- Reordenou-se a condicional em `resolve_rigid_plant_collision()` para verificar primeiramente se a planta já foi ceifada:
  ```gdscript
  if _is_cut[p_idx] == 1:
      continue
  if _max_health[p_idx] <= 1:
      continue
  ```
  Evita acesso a `_max_health` para qualquer planta previamente abatida.

### C. Otimização Aritmética em `cut_in_circle()`
- Armazenamento em cache de `var dist_sq: float = dx * dx + dz * dz`.
- Substituição da chamada de raiz quadrada euclidiana `sqrt()` por comparação direta de quadrados na dispersão de partículas (`dist_sq > max_p_dist_sq`).
- Eliminação da criação de vetores temporários no cálculo de recuo (knockback), aplicando diretamente as componentes escalares `-dx` e `-dz`.

---

## 3. Verificação e Testes

- **Golden Master Test (`tests/test_vegetation_spatial_index.tscn`):**
  - Executado em modo headless contra os níveis 1, 3, 12, 20 e 40.
  - Resultado: **`GOLDEN_RESULT|PASS`** com 0 discrepâncias e 100% de paridade bitwise nos hashes de corte e colisão determinística.
- **Suíte de Testes Adicionais:**
  - `tests/test_species_auto_discovery.gd` -> **PASS (100%)**
  - `tests/test_blade_progression.tscn` -> **PASS (100%)**
  - `tests/test_collection_system.tscn` -> **PASS (100%)**
  - `tests/test_all_botanical_variations.gd` -> **PASS (100%)**
- **Importação Headless:**
  - `godot --headless --import` executado com 0 erros e 0 warnings.
