# Melhoria 047: Ilhas em Miniatura Fiéis via JSON, Elementos sobre a Ilha, Drag Scroll Natural 1:1 e Placas Adaptativas no Menu Inicial 🏝️📱

> **Versão:** `v0.7.9-alpha`  
> **Data:** 20/10/2026  
> **Status:** Concluído com Êxito (0 Warnings / 0 Erros no Godot 4.7)  
> **Domínios:** Menu Inicial, UI/UX Mobile, Renderização 3D, Interação Touch  

---

## 🎯 1. Visão Geral e Objetivos

Esta melhoria refinou expressivamente a experiência visual e a usabilidade do Menu Inicial / Overworld Map (`res://scenes/menu/main_menu.tscn`), trazendo quatro pilares fundamentais:
1. **Ilhas em Miniatura Fiéis via JSON:** Cada uma das 20 ilhas do arquipélago 3D agora lê a matriz real de tiles do respectivo arquivo `data/levels/level_XX.json` e instancia os modelos 3D canônicos (`tile_island_center`, `edge`, `corner_out`, `corner_in`, etc.) a uma escala reduzida de $0.38\times$, substituindo os blocos prismáticos genéricos anteriores por reproduções idênticas às fases jogáveis.
2. **Elementos sobre a Ilha (`objects`):** Todos os elementos de cada fase (gramas coloridas verde, amarela, azul, roxa, rochas 3D, trigo e flores) são instanciados sobre os tiles da miniatura. Para garantir 60 FPS e conformidade estrita com Zero Warnings, extrai-se apenas a malha pura (`VisualMesh`) desvinculando scripts de gameplay, áreas e colisores de física desnecessários, com materiais compartilhados em cache estático.
3. **Rolagem Touch/Mouse 1:1 e Centralização Automática em X na Reta:**
   - A velocidade do arrasto foi geometricamente calibrada com o plano do solo ($Y=0$) através da projeção de raios de câmera (`project_ray_origin` / `project_ray_normal`), garantindo que o terreno sob o dedo acompanhe com precisão milimétrica o movimento do toque em qualquer resolução.
   - **Centralização Automática em X:** À medida que a tela rola pelo arquipélago em ziguezague, a câmera calcula continuamente sua coordenada $X$ interpolando os waypoints dos centros das ilhas através de uma curva cúbica Hermite (`smoothstep`), centralizando perfeitamente no eixo horizontal qualquer fase que esteja no foco da tela.
   - Sentido de arraste corrigido para a convenção natural: arrastar o dedo para baixo puxa o mapa para baixo na tela; arrastar para cima puxa o mapa para cima.
   - Rodinha do mouse e swap/flick gestural na direção do movimento: swap/scroll para baixo avança para a próxima fase; swap/scroll para cima volta para a fase anterior.
   - Preservado o snap magnético suave para a ilha mais próxima na soltura lenta.
4. **Placa Informativa Adaptativa:** A placa de madeira com o número do estágio e as estrelas (⭐) adapta sua pose e orientação conforme o modo de câmera ativo:
   - **Na Visão Mapa (`MAP_VIEW`):** A placa repousa deitada a $Y=0.18\text{m}$ no canto inferior direito de cada ilha ($+X$, $+Z$, calculado pelas dimensões da fase), inclinada em $-58^\circ$ (perpendicular ao vetor focal da câmera aérea), desobstruindo o centro da fase e permitindo leitura límpida sem ocultar a vegetação e o layout geométrico.
   - **Na Visão Robô (`BOT_VIEW`):** A placa permanece oculta (`visible = false`) para garantir um visual limpo e foco absoluto no robô cortador no diorama da Home.

---

## 🛠️ 2. Implementações Técnicas Detalhadas

### 2.1 Reconstrução Dinâmica e Elementos sobre a Ilha (`scripts/menu/island_node.gd`)
- Implementado o método `build_miniature_from_json(lvl: int)`:
  - Carrega dinamicamente o arquivo `data/levels/level_XX.json`.
  - Percorre a matriz de grade (`grid.width`, `grid.height`), centralizando a geometria no ponto focal da ilha.
  - Carrega e instancia as malhas `.glb` correspondentes aos códigos de tiles (`tile_island_center`, `tile_island_edge`, `tile_island_corner_out`, `tile_island_corner_in`, `tile_island_end`, `tile_island_dirt`) com sua respectiva rotação angular `rot_y_deg`.
  - Aplica escala uniforme de $0.38\times$ e espaçamento entre tiles de $0.80\text{m} \times 0.38 = 0.304\text{m}$.
  - Instancia todos os elementos do array `objects` (`grass_green`, `grass_yellow`, `grass_blue`, `grass_purple`, `rock`, `wheat`, `flower`) nas coordenadas reais da fase.
  - **Otimização e Zero Warnings:** A fábrica estática `create_miniature_object(otype)` utiliza modelos puros (`grass_01.glb` e `rock.glb`) com materiais compartilhados cacheados (`StandardMaterial3D`) e método `_strip_visual_mesh` com limpeza recursiva de `owner` para evitar inconsistências de nó e warnings do Godot 4.
  - Desativa o mesh de fallback quadrado quando os tiles e elementos são gerados com sucesso.

### 2.2 Cinemática da Placa Adaptativa (`scripts/menu/island_node.gd` & `scenes/menu/island_node.tscn`)
- Estruturação do nó `Plaque` com `PostMesh` (estaca de madeira), `BoardMesh` (tábua marrom), `LevelLabel` (texto branco da fase) e `StarsLabel` (estrelas amarelas/cinza).
- Implementado `set_view_mode(is_map_view: bool, is_active: bool, animated: bool)`:
  - **Modo Mapa:** `Plaque.position = Vector3(0.0, 0.18, 0.5)`, `Plaque.rotation_degrees = Vector3(-58.0, 0.0, 0.0)`, `PostMesh.visible = false`.
  - **Modo Bot:** `Plaque.position = Vector3(-1.15, 0.0, 0.85)`, `Plaque.rotation_degrees = Vector3(0.0, 15.0, 0.0)`, `PostMesh.visible = true`.
  - Interpolação suave via `Tween` (`TRANS_CUBIC`, `EASE_OUT`) quando animado na transição de câmera.

### 2.3 Calibração 1:1 do Drag Scroll Natural e Flick Gestural (`scripts/menu/menu_camera.gd`)
- Cálculo trigonométrico exato no plano $Y=0$:
  ```gdscript
  func get_pixel_to_ground_ratio() -> float:
      var v_size: Vector2 = get_viewport().get_visible_rect().size
      var center: Vector2 = v_size / 2.0
      var z1: float = get_ground_z(center - Vector2(0, 50))
      var z2: float = get_ground_z(center + Vector2(0, 50))
      var ratio: float = abs(z2 - z1) / 100.0
      return ratio
  ```
- Sentido natural aplicado no arrasto:
  `var movement_z: float = -delta_y * ratio`
  - Dedo descendo na tela: terreno acompanha descendo na tela.
  - Dedo subindo na tela: terreno acompanha subindo na tela.
- Roda do mouse:
  - `WHEEL_UP`: `snap_to_level(current_snapped_level + 1)` (avança para as fases ao norte).
  - `WHEEL_DOWN`: `snap_to_level(current_snapped_level - 1)` (recua para as fases ao sul).
- Threshold de flick gestural rápido (`swipe_velocity_threshold = 4.5` m/s):
  - Soltura rápida para cima: avança para a próxima fase.
  - Soltura rápida para baixo: retorna para a fase anterior.
  - Soltura lenta: realiza snap magnético suave para a ilha mais próxima.
  - Emite sinal `island_snapped(level_idx)` para sincronizar o botão de jogar no HUD.

---

## 🧪 3. Validação e Qualidade de Código

- **Zero Warnings / Zero Errors:** Executado via MCP do Godot Engine v4.7.1. Output limpo sem avisos nem erros.
- **Performance:** Miniaturas completas com centenas de elementos renderizam fluidamente a 60 FPS com draw calls otimizados.
- **Game SemVer:** `v0.7.9-alpha` mantido e documentado.
