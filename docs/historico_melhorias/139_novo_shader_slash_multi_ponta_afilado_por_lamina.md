# Melhoria 139: Novo Efeito de Slash Multi-Ponta Afilado por Lâmina com Gradiente de Transparência 🪚✨

## 1. Resumo Executivo
- **Solicitação do Usuário:** "Quero melhorar o efeito do Slash que fizemos cada ponta da lâmina deve haver um efeito que começa mais largo perto da lâmina e vai afinando e ficando transparente para a ponta , tentei desenhar como quero mas só como exemplo /plan" acompanhado de desenho técnico esquemático com os rastros cortantes afilados ao redor das 6 pontas da lâmina.
- **Objetivo:** Refatorar o efeito de Slash do cortador para gerar rastros cortantes individuais em cada dente/ponta da lâmina ativa (3, 4, 5 ou 6 pontas), iniciando espesso/largo junto à lâmina e afinando progressivamente com curvatura aerodinâmica até sumir suavemente em transparência total na ponta da cauda.
- **Resultado:**
  - **Shader Multi-Ponta Analítico na GPU:** Refatorado `shaders/blade_slash.gdshader` com dobramento de setor polar ($S = \frac{2\pi}{N}$) para calcular todas as pontas em paralelo sem laços de repetição (zero texturas PNG, 60 FPS mobile estritos).
  - **Afinamento Suave e Gradiente de Alpha:** Implementado modelo geométrico de largura $W(t) = W_{\text{base}} \cdot (1 - t)^{1.3}$ e atenuação de transparência $\alpha(t) = (1 - t)^{1.4}$, reproduzindo com fidelidade o esboço técnico do usuário.
  - **Fio de Corte Incandescente:** Adicionado núcleo branco puro (`core_color`) fundido com a energia da lâmina (`slash_color`) para conferir estética arcade e impacto visual.
  - **Dimensionamento Preciso da Malha:** O quad de renderização `PlaneMesh` foi reescalonado de $2.35\text{m}$ para $4.20\text{m}$, contendo com folga o raio real de corte de $1.66\text{m}$ das pontas da serra no `BladeSpinner`.
  - **Sincronização Dinâmica por Tier:** O script `cutter.gd` detecta o tier da lâmina e configura dinamicamente o número de pontas no shader (Tier 1 = 3, Tier 2 = 4, Tier 3 = 5, Tier 4 = 6).

---

## 2. Detalhes de Implementação

### A. Shader Espacial Analítico (`shaders/blade_slash.gdshader`)
- **Render Mode:** `render_mode unshaded, blend_add, depth_draw_never, cull_disabled;`
- **Cálculo Setorial Branchless:**
  ```glsl
  float num_points = float(max(blade_points, 1));
  float sector = 6.28318530718 / num_points;
  float max_arc = sector * arc_ratio;
  float rel_angle = mod(angle - offset_rad, 6.28318530718);
  if (rel_angle < 0.0) rel_angle += 6.28318530718;
  float t_angle = mod(rel_angle, sector);
  float t = clamp(t_angle / max(max_arc, 0.0001), 0.0, 1.0);
  ```
- **Afinamento Progressivo e Cauda Antialiased:**
  ```glsl
  float current_width = max(base_width * pow(1.0 - t, taper_power), 0.002);
  float r_center = tip_radius - (curve_inward * t);
  float dist = abs(r - r_center);
  float radial_alpha = smoothstep(current_width, current_width * 0.15, dist);
  float core_mask = smoothstep(current_width * 0.45, 0.0, dist) * pow(1.0 - t, 0.6);
  float trail_fade = pow(1.0 - t, fade_power);
  float final_alpha = radial_alpha * arc_mask * trail_fade * slash_intensity;
  ```

### B. Integração no `Cutter` (`scripts/cutter/cutter.gd`)
- `PlaneMesh.size = Vector2(4.2, 4.2)` no `blade_slash_mesh`.
- Atualização em `_update_blade_tier_visual()` do parâmetro `blade_points` (`3`, `4`, `5` ou `6`).
- Preservação da modulação contínua por velocidade de rotação e pulso multiplicador de Level Up.

---

## 3. Arquivos Modificados e Criados

- `shaders/blade_slash.gdshader`: Shader analítico multi-ponta com afinamento e fade exponencial.
- `shaders/blade_slash_material.tres`: Material base com novos parâmetros calibrados.
- `scripts/cutter/cutter.gd`: Dimensionamento para $4.2\text{m}$ e sincronização por tier.
- `tests/test_blade_pop_and_slash.gd`: Teste automatizado com validação de dimensões e pontas por tier.
- `docs/02_entidades_e_mecanicas/SISTEMA_DO_CORTADOR.md`: Atualização da documentação do subsistema.
- `docs/04_sistemas_e_gameplay/GAME_FEEL_E_HAPTICS.md`: Atualização sensorial de Game Feel.
- `docs/historico_melhorias/INDICE_MELHORIAS.md`: Indexação da Melhoria 138.
- `project.godot`: Incremento SemVer para `0.12.63-alpha`.

---

## 4. Testes e Validação
- **Teste Automatizado de Slash:** `tests/test_blade_pop_and_slash.tscn` executado via Godot headless com 100% de aprovação:
  - Validação de dimensões $4.2\text{m} \times 4.2\text{m}$ do `PlaneMesh`.
  - Verificação de parâmetros `blade_points`, `base_width`, `taper_power`.
  - Sincronização de 3 pontas no Tier 1 e 6 pontas no Tier 4.
  - Modulação de intensidade por rotação e boost de Level Up.
- **Teste de Regressão de Progressão:** `tests/test_blade_progression.tscn` executado com 100% de sucesso.
- **Zero Warnings / Zero Erros:** Verificado no console Godot 4.7.1.
