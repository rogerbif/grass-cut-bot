# Melhoria 119: Aumento de 100% no Modelo 3D de Trigo (Escala Dobrada) 🌾🌾

**Versão:** `v0.12.43-alpha`  
**Data:** 27/10/2026

---

## 1. Contexto e Motivação

O usuário solicitou: *"aumente em 100% o modelo do trigo no jogo"*.

Anteriormente, o trigo (`wheat_01.glb`) utilizava fatores de escala comparativamente reduzidos (`0.55 .. 0.70` em altura e `0.34 .. 0.46` em largura horizontal no `VegetationGrid` e `IslandNode`; e `0.48 .. 0.58` na cena de instância individual `plant.gd`). Isso deixava as espigas douradas baixas e visualmente delgadas, não transmitindo a imponência de um canavial/trigal denso e robusto sobre as ilhas 3D.

Ao aumentar a escala em 100% (fator multiplicador $\times 2.0$), as espigas passam a exibir altura marcante, feixes volumosos e silhueta imponente, destacando de longe as barreiras de trigo que exigem 2 golpes da serra circular para colheita.

---

## 2. Alterações Implementadas

### 2.1. MultiMesh do Terreno e Amostragem Vetorial (`vegetation_grid.gd`)
- Em `_build_from_vector_field()`:
  - Altura (`scale_y`): ampliada de `0.55 .. 0.70` para `lerpf(1.10, 1.40, scale_factor) * (0.95 + fmod(s_seed * 0.13, 0.10))`.
  - Largura horizontal (`scale_xz`): ampliada de `0.34 .. 0.46` para `lerpf(0.68, 0.92, scale_factor) * (0.95 + fmod(s_seed * 0.27, 0.10))`.
- Em `_build_from_vegetation_field()` (retrocompatibilidade v2):
  - Altura (`scale_y`): ajustada para `lerpf(1.10, 1.40, edge_t) * (0.95 + fmod(s_seed * 0.13, 0.10))`.
  - Largura horizontal (`scale_xz`): ajustada para `lerpf(0.68, 0.92, edge_t) * (0.95 + fmod(s_seed * 0.27, 0.10))`.

### 2.2. Ilha 3D e Miniaturas no Menu Principal (`island_node.gd`)
- Objetos discretos de trigo nos tiles: escala dobrada de `Vector3(0.42, 0.65, 0.42)` para `Vector3(0.84, 1.30, 0.84)`.
- Amostragem por campo vetorial (`sample_all_tufts`): `scale_y: 1.10 .. 1.40` e `scale_xz: 0.68 .. 0.92`.
- Campo de vegetação legado: `scale_y: 1.10 .. 1.40` e `scale_xz: 0.68 .. 0.92`.

### 2.3. Instância Individual de Cena e Editor de Fases (`plant.gd`)
- No `_ready()` para `PlantType.WHEAT`:
  - Escala aleatória ampliada de `0.48 .. 0.58` para `randf_range(0.96, 1.16)` em $X, Y, Z$.
  - Como o pivô do modelo `wheat_01.glb` reside no solo ($Y = 0$), o crescimento ocorre verticalmente para cima sem afundar no terreno nem deslocar o centro de colisão da planta.
- Mantido o raio de colisão física e lógica em $0.18\text{m}$ em `resolve_rigid_plant_collision` e `wheat_tuft.tscn`, garantindo que os corredores de navegação entre obstáculos e bordas da ilha continuem limpos e transitáveis para o robô ceifador.

---

## 3. Validação e Qualidade Técnica

1. **Zero Warnings e Sem Erros:**
   - Validação com Godot 4.7.1 headless em `perf_test.tscn`, `main.tscn` e `main_menu.tscn`.
2. **Performance 60 FPS Mobile:**
   - Renderização MultiMesh em GPU batching único para toda a cultura de trigo na fase. Custo de renderização idêntico com riqueza visual dobrada.
