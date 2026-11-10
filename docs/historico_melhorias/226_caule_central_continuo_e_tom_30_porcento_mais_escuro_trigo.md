# Histórico de Melhoria: Caule Central Contínuo e Tom 30% Mais Escuro do Trigo (`wheat_01.glb`) 🌾✨

**Data:** 10 de Novembro de 2026  
**Versão:** `v0.12.179-alpha`  
**Autor:** Antigravity (Google DeepMind)  
**Status:** Concluído ✅  

---

## 1. Contexto e Motivação
Após a reformulação anatômica 3D da espiga de trigo (Melhoria 225), o usuário apontou duas oportunidades de refinamento:
1. **Ausência do Caule Central:** As folhas laterais estavam flutuando no ar abaixo de $Z = 0.80\text{m}$, pois o modelo original do Sketchfab dependia de um cartão plano 2D com textura transparente para desenhar o caule, sem geometria cilíndrica tridimensional sólida conectando o solo às folhas e à espiga.
2. **Calibração de Cor (30% Mais Escuro):** O tom amarelo dourado estava muito claro/brilhante (neon), precisando escurecer em 30% tanto a parte clara (`color_light`) quanto a base escura (`color_base` e `color_shadow`).

---

## 2. Implementação Técnica

### A. Construção Geométrica do Caule Central no Blender (`wheat.blend`)
- **Colmo Cilíndrico Hexagonal:** Criado um cilindro contínuo de 6 lados com 32 anéis distribuídos ao longo de toda a altura da planta (de $Z = 0.00\text{m}$ no solo até $Z = 1.12\text{m}$ no ápice da espiga).
- **Afunilamento Natural:**
  - Base no solo ($Z = 0.00\text{m}$): raio de $0.012\text{m}$ (diâmetro ~2.4 cm).
  - Inserção das folhas ($Z = 0.05\text{m} \dots 0.75\text{m}$): engloba perfeitamente as bases de todos os folíolos laterais originais ($R \approx 0.003 \dots 0.009\text{m}$), eliminando qualquer folha flutuante.
  - Base da espiga ($Z = 0.80\text{m}$): transição suave para raio de $0.009\text{m}$.
  - Ráquis terminal ($Z = 1.12\text{m}$): afunila para $0.0045\text{m}$ integrando-se ao grão apical.
- **Fechamento e Normais Suaves:** Fundo fechado no solo com fan triangular e normais de face suavizadas (`smooth = true`) para reflexão Toon limpa.

### B. Calibração Cromática 30% Mais Escura
- **`shaders/interactive_wheat_material.tres`:**
  - `color_light`: reduzido de `Color(1.0, 0.88, 0.25)` para `Color(0.70, 0.62, 0.18)` (30% mais escuro, tom âmbar/mel dourado encorpado).
  - `color_base`: reduzido de `Color(0.38, 0.22, 0.05)` para `Color(0.27, 0.15, 0.04)` (30% mais escuro, tom terra profundo nas raízes).
  - `color_shadow`: reduzido de `Color(0.68, 0.46, 0.12)` para `Color(0.48, 0.32, 0.08)`.
  - `rim_color`: reduzido para `Color(0.70, 0.66, 0.49)`.
- **`scripts/plants/vegetation_grid.gd`:**
  - `_resolve_type_particle_color("wheat")`: ajustado para `Color(0.69, 0.55, 0.10)` para coerência sensorial em partículas e HUD.
- **Albedo Neutro em `wheat_01.glb`:**
  - `M_Wheat_Default` no Blender ajustado para `(0.67, 0.54, 0.13, 1.0)`.

### C. Mapeamento Contínuo e Reimportação
- $UV.y$ mapeado linearmente de $1.0$ (solo) a $0.0$ (topo) alinhado com `invert_height = true`.
- Cores de vértice assadas com `COLOR.r = norm_h` (0.0 no solo a 1.0 no ápice), garantindo gradiente vertical fiel da raiz escura para as pontas douradas.
- Reimportação binária atômica no Godot via `godot --headless --import` (Mandamento 12).

---

## 3. Validação e Testes
- **Testes Automatizados:** `tests/test_wheat_level_02.tscn` e `tests/test_all_botanical_variations.gd` aprovados com 100% de sucesso e 0 warnings.
- **Verificação Visual:** Captura no Godot Engine (`test_wheat_godot_stem_dark.png`) confirmou a presença sólida do caule central e a tonalidade âmbar dourada 30% mais escura.
