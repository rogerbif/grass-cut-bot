# Histórico de Melhorias: 149 — Correção da Paridade e Rastreamento Dinâmico da Câmera no Playtest F1 do Editor 🎥🤖

**Data:** 29 de Outubro de 2026  
**Versão:** `v0.12.75-alpha`  
**Autor:** Antigravity (Google DeepMind)  
**Status:** Concluído e Validado ✅

---

## 1. Contexto e Diagnóstico

Ao acionar o teste de fase in-editor ([F1]), o usuário constatou que a câmera não se comportava de forma idêntica à do jogo real (`main.tscn`).

### Causa Raiz Identificada:
1. **Ausência de Atribuição do Target:**
   - Em `scripts/editor/level_editor.gd`, a câmera `playtest_game_camera` recebia apenas a atribuição da propriedade de caminho:
     ```gdscript
     playtest_game_camera.set("target_path", playtest_game_camera.get_path_to(_playtest_cutter))
     ```
   - No entanto, a classe canônica [`IsometricCamera`](../04_sistemas_e_gameplay/GAME_FEEL_E_HAPTICS.md) somente resolvia o nó `target: Node3D` dentro do seu método inicial `_ready()`.
   - Como o cortador de playtest (`_playtest_cutter`) é instanciado dinamicamente muito tempo após o carregamento inicial do editor, a variável interna `target` permanecia estritamente como `<null>`.
2. **Câmera Completamente Congelada e Desalinhada:**
   - No método `reset_cam()`, com `target == null`, a câmera caía no bloco `else`, olhando para um ponto fictício a partir da sua posição inicial estática `(0.0, 3.8756, 4.5809)`, em vez de se posicionar no spawn real do robô (`target.global_position + _current_gameplay_offset`).
   - No loop contínuo de física (`_physics_process`), a primeira linha `if not target: return` interrompia imediatamente a execução:
     - A câmera **não seguia o robô** ao se locomover pelo mapa;
     - A câmera **não realizava zoom dinâmico** por nível de lâmina;
     - A câmera **não aplicava o camera shake** ao colidir com rochas.
3. **Interferência Residual do `editor_camera`:**
   - Os controles de movimentação (`movement_enabled`) da câmera de edição livre permaneciam ativos ao pressionar setas direcionais durante o playtest.

---

## 2. Alterações Realizadas

### 2.1. Resolução Reativa e Defensiva do Target em `IsometricCamera`
- **`scripts/camera/isometric_camera.gd`:**
  - Adicionado setter reativo à propriedade `target_path`:
    ```gdscript
    @export var target_path: NodePath:
    	set(v):
    		target_path = v
    		if is_inside_tree() and has_node(target_path):
    			target = get_node(target_path) as Node3D
    ```
  - Em `reset_cam()`, inserida checagem defensiva: caso `target` seja nulo ou inválido, resolve automaticamente a partir de `target_path`.
  - Garantido que `look_at_from_position` ancore imediatamente a câmera na coordenada real do robô cortador no mundo (`target.global_position + _current_gameplay_offset`) com orientação e pitch canônicos de $-40.23^\circ$.
  - Em `_physics_process()`, adicionada verificação segura `if not target or not is_instance_valid(target): return`.

### 2.2. Ativação Precisa e Desativação Limpa no Editor
- **`scripts/editor/level_editor.gd`:**
  - Em `_start_playtest()`:
    1. Desativa a câmera do editor (`editor_camera.current = false`) e congela seu pan (`editor_camera.movement_enabled = false`).
    2. Atribui diretamente a instância do nó ao target da câmera oficial:
       ```gdscript
       playtest_game_camera.set("target", _playtest_cutter)
       playtest_game_camera.set("target_path", playtest_game_camera.get_path_to(_playtest_cutter))
       ```
    3. Executa `reset_cam()` e invoca `make_current()`.
  - Em `_stop_playtest()`:
    1. Desativa `playtest_game_camera.current = false` e limpa `playtest_game_camera.target = null`.
    2. Reativa `editor_camera.movement_enabled = true` e restaura a visualização de edição com `editor_camera.make_current()` e `restore_editor_view()`.

---

## 3. Testes Automatizados e Validação

1. **`tests/test_editor_camera_and_shortcuts.tscn`:**
   - Teste 1 expandido para instanciar o editor, disparar `_start_playtest()`, validar que `target` aponta fielmente para o `_playtest_cutter`, simular passos de física com deslocamento do robô ($X+10\text{m}, Z-8\text{m}$) e comprovar que a câmera acompanha suavemente as coordenadas sem lag ou salto, restaurando com perfeição ao invocar `_stop_playtest()`.
   - **Resultado:** 5/5 testes aprovados com 100% de sucesso.
2. **`tests/test_save_and_load_roundtrip.tscn`:**
   - 100% aprovado na persistência e restauração do novo formato 0.40m.
3. **`tests/test_editor_enhancements.tscn`:**
   - 7/7 testes aprovados.

---

## 4. Conclusão

A câmera do Playtest F1 agora possui **paridade total e idêntica à do jogo real**: foco exato no robô cortador desde o spawn, acompanhamento físico suave a 8.0 m/s em `_physics_process`, inclinação rígida de $-40.23^\circ$, FOV 48.0, suporte a camera shake e zoom dinâmico por evolução de lâmina.
