# Histórico de Melhoria: Correção das Malhas Multi-Superfície e Materiais de Flores no MultiMesh 🌸✨

- **Data de Conclusão:** 11/11/2026
- **Versão:** `v0.12.190-alpha` (Build Code: `1390`)
- **Status:** Entregue e Validado (Suíte de Integridade 100%)
- **Subdomínio:** Gameplay, Mecânicas e Entidades / Direção de Arte & Visual
- **Arquivos Afetados:**
  - `scripts/plants/vegetation_grid.gd`
  - `tests/test_flower_materials_integrity.gd` (Novo)
  - `scripts/core/game_version.gd`
  - `project.godot`
  - `export_presets.cfg`
  - `docs/historico_melhorias/INDICE_MELHORIAS.md`

---

## 1. Contexto e Causa Raiz

Após a dinamização de tipos no Pacote 5, identificou-se que durante a partida (gameplay) as flores estavam renderizando desfiguradas como hastes e folhas totalmente brancas no meio do gramado verde.

A investigação profunda revelou duas causas simultâneas:
1. **Precedência de Malha Crua em `_resolve_mesh_for_type()`:** Ao resolver a malha da flor, a busca em `PlantSpeciesData.mesh_path` vinha antes da resolução das malhas combinadas. O carregador lia o arquivo `.glb` do Blender cru (`PackedScene`) e extraía o primeiro `MeshInstance3D` encontrado (apenas as folhas cruas `Flower_Leaves`), descartando o caule, as pétalas e toda a estrutura composta do `_build_flower_combined_mesh()`.
2. **Sobreposição Destrutiva de `mmi.material_override`:** As flores no Grass Cut Bot são entidades multi-materiais com 3 superfícies independentes no `ArrayMesh`:
   - Superfície 0: `Flower_Petals` (shader da pétala da respectiva cor/espécie).
   - Superfície 1: `Flower_Leaves` (`interactive_flower_leaves_material.tres` verde).
   - Superfície 2: `Flower_Stem` (`interactive_flower_stem_material.tres` verde).
   Ao definir `mmi.material_override` no nó `MultiMeshInstance3D`, a engine Godot sobrepõe um único material em todas as superfícies da malha, apagando a diferenciação visual e exibindo as peças brancas ou com albedo nulo.

---

## 2. Implementações Realizadas

### A. Priorização das Malhas Multi-Superfície Canônicas
- Em `scripts/plants/vegetation_grid.gd`, o método `_resolve_mesh_for_type()` agora prioriza explicitamente a resolução canônica de flores e trigo:
  - Para `flower_rose`, `flower_daisy`, `flower_sunflower`, `flower_tulip`, `flower_bed` e flor base: retorna as malhas completas de 3 superfícies geradas por `_flower_variation_meshes`.
  - Para `wheat`: retorna `_wheat_mesh` (colmo + espiga).
  - Para `grass_*`: retorna `_grass_mesh`.
  - Apenas para novas espécies customizadas adicionadas dinamicamente via `.tres` sem pipeline multi-mesh realiza o fallback para `sp_res.mesh_path`.

### B. Isolamento de `material_override` para Flores e Trigo
- O método `_resolve_material_for_type()` agora retorna explicitamente `null` quando o tipo for flor (`begins_with("flower")`) ou trigo (`wheat`).
- Como consequência, o nó `MultiMeshInstance3D` dessas espécies não recebe `material_override`, permitindo que cada uma das 3 superfícies do `ArrayMesh` renderize seus materiais nativos de pétala, folha e caule.

### C. Teste de Integridade Automatizado
- Criado o teste `tests/test_flower_materials_integrity.gd`:
  - Varre todas as 23 variações e espécies de flores do jogo.
  - Assegura que toda flor possua rigorosamente 3 superfícies (`get_surface_count() == 3`).
  - Assegura que nenhuma superfície possua material nulo.
  - Assegura que `material_override` seja estritamente `null` para flores e trigo.
  - Assegura que grama possua seu material shader de gradiente vertical ativo.

---

## 3. Verificação e Testes

- `tests/test_flower_materials_integrity.gd` -> **PASS (100% de Sucesso - 23 espécies)**
- `tests/test_vegetation_spatial_index.tscn` -> **GOLDEN_RESULT|PASS (100% Bitwise Parity)**
- `tests/test_species_auto_discovery.gd` -> **PASS (100%)**
- `tests/test_obstacle_auto_discovery.gd` -> **PASS (100%)**
- `tests/test_rock_variations.gd` -> **PASS (100%)**
- `tests/test_all_botanical_variations.gd` -> **PASS (100%)**
- `godot --headless --import` -> **0 Erros / 0 Warnings**
