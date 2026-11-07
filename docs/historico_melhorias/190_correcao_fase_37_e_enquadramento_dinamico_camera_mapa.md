# Melhoria 190: Correção Estrutural da Fase 37 (Pontes Sólidas e Solo Verde Contrastante) e Enquadramento Dinâmico com Canal Constante no Arquipélago 🏝️📷

**Versão do Projeto:** `v0.12.140-alpha`  
**Data:** 06/11/2026  
**Status:** Concluído e Validado ✅  

---

## 📌 Contexto e Diagnóstico

1. **Fase 37 ("Centro Parecendo Água" e "Satélites Isolados"):**
   - **Pontes Incompletas:** O gerador anterior utilizou laços diagonais restritos a $j \in [8..14]$ que não atingiam as coordenadas reais dos 4 satélites chanfrados nos cantos, gerando canais de água abertos e impedindo o trânsito do robô cortador.
   - **Ilusão de Buraco d'Água:** O centro foi preenchido unicamente com um círculo de `grass_blue` (azul piscina/ciano), cuja tonalidade mimetiza o mar toon ao redor, dando a impressão visual ao jogador de que o centro não possuía chão de terra.

2. **Visão de Mapa (Arquipélago no Menu Principal):**
   - **Ilhas Encostando e Colidindo:** O posicionamento das fases no menu utilizava um espaçamento linear fixo de $Z = -float(i - 1) \times 18.5\text{m}$. Como as fases 21 a 40 introduziram mega-ilhas com diâmetros de até $24.8\text{m}$, a soma dos raios das ilhas vizinhas superava $18.5\text{m}$, provocando sobreposição e colisão visual entre as ilhas adjacentes.
   - **Câmera Rígida sem Zoom Apropriado:** A altura da câmera em `menu_camera.gd` possuía clamp rígido entre $25.0$ e $36.0$, insuficiente para afastar e enquadrar adequadamente as mega-ilhas de $25\text{m}$ em modo vertical (portrait 9:16) ou aproximar nas ilhas pequenas iniciais. Além disso, as funções de encaixe magnético (`snap_to_level`, `find_closest_level`) dependiam do $Z$ linear em vez dos waypoints reais.

---

## 🛠️ Implementações Realizadas

### 1. Reconstrução dos Istmos e Paleta da Fase 37 (`scripts/tools/generate_all_40_levels.gd`)
- Conexão contínua de **3 tiles de largura** (mais de 2.4 metros de largura útil) entre o octógono central $(15, 15)$ e os 4 satélites chanfrados para todas as diagonais ($d \in [7, 15]$ e largura $w \in [-1, 1]$), permitindo passagem segura do robô sem risco de queda no mar.
- Pintura da ilha central com grama verde de alto contraste (`grass_green`) com raio de 5.6m, estabelecendo aspecto evidente e sólido de terra firme.
- Distribuição equilibrada e simétrica das variedades cromáticas exigidas nas metas da fase:
  - Top-Left e Bottom-Right: `grass_blue` (azul)
  - Top-Right e Bottom-Left: `grass_yellow` (amarelo)
  - Centro e istmos: `grass_green` (verde)
- Regeneração e validação via auditoria do arquivo `data/levels/level_37.json`.

### 2. Espaçamento Cumulativo com Canal Constante de Água (`scripts/menu/main_menu.gd`)
- Substituição do passo fixo $18.5\text{m}$ pelo algoritmo cumulativo baseado no tamanho real de cada ilha:
  $$\Delta Z_i = \frac{\text{depth}_{i-1}}{2} + \frac{\text{depth}_i}{2} + \text{WATER\_GAP}$$
  onde `water_gap = 9.0` metros de canal aberto de oceano limpo entre as praias de ilhas consecutivas.
- Garantia matemática de que nenhuma ilha toque ou se sobreponha à vizinha, do nível 1 ao 40.
- Posicionamento proporcional do banco de nuvens terminal `clouds_end` logo após a Fase 40.

### 3. Enquadramento Dinâmico da Câmera (Zoom Proporcional) (`scripts/menu/menu_camera.gd`)
- Redefinição de `calculate_island_target_height(dim: Vector2)` com base na projeção geométrica do FOV vertical em orientação portrait (9:16):
  $$Y_{\text{alvo}} = \text{clampf}(\max(dim.x \times 2.10, dim.y \times 1.35), 20.0, 58.0)$$
  - Ilhas pequenas (10m x 10m): altura da câmera desce suavemente para $21.0\text{m}$, aproximando e valorizando os detalhes.
  - Mega-ilhas (24.8m x 24.8m): altura da câmera afasta para $52.08\text{m}$, enquadrando a ilha inteira e seus satélites com margem confortável para o HUD e botões.
- Adaptação das funções de snap magnético (`find_closest_level`, `snap_to_level`, `switch_to_map_view`) para operar diretamente sobre a lista real de waypoints (`island_waypoints`), proporcionando transições precisas e fluidas.

### 4. Acesso Defensivo a Autoloads (Regra 16 do GEMINI.md)
- Atualização em `scripts/ui/cyber_resource_badge.gd` e `scripts/ui/exit_modal.gd` para utilizar `get_node_or_null("/root/AudioManager")` e `get_node_or_null("/root/SaveManager")`, assegurando execução 100% limpa em rotinas de teste e scripts standalone.

---

## 📊 Resultados e Validação

- **Auditoria de Fases (40/40):** 0 erros na geração e validação de todas as fases de 1 a 40.
- **Auditoria Matemática do Arquipélago:** Canal de mar de exatamente $9.0\text{m}$ verificado entre todos os 39 pares de ilhas vizinhas (zero colisões).
- **Enquadramento da Câmera:**
  - Fase 01: $Y = 21.00\text{m}$
  - Fase 10: $Y = 31.92\text{m}$
  - Fase 21: $Y = 38.64\text{m}$
  - Fase 37: $Y = 52.08\text{m}$
- **Console Godot:** 0 warnings e 0 erros.
