# Histórico de Melhorias: 103 - Ancoragem Estrita dos Números Flutuantes ao Lado do Corpo do Robô 🪙🤖

**Data:** 25 de Outubro de 2026  
**Versão:** `v0.12.28-alpha`  
**Escopo:** Feedback Visual de Moedas (`scripts/effects/floating_coin_manager.gd`), Ponto de Spawn Relativo (`scripts/cutter/cutter.gd`), Eliminação de Spawns Espúrios no Centro da Fase e Desativação de Sombras na Serra.

---

## 1. Contexto e Motivação

Durante os testes em gameplay (especialmente na Fase 1), observou-se que alguns números flutuantes de colheita (`+1`, `+3`, `+5`, etc.) estavam surgindo no centro da ilha, longe de onde o robô estava operando.

Ao investigar o fluxo de eventos:
1. Em [`floating_coin_manager.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/effects/floating_coin_manager.gd), a posição padrão inicial era definida como `var spawn_pos: Vector3 = world_pos + Vector3(0.0, 0.28, 0.0)`. Caso a busca tardia por `_cached_cutter` falhasse ou ainda não tivesse resolvido o nó, o número flutuante brotava diretamente na coordenada de mundo `world_pos` do tufo cortado (que na Fase 1 fica localizado exatamente no centro da ilha).
2. O método `get_inner_blade_point` em [`cutter.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/cutter/cutter.gd) calculava offsets baseados na serra circular antiga, com baixa elevação vertical.
3. As lâminas 3D da serra mantinham `cast_shadow = ON`, o que gerava feixes de sombras giratórios projetados na grama a 60 FPS quando a lâmina acelerava.

O usuário determinou explicitamente que:
> *"Os números podem permanecer aparecendo ao lado do corpo do robô, não na lâmina. Garanta que eles só dêem spawn nessa coordenada."*

---

## 2. Ações Implementadas

### A. Ancoragem Estrita e Garantida em `FloatingCoinManager`
- Adicionado `@export var cutter_path: NodePath = NodePath("../LevelController/Cutter")` e resolução direta e robusta em `_get_cutter()`: tenta caminho direto na árvore de cena, busca por grupo `"cutter"` e busca por nome na cena ativa.
- **Regra Rígida de Bloqueio:** Se por qualquer motivo `cutter` for nulo, a rotina **retorna imediatamente** e **NUNCA** utiliza `world_pos`. É garantido que nenhum número brotará no chão da ilha ou no centro da fase.
- **Ordem de Propriedades:** `label.global_position = spawn_pos` agora é atribuído **antes** de `label.visible = true`, evitando flashes visuais do label na coordenada `(0, 0, 0)` onde foi instanciado.
- **Expansão do Pool:** `POOL_SIZE` ampliado de 32 para 64 instâncias, prevenindo reciclagem prematura de labels em ceifadas rápidas.

### B. Calibração Lateral ao Lado do Corpo (`get_inner_blade_point`)
Em [`cutter.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/cutter/cutter.gd):
- **Setor Esquerdo:** `forward * 0.15 - right * 0.45` (imediatamente ao lado do paralama esquerdo do robô).
- **Setor Direito:** `forward * 0.15 + right * 0.45` (imediatamente ao lado do paralama direito do robô).
- **Setor Centro:** `forward * 0.48` (logo à frente do bico).
- **Altura Y:** Elevado para `0.45m` acima da base do robô, flutuando com total clareza visual acima da vegetação.

### C. Desativação de Sombras na Serra
- Em `cutter.gd` e `menu_bot.gd`, ao inicializar no `_ready()`, todos os filhos do `blade_spinner` (`blade_tier_1..4`) têm `cast_shadow` definido estritamente como `SHADOW_CASTING_SETTING_OFF`. Isso elimina 100% das linhas e feixes de sombras estroboscópicas na tela.

### D. Adição de Grupo `"cutter"` na Cena
- Em `scenes/cutter/cutter.tscn`, adicionado `groups=["cutter"]` diretamente no cabeçalho do nó raiz `CharacterBody3D`.

---

## 3. Validação Automatizada

- **Novo Teste Unitário ([`tests/test_floating_coin_manager.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/tests/test_floating_coin_manager.tscn)):**
  - Instancia `main.tscn`, move o cortador para `(3.5, 0.1, -2.8)` e dispara `GameManager.register_cut` com tufo fingido em `(0.01, 0, 0.01)` (centro da fase).
  - Comprova que o label surgiu a apenas $0.669\text{m}$ do robô (ao lado do corpo) e a mais de $4.06\text{m}$ do centro da fase.
  - Aprovado com 100% de sucesso.
- **Suíte SaveGame & Inclinação:** 100% aprovados.
- **Zero Warnings:** Compilação headless confirmada com 0 warnings.
