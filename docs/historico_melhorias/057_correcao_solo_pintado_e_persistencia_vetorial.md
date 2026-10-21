# Melhoria 057: Remoção do Solo Pintado Artificial e Blindagem da Persistência Vetorial v3 🌿💾

**Data de Conclusão:** 21/10/2026  
**Versão Vinculada:** `v0.9.3-alpha` (Build Code: `903`)  
**Status da Entrega:** Concluído com 0 warnings, 0 erros e 100% testado no Godot 4.

---

## 🎯 Contexto e Necessidade

Após a implementação da grama vetorial contínua v3, foram identificados dois comportamentos indesejados no fluxo de criação e gameplay:

1. **Solo Pintado sob a Grama:** Ao estampar ou desenhar formas de grama (como estrelas ou círculos), uma malha plana colorida (`GroundMesh`) era instanciada colada ao piso ($Y=0.005$) com a cor sólida correspondente. Como os tiles da ilha (`tile_island_center`, etc.) já possuem material e textura natural de grama verde, essa malha artificial cobria o terreno como uma tinta opaca não natural.
2. **Perda de Grama ao Salvar/Reabrir Fase:** No editor de fases, ao salvar ou exportar ("Bake"), a função `bake_to_tscn` chamava `save_level_json` passando apenas o antigo `veg_field` (vazio) e omitindo `vector_field`. Isso causava a sobrescrita do arquivo JSON como formato `version: 2` com linhas vazias (`"rows": ["...", ...]`). Ao reabrir a fase, o conversor gerava zero polígonos, exibindo apenas o terreno base.

---

## 🛠️ Alterações Implementadas

### 1. Eliminação do Solo Pintado Artificial (`scripts/plants/vegetation_grid.gd`)
- Removida a chamada `_setup_vector_ground_meshes(vector_field)` e a variável `_ground_mesh_instances`.
- Removidas as funções `_setup_vector_ground_meshes` e `_resolve_ground_color`.
- Agora, a ilha mantém sua textura e materiais 3D nativos intactos; a grama vetorial é representada exclusivamente por tufos 3D orgânicos amostrados via Poisson Disk, garantindo visual limpo e fiel à direção de arte low poly fosca.

### 2. Blindagem e Preservação Defensiva da Persistência Vetorial v3 (`scripts/editor/level_serializer.gd`)
- Atualizada a assinatura de `bake_to_tscn` para incluir `vector_field: RefCounted = null` e repassá-lo na chamada a `save_level_json`.
- Implementada salvaguarda defensiva em `save_level_json`: caso `vector_field` seja nulo mas o arquivo existente em disco já contenha `"grass_vectors"`, os vetores existentes são lidos e preservados, impedindo perdas acidentais de dados.
- Garantido que `version: 3` e `"grass_vectors"` sejam priorizados sempre que houver dados vetoriais.

### 3. Correção da Chamada de Bake no Editor (`scripts/editor/level_editor.gd`)
- Atualizada a função `bake_current_level_tscn()` para repassar `vector_grass` à função `LevelSerializer.bake_to_tscn`.
- Restaurado o arquivo `data/levels/level_02.json` a partir do histórico com versão 3 e vetores íntegros.

---

## 🧪 Verificação e Testes
- **Teste de Carga e Integridade:** Criado script de verificação executado via Godot headless validando serialização, bake, reload e preservação defensiva sem perda de formas (exit code 0).
- **Import Headless:** Executado `godot --headless --import` com 0 erros e 0 warnings.
- **Visual:** O solo agora exibe apenas a textura dos blocos 3D de terreno, sem decalques planos coloridos cobrindo a terra.

---

## 📦 Arquivos Modificados
- `scripts/plants/vegetation_grid.gd`
- `scripts/editor/level_serializer.gd`
- `scripts/editor/level_editor.gd`
- `project.godot`
- `scripts/core/game_version.gd`
- `data/levels/level_02.json`
