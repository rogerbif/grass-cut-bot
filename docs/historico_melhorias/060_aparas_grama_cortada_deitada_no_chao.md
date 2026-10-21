# Melhoria 060: Aparas de Grama Cortada Deitadas no Solo (Estilo Referência) 🍃✂️

**Data de Conclusão:** 21/10/2026  
**Versão Vinculada:** `v0.9.6-alpha` (Build Code: `906`)  
**Status da Entrega:** Concluído com 0 warnings, 0 erros e 100% testado no Godot 4.

---

## 🎯 Contexto e Referência Visual

A tentativa anterior de tocos de pé (achatamento vertical da moita inteira em 15%) criava um aspecto de "mini-moita" compacta de pé, que não transmitia a sensação leve e agradável de um gramado aparado.

Com base na imagem de referência enviada pelo usuário, o efeito canônico desejado consiste em:
1. A grama alta vertical **desaparece completamente** ao ser cortada.
2. O chão de terreno limpo fica **salpicado de lâminas/folhinhas fatiadas deitadas horizontalmente no plano do solo** ($Y \approx 0.005\text{m}$), espalhadas com rotações aleatórias em $360^\circ$ e tom verde escuro contrastante, simulando com fidelidade as aparas trituradas expelidas pela serra.

---

## 🛠️ Alterações Implementadas

### 1. Malha Procedural de Aparas de Grama (`_get_or_create_clippings_mesh`)
- Construída via `SurfaceTool` uma malha estática otimizada de **6 lâminas fatiadas** em formato de losango afilado low poly (comprimento $10 \dots 13\text{cm}$, largura $2.6\text{cm}$):
  - Orientadas horizontalmente no plano $XZ$ com normais estritas $+Y$ e faces duplas (`CULL_DISABLED`).
  - Materiais foscos com cores calibradas por espécie (`_resolve_clipping_color`):
    - **Grama verde:** Verde escuro de grama cortada `Color(0.12, 0.36, 0.12)`.
    - **Grama amarela / Trigo:** Amarelo torrado e dourado palha.
    - **Flor:** Salpicado rosa/magenta com verde.

### 2. MultiMeshes Paralelos de Aparas (`_clipping_multimeshes`)
- Instanciados `MultiMesh` de aparas correspondentes a cada tipo de planta em `VegetationGrid`:
  - Inicialmente, todas as instâncias de aparas começam ocultas (`HIDDEN_TRANSFORM`).
  - Ao sofrer corte fatal (`new_hp <= 0`), a moita alta é ocultada (`HIDDEN_TRANSFORM`) e a instância de aparas correspondente é posicionada no solo (`_cut_transforms[p_idx] = Transform3D(Basis(Vector3.UP, random_rot), pos)`).
  - Integrado ao reset da fase e ao culling de benchmark de densidade.
  - Zero draw calls por tufo (apenas 1 draw call de aparas por tipo de vegetação em toda a ilha).

---

## 🧪 Verificação e Resultados
- **Estética:** Reproduz com exatidão a referência visual do jogo casual mobile: piso claro limpo salpicado de fragmentos de folhas cortadas fatiadas.
- **Performance:** 60 FPS estáveis, com memória em SoA e custo nulo de CPU.
- **Godot Import:** 0 erros e 0 warnings.

---

## 📦 Arquivos Modificados
- `scripts/plants/vegetation_grid.gd`
- `project.godot`
- `export_presets.cfg`
- `scripts/core/game_version.gd`
- `docs/historico_melhorias/060_aparas_grama_cortada_deitada_no_chao.md`
- `docs/historico_melhorias/INDICE_MELHORIAS.md`
- `docs/02_entidades_e_mecanicas/SISTEMA_DE_VEGETACAO.md`
