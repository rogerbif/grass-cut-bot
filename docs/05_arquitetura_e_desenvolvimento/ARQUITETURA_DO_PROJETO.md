# Arquitetura do Projeto Godot 4 🏗️📁

Este documento descreve a organização modular de diretórios, a hierarquia de cenas e a distribuição de responsabilidades técnicas em **Grass Cut Bot**.

---

## 1. Organização de Diretórios

O projeto adota uma estrutura desacoplada por tipo e domínio:

```
grass-cut-bot/
├── .agent/                    # Configurações e skills do agente de desenvolvimento
│   └── skills/atualizar-documentacao/
├── assets/                    # Modelos 3D, texturas e materiais
│   └── models/                # Modelos oficiais glTF (.glb)
│       ├── grass_bot.glb      # Modelo oficial do robô e lâminas modulares
│       ├── terrain_tileset.glb# Biblioteca mestre de tiles e props de terreno
│       └── tiles/             # Modelos unitários (.glb) aplicados no Editor de Fases
│           ├── tile_island_center.glb
│           ├── tile_island_dirt.glb
│           ├── tile_island_edge.glb
│           ├── tile_island_corner_out.glb
│           └── tile_island_corner_in.glb
├── docs/                      # Hub Central da Wiki e documentação técnica canônica
│   ├── .gdignore              # Instrução para Godot ignorar a pasta
│   ├── 01_visao_geral_e_gdd/
│   ├── 02_entidades_e_mecanicas/
│   ├── 03_level_design_e_fases/
│   ├── 04_sistemas_e_gameplay/
│   ├── 05_arquitetura_e_desenvolvimento/
│   ├── historico_melhorias/
│   ├── MELHORIAS_FUTURAS.md
│   └── PROJETO_GRASS_CUT_BOT.md
├── data/                      # Dados serializados do jogo
│   └── levels/                # Fases em formato JSON (level_01.json, etc.)
├── scenes/                    # Cenas montadas (.tscn)
│   ├── cutter/                # Cortador robótico
│   ├── editor/                # Editor de Fases PC Fullscreen e kit de tiles 3D de ilha
│   ├── level/                 # Terrenos, oceano (water_ocean.tscn) e ilhas base
│   ├── levels/                # Fases exportadas como cena Godot (level_01.tscn, etc.)
│   ├── menu/                  # Menu Inicial (Hub Principal), Câmera Dual, Abas e Ilhas
│   ├── obstacles/             # Rochas e barreiras
│   ├── plants/                # Tufos de grama (4 cores), trigo e flores
│   ├── ui/                    # HUD, joystick virtual e modais
│   └── main.tscn              # Cena mestre do jogo
├── scripts/                   # Código fonte GDScript (.gd)
│   ├── camera/
│   ├── core/                  # Autoloads e singletons (GameManager, UpgradeManager)
│   ├── cutter/
│   ├── editor/                # Scripts do Editor de Fases PC (autotiler, pincéis, UI)
│   ├── level/                 # base_level.gd, level_controller.gd e level_json_loader.gd
│   ├── menu/                  # Scripts do Menu Inicial, câmera dual e navegação de abas
│   ├── plants/
│   ├── tools/                 # Geradores automatizados e validadores de fases
│   └── ui/
├── GEMINI.md                  # Central de Guardrails Invariantes e Roteador de Diretrizes
├── GDD.md                     # Espelho de referência rápida do GDD
├── icon.svg                   # Ícone oficial do projeto
└── project.godot              # Arquivo de configuração da Godot Engine 4
```

---

## 2. Camadas de Física Padronizadas (Collision Layers)

Configuradas em `project.godot` sob `[layer_names]`:

| Camada | Nome no Projeto | Descrição e Máscaras Típicas |
| :--- | :--- | :--- |
| **Layer 1** | `Ground & Limits` | Terreno da ilha e paredes invisíveis/cercas limítrofes. |
| **Layer 2** | `Cutter` | Corpo rígido do cortador (`CharacterBody3D`). Colide com Layers 1 e 4. |
| **Layer 3** | `Vegetation` | Áreas de corte dos tufos de grama, trigo e flores. Monitoradas pela lâmina. |
| **Layer 4** | `Obstacles` | Obstáculos sólidos como rochas e troncos. Geram choque e ricochete. |

---

## 3. Arquitetura de Autoloads Globais

1. **`GameManager` (`res://scripts/core/game_manager.gd`):**
   - Estado global da partida (`READY`, `PLAYING`, `PAUSED`, `VICTORY`, `GAME_OVER`).
   - Gerenciamento de tempo decrescente e contagem de metas.
   - Disparo de sinais desacoplados para a UI e sistema de haptics.
2. **`UpgradeManager` (`res://scripts/core/upgrade_manager.gd`):**
   - Carteira persistente de moedas verdes.
   - Níveis de melhoria (Raio, Potência, Velocidade e Multiplicador).
   - Cálculo de custos e emissão de sinais de compra de upgrade.
