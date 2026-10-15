# Melhoria 024: Calibração da Escala dos Tufos de Grama e Partículas Ampliadas com Variação Dinâmica [v0.4.7] 🌿✨

## 1. Visão Geral e Contexto
O usuário observou que o corte da grama causava a sensação de que ela "encolhia" lentamente como um balão antes de se transformar em partículas, e solicitou ajustes de proporção e impacto:
- Redução de ~15% a 20% no tamanho geral dos tufos de grama no cenário para ficarem mais compactos e proporcionais ao cortador.
- Transição de corte ágil e seca (0.04s), eliminando a fase de murchar/esvaziar.
- Aumento de 50% no tamanho das partículas de folhas cortadas (`scale_amount_min = 1.2`), com ampla variação dinâmica (`scale_amount_max = 2.4`) para mesclar aparas pequenas e folhas inteiras.

---

## 2. Implementações Técnicas

### A. Escala dos Tufos e Fatiamento Ágil (`plant.gd`)
- **Proporção Compacta no Cenário:**
  - Escala base no `_ready()` ajustada de `0.85 ~ 1.15` para `0.70 ~ 0.90` (média de 0.80m, redução de 20%).
  - Os tufos agora se assentam perfeitamente na ilha sem parecerem excessivamente altos em relação ao chassi do robô.
- **Corte Imediato:**
  - Removido o Tween lento de dois estágios que inflava a grama para `Vector3(1.3, 0.2, 1.3)` e depois encolhia para zero em 0.14s.
  - Substituído por fatiamento ágil de 0.04s (`visual_mesh.scale * Vector3(1.05, 0.05, 1.05)`), cortando o tufo instantaneamente e substituindo-o pela explosão de folhas partidas.

### B. Partículas Ampliadas com Tamanhos Variados (`CPUParticles3D`)
- **Aumento de 50% e Variação Dinâmica:**
  - `scale_amount_min`: ampliado de `0.8` para `1.2` (+50% no tamanho mínimo).
  - `scale_amount_max`: ampliado de `1.25` para `2.4` (+92% no tamanho máximo).
  - A variação de escala permite que a serra ejete simultaneamente pequenos fragmentos/aparas de grama e pontas de folhas inteiras e volumosas.
- **Atualização nas 5 Cenas de Vegetação:**
  - [`grass_tuft.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/plants/grass_tuft.tscn)
  - [`grass_green.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/plants/grass_green.tscn)
  - [`grass_yellow.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/plants/grass_yellow.tscn)
  - [`grass_blue.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/plants/grass_blue.tscn)
  - [`grass_purple.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/plants/grass_purple.tscn)

---

## 3. Validação e Qualidade
- **Zero Warnings / Zero Erros:** Verificado em execução de debug contínua via Godot MCP (`run_project` e `get_debug_output`).
- **SemVer:** Incrementado para **`v0.4.7`** em `project.godot`.
