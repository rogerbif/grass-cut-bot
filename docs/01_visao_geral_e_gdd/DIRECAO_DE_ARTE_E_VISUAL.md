# Direção de Arte e Estilo Visual: Grass Cut Bot 🎨🌿

Este documento estabelece as diretrizes estéticas canônicas para o projeto **Grass Cut Bot**, com foco na entrega do estilo *Low Poly fosco vibrante* e na sensação de relaxamento visual (*satisfying aesthetics*).

---

## 1. Princípios Estéticos Fundamentais

1. **Low Poly com Cores Sólidas (Flat / Matte Shading):**
   - As superfícies não utilizam texturas fotorealistas ruidosas.
   - O acabamento é puramente fosco (`roughness = 0.85 ~ 0.95`), eliminando reflexos especulares plásticos desagradáveis.
   - As formas geométricas priorizam arestas limpas, silhuetas legíveis em telas pequenas de smartphone e volumes fáceis de ler de relance.

2. **Cores Saturadas e Harmoniosas (Arcade Warm Palette):**
   - A paleta equilibra tons naturais de vegetação com contrastes acentuados entre elementos colhíveis, piso limpo e obstáculos perigosos.

3. **Clareza de Leitura & Feedback Cel-Shaded Cartoon:**
   - Textos de impacto econômico e pontuação utilizam outline preto grosso (14px) para leitura instantânea contra qualquer fundo de gramado ou mar.

---

## 2. Paleta de Cores Canônica

![Concept Art Canônico - Cutter Bit](../assets/cutter_bit_concept_art.jpg)
*Figura: Concept Art canônico do robô cortador (Cutter Bit) demonstrando a aplicação dos materiais foscos, cores da carcaça amarela, placas brancas, lâmina de aço e sensores ciano emissivos.*

| Elemento | Código HEX / Cor | Amostra | Função no Jogo |
| :--- | :--- | :--- | :--- |
| **Grama Verde Esmeralda** | `#4DB352` / `#2E6B35` | 🟢 Verde Suave Pastel (20% mais pálida / desaturada) | Vegetação comum fundamental presente em todos os estágios; tom calmo para contraste com as flores. |
| **Grama Amarela Solar** | `#FFB83D` / `#A67326` | 🟡 Dourado Solar Pastel | Variação estética cosmética (1 golpe). |
| **Grama Azul Celeste** | `#3D9CF2` / `#24599E` | 🔵 Azul Ciano Pastel | Grama de bioma costeiro/aquático. |
| **Grama Roxa Mística** | `#9E47EB` / `#59268C` | 🟣 Roxo Místico Pastel | Grama de bioma noturno e labirintos avançados. |
| **Grama Branca Algodão** | `#F7FAFF` / `#B3BAC7` | ⚪ Branco Fosco Suave | Grama especial de contraste e destaque. |
| **Grama Vermelha Rubi** | `#F25459` / `#85262B` | 🔴 Vermelho Pastel Suave | Variação calma para zonas quentes. |
| **Grama Preta Vulcânica** | `#1C1C21` / `#0D0D10` | ⚫ Grafite Escuro | Grama estilizada para cenários dramáticos. |
| **Piso Aparado (Cortado)** | `#2E6930` / `#1B5E20` | 🟩 Verde Profundo | Revelado após a passagem da serra (sensação de gramado limpo). |
| **Trigo Maduro (Meta 2x)** | `#FFA000` / `#FFB300` | 🌾 Dourado Ouro | Vegetação resistente de 2 golpes com maior valor e cota. |
| **Flores do Campo (Nobre)** | `#E91E63` / `#C2185B` | 🌸 Magenta Vibrante | Vegetação nobre de alto valor econômico (5 moedas). |
| **Carcaça do Robô** | `#F5A623` / `#F7A81B` | 🟨 Amarelo Industrial | Carcaça externa em ABS/Policarbonato (cabeça, paralamas, deck). |
| **Blindagem e Estrutura** | `#E8ECEF` / `#F0F3F6` | ⚪ Branco Metal | Placas protetoras superiores parafusadas e estrutura central. |
| **Pneu Mono-Wheel & Viseira** | `#141416` / `#0D0E10` | ⬛ Preto Profundo | Pneu com cravos, máscara frontal dos olhos, grelhas e calha da serra. |
| **Lâminas e Pistões** | `#CBD3DC` / `#B0BEC5` | ⚙️ Aço Temperado | Rotor de alta rotação e hastes dos pistões de suspensão. |
| **Parafusos e Acabamento** | `#F2C738` / `#FFD54F` | 🟡 Ouro / Titânio | Anel de parafusos da roda e lâminas avançadas da loja. |
| **Sensores & Visor de LED** | `#18D8F0` / `#00E5FF` | 🔵 Ciano Emissivo | Expressões faciais dinâmicas com scanlines. |
| **Rochas / Obstáculos** | `#546E7A` / `#455A64` | 🪨 Cinza Ardósia | Indica bloqueio físico imediato e risco de choque. |
| **Oceano Toon (Wind Waker)** | `#2EA6D1` / `#1485BF` | 🌊 Azul Turquesa | Shader procedural estilizado com reflexos suaves. |
| **Espuma Costeira 2D** | `#E0FAFF` / `#FFFFFF` | ⚪ Espuma Ciano | Fita geométrica com balanço de maré na beira das falésias. |
| **Céu / Fundo** | `#B3E5FC` / `#81D4FA` | 🟦 Azul Pastel Suave | Fundo limpo que não distrai os olhos durante a partida. |

---

## 3. Iluminação e Renderização

- **DirectionalLight3D (Sol Canônico):**
  - Posicionada em ângulo zenital calibrado (`pitch = -37.0°`, `yaw = 40.0°`, `roll = 0.0°`), vetor de direção frontal `(-0.513, -0.602, -0.612)`.
  - Energia da luz calibrada em `1.30` com tom solar suave (`#FFFDE7`).
  - Sombras projetadas ativadas (`shadow_enabled = true`) em modo ortogonal (`SHADOW_ORTHOGONAL`) com distância máxima de $28.0\text{m}$, mapa $1024 \times 1024$ e filtro rápido, garantindo 60 FPS cravados no mobile.
  - As malhas de vegetação operam com `cast_shadow = SHADOW_CASTING_SETTING_OFF` (mantendo sombras nítidas exclusivamente no robô, rochas e falésias da ilha), reduzindo drasticamente as primitivas de renderização.
- **WorldEnvironment:**
  - `background_mode = 1` (Clear Color) com cor de céu tropical suave.
  - Luz ambiente com coloração pastel esverdeada (`#E8F5E9`) e intensidade `0.20`, garantindo alto contraste estilizado de cel shading sem estourar as cores.
  - Tonemap em modo ACES/Filmic para realce das cores vivas sem estourar os brancos.
- **IsometricCamera (Câmera Canônica):**
  - Orientação isométrica travada em `pitch = -40.3°` (`Vector3(-40.3, 0.0, 0.0)`), distância focal `7.40m` (`offset = Vector3(0.0, 4.78, 5.65)`).
- **Vegetação (Toon Shader Gradiente Canônico):**
  - `color_light = Color(0.42, 0.88, 0.46)` (Grama verde) / Paletas dedicadas para Amarela, Azul, Roxa, Branca, Vermelha, Preta e Trigo
  - `color_base = Color(0.10, 0.30, 0.15)`
  - `color_shadow = Color(0.18, 0.50, 0.25)`
  - `rim_color = Color(0.85, 1.00, 0.65)`
  - `toon_ramp_offset = 0.50`
  - `toon_ramp_smoothness = 0.28`
  - `vertical_gradient_mix = 0.85`
  - `use_rim = false`
  - `roughness = 0.90`
- **Solo da Ilha (Island Ground Canônico):**
  - `ground_color = Color(0.14, 0.45, 0.19)`
  - `ground_brightness = 0.80` (Cor final albedo: `Color(0.112, 0.360, 0.152)`)
  - `ground_diffuse_toon = true` (`diffuse_mode = BaseMaterial3D.DIFFUSE_TOON`)
  - Falésias / Paredes verticais: `CLIFF_COLOR = Color(0.4667, 0.2431, 0.1451)`
  - Malha procedural com cores assadas por vértice (`vertex_color_use_as_albedo = true`), eliminando amostragem de textura e garantindo 60 FPS no mobile.

---

## 4. Efeitos Visuais (VFX)

1. **Partículas de Corte da Vegetação (`cut_leaf_piece.obj`):**
   - Emitidas no ponto de contato radial da lâmina via pool estático de 16 emissores compartilhados (`CPUParticles3D`).
   - Cada disparo ejeta **21 fragmentos estilizados de folhas partidas** distribuídas por anel de $0.18\text{m}$ de raio.
   - Os pedaços possuem cor sincronizada ao topo da espécie ceifada e giram no ar em 3D sob gravidade natural ($-9.8\text{ m/s}^2$) durante $0.55\text{s}$, simulando folhas recém-fatiadas voando em arco parabólico.

2. **Aparas Cortadas Deitadas no Solo (Clippings MultiMesh):**
   - No ponto do corte, surge uma composição de 6 lâminas de folhas caídas horizontalmente no solo ($Y \approx 0.005\text{m}$) com tom mais escuro e orientações aleatórias em $360^\circ$, criando o rastro visual de grama aparada.

3. **Números Flutuantes Cartoon 3D de Colheita (`FloatingCoinManager`):**
   - Textos estilizados 3D cel-shaded (`+1` em branco puro para grama comum, `+3` em ouro para trigo, `+5` em rosa para flores).
   - Tipografia bold com **contorno preto sólido de 14px**, sombra desativada e animação rápida de pop-in (escala de 0.5x para 1.35x e acomodação em 1.0x), flutuando suavemente para cima com fade-out rápido (duração total de $0.34\text{s}$) para não poluir o campo de visão.

4. **Faíscas de Choque Mecânico (`SparkParticles`):**
   - Ejetadas da lâmina no ponto exato de colisão contra rochas sólidas (`CPUParticles3D` amarelas/alaranjadas em cone fechado com gravidade e rebote).

5. **Teleporte Estilizado no Mapa (`teleport_effect.gdshader`):**
   - Efeito de feixe turquesa com ruído de dissolução vertical ao transitar entre as ilhas na visualização do mapa overworld.
