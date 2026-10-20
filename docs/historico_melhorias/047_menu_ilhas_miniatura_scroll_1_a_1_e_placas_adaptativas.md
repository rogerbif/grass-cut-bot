# Melhoria 047: Ilhas em Miniatura Fiéis via JSON, Drag Scroll 1:1 e Placas Adaptativas no Menu Inicial 🏝️📱

> **Versão:** `v0.7.9-alpha`  
> **Data:** 20/10/2026  
> **Status:** Concluído com Êxito (0 Warnings / 0 Erros no Godot 4.7)  
> **Domínios:** Menu Inicial, UI/UX Mobile, Renderização 3D, Interação Touch  

---

## 🎯 1. Visão Geral e Objetivos

Esta melhoria refinou expressivamente a experiência visual e a usabilidade do Menu Inicial / Overworld Map (`res://scenes/menu/main_menu.tscn`), trazendo três pilares fundamentais:
1. **Ilhas em Miniatura Fiéis via JSON:** Cada uma das 20 ilhas do arquipélago 3D agora lê a matriz real de tiles do respectivo arquivo `data/levels/level_XX.json` e instancia os modelos 3D canônicos (`tile_island_center`, `edge`, `corner_out`, `corner_in`, etc.) a uma escala reduzida de $0.38\times$, substituindo os blocos prismáticos genéricos anteriores por reproduções idênticas às fases jogáveis.
2. **Rolagem Touch/Mouse 1:1 Rigorosa:** A velocidade do arrasto foi geometricamente unificada com o plano do solo ($Y=0$) através de raios de câmera (`project_ray_origin` / `project_ray_normal`), fazendo com que o terreno sob o dedo acompanhe com precisão milimétrica o movimento do toque em qualquer resolução. Além disso, foram preservados gestos de swipe rápido (flick) para avançar/voltar de fase e snap magnético inteligente.
3. **Placa Informativa Adaptativa:** A placa de madeira com o número do estágio e as estrelas (⭐) adapta sua pose e orientação conforme o modo de câmera ativo:
   - **Na Visão Mapa (`MAP_VIEW`):** A placa repousa deitada sobre o solo da ilha, inclinada em $-58^\circ$ (perpendicular ao vetor focal da câmera aérea), permitindo leitura límpida sem obstruir a visão da geometria do mapa.
   - **Na Visão Robô (`BOT_VIEW`):** A placa ergue-se em pé através de sua estaca fincada no chão, posicionada à frente e à esquerda do robô (`x = -1.15m`, `z = 0.85m`, rotação $15^\circ$), criando uma composição de diorama tridimensional orgânica.

---

## 🛠️ 2. Implementações Técnicas Detalhadas

### 2.1 Reconstrução Dinâmica das Miniaturas das Ilhas (`scripts/menu/island_node.gd`)
- Implementado o método `build_miniature_from_json(lvl: int)`:
  - Carrega dinamicamente o arquivo `data/levels/level_XX.json`.
  - Percorre a matriz de grade (`grid.width`, `grid.height`), centralizando a geometria no ponto focal da ilha.
  - Carrega e instancia as malhas `.glb` correspondentes aos códigos de tiles (`tile_island_center`, `tile_island_edge`, `tile_island_corner_out`, `tile_island_corner_in`, `tile_island_end`, `tile_island_dirt`) com sua respectiva rotação angular `rot_y_deg`.
  - Aplica escala uniforme de $0.38\times$ e espaçamento entre tiles de $0.80\text{m} \times 0.38 = 0.304\text{m}$.
  - Desativa o mesh de fallback quadrado quando os tiles são gerados com sucesso.
  - Otimização mobile: modelos instanciados diretamente sem colisores de física desnecessários, mantendo 60 FPS e baixo draw call count.

### 2.2 Cinemática da Placa Adaptativa (`scripts/menu/island_node.gd` & `scenes/menu/island_node.tscn`)
- Estruturação do nó `Plaque` com `PostMesh` (estaca de madeira), `BoardMesh` (tábua marrom), `LevelLabel` (texto branco da fase) e `StarsLabel` (estrelas amarelas/cinza).
- Implementado `set_view_mode(is_map_view: bool, is_active: bool, animated: bool)`:
  - **Modo Mapa:** `Plaque.position = Vector3(0.0, 0.08, 0.45)`, `Plaque.rotation_degrees = Vector3(-58.0, 0.0, 0.0)`, `PostMesh.visible = false`.
  - **Modo Bot:** `Plaque.position = Vector3(-1.15, 0.0, 0.85)`, `Plaque.rotation_degrees = Vector3(0.0, 15.0, 0.0)`, `PostMesh.visible = true`.
  - Interpolação suave via `Tween` (`TRANS_QUAD`, `EASE_OUT`) quando animado na transição de câmera.

### 2.3 Calibração 1:1 do Drag Scroll e Flick Gestural (`scripts/menu/menu_camera.gd`)
- Substituída a sensibilidade empírica anterior por cálculo trigonométrico exato no plano $Y=0$:
  ```gdscript
  func get_pixel_to_ground_ratio() -> float:
      var v_size: Vector2 = get_viewport().get_visible_rect().size
      var ray_center: Vector3 = project_ray_origin(v_size * 0.5)
      var dir_center: Vector3 = project_ray_normal(v_size * 0.5)
      # Interseção com plano Y = 0
      var t1: float = -ray_center.y / dir_center.y
      var p1: Vector3 = ray_center + dir_center * t1
      
      var offset_y: float = 100.0
      var ray_offset: Vector3 = project_ray_origin(Vector2(v_size.x * 0.5, v_size.y * 0.5 + offset_y))
      var dir_offset: Vector3 = project_ray_normal(Vector2(v_size.x * 0.5, v_size.y * 0.5 + offset_y))
      var t2: float = -ray_offset.y / dir_offset.y
      var p2: Vector3 = ray_offset + dir_offset * t2
      
      return abs(p2.z - p1.z) / offset_y
  ```
- No evento `InputEventScreenDrag` / `InputEventMouseMotion`:
  - `delta_z = -event.relative.y * ratio`
  - A velocidade do terreno coincide perfeitamente com a ponta do dedo do jogador.
- Implementado threshold de velocidade para detecção de gestos de *flick/swipe* (`swipe_velocity_threshold = 6.0`):
  - Soltura rápida para cima: avança para a próxima fase (`snap_to_level(current + 1)`).
  - Soltura rápida para baixo: retorna para a fase anterior (`snap_to_level(current - 1)`).
  - Soltura lenta: realiza snap magnético suave para a ilha mais próxima.
  - Emite sinal `island_snapped(level_idx)` para atualizar o botão `JOGAR - Fase X` no menu principal.

---

## 🧪 3. Validação e Qualidade de Código

- **Zero Warnings / Zero Errors:** Executado via MCP do Godot Engine v4.7.1. Output limpo sem avisos nem erros.
- **Performance:** As 20 miniaturas renderizam de forma fluida sem afetar os 60 FPS em taxa de quadros mobile.
- **Game SemVer:** Atualizado para `v0.7.9-alpha` em `project.godot` e `export_presets.cfg`.
