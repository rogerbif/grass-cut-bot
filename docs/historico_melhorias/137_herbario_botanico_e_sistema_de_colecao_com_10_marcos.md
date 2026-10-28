# Melhoria 137: Ativação do Herbário Botânico da Ilha (`TabCollection`) e Sistema de Maestria com 10 Níveis 🌿📖

## 1. Resumo Executivo
- **Solicitação do Usuário:** "Monte o plano detalhado para ativar o herbário /plan" seguido de feedback aprovando o plano com "Não precisa retrocompatibilidade de save irei apagar o save atual" e "Pode fazer uns 10 níveis de marco".
- **Objetivo:** Ativar a aba "Coleção" (`TabCollection`) do Menu Principal, criando um catálogo botânico completo com 15 espécies nativas, rastreamento cumulativo de colheitas em tempo de execução via `SaveManager`, interface dinâmica responsiva com filtros de categoria, chips de resumo de carreira e sistema progressivo de 10 níveis de marcos de maestria com resgate de moedas.
- **Resultado:**
  - **Catálogo Canônico (`PlantDatabase`):** Cadastramento completo das 15 espécies do jogo (7 gramas coloridas, trigo maduro e 7 flores/canteiros), especificando hits de resistência, moedas base, bioma/nível de introdução, cores temáticas, ícones e 10 níveis de marcos de maestria.
  - **Rastreamento Otimizado em Tempo Real no `SaveManager`:** Acúmulo em memória durante gameplay em `save_data["collection"]` com persistência segura e zero impacto na taxa de 60 FPS mobile.
  - **Integração no Gameplay (`VegetationGrid` & `Plant`):** Chamada imediata de `SaveManager.record_plant_harvest(p_key, 1)` a cada tufo físico ceifado.
  - **Interface do Herbário (`TabCollection`):**
    - Barra de progresso geral: `X / 15 Descobertas (Y%)`.
    - Chips de resumo: `🌾 Ceifados: Total` e `⭐ Marcos: X / 150`.
    - 4 filtros ágeis: `Todas (15)`, `Gramas (7)`, `Culturas (1)` e `Flores (7)`.
    - Cards dinâmicos com diferenciação nítida entre descobertas (cores, descrições, barras de marco e botão de resgate) e bloqueadas (silhueta escura, dicas de fase).
  - **10 Níveis de Marcos Progressivos:** Escalonamento balanceado por espécie com botões de resgate em verde vivo, SFX de moedas e feedback háptico.
  - **Testes Automatizados:** Teste dedicado `tests/test_collection_system.tscn` executado via Godot CLI e aprovado com 100% de sucesso.

---

## 2. Detalhes de Implementação

### A. Catálogo das 15 Espécies (`scripts/plants/plant_database.gd`)
- **Gramas (1 golpe, 1 moeda):** `grass_green` (Fase 1), `grass_yellow` (Fase 1), `grass_blue` (Fase 2), `grass_purple` (Fase 4), `grass_white` (Fase 5), `grass_red` (Fase 8), `grass_black` (Fase 12).
- **Cultura Agrícola (2 golpes, 3 moedas):** `wheat` (Fase 3).
- **Flores Nobres & Canteiros (3 golpes, 5 moedas):** `flower_daisy` (Fase 4), `flower_bell` (Fase 4), `flower_rose` (Fase 5), `flower_sunflower` (Fase 5), `flower_tulip` (Fase 9), `flower_corolla` (Fase 12), `flower_bed` (Fase 15).
- **10 Níveis de Marcos:**
  - *Gramas:* 50 (+10) ➔ 150 (+20) ➔ 350 (+35) ➔ 700 (+50) ➔ 1.200 (+75) ➔ 2.000 (+100) ➔ 3.200 (+150) ➔ 5.000 (+200) ➔ 7.500 (+300) ➔ 10.000 tufos (+500 moedas - Título Mestre).
  - *Trigo:* 15 (+15) ➔ 40 (+25) ➔ 80 (+40) ➔ 150 (+60) ➔ 250 (+90) ➔ 400 (+130) ➔ 650 (+180) ➔ 1.000 (+250) ➔ 1.500 (+350) ➔ 2.200 colheitas (+600 moedas).
  - *Flores:* 10 (+20) ➔ 25 (+35) ➔ 50 (+55) ➔ 90 (+80) ➔ 150 (+120) ➔ 240 (+170) ➔ 380 (+230) ➔ 600 (+320) ➔ 900 (+450) ➔ 1.300 colheitas (+750 moedas).

### B. Persistência em `SaveManager` (`scripts/core/save_manager.gd`)
- Adicionada estrutura `"collection"` com `"discovered"`, `"harvest_counts"` e `"claimed_milestone_levels"`.
- Métodos públicos criados:
  - `record_plant_harvest(species_key: String, amount: int = 1) -> void`
  - `is_species_discovered(species_key: String) -> bool`
  - `get_harvest_count(species_key: String) -> int`
  - `get_total_harvest_count() -> int`
  - `get_discovered_species_count() -> int`
  - `get_claimed_milestone_level(species_key: String) -> int`
  - `claim_milestone_level(species_key: String, milestone_lvl: int, coin_reward: int) -> bool`

### C. Interface do Usuário (`scenes/menu/tabs/tab_collection.tscn` & `.gd`)
- Layout vertical com ScrollContainer, cabeçalho de progresso, barra de filtros e geração dinâmica de cards.
- Remoção imediata de filhos do `cards_vbox` garantindo atualização instantânea sem artefatos de frame.
- Integração em `main_menu.gd` para disparar `refresh_ui()` ao selecionar a aba.

---

## 3. Arquivos Criados e Modificados
- `scripts/plants/plant_database.gd`: Catálogo canônico estático com as 15 espécies e 10 marcos.
- `scripts/core/save_manager.gd`: Registro cumulativo, persistência atômica e sinais do Herbário.
- `scripts/plants/vegetation_grid.gd`: Disparo de registro de colheita no corte físico de tufos.
- `scripts/plants/plant.gd`: Disparo de registro de colheita em instâncias manuais.
- `scenes/menu/tabs/tab_collection.tscn`: Estrutura de cena do Herbário no Menu Principal.
- `scripts/menu/tabs/tab_collection.gd`: Lógica completa de UI, filtros e resgate de marcos.
- `scripts/menu/main_menu.gd`: Chamada de atualização de UI na troca para a aba Coleção.
- `tests/test_collection_system.gd` & `.tscn`: Suíte de testes automatizados completa.
- `docs/04_sistemas_e_gameplay/ECONOMIA_E_OFICINA.md`: Documentação canônica atualizada.

---

## 4. Testes e Validação
- **Testes Automatizados Executados:**
  - `tests/test_collection_system.tscn`: 100% aprovado (PlantDatabase, SaveManager, persistência e UI).
  - `tests/test_save_manager.tscn`: 100% aprovado (regressão zero nos sistemas de save e estrelas).
  - `tests/test_blade_pop_and_slash.tscn`: 100% aprovado (regressão zero nos efeitos do Cutter).
