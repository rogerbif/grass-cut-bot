# Melhoria 188: Contorno Duplo (1px Preto + 2px Branco) e Restauração de Cores Canônicas nos Ícones de Metas 🎨🌿

**Status:** Concluído  
**Data:** 2026-11-06  
**Versão Alvo:** Game SemVer `v0.12.138-alpha` (Patch 138)  

---

## 1. Contexto e Motivação
Após a introdução da borda cartoon em `v0.12.136-alpha`, foi identificado que:
1. O shader de contorno `goal_icon_outline.gdshader` sobrepunha a cor do pixel com a cor pura da textura (`COLOR = col;`), descartando o `COLOR` de entrada (`rect.modulate`) fornecido pelo CanvasItem. Como os SVGs das lâminas de grama (`illus_grass_blades.svg`) e pétalas de flor (`illus_flower_petals.svg`) utilizam tons de cinza/branco como base para tingimento dinâmico, todas as gramas estavam sendo renderizadas com lâminas brancas no Top HUD.
2. A solicitação visual demandava um estilo refinado de contorno duplo (estilo adesivo cartoon profissional): uma borda externa preta justa de 1px contornando a geometria, seguida por uma segunda borda externa branca de 2px envolvendo a borda preta, garantindo contraste excepcional tanto em cenários claros quanto escuros e sobre os badges da interface.

---

## 2. Alterações Realizadas

### A. Shader de Contorno Duplo (`shaders/goal_icon_outline.gdshader`)
- **Preservação de Modulação (`modulate`):** O pixel do sprite agora preserva a modulação com `vec4 modulated_col = vec4(col.rgb * COLOR.rgb, col.a * COLOR.a);`. Quando `col.a > 0.12`, o shader renderiza a cor modulada, restaurando com perfeição as cores canônicas de cada variedade de grama (verde esmeralda, amarelo solar, azul costeiro, violeta crepúsculo, etc.) e de flores.
- **Amostragem em Dois Estágios com Suavização:**
  - **Raio Interno (1px - Preto):** Amostras a `inner_width = 1.2` (com passos cardinais a 50% de distância para evitar lacunas em extremidades finas como pontas de folhas) preenchem a borda preta `inner_outline_color = vec4(0.0, 0.0, 0.0, 1.0)`.
  - **Raio Externo (2px - Branco):** Amostras em anel intermediário e 16 ângulos radiais circulares a `outer_width = 3.6` (1.2 + 2.4 = 3.6) preenchem a borda externa branca `outer_outline_color = vec4(1.0, 1.0, 1.0, 1.0)`.

### B. Atualização na Fábrica de Ícones (`scripts/ui/goal_icon_factory.gd`)
- Parametrização da chamada estática com os novos uniforms:
  - `inner_outline_color`: `Color(0.0, 0.0, 0.0, 1.0)`
  - `outer_outline_color`: `Color(1.0, 1.0, 1.0, 1.0)`
  - `inner_width`: `1.2` (~1px)
  - `outer_width`: `3.6` (~3px total = 1px preto + 2px branco)

### C. Teste Automatizado de Regressão (`tests/test_progression_and_goal_effects.gd`)
- Validação no teste headless da existência dos parâmetros `inner_outline_color` e `outer_outline_color`.
- Verificação assercional de que `grass_green` e `grass_yellow` possuem modulação distinta e não-branca na camada de lâminas.

---

## 3. Verificação e Testes
- Execução do teste headless Godot 4.7.2:
  ```powershell
  & "C:\Users\User\OneDrive\Documentos\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_progression_and_goal_effects.gd
  ```
  Resultado: **TODOS OS TESTES PASSARAM COM SUCESSO!** (0 erros, 0 falhas).
