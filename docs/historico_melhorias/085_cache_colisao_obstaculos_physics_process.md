# 085 - Otimização de Performance: Cache Contíguo de Obstáculos no Physics Process (Tarefa 1.1) ⚡🪨

## 1. Contexto e Diagnóstico
Durante a auditoria de desempenho do projeto, identificou-se um gargalo crítico de CPU dentro do método `_check_obstacle_collisions()` em `scripts/cutter/cutter.gd`:
- A cada tick do loop de física de 60 Hz (`_physics_process`), o script executava `get_tree().get_nodes_in_group("obstacles")`, gerando alocações dinâmicas de `Array[Node]` no heap a cada 16 milissegundos.
- Para cada nó retornado, realizava-se `get_node_or_null("CollisionShape3D")` para extrair o raio do colisor da rocha. Em fases com 25 obstáculos, isso totalizava **~1.500 buscas de árvore de nós e checagens dinâmicas de tipo por segundo**.
- Como todas as rochas da ilha são estáticas (`StaticBody3D` em `layer = 8`), suas posições e raios permanecem rigorosamente invariantes após a fase carregar.

---

## 2. Solução Implementada

### A. Estruturas Orientadas a Dados (Zero-Allocation & Data-Oriented)
Em `scripts/cutter/cutter.gd`, foram introduzidas estruturas primitivas contíguas de memória C++:
```gdscript
var _obstacle_positions_2d: PackedVector2Array = PackedVector2Array()
var _obstacle_radii: PackedFloat32Array = PackedFloat32Array()
var _obstacle_bounds: Rect2 = Rect2()
var _has_obstacles: bool = false
```

### B. Método `rebuild_obstacles_cache()`
- Implementado método de varredura única que pré-calcula as posições 2D no plano $XZ$, os raios efetivos dos colisores cilíndricos/esféricos e a caixa delimitadora 2D (*AABB Rect2*) com margem de segurança baseada no raio da lâmina giratória.
- Disparado via `call_deferred` no `_ready()` do cortador e sincronizado automaticamente por `LevelController.generate_level()` logo após o carregamento dos blocos e rochas do JSON da fase.

### C. Early-Exit Espacial & Loop Vetorial Otimizado
- No novo `_check_obstacle_collisions()`:
  1. Se `not _has_obstacles` ou se o cortador estiver fora da caixa delimitadora `_obstacle_bounds`, o método encerra com custo praticamente zero (~0.001 ms).
  2. Quando dentro da área com rochas, a iteração ocorre diretamente sobre `_obstacle_positions_2d` e `_obstacle_radii`, sem alocações no heap e sem chamadas à SceneTree.
- A salvaguarda física de impacto direto do chassi foi isolada em `_check_slide_collisions()`.

---

## 3. Preservação Rigorosa do Game Feel
Todo o feedback sensorial e a resposta de impacto mecânico foram preservados integralmente:
- Ricochete com força de arremesso de `9.5 m/s` e afundamento de suspensão (`-0.07m`).
- Disparo de faíscas metálicas (`spark_particles.restart()`).
- Vibração háptica de impacto no smartphone (`GameManager.trigger_haptic_impact()`).
- Efeito sonoro do choque dente-de-serra contra rocha (`AudioManager.play_sfx("slap_rock")`).
- Expressão furiosa com olhos de LED vermelhos e relâmpagos procedurais (`robot_eyes.trigger_obstacle_reaction()`).

---

## 4. Arquivos Modificados
- [`scripts/cutter/cutter.gd`](../../scripts/cutter/cutter.gd): Adicionado cache contíguo, `rebuild_obstacles_cache()`, early-exit espacial e loop vetorial.
- [`scripts/level/level_controller.gd`](../../scripts/level/level_controller.gd): Notificação explícita ao `cutter` após instanciar os obstáculos da fase.
- [`scripts/core/game_version.gd`](../../scripts/core/game_version.gd): Incremento para `v0.12.9-alpha`.
- [`project.godot`](../../project.godot) & [`export_presets.cfg`](../../export_presets.cfg): Sincronização do versionamento SemVer (build `1209`).
