# Melhoria 048: Escala Real das Ilhas (1:1), Robô Fiel ao Gameplay (0.62x) e Enquadramento Adaptativo por Fase no Menu Inicial 🗺️🌿🤖

**Data:** 2026-10-20  
**Versão:** `v0.7.10-alpha`  
**Autor:** Antigravity (Advanced Agentic Coding)  
**Status:** Concluído com Sucesso e Validado (0 Warnings / 0 Erros)  

---

## 1. Contexto e Motivação

No Menu Inicial (`res://scenes/menu/main_menu.tscn`), as ilhas do arquipélago 3D eram geradas anteriormente como miniaturas em escala $0.38\times$, enquanto o robô cortador no diorama da Home era instanciado em escala $0.70\times$. Isso causava uma evidente discrepância estética:
1. O robô parecia grande e desproporcional em relação às ilhas, vegetação e pedras.
2. Não havia equivalência física 1:1 entre o mundo visto no mapa e o mundo jogado durante o gameplay.
3. Na visão de mapa aéreo (`MAP_VIEW`), a câmera mantinha uma altura fixa arbitrária, não se adaptando às diferentes dimensões e extensões de cada uma das 20 fases canônicas nem garantindo o enquadramento ideal de cada ilha no centro da tela portrait (9:16).

---

## 2. Decisões Arquiteturais e Execução Técnica

### 2.1 Equalização de Escala Física Real (1:1 Ilhas, 0.62x Robô)
- **Ilhas Canônicas (`scripts/menu/island_node.gd` & `island_node.tscn`):**
  - O `miniature_container` passa a operar em escala real `Vector3(1.0, 1.0, 1.0)`.
  - As dimensões métricas da ilha em metros são expostas via `get_island_dimensions() -> Vector2`.
  - A `ClickArea` e seu colisor `BoxShape3D_click` foram ampliados de $6.0 \times 1.5 \times 5.0\text{m}$ para $14.0 \times 2.0 \times 12.0\text{m}$, cobrindo a extensão completa da ilha na escala real.
  - O `BotAnchor` foi calibrado para $Y = -0.052\text{m}$, assentando as rodas do robô precisamente sobre a superfície do solo em $Y = 0.0\text{m}$.
  - A placa de fase foi redimensionada proporcionalmente (postes e placa de madeira) e reposicionada no canto inferior direito da ilha ($+X$, $+Z$) na cota $Y = 0.25\text{m}$, com inclinação de $-58^\circ$, ficando perfeitamente perpendicular à linha de visão da câmera aérea e desobstruindo o centro do cenário.

- **Robô Cortador no Menu (`scenes/menu/menu_bot.tscn` & `menu_bot.gd`):**
  - O `VisualPivot` foi configurado na escala canônica de gameplay: `scale = Vector3(0.62, 0.62, 0.62)`.
  - O raio efetivo da roda no script foi atualizado para `effective_wheel_radius = 0.45 * 0.62 \approx 0.279\text{m}`, mantendo o cálculo físico de rolagem da mono-wheel rigorosamente livre de patinagem ao se mover.

### 2.2 Reorganização do Arquipélago e Espaçamento de Navegação (`scripts/menu/main_menu.gd`)
- O espaçamento longitudinal entre fases foi reajustado de $8.0\text{m}$ para $z\_spacing = 18.5\text{m}$, proporcional à extensão das ilhas de $\sim 10\text{m}$ a $14\text{m}$ e proporcionando oceanos abertos limpos e respiração visual tropical.
- As amplitudes de ziguezague em $X$ foram ampliadas para $+5.5\text{m}$ (fases pares) e $-5.0\text{m}$ (fases ímpares), mantendo a Fase 1 centralizada em $X = 0.0$.
- O arquipélago terminal de nuvens 3D (`clouds_end`) foi expandido para escala $2.5\times$ e reposicionado para $current\_z - 16.0\text{m}$.
- Os waypoints de posição e dimensões de todas as ilhas são coletados e transmitidos para o controlador de câmera via `menu_camera.set_island_waypoints(waypoints, dimensions)`.

### 2.3 Enquadramento Adaptativo Dinâmico por Fase (`scripts/menu/menu_camera.gd`)
- **Cálculo Trigonométrico de Altitude e Offset:**
  - A altura da câmera é computada dinamicamente para cada ilha por:
    $$Y_{\text{target}} = \text{clamp}(\max(W \times 1.65, H \times 1.25) \times 1.45, 25.0, 36.0)$$
  - O offset de mira em $Z$ é derivado geometricamente da inclinação da câmera ($\theta = 58^\circ$):
    $$\Delta Z = \frac{Y}{\tan(58^\circ)}$$
    garantindo que a linha central de visão da câmera atinja exatamente o ponto $(X_{\text{ilha}}, 0, Z_{\text{ilha}})$.
  - A transição de altitude e centralização horizontal ao longo do scroll utiliza interpolação cúbica Hermite (`smoothstep`), gerando curvas de movimento totalmente fluidas tanto durante o arraste touch quanto nos encaixes magnéticos (snaps).
- **Visão Bot na Home:**
  - Câmera em close-up com `bot_offset = Vector3(0, 1.25, 4.0)` e `bot_pitch_deg = -8.0`, oferecendo ângulo de visão imersivo e acolhedor do robô de corpo inteiro no solo da ilha inicial.

---

## 3. Arquivos Modificados / Criados

- [`scenes/menu/island_node.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/menu/island_node.tscn)
- [`scripts/menu/island_node.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/menu/island_node.gd)
- [`scenes/menu/menu_bot.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/menu/menu_bot.tscn)
- [`scripts/menu/menu_bot.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/menu/menu_bot.gd)
- [`scripts/menu/main_menu.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/menu/main_menu.gd)
- [`scripts/menu/menu_camera.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/menu/menu_camera.gd)
- [`scripts/core/game_version.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/core/game_version.gd)
- [`project.godot`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/project.godot)
- [`docs/04_sistemas_e_gameplay/SISTEMA_DE_INTERFACE_HUD.md`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/docs/04_sistemas_e_gameplay/SISTEMA_DE_INTERFACE_HUD.md)
- [`docs/historico_melhorias/INDICE_MELHORIAS.md`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/docs/historico_melhorias/INDICE_MELHORIAS.md)

---

## 4. Validação e Qualidade

- **Execução Godot 4:** Executado via MCP `run_project` e monitorado via `get_debug_output`.
- **Zero Warnings / Zero Erros:** Console do motor permanece com 0 warnings e 0 erros.
- **Game SemVer:** Atualizado de `v0.7.9-alpha` para `v0.7.10-alpha`.
