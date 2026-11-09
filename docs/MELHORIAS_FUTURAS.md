# Roadmap de Melhorias Futuras & Estratégia de Publicação: Grass Cut Bot 🌿🤖

Este documento contém o planejamento canônico de evolução do jogo, dimensionamento de conteúdo para lançamento em lojas móveis (*Google Play Store* e *App Store*), retenção causal, metagame e refinamentos de *Game Feel*.

---

## 🎯 1. Estratégia de Lançamento & Arquitetura de Mundos

No ecossistema de jogos casuais e arcade mobile, a retenção de jogadores (D1 e D7) depende diretamente da cadência de conteúdo novo sem frustração e com sensação nítida de progressão geográfica. O jogo adota a estrutura canônica de **Mundos Temáticos**:

| Marco de Publicação | Fases Canônicas | Status Atual | Foco Estratégico & Retenção |
| :--- | :---: | :---: | :--- |
| **🚀 MVP / Soft Launch** | **20 Fases** | ✅ **Concluído e Validado** | Validação de engajamento primário, sensação do joystick *one-thumb*, curva de dificuldade dos 5 Tiers e taxa de 60 FPS estáveis em aparelhos Android de entrada. |
| **🌟 Lançamento Global — Mundo 1 (Ilhas Tropicais Diurno)** | **40 Fases Canônicas** | ✅ **Concluído e Auditado** | 40 fases canônicas serializadas em JSON v4, divididas em 4 Tiers com grandes ilhas e mega-ilhas interligadas pelo mapa do arquipélago. O **Ciclo Mestre (New Game+)** garante rejogabilidade infinita aos jogadores que concluírem o nível 40. |
| **🌴 Expansão Total do Mundo 1: Ilhas Tropicais (Diurno)** | **100 Fases Revisadas** | ⏳ **Meta Canônica do Mundo 1** | O Mundo 1 compreenderá exatamente **100 fases autorais, criadas e revisadas**, todas sob o tema diurno clássico (sol a pino, céu ciano e mar turquesa). **Sem variações atmosféricas dentro do mesmo mundo:** a identidade visual é 100% coesa e imersiva ao longo de todo o primeiro arquipélago. |
| **🌇 Desbloqueio do Mundo 2: Sunset / Ilhas do Entardecer** | **100 Novas Fases (101 a 200)** | 🔒 **Condicionado à Conclusão do Mundo 1** | **Diretriz Canônica Invariante:** As variações atmosféricas e de iluminação constituem **Mundos Próprios**. O **Mundo 2 (Mundo Sunset / Entardecer Dourado)** será criado **exclusivamente após a entrega, revisão e aprovação completa de todas as 100 fases do Mundo 1**. |
| **🌌 Desbloqueio do Mundo 3: Noite Tropical / Night World** | **100 Novas Fases (201 a 300)** | 🔒 **Condicionado à Conclusão do Mundo 2** | Terceiro mundo canônico com temática noturna completa (céu estrelado, reflexos lunares no mar e farol do cortador), criado apenas após 100 fases criadas e revisadas no Mundo 2. |

---

## 🏆 2. Metagame, Coleção e Retenção Casual

### 2.1 Ativação Real da Aba Coleção (`TabCollection`) — Herbário Botânico
- **🌿 Herbário da Ilha Interativo:** Conexão direta dos cards botânicos com os dados persistidos no `SaveManager`. O jogador visualiza:
  - As 7 variantes de cor da **Grama Comum** (Verde, Amarela, Azul, Roxa, Branca, Vermelha, Preta).
  - O **Trigo Maduro** (Cultura de 2 hits com textura de espiga).
  - O catálogo completo das 6 **Flores Nobres** (Margarida, Rosa, Flor de Sino, Girassol, Tulipa e Corola).
- **📊 Estatísticas Acumuladas & Mestrado:**
  - Contador vitalício de tufos ceifados por espécie vegetal.
  - Total histórico de moedas verdes colhidas e tempo total acumulado em corte.
  - Recompensas em moedas e insígnias cosméticas ao atingir marcos de colheita (ex: *"Colha 500 Trigos"* ➔ Ganha insígnia dourada e 300 moedas).

### 2.2 Customização de Carcaça do Robô & Lâminas (`TabGarage` / `TabStore`)
- **🎨 Pinturas do Cutter Bit (Skins de Chassi):** Adquiridas na Oficina/Loja com moedas do jogo:
  - 🟡 **Amarelo Clássico:** A pintura original icônica de fábrica.
  - 🔵 **Azul Ciano Ártico:** Chassi azul turquesa vibrante com olhos elétricos.
  - 🔴 **Vermelho Arcade Turbo:** Chassi esportivo com acabamento acetinado.
  - ⚫ **Preto Grafite Stealth:** Preto fosco com detalhes dourados.
  - 🟢 **Verde Limão Botânico:** Camuflagem tropical.
- **✨ Temas Cosméticos de Lâmina:** Trilhas visuais de corte customizadas (azul neon, arco-íris pastel, faíscas douradas).

### 2.3 Engajamento Diário & Desafios Rápidos
- **🎁 Recompensa Diária (Daily Login Bonus):** Temporizador de 24h real com bônus crescente de moedas a cada dia consecutivo de login.
- **📜 Missões Rápidas (3 Tarefas Diárias):**
  - Exemplo 1: *"Ceife 200 tufos de grama amarela."*
  - Exemplo 2: *"Conclua 2 fases sem colidir com rochas."*
  - Exemplo 3: *"Alcance a Lâmina Nível 5 ou 6 em qualquer fase."*

---

## 🌅 3. Arquitetura de Mundos Temáticos: Atmosferas como Novos Mundos

### 3.1 Diretriz Canônica: Sem Variantes Atmosféricas no Mesmo Mundo
Para preservar a consistência visual, imersão temática e identidade clara de progressão:
- **Não haverá alternância de atmosferas ou horários do dia dentro de um mesmo mundo.**
- Cada atmosfera, clima ou momento do dia (Diurno, Sunset, Noturno, etc.) constitui um **Mundo Temático Próprio e Completo**.
- Cada mundo é dimensionado para um conjunto sólido de **100 fases autorais, criadas e revisadas**.

### 3.2 O Roteiro Sequencial de Mundos Canônicos

1. **☀️ Mundo 1: Ilhas Tropicais Diurnas (Fases 01 a 100):**
   - **Atmosfera Exclusiva:** Dia tropical ensolarado em todas as 100 fases. Céu azul ciano límpido, sol a pino com sombras nítidas e acolhedoras, mar turquesa vibrante (`#46E6FF`).
   - **Escopo:** Atualmente conta com as 40 fases canônicas criadas e auditadas; expandirá até atingir a meta de **100 fases criadas e revisadas**.
2. **🌇 Mundo 2: Ilhas do Entardecer Dourado / Sunset World (Fases 101 a 200):**
   - **Atmosfera Exclusiva:** Ambiente completo de pôr do sol / golden hour em todas as 100 fases. Céu alaranjado suave com névoa quente, mar em tons âmbar/cobre suave e luz solar baixa com sombras longas e acolhedoras.
   - **Regra Canônica de Liberação:** O Mundo 2 começará a ser construído **estritamente após a conclusão, auditoria e revisão das 100 fases do Mundo 1**.
3. **🌌 Mundo 3: Noite Tropical Estrelada / Night World (Fases 201 a 300):**
   - **Atmosfera Exclusiva:** Ambiente noturno completo em todas as 100 fases. Céu azul-marinho profundo pontilhado de estrelas, mar escuro com reflexos lunares, partículas de vaga-lumes sobre os gramados e farol sutil do Cutter Bit iluminando a frente de corte.
   - **Regra Canônica de Liberação:** Criado **exclusivamente após a conclusão e revisão das 100 fases do Mundo 2**.
4. **🌺 Mundos Futuros (Mundo 4+):**
   - Novos mundos conceituais (ex: *Mundo Alvorada/Twilight*, *Oásis das Dunas*, *Arquipélago Glacial*), sempre respeitando a cadência de 100 fases revisadas por mundo.

---

## ⚡ 4. Gameplay Dinâmico & Gimmicks de Level Design

### 4.1 Power-ups Coletáveis de Campo
Itens especiais que brotam esporadicamente no gramado e ativam efeitos temporários ao serem ceifados:
- **🚀 Cogumelo Turbo:** Concede 5 segundos de sobrecarga: velocidade do cortador aumentada em +40%, rotação da serra acelerada em 2x e rastro de vento nas esteiras.
- **🧲 Trevo Magnético (Ímã de Moedas):** Atrai moedas flutuantes e aparas diretamente para o Cutter Bit por 6 segundos.
- **⚡ Sobrecarga Relâmpago:** Concede à lâmina corte instantâneo de 1 hit em qualquer vegetação resistente (trigo e flores) durante 4 segundos.

### 4.2 Novos Obstáculos Interativos
- **🪨 Rochas Rachadas (Destrutíveis):** Pedras com fissuras visíveis e partículas de poeira que se partem em pedaços ao sofrerem impacto de Lâminas de Tier avançado (Tier 3+) ou Nível 6, liberando atalhos e canteiros nobres de flores.
- **🪵 Troncos Caídos e Raízes:** Obstáculos lineares/retangulares que forçam o jogador a contornar bordas mais largas, variando a silhueta das tradicionais rochas cilíndricas.

---

## 📱 5. Pipeline de Publicação Mobile (Android & Lojas de Apps)

### 5.1 Validação em Hardware Real Android
- Testes rigorosos de framerate contínuo (60 FPS travados) em aparelhos das faixas de entrada (ex: Mali-G52 / Adreno 610) e intermediários.
- Validação física da resposta dos motores hápticos (ERM e LRA) via `Input.vibrate_handheld(15)` em aparelhos Xiaomi/Redmi, Samsung Galaxy e Google Pixel.
- Teste de consumo térmico e ciclo de vida (`NOTIFICATION_APPLICATION_PAUSED` / `RESUMED`).

### 5.2 Kit de Lançamento na Google Play Store
- **Ícones Oficiais Sincronizados:** Ícone adaptativo com zona segura de 72dp/288px centralizada (foreground 432x432 e background 432x432) e ícone clássico 192x192.
- **Feature Graphic (1024 x 500 px):** Banner de destaque da loja com renderização heroica do Cutter Bit em ação sobre ilha flutuante.
- **Screenshots de Conversão (Portrait 9:16 - 1080 x 1920 px):**
  1. *"Corte Relaxante e Satisfatório"* (Cutter Bit ceifando em arco com partículas de folhas).
  2. *"Evolua suas Lâminas e Robô"* (Interface da Oficina com Tiers de lâminas e atributos).
  3. *"Jardins e Ilhas Flutuantes Únicas"* (Visão panorâmica da Fase 20 em trevo de 4 folhas).
  4. *"Colete Espécies Nobres de Flores"* (Canteiros coloridos com feedback numérico flutuante).
  5. *"Controles Fáceis com Uma Mão"* (Joystick flutuante ágil no polegar).

---

## 🚜 6. Modo Construtor Mobile: "Bot Arquiteto"

Conceito diegético de editor de fases executado diretamente no celular pelo jogador:
- O jogador pilota o próprio Cutter Bit com o joystick virtual sobre o mar. Conforme anda, imprime solo 3D modular com autotile em tempo real.
- Botões de ação rápida no polegar para alternar entre semear grama, plantar trigo/flores e ejetar rochas.
- Alternância instantânea de 1 toque entre o modo de construção e o corte jogável para teste da fase.

---

## ✅ Histórico de Metas Canônicas Concluídas

- [x] **20 Fases Canônicas com Autotile:** Arquipélago de 20 ilhas 3D flutuantes sem cercas e com 5 Tiers de maestria ([Melhoria 034](historico_melhorias/034_criacao_20_fases_canonicas.md)).
- [x] **Toon Shader Gradiente e Iluminação Canônica:** Sombreamento cel-shaded, normais 360°, rim lighting e solo em harmonia ([Melhorias 124](historico_melhorias/124_integracao_toon_shader_grama_e_iluminacao_canonicos.md), [125](historico_melhorias/125_calibracao_final_toon_shader_grama_e_solo_da_ilha.md) e [126](historico_melhorias/126_calibracao_luz_e_diferenciacao_cores_vegetacao.md)).
- [x] **Câmera Isométrica com Zoom Dinâmico por Nível de Lâmina:** Transição fluida de 7.20m (Lv 1) até 10.80m (Lv 6 MAX) ([Melhorias 129](historico_melhorias/129_camera_zoom_dinamico_por_nivel_lamina.md) e [134](historico_melhorias/134_recalibracao_zoom_camera_faixa_lv2_a_lv5.md)).
- [x] **Feedback Sensorial de Level Up na Partida:** Pop elástico (1.38x), flash de energia (2.5x), onda de choque radial e shader de slash contínuo ultra-leve na GPU ([Melhoria 135](historico_melhorias/135_pop_flash_choque_e_shader_slash_level_up.md)).
- [x] **Áudio e Sonoplastia Completa:** Trilha do menu, trilha de jogo, som contínuo do motor com modulação de pitch, corte radial polifônico e coleta de moedas ([Melhoria 074](historico_melhorias/074_sistema_de_audio_e_sonoplastia_completo.md)).
- [x] **SaveGame Atômico e 3 Estrelas:** Persistência segura em JSON com backup `.bak` e registro de pontuação por fase ([Melhoria 037](historico_melhorias/037_sistema_de_savegame_e_persistencia_de_dados.md)).
- [x] **Editor de Fases PC Fullscreen:** Prancheta vetorial plana, autotile e playtest instantâneo com F1 ([Melhorias 028](historico_melhorias/028_editor_de_fases_pc_ilhas_3d_e_carimbos.md), [096](historico_melhorias/096_revisao_ui_editor_fases_e_metas_customizadas.md) e [099](historico_melhorias/099_grama_vetorial_editor_e_playtest_f1.md)).
