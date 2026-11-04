# Relatório de Melhoria: Novo Card de Fase no Menu (Home e Mapa) Substituindo Placa 3D

**Versão:** `v0.12.111-alpha`  
**Data:** 04/11/2026  
**Status:** Concluído com Sucesso

---

## 🎯 Objetivos Realizados

1. **Novo Componente 2D `MapLevelCard`:**
   - Criação do card cyber de informações da fase conforme a referência visual aprovada:
     - **Linha superior esquerda:** Ícone de ilha com palmeiras (`icon_island_palm.svg`) ou cadeado cyber (`icon_cyber_lock.svg`) em fases bloqueadas + número da fase (`Fase %02d`) em destaque e rótulo do bioma ("Ilha Tropical").
     - **Linha superior central:** Trio de estrelas proporcionais (estrela central maior em 46px e laterais em 36px) exibindo `star_3d_gold.svg` para conquistadas e `star_empty_cyber.svg` para pendentes + subtítulo "Estrelas" / "Bloqueada".
     - **Linha superior direita:** Ícone de relógio (`icon_clock.svg`) + tempo formatado (`mm:ss`) extraído de `time_limit` + legenda "Tempo".
     - **Faixa de Objetivos da Fase:** Moldura hexagonal cyber (`frame_objectives.svg`) contendo os mini-cards de 72px de altura com os ícones botânicos vetoriais idênticos à Coleção/HUD (`illus_wheat_bundle.svg`, camadas de solo e tufos coloridos de grama, hastes e flores) gerados por `GoalIconFactory`.

2. **Remoção Definitiva da Placa 3D Antiga:**
   - Removidos de `island_node.tscn` e `island_node.gd` o nó 3D `Plaque` (com `PostMesh`, `BoardMesh`, `LevelLabel` e `StarsLabel`), economizando nós 3D, cálculos de transformação e materiais redundantes por ilha.

3. **Metas Canônicas Gravadas em Cada Fase (`card_goals`):**
   - Criação da ferramenta de geração headless e gravação de `card_goals` em todos os 20 arquivos JSON de fase (`data/levels/level_01.json` a `level_20.json`).
   - Integração no `level_serializer.gd` para que futuras fases salvas pelo editor já gravem automaticamente as metas calculadas.

4. **Exibição Universal (Home/Bot e Mapa):**
   - Conforme especificado pelo usuário, o `MapLevelCard` fica posicionado perfeitamente acima da barra de botões `JOGAR / MAPA` na aba `TabHome`, atualizando instantaneamente quando o jogador rola pelo arquipélago ou seleciona qualquer ilha.

---

## 📂 Arquivos Modificados / Criados

- `assets/ui/map_card/`: Vetores `card_level_bg.svg`, `frame_objectives.svg`, `star_empty_cyber.svg`, `icon_island_palm.svg`.
- `scripts/ui/goal_icon_factory.gd`: Fábrica botânica unificada para construção das ilustrações multicamadas.
- `scripts/level/level_card_data.gd`: Helper de leitura rápida de dados de cards de fases, bioma e formatação.
- `scripts/ui/map_level_card.gd` & `scenes/ui/map_level_card.tscn`: Implementação completa do card de fase 2D.
- `scenes/menu/tabs/tab_home.tscn` & `scripts/menu/tabs/tab_home.gd`: Integração do `MapLevelCard` acima de `BottomAction` e sincronização no `preview_level`.
- `scripts/menu/main_menu.gd`: Conexão do `preview_level` no foco de scroll da câmera de mapa.
- `scenes/menu/island_node.tscn` & `scripts/menu/island_node.gd`: Limpeza da placa 3D antiga.
- `scripts/ui/hud.gd`: Refatoração limpa consumindo `GoalIconFactory`.
- `scripts/editor/level_serializer.gd`: Auto-computação de `card_goals` ao salvar JSONs.
- `data/levels/level_01.json` a `level_20.json`: Metas das 20 fases adicionadas em `card_goals`.
- `project.godot` e `scripts/core/game_version.gd`: Incremento de versão para `0.12.111-alpha`.
