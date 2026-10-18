# Melhoria 035: Menu Inicial (Hub Principal) com Câmera Dual (Bot & Mapa de Ilhas 3D), 4 Abas e Modal de Configurações 🌿🤖

**Data:** 18 de Outubro de 2026  
**Versão:** 0.6.0  
**Autor:** Antigravity AI Assistant & Grass Cut Bot Team  

---

## 🎯 Objetivo da Melhoria
Criar uma tela canônica de **Menu Inicial / Hub Principal** para *Grass Cut Bot* inspirada nas referências visuais de jogos mobile casuais modernos (ex: *Archero*, *Royal Match*), com formato portrait 720x1280, incorporando:
1. **Visão Bot (Default):** Diorama 3D tropical com o robô em pose de destaque heróica, flutuação vertical procedural suave (*hover bobbing*), rotação de lâmina em marcha lenta e orientação frontal voltada diretamente para o jogador.
2. **Visão Mapa (Overworld 3D do Arquipélago):** Câmera elevada panorâmica ativada pelo botão `[ 🗺️ MAP ]`, revelando as ilhas geradas dinamicamente com suporte a rolagem vertical (*drag scroll* touch e mouse wheel), pinos de fase com estrelas e cadeados, robô posicionado sobre a ilha da fase atual e banco terminal de nuvens 3D com a placa *"Em breve mais fases..."* delimitando o fim da rolagem.
3. **Barra de Navegação Inferior de 4 Abas:** `Garage` 🔧 | `Home` 🏠 | `Collection` 🌿 | `Store` 🏪 com animação de elevação da aba selecionada.
4. **Modal de Configurações Quase Tela Toda:** 3 toggles de áudio e háptica (Música, Som FX, Vibração), seção *Save Progress* (Salvar Local, Conectar Google, Conectar Facebook) e botão de Suporte.
5. **Integração com o Fluxo de Jogo:** Botão *"Menu Inicial 🏠"* adicionado nos modais de Pausa, Vitória e Derrota do gameplay, com preservação contínua das moedas ganhas.

---

## 🏗️ Arquitetura e Arquivos Criados

| Arquivo | Descrição |
| :--- | :--- |
| `res://scenes/menu/main_menu.tscn` | Cena raiz do Menu Inicial com iluminação tropical, oceano e interface CanvasLayer. |
| `res://scripts/menu/main_menu.gd` | Orquestrador principal conectando abas, arquipélago dinâmico, top bar e transição de cenas. |
| `res://scripts/menu/menu_camera.gd` | Controlador da Câmera Dual (`BOT_VIEW` e `MAP_VIEW`), interpolação Tween e drag scroll com inércia. |
| `res://scenes/menu/menu_bot.tscn` / `menu_bot.gd` | Robô 3D com hover procedural, orientação frontal corrigida para a câmera e sincronização com tier da lâmina. |
| `res://scenes/menu/island_node.tscn` / `island_node.gd` | Ilha individual do arquipélago com pinos de fase (estrelas/cadeados) e âncora do robô. |
| `res://scenes/menu/clouds_end_node.tscn` | Ilha terminal coberta por nuvens estilizadas 3D e placa *"Em breve mais fases..."*. |
| `res://scenes/menu/bottom_nav_bar.tscn` / `bottom_nav_bar.gd` | Barra inferior com as 4 abas na ordem oficial: `Garage`, `Home`, `Collection`, `Store`. |
| `res://scenes/menu/tabs/tab_home.tscn` / `tab_home.gd` | Aba central com botões `"Level X ▶"` e `"🗺️ MAP"` / `"🤖 BOT"`. |
| `res://scenes/menu/tabs/tab_garage.tscn` / `tab_garage.gd` | Aba Oficina conectada ao `UpgradeManager` com os 4 upgrades e exibição de Tiers. |
| `res://scenes/menu/tabs/tab_collection.tscn` / `tab_collection.gd` | Aba Herbário com catálogo ilustrado das espécies da ilha e colecionáveis. |
| `res://scenes/menu/tabs/tab_store.tscn` / `tab_store.gd` | Aba Loja com pacotes de moedas e resgate de recompensa inicial. |
| `res://scenes/ui/settings_modal.tscn` / `settings_modal.gd` | Modal amplo cobrindo ~85% da tela com áudio, salvamento e suporte. |

---

## 🔍 Validação e Conformidade com os Guardrails
- **Zero Warnings Estrito:** Compilação e execução validadas com 0 warnings e 0 erros no Godot 4.7.
- **Orientação Mobile Portrait:** Interface nativa e responsiva em 720x1280.
- **Game SemVer:** Atualizado para `v0.6.0` em `project.godot`.
