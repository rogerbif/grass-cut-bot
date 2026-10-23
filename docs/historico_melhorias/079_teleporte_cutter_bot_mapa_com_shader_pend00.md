# Melhoria 079: Teleporte do Cutter Bot no Mapa com Spatial Shader 3D (pend00) 🌌🤖

Melhoria executada em conformidade com as diretrizes do `GEMINI.md` e a skill `atualizar-documentacao`.

---

## 🎯 Objetivo da Melhoria

Implementar o efeito de teleporte do **Cutter Bot** ao navegar entre as ilhas na **Visão de Mapa** (`MAP_VIEW`), reproduzindo o shader canônico [godotshaders.com/shader/teleport-effect](https://godotshaders.com/shader/teleport-effect/) adaptado para Spatial 3D em Godot 4.
- **Desaparição de Cima para Baixo:** Quando o foco da câmera muda, o robô na ilha de origem é varrido por um feixe turquesa brilhante com ruído procedural de gradiente, desintegrando-se do topo da antena até a roda.
- **Aparecimento de Baixo para Cima:** Na nova ilha em foco, o robô materializa-se a partir da base subindo até o topo, restaurando os materiais normais ao concluir.

---

## 🛠️ Alterações Implementadas

### 1. Novo Shader Spatial 3D (`shaders/teleport_effect.gdshader`)
- Algoritmo de ruído de gradiente procedural pseudo-aleatório baseado no shader CC0 de pend00.
- Normalização de altura em espaço global (`v_world_pos.y`) relativo à base do robô, unificando a varredura entre cabeça, olhos, chassi, serra e rodas em uma fatia planar horizontal contínua.
- Suporte a dois modos: `mode = 0` (desaparece de cima para baixo) e `mode = 1` (aparece de baixo para cima).
- Preservação dinâmica dos parâmetros PBR originais (`albedo_color`, `albedo_texture`, `metallic`, `roughness`, `emission`) durante a desintegração.
- Feixe luminoso com cor HDR (`vec4(0.0, 1.02, 1.2, 1.0)`) e emissão ajustada para Bloom/Glow.

### 2. Controlador MenuBot (`scripts/menu/menu_bot.gd`)
- Adição da rotina `teleport_to_position(target_pos: Vector3, on_complete: Callable = Callable())`.
- Injeção e remoção atômica de `ShaderMaterial` via `set_surface_override_material`, com recuperação automática da tela de LED dos olhos (`_setup_eyes()`) ao término.
- Orquestração de animação via `Tween`:
  - Varredura de saída: $0.36\text{s}$ com SFX `fast_forward`.
  - Reposicionamento quando 100% invisível.
  - Varredura de entrada: $0.40\text{s}$ com SFX `power_up`.
  - Retorno suave à máquina de estados de locomoção autônoma.

### 3. Orquestração no MainMenu (`scripts/menu/main_menu.gd`)
- Rastreamento de `current_bot_level`.
- Gatilho reativo disparado ao encaixar o mapa em uma nova ilha (`_on_camera_island_snapped`).
- Gatilho imediato ao tocar em outra ilha no arquipélago (`_on_island_clicked`), sincronizando o teleporte com o deslocamento suave da câmera.
- Atualização dinâmica de `menu_camera.set_bot_target()`.

### 4. Teste Automatizado (`tests/test_menu_bot_teleport.tscn` / `.gd`)
- Cena de validação cobrindo compilação do shader, atribuição de materiais, ativação do estado `is_teleporting`, execução do ciclo completo e limpeza final com 0 warnings.

---

## 🧪 Verificação & Qualidade

- **Godot 4.7.1 Vulkan Forward Mobile:** Execução da cena de teste e da cena principal com **0 erros e 0 warnings**.
- **Versão SemVer:** Atualizado para `v0.12.4-alpha`.
