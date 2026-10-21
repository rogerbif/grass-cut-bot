# Melhoria 058: Efeito Visual de Grama Cortada no Chão (Tocos 3D Aparados / Stubble) 🌾✂️

**Data de Conclusão:** 21/10/2026  
**Versão Vinculada:** `v0.9.4-alpha` (Build Code: `904`)  
**Status da Entrega:** Concluído com 0 warnings, 0 erros e 100% testado no Godot 4.

---

## 🎯 Contexto e Objetivo

Anteriormente, quando um tufo de vegetação era cortado pela serra do robô, a instância no `MultiMesh` era ocultada para longe (`y = -9999.0` e `scale = 0.0`), deixando apenas o terreno liso por baixo. Embora funcional, o chão parecia "vazio", sem a sensação tátil e satisfatória de um gramado recém-aparado.

O objetivo desta melhoria foi implementar a **Opção 1 (Mini-Restolho / Tocos 3D Aparados)**: ao cortar a grama alta, manter a instância com altura reduzida (~4.5 cm de altura) e leve espalhamento lateral, simulando as bases e lâminas aparadas rente ao solo com **custo zero de draw calls extras**.

---

## 🛠️ Alterações Implementadas

### 1. Sistema de Tocos Aparados em SoA (`scripts/plants/vegetation_grid.gd`)
- Adicionado array de transforms pré-calculados `var _cut_transforms: Array[Transform3D] = []`.
- Implementada a função de cálculo proporcional `_compute_stub_transform(init_xform: Transform3D, v_type: String) -> Transform3D`:
  - **Grama (todas as cores):** Escala vertical $Y \times 0.15$ (~4.5 cm de altura) e expansão lateral $XZ \times 1.08$, criando toquinhos densos de grama aparada.
  - **Trigo (`wheat`):** Escala vertical $Y \times 0.16$ e $XZ \times 1.05$, gerando o visual característico de palha/restolho de trigo ceifado.
  - **Flor (`flower`):** Escala vertical $Y \times 0.10$ e $XZ \times 1.15$, deixando pétalas fatiadas e caule cortado rentes ao solo.
- No método de corte `cut_in_circle()`, ao atingir `new_hp <= 0`, a instância do `MultiMesh` transiciona imediatamente para `_cut_transforms[p_idx]`, sincronizada com a explosão de partículas em arco e a vibração háptica.
- Integrado ao sistema de reset e benchmark de densidade (`set_benchmark_visibility` e `reset_all_plants`).

---

## 🧪 Verificação e Resultados
- **Performance:** Zero draw calls a mais, zero vértices a mais e sem nós adicionais na árvore da cena. 60 FPS cravados no mobile.
- **Game Feel:** O caminho percorrido pelo cortador fica claramente demarcado no chão como um gramado recém-cortado, aumentando dramaticamente a sensação satisfatória de progresso e limpeza.
- **Testes Headless:** Executado teste automatizado de corte e recarga com exit code 0 e 0 warnings.

---

## 📦 Arquivos Modificados
- `scripts/plants/vegetation_grid.gd`
- `project.godot`
- `export_presets.cfg`
- `scripts/core/game_version.gd`
- `docs/historico_melhorias/058_efeito_grama_cortada_tocos_aparados.md`
- `docs/historico_melhorias/INDICE_MELHORIAS.md`
- `docs/02_entidades_e_mecanicas/SISTEMA_DE_VEGETACAO.md`
- `docs/04_sistemas_e_gameplay/GAME_FEEL_E_HAPTICS.md`
