# Projeto Grass Cut Bot 🌿🤖 (Hub Central da Wiki)

![Ícone Grass Cut Bot](../icon.svg)

## 1. Visão Geral e Filosofia do Jogo

**Grass Cut Bot** é um jogo hiper-casual e de simulação arcade com foco em relaxamento mecânico, feedback tátil responsivo (*satisfying game feel*) e partidas dinâmicas contra o relógio em formato vertical (Portrait), projetado sob medida para dispositivos Android.

O jogador assume o comando de um robô cortador equipado com uma serra circular omnidirecional em perspectiva isométrica. Seu objetivo é limpar gramados compactos, cumprir metas específicas de colheita vegetal (grama comum, trigo dourado e flores) antes do cronômetro zerar, desviando de rochas e barreiras sólidas.

O núcleo do jogo combina:
1. **Sensação Tátil Suculenta (Juicy Game Feel):** Vibração háptica leve e contínua sincronizada com cada tufo ceifado, partículas de folhas em arco parabólico e resposta ágil de corte radial imediato.
2. **Controle com Uma Mão (One-Thumb Play):** Joystick flutuante que surge em qualquer toque na metade inferior da tela, garantindo navegação natural sem fadiga motora.
3. **Loop de Metas e Recompensas:** Contadores de colheita no HUD que decrescem em tempo real e moedas verdes acumuladas para evoluir a máquina na Oficina de Upgrades (Raio, Potência, Velocidade e Multiplicador).

![Concept Art Oficial - Cutter Bit](./assets/cutter_bit_concept_art.jpg)
*Figura: Concept Art canônico do robô cortador Cutter Bit.*

---

## 📚 Índice Mestre da Documentação Técnica (Os 5 Pilares)

A documentação técnica, artística e de engenharia de **Grass Cut Bot** está estruturada em 5 Pilares Temáticos interconectados, além do Hub e do Catálogo Histórico:

### 🏛️ Pilar 1: Visão Geral, Design e Direção de Arte
1. **[GDD Oficial - Documento Vivo (v0.2)](./01_visao_geral_e_gdd/GDD_OFICIAL.md)**  
   O Game Design Document canônico: High Concept, USP, Core Loop, esquema de entrada, especificações do cortador, tipos de vegetação e estrutura dos estágios.
2. **[Direção de Arte e Estilo Visual](./01_visao_geral_e_gdd/DIRECAO_DE_ARTE_E_VISUAL.md)**  
   Identidade visual Low Poly com acabamento fosco (*matte*), paleta de cores sólidas vibrantes, iluminação suave, sombreamento de ilhas e efeitos de partículas.

---

### 🪚 Pilar 2: Entidades, Física e Mecânicas de Jogo
3. **[Sistema do Cortador (Serra Circular)](./02_entidades_e_mecanicas/SISTEMA_DO_CORTADOR.md)**  
   Estrutura mecânica da lâmina rotativa, rotação de alta velocidade (1200°/s), corte por contato radial omnidirecional, inércia responsiva e sistema de choque/knockback contra obstáculos sólidos.
4. **[Sistema de Vegetação e Colheita](./02_entidades_e_mecanicas/SISTEMA_DE_VEGETACAO.md)**  
   Grid regular de tufos 3D, variedades vegetais (Grama Verde, Trigo Dourado, Flores), resistência a golpes, remoção animada e lançamento de partículas parabólicas.
5. **[Sistema de Obstáculos e Ilha do Terreno](./02_entidades_e_mecanicas/SISTEMA_DE_OBSTACULOS_E_TERRENO.md)**  
   Piso estilizado aparado, muretas e cercas limítrofes da ilha, e rochas sólidas causadoras de ricochete e faíscas.

---

### 🗺️ Pilar 3: Level Design e Estrutura de Fases
6. **[Estrutura das Fases e Level Design](./03_level_design_e_fases/ESTRUTURA_DAS_FASES.md)**  
   Catálogo canônico das 20 fases em ilhas 3D flutuantes com geometrias únicas, progressão em 5 Tiers de maestria, introdução de trigo e flores, caminhos estreitos, labirintos rochosos e transição triunfal para o Ciclo Mestre.

---

### 🎮 Pilar 4: Sistemas, Interface, Controles e Metagame
7. **[Sistema de Controles Touch (Joystick Flutuante)](./04_sistemas_e_gameplay/SISTEMA_DE_CONTROLES_TOUCH.md)**  
   Lógica do joystick flutuante ancorado na metade inferior da tela, cálculo do vetor de arrasto, zona morta contra microtoques e suporte transparente para mouse e teclado no PC.
8. **[Sistema de Interface, HUD e Menus](./04_sistemas_e_gameplay/SISTEMA_DE_INTERFACE_HUD.md)**  
   Menu Inicial (Hub Principal) com Câmera Dual (Bot heróico e Mapa do Arquipélago com drag scroll), 4 abas inferiores (Garage, Home, Collection, Store), Modal de Configurações, Top HUD dinâmico e modais de Pausa, Vitória (com Próxima Fase) e Derrota.
9. **[Economia e Oficina de Upgrades](./04_sistemas_e_gameplay/ECONOMIA_E_OFICINA.md)**  
   Moedas verdes por tufo ceifado, progressão dos 4 atributos centrais da oficina (Raio da Lâmina, Potência e Fio, Velocidade da Serra e Multiplicador de Moedas).
10. **[Game Feel, Haptics e Câmera Isométrica](./04_sistemas_e_gameplay/GAME_FEEL_E_HAPTICS.md)**  
    Pilares do relaxamento mecânico, vibrações táteis sincronizadas (pulso curto no corte e impacto seco no obstáculo), câmera isométrica suave com interpolação e camera shake.

---

### ⚙️ Pilar 5: Engenharia de Software e Desenvolvimento
11. **[Arquitetura do Projeto Godot 4](./05_arquitetura_e_desenvolvimento/ARQUITETURA_DO_PROJETO.md)**  
    Organização de diretórios por responsabilidade (`scenes/`, `scripts/`, `assets/`, `docs/`), camadas físicas padronizadas (Layers 1 a 4) e Autoloads globais (`GameManager`, `UpgradeManager`).
12. **[Padrão de Scripts e Boas Práticas GDScript 4](./05_arquitetura_e_desenvolvimento/PADRAO_DE_SCRIPTS.md)**  
    Regras estritas de Zero Warnings, tipagem estática obrigatória, desacoplamento por sinais e prevenção de erros comuns de runtime.
13. **[Diretrizes de Desenvolvimento, Terminal e Git](./05_arquitetura_e_desenvolvimento/DIRETRIZES_DE_DESENVOLVIMENTO.md)**  
    Padrões para PowerShell no Windows, codificação UTF-8 sem BOM, ciclo Game SemVer e commits semânticos.
14. **[Portabilidade e Otimização para Android](./05_arquitetura_e_desenvolvimento/PORTABILIDADE_ANDROID.md)**  
    Parâmetros do preset de exportação Android, renderizador Mobile (Vulkan/GLES), renderização portrait e garantia de 60 FPS estáveis em telas mobile.

---

## 📜 Registro Histórico Perpétuo de Melhorias

Para consultar o histórico detalhado de todas as refatorações, construções e entregas técnicas do projeto, acesse:
👉 **[Catálogo Mestre do Histórico de Melhorias (`INDICE_MELHORIAS.md`)](./historico_melhorias/INDICE_MELHORIAS.md)**
- Consulte também a [Regra do Histórico Perpétuo](./historico_melhorias/regra_historico_melhorias.md).

---

## 🎯 Planejamento e Roadmap

Para acompanhar as próximas etapas de desenvolvimento ordenadas por impacto na experiência do jogador, consulte o **[Roadmap de Melhorias Futuras](./MELHORIAS_FUTURAS.md)**.
