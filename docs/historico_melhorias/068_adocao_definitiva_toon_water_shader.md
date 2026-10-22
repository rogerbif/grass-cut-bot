# Histórico de Melhoria: Adoção Definitiva do Toon Water Shader e Calibração Fina 🌊✨

**ID:** `068_adocao_definitiva_toon_water_shader`  
**Versão:** `v0.10.5-alpha`  
**Data:** 21/10/2026  
**Status:** Concluído e Validado (0 Warnings no Godot 4.7.1)  

---

## 1. Contexto

Após a avaliação de múltiplos estilos visuais para a água (procedural pura com círculos senoidais, shader 2D Wind Waker, e shader com ruído fractal), foi testado e aprovado em definitivo o clássico **Toon Water Shader** (inspirado no trabalho canônico de Erik Roystan Ross e Heverton Gouveia).

O shader foi portado para Godot 4 Spatial, integrando:
1. Reconstrução linear de profundidade do Viewport (`INV_PROJECTION_MATRIX`).
2. Atenuação exponencial da luz (Beer-Lambert Law) para gradação entre água rasa e profunda.
3. Geração orgânica de espuma costeira no contato da água com a costa das ilhas e objetos.
4. Texturas duplas (`PerlinNoise.png` e `WaterDistortion.png`) para correnteza dinâmica e ondulação.
5. Coordenadas de mundo ($XZ$) para estabilidade e consistência perfeita no oceano infinito.

Todos os shaders alternativos temporários foram completamente eliminados do repositório, consolidando uma arquitetura limpa e unificada.

---

## 2. Parâmetros Oficiais Calibrados (`shaders/toon_water_material.tres`)

Os seguintes valores aprovados foram gravados no material mestre unificado:

| Parâmetro | Valor | Efeito no Jogo |
| :--- | :--- | :--- |
| `world_scale` | `0.280` | Escala perfeita dos veios d'água em relação às ilhas e ao robô. |
| `beer_factor` | `1.40` | Transição natural da translucidez rasa até o azul marinho profundo. |
| `surface_noise_cutoff` | `0.520` | Espessura equilibrada dos filetes brancos de espuma na correnteza. |
| `surface_distortion_amount` | `0.34` | Curvatura orgânica e fluida das ondas sem quebras. |
| `surface_noise_scroll` | `Vector3(0.040, 0.040, 0.0)` | Deslizamento suave e constante da correnteza do mar. |
| `foam_max_distance` | `0.72` | Alcance e presença marcante da espuma onde a água toca os penhascos da ilha. |
| `roughness` | `0.48` | Acabamento fosco arcade acetinado, respeitando o estilo Low Poly. |
| `use_world_coords` | `true` | Coordenadas mundiais $XZ$ (padrão estável sem distorção por escala de malha). |
| `_DepthGradientShallow` | `Color(0.180, 0.650, 0.820, 1.0)` | Azul turquesa tropical cristalino nas margens (#2ea6d1). |
| `_DepthGradientDeep` | `Color(0.084, 0.520, 0.743, 1.0)` | Azul marinho profundo com alto contraste (#1585bd). |
| `foam_color` | `Color(0.880, 0.980, 1.000, 1.0)` | Espuma quase branca com sutil toque ciano (#e0faff). |

---

## 3. Arquivos Consolidados e Higienização

- **Oficiais mantidos:**
  - `assets/textures/water/PerlinNoise.png` e `assets/textures/water/WaterDistortion.png`
  - `shaders/toon_water.gdshader` (shader oficial mestre)
  - `shaders/toon_water_material.tres` (material oficial com texturas e parâmetros)
  - `scenes/level/water_ocean.tscn` (atualizado para o material oficial)
  - `scenes/menu/main_menu.tscn` (atualizado para o material oficial)
  - `scenes/tools/water_tuner.tscn` e `scripts/tools/water_tuner.gd` (sintonizador oficial atualizado para o novo shader)
- **Eliminados definitivamente:**
  - Shaders e materiais legados/temporários (`wind_waker_water.*`, `nekoto_wind_waker_*`, `roystan_water_tuner.*`).

---

## 4. Validação e Testes

- Executados testes de execução com o Godot MCP Debug Runner:
  - `scenes/menu/main_menu.tscn`: Aprovado com **0 warnings e 0 erros**.
  - `scenes/main.tscn`: Aprovado com **0 warnings e 0 erros**.
  - `scenes/tools/water_tuner.tscn`: Aprovado com **0 warnings e 0 erros**.
