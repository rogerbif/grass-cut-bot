# Histórico de Melhoria: Sincronização das Fases 03-20 com a Fase 02 e Aumento de 50% nas Folhas do Tufo 🌿🌾✂️

**ID:** `076_sincronizacao_fases_e_aumento_folhas_tufo`  
**Versão:** `v0.11.5-alpha`  
**Data:** 22/10/2026  
**Status:** Concluído e Validado (0 Warnings no Godot 4.7.1)  

---

## 1. Contexto e Objetivos

O usuário solicitou duas intervenções de escopo complementar:
1. **Padronização e Limpeza de Fases:** Limpar todas as fases da Fase 03 em diante (Fases 03 a 20) e replicar exatamente a estrutura, terreno, objetos e vegetação da Fase 02, servindo de base limpa uniforme para reedição manual no Editor de Fases.
2. **Densidade e Volume Foliar (+50%):** Aumentar em 50% a quantidade de folhas em cada tufo de vegetação 3D (`grass_01.glb`), elevando o volume estético e a exuberância do gramado sem prejudicar a taxa de 60 FPS no mobile.

---

## 2. Implementações Realizadas

### A. Sincronização Integral das Fases 03 a 20 (`data/levels/`)
- A partir de [`data/levels/level_02.json`](../../data/levels/level_02.json), foram sobrescritos todos os arquivos de fases `level_03.json` até `level_20.json`:
  - Grade unificada de $17 \times 17$ com 285 blocos de solo 3D e falésias automáticas.
  - 4 rochas periféricas e 4 estrelas de trigo maduro (`wheat`) com anel central de grama verde (`grass_green`).
  - IDs e nomes atualizados individualmente para cada fase (`level_id: X`, `name: "Fase XX"`).
  - Preservado o limite de tempo ($85\text{s}$) e formato canônico JSON v3.

### B. Aumento de 50% na Geometria das Folhas (`assets/models/grass_01.glb`)
- No Blender 5.2.1 headless:
  - O tufo base original possuía **14 folhas** (98 vértices e 70 faces).
  - Foi aplicado um aumento exato de **+50%**, expandindo a contagem para **21 folhas** (147 vértices e 105 faces).
  - As 7 novas folhas foram distribuídas radialmente nos setores menos densos (quadrantes vazios em torno de 70°, 95°, -5°, 12°, -96°, -175° e centro), gerando uma silhueta cilíndrica uniforme e densa.
  - Cada folha nova recebeu atributos de vértice assados na camada `Color` (`COLOR.r` para fase individual, `COLOR.g` para orientação azimutal normalizada e `COLOR.b` para frequência própria), garantindo balanço pendular independente no `interactive_grass.gdshader`.
  - Exportação glTF com `export_apply=True`, `export_yup=True` e `export_attributes=True`.
  - Reimportação atômica executada pelo editor Godot, gerando o cache `.scn` de 6.088 bytes em `.godot/imported/`.

### C. Ajuste do Pool de Partículas de Corte (`scripts/plants/plant.gd`)
- Em [`scripts/plants/plant.gd`](../../scripts/plants/plant.gd):
  - A quantidade de partículas de corte emitidas por tufo (`p.amount`) foi ajustada de 14 para 21 (`+50%`), mantendo paridade visual perfeita entre o volume de folhas cortadas e as folhas ejetadas no ar.

---

## 3. Validação Técnica (0 Warnings / 0 Erros)

- **Godot 4.7.1 Debug Runner (MCP):**
  - Execução de `scenes/editor/level_editor.tscn`: **0 warnings e 0 erros**.
  - Execução de `scenes/main.tscn`: **0 warnings e 0 erros**.
  - O gramado e as folhas de trigo apresentam densidade visivelmente superior, toque mais farto e balanço independente fluido na GPU.
  - Todas as fases de 03 a 20 carregam perfeitamente o layout template da Fase 02.
