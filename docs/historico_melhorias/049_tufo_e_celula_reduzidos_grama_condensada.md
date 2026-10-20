# Melhoria 049: Redução do Tufo (-50% Diâmetro, -25% Altura), Célula de Vegetação em 0.40m e Gramado Condensado 🌿✂️📐

**Data:** 2026-10-20  
**Versão:** `v0.7.11-alpha`  
**Autor:** Antigravity (Advanced Agentic Coding)  
**Status:** Concluído com Sucesso e Validado (0 Warnings / 0 Erros)  

---

## 1. Contexto e Motivação

O usuário identificou que o tufo de grama individual apresentava dimensões muito largas no cenário, solicitando:
> *"acho que o tufo de grama esta muito grande ainda reduza em 50% no diametro na altura reduza somente 25% quero que fique mais condensada a grama /plan na fase e na tela inicial"*
> *"precisa reduzir o tamanho da celula também, atualize o plano, para que a celula tenha o mesmo diametro do tufo, as flores podem ocupar a mesma posição de um tufo de grama a pedra pode manter o mesmo tamanho e onde ela esta não tem grama como é atualmente"*

Para atender a esses requisitos sem deixar o gramado esparso ou criar frestas de chão aberto, o sistema espacial de vegetação foi recalibrado tanto no gameplay quanto no Menu Inicial, alinhando a malha do tufo à nova célula reduzida.

---

## 2. Decisões Arquiteturais e Execução Técnica

### 2.1 Calibração Métrica do Tufo de Grama
- **Diâmetro Horizontal ($X$ e $Z$):** Reduzido em 50%, passando de $0.95 \sim 1.10\text{m}$ para **$0.40 \sim 0.45\text{m}$**, correspondendo exatamente à nova largura da célula.
- **Altura Vertical ($Y$):** Reduzida em 25%, passando de $0.70 \sim 0.85\text{m}$ para **$0.53 \sim 0.64\text{m}$**, conferindo às folhas uma postura mais esguia e condensada.
- **Física e Partículas:**
  - O colisor `CollisionShape3D` (`CylinderShape3D`) das cenas `grass_tuft.tscn`, `grass_green.tscn`, `grass_yellow.tscn`, `grass_blue.tscn`, `grass_purple.tscn`, `flower_tuft.tscn` e `wheat_tuft.tscn` foi reduzido de raio $0.35\text{m}$ / altura $0.60\text{m}$ para **raio $0.18\text{m}$ / altura $0.45\text{m}$** (posicionado em $Y = 0.225\text{m}$).
  - O anel emissor de `CutParticles` teve seu raio reduzido de $0.35\text{m}$ para $0.18\text{m}$ e altura para $0.08\text{m}$, com partículas de folhas estilizadas redimensionadas proporcionalmente (`scale_amount = 0.8 ~ 1.6`).

### 2.2 Subgrade de Vegetação ($0.40\text{m}$) e Condensação Contínua
- Para manter os blocos de terreno modulares 3D de $0.80\text{m} \times 0.80\text{m}$ íntegros, cada bloco de terreno abriga uma **subgrade $2 \times 2$ de células de vegetação de $0.40\text{m}$**:
  $$\text{Offsets: } (-0.20\text{m}, -0.20\text{m}), (+0.20\text{m}, -0.20\text{m}), (-0.20\text{m}, +0.20\text{m}), (+0.20\text{m}, +0.20\text{m})$$
- Como o diâmetro do tufo ($0.40 \sim 0.45\text{m}$) coincide com a largura da célula ($0.40\text{m}$), os tufos se tocam e se entrelaçam continuamente, resultando em um gramado **altamente condensado, farto e sem espaços vazios**.
- **Gameplay (`scripts/level/level_controller.gd`):** A leitura do JSON instancia os 4 tufos por bloco, atualizando as metas em tempo real no `GameManager`.
- **Menu Inicial (`scripts/menu/island_node.gd`):** A mesma subgrade $2 \times 2$ é instanciada para cada bloco no arquipélago 3D, garantindo total equivalência visual e estética entre a Home/Mapa e as fases.

### 2.3 Flores, Trigo e Preservação de Rochas
- **Flores e Trigo:** Ocupam a posição de 1 célula de tufo de grama ($0.40\text{m}$) com escala proporcional ($0.48 \sim 0.58$), com os outros 3 slots do bloco preenchidos por tufos de grama verde.
- **Rochas:** Mantêm seu tamanho físico original intacto (raio $0.36\text{m}$, ocupando o bloco de $0.80\text{m}$). Onde há rocha, **nenhuma grama é gerada** sob ou dentro da sua área.

---

## 3. Arquivos Modificados

- [`scenes/plants/grass_tuft.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/plants/grass_tuft.tscn)
- [`scenes/plants/grass_green.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/plants/grass_green.tscn)
- [`scenes/plants/grass_yellow.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/plants/grass_yellow.tscn)
- [`scenes/plants/grass_blue.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/plants/grass_blue.tscn)
- [`scenes/plants/grass_purple.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/plants/grass_purple.tscn)
- [`scenes/plants/flower_tuft.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/plants/flower_tuft.tscn)
- [`scenes/plants/wheat_tuft.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scenes/plants/wheat_tuft.tscn)
- [`scripts/plants/plant.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/plants/plant.gd)
- [`scripts/level/level_controller.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/level/level_controller.gd)
- [`scripts/menu/island_node.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/menu/island_node.gd)
- [`scripts/core/game_version.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/core/game_version.gd)
- [`project.godot`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/project.godot)
- [`docs/02_entidades_e_mecanicas/SISTEMA_DE_VEGETACAO.md`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/docs/02_entidades_e_mecanicas/SISTEMA_DE_VEGETACAO.md)

---

## 4. Validação e Qualidade

- **Execução Godot 4:** Validado em execução no `main_menu.tscn` e `main.tscn` via Godot MCP.
- **Zero Warnings / Zero Erros:** Console do Godot permanece limpo com 0 warnings e 0 erros.
- **Game SemVer:** Atualizado para **`v0.7.11-alpha`**.
