# Histórico de Melhoria: Gradiente Vertical de Base Escura em Todas as Variações de Grama 🌿🎨

**Data:** 10 de Novembro de 2026  
**Versão:** `v0.12.174-alpha`  
**Autor:** Antigravity (Google DeepMind)  
**Status:** Concluído ✅  

---

## 1. Contexto e Motivação
O usuário solicitou que todas as folhas e lâminas das variações de grama passassem a exibir um gradiente vertical de **base mais escura para a cor atual viva**, idêntico ao tratamento botânico realizado nas flores e caules:
- Anteriormente, o shader espacial `shaders/interactive_grass.gdshader` continha uma checagem `if (COLOR.a > 0.001) leaf_h = COLOR.r;`.
- Como a malha `grass_01.glb` exportada do Blender possui `COLOR.a = 1.0` por padrão e `COLOR.r` assado como a fase de balanço individual de cada lâmina (constante por folha, em torno de `0.70` a `0.95`), a altura vertical contínua da folha (`UV.y`) era ignorada.
- Consequentemente, cada lâmina recebia apenas a cor do ápice (`color_light`), suprimindo a tonalidade profunda de raiz (`color_base`) e resultando em tufos de cor monocromática plana.

---

## 2. Alterações Realizadas

### A. Correção da Altura Vertical no Shader (`interactive_grass.gdshader`)
1. **Passagem de Altura Canônica via Varying:**
   - No estágio `vertex()`, a variável `v_leaf_h` é calculada e normalizada de $0.0$ (raiz/solo) a $1.0$ (ponta da folha) através de `raw_h = invert_height ? (1.0 - UV.y) : UV.y`.
   - Para o trigo maduro (`wheat_01.glb`), quando `invert_height == true && COLOR.r > 0.001`, preserva-se o gradiente assado folha a folha no canal R do Blender.
2. **Interpolação de Base Escura para Cor Atual no `fragment()`:**
   - A curva de gradiente foi calibrada com `grad_t = smoothstep(0.04, 0.88, h);`.
   - Na inserção/raiz no solo ($h \to 0.0$), a superfície exibe $100\%$ de `color_base` (tom profundo/escuro).
   - Ao longo do corpo da lâmina, transiciona suavemente até atingir a cor vibrante atual (`color_light`) nas pontas.

### B. Paleta Canônica de Gradientes por Variação de Grama
Todas as 7 variações de grama e o trigo agora exibem gradientes botânicos de alto contraste:
- **Grama Verde:** Base verde floresta escuro (`#1F700D`) $\to$ Ponta verde limão viçoso (`#47CF1A`).
- **Grama Amarela:** Base âmbar/ocre terroso quente (`#7A4D0F`) $\to$ Ponta dourado solar radiante (`#FFD62E`).
- **Grama Azul:** Base azul marinho profundo (`#14387A`) $\to$ Ponta azul celeste/ciano luminoso (`#3DB8FF`).
- **Grama Roxa:** Base ameixa/roxo místico escuro (`#421470`) $\to$ Ponta lilás/orquídea vibrante (`#BD57FA`).
- **Grama Branca:** Base ardósia azulada sombreada (`#7A8AA3`) $\to$ Ponta branco gelo puro (`#FAFCFF`).
- **Grama Vermelha:** Base vinho carmesim profundo (`#6B141A`) $\to$ Ponta vermelho rubi ardente (`#FA4D57`).
- **Grama Preta:** Base ébano/preto profundo (`#0F0F14`) $\to$ Ponta cinza grafite/antracite (`#474D59`).
- **Trigo:** Base âmbar tostado (`#61380D`) $\to$ Ponta amarelo palha maduro (`#FFDF40`).

---

## 3. Validação e Testes
- **Captura Close-Up (Grama Verde vs Amarela):** Validado em `showcase_grass_gradient_closeup.png`, comprovando a transição suave de base escura para o ápice luminoso.
- **Showcase de Todas as 7 Variedades:** Validado em `showcase_grass_gradient_all.png`, demonstrando separação volumétrica nítida em todas as cores.
- **Gameplay Real (Nível 5):** Validado em `gameplay_grass_gradient_level5.png`, com leitura limpa e ancoragem profunda no solo verde.
- **Integridade GDScript:** Suite completa de testes botânicos executada com 0 warnings e 0 erros.

---

## 4. Arquivos Modificados
- `shaders/interactive_grass.gdshader`
- `scripts/core/game_version.gd`
- `project.godot`
- `export_presets.cfg`
- `docs/02_entidades_e_mecanicas/SISTEMA_DE_VEGETACAO.md`
- `docs/historico_melhorias/INDICE_MELHORIAS.md`
- `docs/historico_melhorias/221_gradiente_vertical_base_escura_todas_as_gramas.md`
