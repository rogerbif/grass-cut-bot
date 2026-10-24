# Melhoria 096: Revisão Completa da UI do Editor de Fases e Sistema de Metas Customizadas (Checkboxes & SpinBoxes) 🏝️🎯🛠️

**Status:** Concluído ✅  
**Data:** 2026-10-24  
**Versão SemVer:** `v0.12.21-alpha` (Code: 1221)  
**Domínio:** Interface & HUD / Level Design & Editor / Arquitetura & GDScript  

---

## 1. Visão Geral e Contexto do Problema

Durante sessões de edição de níveis no **Editor de Fases para PC** (`level_editor.tscn`), foram reportadas inconsistências ergonômicas e visuais no painel lateral direito:
1. **Botões e Labels Reduzidos:** Enquanto o painel esquerdo utilizava botões com altura de $34\text{px}$ e fonte $14\text{px}$, os botões de terreno e grama do painel direito estavam comprimidos em altura de apenas $28\text{px}$ com fonte minúscula de $11\text{px}$, gerando desconforto de clique e disparidade visual nítida.
2. **Corte Vertical de Layout:** Em janelas com resolução vertical menor ou igual a $900\text{px}$ (`target_h = mini(900, ...)`), os painéis fixados em $980\text{px}$ sem `ScrollContainer` tinham suas seções inferiores cortadas para fora da tela.
3. **Rigidez no Sistema de Metas:** O editor contabilizava compulsoriamente toda a vegetação presente no mapa como meta obrigatória de vitória. O criador de fases não possuía flexibilidade para ter vegetação puramente estética (ex: campo de grama com apenas trigo maduro como meta obrigatória de corte) nem para ajustar a quantidade numérica necessária para vencer.

---

## 2. Solução Implementada

### A. Equalização Ergonômica e Visual da Paleta
- **Altura e Tipografia Padronizadas:** Todos os botões da paleta de blocos de terreno e gramas foram ampliados para $34\text{px}$ de altura e fonte de $13\text{px}$ (aumento de ~21% na legibilidade e ~18% na área de clique).
- **Banner de Camada Ativa:** Adicionado cabeçalho dinâmico no topo do painel direito com estilização colorida e texto contextual de acordo com a camada selecionada (`🏝️ PALETA: TERRENO DA ILHA (0.8m)`, `🌿 PALETA: GRAMAS VETORIAIS (0.2m)`, `🪨 PALETA: OBJETOS NO TILE (0.8m)`).
- **Grid de Objetos Reformulado:** Seção de objetos reorganizada em grade harmônica de 3 colunas de $94\text{px}$ cada (`🪨 Rocha`, `🌸 Flor`, `🤖 Spawn`), eliminando transbordamento horizontal.
- **ScrollContainers Responsivos:** Ambos os painéis laterais (esquerdo e direito) foram integrados dentro de `ScrollContainer` com ancoragens verticais dinâmicas (`anchor_bottom = 1.0` com offset para a barra inferior), garantindo adaptação perfeita e sem cortes a qualquer resolução de monitor.

### B. Sistema de Metas Personalizadas (Checkboxes & SpinBoxes Editáveis)
- **Cards Individuais por Espécie Colhível:** Criados cards visuais estilizados para `🌿 Grama`, `🌾 Trigo` e `🌸 Flores`.
- **CheckBox de Ativação:** Permite marcar se aquela variedade vegetal é uma meta necessária para a vitória ou apenas vegetação secundária/decorativa que rende moedas mas não bloqueia a conclusão da fase.
- **SpinBox Numérico Editável:** Permite calibrar a quantidade exata necessária para a vitória (ex: exigir 30 trigos de um total de 60 presentes no mapa). Quando desmarcado, o campo reduz a opacidade e desabilita edição. Edições manuais congelam a meta sem sobrescrevê-la pela contagem automática de pintura.
- **Métricas Informativas de Construção:** Obstáculos rígidos (`🪨 Rochas`) e blocos de solo (`🏝️ Blocos Ilha`) foram isolados em um card inferior informativo.
- **Persistência em JSON v3 e Suporte ao Jogo:**
  - `LevelSerializer.save_level_json()` e `bake_to_tscn()` gravam o dicionário `"goals"` no JSON do nível.
  - `VegetationGrid.build_from_level_json()` respeita o dicionário `"goals"`, garantindo que o comportamento seja idêntico tanto no Playtest do editor quanto no runtime mobile.

---

## 3. Arquivos Modificados e Criados

| Arquivo | Descrição das Modificações |
| :--- | :--- |
| `scripts/editor/level_editor_ui.gd` | Implantação dos `ScrollContainer` nos painéis, equalização de fontes ($13\text{px}$) e botões ($34\text{px}$), criação dos cards de metas com CheckBox, contador total e SpinBox editável, banner de camada ativa e métodos `get_configured_goals()` / `set_configured_goals()`. |
| `scripts/editor/level_editor.gd` | Integração do carregamento de metas salvas no JSON, sincronização de metas no salvamento e exportação `.tscn`, e injeção das metas customizadas no Playtest. |
| `scripts/editor/level_serializer.gd` | Suporte ao parâmetro `custom_goals` em `save_level_json` e `bake_to_tscn`, gravando a chave `"goals"` no payload do JSON. |
| `scripts/plants/vegetation_grid.gd` | Suporte ao override de metas customizadas via `data["goals"]` em `build_from_level_json()`. |
| `scripts/core/game_manager.gd` | Proteção para registro de shader parameters apenas em contexto de editor, eliminando chamadas redundantes e mantendo zero warnings. |
| `docs/03_level_design_e_fases/SISTEMA_EDITOR_DE_FASES.md` | Atualização da documentação técnica canônica do editor com o novo sistema de metas e UI responsiva. |
| `project.godot` | Incremento Game SemVer de `v0.12.20-alpha` para `v0.12.21-alpha`. |
| `export_presets.cfg` | Sincronização do SemVer `0.12.21-alpha` e code `1221` para pacote Android. |
| `docs/historico_melhorias/INDICE_MELHORIAS.md` | Indexação da melhoria 096 no catálogo histórico. |

---

## 4. Verificação e Validação

1. **Compilação e Execução Limpa:** O projeto foi iniciado via Godot MCP e verificado sem qualquer erro de compilação ou falha de scripts.
2. **Zero Warnings/Erros:** Logs de console limpos, mantendo estrita conformidade com os 12 Mandamentos Invariantes do `GEMINI.md`.
3. **Persistência e Compatibilidade Retroativa:** Fases sem a chave `"goals"` continuam operando normalmente por autodetecção de toda a vegetação presente no mapa.
