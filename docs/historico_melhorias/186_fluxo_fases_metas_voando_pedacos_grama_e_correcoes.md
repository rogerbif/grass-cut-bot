# Melhoria 186: Fluxo de Fases, Ícones Voando de Metas, Pedaços 3D de Grama e Correções Gerais (`v0.12.136-alpha`) 🌿✨

## 1. Resumo Executivo
Esta melhoria implementa um conjunto de 5 refinamentos fundamentais de jogabilidade, fluxo e Game Feel solicitados pelo usuário, além da correção da transição da Fase 20:
1. **Posicionamento Automático na Próxima Fase:** Ao concluir uma fase e retornar para a Home (seja pelo botão "Menu" no modal de vitória ou pelo botão voltar), o arquipélago 3D agora inicializa focado diretamente na **próxima fase após a última concluída** (robô, câmera e card de fase já posicionados).
2. **Correção da Fase 20 (Ciclo Mestre):** Eliminada a trava hardcoded (`>= 20`) no `HUD`. A Fase 20 agora avança normalmente para a Fase 21, reservando o título de Campeão e "Ciclo Mestre" exclusivamente para a vitória na Fase 40 (última fase do Mundo 1).
3. **Efeito Visual do Ícone de Meta Voando até o HUD:** Ao cortar qualquer planta que seja meta ativa da fase, além dos números flutuantes de moedas, um ícone 2D compacto com borda branca externa nasce na posição de tela projetada (`camera.unproject_position`) e voa em curva suave (Bézier quadrática) até o card da meta no TopBar, disparando um punch de escala de absorção elástica no badge.
4. **Borda Branca Externa no Ícone do Objetivo:** Criação do shader de outline 2D `shaders/goal_icon_outline.gdshader` integrado via `GoalIconFactory.build_goal_icon()`, conferindo acabamento sticker cartoon com contraste impecável.
5. **Pedaços 3D de Corte de Grama e Auditoria Universal de Flores:** 
   - A grama agora emite pedaços 3D chanfrados de folhas com vinco dorsal (`cut_leaf_piece.obj` / SurfaceTool 3D blade) em vez de quadradinhos planos genéricos.
   - Resolução universal de espécies em `PlantScript._resolve_flower_base_type()`, garantindo que todas as 8 espécies e todas as variantes de flores (Margaridas, Rosas, Tulipas, etc.) disparem suas respectivas pétalas 3D desprendíveis tanto no primeiro hit quanto no golpe final.
6. **Correção do Upgrade da Lâmina no Centro do Mapa:** No método `Cutter._trigger_level_up_effects()`, a posição global do nó desacoplado `spark_particles` agora é explicitamente sincronizada com o robô (`global_position + Vector3(0, 0.45, 0)`) antes do disparo, eliminando o estouro incorreto no centro da ilha `(0, 0, 0)`.

---

## 2. Detalhes de Implementação

### A. Fluxo de Fases e Resolução do SaveGame
- **Diagnóstico da Sobrescrita:** No `SaveManager.save_game()`, a instrução `pl["last_played_level"] = GameManager.current_level` sobrescrevia o avanço realizado por `record_level_victory()`.
- **Correção:** Modificado para `pl["last_played_level"] = maxi(cur_last, GameManager.current_level)`. Ao vencer, o `last_played_level` avança para `completed_lvl + 1`. Na Home (`main_menu.gd`), a leitura de `SaveManager.get_last_played_level()` posiciona o robô e enquadra a câmera diretamente na nova fase.
- **Detecção Dinâmica de Fases:** Criado `GameManager.get_total_levels() -> int`, computando as 40 fases do Mundo 1. O teste no modal de vitória foi ajustado para `GameManager.current_level >= total_lvls`.

### B. Feedback de Metas com Voo de Ícone 2D
- **Sinal Dedicado:** Criado `GameManager.signal goal_item_collected(plant_type: String, world_pos: Vector3)`.
- **Projeção de Mundo para Tela:** O `HUD` converte a coordenada 3D via `cam.unproject_position(world_pos)`.
- **Trajetória e Juiciness:** Pop elástico inicial de surgimento ($0.25 \to 1.28$), voo em arco quadrático de Bézier de $0.44\text{s}$ até o centro do card da meta, seguido de absorção e punch scale ($1.22 \to 1.0$) no badge da TopBar.
- **Proteção de Performance Mobile:** Limitador de cadência de $55\text{ms}$ por objetivo para garantir 60 FPS inabaláveis.

### C. Shader de Contorno Externo Branco Puro (`shaders/goal_icon_outline.gdshader`)
- Shader de `canvas_item` com amostragem ortogonal e diagonal em 8 direções para detecção de silhueta.
- Integrado na fábrica estática `GoalIconFactory.build_goal_icon(plant_type, size, with_outline)`.

### D. Pedaços 3D de Grama e Flores
- `Plant._ensure_particle_meshes()`: Integra a malha 3D chanfrada `cut_leaf_piece.obj` (5 vértices, vinco e faces duplas) e pontas afiladas `_grass_blade_tip_mesh`.
- `Plant._resolve_flower_base_type()`: Resolução limpa de todas as espécies e colorways.
- `VegetationGrid`: Disparo garantido de `PlantScript.spawn_flower_detach_pieces()` no corte final de flores.

### E. Posicionamento de Partículas no Level Up da Lâmina
- Em `Cutter._trigger_level_up_effects()`, atualização de `spark_particles.global_position = global_position + Vector3(0.0, 0.45, 0.0)` com `reset_physics_interpolation()`.

---

## 3. Arquivos Modificados e Criados

| Arquivo | Natureza da Alteração |
| :--- | :--- |
| `shaders/goal_icon_outline.gdshader` | Novo shader 2D de contorno branco puro para ícones de objetivos |
| `scripts/ui/goal_icon_factory.gd` | Aplicação do material de outline em ícones botânicos |
| `scripts/core/game_manager.gd` | Total dinâmico de fases (`get_total_levels`), avanço e sinal `goal_item_collected` |
| `scripts/core/save_manager.gd` | Preservação de `last_played_level` contra sobrescrita em `save_game()` |
| `scripts/ui/hud.gd` | Voo de ícones flutuantes, limite da Fase 40 para Ciclo Mestre e absorção elástica |
| `scripts/menu/main_menu.gd` | Inicialização na próxima fase desbloqueada e suporte a 40 fases |
| `scripts/cutter/cutter.gd` | Fix de posicionamento de `spark_particles` no robô durante o upgrade |
| `scripts/plants/plant.gd` | Pedaços 3D de grama chanfrada e resolução universal de variantes de flores |
| `scripts/plants/vegetation_grid.gd` | Disparo de peças desprendíveis de flores no corte final |
| `tests/test_progression_and_goal_effects.gd` | Novo teste automatizado cobrindo progressão, metas e efeitos |
| `project.godot` & `export_presets.cfg` | Bump para versão `0.12.136-alpha` (code `1336`) |

---

## 4. Validação e Testes
- **Testes Automatizados Aprovados com 100% de Sucesso:**
  - `tests/test_progression_and_goal_effects.gd`: 40 fases, avanço da Fase 20 para 21, persistência de save, shader de outline e malha 3D de grama.
  - `tests/test_flower_detach.gd`: Todas as 8 espécies de flores desprendendo peças corretamente.
  - `tests/test_blade_pop_and_slash.tscn`: Efeitos de lâmina, pop e choque validados.
  - `tests/test_save_manager.tscn`: Resiliência e persistência atômica íntegras.
- **Headless Check:** Execução via Godot 4 com **0 erros e 0 warnings**.
