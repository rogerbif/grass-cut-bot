# Melhoria 054: Grama Orgânica em Campo Fino (0.20m), Corte Circular Radial e Decalque de Solo 🌿✂️🎨

**Data:** 21 de Outubro de 2026  
**Versão:** `v0.8.0-alpha`  
**Escopo:** Visual, Mecânicas de Corte, Shaders, Level Editor e Performance  
**Status:** Concluído e Validado  

---

## 1. Visão Geral e Motivação

Anteriormente, o sistema de vegetação utilizava uma grade discreta de $0.40\text{m}$ (e blocos originais de $0.80\text{m}$) onde os tufos eram agrupados rigidamente. Quando o usuário desenhava círculos, corações ou formas arredondadas no Editor de Fases, as bordas ficavam serrilhadas com degraus em $90^\circ$ e formato de cruz `+`. Além disso, quando o cortador passava, a remoção ocorria por bloco lógico sem borda visual circular suave, e não havia visualização contínua de gramado aparado sob a lâmina.

Esta melhoria implementou um salto visual completo mantendo o orçamento de renderização idêntico:
1. **Campo Analítico Fino de Vegetação ($0.20\text{m} \times 0.20\text{m}$):** Ilhas particionadas em micro-células de $0.20\text{m}$ ($4 \times 4$ por bloco de $0.80\text{m}$).
2. **Poda e Otimização do Modelo 3D (`grass_01.glb`):** Redução de 56 folhas (392 vértices) para 14 folhas (98 vértices, 70 faces) no Blender, preservando atributos de vértice `COLOR_0` para animação pendular individual das folhas.
3. **Afinamento de Borda por SDF (Signed Distance Field):** Algoritmo Chamfer 2-pass que calcula a distância de cada micro-tufo à borda vazia do campo, diminuindo gradualmente a escala dos tufos periféricos de forma natural.
4. **Corte Circular Radial por Micro-Tufo:** O corte visual ocorre individualmente sob o raio da lâmina da serra circular, produzindo uma borda de corte perfeitamente arredondada em tempo real.
5. **Agrupamento Lógico de Células ($0.40\text{m}$):** Para garantir consistência com o balanceamento do jogo, cota de colheita e moedas são concedidas quando todos os micro-tufos de uma célula lógica de $0.40\text{m}$ são colhidos (zero tufos órfãos).
6. **Decalque de Solo Orgânico & Trilha de Corte (`lawn_base_decal.gdshader` & `lawn_cut_trail.gd`):** Plano horizontal com interpolação linear e corte suave que revela o chão aparado sob a trajetória da serra.
7. **Editor de Fases Atualizado:** Pincéis analíticos contínuos (Círculo, Estrela, Coração, Losango), auto-geração de terreno ao pintar vegetação e exportação JSON v2 com compatibilidade retroativa total.

---

## 2. Componentes Criados e Modificados

| Componente | Caminho | Função |
| :--- | :--- | :--- |
| **`VegetationField`** | `scripts/level/vegetation_field.gd` | Estrutura de dados compacta em `PackedByteArray` ($0.20\text{m}$), mapa SDF 2-pass, world-to-cell e serialização JSON v2. |
| **`VegetationGrid`** | `scripts/plants/vegetation_grid.gd` | Instanciação em lote (`MultiMeshInstance3D`) com jitter determinístico, escala modulada por SDF, corte circular radial e decalque de solo. |
| **`LawnCutTrail`** | `scripts/level/lawn_cut_trail.gd` | Buffer de rastro dinâmico via `SubViewport` que desenha a trajetória da serra circular no gramado. |
| **`LawnBaseDecal Shader`** | `shaders/lawn_base_decal.gdshader` | Shader de piso para silhueta orgânica de base e máscara dinâmica de corte. |
| **`grass_01.glb`** | `assets/models/grass_01.glb` | Malha compacta de 14 folhas (98 vértices), mantendo ancoragem na base e balanço independente por folha. |
| **`BrushPatterns`** | `scripts/editor/brush_patterns.gd` | Função `get_field_offsets()` para carimbos contínuos analíticos em resolução de $0.20\text{m}$. |
| **`GridOverlay`** | `scripts/editor/grid_overlay.gd` | Visualização holográfica do pincel em passos de $0.20\text{m}$ no Editor de Fases. |
| **`LevelEditor`** | `scripts/editor/level_editor.gd` | Suporte à pintura direta em $0.20\text{m}$, auto-criação de terreno de ilha de $0.80\text{m}$ e undo/redo completo. |
| **`LevelSerializer`** | `scripts/editor/level_serializer.gd` | Leitura e gravação de fases no formato JSON v2 com backward compatibility total para JSON v1. |
| **`IslandNode`** | `scripts/menu/island_node.gd` | Suporte a miniaturas no Menu Inicial a partir do novo campo analítico. |

---

## 3. Validação e Métricas de Performance

- **Zero Warnings / Zero Erros:** Execução estrita no Godot 4.7.1 headless em todas as 20 fases, Menu Inicial, Editor de Fases e Benchmark.
- **Orçamento de Vértices:** ~5.000 micro-tufos na Fase 20 totalizam ~490k vértices (inferior aos ~508k anteriores), rodando a 60 FPS cravados no mobile.
- **Paridade de Metas:** Todas as 20 fases canônicas mantêm rigorosamente 100% de paridade de metas e recompensas (`Level 01: 216 grass`, `Level 20: 1188 grass, 54 wheat, 54 flower`).
