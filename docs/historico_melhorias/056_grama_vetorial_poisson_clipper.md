# Melhoria 056: Grama por Coordenadas Vetoriais 2D, Clipper C++, Amostragem Poisson Disk e Formato JSON v3 🌿📐

## 1. Visão Geral e Contexto

Anteriormente, o sistema de vegetação evoluiu de blocos discretos de $0.80\text{m}$ (v1) para uma subgrade fina de $0.20\text{m}$ (v2). No entanto, o desenho de tufos ainda dependia de discretizações quadriculadas de matriz, o que restringia o desenho orgânico contínuo e causava artefatos escalonados em contornos arredondados, além de limitar traços livres naturais no editor de fases.

Esta melhoria implanta a **Abordagem 1: Desenho Vetorial 2D (Polígonos 2D / Splines Bézier / Poisson Disk Sampling)**, permitindo desenhar a grama livremente sobre o terreno como uma pintura contínua ou carimbo analítico, sem depender de células mínimas de grid. A distribuição de tufos é gerada matematicamente por amostragem orgânica **Poisson Disk (Blue Noise)** acelerada em grade espacial, com afinamento suave nas bordas e geração de malhas planas 2D trianguladas de base sobre o piso da ilha.

---

## 2. Arquitetura da Solução Técnica

### 2.1 Classe Central `VectorGrassField` (`scripts/level/vector_grass_field.gd`)
- **Geometria Vetorial Contínua:** Armazena polígonos externos fechados (`polygon: PackedVector2Array`) e furos internos (`holes: Array[PackedVector2Array]`) em coordenadas contínuas de mundo ($XZ$ em metros).
- **Operações Booleanas em C++ (Clipper / Geometry2D):**
  - `merge_or_add_shape(type_name, new_poly)`: Detecta sobreposições reais com `Geometry2D.intersect_polygons()` e une contornos do mesmo tipo via `Geometry2D.merge_polygons()`.
  - `clip_shapes(eraser_poly)`: Aplica subtração booleana via `Geometry2D.clip_polygons()`, permitindo cortar, vazar ou apagar qualquer porção da grama com precisão analítica.
- **Amostragem Poisson Disk (Algoritmo de Bridson Otimizado):**
  - Distância mínima inter-tufo $r = 0.22\text{m}$ (densidade orgânica uniforme sem alinhamento em eixos e sem agrupamento irregular).
  - Aceleração por grade espacial de células $r / \sqrt{2}$, garantindo amostragem completa de níveis densos em $\approx 2\text{ ms}$ a $5\text{ ms}$.
  - Afinamento suave de borda: calcula a distância mínima de cada ponto até as arestas do polígono via `Geometry2D.get_closest_point_to_segment()`, escalando os tufos de borda suavemente de $0.50$ a $1.00$ ($d_{\text{taper}} = 0.16\text{m}$).
- **Geração de Malhas de Chão Trianguladas (`generate_ground_meshes`):**
  - Converte os polígonos vetoriais em superfícies 2D trianguladas via `Geometry2D.triangulate_polygon()`.
  - Instancia malhas planas rente ao piso ($Y = 0.005$) com materiais foscos sólidos (`roughness = 0.90`), desenhando a base perfeita da grama sob os tufos e eliminando qualquer necessidade de texturas rasterizadas de alta resolução.
- **Conversor Retrocompatível (`convert_from_legacy_field`):**
  - Converte células matriciais legadas (v1 ou v2) em retângulos contíguos e executa união via Clipper, gerando os contornos vetoriais correspondentes de forma transparente.

### 2.2 Integração no `VegetationGrid` (`scripts/plants/vegetation_grid.gd`)
- Suporte nativo ao formato v3 (`grass_vectors`): carrega via `VectorGrassField.from_dict_list()` ou converte automaticamente níveis legados.
- Eliminação de grama sob rochas: corta círculos analíticos de raio $0.38\text{m}$ diretamente nos polígonos vetoriais antes da amostragem.
- Agrupamento em células lógicas de $0.40\text{m}$ para preservar a economia de metas e moedas com 100% de estabilidade com os sistemas de gameplay e HUD existentes.
- Malhas planas de piso renderizadas em instâncias leves (`_ground_mesh_instances`) com cores sólidas correspondentes a cada tipo de planta (verde, amarelo, azul, roxo, trigo, flor).

### 2.3 Editor de Fases com Pincel Livre Contínuo e Estampas (`scripts/editor/level_editor.gd`)
- **Pincel Livre (Freehand Ribbon):** Na camada `EditLayer.GRASS`, o arrasto do mouse acumula pontos de traço e gera polígonos contínuos via `BrushPatterns.create_ribbon_polygon(_freehand_points, width)` com pontas arredondadas suaves (`JOIN_ROUND`, `END_ROUND`).
- **Ajuste de Largura do Pincel:** Atalhos `[` e `]` ajustam o tamanho do pincel em tempo real (1 a 4), variando a largura de traço de $0.30\text{m}$ a $1.00\text{m}$.
- **Carimbos Paramétricos:** Estampas geométricas (Círculo, Quadrado, Diamante, Coração, Estrela e Cruz) geram polígonos vetoriais instantâneos na posição do cursor.
- **Preview Holográfico:** Renderização ImmediateMesh em tempo real na superfície (`grid_overlay.update_vector_preview`) com contorno neon e preenchimento translúcido.
- **Undo / Redo Completo:** Histórico de snapshots armazena `grass_vectors_data`, garantindo Ctrl+Z e Ctrl+Y fluidos e sem perda de dados vetoriais.

### 2.4 Conversão em Lote das 20 Fases Canônicas
- Todas as fases de 1 a 20 em `data/levels/level_*.json` foram convertidas para o padrão `"version": 3` contendo `"grass_vectors"`.
- As pedras e flores foram mantidas na camada discreta de objetos de tile (`objects`), assegurando remoção independente sem interferência mútua.

---

## 3. Resultados de Performance e Integridade

- **Tempo de Carga na Fase 20:** Carregamento de 14.924 tufos vetoriais em apenas **$809.9\text{ ms}$** (anteriormente $\approx 1.722\text{ ms}$), uma redução de **53%** no tempo de processamento.
- **Zero Warnings Estrito:** Godot Engine 4.7.1 executou todos os testes headless (`level_editor.tscn`, `main.tscn`, `main_menu.tscn`, `perf_test.tscn`) com **0 erros** e **0 warnings**.
- **Game SemVer:** Atualizado para `v0.9.0-alpha` (código `900`) em `game_version.gd`, `project.godot` e `export_presets.cfg`.
