# Histórico de Melhorias: 246 - Correção da Emenda de Terreno e Remoção de Paredes Invisíveis na Fase 18 🏝️🧱

**Versão Associada:** `v0.12.203-alpha`  
**Data de Conclusão:** 16/11/2026  
**Status:** Concluído e Validado  

---

## 1. Visão Geral e Contexto do Problema

Ao criar e desenhar a **Fase 18** através do Editor de Fases utilizando múltiplos carimbos/retângulos sobrepostos para compor o arquipélago, o usuário constatou que o robô cortador colidia contra "paredes invisíveis" nos corredores transitáveis, impedindo-o de percorrer todo o mapa.

A investigação minuciosa na geometria da fase e nos algoritmos de compilação de terreno revelou duas causas raízes críticas:

1. **Descarte de União Booleana no `VectorTerrainField`:**
   - Em `scripts/level/vector_terrain_field.gd`, as funções `add_land` e `_reduce_overlapping_polygons` chamavam `Geometry2D.merge_polygons(poly_a, poly_b)` e impunham a condição restritiva:
     ```gdscript
     if res.size() == 1:
         # aceitava a união
     ```
   - Quando peças de terra firme (como retângulos nos cantos e uma cruz central) são sobrepostas cercando pequenos vãos ou lagos internos (gerando 1 contorno externo e 1 ou mais furos internos), o Clipper do Godot retorna múltiplos polígonos (`res.size() >= 2`).
   - Por descartar uniões onde `res.size() != 1`, o editor mantinha os 5 polígonos sobrepostos soltos em `island_polygons`.

2. **Geração de Colisores Costeiros em Bordas Internas Sobrepostas (`IslandMeshBuilder`):**
   - Ao carregar uma fase com polígonos de terra sobrepostos em `IslandMeshBuilder.build_coastal_colliders()`, cada polígono gerava caixas de colisão verticais em todas as suas arestas originais (`Layer 1: Ground & Limits`).
   - As arestas que cortavam os corredores do outro polígono tornavam-se barreiras de colisão físicas invisíveis que travavam a navegação do Cutter Bot.

---

## 2. Modificações e Soluções Implementadas

### 2.1 União Booleana Robusta com Separação de Furos (`scripts/level/vector_terrain_field.gd`)
- Criado o método privado `_merge_land_polygons(poly_a: PackedVector2Array, poly_b: PackedVector2Array) -> Array[PackedVector2Array]`:
  - Utiliza `Geometry2D.merge_polygons()`.
  - Normaliza os vértices e identifica o contorno externo principal (outer).
  - Quando a fusão fecha um vão interno, detecta os furos resultantes usando teste de ponto em polígono (`Geometry2D.is_point_in_polygon`) e registra-os automaticamente na lista de `base_holes`.
  - Retorna o contorno externo unificado.
- Substituída a rotina legada `_reduce_overlapping_polygons` por `_reduce_overlapping_polygons_with_holes`:
  - Itera sobre a lista de polígonos de terra até que todas as formas sobrepostas ou adjacentes sejam completamente fundidas.
- Integrada a auto-cura em `from_dict()`: fases carregadas com polígonos sobrepostos são saneadas e unificadas imediatamente.

### 2.2 Blindagem e Sanitização no Construtor 3D (`scripts/level/island_mesh_builder.gd`)
- Implementado o método estático `sanitize_island_polygons(island_polygons: Array) -> Array[PackedVector2Array]`:
  - Executa fusão booleana recursiva em todos os polígonos de terra antes da compilação da malha.
- Integrada a sanitização nas três etapas de construção:
  - `build_island_mesh`: previne sobreposição de malha e z-fighting.
  - `build_coastal_foam_mesh`: garante uma única fita de espuma limpa no perímetro costeiro.
  - `build_coastal_colliders`: garante que colisores só existam nas bordas marítimas reais e nos furos autênticos, eliminando qualquer colisor interno nos corredores.

### 2.3 Saneamento e Validação da Fase 18 (`data/levels/level_18.json`)
- Com autorização expressa do usuário (Mandamento 17), `level_18.json` foi saneado:
  - Os 5 polígonos sobrepostos foram unificados em **1 único contorno perimetral contínuo** de 84 vértices.
  - Os furos internos transitáveis e lagos foram consolidados com precisão matemática.
- Executado teste de navegação standalone (`verify_level_18_navigation.gd`):
  - Comprovada a ausência de qualquer colisor costeiro nos corredores entre o ponto de spawn `(-6.0, 8.4)` e os 4 quadrantes da fase.

---

## 3. Arquivos Modificados e Impactados

| Arquivo | Modificação Principal |
| :--- | :--- |
| `scripts/level/vector_terrain_field.gd` | Fusão com suporte a múltiplos polígonos/furos e auto-cura de sobreposições em `from_dict`. |
| `scripts/level/island_mesh_builder.gd` | Salvaguarda `sanitize_island_polygons` aplicada na malha, espuma e colisores costeiros. |
| `data/levels/level_18.json` | Consolidação geométrica dos polígonos de ilha e furos, eliminando paredes internas. |
| `scripts/core/game_version.gd` | Incremento SemVer para `v0.12.203-alpha`. |
| `project.godot` | Atualização de versão canônica `0.12.203-alpha`. |
| `export_presets.cfg` | Atualização do preset Android para `0.12.203-alpha` (`version/code=1403`). |
| `docs/03_level_design_e_fases/SISTEMA_EDITOR_DE_FASES.md` | Documentação canônica da união booleana com furos no terreno vetorial. |
| `docs/02_entidades_e_mecanicas/SISTEMA_DE_OBSTACULOS_E_TERRENO.md` | Documentação canônica da sanitização de polígonos no `IslandMeshBuilder`. |
| `docs/historico_melhorias/INDICE_MELHORIAS.md` | Indexação da melhoria 246 no catálogo mestre. |

---

## 4. Testes e Validação

1. **Verificação de Colisões e Navegação:**
   - O robô cortador tem trânsito 100% livre por toda a ilha da Fase 18 sem travar em barreiras invisíveis.
2. **Reimportação Atômica de Recursos:**
   - `godot --headless --import` executado com código de retorno 0.
3. **Zero Warnings Estrito:**
   - Execução dos scripts e do projeto mantida em 0 warnings no console da Godot.
