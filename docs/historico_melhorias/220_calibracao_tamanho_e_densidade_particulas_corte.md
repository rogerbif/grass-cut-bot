# Histórico de Melhoria: Calibração de Tamanho (+25%) e Densidade (-20%) das Partículas de Corte 🌿✨

**Data:** 10 de Novembro de 2026  
**Versão:** `v0.12.172-alpha`  
**Autor:** Antigravity (Google DeepMind)  
**Status:** Concluído ✅  

---

## 1. Contexto e Motivação
Após a reestruturação da geometria das aparas de corte para folhas picadas dobradas no plano horizontal (Melhoria 218), o usuário solicitou um ajuste fino na leitura visual e equilíbrio do jogo:
- **Redução da quantidade de partículas em ~20%:** Evitar excesso de elementos visuais simultâneos na tela ao ceifar grandes áreas de grama densa.
- **Aumento do tamanho das partículas em 25%:** Destacar as aparas e pétalas soltas no ar de forma mais legível na perspectiva isométrica mobile.

---

## 2. Alterações Realizadas

### A. Redução na Quantidade de Emissão (-20%)
No script `scripts/plants/plant.gd`:
- **Grama e Trigo (`spawn_grass_cut_particles`):**
  - Aparas de corpo (`_grass_blade_mesh`): reduzido de `10` para `8` partículas por burst (-20%).
  - Pontas afiladas (`_grass_blade_tip_mesh`): reduzido de `8` para `6` partículas por burst (-25%).
  - Total por corte: de 18 para 14 partículas (-22%).
- **Flores (`spawn_flower_cut_particles`):**
  - Círculos de pétalas: reduzido de `8` para `6` (-25%).
  - Miolo: reduzido de `4` para `3` (-25%).
  - Fragmentos de caule e folhas: reduzido de `3` para `2` cada (-33%).
- **Hits Intermediários (`spawn_flower_petal_burst`):**
  - Círculos de pétalas: reduzido de `6` para `5`.

### B. Aumento no Tamanho das Partículas (+25%)
No pool de partículas `_init_particle_pool()` em `scripts/plants/plant.gd`:
- `scale_amount_min`: ajustado de `0.85` para `1.06` ($0.85 \times 1.25 = 1.0625$, ampliação de +25%).
- `scale_amount_max`: ajustado de `1.15` para `1.44` ($1.15 \times 1.25 = 1.4375$, ampliação de +25%).
- `p.amount`: ajustado de `10` para `8` partículas base.

---

## 3. Validação e Testes
- **Visual In-Game:** Testado via script de captura executando a cena principal de gameplay no corte de grama e flores coloridas (`test_particles_calibrated_size_count.png`).
- **Performance e Zero Warnings (Mandamento 1):** Godot 4.7.2 headless executado com 0 warnings e 0 erros.
- **Leitura Mobile:** As partículas voam com clareza sem poluir a visão do robô, mantendo rotação orgânica e caindo deitadas.

---

## 4. Arquivos Modificados
- `scripts/plants/plant.gd`
- `scripts/core/game_version.gd`
- `project.godot`
- `export_presets.cfg`
- `docs/02_entidades_e_mecanicas/SISTEMA_DE_VEGETACAO.md`
- `docs/historico_melhorias/INDICE_MELHORIAS.md`
- `docs/historico_melhorias/220_calibracao_tamanho_e_densidade_particulas_corte.md`
