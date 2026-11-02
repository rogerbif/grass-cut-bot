# Registro de Melhoria: Equalização Cromática Canônica (Opção 3) 🌿🎨

- **Data:** 02/11/2026
- **Versão:** `v0.12.95-alpha`
- **Autor:** Antigravity AI & Roger Bif
- **Status:** Concluído e Validado

---

## 1. Contexto & Motivação
Nas versões anteriores, observou-se variação perceptível nas cores da grama, ilha e trigo entre a tela de Menu e o Gameplay, além de pequenas inconsistências de atenuação luminosa entre renderizadores (Mobile Vulkan e Web gl_compatibility). O usuário solicitou uma análise visual comparativa de 3 opções e aprovou a **Opção 3 (Direita)** para ser fixada como Fonte Única da Verdade (Single Source of Truth) em todo o projeto.

---

## 2. Paleta Canônica Homologada (Opção 3)

| Elemento | Código HEX | RGB Linear | Aplicação Técnica |
| :--- | :--- | :--- | :--- |
| **Grama Verde** | `#99EA3F` | `Color(0.600, 0.918, 0.247)` | `interactive_grass_material.tres`, `island_mesh_builder.gd`, `island_node.tscn` |
| **Trigo / Grama Dourada** | `#F0D92F` | `Color(0.941, 0.851, 0.184)` | `interactive_wheat_material.tres`, `interactive_grass_yellow_material.tres` |
| **Falésia da Ilha** | `#F1AB65` | `Color(0.945, 0.671, 0.396)` | Paredes da ilha em `island_mesh_builder.gd` e `island_node.tscn` |
| **Ambiente & Céu** | `#8CD1F0` / `#E0F0EB` | Céu `(0.55, 0.82, 0.94)`, Amb `0.85` | Recurso compartilhado `assets/environments/shared_environment.tres` |

---

## 3. Principais Alterações Implementadas

1. **Unificação do Ambiente (`assets/environments/shared_environment.tres`):**
   - Recurso único de `Environment` com tonemapper ACES, céu tropical suave e luz ambiente uniforme (energia 0.85).
   - Aplicado tanto em `scenes/main.tscn` quanto em `scenes/menu/main_menu.tscn`.
2. **Harmonização da Ilha:**
   - `scripts/level/island_mesh_builder.gd`: `ground_base_color` atualizado para `#99EA3F` com brilho 1.0; falésias atualizadas para `#F1AB65`.
   - `scenes/menu/island_node.tscn`: Materiais do chão e falésia atualizados para coincidir perfeitamente com a malha do gameplay.
3. **Calibração dos Shaders de Vegetação:**
   - `shaders/interactive_grass_material.tres`: Atualizado para gradiente com topo em `#99EA3F`.
   - `shaders/interactive_wheat_material.tres` e `shaders/interactive_grass_yellow_material.tres`: Atualizados com topo em `#F0D92F`.
   - `scripts/plants/vegetation_grid.gd`: Partículas e aparas aparadas sincronizadas com a nova paleta.

---

## 4. Validação
- **Headless check:** 0 warnings, 0 erros no carregamento dos recursos.
- **Transição Menu ⇄ Gameplay:** 100% contínua e sem saltos cromáticos.
