# 089 - Otimização de Performance: Cache de Referência do Cortador no FloatingCoinManager (Tarefa 1.4) 🪙⚡

## 1. Contexto e Diagnóstico
A exibição de números flutuantes 3D de moedas (`+1`, `+3`, `+5`) calculada em `scripts/effects/floating_coin_manager.gd` ancora a coordenada de nascimento em um dos 3 setores do anel interno da lâmina giratória (`get_inner_blade_point`).
- **Gargalo Anterior:** O método `_get_cutter()` chamava `get_tree().get_first_node_in_group("cutter")` a cada invocação de `_on_coin_popup_requested()`.
- **Consequência:** A cada meta colhida, a SceneTree realizava uma varredura por nós pertencentes ao grupo `"cutter"`. Durante ceifas contínuas e rápidas, ocorriam dezenas de lookups desnecessários por segundo na CPU.

---

## 2. Solução Implementada

### A. Referência Preguiçosa em Cache (*Lazy Cached Reference*)
Em [`scripts/effects/floating_coin_manager.gd`](../../scripts/effects/floating_coin_manager.gd):
- Declarada a variável local de cache:
  ```gdscript
  var _cached_cutter: CharacterBody3D = null
  ```
- O método `_get_cutter()` agora reaproveita a referência armazenada na memória RAM, buscando na árvore exclusivamente quando `_cached_cutter == null` ou se o nó for invalidado:
  ```gdscript
  func _get_cutter() -> CharacterBody3D:
      if _cached_cutter == null or not is_instance_valid(_cached_cutter):
          var tree: SceneTree = get_tree()
          if tree != null:
              _cached_cutter = tree.get_first_node_in_group("cutter") as CharacterBody3D
      return _cached_cutter
  ```
- No `_ready()`, invoca-se `call_deferred("_get_cutter")` para pré-popular a referência assim que a cena entra na árvore.

---

## 3. Preservação do Game Feel e Resultados
- **Comportamento Idêntico:** O rastro de moedas flutuantes continua subindo nos 3 setores do anel interno (Esquerda, Centro, Direita) com pop elástico e contorno cel-shaded cartoon de 14px.
- **Zero Lookups Redundantes:** O custo de localização do robô por popup de moeda caiu para **0 ms** após o primeiro acesso.
- **Fase 1 do Plano Mestre de Performance 100% Concluída:** Tarefas 1.1, 1.2, 1.3 e 1.4 finalizadas com sucesso.

---

## 4. Arquivos Modificados
- [`scripts/effects/floating_coin_manager.gd`](../../scripts/effects/floating_coin_manager.gd): Cache de referência do cortador.
- [`scripts/core/game_version.gd`](../../scripts/core/game_version.gd): Avanço para `v0.12.13-alpha`.
- [`project.godot`](../../project.godot) & [`export_presets.cfg`](../../export_presets.cfg): Sincronização do versionamento SemVer (build `1213`).
