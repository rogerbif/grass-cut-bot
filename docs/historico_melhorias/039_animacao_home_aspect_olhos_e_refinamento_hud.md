# Melhoria 039: Animação Autônoma na Home, Proporção 3:1 de Olhos LED e Refinamento de UI [v0.7.2] 🌿🤖🎨

Este documento consolida o conjunto de melhorias visuais, comportamentais e ergonômicas implementadas na tela inicial (**Home**), no modelo 3D do cortador e na barra de navegação (**BottomNavBar**).

---

## 📋 Resumo Executivo
- **Data da Conclusão:** Outubro de 2026
- **Versão SemVer:** `v0.7.2` (Patch release - Refinamentos de UI, proporcionalidade de texturas e animação autônoma)
- **Domínio:** Interface de Usuário (HUD), Modelagem 3D (Blender), Shaders e Inteligência Comportamental
- **Objetivos Entregues:**
  1. **Ativação dos Olhos de LED no Menu:** O robô do menu (`menu_bot.tscn`) agora exibe o visor de LED aceso com o material `eye_display_material.tres` e o nó `RobotEyes`.
  2. **Assentamento no Solo (Fim da Flutuação):** Remoção da flutuação senoidal no ar (`idle_bob`), apoiando o pneu firmemente no piso da ilha.
  3. **Locomoção Autônoma da Home:** O robô avança suavemente $+0.50\text{m}$, para, faz curvas exploratórias ($\pm 22^\circ$) com a serra girando e a roda rolando, e retorna de marcha à ré para a base.
  4. **Articulação da Cabeça e Expressões:** Movimentos randômicos da cabeça (olhar para os lados, cima e baixo), piscar orgânico e alternância de emoções (`NORMAL`, `HAPPY`, `ALERT`, `WINK`, `VICTORY`).
  5. **Correção do Aspect Ratio dos Olhos (Proporção 3:1):** Reestruturação do atlas vetorial `eyes_atlas.svg` para grade $2 \times 6$, garantindo círculos 100% redondos e volumosos fiéis ao concept art (eliminando o achatamento).
  6. **Alinhamento do Título à Direita:** Na TopBar do menu, o texto *"Ilha Tropical"* foi alinhado à direita junto ao botão de configurações `[⚙️]`.
  7. **Capa da Lâmina Rente à Serra:** No Blender (`grass_bot_00.blend`), a abertura do `blade_container` foi reduzida de $9.6\text{cm}$ para $4.5\text{cm}$, eliminando o vão sobressalente e abraçando a lâmina de $4.2\text{cm}$ com folga de $1.5\text{mm}$.
  8. **Ícones da Navbar Ampliados:** A `BottomNavBar` teve sua altura expandida para $104\text{px}$, com ícones em tamanho ampliado (`font_size = 28`) e legendas rebaixadas com espaçamento vertical confortável.

---

## 🔍 Comparativo: Cenário Anterior vs Novo Cenário

| Componente | Antes | Agora |
| :--- | :--- | :--- |
| **Robô na Home** | Visor apagado, flutuando no ar sem andar | Olhos acesos, apoiado no solo, anda 0.5m, dá ré, vira chassi e mexe a cabeça |
| **Olhos de LED** | Elipses achatadas (distorção por grade quadrada 1:1) | Círculos perfeitamente redondos e grandes (grade proporcional 3:1) |
| **Capa da Lâmina** | Vão vazio de 2.7cm embaixo da serra | Fenda rente de 4.5cm abraçando a lâmina de 4.2cm com 1.5mm de folga |
| **TopBar do Menu** | Título centralizado no meio do vazio | Alinhado à direita encostado junto ao botão de configurações ⚙️ |
| **BottomNavBar** | Ícones pequenos (font_size 14) colados no texto | Ícones ampliados (font_size 28) com textos confortavelmente rebaixados |

---

## 🛡️ Conformidade de Guardrails Invariantes
- **Zero Warnings Estrito (Guardrail 1):** Console Godot 4.7.1 validado com 0 warnings e 0 erros.
- **Tipagem Estática (Guardrail 10):** 100% dos métodos e propriedades com tipagem forte GDScript 4.
- **Pipeline Blender glTF Seguro (Guardrail 12):** Reexportação do `grass_bot.glb` com `export_apply=True` e `export_yup=True`.

---

## 📦 Artefatos e Arquivos Modificados
- `scenes/menu/main_menu.tscn`: Alinhamento do TitleContainer à direita.
- `scenes/menu/bottom_nav_bar.tscn`: Reestruturação com VBox, IconLabel (28px) e TitleLabel rebaixado.
- `scripts/menu/menu_bot.gd`: Máquina de estados de locomoção, articulação de cabeça, olhos de LED e apoio no solo.
- `scenes/menu/menu_bot.tscn`: Instanciação do nó `RobotEyes`.
- `assets/textures/cutter/eyes_atlas.svg`: Novo layout 2x6 eliminando o achatamento.
- `shaders/eye_display.gdshader` & `shaders/eye_display_material.tres`: Atualizados para `atlas_grid = Vector2(2, 6)`.
- `assets/models/grass_bot.glb` & `grass_bot_00.blend`: Ajuste da fenda do `blade_container` para $4.5\text{cm}$.
- `project.godot`: Versão elevada para `v0.7.2`.
