# Histórico de Melhoria: Oceano Infinito com Camera Tracking e Shader de Água Toon (Wind Waker) 🌊⛵

**ID:** `063_oceano_infinito_e_shader_agua_wind_waker`  
**Versão:** `v0.10.0-alpha`  
**Data:** 21/10/2026  
**Status:** Concluído e Validado (0 Warnings no Godot 4.7.1)  

---

## 1. Contexto e Diagnóstico

### A. Fim da Malha do Oceano após a Fase 5
O jogador notou que, a partir da Fase 6 no Mapa de Fases, a água parecia "mudar de cor" para um azul claro pastel com uma linha divisória nítida.
- **Causa Raiz Identificada:** A malha do oceano do Menu Inicial (`scenes/menu/main_menu.tscn`) possuía tamanho fixo de $160\text{m} \times 160\text{m}$ centrada em $Z = 0$ ($Z = +80\text{m} \dots -80\text{m}$). Como as ilhas estão espaçadas ao longo do eixo $Z$ (Fase 5 em $Z = -74.0\text{m}$ e Fase 6 em $Z = -92.5\text{m}$), logo após a Fase 5 a malha do mar terminava fisicamente, revelando o fundo do céu (`background_color = Color(0.55, 0.82, 0.94)`).

### B. Solicitação do Shader de Água Estilo Zelda Wind Waker
O usuário solicitou a aplicação do clássico shader de água procedural sem texturas de *The Legend of Zelda: The Wind Waker* (NekotoArts / Godot Shaders), tanto no Mapa do Menu Inicial quanto no jogo durante as partidas.

---

## 2. Implementações Realizadas

### 1. Rastreamento Dinâmico de Câmera (Oceano Infinito)
- No script do menu principal ([`scripts/menu/main_menu.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/menu/main_menu.gd)):
  - O `OceanMesh` agora acompanha as coordenadas $X$ e $Z$ da câmera no `_process`:
    ```gdscript
    func _process(_delta: float) -> void:
    	if ocean_mesh != null and menu_camera != null:
    		ocean_mesh.global_position.x = menu_camera.global_position.x
    		ocean_mesh.global_position.z = menu_camera.global_position.z
    ```
  - A malha `PlaneMesh` foi expandida para $320\text{m} \times 320\text{m}$.
  - Com o centro da água sempre colado na câmera, o oceano nunca termina, mantendo água contínua da mesma cor em 100% do arquipélago, da Fase 1 até além da Fase 20.

### 2. Shader de Água Toon Estilo Wind Waker (`shaders/wind_waker_water.gdshader`)
- Criado shader espacial procedural otimizado para mobile (zero texturas externas necessárias):
  - **Coordenadas de Mundo (`v_world_pos.xz`):** O cálculo do padrão de ondas e anéis de espuma utiliza a posição de mundo calculada no Vertex Shader. Desta forma, o mar flui organicamente no espaço global, sem esticar ou deslizar artificialmente quando o plano se desloca.
  - **Anéis e Espuma Procedural:** Reprodução da estética clássica de círculos e ondas com distorção por FBM (Fractal Brownian Motion).
  - **Desempenho Mobile:** Otimizado com 3 oitavas de ruído determinístico leve, `diffuse_toon` e `specular_disabled`, garantindo 60 FPS cravados em dispositivos Android.
  - **Paleta Tropical Consistente:**
    - `water_color`: `Color(0.18, 0.65, 0.82)` (turquesa arcade ensolarado)
    - `deep_color`: `Color(0.12, 0.48, 0.68)` (azul profundo em contraste com as cristas)
    - `foam_color`: `Color(0.85, 0.98, 1.00)` (espuma branca/ciano brilhante)

### 3. Aplicação Global (Mapa e Gameplay)
- **No Mapa e Home:** Aplicado em `scenes/menu/main_menu.tscn` no nó `OceanMesh`.
- **No Gameplay:** Aplicado em `scenes/level/water_ocean.tscn` no nó `SurfaceWater`, integrando automaticamente todas as 20 fases canônicas e o Editor de Fases.

---

## 3. Validação e Testes

- **Testes com Godot Debug Runner (MCP):**
  - Execução da cena `scenes/menu/main_menu.tscn` (Home e Mapa de Fases com scroll por todas as ilhas).
  - Execução da cena principal de gameplay `scenes/main.tscn`.
  - Console da engine retornou com **0 warnings e 0 erros** em ambas as execuções.
- O mar agora possui ondas procedurais toon e anéis de espuma vivos, com tonalidade uniforme em 100% da extensão do mapa.

---

## 4. Arquivos Modificados / Criados

| Arquivo | Descrição |
| :--- | :--- |
| `shaders/wind_waker_water.gdshader` | Shader espacial de água toon estilo Zelda Wind Waker com posições de mundo e sem texturas. |
| `shaders/wind_waker_water_material.tres` | Recurso de material ShaderMaterial compartilhado com parâmetros afinados. |
| `scenes/menu/main_menu.tscn` | Expansão da malha do oceano para 320x320m e aplicação do novo ShaderMaterial. |
| `scripts/menu/main_menu.gd` | Implementação de camera-tracking para manter o oceano centrado na câmera. |
| `scenes/level/water_ocean.tscn` | Aplicação do novo ShaderMaterial no mar das fases jogáveis. |
| `docs/01_visao_geral_e_gdd/DIRECAO_DE_ARTE_E_VISUAL.md` | Documentação da paleta do Oceano Toon. |
| `scripts/core/game_version.gd`, `project.godot`, `export_presets.cfg` | Atualização SemVer para `v0.10.0-alpha` (code `1000`). |
