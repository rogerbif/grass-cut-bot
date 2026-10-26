# Grass Cut Bot 🌿🤖

[![Versão](https://img.shields.io/badge/versão-v0.12.31--alpha-2ECC71.svg)](docs/05_arquitetura_e_desenvolvimento/SISTEMA_DE_VERSIONAMENTO.md)
[![Engine](https://img.shields.io/badge/Godot-4.7%20Mobile-478CBF.svg?logo=godotengine&logoColor=white)](https://godotengine.org)
[![Plataforma](https://img.shields.io/badge/plataforma-Android%20%7C%20PC%20Dev-orange.svg?logo=android&logoColor=white)](docs/05_arquitetura_e_desenvolvimento/PORTABILIDADE_ANDROID.md)
[![Zero Warnings](https://img.shields.io/badge/Godot%20Console-0%20Warnings-brightgreen.svg)](docs/05_arquitetura_e_desenvolvimento/PADRAO_DE_SCRIPTS.md)
[![Licença](https://img.shields.io/badge/licença-Proprietária%20%2F%20BifGames-blue.svg)](#licença)

> **Jogo mobile hiper-casual e de simulação arcade em 3D Low Poly com foco em relaxamento mecânico, feedback tátil contínuo (*satisfying game feel*) e partidas rápidas contra o relógio em modo vertical (*Portrait*), projetado sob medida para Android.**

![Concept Art Oficial - Cutter Bit](docs/assets/cutter_bit_concept_art.jpg)

---

## 🎮 High Concept & Core Loop

No comando do **Cutter Bit** — um robô cortador ágil de monociclo (*mono-wheel*) e serra circular omnidirecional —, seu objetivo é navegar por ilhas 3D flutuantes no oceano, cumprir cotas de colheita botânica (grama comum, trigo dourado de 2 golpes e flores nobres) antes do cronômetro zerar e desviar de rochas sólidas para acumular moedas verdes na oficina de upgrades.

```
       ┌────────────────────────┐
       │   1. Entrar na Ilha    │
       └───────────┬────────────┘
                   ▼
       ┌────────────────────────┐
       │  2. Navegação 1-Thumb  │ ◄─── Toque em qualquer ponto inferior
       └───────────┬────────────┘
                   ▼
       ┌────────────────────────┐
       │ 3. Corte Radial Satisf.│ ◄─── Vibração háptica + folhas em arco
       └───────────┬────────────┘
                   ▼
       ┌────────────────────────┐
       │  4. Bater as Metas ⏱️   │ ◄─── Grama (1x), Trigo (2x), Flores (5x)
       └───────────┬────────────┘
                   ▼
       ┌────────────────────────┐
       │  5. Oficina & Evolução │ ◄─── Raio, Potência, Velocidade e Lâminas
       └────────────────────────┘
```

---

## ✨ Destaques de Design e Tecnologia

- **🕹️ Controles One-Thumb com Joystick Flutuante:** Operação natural com uma mão ancorada na metade inferior da tela, zona morta contra toques acidentais e fallback instantâneo para mouse/teclado no PC.
- **🏝️ Ilhas 3D Modulares Sem Cercas:** Cenários estilizados sobre oceano azul turquesa toon, falésias costeiras arredondadas, espuma litorânea e contenção invisível na Layer 1 (o robô nunca cai na água, dispensando grades visuais).
- **🪚 Serra Circular Omnidirecional & Tiers de Lâminas:** Corte por contato radial contínuo (1200°/s) com 4 modelos 3D estrelados na Oficina (Tripla, Ninja de 4 pontas, Titânio de 5 pontas e Vortex de 6 pontas).
- **🌾 Vegetação Orgânica & Efeito Grama Cortada:** Tufos gerados por algoritmo Poisson Disk sobre malhas trianguladas e renderizados via `MultiMeshInstance3D`, com tocos aparados e lâminas fatiadas deitadas no solo.
- **📳 Feedback Multissensorial (*Juicy Game Feel*):** Pulso háptico sutil sincronizado a cada ceifada (`Input.vibrate_handheld(30)`), impacto seco com recuo elétrico em rochas, números cartoon flutuantes cel-shaded (`+1`, `+3`, `+5`) com rastro e celebração de vitória com câmera heróica.
- **🎵 Sonoplastia Completa:** Barramentos isolados (`Master`, `Music`, `SFX`), trilhas dinâmicas de Dyalla, motor elétrico modulado proceduralmente por velocidade e 20 efeitos sonoros autônomos.
- **🛠️ Editor de Fases PC Fullscreen Integrado:** Ferramenta in-game em janela widescreen (F2/F6) com Auto-Tile de ilhas, pincel livre com Clipper C++, carimbos analíticos de formas de 1x a 20x, cards de metas configuráveis e playtest instantâneo com F1.
- **⚡ Performance Mobile Estrita (60 FPS):** Culling de sombras, pool compartilhado de partículas, eliminação de depth texture em água mobile, shaders com parâmetros globais e zero warnings no console.

---

## 🏛️ Estrutura da Documentação Técnica (Os 5 Pilares)

Todo o ecossistema do projeto está documentado de forma viva e canônica na pasta [`docs/`](docs/PROJETO_GRASS_CUT_BOT.md):

| Pilar Temático | Documentos Canônicos | Descrição |
| :--- | :--- | :--- |
| **🏛️ 1. Visão Geral & Arte** | [`GDD_OFICIAL.md`](docs/01_visao_geral_e_gdd/GDD_OFICIAL.md)<br>[`DIRECAO_DE_ARTE_E_VISUAL.md`](docs/01_visao_geral_e_gdd/DIRECAO_DE_ARTE_E_VISUAL.md) | Game Design Document vivo, USP, Core Loop, paleta de cores foscas, iluminação e shader toon. |
| **🪚 2. Entidades & Mecânicas** | [`SISTEMA_DO_CORTADOR.md`](docs/02_entidades_e_mecanicas/SISTEMA_DO_CORTADOR.md)<br>[`SISTEMA_DE_VEGETACAO.md`](docs/02_entidades_e_mecanicas/SISTEMA_DE_VEGETACAO.md)<br>[`SISTEMA_DE_OBSTACULOS_E_TERRENO.md`](docs/02_entidades_e_mecanicas/SISTEMA_DE_OBSTACULOS_E_TERRENO.md) | Física de corte radial, modelo 3D do Cutter Bit, suspensão procedural, multi-meshes foliares e falésias. |
| **🗺️ 3. Level Design & Editor** | [`ESTRUTURA_DAS_FASES.md`](docs/03_level_design_e_fases/ESTRUTURA_DAS_FASES.md)<br>[`SISTEMA_EDITOR_DE_FASES.md`](docs/03_level_design_e_fases/SISTEMA_EDITOR_DE_FASES.md) | Catálogo das 20 fases canônicas, 5 tiers de progressão e editor de fases PC com prancheta vetorial. |
| **🎮 4. Sistemas, UI & Áudio** | [`SISTEMA_DE_CONTROLES_TOUCH.md`](docs/04_sistemas_e_gameplay/SISTEMA_DE_CONTROLES_TOUCH.md)<br>[`SISTEMA_DE_INTERFACE_HUD.md`](docs/04_sistemas_e_gameplay/SISTEMA_DE_INTERFACE_HUD.md)<br>[`ECONOMIA_E_OFICINA.md`](docs/04_sistemas_e_gameplay/ECONOMIA_E_OFICINA.md)<br>[`GAME_FEEL_E_HAPTICS.md`](docs/04_sistemas_e_gameplay/GAME_FEEL_E_HAPTICS.md)<br>[`SISTEMA_DE_AUDIO_E_SFX.md`](docs/04_sistemas_e_gameplay/SISTEMA_DE_AUDIO_E_SFX.md) | Joystick flutuante, Top HUD com metas dinâmicas, modais em processo contínuo, haptics e arquitetura de áudio. |
| **⚙️ 5. Engenharia & Mobile** | [`ARQUITETURA_DO_PROJETO.md`](docs/05_arquitetura_e_desenvolvimento/ARQUITETURA_DO_PROJETO.md)<br>[`PADRAO_DE_SCRIPTS.md`](docs/05_arquitetura_e_desenvolvimento/PADRAO_DE_SCRIPTS.md)<br>[`DIRETRIZES_DE_DESENVOLVIMENTO.md`](docs/05_arquitetura_e_desenvolvimento/DIRETRIZES_DE_DESENVOLVIMENTO.md)<br>[`PLANO_MESTRE_DE_PERFORMANCE.md`](docs/05_arquitetura_e_desenvolvimento/PLANO_MESTRE_DE_PERFORMANCE.md)<br>[`PORTABILIDADE_ANDROID.md`](docs/05_arquitetura_e_desenvolvimento/PORTABILIDADE_ANDROID.md)<br>[`SISTEMA_DE_SAVE.md`](docs/05_arquitetura_e_desenvolvimento/SISTEMA_DE_SAVE.md)<br>[`SISTEMA_DE_VERSIONAMENTO.md`](docs/05_arquitetura_e_desenvolvimento/SISTEMA_DE_VERSIONAMENTO.md) | Padrão GDScript 4 defensivo, Zero Warnings, pipeline glTF Blender, save atômico `.bak`, Game SemVer e otimização Android. |

- 📜 **Histórico Completo de Entregas:** [`docs/historico_melhorias/INDICE_MELHORIAS.md`](docs/historico_melhorias/INDICE_MELHORIAS.md) (106+ melhorias técnicas catalogadas).
- 🧭 **Planejamento Futuro:** [`docs/MELHORIAS_FUTURAS.md`](docs/MELHORIAS_FUTURAS.md) (Roadmap de novidades, incluindo o modo construtor mobile "Bot Arquiteto").

---

## 🚀 Como Executar o Projeto

### Pré-requisitos
- **Engine:** [Godot Engine 4.3+](https://godotengine.org) (recomendado Godot 4.7 Mobile/Standard).
- **Ambiente:** Windows, Linux ou macOS para desenvolvimento.
- **Exportação Mobile:** Android SDK configurado para builds APK/AAB.

### Executando no Editor Godot
1. Clone o repositório:
   ```bash
   git clone https://github.com/rogerbif/grass-cut-bot.git
   ```
2. Abra a Godot Engine e importe o arquivo `project.godot`.
3. Pressione **F5** para iniciar o jogo a partir do Menu Principal (`res://scenes/menu/main_menu.tscn`).
4. **Atalhos Úteis no PC:**
   - `WASD` ou `Setas`: Movimentação do robô.
   - `Mouse`: Arrasto simulando o joystick touchscreen.
   - `F2` (ou botão no menu): Abre o Editor de Fases In-Game PC widescreen.
   - `F1` (dentro do editor): Aciona o modo Playtest com o robô real.

---

## 📄 Licença

Projeto desenvolvido e mantido por **BifGames** / **Roger Bif**. Todos os direitos reservados. Código e modelos proprietários.
