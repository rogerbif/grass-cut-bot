# Melhoria 018: Restauração da Animação de Vento e Interatividade no Novo Modelo 3D de Grama [v0.4.1] 🍃🌾

## 1. Visão Geral e Contexto
O usuário notou que o novo modelo de grama importado do Blender não possuía o balanço dinâmico de vento que existia nos tufos procedurais anteriores: *"notei que o modelo novo não tem o balanço de animação do vento como podemos trazer isso novamente?"*.

### Causa Identificada:
Os materiais exportados pelo Blender para o glTF são `StandardMaterial3D` estáticos, que carecem de lógica de deformação de vértices. A animação orgânica de vento e a reação elástica à aproximação da serra são calculadas em tempo real na GPU pelo vertex shader `shaders/interactive_grass.gdshader`.

---

## 2. Implementações Técnicas

### A. Compatibilidade UV e Vértices
- **Inspeção de UVs:** Verificamos que a malha do modelo 3D possui coordenadas UV normalizadas onde $UV.y = 1.0$ na base das raízes ($Y=0.0$) e $UV.y = 0.0$ nas pontas das folhas ($Y=1.025$).
- **Fórmula de Curvatura Exponencial:** A equação `height_factor = clamp(1.0 - UV.y, 0.0, 1.0)` resulta em $0.0$ nas raízes (ancoragem total no solo) e $1.0$ no ápice foliar, permitindo que a curvatura `bend_factor = pow(height_factor, 1.6)` atue de forma realista e orgânica.

### B. Criação dos Materiais de Shader Interativo por Cor
Criamos materiais dedicados compartilhando o shader espacial `interactive_grass.gdshader`:
1. `interactive_grass_material.tres`: Verde esmeralda vivo (`Color(0.12, 0.42, 0.16)` base, `Color(0.20, 0.70, 0.22)` topo).
2. `interactive_grass_yellow_material.tres`: Amarelo/dourado pastoral (`Color(0.65, 0.40, 0.02)` base, `Color(1.00, 0.65, 0.05)` topo).
3. `interactive_grass_blue_material.tres`: Azul místico/gélido (`Color(0.02, 0.28, 0.62)` base, `Color(0.06, 0.52, 0.95)` topo).
4. `interactive_grass_purple_material.tres`: Roxo exótico (`Color(0.30, 0.05, 0.55)` base, `Color(0.55, 0.12, 0.92)` topo).

Todos calibrados com `wind_strength = 0.10`, `wind_speed = 2.5` e acabamento fosco `roughness = 0.88` (Mandamento 7).

### C. Integração no `plant.gd`, `grass_tuft.tscn` e `cutter.gd`
- **`plant.gd`:** No método `_apply_grass_variation()`, o `material_override` correspondente é injetado diretamente na malha ativa da variante, permitindo que qualquer cor (Verde, Amarela, Azul ou Roxa) balance suavemente no vento.
- **`cutter.gd`:** Atualizado o método `_update_shader_globals()` para sincronizar `cutter_pos` e `cutter_interact_radius` com todos os 4 materiais de grama, fazendo a nova vegetação 3D se curvar e achatar sob a aproximação do robô.
- **`grass_tuft.tscn` & `grass_01.tscn`:** Configurados com os materiais de shader nos nós de malha.

---

## 3. Validação e Qualidade
- **Zero Warnings / Zero Erros:** Verificado com sucesso via Godot MCP (`run_project` e `get_debug_output`).
- **Game Feel Restaurado:** O gramado agora ondula organicamente com ondas de vento cruzadas globais e se afasta elasticamente da lâmina do cortador.
- **SemVer:** Incrementado para **`v0.4.1`** em `project.godot`.
