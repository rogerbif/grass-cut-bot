# Relatório de Melhoria: Ícones de Objetivo da Coleção, Alinhamento Superior e Simetria no HUD

**Versão:** `v0.12.110-alpha`  
**Data:** 04/11/2026  
**Status:** Concluído com Sucesso

---

## 🎯 Objetivos Realizados

1. **Ícones de Objetivo Fiéis à Coleção:**
   - Substituição completa do antigo ícone de trigo (que exibia um celeiro vermelho com portão em X) e folhas genéricas pelos vetores botânicos canônicos de alta fidelidade da tela de Coleção.
   - **Trigo Dourado:** Renderiza `res://assets/ui/collection/illus_wheat_bundle.svg` (espigas fartas douradas).
   - **Gramas Canônicas:** Composição da base de solo isométrica (`res://assets/ui/collection/illus_grass_base.svg`) sobreposta pelas lâminas botânicas (`res://assets/ui/collection/illus_grass_blades.svg`), com coloração dinâmica (`modulate`) extraída diretamente de `PlantDatabaseScript.get_species(plant_type)["color"]` (Grama Esmeralda, Dourada Solar, Azul Costeira, etc.).
   - **Flores:** Composição em camadas de hastes (`illus_flower_stems.svg`) e pétalas (`illus_flower_petals.svg`) com a tonalidade oficial de cada espécie.

2. **Alinhamento Superior Idêntico à Home:**
   - Ajuste em `scenes/ui/hud.tscn` no `StyleBoxFlat_top`: alteração de `content_margin_top` de `48.0px` para `16.0px`, fazendo com que o TopBar do HUD inicie exatamente no mesmo offset Y superior do TopBar da Home (`margin_top = 16`).

3. **Simetria Rigorosa de Altura (52px):**
   - Padronização da altura de todos os badges e cartões da TopBar de gameplay para `52px`:
     - `TimerContainer`: `custom_minimum_size = Vector2(110, 52)`
     - `CoinsContainer`: `custom_minimum_size = Vector2(110, 52)`
     - `PauseButton`: `custom_minimum_size = Vector2(58, 52)`
     - `GoalCards`: `custom_minimum_size = Vector2(88, 52)` com margens internas e vitrine de ilustração `34x34`.

4. **Equalização Tipográfica (23px):**
   - Aumento da fonte de `18px` para `23px` com `SystemFont_bold` (peso 900) no `TimerLabel`, `CoinsLabel` e no contador de metas restantes de cada Goal Card (`count_lbl`).

---

## 📂 Arquivos Modificados

- `scenes/ui/hud.tscn`: Margem superior reduzida para `16.0px`, dimensões de `TimerContainer` e `CoinsContainer` ajustadas para altura `52px`, fontes aumentadas para `23px`.
- `scripts/ui/hud.gd`: Integração com `PlantDatabaseScript`, carregamento dos vetores da Coleção, criação dos cards de objetivos com 52px de altura, vitrine botânica dinâmica e contadores em 23px.
- `project.godot` e `scripts/core/game_version.gd`: Incremento de versão para `0.12.110-alpha`.
