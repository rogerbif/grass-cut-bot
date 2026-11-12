# Histórico de Melhoria: Pacotes 2 e 3 de Performance do Herbário (Ícones Pré-Assados e Cards Reaproveitáveis)

**Versão:** `v0.12.199-alpha`  
**Data:** 11/11/2026  
**Tipo:** Performance, Otimização de GPU/CPU, Arquitetura UI  
**Autor:** Antigravity (Google DeepMind Pair Programming)

---

## 🎯 Objetivo

Implementar os **Pacotes 2 e 3** do plano de otimização de performance do Herbário da Ilha:
1. **Pacote 2 (Ícones Pré-Assados):** Eliminar o custo de shaders dinâmicos multi-pass na GPU durante a rolagem e abertura de telas, pré-assando em CPU a silhueta, as bordas tipo sticker (1px preto + 2px branco via algoritmo de dilatação) e as camadas de cores em um único `ImageTexture` de $128 \times 128$ por espécie. Cada ícone construído por `GoalIconFactory.build_goal_icon()` agora é um único `TextureRect`, economizando nós na árvore de cena e desonerando o rasterizador mobile.
2. **Pacote 3 (Reaproveitamento de Cards):** Eliminar o custo de destruição e recriação dos 36 cards do catálogo botânico. Os cards passam a ser instanciados uma única vez na inicialização da aba e mantidos em um dicionário em memória (`_cards_by_key`). A alternância entre filtros botânicos (*Todas*, *Gramas*, *Trigo*, *Flores*, *Resgatar*) passa a ocorrer via `card.visible = true / false` de forma quase instantânea (< 2.8 ms), e atualizações de dados acontecem em-place (`_update_card_view`) sem desmontar a hierarquia da UI.

---

## 🔍 Diagnóstico e Análise Técnica

### Gargalos Anteriores
1. **Sobrecarga de Nós e Passes de Fragment Shader por Ícone:**
   - Anteriormente, cada ícone gerado por `GoalIconFactory.build_goal_icon` continha um container com até 3 camadas de nós (`Control` base, lâminas/pétalas coloridas e uma camada inferior `OutlineRect` executando o shader `goal_icon_outline.gdshader` em tempo real a cada frame visível na GPU).
   - Com 36 cards no catálogo do Herbário, havia centenas de nós e 36 passes simultâneos de fragment shader amostrando os 8 vizinhos com offsets UV a cada quadro na GPU móvel.
2. **Destruição e Reconstrução Contínua de Cards:**
   - A cada clique em um botão de filtro (*Gramas*, *Flores*, etc.) ou chamada de `refresh_cards()`, todos os filhos de `cards_vbox` eram removidos e destruídos via `queue_free()`, e 36 novos cards completos eram instanciados e configurados do zero.
   - Isso gerava picos de alocação de memória, engasgos na rolagem e atrasos perceptíveis para o jogador.

---

## 🛠️ Implementação Realizada

### 1. Pacote 2: Pré-Assamento de Ícones em `GoalIconFactory` (`scripts/ui/goal_icon_factory.gd`)
- **Silhueta Composta & Dilatação em CPU:**
  - `_bake_category_outline(cat: String) -> Image`: Gera uma textura de máscara com borda preta interna de 1.2px e contorno branco externo de 3.6px via campo de distâncias ortogonal/diagonal. Como as silhuetas geométricas dependem exclusivamente da categoria (`grass`, `crop`, `flower`), o contorno é gerado uma única vez por categoria e mantido em cache (`_category_outline_cache`).
- **Composição Cromática Atômica:**
  - `get_baked_icon_texture(plant_type: String, with_outline: bool = true) -> Texture2D`: Mescla a máscara de contorno pré-assada com a textura base e a camada foliar/pétalas multiplicada pela cor temática canônica da espécie (`PackedByteArray` RGBA8 com C++ `blend_rect()`). O resultado é encapsulado em um `ImageTexture` imutável de $128 \times 128$ cacheado em `_baked_icon_cache[cache_key]`.
- **Nó Único no Retorno de `build_goal_icon`:**
  - `GoalIconFactory.build_goal_icon()` agora instancia diretamente um único `TextureRect` configurado com `expand_mode = EXPAND_IGNORE_SIZE`, `stretch_mode = STRETCH_KEEP_ASPECT_CENTERED` e a textura pré-assada. Elimina 72 nós no Herbário e 100% dos shaders de contorno na GPU.

### 2. Pacote 3: Cards Reaproveitáveis em `TabCollection` (`scripts/menu/tabs/tab_collection.gd`)
- **Instanciação Única e Cache Indexado:**
  - Adicionadas as variáveis `_cards_by_key: Dictionary = {}` e `_cards_built: bool = false`.
  - Na primeira execução de `refresh_cards()`, os 36 cards são gerados e indexados por sua chave (`key`).
- **Atualização In-Place (`_update_card_view`):**
  - Cada card armazena em seus metadados (`card.set_meta("refs", refs)`) referências diretas para seus componentes reativos (`icon_panel`, `icon_view`, `lock_rect`, `tag_bg`, `tag_lbl`, `origin_badge`, `name_lbl`, `attr_lbl`, `desc_lbl`, `prog_container`, `count_lbl`, `milestone_title_lbl`, `m_bar`, `action_vbox`).
  - Quando os dados mudam (resgate de marco ou nova colheita), `_update_card_view()` atualiza apenas propriedades textuais, valores da barra e estado do botão de resgate, sem recriar nenhum nó estrutural.
- **Alternância Instantânea de Filtros via `.visible`:**
  - Implementado `_apply_active_filter()` e `_is_matching_filter()`. Ao clicar em um filtro de categoria, nenhum card é destruído: o loop apenas ajusta `card.visible = true/false`.
  - Adicionado o método auxiliar `get_visible_cards_count() -> int` para inspeção e testes automatizados.

---

## 📊 Resultados e Métricas (Benchmark Oficial)

Executado via `tests/test_herbarium_perf.tscn` no console Godot 4.7.2:

| Métrica | Linha de Base (v0.12.197) | Pacotes 0 & 1 (v0.12.198) | Pacotes 2 & 3 (v0.12.199) | Ganho Acumulado |
| :--- | :--- | :--- | :--- | :--- |
| **Total de Nós na Aba** | 928 nós | 928 nós | **856 nós** | **-72 nós eliminados** |
| **Passes de Fragment Shader na GPU** | 36 passes contínuos | 36 passes contínuos | **0 passes (pré-assado)** | **100% livre de shader 2D** |
| **Estilos Únicos (StyleBoxes)** | 95 instâncias | 15 instâncias | **15 instâncias** | **-84.2% memória UI** |
| **Tempo Médio de Troca de Filtro** | ~60.00 ms (rebuild) | ~60.00 ms (rebuild) | **2.56 ms (toggle .visible)** | **~23.4x mais rápido** |
| **Atualização Geral (`refresh_cards`)** | ~60.00 ms | ~60.00 ms | **15.14 ms** | **~4.0x mais rápido** |
| **Resgate de 1 Marco (`claim_ms`)** | 163.66 ms | 5.51 ms | **4.51 ms** | **~36.3x mais rápido** |

---

## 🧪 Testes e Validação de Integridade

- `tests/test_herbarium_perf.tscn`: Aprovado com sucesso (856 nós, 2.56ms troca de filtro, 15.14ms refresh).
- `tests/test_collection_system.tscn`: Aprovado com sucesso (36 espécies, persistência e filtros validados).
- `tests/test_manifest_sync.gd`: Aprovado com 0 erros (36 espécies, 6 obstáculos, 3 temas).
- `tests/test_all_botanical_variations.gd`: Aprovado com sucesso (28 flores, 7 gramas, 1 trigo).
- `tests/test_wheat_level_02.tscn`: Aprovado com sucesso.
- `godot --headless --import`: Executado com sucesso, 0 warnings e 0 erros.
