# Histórico de Melhoria: Calibração Fina do Shader de Água Wind Waker 🌊🎨

**ID:** `065_shader_agua_wind_waker_calibrado`  
**Versão:** `v0.10.2-alpha`  
**Data:** 21/10/2026  
**Status:** Concluído e Validado (0 Warnings no Godot 4.7.1)  

---

## 1. Diagnóstico do Shader Inicial

Na primeira versão do shader de Wind Waker testada, a fórmula matemática apresentava uma inversão de threshold:
- O teste de espuma utilizava um `step(0.7, pattern)` onde mais de 80% dos pixels atingiam o valor máximo. Como consequência, o mar ficou predominantemente **branco** com furos azuis circulares (aparência de manchas brancas caóticas de leopardo).
- A escala `uv_scale = 0.12` gerava círculos com diâmetro gigantesco (mais de 8 metros cada).

O usuário indicou a versão 2D do shader de Wind Waker para Godot 4 ([zeludtnecniv no GodotShaders](https://godotshaders.com/shader/wind-waker-2d-water-shader-godot-4/)) como referência ideal.

---

## 2. Implementação e Calibração

### A. Port para Spatial 3D (`shaders/wind_waker_water.gdshader`)
- Adaptamos a lógica limpa da referência 2D para shader espacial 3D com coordenadas de mundo:
  - **Base Azul Predominante:** O corpo da água mistura duas tonalidades de azul turquesa tropical (`water_color` e `water2_color`) através da camada primária de círculos suaves (`mix(water_color, water2_color, layer1)`).
  - **Espuma Suave e Contida:** A espuma entra com intensidade ponderada (`foam_intensity = 0.40`) apenas nas linhas de crista de onda (`(1.0 - layer2) * foam_intensity`), sem nunca tomar conta do mar.
  - **Distorção Trigonométrica Leve:** Substituído o ruído FBM pesado por oscilações senoidais (`sin/cos`), reduzindo drasticamente o consumo de GPU para manter 60 FPS cravados em celulares Android.
  - **World Coordinates:** Coordenadas de amostragem no plano $XZ$ de mundo (`v_world_pos.xz * uv_scale`), garantindo fluxo contínuo e estanque durante o movimento da câmera e o scroll do mapa.

### B. Parâmetros do Material (`shaders/wind_waker_water_material.tres`)
- `water_color`: `Color(0.18, 0.65, 0.82)`
- `water2_color`: `Color(0.08, 0.52, 0.75)`
- `foam_color`: `Color(0.88, 0.98, 1.00)`
- `uv_scale`: `0.22` (escala refinada proporcional às ilhas e ao robô)
- `distortion_speed`: `1.2`
- `foam_intensity`: `0.40`
- `roughness`: `0.88` (acabamento fosco arcade)

### C. Integração
- Aplicado no `OceanMesh` do Menu Inicial (`scenes/menu/main_menu.tscn`) com camera-tracking infinito.
- Aplicado no `SurfaceWater` das fases jogáveis (`scenes/level/water_ocean.tscn`).

---

## 3. Validação

- Execução via Godot Debug Runner nas cenas `main_menu.tscn` e `main.tscn`: **0 warnings e 0 erros**.
- Visual equilibrado: mar azul turquesa vibrante com ondas sutis e espuma Toon estilizada.

---

## 4. Arquivos Modificados

| Arquivo | Descrição |
| :--- | :--- |
| `shaders/wind_waker_water.gdshader` | Novo shader espacial Toon Wind Waker calibrado. |
| `shaders/wind_waker_water_material.tres` | Material com parâmetros equilibrados (água azul 90%, espuma sutil 10%). |
| `scenes/menu/main_menu.tscn` | Aplicação do novo material no oceano do mapa. |
| `scenes/level/water_ocean.tscn` | Aplicação do novo material na água das fases. |
| `docs/01_visao_geral_e_gdd/DIRECAO_DE_ARTE_E_VISUAL.md` | Atualização da documentação de arte. |
| `docs/historico_melhorias/INDICE_MELHORIAS.md` | Indexação da melhoria. |
| `scripts/core/game_version.gd`, `project.godot`, `export_presets.cfg` | Atualização SemVer para `v0.10.2-alpha` (code `1002`). |
