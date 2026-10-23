# Melhoria 082: Agrupamento de Corte (10 Tufos Físicos = 1 Meta = 1 Moeda) [v0.12.6-alpha] 🌾🪙

Este documento registra a implementação do balanceamento e agrupamento de corte para todas as espécies de campo (**Grama e Trigo**), unificando a proporção em **10 tufos físicos ceifados por unidade virtual de meta**, gerando ritmo fluido (*pacing*), números limpos e eliminando 100% da poluição visual de popups no robô cortador.

---

## 📋 Resumo Executivo
- **Data da Conclusão:** Outubro de 2026
- **Versão SemVer:** `v0.12.6-alpha` (Code: `1206`)
- **Domínio:** Gameplay, Game Balance, Game Feel e Otimização Visual
- **Objetivos Entregues:**
  1. **Regra Unificada de Campo (10 Tufos Físicos = 1 Unidade Virtual):**
     - **Grama (todos os tipos/cores):** A cada 10 tufos físicos ceifados no solo, a meta da TopBar decrementa em 1, concede 1 moeda base e emite 1 popup cartoon `+1` em branco;
     - **Trigo Dourado:** A cada 10 tufos físicos ceifados no solo, a meta de trigo da TopBar decrementa em 1, concede 3 moedas base e emite 1 popup cartoon `+3` em dourado;
     - **Flores Nobres:** Permanecem individuais (1 tufo físico = 1 meta = 5 moedas com popup `+5` em rosa magenta).
  2. **Eliminação da Poluição Visual:**
     - Redução de **10x** no volume instantâneo de popups 3D sobre a lâmina, garantindo leitura impecável e rastro contínuo comemorativo sem empilhamento;
     - Metas na TopBar calibradas para números casuais elegantes (ex: Fase 1 agora exibe ~35 de grama em vez de 128).
  3. **Proteção Anti-Trava (Fim de Fase):**
     - Ao raspar os últimos tufos físicos da ilha, qualquer fração residual pendente no acumulador (ex: 4 ou 7 tufos) é automaticamente fechada, garantindo vitória instantânea com 100% da ilha limpa.
  4. **Zero Warnings & Estabilidade:**
     - Testado na Godot 4.7.1 via Godot MCP com 0 erros e 0 warnings no console.

---

## 🔍 Detalhamento Técnico das Modificações

### 1. `scripts/plants/vegetation_grid.gd`
- Adicionados contadores de rastreamento físico:
  ```gdscript
  var _total_physical_grass: int = 0
  var _total_physical_wheat: int = 0
  var _total_physical_flower: int = 0
  var _remaining_physical_grass: int = 0
  var _remaining_physical_wheat: int = 0
  var _remaining_physical_flower: int = 0
  var _grass_cut_accumulator: int = 0
  var _wheat_cut_accumulator: int = 0
  ```
- **Cálculo de Metas:**
  - `goals["grass"] = maxi(1, int(ceilf(float(_total_physical_grass) / 10.0)))`
  - `goals["wheat"] = maxi(1, int(ceilf(float(_total_physical_wheat) / 10.0)))`
- **Corte em `cut_in_circle`:**
  - Acumula cortes físicos por tipo e aciona `GameManager.register_cut` a cada 10 unidades físicas ou no encerramento da espécie na ilha;
  - Cláusula de garantia global de fechamento de metas residuais ao zerar todos os tufos físicos.

---

## 🧪 Testes e Validação
- **MCP Godot Run:** Execução de `res://scenes/main.tscn` e `res://scenes/editor/level_editor.tscn` com 0 erros e 0 warnings.
- **SemVer:** Atualizado para `v0.12.6-alpha` (Code: `1206`).
