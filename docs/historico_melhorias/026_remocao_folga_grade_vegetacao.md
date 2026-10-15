# Melhoria 026: Remoção de Folga Livre e Padronização do Gramado Contínuo [v0.4.9] 🌿📐

## 1. Visão Geral e Contexto
Após o esclarecimento de que o espaçamento anterior de $1.10\text{m}$ deixava uma folga livre visível de $0.20\text{m} \sim 0.30\text{m}$ entre as pontas das folhas de tufos adjacentes, o usuário solicitou:
- *"quero que remova a folga livre entre as folhas, coloque isso como padrão"*

O objetivo desta melhoria foi padronizar uma cobertura densa, contínua e sem espaços vazios em todo o jogo, fazendo com que as folhas vizinhas se toquem e se entrelacem perfeitamente sem chão aparente entre elas.

---

## 2. Implementações Técnicas

### A. Novo Padrão Canônico de Espaçamento de Grade (`DEFAULT_VEGETATION_SPACING = 0.80m`)
- Definida a constante `const DEFAULT_VEGETATION_SPACING: float = 0.80` em `scripts/level/level_controller.gd`.
- Todos os geradores procedurais (`_build_level_1_mvp`, `_build_level_2`, `_build_level_3`, `_build_procedural_level`) adotaram o espaçamento padrão de $0.80\text{m}$ (anteriormente $1.10\text{m}$).
- Calibrada a zona livre de spawn inicial do cortador (`pos.length() < 0.7m`), liberando os 4 pontos centrais da grade para a arrancada limpa do robô sem colisões imediatas.

### B. Calibração da Escala das Plantas no `plant.gd`
- No script base [`plant.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/plants/plant.gd), a escala do tufo de grama (`PlantType.GRASS`) foi calibrada de forma anisotrópica:
  - **Altura Compacta no Eixo Y:** `randf_range(0.70, 0.85)` — preserva o perfil baixo e proporcional ao chassi do cortador.
  - **Diâmetro Horizontal no Plano XZ:** `randf_range(0.95, 1.10)` — amplia a envergadura das folhas para $0.96\text{m} \sim 1.11\text{m}$.
- Com centros espaçados a $0.80\text{m}$ e diâmetros de folhagem $\ge 0.96\text{m}$, a soma dos raios adjacentes ($R_1 + R_2 \ge 0.96\text{m}$) excede a distância da grade ($0.80\text{m}$), garantindo sobreposição mínima de $16\text{cm}$ e eliminando completamente qualquer folga livre entre as folhas.
- Mesmo nas diagonais ($\approx 1.13\text{m}$), o alcance das folhas e a rotação aleatória $Y$ fecham os cantos, gerando a sensação de um gramado natural ininterrupto.

### C. Reposicionamento Canônico da Fase 1 (`level_01.tscn`)
- Atualizadas as posições dos 56 tufos de grama em [`level_01.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/levels/level_01.tscn) para a grade $10 \times 6$ com espaçamento $0.80\text{m}$:
  - Colunas $X$: $-3.6, -2.8, -2.0, -1.2, -0.4, 0.4, 1.2, 2.0, 2.8, 3.6$
  - Linhas $Z$: $-2.0, -1.2, -0.4, 0.4, 1.2, 2.0$
  - Centro desobstruído para spawn do robô: $(-0.4, \pm 0.4)$ e $(0.4, \pm 0.4)$.
- A contagem de 56 tufos e a meta da fase foram 100% preservadas e detectadas automaticamente pelo `base_level.gd`.

---

## 3. Arquivos Modificados
- [`scripts/level/level_controller.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/level/level_controller.gd)
- [`scripts/plants/plant.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/plants/plant.gd)
- [`scenes/levels/level_01.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/levels/level_01.tscn)
- [`docs/02_entidades_e_mecanicas/SISTEMA_DE_VEGETACAO.md`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/docs/02_entidades_e_mecanicas/SISTEMA_DE_VEGETACAO.md)
- [`docs/03_level_design_e_fases/ESTRUTURA_DAS_FASES.md`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/docs/03_level_design_e_fases/ESTRUTURA_DAS_FASES.md)
- [`docs/historico_melhorias/INDICE_MELHORIAS.md`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/docs/historico_melhorias/INDICE_MELHORIAS.md)
- [`project.godot`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/project.godot)

---

## 4. Validação e Qualidade
- **Zero Warnings / Zero Erros:** Validado em execução no Godot 4.7.1 Forward Mobile.
- **Game SemVer:** Atualizado para **`v0.4.9`** em `project.godot`.
