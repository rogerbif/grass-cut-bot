# Melhoria 193: Restauração Canônica das Fases 01 a 20 e Proteção Definitiva contra Sobrescrita Legada 🏝️🛡️

**Versão do Projeto:** `v0.12.143-alpha`  
**Data:** 07/11/2026  
**Status:** Concluído e Validado ✅  

---

## 📌 Contexto e Diagnóstico

Na rotina anterior de ajuste de raios de vegetação, o script gerador `generate_all_20_levels.gd` foi acionado inadvertidamente. Esse script continha uma versão procedural arcaica e reduzida das primeiras 20 fases (grade de 13x13 com ilhas diminutas e poucos tufos), sobrescrevendo a versão oficial e refinada que já havia sido ampliada e calibrada com maestria no editor.

O usuário prontamente identificou a regressão visual nas fases 01 a 20.

---

## 🛠️ Implementações Realizadas

### 1. Restauração Imediata das Fases 01 a 20 (`data/levels/level_01.json` a `level_20.json`)
- Restauração pontual e atômica de todos os 20 arquivos JSON canônicos a partir do commit estável `48ebb24`.
- **Fase 1:** Retorno à escala real de 10m x 10m (grade 25x25), 58 tufos de `grass_green`, 36 de `grass_yellow` e geometria com anéis e cantos chanfrados.
- **Fases 2 a 20:** Todas as ilhas, obstáculos, trigos, flores e tempos originais totalmente preservados e intactos.

### 2. Preservação dos Novos Raios de Vegetação via Runtime Dinâmico
- Conforme solicitado na melhoria 192:
  - O raio de afastamento das rochas permanece em **$0.90\text{m}$** (raio da menor lâmina).
  - O raio da clareira do spawn do bot permanece em **$1.40\text{m}$** (raio anterior da rocha).
- Como tanto o [`vegetation_grid.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/plants/vegetation_grid.gd) (gameplay) quanto o [`island_node.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/menu/island_node.gd) (menu) aplicam esse recorte dinamicamente em tempo de execução ao instanciar os níveis, as fases 01 a 20 restauradas desfrutam dos novos raios sem necessidade de regeneração destrutiva.

### 3. Trava de Proteção Ativa em `generate_all_20_levels.gd`
- Inserção de bloqueio rígido no método `_init()` de `scripts/tools/generate_all_20_levels.gd` com encerramento imediato (`quit(1)`), impedindo que qualquer chamada acidental ao gerador procedural legado volte a sobrescrever os dados oficiais das fases 01 a 20.

### 4. Integração do Sistema de Gestos no Menu
- Registro e validação da navegação por gestos de swipe adicionada em `main_menu.gd` (swipe horizontal para abas, swipe vertical para fases na tela inicial) e animação bump no `map_level_card.gd`.

---

## 📊 Resultados e Validação

- **Fases 01 a 20:** 100% restauradas à sua geometria rica e em escala real.
- **Execução Headless:** Execução do `main_menu.tscn` concluída com **0 warnings e 0 erros**.
