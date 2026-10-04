# Portabilidade e Otimização para Android 📱🚀

Este documento reúne os requisitos técnicos, presets de exportação e boas práticas de desempenho para a execução suave de **Grass Cut Bot** no ecossistema Android.

---

## 1. Configurações da Janela e Orientação

- **Orientação Fixa (Portrait):** Configurada como `window/handheld/orientation = 1` (`portrait`). A rotação da tela é bloqueada no manifesto Android para evitar redraws custosos e garantir jogabilidade confortável com uma só mão.
- **Resolução Base:** Viewport virtual em `720 x 1280` pixels com `window/stretch/mode = "canvas_items"` e `window/stretch/aspect = "keep_width"`. Essa configuração preenche perfeitamente aparelhos de proporções alongadas modernas (19.5:9 e 20:9) sem cortes nos elementos críticos do HUD.

---

## 2. Escolha do Renderizador da Godot 4

- **Modo Padrão (`mobile`):**
  - Utiliza a API Vulkan mobile moderna da Godot 4.
  - Oferece suporte eficiente a materiais StandardMaterial3D e sombras dinâmicas de alta fidelidade.
- **Alternativa de Compatibilidade Ampla (`gl_compatibility`):**
  - Utiliza OpenGL ES 3.0 / WebGL2.
  - Recomendado se o público alvo incluir smartphones Android de entrada com drivers Vulkan instáveis.

---

## 3. Diretrizes de Otimização para 60 FPS Mobile

1. **Baixo Número de Draw Calls (Batching):**
   - Os materiais compartilham parâmetros padronizados de sombreamento.
   - Os tufos de vegetação utilizam malhas simples de prismas e caixas, mantendo a contagem total de polígonos da cena abaixo de 30.000 triângulos.
2. **Sombra Direcional Limitada:**
   - O alcance da sombra é delimitado a $40\text{m}$ (`directional_shadow_max_distance = 40.0`), evitando cálculos de matriz de sombra além dos limites da ilha.
3. **Gerenciamento de Memória de Partículas:**
   - Emissores `CPUParticles3D` com emissão por explosão e vida útil curta ($\le 0.6\text{s}$) garantem reciclagem imediata de memória sem picos de garbage collector.
