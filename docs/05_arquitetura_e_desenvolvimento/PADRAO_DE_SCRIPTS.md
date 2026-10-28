# Padrão de Scripts e Boas Práticas GDScript 4 ⚡📜

Este documento estabelece as diretrizes estritas de código, padronização e garantia de **Zero Warnings** em **Grass Cut Bot**.

---

## 1. Princípio do "Zero Warnings" Estrito

O console da Godot Engine deve permanecer limpo em todas as execuções:
- **Proibição de Tipagem Implícita:** Toda variável de membro ou retorno de função deve declarar seu tipo estático:
  ```gdscript
  # Correto:
  var current_coins: int = 0
  func calculate_reward(plant_key: String) -> int:
      return 1

  # Incorreto:
  var current_coins = 0
  func calculate_reward(plant_key):
      return 1
  ```
- **Proibição de Divisões Inteiras Diretas Ocultas:** Utilize números de ponto flutuante explícitos (`1.0 / 2.0`) quando divisão decimal for requerida.
- **Prevenção de Shadowed Variables:** Jamais declare parâmetros ou variáveis locais com nomes que conflitem com propriedades de classes nativas da Godot (`position`, `rotation`, `scale`, `name`, `owner`).

---

## 2. Convenções de Nomenclatura

- **Arquivos e Pastas:** `snake_case` (ex: `level_controller.gd`, `floating_joystick.tscn`).
- **Nós e Cenas:** `PascalCase` (ex: `CharacterBody3D`, `BladeDisc`, `FloatingJoystick`).
- **Funções e Variáveis:** `snake_case` (ex: `set_input_direction()`, `is_stunned`).
- **Constantes e Enums:** `SCREAMING_SNAKE_CASE` (ex: `GameState.PLAYING`, `BASE_COST`).
- **Manipuladores de Sinais:** Prefixo `_on_` (ex: `_on_joystick_moved()`, `_on_time_updated()`).

---

## 3. Desacoplamento Arquitetural por Sinais

- Entidades filhas nunca devem referenciar nós pais ou irmãos diretamente via caminhos rígidos (`../../`).
- **Padrão Upwards via Signals:** Nós filhos emitem sinais quando seu estado muda (ex: `joystick_moved.emit(dir)`, `plant.cut()`).
- **Padrão Downwards via Methods:** Nós controladores chamam métodos em nós filhos (ex: `cutter.set_input_direction(dir)`).
- Os Autoloads (`GameManager`, `UpgradeManager`) operam como pontes globais de comunicação desacoplada.

---

## 4. Extração de Malhas e Ciclo de Vida MultiMesh

- **Ausência de `_ready()` fora da SceneTree:** Ao instanciar cenas com `PackedScene.instantiate()` exclusivamente para ler malhas e combiná-las via `SurfaceTool` (sem inserção na árvore via `add_child()`), lembre-se de que o método `_ready()` **não é executado**.
- **Atribuição Programática de Materiais:** Nunca confie que a lógica de estilização de nós filhos herdados no `.tscn` ou no `_ready()` estará presente na malha combinada. A atribuição de materiais para `MultiMeshInstance3D` deve ser feita de forma estática ou através de funções de montagem programática dedicadas (ex: `_build_flower_combined_mesh()`), forçando `st.set_material(mat)` com dicionários canônicos pré-carregados.
