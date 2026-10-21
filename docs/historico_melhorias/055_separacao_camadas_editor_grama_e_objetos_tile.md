# Melhoria 055: Separação de Camadas no Editor (Terreno, Grama Fina e Objetos no Tile) 🪨🌸🌿

**Data:** 21 de Outubro de 2026  
**Versão:** `v0.8.1-alpha`  
**Escopo:** Editor de Fases, UX de Ferramentas, Persistência de Dados e Entidades  
**Status:** Concluído e Validado  

---

## 1. Visão Geral e Motivação

Durante o uso do Editor de Fases após a implementação da grama orgânica em campo fino ($0.20\text{m}$), pedras e gramas estavam agrupadas em uma única camada ("Gramas & Objetos"). Isso criava atritos de edição:
- Ao tentar apagar uma pedra (`rock`) com a borracha ou clique direito tendo uma cor de grama selecionada, o editor executava a limpeza apenas no campo fino de grama (`veg_field`), ignorando a grade de objetos (`object_grid`).
- A mistura de elementos de naturezas distintas (grama contínua vs. rochas sólidas vs. flores de tile) gerava confusão na seleção e exclusão de elementos.

A solução foi estruturar o editor e a renderização em **3 camadas dedicadas e ortogonais**:
1. **Camada 0 — Terreno (Ilha 0.80m):** Blocos modulares 3D de terreno com Auto-Tile.
2. **Camada 1 — Grama (Campo Fino 0.20m):** Pintura fluida e contínua de gramas coloridas e trigo com formas analíticas suaves (círculo, coração, etc.).
3. **Camada 2 — Objetos no Tile (0.80m):** Entidades discretas centralizadas por bloco:
   - **Rocha Sólida (`rock`):** Obstáculo com colisão e ricochete.
   - **Flor Nobre (`flower`):** Vegetação de alto valor econômico centralizada no tile.
   - **Spawn (`cutter_spawn`):** Ponto de partida do robô cortador.

---

## 2. Destaques Técnicos

1. **UX de Seleção Automática de Camada:**
   - Clicar em qualquer botão de Terreno ativa a Camada 0 (`TERRAIN`).
   - Clicar em qualquer botão de Grama ativa a Camada 1 (`GRASS`).
   - Clicar em qualquer botão de Objeto (Rocha, Flor ou Spawn) ativa a Camada 2 (`OBJECTS`).
2. **Exclusão Eficiente e Imediata de Objetos:**
   - Na Camada de Objetos, a Borracha (`ToolMode.ERASER`) e o Clique Direito apagam instantaneamente qualquer objeto presente na célula de $0.80\text{m}$ (`object_grid.erase(cell)`).
   - O Clique Direito sobre uma célula contendo pedra ou flor apaga o objeto diretamente, eliminando qualquer atrito de exclusão.
3. **Flores como Objetos no Tile (`0.80m`):**
   - Flores são armazenadas em `object_grid` e serializadas em `"objects": [ { "gx": ..., "gz": ..., "type": "flower", "rot": ... } ]`.
   - O `VegetationGrid` instancia a flor como célula lógica no centro exato do tile, garantindo compatibilidade total com todas as 20 fases canônicas e concedendo 5 moedas e 2 hits por flor.
4. **Resumo Automático de Metas Aprimorado:**
   - O HUD do editor agora discrimina em tempo real:
     - 🌿 Grama (micro-tufos no campo fino)
     - 🌾 Trigo (micro-tufos maduros)
     - 🌸 Flores (objetos de tile)
     - 🪨 Rochas (obstáculos sólidos)
     - 🏝️ Blocos de Ilha (tiles de terreno)

---

## 3. Validação

- Zero warnings e zero erros em Godot 4.7.1 headless em `main_menu.tscn`, `main.tscn`, `level_editor.tscn` e `perf_test.tscn`.
- Todas as 20 fases canônicas verificadas e mantidas com 100% de paridade.
