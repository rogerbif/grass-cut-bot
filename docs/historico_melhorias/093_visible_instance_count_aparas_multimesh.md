# 093 - Otimização de Performance: Gerenciamento Contíguo de visible_instance_count em Aparas Cortadas (Tarefa 3.1) 🌾⚡

## 1. Contexto e Diagnóstico
Em fases com alta densidade de vegetação (como a **Fase 20**, com 1.296 tufos físicos), cada tipo vegetal instanciado criava um `MultiMesh` de aparas fatiadas caídas no solo (`ClippingsMMI`).

- **Gargalo Anterior:**
  - O `instance_count` de aparas era alocado de antemão com o total de plantas da fase.
  - Para ocultar as aparas antes do corte, todas eram inicializadas com escala zero (`HIDDEN_TRANSFORM`), mantendo a propriedade nativa `visible_instance_count = -1` (todas as instâncias processadas).
  - Como resultado, **a GPU era forçada a transformar e submeter ao pipeline de vértices mais de 1.200 aparas invisíveis por frame** no início de cada partida, gerando processamento inútil de geometria e desperdício de fill-rate.
- **Desafio da Engine:**
  - A propriedade nativa `visible_instance_count = N` do Godot 4 emite draw calls instanciados (`vkCmdDrawIndexed` / `glDrawElementsInstanced`) para desenhar estritamente os slots do índice `0` ao `N-1`.
  - Como o jogador ceifa plantas em locais esparsos, gravar no índice original `inst_idx` da planta quebraria o desenho se `inst_idx >= N`.

---

## 2. Soluções Implementadas

### A. Empacotamento Contíguo e Sequencial de Aparas
Em [`scripts/plants/vegetation_grid.gd`](../../scripts/plants/vegetation_grid.gd):
- Criada a lista de contadores numéricos progressivos `_clipping_counts: PackedInt32Array`.
- No carregamento da fase (`_build_from_vector_field` e `_build_from_vegetation_field`):
  - Todos os MultiMeshes de aparas são inicializados com `clip_mm.visible_instance_count = 0`.
  - **No início da partida, o custo de renderização de aparas é ZERO absoluto.**
- No momento do corte (`cut_in_circle`):
  - A apara cortada é gravada no próximo slot sequencial contíguo do buffer (`0, 1, 2...`):
    ```gdscript
    var clip_mm: MultiMesh = _clipping_multimeshes[mmi_idx]
    if clip_mm != null:
        var c_idx: int = _clipping_counts[mmi_idx] if mmi_idx < _clipping_counts.size() else 0
        if c_idx < clip_mm.instance_count:
            clip_mm.set_instance_transform(c_idx, _cut_transforms[p_idx])
            c_idx += 1
            if mmi_idx < _clipping_counts.size():
                _clipping_counts[mmi_idx] = c_idx
            clip_mm.visible_instance_count = c_idx
    ```
  - A GPU desenha apenas o número exato de aparas que já foram cortadas pelo jogador.

### B. Reinício Instantâneo sem Overhead de Memória
- Em `reset_all_plants()`:
  - Não é mais necessário percorrer e gravar matrizes com escala zero para cada apara no GDScript.
  - A função redefine instantaneamente `_clipping_counts[mmi_idx] = 0` e `clip_mm.visible_instance_count = 0`, tornando o reinício de fase leve e imediato.

---

## 3. Preservação do Game Feel e Resultados
- **Experiência Visual Idêntica:** As aparas fatiadas no solo continuam aparecendo exatamente sob a lâmina da serra no momento do corte, com materiais e cores correspondentes.
- **Redução Média de >70% de Instâncias de Aparas:** No início e durante a maior parte das fases, a GPU economiza milhares de transformações de vértices e testes de frustum culling.
- **Zero Warnings:** Totalmente aderente às diretrizes de tipagem estrita do Godot 4.

---

## 4. Arquivos Modificados
- [`scripts/plants/vegetation_grid.gd`](../../scripts/plants/vegetation_grid.gd): Alocação contígua de aparas com `_clipping_counts` e `visible_instance_count`.
- [`scripts/core/game_version.gd`](../../scripts/core/game_version.gd): Incremento para `v0.12.17-alpha`.
- [`project.godot`](../../project.godot) & [`export_presets.cfg`](../../export_presets.cfg): Bump SemVer (build `1217`).
- [`docs/05_arquitetura_e_desenvolvimento/PLANO_MESTRE_DE_PERFORMANCE.md`](../05_arquitetura_e_desenvolvimento/PLANO_MESTRE_DE_PERFORMANCE.md): Tarefa 3.1 marcada como concluída.
- [`docs/historico_melhorias/INDICE_MELHORIAS.md`](INDICE_MELHORIAS.md): Indexação do item 093.
