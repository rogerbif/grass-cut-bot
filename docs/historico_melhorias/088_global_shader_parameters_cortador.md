# 088 - Otimização de Performance: Global Shader Parameters para Interação da Serra (Tarefa 1.3) 🪚⚡

## 1. Contexto e Diagnóstico
A deformação orgânica e o encurvamento da grama, trigo e flores ao redor da serra giratória do cortador necessitam da posição global (`cutter_pos`) e do raio de alcance da lâmina (`cutter_interact_radius`).
- **Gargalo Anterior:** No `scripts/cutter/cutter.gd`, o script mantinha referências carregadas para 9 arquivos `.tres` e executava 18 chamadas de `set_shader_parameter()` no GDScript a cada micro-deslocamento do robô.
- **Consequência:** Sobrecarga desnecessária na CPU (18 invocações por quadro de física) e invalidação individual de uniformes de materiais no driver gráfico da GPU (Vulkan/OpenGL ES). Além disso, o editor de fases precisava carregar e resetar manualmente os 9 arquivos `.tres` no disco.

---

## 2. Solução Implementada

### A. Configuração no `project.godot`
Declaradas as variáveis globais sob a seção `[shader_globals]`:
- `global_cutter_pos` (tipo `vec3`, valor padrão `Vector3(0, -9999, 0)`)
- `global_cutter_interact_radius` (tipo `float`, valor padrão `1.6`)

### B. Consumo Global em `interactive_grass.gdshader`
No shader espacial unificado de vegetação, os uniformes locais foram substituídos por declarações globais:
```glsl
global uniform vec3 global_cutter_pos;
global uniform float global_cutter_interact_radius;
```
O cálculo de distância e deformação curvilínea passa a ler diretamente do *Uniform Buffer Object* (UBO) global compartilhado na GPU.

### C. Atualização Direta via `RenderingServer`
- Em `scripts/cutter/cutter.gd`:
  - Removidos os 9 preloads de materiais `.tres`.
  - Método `_update_shader_globals()` reduzido para apenas 2 chamadas nativas em C++ no servidor de renderização:
    ```gdscript
    RenderingServer.global_shader_parameter_set("global_cutter_pos", global_position)
    RenderingServer.global_shader_parameter_set("global_cutter_interact_radius", interact_radius)
    ```
  - No `_exit_tree()`, a posição global é restaurada para `-9999.0m` defensivamente.
- Em `scripts/editor/level_editor.gd`:
  - O método `_reset_grass_shader_interaction()` agora reseta o parâmetro global diretamente via `RenderingServer`, eliminando a leitura dos 9 caminhos no disco.

---

## 3. Ganhos de Desempenho
- **CPU / GDScript:** Redução de 18 chamadas reflexivas de script por frame de física para apenas 2 chamadas diretas em C++.
- **GPU / Driver:** Atualização em bloco único de UBO compartilhado na memória de vídeo, reduzindo trocas de estado de material na GPU.
- **Memória:** Eliminação de 9 instâncias de materiais carregadas permanentemente como constantes no script do robô.

---

## 4. Arquivos Modificados
- [`project.godot`](../../project.godot): Registro de `global_cutter_pos` e `global_cutter_interact_radius` em `[shader_globals]`.
- [`shaders/interactive_grass.gdshader`](../../shaders/interactive_grass.gdshader): Adoção de `global uniform`.
- [`scripts/cutter/cutter.gd`](../../scripts/cutter/cutter.gd): Atualização via `RenderingServer.global_shader_parameter_set` e remoção de preloads.
- [`scripts/editor/level_editor.gd`](../../scripts/editor/level_editor.gd): Reset simplificado do shader global.
- [`scripts/core/game_version.gd`](../../scripts/core/game_version.gd): Avanço para `v0.12.12-alpha`.
- [`export_presets.cfg`](../../export_presets.cfg): Sincronização do versionamento SemVer (build `1212`).
