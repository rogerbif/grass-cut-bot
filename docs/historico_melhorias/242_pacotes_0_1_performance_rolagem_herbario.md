# Melhoria 242: Pacotes 0 e 1 de Performance da Rolagem do Herbário 🌿⚡📜

**Data:** 11 de Novembro de 2026  
**Versão:** `v0.12.198-alpha` (Build Code: 1398)  
**Status:** ✅ Concluído e Auditado  
**Tipo:** Performance UI / Otimização de Layout / Cache de Estilos / Redução de Draw Calls  

---

## 🎯 1. Contexto e Motivação

Após a expansão do **Herbário da Ilha** (`TabCollection`) para 36 espécies completas, a rolagem da lista vertical apresentou engasgos de taxa de quadros e comportamento irregular de arrasto em telas sensíveis ao toque.
A análise estática do código revelou os seguintes gargalos de CPU e memória:
1. **Proliferação de instâncias de `StyleBox`:** Cada card instanciava novos objetos `StyleBoxTexture` e `StyleBoxFlat` para fundo, moldura, barra de progresso, botão de resgate e badge de bloqueio (cerca de 5 a 6 novos estilos por card, totalizando ~95 instâncias únicas ativas simultaneamente).
2. **Reconstrução total em resgate de marco:** Ao resgatar um marco, o método `_on_claim_milestone_pressed` disparava `refresh_ui()`, destruindo e reconstruindo os 36 cards do zero (levando ~173 ms e causando travamento perceptível de quadro).
3. **Conflito de rolagem e inércia duplicada:** O script tratava arrastos manuais somando deslocamento ao `scroll_vertical` ao mesmo tempo em que o `ScrollContainer` nativo realizava o seu próprio scroll, duplicando eventos quando `emulate_touch_from_mouse` estava ativo e mantendo o método `_process` rodando continuamente a cada frame.

---

## 🛠️ 2. Alterações Implementadas

### A. Pacote 0: Suíte de Medição e Linha de Base (`tests/test_herbarium_perf.gd`)
- Criado teste automatizado executável em modo headless que quantifica o custo de layout, número de nós, instâncias de `StyleBox` únicas e latências de construção/atualização com dados persistidos reais.

### B. Pacote 1: Cache Estático de Estilos (`StyleBox`)
- **Estilos Compartilhados:** Centralizados métodos auxiliares em `tab_collection.gd` que retornam instâncias estáticas cacheadas:
  - `_get_card_sb(is_disc)`: Apenas 2 instâncias (descoberta vs não descoberta).
  - `_get_icon_frame_sb()`: 1 instância única para a moldura, com a coloração da espécie migrada para `icon_panel.self_modulate`.
  - `_get_bar_bg_sb()`: 1 instância única para o fundo da barra de progresso.
  - `_get_bar_fill_sb(col)`: Cache indexado por cor da espécie (~36 instâncias estáticas).
  - `_get_claim_sb()` e `_get_badge_sb()`: 1 instância estática para botões e badges.
  - `_get_filter_sb(is_active)`: 2 instâncias estáticas para os botões de filtro ativo/inativo.

### C. Pacote 1: Resgate Cirúrgico de Card Único & Sinais Condicionais
- **`_refresh_single_card(species_key)`:** Ao resgatar um marco, apenas o card correspondente à espécie afetada é reconstruído e substituído em sua posição exata na lista (`move_child`), sem tocar nos outros 35 cards.
- **Sinal `plant_harvested` Condicional:** Se o sinal for recebido enquanto a aba está oculta (durante o gameplay), apenas marca uma flag `_dirty = true` e adia a atualização para quando a aba for reaberta via `visibility_changed`.
- **Bloqueio de Batch Claiming:** Ao clicar em "Coletar Tudo", ativa a flag `_batch_claiming` para evitar que cada marco resgatado tente reconstruir cards individualmente antes da finalização do lote.

### D. Pacote 1: Rolagem com Única Fonte de Movimento e Inércia Otimizada
- O arrasto contínuo da lista foi delegado ao comportamento nativo suave do `ScrollContainer`.
- O listener manual em `_on_scroll_gui_input` agora se restringe a medir a velocidade terminal do gesto de toque (`sd.relative.y / dt_t`).
- O `_process` é desativado por padrão (`set_process(false)`) e é ligado exclusivamente durante o período residual de amortecimento da inércia após a liberação do dedo, desligando-se assim que a velocidade cai para zero ou o scroll atinge o limite do topo/fundo.

---

## 📊 3. Resultados de Performance (Pacote 0 vs Pacote 1)

Medições obtidas via `tests/test_herbarium_perf.tscn` no mesmo ambiente:

| Métrica | Antes (Baseline) | Depois (Pacote 1) | Melhoria |
|---|---|---|---|
| **Instâncias Únicas de `StyleBox`** | 95 | **15** | **-84.2%** |
| **Tempo do 1º `refresh_cards()`** | 983.79 ms | **117.84 ms** | **8.3x mais rápido** (-88.0%) |
| **Média de `refresh_cards()` (10 execuções)** | 103.40 ms | **39.89 ms** | **2.6x mais rápido** (-61.4%) |
| **Tempo de Resgate de 1 Marco** | 173.15 ms | **5.83 ms** | **29.7x mais rápido** (-96.6%) |
| **Nós Totais da Aba** | 798 | 798 | Preservado |

---

## 🧪 4. Validação e Testes

- **`tests/test_herbarium_perf.tscn`:** Executado com sucesso, comprovando as reduções de tempo e alocação.
- **`tests/test_collection_system.tscn`:** 100% aprovado (36 espécies, 10 marcos, filtros e persistência no `SaveManager`).
- **`tests/test_manifest_sync.gd`:** 100% aprovado (sincronia dos manifestos canônicos de espécies, obstáculos e temas).
- **`tests/test_wheat_level_02.tscn` & `tests/test_all_botanical_variations.gd`:** 100% aprovados.
- **Godot Headless Import:** 0 erros e 0 warnings.
