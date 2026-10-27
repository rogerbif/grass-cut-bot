# Melhoria 133: Restauração da Configuração Original de Iluminação

**Data:** 27 de Outubro de 2026  
**Versão:** `v0.12.56-alpha`  
**Autor:** Antigravity  

---

## 1. Contexto e Motivação

A pedido do usuário (*"Volte a configuração de iluminação de antes de eu começar a alterar"*), toda a configuração de iluminação da cena de jogo (`scenes/main.tscn`), do menu inicial (`scenes/menu/main_menu.tscn`) e da classe `Main` (`scripts/main.gd`) foi restaurada rigorosamente para o estado anterior às alterações e experimentações de estúdio de shaders.

---

## 2. Parâmetros Restaurados

### 2.1. Luz Solar Principal (`DirectionalLight3D`)
- **Transform / Orientação:**  
  `Transform3D(0.866025, -0.353553, 0.353553, 0, 0.707107, 0.707107, -0.5, -0.612372, 0.612372, 0, 15, 0)`  
  Correspondente ao ângulo zenital angular original: `pitch = -45.0°`, `yaw = 30.0°` (mesmo padrão presente no Editor de Fases).
- **Energia da Luz:** Padrão original `1.0` (removida a sobre-elevação de `1.30`).
- **Remoção de Overrides no Script:** Removidas as linhas de `scripts/main.gd` que forçavam programaticamente a rotação `-37°, 40°` e energia `1.30`.

### 2.2. Ambiente e Luz Indireta (`WorldEnvironment`)
- **Gameplay (`scenes/main.tscn`):**
  - `ambient_light_energy = 0.85` (restaurado de `0.20`).
  - `ambient_light_color = Color(0.85, 0.92, 0.88, 1.0)`.
  - Proporciona claridade uniforme e acolhedora, impedindo que faces opostas ao sol fiquem excessivamente escuras.
- **Menu Inicial (`scenes/menu/main_menu.tscn`):**
  - `ambient_light_energy = 0.90` (restaurado de `0.45`).
  - `ambient_light_color = Color(0.88, 0.94, 0.92, 1.0)`.

---

## 3. Verificação Visual e Validação

- **Captura direta de Viewport:** A captura `snap_lighting_reverted.png` demonstra visual limpo, cores equilibradas e sombras suaves idênticas à estética consagrada do projeto.
- **Console Godot:** 0 erros e 0 warnings mantidos com tipagem estática e guardrails preservados.
