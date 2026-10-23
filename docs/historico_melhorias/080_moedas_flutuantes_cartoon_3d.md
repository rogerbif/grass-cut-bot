# Melhoria 080: Números Flutuantes Cartoon 3D de Colheita 💥 (+1, +3, +5) [v0.12.4-alpha] 🌿🪙

Este documento registra a implementação do sistema de **Números Flutuantes Cartoon 3D de Colheita** (*Floating Popups / Number Trail*), calibrado com fidelidade estética cel-shaded cartoon a partir das capturas de referência enviadas pelo usuário, trazendo feedback sensorial imediato e rastro contínuo (*number trail*) ao ceifar vegetações.

---

## 📋 Resumo Executivo
- **Data da Conclusão:** Outubro de 2026
- **Versão SemVer:** `v0.12.4-alpha` (Code: `1204`)
- **Domínio:** Gameplay, Game Feel, Efeitos Visuais 3D e Interface no Mundo (In-Game 3D Popups)
- **Objetivos Entregues:**
  1. **Tipografia Cartoon & Cel-Shaded Fiel à Referência:**
     - Exibição limpa de números em formato puro: `+1`, `+3`, `+5` (sem ícones obstrutivos de moedas ao lado do número);
     - Preenchimento branco sólido (`#FFFFFF`) para grama comum com contorno preto grosso e nítido (`#000000`, 14px), garantindo máximo contraste visual contra qualquer tonalidade de terreno e vegetação;
     - Diferenciação cromática cartoon para espécies especiais: Amarelo Ouro brilhante (`#FFE633`) para trigo e Rosa Magenta vivo (`#FF4090`) para flores silvestres;
     - Suporte automático a multiplicadores de recompensa da oficina (`UpgradeManager`), renderizando o valor líquido multiplicado (`+2`, `+6`, `+10`, etc.).
  2. **Efeito Rastro Contínuo (*Number Trail*):**
     - Conforme a lâmina do cortador ceifa os tufos em sequência, os números surgem exatamente sobre o ponto 3D do corte com escala *pop-in* elástica (`0.5 -> 1.25 -> 1.0`);
     - Os números flutuam verticalmente no ar subindo suavemente $+0.72\text{m}$ em 0.65s, mantendo opacidade 100% durante os primeiros 0.35s e esmaecendo gradualmente (`alpha: 1.0 -> 0.0`) nos 0.30s finais;
     - O encadeamento contínuo gera um rastro satisfatório de colheita no ar idêntico ao jogo de referência.
  3. **Pool Circular Otimizado para Mobile (32 Instâncias de `Label3D`):**
     - Alocação prévia estática de 32 nós `Label3D` no `_ready()`, eliminando instanciamento dinâmico em runtime e prevenindo picos de *Garbage Collection* no Android;
     - Reutilização circular atômica com interrupção limpa de *tweens* prévios caso um nó seja reciclado durante ceifas ultrarrápidas.
  4. **Integração Global:**
     - Integrado nativamente à cena de gameplay (`scenes/main.tscn`) e ao modo playtest do editor de fases (`scenes/editor/level_editor.tscn`);
     - Comunicação desacoplada orientada a eventos via sinal `GameManager.coin_popup_requested(world_pos, amount, plant_type)`.
  5. **Zero Warnings & Estabilidade:**
     - 100% de tipagem estática e conformidade com GDScript 4 defensivo, sem warnings no console da Godot 4.7.1.

---

## 🔍 Detalhamento Técnico das Modificações

### 1. `scripts/core/game_manager.gd`
- Adicionado novo sinal com tipagem estrita:
  ```gdscript
  signal coin_popup_requested(world_pos: Vector3, amount: int, plant_type: String)
  ```
- Atualizado o método `register_cut(plant_type: String, base_coins: int = 1, cut_pos: Vector3 = Vector3.ZERO)` para aceitar a coordenada mundial do corte e emitir `coin_popup_requested` com a posição e valor multiplicado líquido.

### 2. `scripts/plants/vegetation_grid.gd` & `scripts/plants/plant.gd`
- Em `vegetation_grid.gd`, o método `cut_in_circle` repassa a posição mundial exata `p_pos` do tufo colhido para `GameManager.register_cut(_cell_keys[cell_idx], _cell_rewards[cell_idx], p_pos)`.
- Em `plant.gd`, `_perform_cut` repassa `global_position` para `GameManager.register_cut`.

### 3. `scripts/effects/floating_coin_manager.gd`
- Novo gerenciador de efeitos 3D contendo:
  - Constantes de cores cartoon: `COLOR_GRASS` (Branco), `COLOR_WHEAT` (Amarelo) e `COLOR_FLOWER` (Magenta);
  - Pool de 32 nós `Label3D` pré-configurados com:
    - `billboard = BaseMaterial3D.BILLBOARD_ENABLED`;
    - `no_depth_test = true` e `render_priority = 25`;
    - `font_size = 56` e `pixel_size = 0.005`;
    - `outline_size = 14` e `outline_modulate = Color(0, 0, 0, 1)`;
    - `shaded = false` e `double_sided = true`.
  - Sequenciador de animação via `create_tween()` orquestrando escala *pop* elástica, subida vertical em Y e desvanecimento transparente com reciclagem ao final.

### 4. `scenes/main.tscn` & `scenes/editor/level_editor.tscn`
- Instanciado o nó `FloatingCoinManager` conectado nativamente ao `GameManager`, provendo suporte unificado tanto na campanha quanto durante testes no editor de níveis.

---

## 🧪 Testes e Validação
- **MCP Godot Run:** Execução de `res://scenes/main.tscn` e `res://scenes/editor/level_editor.tscn` com 0 erros e 0 warnings no console.
- **Suíte de Testes:** Suítes de Save e Áudio executadas com sucesso.
- **SemVer:** Atualizado para `v0.12.4-alpha` (Code: `1204`).
