# Melhoria 238: Calibração de Gradiente e Sombra Toon da Grama Branca Cristalina (`grass_white`)

**Data:** 11/11/2026  
**Versão:** `v0.12.192-alpha`  
**Status:** Concluído ✅  
**Autor:** Antigravity AI Pair Programmer & Usuário  

---

## 1. Contexto e Diagnóstico

Durante gameplay em fases com presença de `grass_white` (como a Fase 04), constatou-se que as lâminas da Grama Branca Cristalina perdiam o volume e apresentavam aspecto visual de "malha fantasma / textura ausente (glitch)":
- O material `interactive_grass_white_material.tres` possuía `color_light = Color(0.98, 0.99, 1.0, 1.0)` e `color_shadow = Color(0.72, 0.78, 0.86, 1.0)`.
- Sob a incidência direta da `DirectionalLight3D` e iluminação ambiente da cena, o albedo somado ultrapassava 1.0, causando estouramento (blowout) total para branco absoluto (`#FFFFFF`) sem sombreamento próprio perceptível.
- Em fronteiras onde `grass_white` e `grass_green` se encontram no mesmo canteiro (como no Nível 4), lâminas brancas pontiagudas se projetavam de dentro dos tufos verdes, simulando defeito gráfico na malha de grama.

---

## 2. Ações Implementadas

1. **Recalibração Botânica do Material Toon (`shaders/interactive_grass_white_material.tres`):**
   - `color_light`: Redefinido para `Color(0.82, 0.88, 0.92, 1.0)` (tom prateado/gelo cristalino acetinado de alta nobreza).
   - `color_base`: Ajustado para `Color(0.24, 0.32, 0.40, 1.0)` (raiz azul-acinzentada profunda que confere ancoragem e solidez biológica ao solo).
   - `color_shadow`: Ajustado para `Color(0.46, 0.54, 0.64, 1.0)` (sombra rica com contraste toon marcante que revela o balanço e curvatura das lâminas).
   - `rim_color`: Suavizado para `Color(0.90, 0.95, 1.0, 1.0)`.

2. **Auditoria de Integridade Botânica:**
   - Comprovada a preservação de 100% das 36 variedades botânicas do jogo em `tests/test_flower_materials_integrity.gd`.
   - Confirmação de que as flores com pétalas brancas (como Margaridas e Rosas Brancas) mantêm miolos dourados/amarelos e caules/folhas verdes intactos.

---

## 3. Validação e Resultados

- **Teste Automatizado de Integridade:** `tests/test_flower_materials_integrity.gd` passou com 100% de sucesso.
- **Renderização GPU Vulkan:** Comprovado visualmente em GPU física o sombreamento volumétrico prateado nítido sem estouro branco.
- **Zero Warnings:** Console Godot permanece rigorosamente com 0 erros e 0 warnings.
