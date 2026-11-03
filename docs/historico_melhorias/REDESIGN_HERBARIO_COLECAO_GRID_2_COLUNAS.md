# Redesign do Herbário Botânico (Aba Coleção) e Rolagem Touch 🌿📱

**Versão:** `v0.12.97-alpha`  
**Data:** 02/11/2026  
**Status:** Concluído com Sucesso

---

## 🎯 Objetivo
Reformular a interface da aba Coleção (**Herbário da Ilha & Itens**) e sanar os problemas de rolagem touch/mouse:
1. Reestruturação do catálogo em **Grid de 2 Colunas** com cartões verticais mecha/cyber (`card_species_bg.svg`).
2. Implementação de **rolagem inercial touch/mouse fluida** com controle inercial suave (`_gui_input`, `MOUSE_FILTER_PASS`).
3. Barra de progresso do topo em estilo **Cyber Arcade** com gradiente ciano e indicador textual `Descobertas: X / 15 (Y%)`.
4. Botão **"Coletar Tudo ✨"** no cabeçalho quando houver recompensas acumuladas de marcos de maestria.
5. Botão individual **"COLETAR +X"** em cada cartão de espécie descoberta que atinge marco de ceifa.
6. Remoção de filtros desnecessários no topo para maximizar o espaço útil de visualização móvel.

---

## 🛠️ Modificações Realizadas

### 1. Novos Ativos Vetoriais SVG (`assets/ui/collection/`)
- `card_species_bg.svg`: Fundo de cartão vertical chanfrado com gradiente escuro e contorno neon.
- `collection_prog_track.svg`: Calha de progresso com extremidades chanfradas em estilo cyber arcade.
- `collection_prog_fill.svg`: Preenchimento ciano/esmeralda com brilho superior translúcido.
- `badge_discovered.svg`: Pílula chanfrada verde militar/esmeralda com contorno neon para espécies descobertas (`✓ DESCOBERTA`).
- `badge_locked.svg`: Pílula chanfrada escura/avermelhada para espécies bloqueadas (`BLOQUEADO`).
- `icon_cyber_lock.svg`: Ícone de cadeado cyber neon com ponto de interrogação `?` estilizado.

### 2. Cena da Aba Coleção (`scenes/menu/tabs/tab_collection.tscn`)
- Painel principal reestruturado com margens refinadas para celular portrait.
- Cabeçalho com ícone botânico nativo, título `Herbário da Ilha & Itens`, subtítulo e barra de progresso cyber com contagem e percentual.
- Botão condicional de coleta em lote `BtnClaimAll` ("Coletar Tudo").
- `ScrollContainer` contendo `GridContainer` com `columns = 2` e separação proporcional de 12px horizontal e 14px vertical.

### 3. Script da Aba Coleção (`scripts/menu/tabs/tab_collection.gd`)
- Implementada rolagem inercial cinética suave via detecção de toque (`InputEventScreenTouch` / `InputEventScreenDrag`) e mouse (`InputEventMouseButton` / `InputEventMouseMotion` / roda do mouse).
- Configuração estrita de `mouse_filter = MOUSE_FILTER_PASS` em todos os cartões e nós filhos para não reter gestos de arraste.
- Geração dinâmica de cartões em 2 colunas com tags `✓ DESCOBERTA` / `BLOQUEADO`, ícone colorido com halo suave ou silhueta de cadeado, resistência em golpes, moedas de recompensa, barra de progresso e botão de resgate.
- Função `_on_claim_all_pressed()` para resgatar todos os marcos pendentes em lote com feedback sonoro e háptico.

---

## 📊 Verificação
- Godot 4.7.1 executado com 0 warnings no console.
- UIDs de recursos SVG sincronizados.
- Todos os 15 cartões de plantas organizados em 2 colunas responsivas.
