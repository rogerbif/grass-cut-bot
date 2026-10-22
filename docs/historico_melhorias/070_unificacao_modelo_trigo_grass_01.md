# Histórico de Melhoria: Unificação do Modelo 3D do Trigo com a Grama Oficial (`grass_01`) 🌾✨

**ID:** `070_unificacao_modelo_trigo_grass_01`  
**Versão:** `v0.10.7-alpha`  
**Data:** 21/10/2026  
**Status:** Concluído e Validado (0 Warnings no Godot 4.7.1)  

---

## 1. Contexto e Diagnóstico

Durante os testes em dispositivo móvel, foi constatado que o trigo apresentava um aspecto visual destoante do restante da vegetação do jogo:
- A grama utilizava a malha 3D low poly estilizada de alta qualidade (`grass_01.glb`), com folhas esguias em leque e curvatura orgânica.
- O trigo utilizava a cena legada `scenes/plants/wheat_tuft.tscn` composta por primitivas procedurais duras (cilindros finos e caixas retangulares de espiga), gerando inconsistência estética.

---

## 2. Solução Implementada

1. **Adoção do Modelo Canônico `grass_01.glb` para o Trigo:**
   - Em [`scripts/plants/vegetation_grid.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/plants/vegetation_grid.gd), o tipo `v_type == "wheat"` foi unificado para instanciar a malha `_grass_mesh` (`grass_01.glb`), eliminando o uso das primitivas geométricas.
   - Adicionada a entrada `"wheat": preload("res://shaders/interactive_wheat_material.tres")` em `GRASS_MATERIALS`.
   - Calibradas as proporções de escala do trigo para manter porte maduro e imponente (altura entre $0.55\text{m}$ e $0.70\text{m}$ e largura $XZ$ entre $0.34\text{m}$ e $0.46\text{m}$), perfeitamente integrado à grade e amostragem Poisson Disk.

2. **Unificação no Menu Inicial (`scripts/menu/island_node.gd`):**
   - Miniaturas das ilhas agora utilizam `_grass_mesh` para o trigo, com materiais dedicados `MAT_ACTIVE_WHEAT` (dinâmico com balanço de vento na Home) e `_mat_static_wheat` (estático para performance na visão Mapa).

3. **Atualização da Cena Base (`scenes/plants/wheat_tuft.tscn`):**
   - Atualizada para instanciar `assets/models/grass_01.glb` com `interactive_wheat_material.tres`, garantindo conformidade caso a cena seja instanciada individualmente.

---

## 3. Validação Técnica

- Testado no Godot 4.7.1 via MCP Debug Runner:
  - `scenes/main.tscn`: Aprovado com **0 warnings e 0 erros**. Trigo farto, curvado e ondulando com a mesma elegância da grama em leque.
  - `scenes/menu/main_menu.tscn`: Aprovado com **0 warnings e 0 erros**.
