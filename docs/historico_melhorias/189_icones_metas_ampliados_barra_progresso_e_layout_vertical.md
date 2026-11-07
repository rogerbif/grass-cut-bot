# Melhoria 189: Ícones de Metas Ampliados em 20%, Barra de Progresso e Layout Vertical no HUD 🌿📊

**Status:** Concluído  
**Data:** 2026-11-06  
**Versão Alvo:** Game SemVer `v0.12.139-alpha` (Patch 139)  

---

## 1. Contexto e Objetivos
Com a individualização de cada cor e variedade botânica nas 40 fases e a introdução da estilização de contorno duplo tipo adesivo cartoon, buscou-se aprimorar a visibilidade e legibilidade dos objetivos no Top HUD durante a gameplay:
1. **Ampliação dos Ícones em 20%:** Aumentar a escala dos ícones de metas de 34px para 41px para destacar as espécies botânicas e seus detalhes.
2. **Desativação Temporária do Efeito de Voo do Ícone:** Desabilitar o surgimento do ícone flutuante em arco que subia até o TopBar após cada corte, mantendo o código preservado para fácil reativação no futuro.
3. **Layout Vertical dos Cards:** Mudar a disposição interna dos cards de metas de horizontal para vertical (ícone no topo, número abaixo), aproveitando com naturalidade a proporção do badge original (`badge_goal_bg.svg`, 76x72).
4. **Barra de Progresso para Metas com Mais de 100 Itens:** Exibir uma mini barra de progresso horizontal (`ProgressBar`) enchendo fluidamente abaixo do ícone para objetivos grandes ($\ge 100$ itens, como gramas), colorida com a cor temática da própria espécie.

---

## 2. Alterações Realizadas

### A. Componente do Card de Meta (`scripts/ui/hud.gd`)
- **Tamanho e Proporção:** Ajuste de `custom_minimum_size` de `Vector2(88, 52)` para `Vector2(74, 82)` com `pivot_offset = Vector2(37, 41)`.
- **Layout `VBoxContainer`:** Substituição de `HBoxContainer` por `VBoxContainer` centralizado.
- **Ícone Ampliado (+20%):** Chamada de `GoalIconFactory.build_goal_icon(plant_type, 41.0)` garantindo 41x41px de dimensão.
- **Barra de Progresso Dinâmica:** Para metas com `target >= 100`:
  - `ProgressBar` de 50x5px com cantos arredondados (3px).
  - Preenchimento reativo com a cor canônica da espécie via `PlantDatabase.get_species(plant_type).get("color")`.
  - Atualização por interpolação `Tween` em `_on_goal_updated()` preenchendo conforme `target - remaining`.
  - Fixação em 100% ao concluir (`_on_goal_completed()`).
- **Números Abaixo do Ícone:** Label com tamanho 18px e peso 900 (`SystemFont`), perfeitamente centralizado abaixo do ícone e da barra de progresso.
- **Desativação do Voo Flutuante:** Adicionado `return` preventivo no início de `_on_goal_item_collected()`.

### B. Teste Automatizado de Regressão (`tests/test_progression_and_goal_effects.gd`)
- Validação de que metas menores que 100 não instanciam barra de progresso.
- Validação de que metas $\ge 100$ possuem `ProgressBar` funcional, com `max_value = target`, inicialização em 0 e preenchimento progressivo conforme itens são ceifados.

---

## 3. Verificação
- Bateria de testes executada no Godot 4.7.2 Headless com aprovação total de 100% dos testes e 0 erros.
