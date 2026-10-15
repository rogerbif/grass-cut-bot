# Melhoria 016: Variações de Grama Low Poly Estilizada (grass_01) em Cores Sólidas [v0.3.9] 🌿🎨

## 1. Visão Geral e Contexto
Nesta melhoria, integramos o novo modelo de vegetação 3D estilizado com as seguintes diretrizes:
1. **Seleção de Malha Base:** Utilização do modelo `grass_varien_4_grass_0` do arquivo `grass_01.blend` como malha base (112 vértices e 80 faces), garantindo perfil foliar orgânico, leve e altamente performático para mobile.
2. **Eliminação de Texturas:** Remoção total das texturas de imagem rasterizadas (`Image_0`), eliminando nós de textura dos materiais para aderência ao estilo Low Poly fosco limpo (Mandamento 7).
3. **Quatro Variações Cromáticas:** Criação de materiais dedicados com cores sólidas e acabamento fosco (`roughness = 0.88`):
   - Verde (`M_Grama_Verde`)
   - Amarelo (`M_Grama_Amarela`)
   - Azul (`M_Grama_Azul`)
   - Roxo (`M_Grama_Roxa`)
4. **Disposição Lado a Lado no Blender:** Distribuição dos 4 tufos ao longo do eixo X para visualização comparativa e organização anatômica clara.
5. **Normalização e Ancoragem:** Aplicação de escala uniforme ($s = 0.0242265$) para adequação ao grid de $1\text{m}$ do jogo e alinhamento do vértice inferior da raiz em $Z = 0.0$.
6. **Exportação glTF e Importação no Godot:** Exportação segura com `export_apply=True` e `export_yup=True` (Mandamento 12) gerando `assets/models/grass_01.glb` e criação da cena Godot `scenes/plants/grass_01.tscn`.

---

## 2. Implementações Técnicas

### A. Processamento e Limpeza no Blender (`grass_01.blend`)
- **Remoção de Texturas:** Todas as texturas empacotadas ou vinculadas foram desvinculadas dos slots de materiais, configurando os shaders apenas com o nó `Principled BSDF`.
- **Escala e Pivô:** As coordenadas dos vértices de `grass_varien_4_grass_0` foram normalizadas:
  - Dimensão original no FBX: $\sim 36.8\text{m} \times 36.8\text{m} \times 42.3\text{m}$ (escala em centímetros do Blender/FBX).
  - Dimensão final normalizada: $0.89\text{m} \times 0.89\text{m} \times 1.025\text{m}$.
  - Deslocamento de ancoragem: o ponto mais baixo da malha foi transladado para $Z = 0.0$.
- **Objetos e Posições (Lado a Lado):**
  - `grass_green`: $X = -2.25\text{m}$, Material `M_Grama_Verde` `(0.18, 0.65, 0.12, 1.0)`.
  - `grass_yellow`: $X = -0.75\text{m}$, Material `M_Grama_Amarela` `(1.00, 0.62, 0.02, 1.0)`.
  - `grass_blue`: $X = +0.75\text{m}$, Material `M_Grama_Azul` `(0.04, 0.45, 0.90, 1.0)`.
  - `grass_purple`: $X = +2.25\text{m}$, Material `M_Grama_Roxa` `(0.48, 0.08, 0.85, 1.0)`.

### B. Pipeline glTF para Godot 4
- **Exportação glTF 2.0:**
  - Arquivo de destino: `res://assets/models/grass_01.glb`.
  - Flags obrigatórias: `export_apply=True` e `export_yup=True`.
- **Compilação e UID:**
  - O Godot compilou o asset gerando `.godot/imported/grass_01.glb-b59fbfec89794044dd0e758b8f7494e1.scn` com UID `uid://oow7pgxl0ues`.
- **Cena Demonstrativa:**
  - Criada a cena `scenes/plants/grass_01.tscn` instanciando `res://assets/models/grass_01.glb` pronta para visualização e derivação de biomas no Level Design.

---

## 3. Validação e Qualidade
- **Zero Warnings / Zero Erros:** Verificado no console Godot 4 via MCP (`run_project` e `get_debug_output`).
- **Harmonia Cromática:** Cores vivas sem brilhos especulares indesejados, perfeitamente integradas ao estilo Low Poly fosco do projeto.
