# Sistema de Controles Touch (Joystick Flutuante) 🕹️📱

Este documento descreve a mecânica de entrada tátil móvel, a lógica do joystick virtual dinâmico e o mapeamento de suporte para desktop em **Grass Cut Bot**.

---

## 1. Princípio do Joystick Flutuante (Floating Dynamic Joystick)

Projetado especificamente para uso com uma só mão (dedo polegar - *one-thumb play*):
1. **Área Ativa:** Ancorada exclusivamente na metade inferior da tela (`anchor_top = 0.4`, `anchor_bottom = 1.0`). Isso impede que toques no controle bloqueiem botões do Top HUD ou a visão principal do cortador.
2. **Definição da Origem Dinâmica:** O ponto onde o dedo encosta na tela no evento `InputEventScreenTouch` (ou clique do mouse) torna-se a coordenada central da base do joystick.
3. **Arrasto e Vetor de Saída:**
   - O deslocamento em relação à base calcula a direção e intensidade.
   - O pino visual (*stick thumb*) é delimitado ao raio máximo (`max_radius = 75.0 px`).
4. **Zona Morta Central (`dead_zone = 12.0 px`):**
   - Microdeslocamentos involuntários abaixo de 12 pixels geram vetor nulo, evitando tremores indesejados da serra.
   - Acima da zona morta, o valor de magnitude é normalizado linearmente de `0.0` a `1.0`.
5. **Soltura e Desativação:**
   - Ao soltar o toque, o joystick zera o vetor de direção e oculta seus elementos visuais na tela.

---

## 2. Renderização Vetorial Nativa (`_draw`)

Para máxima nitidez em qualquer densidade de pixels mobile (telas HD, Full HD e Quad HD) sem peso de texturas bitmapped:
- O joystick é desenhado proceduralmente via métodos CanvasItem da Godot:
  - Base: Círculo translúcido suave (`Color(1.0, 1.0, 1.0, 0.25)`) e anel externo antialiased.
  - Stick: Círculo mais brilhante (`Color(1.0, 1.0, 1.0, 0.65)`) com contorno destacado.

---

## 3. Compatibilidade com Teclado e Mouse no PC

Para permitir iterações de desenvolvimento e testes instantâneos no ambiente de desenvolvimento:
- **Mouse:** O mouse simula toques de tela graças ao parâmetro `pointing/emulate_touch_from_mouse = true` em `project.godot`.
- **Teclado:** Quando não houver toque ativo na tela, o script lê diretamente as teclas **WASD** ou as **Setas do Teclado**, convertendo a direção ortogonal/diagonal em vetor unitário e repassando ao cortador.
