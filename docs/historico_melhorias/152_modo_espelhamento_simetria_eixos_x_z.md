# Modo de Espelhamento e Simetria nos Eixos X e Z no Editor de Fases 🪞✨

**Versão da Implementação:** `v0.12.78-alpha`  
**Data:** 29 de Outubro de 2026  
**Responsável:** Antigravity (Google Deepmind)  
**Status:** Concluído com 100% de Sucesso (Zero Warnings, Zero Erros)

---

## 1. Contexto e Motivação

Durante o level design e a composição de ilhas 3D no editor de fases PC (`LevelEditor`), a criação de ilhas orgânicas balanceadas, campos de flores geométricos, labirintos simétricos e arenas competitivas demandava desenhar manualmente cada quadrante ou hemisfério repetidamente.

O usuário solicitou explicitamente:
> *"no editor quero só o espelhamento"*

A funcionalidade implementada introduz suporte nativo a **Modos de Espelhamento e Simetria nos Eixos X e Z**, integrando pintura em tempo real para terreno, vegetação e objetos com preview holográfico simultâneo e rotação espelhada matematicamente precisa.

---

## 2. Arquitetura e Modos de Operação

O sistema implementa o enum `MirrorMode` em [`scripts/editor/level_editor.gd`](../../scripts/editor/level_editor.gd):

```gdscript
enum MirrorMode {
    NONE = 0,            # Desligado (padrão)
    HORIZONTAL_X = 1,    # Espelho no Eixo X (esquerda <-> direita)
    VERTICAL_Z = 2,      # Espelho no Eixo Z (superior <-> inferior)
    QUAD_XZ = 3          # Quádruplo (X + Z simultâneos nos 4 quadrantes)
}
```

### 2.1 Atalho e Ciclo de Alternância
- **Atalho de Teclado:** Tecla `X` no editor.
- **Botão UI:** `btn_mirror` no painel esquerdo inferior da interface (`level_editor_ui.gd`), com indicação reativa de cor quando ativo e rótulos contextuais:
  - `🪞 Espelho [X]: Desligado` (cor padrão)
  - `🪞 Espelho [X]: Horizontal (X)` (destaque ciano/neon ativo)
  - `🪞 Espelho [X]: Vertical (Z)` (destaque ciano/neon ativo)
  - `🪞 Espelho [X]: Quádruplo (X+Z)` (destaque ouro/âmbar ativo)

---

## 3. Matemática de Transformação e Espelhamento

### 3.1 Posições Espelhadas na Grade e no Mundo
Dada a célula central da grade $\vec{c} = (cx, cz)$ com dimensões $W \times H$:
- Espelho Horizontal ($X$): $mx = (W - 1) - cx$, $mz = cz$
- Espelho Vertical ($Z$): $mx = cx$, $mz = (H - 1) - cz$
- Espelho Quádruplo ($XZ$): combina $(mx, cz)$, $(cx, mz)$ e $(mx, mz)$

Para superfícies contínuas de grama vetorial (`VectorGrassStamp`), a transformação reflete os polígonos através dos eixos de mundo $X = 0.0$ e $Z = 0.0$:
- Inversão em $X$: $(x, z) \mapsto (-x, z)$
- Inversão em $Z$: $(x, z) \mapsto (x, -z)$
- Inversão em $XZ$: $(x, z) \mapsto (-x, -z)$

### 3.2 Rotação Espelhada de Tiles e Invariante de Flores
- **Espelho Horizontal ($X$):**
  $$\text{rot}_x = (360 - \text{rot}) \pmod{360}$$
  - $0^\circ \mapsto 0^\circ$, $90^\circ \mapsto 270^\circ$, $180^\circ \mapsto 180^\circ$, $270^\circ \mapsto 90^\circ$.
- **Espelho Vertical ($Z$):**
  $$\text{rot}_z = (540 - \text{rot}) \pmod{360}$$
  - $0^\circ \mapsto 180^\circ$, $90^\circ \mapsto 90^\circ$, $180^\circ \mapsto 0^\circ$, $270^\circ \mapsto 270^\circ$.
- **Invariante das Flores:** Em estrita conformidade com as regras do projeto, flores nunca sofrem rotações arbitrárias, permanecendo sempre voltadas para a câmera do jogador ($\text{rot} = 0^\circ$), independentemente do eixo de espelhamento ativo.

---

## 4. Feedback Visual e Holograma em Tempo Real (`GridOverlay`)

1. **Linhas Guia de Eixo (`update_mirror_axis`):**
   - Linhas contínuas desenhadas em tom neon âmbar translúcido (`Color(0.95, 0.78, 0.35, 0.85)`) sobre a grade para demarcar os eixos de simetria ativos (eixo vertical para $X$, eixo horizontal para $Z$).
2. **Preview Holográfico Simultâneo:**
   - Durante o hover do pincel, todos os pontos e quadrantes espelhados são renderizados simultaneamente na grade translúcida, permitindo ao level designer visualizar exatamente o impacto da pintura antes de clicar.

---

## 5. Validação e Testes Automatizados

Foi criada uma suíte completa de testes unitários em [`tests/test_editor_mirror_mode.gd`](../../tests/test_editor_mirror_mode.gd):
1. `test_mirror_mode_cycling`: Validação do ciclo sequencial via tecla `X` (`NONE` $\to$ `HORIZONTAL_X` $\to$ `VERTICAL_Z` $\to$ `QUAD_XZ` $\to$ `NONE`).
2. `test_horizontal_x_mirroring`: Validação da pintura simétrica de terreno e rotação correspondente em $X$.
3. `test_vertical_z_mirroring`: Validação da pintura simétrica de rochas e rotação correspondente em $Z$.
4. `test_quad_mirroring`: Validação de pintura simultânea em 4 quadrantes.
5. `test_flower_camera_facing_invariant`: Confirmação de que flores sempre mantêm `rot = 0` em todos os espelhos.
6. `test_mirror_eraser`: Confirmação de que apagar (borracha) também opera nos eixos de simetria.

Resultado da execução headless:
```text
=== TESTES DE ESPELHAMENTO / SIMETRIA NO EDITOR CONCLUÍDOS COM SUCESSO! ===
Todos os testes passaram com 100% de sucesso e 0 warnings.
```
