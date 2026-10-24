# Melhoria 097: Câmera Top-Down Ortogonal Pura e Rotação Horária do Pincel de 5° em 5° 🎥📐🔄

**Status:** Concluído ✅  
**Data:** 2026-10-24  
**Versão SemVer:** `v0.12.22-alpha` (Code: 1222)  
**Domínio:** Level Design & Editor / Interface & HUD / Arquitetura & GDScript  

---

## 1. Visão Geral e Contexto do Problema

Durante a modelagem e desenho vetorial de ilhas e vegetação no **Editor de Fases para PC** (`level_editor.tscn`), foram solicitadas duas melhorias essenciais de precisão geométrica e experiência de edição:
1. **Câmera Superior Ortogonal Pura:** A visão de topo anterior operava em perspectiva com ângulo inclinado de $86^\circ$, causando pequenas distorções de paralelaxe e fuga nas bordas da tela. Foi requisitada uma visualização top-down estritamente ortogonal (sem distorção de perspectiva), ideal para alinhamento e precisão cartográfica.
2. **Rotação Fina do Pincel de $5^\circ$ em $5^\circ$:** A rotação com a tecla `R` avançava exclusivamente em saltos de $90^\circ$. Para formas analíticas de grama vetorial (quadrados, corações, estrelas, cruzes e losangos), era necessário poder inclinar os carimbos finamente em sentido horário em incrementos de $5^\circ$.

---

## 2. Solução Implementada

### A. Câmera Superior Ortogonal (`editor_camera.gd`)
- **Projeção Ortogonal Dinâmica:** Ao alternar para o modo Top-Down (`V`), a câmera altera sua propriedade de projeção para `Camera3D.PROJECTION_ORTHOGONAL`.
- **Zoom Adaptativo via `size`:** O dimensionamento do campo de visão ortogonal escala suavemente com a distância de foco (`size = current_distance * 0.85`), mantendo o comportamento intuitivo da rolagem do mouse (`Scroll Up / Down`) sem quebrar a proporção do mapa.
- **Orientação Axial Cardinal Perfeita:** A câmera posiciona-se perpendicularmente sobre o ponto focal (`focus_point + Vector3(0.0, 35.0, 0.0)`) com `looking_at(Vector3.DOWN, Vector3.FORWARD)`, garantindo que o Norte ($-Z$) aponte para o topo da tela, o Sul ($+Z$) para a base, Oeste ($-X$) para a esquerda e Leste ($+X$) para a direita.
- **Restauração em Playtest:** Ao iniciar o teste (`F1`), a câmera retorna automaticamente para a perspectiva isométrica de acompanhamento do robô cortador.

### B. Rotação Horária do Pincel de $5^\circ$ em $5^\circ$
- **Incremento Angular Horário (`level_editor.gd`):** Ao pressionar a tecla `R` ou clicar no botão de rotação na paleta de vegetação ou objetos, a orientação avança em `+5°` no sentido horário (`current_rot_deg = (current_rot_deg + 5) % 360`).
- **Preservação de Encaixe Ortogonal de Terreno:** Quando a camada ativa é a de Terreno (`active_layer == EditLayer.TERRAIN`), os blocos modulares da ilha continuam rotacionando em passos de $90^\circ$ para respeitar o grid ortogonal de $0.80\text{m}$.
- **Transformação Geométrica de Carimbos (`brush_patterns.gd`):** O método `BrushPatterns.get_vector_stamp_polygon()` recebeu o parâmetro `rotation_deg: float = 0.0`. Cada vértice gerado em torno do centro é rotacionado analiticamente no sentido horário via `center + rel.rotated(deg_to_rad(rotation_deg))`.
- **Feedback Visual Holográfico (`grid_overlay.gd`):** A seta direcional projetada sobre o solo e o contorno holográfico do pincel giram em tempo real de $5^\circ$ em $5^\circ$ acompanhando o cursor do mouse.
- **Rótulo Dinâmico na UI (`level_editor_ui.gd`):** O botão de rotação reflete o incremento contextual:
  - Camada de Grama/Objetos: `🔄 Girar Pincel [R]: X° (+5°)`
  - Camada de Terreno: `🔄 Girar Tile [R]: X° (+90°)`
  - Câmera: `🎥 Câmera [V]: Top-Down Ortogonal`

---

## 3. Arquivos Modificados e Criados

| Arquivo | Descrição das Modificações |
| :--- | :--- |
| `scripts/editor/editor_camera.gd` | Implantação de projeção ortogonal no modo top-down (`PROJECTION_ORTHOGONAL`), controle dinâmico de `size` via zoom e orientação perpendicular mirando em `Vector3.DOWN` com up `Vector3.FORWARD`. |
| `scripts/editor/brush_patterns.gd` | Adicionado suporte a rotação angular em `get_vector_stamp_polygon()`, rotacionando polígonos fechados em torno do centro relativo. |
| `scripts/editor/level_editor.gd` | Atualizado `_rotate_active_step()` para passos de $5^\circ$ em vegetação/objetos e repasse de `current_rot_deg` nos previews e aplicação de carimbos. |
| `scripts/editor/grid_overlay.gd` | Calibração do vetor direcional `fwd` da seta indicadora para rotação horária contínua. |
| `scripts/editor/level_editor_ui.gd` | Textos contextuais para `btn_rotate` (`+5°` vs `+90°`) e `btn_cam_view` (`Top-Down Ortogonal`). |
| `docs/03_level_design_e_fases/SISTEMA_EDITOR_DE_FASES.md` | Documentação técnica canônica atualizada com atalhos de rotação fina e projeção ortogonal. |
| `project.godot` | Incremento Game SemVer de `v0.12.21-alpha` para `v0.12.22-alpha`. |
| `export_presets.cfg` | Sincronização do SemVer `0.12.22-alpha` e code `1222`. |
| `docs/historico_melhorias/INDICE_MELHORIAS.md` | Registro da melhoria 097 no catálogo histórico. |

---

## 4. Verificação e Validação

1. **Compilação e Execução Limpa:** Projeto inicializado via Godot MCP e validado com sucesso.
2. **Zero Warnings/Erros:** Console do Godot 100% livre de warnings ou erros em tempo de execução.
3. **Raycast Preciso:** O raycast do mouse (`project_ray_origin` / `project_ray_normal`) opera com exatidão matemática sobre o plano do chão na projeção ortogonal.
