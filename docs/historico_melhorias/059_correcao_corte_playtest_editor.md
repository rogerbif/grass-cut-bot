# Melhoria 059: Correção da Conexão de Corte no Modo Playtest do Editor 🏝️🤖✂️

**Data de Conclusão:** 21/10/2026  
**Versão Vinculada:** `v0.9.5-alpha` (Build Code: `905`)  
**Status da Entrega:** Concluído com 0 warnings, 0 erros e 100% testado no Godot 4.

---

## 🎯 Contexto do Problema

Ao testar uma fase no Editor de Fases através do modo **Playtest** (`F1`), o cortador (`Cutter`) conseguia se locomover e girar a serra, mas nenhuma grama era cortada: as metas do HUD ficavam congeladas e a vegetação permanecia intocada.

---

## 🔍 Causa Raiz Identificada

1. **Colisão de Nomes e Nós Zumbis por `queue_free()` diferido:**  
   A cada pincelada do usuário no editor, a função `_rebuild_3d_world()` chamava `queue_free()` nos filhos do container de plantas (`plants_container`). Como o Godot só libera nós no final do frame, o nó antigo `"EditorVegGrid"` continuava na árvore no momento em que o novo `VegetationGrid` era adicionado com `add_child()`, fazendo a engine renomear a instância ativa para um nome anônimo (ex: `@Node3D@1312`).
2. **Referência Órfã no Playtest:**  
   Ao iniciar o teste (`_start_playtest()`), o código realizava `plants_container.get_node_or_null("EditorVegGrid")`. Isso retornava o nó zumbi que estava marcado para deleção (`is_queued_for_deletion = true`), que era destruído no frame seguinte, deixando o `vegetation_grid` do cortador nulo ou desconectado da malha ativa visível na tela.

---

## 🛠️ Alterações Implementadas

### 1. Desvinculação Imediata da Árvore e Referência Forte (`scripts/editor/level_editor.gd`)
- Em `_rebuild_3d_world()`, os filhos de todos os containers 3D (`island_tiles_container`, `coastal_limits_body`, `plants_container`, `obstacles_container`) agora executam `remove_child(c)` **imediatamente** antes de chamar `c.queue_free()`.
- Criada a variável forte de membro `var _active_veg_grid: Node3D = null`.
- Ao criar a nova instância do `VegetationGrid`, ela é registrada diretamente em `_active_veg_grid = veg_grid_inst`.
- No `_start_playtest()`, o cortador recebe prioritariamente a referência forte `_active_veg_grid`, com varredura defensiva sobre filhos não deletados caso necessário.

---

## 🧪 Verificação e Testes
- **Diagnóstico Automatizado Headless:** Criado script de teste simulando múltiplas reconstruções seguidas de playtest e corte: o cortador recebe o nó ativo sem falhas e corta com sucesso os tufos com validação de `is_cut == 1`.
- **Godot Import Headless:** 0 erros e 0 warnings.

---

## 📦 Arquivos Modificados
- `scripts/editor/level_editor.gd`
- `project.godot`
- `export_presets.cfg`
- `scripts/core/game_version.gd`
- `docs/historico_melhorias/059_correcao_corte_playtest_editor.md`
- `docs/historico_melhorias/INDICE_MELHORIAS.md`
- `docs/03_level_design_e_fases/SISTEMA_EDITOR_DE_FASES.md`
