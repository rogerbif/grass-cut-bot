# Plano Mestre de Otimização e Performance: Grass Cut Bot ⚡🌿

Este documento estabelece o diagnóstico técnico, a matriz de priorização por esforço versus impacto e o roteiro canônico de otimizações de desempenho para o **Grass Cut Bot** (Godot 4). O objetivo é garantir **60 FPS cravados**, redução no consumo de bateria e baixa dissipação térmica em smartphones Android modestos e intermediários.

---

## 🧭 1. Matriz de Priorização (Esforço vs. Impacto)

```
        ▲ ALTO IMPACTO
        │
        │  [2.1 Água sem Depth Tex]      [1.1 Cache de Rochas]
        │  [2.3 Scaling 3D / FSR]        [1.2 SubViewport Sob Demanda]
        │                                [1.3 Global Shader Uniforms]
        │
────────┼────────────────────────────────────────────────────────►
        │                                ALTO ESFORÇO
        │  [3.1 Visible Count Clippings] [4.1 Fallback gl_compatibility]
        │  [3.2 Pool Partículas Foliar]  [1.4 Cache Cutter CoinManager]
        │
        ▼ BAIXO IMPACTO
```

| ID | Subsistema | Tarefa / Otimização | Impacto | Esforço | Alvo Principal |
| :---: | :--- | :--- | :---: | :---: | :--- |
| **1.1** | **Física / CPU** | Cache pré-calculado de obstáculos (eliminar `get_nodes_in_group` e `get_node_or_null` em tick de 60Hz) | **Alto** | **Baixo** | ✅ **Concluído (`v0.12.9-alpha`)** |
| **1.2** | **Render / GPU** | SubViewport de trilha de corte em modo sob demanda (`UPDATE_ONCE` / dirty) | **Alto** | **Baixo** | ✅ **Concluído (`v0.12.11-alpha`)** |
| **1.3** | **Shaders / CPU** | Migração de parâmetros da lâmina para `RenderingServer.global_shader_parameter_set` | **Alto** | **Baixo** | ✅ **Concluído (`v0.12.12-alpha`)** |
| **1.4** | **Efeitos / CPU** | Cache de referência do cortador no `FloatingCoinManager` | **Médio** | **Mínimo** | ✅ **Concluído (`v0.12.13-alpha`)** |
| **2.1** | **Shaders / GPU** | Desacoplar `depth_texture` da água do mar em mobile (aproveitando `CoastalFoamRibbon`) | **Crítico** | **Médio** | ✅ **Concluído (`v0.12.14-alpha`)** |
| **2.2** | **Render / GPU** | Avaliação de Backface Culling (`cull_back`) nas malhas de grama e aparas de solo | **Alto** | **Médio** | `shaders/interactive_grass.gdshader` |
| **2.3** | **Mobile / Engine** | Suporte a Escala de Resolução 3D (Scaling 3D / FSR 1.0) nas configurações de usuário | **Alto** | **Médio** | `scripts/ui/settings_modal.gd` & `project.godot` |
| **3.1** | **Vegetação / VRAM** | Gerenciamento de `visible_instance_count` nos MultiMeshes de aparas cortadas | **Médio** | **Médio** | `scripts/plants/vegetation_grid.gd` |
| **3.2** | **Partículas / CPU** | Calibração do pool e contagem de partículas de corte | **Médio** | **Baixo** | `scripts/plants/plant.gd` |
| **4.1** | **Arquitetura** | Perfil experimental de renderizador OpenGL ES 3.0 (`gl_compatibility`) | **Médio** | **Alto** | `project.godot` |

---

## 📋 2. Frentes de Execução Detalhadas

### Fase 1: Vitórias Rápidas de CPU & Ciclos Ociosos (Quick Wins)
Foco em eliminar alocações repetitivas de memória, travamentos de garbage collection e redesenhos invisíveis sem nenhuma alteração visual perceptível.

1. **Tarefa 1.1 — Cache de Colisão de Rochas (`cutter.gd`):** Substitui a varredura dinâmica de nós da árvore a cada 1/60s por arrays numéricos estáticos `PackedVector2Array` e `PackedFloat32Array`.
2. **Tarefa 1.2 — SubViewport Sob Demanda (`lawn_cut_trail.gd`):** O `SubViewport` só é re-renderizado quando novas coordenadas de corte forem adicionadas ao buffer de pintura.
3. **Tarefa 1.3 — Global Shader Parameters (`cutter.gd`):** Substituição de 9 chamadas GDScript de material individual por uma única atualização direta via `RenderingServer`.
4. **Tarefa 1.4 — Cache no `FloatingCoinManager`:** Eliminação de chamadas a `get_first_node_in_group` a cada tufo coletado.

### Fase 2: Ganhos Centrais de GPU e Largura de Banda de VRAM
Foco em eliminar gargalos de fill-rate e passadas adicionais de profundidade da GPU.

1. **Tarefa 2.1 — Shader de Oceano Otimizado (`toon_water.gdshader`):** Remover a leitura de `hint_depth_texture` e derivadas `dFdx/dFdy` em mobile. A espuma da costa continuará existindo com perfeição através da geometria gerada por `CoastalFoamRibbon`.
2. **Tarefa 2.2 — Culling Seletivo de Faces Traseiras:** Reduzir para metade os fragmentos processados na vegetação ao habilitar descarte de faces traseiras (`cull_back`).
3. **Tarefa 2.3 — Scaling 3D / FSR:** Reduzir a quantidade bruta de pixels processados em displays mobile 1080p+ com ganho substancial de FPS e economia de bateria.

### Fase 3: Ganhos Incrementais & Polimento
1. **Tarefa 3.1 — Instâncias de Aparas:** Redução da carga de culling do `MultiMeshInstance3D` de aparas caídas usando `visible_instance_count`.
2. **Tarefa 3.2 — Partículas de Folhas:** Calibração fina da contagem e lifetime do pool de partículas.

---

## 📊 3. Critérios de Aceite e Métricas de Validação

Todas as alterações devem ser mensuradas com a ferramenta de benchmark integrada [`scenes/tools/perf_test.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/tools/perf_test.tscn) na **Fase 20**:
- **Zero Warnings** estrito no console do Godot.
- **Game Feel Inalterado:** Resposta da lâmina, recuo nas rochas, efeitos visuais e haptics 100% preservados.
- **60 FPS cravados** em dispositivos móveis Android de entrada/intermediários.
- **Redução do Physics Process Time** de ~2.8ms para < 0.9ms.
