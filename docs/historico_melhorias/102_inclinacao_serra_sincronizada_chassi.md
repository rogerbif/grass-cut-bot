# Histórico de Melhorias: 102 - Sincronização da Inclinação da Serra com o Chassi do Robô 🪚🤖

**Data:** 25 de Outubro de 2026  
**Versão:** `v0.12.27-alpha`  
**Escopo:** Entidade Cortador (`scripts/cutter/cutter.gd`), Robô do Menu (`scripts/menu/menu_bot.gd`), Dinâmica Procedural e Game Feel.

---

## 1. Contexto e Motivação

Durante a aceleração e frenagem no gameplay, o chassi do cortador (`robot_body`) utiliza física procedural com inclinação longitudinal (*pitch* de até $\pm 6.0^\circ$) e inclinação lateral (*roll* de até $\pm 4.5^\circ$), além de oscilação vertical da suspensão.

Entretanto, o rotor da serra circular (`BladeSpinner`) permanecia originalmente na raiz do robô (`Robot/BladeSpinner`), como nó irmão do chassi (`Robot/Body`). Em consequência desse desacoplamento na hierarquia original do glTF, a serra ficava sempre estática no plano horizontal ($X=0, Z=0$). Quando o robô acelerava para frente e mergulhava a frente da carcaça amarela (`blade_container`), a lâmina não acompanhava a inclinação, atravessando a lataria ou parecendo descolada do veículo.

Esta melhoria sincroniza em tempo real a atitude angular (pitch, roll, yaw) e a suspensão da lâmina com o chassi, mantendo a serra perfeitamente coplanar à abertura do deck protetor.

---

## 2. Implementação Técnica

### A. Reparentagem Dinâmica em Tempo de Execução
Em [`scripts/cutter/cutter.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/cutter/cutter.gd) e [`scripts/menu/menu_bot.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/menu/menu_bot.gd), o nó `BladeSpinner` é reparentado para dentro de `robot_body` logo no `_ready()`:
```gdscript
if blade_spinner != null and robot_body != null:
	blade_spinner.reparent(robot_body, true)
```

Como `robot_body` e `blade_spinner` compartilham a mesma escala visual ($0.62\times$) e origem em `Robot`, a posição local da serra dentro do corpo se consolida exatamente em $(0.0, 0.642, 0.0)$, concentricamente ao deck protetor (`blade_container`).

### B. Rotação Contínua no Eixo Normal Local
Ao ser filha de `robot_body`, a serra herda nativamente todas as transformações de rotação:
- **Pitch:** Acompanha a inclinação para frente na aceleração frontal e para trás na ré.
- **Roll:** Inclina para o lado da curva suavemente.
- **Yaw:** Vira junto com a frente do robô.
- **Suspensão:** Sobe e desce em harmonia com o *bobbing* vertical do chassi.

O comando `blade_spinner.rotate_y(deg_to_rad(current_blade_speed * delta))` passa a atuar sobre o eixo $Y$ **local** da lâmina, que é sempre perpendicular ao deck inclinado, garantindo rotação circular contínua sem wobble ou distorção.

### C. Preservação do Guardrail #5 (Corte Radial Omnidirecional)
A área de colisão de corte (`BladeArea`) permaneceu como nó independente na raiz do `Cutter`, mantendo seu formato cilíndrico na base ($Y = 0.45\text{m}, h = 0.4\text{m}$) sem inclinação física. Isso cumpre rigorosamente o Mandamento 5 do `GEMINI.md`, assegurando detecção simétrica de vegetação em 360° em qualquer direção.

---

## 3. Validação e Qualidade

1. **Teste Automatizado de Inclinação ([`tests/test_blade_inclination.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/tests/test_blade_inclination.tscn)):**
   - Valida que `blade_spinner` é reparentado para `Body`.
   - Comprova desvio angular zero ($0.0^\circ$) entre o vetor normal da lâmina e o vetor normal do chassi em pitch $+6^\circ$, pitch $-4^\circ$ e roll $+4.5^\circ$.
   - Comprova coplanaridade total durante a rotação contínua da lâmina.
   - Valida idêntico comportamento no `MenuBot`.
2. **Suíte SaveGame:** 100% de aprovação em todos os testes de persistência.
3. **Zero Warnings:** Compilação em modo headless confirmada com 0 warnings e 0 erros.
