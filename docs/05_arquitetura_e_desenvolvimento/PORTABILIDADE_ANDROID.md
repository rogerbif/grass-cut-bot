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

---

## 5. Especificação de Adaptive Icons (Android 8.0+)

- **Safe Zone Canônica (72dp / ~67%):** Em dispositivos Android modernos (MIUI/HyperOS, OneUI, Pixel), o launcher aplica máscaras de recorte adaptativas (squircle, círculo ou quadrado arredondado) sobre a tela de 108dp (432x432 px).
- **Enquadramento Sem Cortes:** Toda a arte crítica (logo "GRASS CUT BOT", Cutter Bit, lâminas e ilha) deve estar estritamente contida dentro da zona segura central de 288x288 px (escala de ~67% centralizada).
- **Camadas Separadas e Sincronizadas:**
  - `launcher_icons/adaptive_foreground_432x432="res://assets/brand/icon_432.png"`: Contém o emblema centrado na Safe Zone sobre o fundo de céu estendido.
  - `launcher_icons/adaptive_background_432x432="res://assets/brand/icon_adaptive_background_432.png"`: Contém o gradiente de céu tropical (#6EE6FD -> #1E98D0) preenchendo todos os 432x432 px.
  - `launcher_icons/main_192x192="res://assets/brand/icon_192.png"`: Formato legado para versões anteriores ao Android 8.0.

---

## 6. Serialização Binária de Cenas e Imunidade de Materiais (.scn vs .tscn)

- **Descarte de Overrides em Modelos Importados:** No Godot 4, ao compilar cenas `.tscn` para `.scn` no APK Android, propriedades `surface_material_override` atribuídas a nós filhos de cenas 3D instanciadas (`.glb`) são descartadas silenciosamente pelo exportador binário.
- **Injeção Programática Obrigatória:** Todo pipeline que combina malhas para `MultiMeshInstance3D` (como em `VegetationGrid` e `IslandNode`) deve injetar os materiais explicitamente em código via `SurfaceTool.set_material(mat)` utilizando constantes pré-carregadas (`FLOWER_MATERIALS`, `GRASS_MATERIALS`), garantindo independência total da serialização da cena.
- **Defesa em Profundidade 3D:** Modelos 3D gerados no Blender devem manter albedo neutro em seus materiais base para evitar que qualquer fallback inesperado de renderização exiba cores indesejadas em dispositivos móveis.

---

## 7. Gestão de Ciclo de Vida e Auto-Pausa (Google Play Core App Quality)

- **Proteção Contra Perda de Foco:** Ao receber chamadas telefônicas, alternar para outros apps ou pressionar o botão Home, o sistema operacional Android envia as notificações `NOTIFICATION_APPLICATION_PAUSED` e `NOTIFICATION_APPLICATION_FOCUS_OUT`.
- **Auto-Pausa no `GameManager`:** Se uma fase estiver ativa (`current_state == GameState.PLAYING`), o jogo pausa imediatamente (`get_tree().paused = true`), impedindo que o cronômetro continue correndo ou cause derrota injusta em segundo plano.
- **Persistência Atômica:** O `SaveManager` escuta essas mesmas notificações para descarregar o progresso do jogador em disco imediatamente antes que o processo possa ser suspenso ou finalizado pelo SO.

---

## 8. Hierarquia do Botão Voltar e Safe Area Dinâmica

- **Navegação com Botão/Gesto Voltar (`NOTIFICATION_WM_GO_BACK_REQUEST`):**
  - **No Gameplay (`hud.gd`):**
    1. Se a oficina estiver aberta: fecha a oficina.
    2. Se o modal de pausa estiver aberto: fecha a pausa e retoma a partida.
    3. Se em vitória/derrota: retorna ao menu principal.
    4. Se jogando: abre o modal de pausa.
  - **No Menu Principal (`main_menu.gd`):**
    1. Se o modal de configurações estiver aberto: fecha o modal.
    2. Se a câmera estiver no modo mapa/arquipélago: retorna à visão focada no robô.
    3. Se estiver em aba secundária (Garagem, Coleção, Loja): retorna à aba Home (índice 0).
    4. Se o modal de saída estiver aberto: fecha o modal (cancela a saída).
    5. Se já estiver na tela inicial padrão: exibe o modal de confirmação de saída (`ExitModal`) perguntando se o usuário deseja fechar o app ou continuar jogando. Se confirmado, salva o progresso e encerra limpo (`get_tree().quit()`).
- **Safe Area Dinâmica (Notches & Cutouts):**
  - O método `_apply_safe_area()` consulta `DisplayServer.get_display_safe_area()` e compensa dinamicamente a margem superior (`content_margin_top`) do `TopBar` no HUD e no Menu Principal, impedindo sobreposição em aparelhos com entalhes de câmera profundos.

---

## 9. Compilação do Android App Bundle (.aab) e Keystore de Lançamento

- **Script de Automação:** Executado via `scripts/tools/build_android_aab.ps1`.
- **Keystore de Assinatura:**
  - Armazenado na raiz do projeto como `upload-keystore.jks` (alias `grasscutbot`), protegido no `.gitignore`.
  - Injetado em tempo de execução através das variáveis de ambiente:
    - `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`
    - `GODOT_ANDROID_KEYSTORE_RELEASE_USER`
    - `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`
- **Requisitos de SDK:**
  - `targetSdkVersion = 36` (Android 16 obrigatório no Google Play Console a partir de 2026/2027) com supressão `android.suppressUnsupportedCompileSdk=36` em `gradle.properties`.
  - `minSdkVersion = 24` (Android 7.0 Nougat, padrão nativo do Godot 4).
- **Prevenção de Locks e Resíduos Gradle no Windows/OneDrive:**
  - As tarefas `:clean` de todos os subprojetos são neutralizadas em `android/build/build.gradle` (`tasks.matching { it.name == 'clean' }.all { enabled = false }`) para impedir exceções de `IOException: Unable to delete directory`.
  - Limpeza forçada nativa em PowerShell com `cmd.exe /c rmdir /s /q` sobre diretórios `build` e `android/build/src/main/assets` antes da compilação para evitar duplicidade de assets entre módulos `base` e `assetPackInstallTime`.

---

## 10. Pipeline de Publicação Automatizada via Google Play Developer API

- **Infraestrutura Google Cloud & API:**
  - API habilitada: `androidpublisher.googleapis.com`.
  - Conta de Serviço: `play-store-uploader@play-store-uploader-514021.iam.gserviceaccount.com`.
  - Credencial privada: `play_service_account.json` na raiz do projeto (estritamente ignorada no `.gitignore`).
- **Script Uploader CLI (`scripts/tools/play_store_uploader/upload.js`):**
  - Autentica via JWT com a biblioteca oficial `googleapis`.
  - Abre sessão de edição atômica em `com.bifgames.grasscutbot`.
  - Envia o bundle `.aab` por streaming, recebe o `versionCode` processado, associa à faixa especificada (`internal`, `alpha`, etc.), anexa as release notes multilíngues e comita as alterações.
- **Integração Ponta a Ponta com 1 Comando:**
  ```powershell
  # Compila o AAB e publica diretamente no Teste Interno:
  .\scripts\tools\build_android_aab.ps1 -Publish

  # Compila e publica no Teste Fechado (Alpha):
  .\scripts\tools\build_android_aab.ps1 -Publish -Track alpha
  ```

---

## 11. Padrão Mandatório de Release Notes Bilíngues

Sempre que um novo build `.aab` for gerado ou publicado, as notas da versão devem ser estruturadas obrigatoriamente nas tags correspondentes:

```html
<pt-BR>
Novidades da versão:
• Descrição sucinta das melhorias e novidades para o público brasileiro.
</pt-BR>
<en-US>
What's new in this version:
• Concise description of improvements and new features for global players.
</en-US>
```

