# Melhoria 143: Zero Warnings Estrito (Eliminação de 6 Avisos GDScript) e Resiliência Vulkan 🛡️🧹

## 🎯 Objetivo e Contexto
1. **Conformidade Estrita com o Mandamento 1 (Zero Warnings):**
   - Resolução de todos os 6 avisos de compilação e recarga apontados pelo console da Godot:
     - `INTEGER_DIVISION` em `hud.gd:108` (`var minutes: int = total_sec / 60`).
     - `SHADOWED_GLOBAL_IDENTIFIER` em `island_node.gd:10`, `vegetation_grid.gd:7` e `level_json_loader.gd:3` (redeclaração de constante local para classe global `IslandMeshBuilder`).
     - `CONFUSABLE_LOCAL_DECLARATION` em `vegetation_grid.gd:1313-1315` (`mmi_idx`, `inst_idx`, `mm` no bloco de tremor conflitantes com escopo inferior).
     - `UNUSED_VARIABLE` em `island_mesh_builder.gd:330` (`vert_normals` não utilizado no laço de colisores).
2. **Diagnóstico do Erro C++ Vulkan (`VK_ERROR_SURFACE_LOST_KHR`):**
   - Mapeamento e documentação técnica do erro de apresentação do driver Vulkan Mobile quando o app é minimizado, a tela é bloqueada ou o Android destrói a superfície de desenho nativa (`ANativeWindow`).

---

## 🛠️ Alterações Realizadas

### 1. `scripts/ui/hud.gd`
- Substituída a divisão inteira direta `total_sec / 60` por `floori(float(total_sec) / 60.0)` na formatação do cronômetro, eliminando o aviso `INTEGER_DIVISION`.

### 2. `scripts/menu/island_node.gd`, `scripts/plants/vegetation_grid.gd` e `scripts/level/level_json_loader.gd`
- Removidas as declarações redundantes `const IslandMeshBuilder = preload(...)`. Como a classe possui `class_name IslandMeshBuilder`, o identificador já é acessível globalmente sem sombreamento.

### 3. `scripts/plants/vegetation_grid.gd`
- Renomeadas as variáveis locais temporárias do bloco de micro-tremor para `shake_mmi_idx`, `shake_inst_idx` e `shake_mm`, eliminando o aviso `CONFUSABLE_LOCAL_DECLARATION`.

### 4. `scripts/level/island_mesh_builder.gd`
- Prefixada com sublinhado a variável não utilizada na geração de colisores (`_vert_normals`), eliminando o aviso `UNUSED_VARIABLE`.

---

## 🔍 Análise do Erro Vulkan (`VK_ERROR_SURFACE_LOST_KHR`)
- O erro C++ `drivers/vulkan/rendering_device_driver_vulkan.cpp @ command_queue_execute_and_present(): VK_ERROR_SURFACE_LOST_KHR` ocorre quando o Android invalida a superfície de renderização nativa enquanto a engine tenta apresentar o frame.
- **Causas Comuns:**
  1. Bloqueio de tela do smartphone durante a execução.
  2. Alternância para outro app ou retorno à tela inicial (Home).
  3. Desconexão temporária de cabo USB durante o processo de deploy.
- **Recomendação:** Esse evento é absorvido pela Godot na reabertura do app; caso ocorra instabilidade frequente em certos aparelhos, o projeto mantém a alternativa de compatibilidade OpenGL ES (`gl_compatibility`) documentada no canônico de portabilidade Android.

---

## ✅ Verificação e Testes
1. **Compilação e Import Headless:** `godot_console.exe --headless --import` executado com **0 erros e 0 warnings**.
2. **Suíte Automatizada:** `tests/test_multi_hit_continuous.tscn` executado em modo headless com sucesso:
   - Zero avisos de GDScript emitidos.
   - Sincronização de versão validada em `v0.12.69-alpha`.
