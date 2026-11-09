# 214 — Pacote 3 de Automação e Templates do Editor: Balde de Tinta `[5 / K]`, Galeria de 6 Templates de Ilha e Duplicar Fase `[Ctrl+Shift+S]` (`v0.12.166-alpha`)

**Data:** 09/11/2026  
**Versão:** `v0.12.166-alpha` (`version/code = 1366`)  
**Domínio:** Level Design & Editor de Fases (`scripts/editor/level_editor.gd`, `scripts/editor/level_editor_ui.gd`, `scripts/level/vector_grass_field.gd`, `scripts/level/vector_terrain_field.gd`)

---

## 1. Contexto e Objetivo

Concluindo o trio de pacotes de aprimoramento do **Editor de Fases In-Game**, o **Pacote 3** introduz ferramentas de automação em 1 clique para criação acelerada de fases:

1. **Ferramenta `[5] Balde de Tinta / Preencher` (`ToolMode.FLOOD_FILL`, atalho `5` ou `K`):**
   - **Na Camada 1 (Grama Vetorial):**
     - Clicar sobre uma mancha de grama existente recolore-a instantaneamente para a cor ativa (`recolor_shape_at_point`) e funde com polígonos adjacentes da mesma cor.
     - Clicar sobre solo livre preenche toda a área disponível da ilha com a cor selecionada, respeitando automaticamente o corredor costeiro externo ($0.48\text{m}$), as margens de lagos internos ($+0.48\text{m}$), as clareiras de rochas ($0.90\text{m}$), a clareira do spawn ($1.40\text{m}$) e preservando manchas existentes de outras cores (ou substituindo toda a grama da ilha com `Shift + Clique`).
   - **Na Camada 0 (Terreno Vetorial):**
     - Clicar dentro de um furo/lago interno fecha-o imediatamente com terra firme (`fill_hole_at_point`).
   - **Na Camada 2 (Objetos):**
     - Clicar sobre uma flor, trigo ou rocha substitui em lote todas as ocorrências daquele tipo no mapa pelo item selecionado na paleta.
2. **Galeria de 6 Templates Pré-Prontos de Ilha (`📐 Templates ▾`):**
   - `retangulo`: Ilha Retangular Clássica.
   - `atol`: Atol / Anel com Lagoa Central.
   - `gemeas`: Ilhas Gêmeas conectadas por Ponte Central.
   - `cruz_4`: Quatro Ilhotas em Cruz.
   - `estrela`: Ilha Estrela Tropical de 5 Pontas.
   - `meia_lua`: Enseada / Baía Costeira em Ferradura.
3. **Duplicar Fase / Salvar Como (`📋 Duplicar` / `Ctrl + Shift + S`):**
   - Modal `save_as_dialog` que detecta e sugere automaticamente a próxima fase livre (`_find_next_free_level_id()`), informa em tempo real se o slot de destino está livre (`✨ Nova fase`) ou ocupado (`⚠️ Sobrescrever`), e salva uma cópia completa da fase.

---

## 2. Validação e Testes Automatizados

- **`tests/test_editor_pacote3.gd` (`6/6` aprovados):**
  1. Verificação dos novos componentes de UI (`tool_buttons[4]`, `menu_island_templates`, `btn_save_as`, `save_as_dialog`).
  2. Geração dos 6 templates de ilha (`retangulo`, `atol`, `gemeas`, `cruz_4`, `estrela`, `meia_lua`), validando polígonos externos, lagoa interna do atol e `spawn_cell` posicionado em terra firme.
  3. Balde de Tinta na Camada 0 fechando o lago interno do Atol em 1 clique (`fill_hole_at_point`).
  4. Balde de Tinta na Camada 1 preenchendo o solo livre da ilha com `grass_blue` e recolorindo a mancha para `grass_yellow` (`recolor_shape_at_point`).
  5. Balde de Tinta na Camada 2 substituindo todas as ocorrências de `flower_rose_red` por `flower_rose_blue`.
  6. Duplicação de fase (`save_level_as(199)`) criando e validando o arquivo JSON e limpando `is_dirty`.
- **Testes de Regressão:** `test_editor_pacote2.gd` (`6/6`), `test_editor_pacote1.gd` (`5/5`) e `verify_levels_integrity.gd` (`40/40`) executados com 0 warnings e 100% de aprovação.
