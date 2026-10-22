# Histórico de Melhoria: Restauração da Espuma Costeira Animada nas Ilhas do Menu e Gameplay 🌊🏖️

**ID:** `069_restauracao_espuma_costeira_animada_ilhas`  
**Versão:** `v0.10.6-alpha`  
**Data:** 21/10/2026  
**Status:** Concluído e Validado (0 Warnings no Godot 4.7.1)  

---

## 1. Contexto e Diagnóstico

O usuário identificou que o contorno de espuma animada na base das ilhas (onde as falésias encontram a água) havia desaparecido na visualização do Mapa de Fases do Menu Inicial.

A investigação da causa raiz revelou três fatores combinados:
1. **Omissão na Migração MultiMesh do Menu (`island_node.gd`):** Durante a migração de renderização para GPU Instancing das ilhas no menu, a geração da fita costeira de espuma (`CoastalFoamRibbon`) não havia sido acoplada na montagem procedural dos blocos.
2. **Desnível da Água no Menu (`scenes/menu/main_menu.tscn`):** O nó `OceanMesh` no menu estava posicionado em $Y = -0.34\text{m}$ (valor legado pré-calibração), enquanto os tiles de terreno eram escalados por $0.5$ em Y ($0.36\text{m}$ de profundidade). Já no gameplay e no editor, o oceano canônico é posicionado em **$Y = -0.71\text{m}$** e a falésia possui $0.72\text{m}$ de altura total. Esse desnível de $37\text{cm}$ no menu afogava qualquer geometria costeira.
3. **Ordem de Renderização (`render_priority`):** A malha de espuma necessitava de `render_priority = 2` para ser desenhada com transparência sobre o novo shader de água opaco/toon sem sofrer z-fighting.

---

## 2. Soluções Implementadas

1. **Modularização da Fita Costeira (`scripts/level/level_json_loader.gd`):**
   - Criado o método estático reutilizável `build_coastal_foam_mesh_instance(occupied_cells, width, height, cell_size, foam_y)` que gera a malha paramétrica contínua $C^1$ contornando os cantos curvos (`island_edge`, `island_corner_out`, `island_corner_in`, `island_end`).
   - Material associado ao shader `shaders/coastal_foam.gdshader` com `render_priority = 2` e `foam_y = -0.692\text{m}` ($1.8\text{cm}$ acima da água).

2. **Integração nas Ilhas do Menu (`scripts/menu/island_node.gd`):**
   - Coletado o dicionário `occupied_cells` dos tiles da ilha.
   - Removida a escala achatada `Vector3(1.0, 0.5, 1.0)`, restaurando a altura real 1:1 de $0.72\text{m}$ das falésias (idêntica ao gameplay).
   - Instanciado o `CoastalFoamRibbon` diretamente no `miniature_container` de cada ilha do menu.

3. **Equalização do Oceano no Menu (`scenes/menu/main_menu.tscn`):**
   - Reposicionado o `OceanMesh` de $Y = -0.34\text{m}$ para **$Y = -0.71\text{m}$**, unificando a linha d'água entre o Menu Inicial, Mapa e Gameplay.

---

## 3. Validação Técnica

- Executado o Godot MCP Debug Runner:
  - `scenes/menu/main_menu.tscn`: Aprovado com **0 warnings e 0 erros**. Espuma animada com vai e vem visível contornando todas as ilhas.
  - `scenes/main.tscn`: Aprovado com **0 warnings e 0 erros**.
  - `scenes/tools/water_tuner.tscn`: Aprovado com **0 warnings e 0 erros**.
