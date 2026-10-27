# Melhoria 135: Efeito de Pop Elástico, Flash, Choque e Shader de Slash Ultra-Leve no Level UP 🪚✨

## 1. Resumo Executivo
- **Solicitação do Usuário:** "A cada level UP gostaria de um efeito de pop na lâmina e um shader de Slash enquanto a lâmina gira tipo esse mas o mais leve que encontrar https://godotshaders.com/shader-tag/slash/ ... Quero o choque e flash e opção A".
- **Objetivo:** Criar um conjunto de feedbacks audiovisuais e táteis no instante em que a lâmina sobe de nível (Pop mecânico elástico, Flash de energia, Onda de choque expansiva no solo), acompanhado por um Shader de Slash procedural analítico ultra-leve acoplado à rotação da serra.
- **Resultado:**
  - **Pop Elástico com Squash & Stretch:** Punch de escala de $1.38\times$ na lâmina em $0.07\text{s}$ com recuo elástico em mola em $0.30\text{s}$ (`TRANS_BACK`), preservando volume com compressão em Y.
  - **Flash de Energia:** Pulso luminoso instantâneo de brilho com boost de intensidade de $2.5\times$ decaindo em $0.28\text{s}$.
  - **Onda de Choque Radial (Shockwave Ring):** Anel procedural aditivo no plano do solo que expande de $0.15\text{m}$ até $1.65\times$ o raio da lâmina com fade-out exponencial em $0.32\text{s}$.
  - **Shader de Slash Ultra-Leve (Opção A):** Rastro em arco polar contínuo gerado 100% matematicamente no fragment shader da GPU (zero texturas PNG na VRAM), modulado dinamicamente pela velocidade de giro da lâmina (sutil em idle, brilhante no corte).
  - **Desacoplamento Canônico:** Sinal dedicado `UpgradeManager.blade_leveled_up`, garantindo que o efeito dispare exclusivamente na subida de nível e nunca em penalidades de rochas ou carregamento de savegames.

---

## 2. Detalhes de Implementação

### A. Shader de Slash Procedural Analítico (`shaders/blade_slash.gdshader`)
- **Render Mode:** `render_mode unshaded, blend_add, depth_draw_never, cull_disabled;`
- **Matemática Polar:** Converte coordenadas $UV$ em $(r, \theta)$ e calcula o arco cortante com atenuação quadrática na cauda e anel delimitador entre raio interno e ponta da lâmina via `smoothstep`.
- **Performance Mobile:** Custo de renderização praticamente nulo (zero texturas, zero consultas de profundidade e apenas 1 draw call em plano horizontal).
- **Modulação por Velocidade:** A intensidade (`slash_intensity`) varia de $0.12$ (em marcha lenta / repouso) até $1.00$ (na rotação de corte ativo a $720^\circ/\text{s}$).

### B. Shader de Onda de Choque (`shaders/shockwave_ring.gdshader`)
- **Render Mode:** `render_mode unshaded, blend_add, depth_draw_never, cull_disabled;`
- Anel circular fino com suavização analítica antialiasing nas bordas interna e externa, controlado por uniforms de escala e `alpha` via Tween.

### C. Sinal Canônico no `UpgradeManager`
- Criado `signal blade_leveled_up(new_level: int, is_max: bool)`.
- Emitido estritamente quando `blade_level += 1` em `add_blade_xp` e em `buy_blade_upgrade`.
- Não é emitido em `penalize_blade_hit` nem na inicialização/carregamento de saves.

### D. Integração no `Cutter` (`scripts/cutter/cutter.gd`)
- Instanciação procedural limpa de `BladeSlash` (filho do rotor `BladeSpinner`) e `ShockwaveRing` (na base do robô a $Y = 0.035\text{m}$).
- Sincronização contínua de escala em `_sync_blade_spinner_transform`:
  ```gdscript
  var visual_scale: float = (_cached_blade_radius / 1.03) * _blade_pop_scale
  var squash_y: float = 1.0 / sqrt(maxf(_blade_pop_scale, 0.01))
  blade_spinner.basis = Basis(tilt_quat * spin_quat).scaled(Vector3(visual_scale, squash_y, visual_scale))
  ```

---

## 3. Arquivos Criados e Modificados

- `shaders/blade_slash.gdshader`: Shader procedural em arco para o rastro giratório da serra.
- `shaders/blade_slash_material.tres`: Material base do slash com blend aditivo.
- `shaders/shockwave_ring.gdshader`: Shader do anel de onda de choque no solo.
- `shaders/shockwave_ring_material.tres`: Material aditivo da onda de choque.
- `scripts/core/upgrade_manager.gd`: Declaração e emissão de `blade_leveled_up`.
- `scripts/cutter/cutter.gd`: Implementação do Pop elástico, Flash, Choque e modulação do Slash.
- `tests/test_blade_pop_and_slash.gd` & `.tscn`: Teste automatizado de validação completa.
- `docs/02_entidades_e_mecanicas/SISTEMA_DO_CORTADOR.md`: Documentação técnica canônica.
- `docs/04_sistemas_e_gameplay/GAME_FEEL_E_HAPTICS.md`: Registro das camadas sensoriais de Game Feel.

---

## 4. Testes e Validação
- **Teste Automatizado Dedicado:** `tests/test_blade_pop_and_slash.tscn` executado e aprovado com 100% de sucesso:
  - Criação de `blade_slash_mesh` e `shockwave_mesh` confirmada.
  - Compilação de shaders com 0 erros e 0 warnings.
  - Emissão de `blade_leveled_up` ao subir para Lv 2 confirmada.
  - Ativação do Pop de escala e da Onda de Choque confirmada.
  - Imunidade de disparo a penalidades de rocha confirmada.
  - Modulação dinâmica de intensidade por rotação validada.
- **Testes de Regressão:** `test_blade_progression.tscn`, `test_wheat_level_02.tscn` e `test_editor_goals_and_panel.tscn` aprovados com 100% de sucesso.
