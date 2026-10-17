# Melhoria 030: Ajustes Críticos Mobile — Cor da Grama, Velocidade, Câmera e Menu de Pausa [v0.5.3] 📱🌿🤖

## 1. Visão Geral e Contexto
Após o primeiro teste bem-sucedido do jogo exportado nativamente para smartphone Android, o usuário reportou quatro comportamentos a calibrar:
1. *"A grama ficou branca não sei porquê"*
2. *"Dá para reduzir a velocidade inicial do bot em 50%"*
3. *"A câmera parece que fica travando enquanto ele anda verifique"*
4. *"O menu pausa só abre se ficar segurando o botão verifique"*

---

## 2. Diagnóstico e Implementações Técnicas

### A. Correção da Grama Branca no Mobile (`plant.gd`, `grass_tuft.tscn`, `interactive_grass.gdshader`)
- **Causa Raiz:** No `.glb` importado, o material embutido padrão `M_Grama_Default` possuía cor base cinza claro/branco ($0.8, 0.8, 0.8$). O `material_override` do shader na cena estava atribuído via herança de nós em `.tscn` (`[node name="grass_01" parent="VisualMesh/Grass01" index="0"]`), que era descartado ou não mapeado em tempo de execução no empacotamento Android do Godot 4.
- **Solução Defensiva:**
  - Exportado `@export var custom_material: Material` em `scripts/plants/plant.gd`.
  - No `_ready()`, implementada propagação recursiva `_apply_visual_material(visual_mesh)` para garantir em tempo de execução que todo `MeshInstance3D` filho receba o material configurado.
  - Adicionado fallback automático via código para `StandardMaterial3D` verde vibrante (`Color(0.22, 0.68, 0.24)` com `roughness = 0.9`), impedindo que a vegetação fique branca em qualquer hipótese de fallback.
  - No shader espacial `interactive_grass.gdshader`, cacheada a matriz inversa `mat3 inv_model = mat3(inverse(MODEL_MATRIX))` em variável única na função `vertex()`, eliminando cálculos repetidos de inversão matricial por vértice e garantindo total estabilidade em GPUs mobile (Mali e Adreno).

### B. Calibração da Velocidade Inicial do Cortador em 50% (`cutter.gd` e `upgrade_manager.gd`)
- Em `scripts/cutter/cutter.gd`: reduzido `base_speed` de $6.5\text{ m/s}$ para **$3.25\text{ m/s}$** ($50\%$ de redução).
- Em `scripts/core/upgrade_manager.gd`: atualizado `get_cutter_speed()` para base de $3.25\text{ m/s}$ com incremento suave de $+0.45\text{ m/s}$ por nível de oficina.
- Proporciona dirigibilidade mais controlada, confortável e precisa com joystick virtual de um dedo no celular.

### C. Eliminação de Micro-travamentos na Câmera (`isometric_camera.gd` e `project.godot`)
- **Causa Raiz:** O robô cortador se movimenta em `_physics_process` (passo fixo de física a 60Hz), enquanto a câmera estava atualizando sua interpolação em `_process` (taxa de quadros variável de renderização). Isso gerava jitter/micro-stutter visível no celular (telas de 60Hz/90Hz/120Hz). Além disso, o eixo Y estava com snap direto sem suavização.
- **Solução:**
  - Câmera migrada para `_physics_process(delta)` em `isometric_camera.gd`, sincronizando perfeitamente o ciclo de rastreio com a física do cortador.
  - Suavização aplicada uniformemente em todos os três eixos ($X, Y, Z$) via `lerpf`.
  - Habilitada a interpolação nativa de física da engine em `project.godot` (`physics/common/physics_interpolation = true`).

### D. Correção do Menu de Pausa no Touch (`hud.gd`)
- **Causa Raiz:** O método `_connect_button` no `hud.gd` conectava tanto o sinal `btn.pressed` quanto o evento `gui_input` com `event.pressed == true`. Ao dar um toque rápido no botão, o toque disparava o evento inicial de touch (pausando o jogo) e, ao soltar o dedo, o botão nativo disparava `pressed` (despausando imediatamente). Por isso o menu só ficava aberto enquanto o usuário mantinha o dedo pressionado na tela.
- **Solução:** Removida a conexão duplicada do `gui_input`. O sinal nativo `Button.pressed` já gerencia cliques, toques e liberação com debounce no Android e Desktop sem falso duplo-disparo.

---

## 3. Validação e Qualidade
- **Zero Warnings / Zero Erros:** Verificado no console e via Godot MCP (`run_project` / `get_debug_output`).
- **SemVer:** Incrementado para **`v0.5.3`** em `project.godot`.
