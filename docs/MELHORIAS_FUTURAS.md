# Roadmap de Melhorias Futuras: Grass Cut Bot 🌿🤖

Este documento contém o planejamento de evolução do jogo organizado por impacto na experiência do jogador (*Juicy Game Feel*, retenção casual, metagame e qualidade técnica mobile).

---

## 🚀 1. Gameplay Dinâmico & Juicy Game Feel

### 1.1 Power-ups e Bônus de Campo
- **🍄 Cogumelo Turbo:** Tufo especial no gramado que, ao ser ceifado, concede 4 a 5 segundos de sobrecarga: rotação da serra acelerada em 2x, raio de lâmina ampliado temporariamente (+0.25m), aura energética brilhante e SFX em alta frequência.
- **🌟 Flor Dourada Rara:** Espécie que brota esporadicamente nas fases e murcha após 10 segundos caso não seja colhida, recompensando o jogador com um bônus gordo de $+25$ moedas.
- **🧲 Imã de Moedas / Trevo de 4 Folhas:** Efeito temporário que atrai automaticamente moedas emitidas ou duplica ganhos durante 6 segundos.

### 1.2 Feedback Visual e "Juiciness"
- **[ENTREGUE v0.12.4-alpha] 🪙 Moedas Flutuantes Tridimensionais:** Textos estilizados cel-shaded cartoon (`+1`, `+3`, `+5`) com contorno preto grosso (14px) e rastro contínuo no mundo 3D ao ceifar tufos.
- **[ENTREGUE v0.12.3-alpha] 🎉 Celebração de Vitória (3 ⭐):** Câmera heroica frontal, bot sorrindo e saltando com squash & stretch, confetes e fogos de artifício 3D, estrelas em arco e transição para comportamento vivo.
- **[ENTREGUE v0.12.3-alpha] 💥 Reação Dramática de Derrota:** Quando o cronômetro zera, animação dos olhos em `SAD`, robô cabisbaixo com suspensão cedida, fumaça cinza saindo do motor e lâmina desacelerando por inércia.
- **💨 Poeira e Marcas de Manobra:** Pequenas partículas de poeira branca/terra saindo da mono-wheel ao mudar bruscamente de direção no gramado.

---

## 🏆 2. Metagame, Coleção e Retenção Casual

### 2.1 Ativação Real da Aba Coleção (`TabCollection`)
- **🌿 Herbário da Ilha Interativo:** Conexão direta dos cards botânicos com os dados de progresso no `SaveManager`. Exibe espécies descobertas e bloqueadas por nível.
- **📊 Estatísticas Globais de Carreira:**
  - Total acumulado de tufos cortados (Grama, Trigo, Flores).
  - Total de moedas verdes colhidas historicamente.
  - Estrelas totais conquistadas no arquipélago (ex: $52/60 \star$).
  - Tempo total de corte acumulado.
- **🎖️ Sistema de Conquistas e Badges:**
  - Condecorações desbloqueáveis com recompensa em moedas:
    - *"Ceifador Implacável"*: Cortar 1.000 tufos.
    - *"Mestre das 3 Estrelas"*: Conquistar 3 estrelas em 10 fases.
    - *"Corte Cirúrgico"*: Vencer uma fase sem bater em nenhuma rocha.
    - *"Lâmina Lendária"*: Atingir o Tier 4 na Oficina.

### 2.2 Loja & Engajamento Diário (`TabStore`)
- **🎁 Recompensa Diária (Daily Reward):** Temporizador de 24 horas real com bônus progressivo de moedas a cada dia consecutivo de login.
- **📦 Pacotes de Recursos:** Conversão ou pacotes temáticos de moedas desbloqueáveis.

---

## 🎨 3. Customização e Oficina do Robô

### 3.1 Pinturas de Chassi (Skins do Cutter Bit)
- Variações de cor e materiais aplicadas à carcaça do robô, adquiridas na Oficina com moedas ganhas em jogo:
  - 🟡 **Amarelo Clássico:** A pintura amarela vibrante icônica de fábrica.
  - 🔵 **Azul Ciano Ártico:** Chassi azul turquesa com olhos ciano brilhantes.
  - 🔴 **Vermelho Arcade Turbo:** Chassi vermelho esportivo com acabamento acetinado.
  - ⚫ **Preto Grafite Stealth:** Preto fosco com detalhes em dourado metálico.
  - 🟢 **Verde Limão Esmeralda:** Camuflagem botânica.

### 3.2 Acessórios Cosméticos
- Pequenos adereços de topo para o robô:
  - Antena com bandeirinha quadriculada.
  - Mini hélice de brinquedo giratória.
  - Óculos escuros estilo arcade.

---

## 🗺️ 4. Variedade de Cenários, Obstáculos e Novos Modos

### 4.1 Novos Obstáculos e Elementos Interativos
- **🪵 Troncos Caídos e Raízes:** Obstáculos sólidos retangulares/alongados (diferentes das rochas cilíndricas) que exigem manobras perimetrais mais amplas.
- **💧 Poças de Lama / Areia Fofa:** Áreas de piso que reduzem temporariamente a tração e velocidade do cortador em 35% ao passar por cima.

### 4.2 Novos Biomas e Variações Visuais
- **🍂 Ilhas de Crepúsculo (Outono):** Terreno em tons quentes, gramado dourado/âmbar, água arroxeada e folhagens secas ao vento.
- **🌌 Ilhas Noturnas Bioluminescentes:** Iluminação suave de luar, mar escuro profundo com reflexos estelares, gramado violeta fluorescente e vaga-lumes flutuantes.

### 4.3 Modos de Jogo Alternativos
- **🧘 Modo Zen / Anti-Estresse:** Jogo livre em ilha ampla sem cronômetro, sem metas obrigatórias e sem risco de derrota, focado 100% no prazer relaxante de aparar toda a vegetação com som das ondas.
- **⏱️ Desafio Diário (Time Attack):** Fase especial gerada ou selecionada rotativamente por dia com contagem de milissegundos e tabela local de recordes pessoais.

### 4.4 Modo Construtor Mobile: "Bot Arquiteto" (Editor de Fases Jogável One-Thumb)
- **🚜 Conceito Diegético Jogável:** Em vez de depender de janelas e precisão de mouse do PC, o jogador pilota o próprio Bot usando o joystick virtual na metade inferior da tela para terraformar e desenhar fases de forma relaxante e tátil.
- **🏝️ Terraplanagem & Auto-Tile em Tempo Real:** Conforme o robô se desloca sobre o oceano com propulsores flutuantes, imprime blocos de ilha 3D e aciona o auto-tile dinamicamente (falésias, cantos arredondados e espuma litorânea calculados no rastro).
- **🌿 Semeador de Vegetação:** O robô espalha grama verde ou trigo maduro sob as esteiras, com largura de traço ajustável (1 a 3 blocos de cobertura).
- **🪨 Ejeção Rápida de Obstáculos & Itens:** Botões de ação rápida no polegar para ejetar rochas sólidas, plantar flores nobres ou marcar o ponto de início (`cutter_spawn`).
- **🌊 Draga / Cavação (Borracha):** Modo reverso que cava o solo sob o robô, restaurando o mar aberto e removendo obstáculos em um único passe.
- **🔄 Loop Instantâneo "Construir ➔ Testar (1 Toque)":** Alternância imediata entre a ferramenta de semeadura e a lâmina de corte. O cálculo das metas de vitória é automático com base no total plantado na fase.
- **🔍 Navegação Livre & Drone:** Gesto de pinça (*pinch-to-zoom*) para subir a câmera em visão panorâmica aérea de satélite, com botão de recentralização instantânea no robô.
- **💾 Salvamento e Compartilhamento:** Persistência em `user://custom_levels/*.json` com geração de códigos curtos/QR para troca de mapas entre jogadores.

---

## ✅ Histórico de Metas Antigas Concluídas

Os itens prioritários das versões anteriores já consolidados na árvore de desenvolvimento canônica:

- [x] **Sistema de Áudio e Sound Design:** AudioManager com 20 SFX, trilhas e motor sonoro ([Melhoria 074](historico_melhorias/074_sistema_de_audio_e_sonoplastia_completo.md)).
- [x] **Persistência de Dados e SaveGame:** SaveManager com escrita atômica, backup .bak e estrelas ([Melhoria 037](historico_melhorias/037_sistema_de_savegame_e_persistencia_de_dados.md)).
- [x] **Efeito Visual de Solo Aparado:** Tocos aparados e aparas de grama cortada deitadas no chão ([Melhorias 058](historico_melhorias/058_efeito_grama_cortada_tocos_aparados.md) e [060](historico_melhorias/060_aparas_grama_cortada_deitada_no_chao.md)).
- [x] **Lâminas Estreladas e Tiers:** Modelagem 3D dos Tiers 1 a 4 com arestas retas no rotor ([Melhorias 012](historico_melhorias/012_nova_lamina_tripla_tier_1.md), [013](historico_melhorias/013_nova_lamina_quadrupla_tier_2.md), [015](historico_melhorias/015_familia_laminas_estreladas_e_amarelo_vibrante.md), [032](historico_melhorias/032_ajuste_raio_base_e_incremento_lamina.md)).
- [x] **20 Fases Canônicas com Autotile:** Arquipélago de 20 ilhas 3D flutuantes sem cerca ([Melhorias 034](historico_melhorias/034_criacao_20_fases_canonicas.md) e [076](historico_melhorias/076_sincronizacao_fases_e_aumento_folhas_tufo.md)).
- [x] **Menu Inicial Hub com Diorama 3D & Mapa:** Câmera dual, scroll 1:1, placas adaptativas e lazy loading ([Melhorias 035](historico_melhorias/035_menu_inicial_hub_principal_com_camera_dual_e_tabs.md), [047](historico_melhorias/047_menu_ilhas_miniatura_scroll_1_a_1_e_placas_adaptativas.md), [051](historico_melhorias/051_lazy_loading_ilhas_e_persistencia_em_memoria.md)).
- [x] **Preset Android, Haptics & Ícone Oficial:** Permissões, haptics calibrado a 25%/80% e novos ícones comerciais ([Melhorias 072](historico_melhorias/072_correcao_permissao_e_calibracao_vibracao_celular.md) e [077](historico_melhorias/077_atualizacao_novo_icone_oficial.md)).
