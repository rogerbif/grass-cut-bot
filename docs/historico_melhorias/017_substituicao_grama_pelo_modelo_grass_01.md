# Melhoria 017: Substituição da Grama do Jogo pelo Novo Modelo 3D (grass_01) [v0.4.0] 🌿🚜

## 1. Visão Geral e Contexto
Nesta melhoria, atendemos à solicitação do usuário: *"pode substituir no jogo a grama atual pelo modelo da nova"*.
Substituímos os tufos de grama primitivos (`PrismMesh` procedurais de 5 lâminas) em `scenes/plants/grass_tuft.tscn` pelo modelo 3D estilizado oficial derivado de `grass_01.blend` (`assets/models/grass_01.glb`).

---

## 2. Implementações Técnicas

### A. Centralização de Pivôs e Exportação glTF
- **Origem dos Modelos:** No arquivo `grass_01.blend`, os 4 objetos de grama continuam organizados lado a lado ao longo do eixo X ($-2.25, -0.75, +0.75, +2.25$) para visualização anatômica direta no Blender.
- **Exportação glTF Unificada:** Durante o processo de exportação glTF para `assets/models/grass_01.glb`, as coordenadas de objeto foram centradas em $(0,0,0)$ com alinhamento inferior $Z = 0.0$ (convertido para $+Y = 0.0$ no Godot 4 via `export_yup=True` e `export_apply=True`), assegurando que cada variante gire e escalone sobre o próprio eixo sem deslocamentos angulares excêntricos.
- **Cena de Exibição (`grass_01.tscn`):** Ajustados os offsets individuais na cena de catálogo para manter os 4 modelos visíveis lado a lado sem sobreposição.

### B. Integração em `grass_tuft.tscn` e `plant.gd`
- **Hierarquia Visual:**
  - O contêiner `$VisualMesh` agora instancia `res://assets/models/grass_01.glb`.
  - Colisor `Area3D` com cilindro de raio $0.35\text{m}$ e altura $0.6\text{m}$ alinhado à zona central do tufo.
- **Controle Dinâmico de Variantes no `plant.gd`:**
  - Adicionado enum `GrassVariation { GREEN, YELLOW, BLUE, PURPLE, RANDOM }`.
  - Propriedade exportada `@export var grass_variation: GrassVariation = GrassVariation.GREEN`.
  - Método `_apply_grass_variation()` implementado com tipagem estrita: chaveia a visibilidade dos nós internos (`grass_green`, `grass_yellow`, `grass_blue`, `grass_purple`), ativando a variante escolhida (verde por padrão) e permitindo geração procedural de biomas multicoloridos ou aleatórios.
- **Feedback Sensorial e Game Feel:**
  - Preservada a animação de squash & shrink ao ser ceifada pela lâmina do robô.
  - Partículas parabólicas calibradas em verde esmeralda vibrante.
  - Vibração háptica de 15ms e acúmulo de moedas no `GameManager`.

---

## 3. Validação e Qualidade
- **Zero Warnings / Zero Erros:** Verificado em execução de debug contínua via Godot MCP (`run_project` e `get_debug_output`).
- **Performance Mobile:** Malha leve de 112 vértices e 80 faces, sem texturas rasterizadas e com renderização PBR fosca leve (Mandamento 7).
- **SemVer:** Incrementado para **`v0.4.0`** em `project.godot`.
