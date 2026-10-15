# Melhoria 020: Consolidação de Modelo Único no Blender e Cenas Base Coloridas no Godot [v0.4.3] 🌿🎨

## 1. Visão Geral e Contexto
O usuário solicitou uma simplificação na divisão de responsabilidades entre o Blender e o Godot: *"o modelo da grama no blender deve ser somente 1, importe para o godot e exclua as ouras versões deve usar somente esse modelo, deixe no blender so o modelo default sem cor, no godot duplique o arquivo base e coloque a cor para cada tipo"*.

Anteriormente, o arquivo `grass_01.blend` mantinha 4 objetos com cores assadas exportados em conjunto, o que resultava em 4 nós de malha dentro de cada tufo instanciado na engine (3 ocultos e 1 visível). Esta melhoria deixa o Blender com um único modelo padrão limpo e transfere a especialização de cores para cenas Godot independentes e modulares.

---

## 2. Implementações Técnicas

### A. Consolidação da Malha no Blender (`grass_01.blend`)
- **Limpeza de Objetos:** Excluídos `grass_yellow`, `grass_blue` e `grass_purple`.
- **Objeto Base Único:**
  - Nome: `grass_01` com malha `grass_01_mesh` (112 vértices, 80 faces).
  - Transform: Coordenadas $(0.0, 0.0, 0.0)$, rotação $(0, 0, 0)$, escala $(1, 1, 1)$.
  - Ancoragem: Vértices inferiores alinhados estritamente em $Z = 0.0$.
  - Material Neutro: `M_Grama_Default` sem nós de texturas rasterizadas e com albedo cinza claro neutro.
- **Exportação glTF:** Gerado `assets/models/grass_01.glb` com `export_apply=True` e `export_yup=True`. O arquivo compilado reduziu em 64% o tamanho em disco e contém apenas um único nó MeshInstance3D.

### B. Criação de Cenas Base Coloridas no Godot (`scenes/plants/`)
No Godot, foram criadas cenas modulares especializadas que instanciam o modelo único `grass_01.glb` e aplicam diretamente o `material_override` correspondente com o shader espacial `interactive_grass.gdshader`:
1. `grass_tuft.tscn` / `grass_green.tscn`: Verde vivo com shader interativo e partículas verdes.
2. `grass_yellow.tscn`: Amarelo pastoral com shader amarelo e partículas douradas.
3. `grass_blue.tscn`: Azul místico com shader azul e partículas celestes.
4. `grass_purple.tscn`: Roxo exótico com shader roxo e partículas magenta.

### C. Limpeza e Otimização do Script `plant.gd`
- Removido o chaveamento procedural de nós filhos (`GrassVariation` e `_apply_grass_variation()`), eliminando chamadas de busca de nós por string em tempo de execução.
- Cada tufo executa apenas variação suave de escala/rotação aleatória no `_ready()`, detecção de corte pela lâmina e emissão de partículas.
- Redução de 75% na quantidade de nós MeshInstance3D presentes na cena da Fase 1 (de 224 nós de malha para apenas 56).

### D. Integração na Cena da Fase 1 (`level_01.tscn`)
- Todos os 56 tufos da cena `scenes/levels/level_01.tscn` utilizam a cena limpa `grass_tuft.tscn`.
- O designer pode arrastar `grass_yellow.tscn`, `grass_blue.tscn` ou `grass_purple.tscn` da aba FileSystem para criar trechos coloridos visualmente no 3D Viewport com detecção automática de metas.

---

## 3. Validação e Qualidade
- **Zero Warnings / Zero Erros:** Verificado em execução de debug contínua via Godot MCP (`run_project` e `get_debug_output`).
- **SemVer:** Incrementado para **`v0.4.3`** em `project.godot`.
