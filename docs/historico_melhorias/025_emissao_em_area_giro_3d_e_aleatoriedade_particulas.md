# Melhoria 025: Emissão em Área Circular, Giro no Ar e Alta Aleatoriedade de Trajetória [v0.4.8] 🌿🌀

## 1. Visão Geral e Contexto
O usuário apontou limitações no comportamento das partículas de corte:
- *"as particulas partem do centro não temos como ser na area do tufo cortado"*
- *"e que as particulas girem pelo ar"*
- *"e não tenham um padrão de direção quero mais aleatoriedade"*

---

## 2. Implementações Técnicas

### A. Emissão Distribuída pela Área do Tufo (`emission_shape = RING`)
- Anteriormente, o emissor utilizava `EMISSION_SHAPE_POINT`, fazendo todas as 30 folhas partirem de um único ponto central microscópico `(0, 0, 0)`.
- Configurado `emission_shape = 6` (`EMISSION_SHAPE_RING`):
  - `emission_ring_axis = Vector3(0, 1, 0)`
  - `emission_ring_height = 0.1m`
  - `emission_ring_radius = 0.35m`
  - `emission_ring_inner_radius = 0.0m` (preenchimento total do disco).
- As partículas agora brotam espalhadas por toda a base circular de 70 cm do tufo ceifado, exatamente de onde as lâminas de grama foram decepadas pela serra.

### B. Ativação de Rotação 3D no Ar (`particle_flag_rotate_y`)
- No Godot 4, as partículas de malha não giram a menos que a flag de rotação esteja explicitamente ativada no nó.
- Habilitado `particle_flag_rotate_y = true`.
- Configuradas velocidades angulares de $-540^\circ$ a $+540^\circ/\text{s}$ (`angular_velocity_min = -540.0`, `angular_velocity_max = 540.0`).
- Configurado ângulo inicial totalmente aleatório entre $-180^\circ$ e $+180^\circ$ (`angle_min = -180.0`, `angle_max = 180.0`).
- As folhas agora giram e capotam dinamicamente no ar em sentidos horários e anti-horários enquanto viajam em arco.

### C. Quebra de Padrão Direcional e Alta Aleatoriedade
- Abertura cônica ampliada de `32.0°` para **`85.0°`** (`spread = 85.0`), quebrando a coluna uniforme e criando uma dispersão hemisférica orgânica.
- Velocidade inicial com maior faixa dinâmica (`initial_velocity_min = 2.0`, `initial_velocity_max = 4.5`).
- Adicionada aceleração tangencial caótica (`tangential_accel_min = -3.0`, `tangential_accel_max = 3.0`) para trajetórias helicoidais e curvas no ar.
- Adicionado amortecimento de ar (`damping_min = 1.0`, `damping_max = 2.5`) para simular arrasto aerodinâmico nas folhas leves.
- Duração ajustada para `0.70s` com curva de escala suave de encolhimento no solo.

---

## 3. Cenas Atualizadas
- [`grass_tuft.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/plants/grass_tuft.tscn)
- [`grass_green.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/plants/grass_green.tscn)
- [`grass_yellow.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/plants/grass_yellow.tscn)
- [`grass_blue.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/plants/grass_blue.tscn)
- [`grass_purple.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/plants/grass_purple.tscn)

---

## 4. Validação e Qualidade
- **Zero Warnings / Zero Erros:** Verificado em execução de debug contínua via Godot MCP (`run_project` e `get_debug_output`).
- **SemVer:** Incrementado para **`v0.4.8`** em `project.godot`.
