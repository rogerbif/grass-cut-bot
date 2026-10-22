# Melhoria 073: Ajuste e Calibração do Colisor da Pedra (Redução de 50%) 🪨✂️

**Data:** 22/10/2026  
**Versão:** `v0.10.10-alpha` (Code: `1010`)  
**Status:** Concluído com Sucesso ✅  
**Arquivos Principais Afetados:**
- `scenes/obstacles/rock.tscn`
- `scripts/cutter/cutter.gd`
- `scripts/core/game_version.gd`
- `project.godot`
- `export_presets.cfg`
- `docs/02_entidades_e_mecanicas/SISTEMA_DE_OBSTACULOS_E_TERRENO.md`
- `docs/02_entidades_e_mecanicas/SISTEMA_DO_CORTADOR.md`

---

## 1. Motivação e Diagnóstico
Anteriormente, o colisor cilíndrico da rocha em `scenes/obstacles/rock.tscn` possuía raio de $0.36\text{m}$ (diâmetro de $0.72\text{m}$). Como a célula de grade dos níveis mede $0.80\text{m}$, o colisor ocupava 90% da largura do bloco, criando um volume de colisão largo que dificultava manobras de corte do cortador ao redor de pedras e estreitava passagens entre obstáculos.
Adicionalmente, na detecção perimétrica da lâmina no `cutter.gd`, a distância limite era calculada como `_cached_blade_radius + 0.36`, o que mantinha a lâmina e o chassi afastados excessivamente do núcleo sólido da rocha, impedindo a ceifa de grama rente à pedra.

---

## 2. Ações Executadas

### A. Redução do Raio do Colisor em 50% (`scenes/obstacles/rock.tscn`)
- O recurso `CylinderShape3D_rock` teve seu raio reduzido em 50%: de `radius = 0.36m` para **`radius = 0.18m`** (diâmetro de $0.36\text{m}$).
- A altura de $0.8\text{m}$ e o deslocamento vertical $Y = 0.4\text{m}$ foram preservados, mantendo a integridade da barreira vertical impenetrável contra pulos ou encavalamentos do cortador.

### B. Detecção Dinâmica de Colisor no Cortador (`scripts/cutter/cutter.gd`)
- Em `_check_obstacle_collisions()`, a constante fixa de $0.36\text{m}$ foi substituída por consulta dinâmica ao nó `CollisionShape3D` do obstáculo:
  - Recupera `(shape as CylinderShape3D).radius` com fallback defensivo para `0.18m`.
  - Distância perimétrica calibrada: `var blade_reach: float = _cached_blade_radius + obs_radius`.
  - Cálculo de overlap instantâneo e ricochete agora respondem com precisão milimétrica ao novo perímetro de $0.18\text{m}$, permitindo ao jogador cortar grama muito mais próxima à rocha sem sofrer ricochetes falsos.

### C. Versionamento SemVer e Documentação Canônica
- Bump SemVer de PATCH: versão elevada para `v0.10.10-alpha` (code: `1010`) em `game_version.gd`, `project.godot` e `export_presets.cfg`.
- Documentação canônica atualizada em `SISTEMA_DE_OBSTACULOS_E_TERRENO.md` e `SISTEMA_DO_CORTADOR.md`.

---

## 3. Verificação e Resultados
- **Colisão Física e Dinâmica:** A rocha possui agora um núcleo sólido reduzido em 50% ($R = 0.18\text{m}$), garantindo passagens muito mais fluidas e agradáveis ao jogador em todas as 20 fases.
- **Detecção da Serra:** A lâmina corta a vegetação tangencial à pedra sem ser repelida prematuramente a $1.26\text{m}$ de distância.
- **Zero Warnings:** Tipagem estrita e integridade defensiva mantidas.
