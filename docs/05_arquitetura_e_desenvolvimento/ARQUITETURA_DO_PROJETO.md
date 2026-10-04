# Arquitetura do Projeto Godot 4 🏗️📁

Este documento descreve a organização modular de diretórios, a hierarquia de cenas e a distribuição de responsabilidades técnicas em **Grass Cut Bot**.

---

## 1. Organização de Diretórios

O projeto adota uma estrutura desacoplada por tipo e domínio:

```
grass-cut-bot/
├── .agent/                    # Configurações e skills do agente de desenvolvimento
│   └── skills/atualizar-documentacao/
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
├── scenes/                    # Cenas montadas (.tscn)
│   ├── cutter/                # Cortador robótico
│   ├── level/                 # Terrenos e ilhas
│   ├── obstacles/             # Rochas e barreiras
│   ├── plants/                # Tufos de grama, trigo e flores
│   ├── ui/                    # HUD, joystick virtual e modais
│   └── main.tscn              # Cena mestre do jogo
├── scripts/                   # Código fonte GDScript (.gd)
│   ├── camera/
│   ├── core/                  # Autoloads e singletons (GameManager, UpgradeManager)
│   ├── cutter/
│   ├── level/
│   ├── plants/
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
