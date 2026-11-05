# Melhoria 174: Ajuste de Cor da Flor Silvestre — Miolo Amarelo e Gradiente de Pétalas Rosa 🌸💛

## 🎯 Objetivo
Atender ao feedback visual da **Flor Silvestre** (`flower`, `flower_01.glb`):
1. **Miolo Amarelo:** O centro/disco central da flor passa a ser amarelo solar vibrante (`#FFE00D`, `Color(1.0, 0.88, 0.05, 1.0)`).
2. **Pétalas Rosa com Gradiente:** As pétalas passam a ser rosa, com a parte interna (base junto ao miolo) em um tom mais escuro/encorpado (`Color(0.88, 0.10, 0.48, 1.0)`) e as pontas em um rosa suave e iluminado (`Color(1.0, 0.58, 0.80, 1.0)`).

---

## 🛠️ Diagnóstico e Causa Raiz
Na auditoria dos 18 componentes (islands) de malha de `Flower_Petals` no Blender:
- Os miolos circulares das duas hastes (Island 8 na haste principal e Island 17 na haste secundária) estavam marcados incorretamente com $G = 0.0$, enquanto duas pétalas externas (Island 6 e Island 7) estavam marcadas com $G = 1.0$.
- Isso fazia com que duas pétalas ficassem amarelas e o miolo central ficasse rosa.
- O gradiente de ponta via `COLOR.a` estava com amplitude muito curta ($0.40 \sim 0.78$) derivada de um bounding box global, tornando imperceptível a transição entre base e ponta de cada pétala individual.

---

## 🔧 Alterações Realizadas

### 1. Correção Anatômica do Modelo 3D (`assets/models/flower_01.glb`)
- **Miolos Centrais (Island 8 e Island 17):**
  - Marcados com $G = 1.0, R = 0.0, B = 0.0, A = 1.0$.
  - Como $R = 0.0$, os miolos permanecem fixos na haste durante o Hit 1 e Hit 2, sendo colhidos apenas no Hit 3 fatal.
- **Pétalas em Duas Levas Alternadas:**
  - Externas ($R = 0.5$, colapsam no Hit 1): Island 0, 2, 3, 7 (com Island 0 e 2 marcadas com $B = 1.0$ para desprendimento físico).
  - Internas ($R = 1.0$, colapsam no Hit 2): Island 1, 4, 5, 6.
  - O mesmo padrão radial alternado foi calibrado para a haste secundária (Island 9..16).
- **Gradiente Radial Exato por Pétala via `COLOR.a`:**
  - Para cada vértice de cada pétala individual, a distância euclidiana até o centro do miolo correspondente foi normalizada: $d_{min} \rightarrow A = 0.0$ (base interna) e $d_{max} \rightarrow A = 1.0$ (ponta externa).

### 2. Shader `shaders/interactive_flower.gdshader`
- Adicionado uniform `uniform vec4 petal_inner_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);`.
- Quando `petal_inner_color.a > 0.001`, interpola suavemente entre `petal_inner_color` na base ($A = 0.0$) e `petal_color` na ponta ($A = 1.0$).
- Preserva retrocompatibilidade transparente com as outras 7 espécies de flores (quando `petal_inner_color` tem alpha 0, utiliza o escurecimento via `shade = mix(0.55, 1.0, COLOR.a)`).
- `center_color` (amarelo) não é mais escurecido por `shade`, permanecendo limpo e saturado.

### 3. Material e Paleta de Cores
- **`shaders/interactive_flower_material.tres`:**
  - `center_color = Color(1.0, 0.88, 0.05, 1.0)`
  - `petal_inner_color = Color(0.88, 0.10, 0.48, 1.0)`
  - `petal_color = Color(1.0, 0.58, 0.80, 1.0)`
- **`scripts/plants/plant.gd` & `scripts/editor/level_editor_ui.gd`:**
  - Atualizadas as cores de confetes, pétalas soltas e HUD para o rosa característico da espécie (`Color(1.0, 0.58, 0.80)`).

---

## ✅ Validação e Verificação
1. **Render 3D no Blender:** Verificação por imagem renderizada com materiais e iluminação idênticos à engine.
2. **Reimportação Atômica:** Executado `godot --headless --import` com compilação bem-sucedida de `flower_01.glb`.
3. **Suite Headless:** `godot --headless -s tests/test_flower_detach.gd` executado com status `RESULTADO FINAL 8 FLORES: OK`.
4. **SemVer:** Versão incrementada para `0.12.120-alpha`.
