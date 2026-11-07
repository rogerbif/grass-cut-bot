# Histórico de Melhorias: 198. Calibração da Tipografia de Metas (16px) e Contorno Duplo Externo Puro nos Ícones de Objetivos 🌿🎨

**Data:** 07 de Novembro de 2026  
**Versão:** `v0.12.148-alpha`  
**Escopo:** `MapLevelCard` (Card de Fase), Top HUD de Gameplay (`HUD`), `DefeatModal` e Fábrica de Ícones Botânicos (`GoalIconFactory`).  

---

## 1. Contexto e Motivação

1. **Desproporção Tipográfica nos Contadores de Metas:** No `MapLevelCard`, os números de quantidade dos objetivos eram exibidos em 21px (`amount_lbl`), criando um contraste excessivo contra a legenda inferior `"Objetivos:"` (16px). O mesmo acontecia no Top HUD de gameplay (`18px`), carecendo de alinhamento e consistência visual.
2. **Artefatos e Linhas Internas no Contorno dos Ícones:** O contorno duplo (1px preto + 2px branco) vinha sendo aplicado de forma individual por camada em `GoalIconFactory._add_layer()`. Isso provocava três anomalias visuais graves:
   - A camada de lâminas de grama (`illus_grass_blades.svg`) desenhava um traço branco/preto na sua borda inferior transparente, cortando horizontalmente o solo verde/marrom da base.
   - A camada de base (`illus_grass_base.svg`) desenhava um traço de contorno ao longo do seu topo e ao redor de halos difusos (radial glow e drop shadow).
   - Entre as lâminas de grama e pétalas de flor, frestas transparentes eram preenchidas com linhas pretas e brancas no interior do tufo, quebrando o aspecto limpo de adesivo.

A solicitação do usuário exigiu:
> *"Reduza o tamanho da fonte dos números do objetivo para o mesmo tamanho da de baixo, aplique para objetivo do jogo também. A borda do icone do objetivo quando pedi para ser branca é somente o contorno externo do icone corrija, borda preta e a branca"*

---

## 2. Implementações Técnicas

### 2.1 Calibração Tipográfica em 16px (MapLevelCard, HUD e DefeatModal)
- Em [`scripts/ui/map_level_card.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/ui/map_level_card.gd), alteramos o tamanho da fonte de `amount_lbl` de `21px` para `16px`, igualando rigorosamente à legenda `"Objetivos:"` (`obj_caption`).
- Em [`scripts/ui/hud.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/ui/hud.gd), alteramos o tamanho da fonte de `count_lbl` de `18px` para `16px`.
- Em [`scripts/ui/defeat_modal.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/ui/defeat_modal.gd), alinhamos também os rótulos de metas pendentes de `18px` para `16px`, estabelecendo consistência absoluta em toda a UI.

### 2.2 Arquitetura de Contorno Externo Puro (`GoalIconFactory`)
- **Separação Rígida entre Arte Visível e Contorno:**
  - As camadas visíveis da ilustração (Base do solo + Lâminas de grama moduladas com a cor da variedade; ou Caules + Pétalas da flor) agora são instanciadas **100% limpas**, sem nenhum `ShaderMaterial` ou pós-processamento interno.
  - O contorno duplo (1px preto + 2px branco) é gerado exclusivamente por uma camada subjacente dedicada (`OutlineRect`), com `show_behind_parent = true` e `z_index = -1`, renderizada atrás da arte limpa.
- **Silhueta Unificada Sem Halos ou Cavidades Internas:**
  - Implementada a rotina de cache estático `_get_composite_silhouette(plant_type, cat)`:
    1. **Purificação da Base:** Pixels de halos difusos (glow radial translúcido a 28% de opacidade e sombras) com $\alpha < 0.60$ são eliminados, retendo apenas a geometria rígida e sólida do bloco de solo e grama.
    2. **Fusão Atômica de Camadas:** As lâminas/pétalas são mescladas diretamente sobre a base via `img.blend_rect()`, eliminando qualquer fresta ou descontinuidade entre o pé das folhas e o topo do solo.
    3. **Detecção Polar de Bordas via Flood Fill:** Algoritmo BFS a partir das 4 extremidades da imagem ($x=0$, $x=W-1$, $y=0$, $y=H-1$) mapeia todo o espaço verdadeiramente externo.
    4. **Fechamento de Cavidades Internas:** Qualquer pixel enclausurado no interior do tufo que não foi alcançado pelo flood fill tem sua opacidade consolidada ($\alpha = 1.0$).
- **Resultado:**
  - O shader `OUTLINE_SHADER` opera na silhueta consolidada e só atua nos pixels onde $\alpha \le 0.12$ na vizinhança externa da silhueta unificada.
  - **Zero** linhas ou pontos brancos/pretos no interior das folhas ou solo.
  - Contorno sticker contínuo, limpo e profissional contornando exclusivamente o perfil externo da planta.

---

## 3. Validação e Testes
- `tests/test_progression_and_goal_effects.gd`: executado com 100% de aprovação (validação do contorno duplo, modulações de cores canônicas de grama e integridade do HUD).
- `tests/test_blade_progression.tscn`: executado com 100% de aprovação em todos os 10 níveis da lâmina.
- Testes headless rodados com 0 warnings e 0 erros.

---

## 4. Arquivos Modificados

| Arquivo | Descrição das Modificações |
| :--- | :--- |
| [`scripts/ui/map_level_card.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/ui/map_level_card.gd) | `amount_lbl` calibrado de 21px para 16px. |
| [`scripts/ui/hud.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/ui/hud.gd) | `count_lbl` no Top HUD calibrado de 18px para 16px. |
| [`scripts/ui/defeat_modal.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/ui/defeat_modal.gd) | Labels de metas no modal de derrota calibrados para 16px. |
| [`scripts/ui/goal_icon_factory.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/ui/goal_icon_factory.gd) | Silhueta unificada sem glow, preenchimento de cavidades internas e `OutlineRect` subjacente limpo. |
| [`project.godot`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/project.godot) | Versão bump para `0.12.148-alpha`. |
| [`scripts/core/game_version.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/core/game_version.gd) | `PATCH` incrementado para `148`. |
| [`export_presets.cfg`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/export_presets.cfg) | Preset Android atualizado para `0.12.148-alpha` (code `1348`). |
| [`docs/04_sistemas_e_gameplay/SISTEMA_DE_INTERFACE_HUD.md`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/docs/04_sistemas_e_gameplay/SISTEMA_DE_INTERFACE_HUD.md) | Documentação de metas e silhueta subjacente atualizada. |
| [`docs/historico_melhorias/INDICE_MELHORIAS.md`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/docs/historico_melhorias/INDICE_MELHORIAS.md) | Registro canônico da melhoria 198. |
