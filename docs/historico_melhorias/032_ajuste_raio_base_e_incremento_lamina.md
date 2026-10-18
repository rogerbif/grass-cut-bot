# Melhoria 032: Redução do Raio Base da Lâmina (0.90m) e Calibração do Incremento (0.10m) 🪚📏

## 1. Contexto e Motivação
A serra circular do cortador contava anteriormente com um raio base inicial de $1.18\text{m}$ e um incremento de $+0.15\text{m}$ a cada nível de upgrade. Para refinar o ritmo de progressão, proporcionar maior sensação de precisão inicial na pilotagem e tornar os upgrades graduais mais perceptíveis e satisfatórios, o raio inicial foi calibrado para **$0.90\text{m}$** com incremento de **$+0.10\text{m}$** por nível.

---

## 2. Alterações Realizadas

### A. Gerenciador de Upgrades (`scripts/core/upgrade_manager.gd`)
- Ajustada a função `get_blade_radius()` para retornar:
  $$R_{\text{lâmina}} = 0.90\text{m} + (\text{radius\_level} - 1) \times 0.10\text{m}$$

### B. Cortador (`scripts/cutter/cutter.gd` e `scenes/cutter/cutter.tscn`)
- Atualizado o valor padrão/fallback de `blade_radius` no método `_update_shader_globals()` para `0.90`.
- O cálculo da escala visual do rotor (`BladeSpinner`) continua derivado da geometria base modelada ($1.18\text{m}$ no jogo):
  $$\text{visual\_scale} = \frac{R_{\text{lâmina}}}{1.18}$$
  Resultando em escala inicial $\approx 0.763$, alinhando a representação visual da malha 3D perfeitamente com a nova área cilíndrica de corte de $0.90\text{m}$.
- Atualizado o sub-recurso `CylinderShape3D` (`id="CylinderShape3D_f1mop"`) em `scenes/cutter/cutter.tscn` de `radius = 1.18` para `radius = 0.9`.

### C. Documentações Canônicas e SemVer
- Atualizado [SISTEMA_DO_CORTADOR.md](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/docs/02_entidades_e_mecanicas/SISTEMA_DO_CORTADOR.md) com o novo raio base de $0.90\text{m}$ e fórmula com incremento de $+0.10\text{m}$.
- Atualizado [ECONOMIA_E_OFICINA.md](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/docs/04_sistemas_e_gameplay/ECONOMIA_E_OFICINA.md) na tabela de upgrades de oficina.
- Versão do projeto incrementada para `0.5.5` em `project.godot`.

---

## 3. Impacto no Gameplay
- No nível 1, a lâmina tem diâmetro total de $1.80\text{m}$ ($R = 0.90\text{m}$), exigindo passadas mais concentradas sobre os tufos.
- No nível 2: $R = 1.00\text{m}$ (diâmetro $2.00\text{m}$).
- No nível 3: $R = 1.10\text{m}$.
- No nível 4: $R = 1.20\text{m}$.
- A sincronia com o shader de curvatura da grama (`cutter_interact_radius = blade_radius + 0.95`) permanece perfeitamente proporcional.
