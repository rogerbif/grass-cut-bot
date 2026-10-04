# Melhoria 001: Fundação do Projeto Grass Cut Bot e Entrega do MVP da Fase 1 🌿🤖

**Data:** 03/10/2026  
**Versão:** `v0.2.0-mvp`  
**Autor:** Antigravity AI Pair Programmer & Usuário  

---

## 1. Contexto e Objetivo

Inicializar o desenvolvimento do jogo **Grass Cut Bot** na **Godot Engine 4** com base nas diretrizes do Game Design Document (GDD v0.2), implementando a fundação arquitetural, o sistema de corte radial tátil, os controles touch adaptados para uma só mão em formato vertical (Portrait), o Top HUD reativo e a validação completa da **Fase 1 (MVP)**.

Além disso, adotar rigorosamente a arquitetura canônica de governança e documentação de excelência do projeto *Rover Raid*.

---

## 2. O Que Foi Desenvolvido

### 2.1 Configurações de Engine e Plataforma
- Arquivo [`project.godot`](../../project.godot) configurado com resolução base `720x1280` (Portrait 9:16), stretch mode `canvas_items` e `keep_width`.
- Emulação de toque ativada (`pointing/emulate_touch_from_mouse = true`) para testes ágeis no desktop com mouse e teclado.
- Padronização das 4 camadas físicas 3D (`Ground & Limits`, `Cutter`, `Vegetation`, `Obstacles`).

### 2.2 Núcleo e Economia (Autoloads)
- **[`GameManager`](../../scripts/core/game_manager.gd):** Gerenciador de estados de partida (`READY`, `PLAYING`, `PAUSED`, `VICTORY`, `GAME_OVER`), cronômetro decrescente, metas de colheita em tempo real, haptics mobile (`Input.vibrate_handheld`) e solicitação de camera shake.
- **[`UpgradeManager`](../../scripts/core/upgrade_manager.gd):** Gestor de economia de moedas verdes e progressão dos 4 atributos centrais da oficina (Raio da Lâmina, Potência e Fio, Velocidade da Serra e Multiplicador).

### 2.3 Mecânicas de Gameplay e Entidades 3D
- **O Cortador ([`cutter.tscn`](../../scenes/cutter/cutter.tscn) / [`cutter.gd`](../../scripts/cutter/cutter.gd)):**
  - Disco metálico circular com rotação angular constante de $1200^\circ/\text{s}$ no eixo Y.
  - Corte omnidirecional radial via `Area3D` com raio calibrável por upgrades.
  - Estado de choque com recuo elástico (knockback reverso de $5.0\text{ m/s}$), emissão de faíscas incandescentes e vibração de impacto seco contra rochas.
- **Vegetação Low Poly com Partículas:**
  - Tufos 3D de Grama Verde ([`grass_tuft.tscn`](../../scenes/plants/grass_tuft.tscn)), Trigo Dourado ([`wheat_tuft.tscn`](../../scenes/plants/wheat_tuft.tscn)) e Flores ([`flower_tuft.tscn`](../../scenes/plants/flower_tuft.tscn)).
  - Partículas de folhas e pétalas projetadas em arco parabólico natural (`gravity = -9.8 m/s²`).
  - Suporte a resistência de cortes para plantas densas.
- **Obstáculos e Terreno ([`rock.tscn`](../../scenes/obstacles/rock.tscn) / [`terrain.tscn`](../../scenes/level/terrain.tscn)):**
  - Ilha de jogo com piso verde aparado e 4 muretas limítrofes sólidas.
  - Rochas sólidas com colisão física tangencial e ricochete frontal.
- **Câmera Isométrica ([`isometric_camera.gd`](../../scripts/camera/isometric_camera.gd)):**
  - Ângulo zenital elevado ($Y = +11.0\text{m}, Z = +7.5\text{m}$) com amortecimento suave (`lerp`) e efeito de camera shake nos choques.

### 2.4 Controles e Interface (HUD)
- **Joystick Flutuante ([`floating_joystick.tscn`](../../scenes/ui/floating_joystick.tscn) / [`floating_joystick.gd`](../../scripts/ui/floating_joystick.gd)):**
  - Opera na metade inferior da tela, define a base dinamicamente no ponto de toque, possui zona morta de $12\text{ px}$ e suporte a mouse e teclado WASD/setas.
- **Top HUD & Modais ([`hud.tscn`](../../scenes/ui/hud.tscn) / [`hud.gd`](../../scripts/ui/hud.gd)):**
  - Top Bar com cronômetro circular (`1:30`), contadores pop em tempo real para cada meta, saldo de moedas e botão de pausa.
  - Modais de Pausa, Vitória, Derrota e Oficina de Upgrades interativa com `process_mode = PROCESS_MODE_ALWAYS`.

### 2.5 Fase 1 (MVP de Validação)
- Implementada em [`level_controller.gd`](../../scripts/level/level_controller.gd):
  - Retângulo compacto com 60 tufos de grama verde básica.
  - Cronômetro generoso de $1:30$.
  - Sem obstáculos internos para validação do game feel e fluidez de corte.

### 2.6 Governança e Documentação Canônica (Estrutura Rover Raid)
- Implantação da Central de Guardrails Invariantes [`GEMINI.md`](../../GEMINI.md).
- Criação da skill de governança [`.agent/skills/atualizar-documentacao/SKILL.md`](../../.agent/skills/atualizar-documentacao/SKILL.md).
- Hub Mestre da Wiki [`docs/PROJETO_GRASS_CUT_BOT.md`](../PROJETO_GRASS_CUT_BOT.md).
- Roadmap de [`docs/MELHORIAS_FUTURAS.md`](../MELHORIAS_FUTURAS.md).
- 10 documentos canônicos distribuídos nos 5 Pilares Temáticos e catálogo histórico perpétuo.

---

## 3. Validação e Verificação Técnica

- **Godot 4 Headless Import & Compilação:** Executado com sucesso via CLI (`exit code 0`), sem erros de sintaxe ou nós faltantes.
- **Execução Headless da Cena Principal:** Cena `main.tscn` carregada e processada por múltiplos frames sem erros ou exceções de runtime (`exit code 0`).
