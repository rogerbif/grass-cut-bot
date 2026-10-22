# Portabilidade e Otimização para Android 📱🚀

Este documento reúne os requisitos técnicos, presets de exportação e boas práticas de desempenho para a execução suave de **Grass Cut Bot** no ecossistema Android.

---

## 1. Configurações da Janela e Orientação

- **Orientação Fixa (Portrait):** Configurada como `window/handheld/orientation = 1` (`portrait`). A rotação da tela é bloqueada no manifesto Android para evitar redraws custosos e garantir jogabilidade confortável com uma só mão.
- **Resolução Base:** Viewport virtual em `720 x 1280` pixels com `window/stretch/mode = "canvas_items"` e `window/stretch/aspect = "keep_width"`. Essa configuração preenche perfeitamente aparelhos de proporções alongadas modernas (19.5:9 e 20:9) sem cortes nos elementos críticos do HUD.

---

## 2. Escolha do Renderizador da Godot 4

- **Modo Padrão (`mobile`):**
  - Utiliza a API Vulkan mobile moderna da Godot 4.
  - Oferece suporte eficiente a materiais StandardMaterial3D e sombras dinâmicas de alta fidelidade.
- **Alternativa de Compatibilidade Ampla (`gl_compatibility`):**
  - Utiliza OpenGL ES 3.0 / WebGL2.
  - Recomendado se o público alvo incluir smartphones Android de entrada com drivers Vulkan instáveis.

---

## 3. Diretrizes de Otimização para 60 FPS Mobile

1. **Baixo Número de Draw Calls (Batching):**
   - Os materiais compartilham parâmetros padronizados de sombreamento.
   - Os tufos de vegetação utilizam malhas simples de prismas e caixas, mantendo a contagem total de polígonos da cena abaixo de 30.000 triângulos.
2. **Sombra Direcional Ortogonal e Seletiva:**
   - A `DirectionalLight3D` utiliza `directional_shadow_mode = SHADOW_ORTHOGONAL` (1 única cascata em vez de 4 splits PSSM), `directional_shadow_max_distance = 28.0`, mapa `1024x1024` e `soft_shadow_filter_quality = 0`.
   - As malhas de vegetação operam com `cast_shadow = SHADOW_CASTING_SETTING_OFF` (mantendo sombras nítidas no robô, rochas e falésias da ilha), reduzindo as primitivas de 654k para 159k e os draw calls de 2.077 para 815 na Fase 20.
3. **Pool Compartilhado de Partículas e Shader sem Inverse Matrix:**
   - Um pool estático de 16 `CPUParticles3D` em `plant.gd` atende a todos os cortes da fase sem instanciar emissores ociosos por tufo.
   - O `interactive_grass.gdshader` projeta vetores de mundo usando as colunas XZ da `MODEL_MATRIX` (sem `inverse()` por vértice) e aplica *early-out* por distância ao quadrado (`dist_sq < r_sq`).

---

## 4. Permissões Android e Feedback Háptico

- **Permissão VIBRATE Obrigatória:** No arquivo `export_presets.cfg`, a chave `permissions/vibrate` deve estar configurada como `true`. Sem isso, o sistema operacional Android bloqueia o acesso ao serviço de vibração em nível de sistema operacional (`SecurityException`), desativando silenciosamente qualquer chamada a `Input.vibrate_handheld()`.
- **Calibração de Motores (ERM/LRA):** Pulsos hápticos devem respeitar um tempo mínimo de aceleração de inércia ($\ge 30\text{ms}$) e incluir rate-limiting de $\ge 35\text{ms}$ para evitar o cancelamento contínuo da API do Android em ceifadas consecutivas.
