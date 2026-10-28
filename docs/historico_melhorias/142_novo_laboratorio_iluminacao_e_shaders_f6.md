# Melhoria 142: Recriação do Laboratório Completo de Iluminação, Shaders e Game Feel (Acesso Direto com F6) 🌿🤖💡

## 🎯 Objetivo e Contexto
1. **Restauração e Recriação do Laboratório de Iluminação:**
   - A antiga cena de testes do Toon Shader havia sido removida em iterações anteriores, deixando desenvolvedores e artistas sem um ambiente rápido para calibrar a iluminação solar, ambientação, shaders cel e cores de terreno diretamente no Godot Engine.
   - O usuário solicitou explicitamente a recriação do laboratório com acesso direto pela tecla de atalho **F6** (Play Current Scene no Godot) e relatou que a iluminação geral do jogo precisava de calibração interativa porque o visual ainda não estava satisfatório.
2. **Resolução dos Gargalos do Laboratório Anterior:**
   - **Visualização Obstruída em Mobile Portrait (720x1280):** A ferramenta antiga possuía dois painéis laterais fixos que somavam 660px de largura em uma tela de 720px, cobrindo 90% da cena 3D e inviabilizando a inspeção visual.
   - **Ausência de Oceano e Contraste Descontextualizado:** A cena antiga não continha água, deixando o diorama em um vazio cinza/azul sem reflexos nem contraste com a espuma e o mar.
   - **Inércia e Falta de Jogabilidade:** Não era possível movimentar o cortador nem testar a interação dinâmica com o pasto (curvatura reativa foliar, colheita, partículas, sombras em movimento).

---

## 🛠️ O Novo Laboratório de Iluminação (`scenes/tools/lighting_lab.tscn`)

### 1. Arquitetura 3D Completa e Câmeras Duplas
- **Cenário 3D:**
  - `OceanMesh` instanciado com o shader canônico de água (`toon_water_material.tres`) em $320 \times 320\text{m}$.
  - `LevelContainer` compatível com todos os níveis de 01 a 20 (`LevelJsonLoader` + `VegetationGrid`), gerando ilha procedural, vegetação, flores, rochas e o Cutter Bit com física.
  - `StudioMount` e `Pedestal` cilíndrico para inspeção detalhada de 9 modelos avulsos com rotação suave contínua (*Turntable*).
- **Sistema de Câmeras Duplo:**
  - **Câmera Livre (Órbita 360°):** Controle por arrasto de mouse (botão esquerdo para órbita esférica, botão direito para pan e scroll para zoom).
  - **Câmera de Jogo (Isométrica Canônica):** Câmera idêntica à do gameplay principal com `isometric_camera.gd` seguindo o robô enquanto o usuário se movimenta com as teclas `WASD` ou `Setas` pelo teclado, permitindo testar cortes, mastigação de plantas e iluminação em tempo real.

### 2. Interface de Calibração Retrátil (Mobile Portrait & Desktop)
- **TopBar Compacta:** Permite alternar entre **Modo Nível (Fases 01 a 20)** e **Modo Estúdio (9 modelos)**, alternar entre **Câmera Livre** e **Câmera Jogo**, exibir/ocultar toda a UI (`👁️` ou `Tab`/`H`), salvar diretamente no jogo (`💾`) e copiar o código de configuração (`📋`).
- **Drawer Inferior Retrátil:** Ocupa apenas o rodapé da tela, deixando a área central livre para visualização 3D, podendo ser recolhido para uma barra de 26px com 1 clique ou atalho.
- **Abas Especializadas:**
  1. **☀️ Sol & Luz:** Energia solar (0.0 a 3.0), Pitch zenital (-89° a -5°), Yaw/Azimute (0° a 360°), Cor da luz, ativação de sombras e toggle de rotação contínua para simulação do ciclo dia/noite.
  2. **🌌 Ambiente & Céu:** Energia da luz ambiente (0.0 a 1.5), Cor ambiente, Cor do céu/background, Seleção de Tonemap (Linear, Reinhard, Filmic, ACES) e Exposição.
  3. **🎨 Toon Shader:** Seletor de materiais de plantas (8 tipos: Grama Verde, Amarela, Azul, Roxa, Branca, Vermelha, Preta e Trigo), Pickers de cor (Luz, Sombra e Base), Degrau Toon (Offset), Suavidade Cel (Smoothness), Gradiente Vertical, Rim Light (toggle, cor, potência, brilho) e Rugosidade fosca.
  4. **🏝️ Solo & Mar:** Cor do topo da ilha (`ground_base_color`), brilho do solo (`ground_brightness`), Difusão Toon no solo, Cor das falésias e personalização do oceano (raso/profundo).
  5. **⚡ Presets Canônicos:** 5 presets com aplicação em 1 clique:
     - ☀️ *Canônico Equilibrado* (Luz viva, sombras cel nítidas, estilo casual premium)
     - 🎮 *Produção Atual (main.tscn)* (Restaura o estado atual do jogo)
     - 🌅 *Golden Hour* (Pôr do sol tropical acolhedor com sombras alongadas)
     - 🏖️ *Casual Pop Saturado* (Alto contraste cel, cores ultra-vibrantes)
     - 🌙 *Crepúsculo Estilizado* (Ambiente relaxante com iluminação suave)

### 3. Integração e Persistência
- **Salvar no Jogo Diretamente:** O botão `💾 Salvar` grava as alterações diretamente nos arquivos `.tres` (`interactive_grass_material.tres`, etc.) e sincroniza as propriedades estáticas de `IslandMeshBuilder`.
- **Copiar Parâmetros:** O botão `📋 Copiar` gera o bloco GDScript / Shader parameters formatado pronto para documentação e versionamento no clipboard.

---

## 📁 Arquivos Criados e Modificados
1. **`scenes/tools/lighting_lab.tscn`:** Nova cena do laboratório de iluminação, configurada e pronta para execução via **F6**.
2. **`scripts/tools/lighting_lab.gd`:** Script do laboratório com suporte a inputs de teclado/mouse, controle do Cutter, carregamento de fases, presets e exportação.
3. **`scripts/cutter/cutter.gd`:** Proteção defensiva com `is_inside_tree()` em `rebuild_obstacles_cache()` para prevenir warnings caso o nó seja acessado fora da árvore.
4. **`tests/test_lighting_lab_runner.gd` e `tests/test_lighting_lab.tscn`:** Suíte automatizada de testes cobrindo nós 3D, câmeras, presets, níveis, estúdio, salvamento e cópia.
5. **`project.godot` e `export_presets.cfg`:** Versionamento atualizado para `v0.12.68-alpha` (Code 1268).

---

## ✅ Verificação e Testes
- **Execução Headless:** Executado `tests/test_lighting_lab.tscn` via Godot 4.7.1 Console:
  - 100% dos testes passaram com sucesso (0 erros, 0 warnings).
  - Testados carregamentos dinâmicos de níveis 01, 02, 05, 10 e 20.
  - Testados os 9 modelos de estúdio e os 5 presets de iluminação.
- **F6 no Editor Godot:** A cena `scenes/tools/lighting_lab.tscn` pode ser aberta e iniciada imediatamente com a tecla F6 para calibração interativa.
