# Central de Guardrails e Roteador de Diretrizes: Grass Cut Bot (Godot 4) 🌿🤖

Central de guardrails invariantes, roteamento para `docs/` e economia de tokens do projeto **Grass Cut Bot**.

---

## ⚡ Os 18 Mandamentos Invariantes (Guardrails Críticos)

1. **Zero Warnings Estrito:** Console da Godot com 0 warnings; evite divisões inteiras diretas, nomes reservados da engine e variáveis sombreadas.
2. **PowerShell, UTF-8 sem BOM & Git no OneDrive:** Use `;` no PowerShell, `-Encoding UTF8` ao gravar arquivos, `@' ... '@` em referências `$Node`, e `BypassSandbox: true` em comandos Git que escrevem em `.git/index.lock` (`git add`, `git commit`).
3. **Resolução Mobile Portrait:** Base `720x1280` (9:16), `canvas_items` + `keep_width`, respeitando safe zones nos componentes de HUD.
4. **Camadas de Física 3D:** `Layer 1` Terreno/Limites (`layer=1`), `Layer 2` Cortador (`layer=2`, `mask=1|8`), `Layer 3` Vegetação (`layer=4`, `mask=0`), `Layer 4` Obstáculos (`layer=8`, `mask=0`).
5. **Corte Radial Omnidirecional:** Corte exclusivo por contato radial (`Area3D` com raio dinâmico via `UpgradeManager`), sem depender de frente/ré fixa.
6. **Controles One-Thumb:** Joystick flutuante ancorado na metade inferior da tela com deadzone central e fallback mouse/teclado no PC.
7. **Estilo Low Poly Fosco & 60 FPS:** Materiais com `roughness = 0.85 ~ 0.95`, cores sólidas vibrantes e malhas/partículas leves para 60 FPS estáveis no Android.
8. **Game Feel & Haptics:** Cortes disparam `Input.vibrate_handheld(15)` e partículas em arco; choques com rochas geram recuo (knockback), faíscas e impacto seco.
9. **Modais com Process Mode Always:** HUD raiz e modais de pausa/vitória/derrota usam `process_mode = PROCESS_MODE_ALWAYS` (Node 3) com `get_tree().paused = true`.
10. **Tipagem Estrita & GDScript Defensivo:** Tipagem estática obrigatória (`var x: int`, `func foo() -> void:`) e acesso seguro a dicionários.
11. **Protocolo Perpétuo de Changelog:** Registrar toda melhoria em `docs/historico_melhorias/<nome>.md` e indexar em `docs/historico_melhorias/INDICE_MELHORIAS.md`.
12. **Pipeline 3D Blender -> Godot:** Exportar `.glb` com `export_apply=True` e `export_yup=True` (pivô em $X=0$ para peças simétricas); em `rot=0`, falésia aponta para Norte ($-Z$) e conexão interna para Sul ($+Z$); rodar `godot --headless --import` após novos `.glb`.
13. **Imunidade de Materiais em glTF/MultiMesh:** Nunca dependa de `surface_material_override` em `.tscn` para `.glb` (descartado ao compilar `.scn`); injete materiais em GDScript (`FLOWER_MATERIALS`, `GRASS_MATERIALS`) com albedo base neutro no Blender.
14. **Botânica 100% Individual:** Nunca unifique espécies em chaves genéricas (`"grass"`, `"flower"`). Declare cada variedade explicitamente (`grass_green`, `grass_yellow`, `grass_blue`, `grass_purple`, `grass_red`, `grass_white`, `grass_black`, etc.).
15. **Imutabilidade de Metas Concluídas:** Ao zerar (`remaining <= 0`), o card entra em `is_completed = true` (`"OK"`, `Color(0.22, 1.0, 0.48)`, `badge_goal_done_bg.svg`) e nunca volta a exibir números em cortes excedentes.
16. **Acesso Defensivo a Autoloads:** Em entidades e scripts CLI (`--script`), use `get_node_or_null("/root/<Autoload>")` com checagem de método em vez de globais não qualificados.
17. **Confirmação Prévia em Geradores de Fases:** Pergunte e obtenha autorização expressa do usuário (informando quais fases e o impacto) antes de rodar qualquer rotina procedural que crie/sobrescreva `data/levels/level_*.json`.
18. **Publicação Unificada (Google Play + itch.io):** Releases via `publish.ps1` ou `/publicar-versao` atualizam simultaneamente Android AAB (`targetSdk >= 36`, `minSdk = 24`, segredos fora do Git, locks Gradle contornados) e Web HTML5 (`bifgames/grass-cut-bot:html5` via Butler CLI), exibindo release notes em `<pt-BR>` e `<en-US>` (detalhes na skill `publicar-versao`).

---

## 🧭 Matriz Roteadora de Diretrizes por Domínio

Consulte o documento canônico correspondente em `docs/` antes de planejar ou alterar qualquer subsistema:

| Domínio de Trabalho | Documento Canônico de Referência | Foco |
| :--- | :--- | :--- |
| **🗺️ Mapa de Símbolos (CodeGraph Godot)** | [`docs/05_arquitetura_e_desenvolvimento/MAPA_DE_SIMBOLOS.md`](docs/05_arquitetura_e_desenvolvimento/MAPA_DE_SIMBOLOS.md) | Índice de `.gd` (funções, sinais, linhas) e `.tscn`; consultar via `--query` antes de ler arquivos inteiros. |
| **📜 Visão Geral & GDD** | [`docs/01_visao_geral_e_gdd/GDD_OFICIAL.md`](docs/01_visao_geral_e_gdd/GDD_OFICIAL.md) | Regras de vitória/derrota, USP e escopo dos níveis. |
| **🎨 Direção de Arte & Visual** | [`docs/01_visao_geral_e_gdd/DIRECAO_DE_ARTE_E_VISUAL.md`](docs/01_visao_geral_e_gdd/DIRECAO_DE_ARTE_E_VISUAL.md) | Cores sólidas, Low Poly fosco, iluminação e partículas. |
| **🪚 O Cortador & Lâmina** | [`docs/02_entidades_e_mecanicas/SISTEMA_DO_CORTADOR.md`](docs/02_entidades_e_mecanicas/SISTEMA_DO_CORTADOR.md) | Rotação, movimentação omnidirecional, choque/ricochete e upgrades. |
| **🌾 Vegetação & Colheita** | [`docs/02_entidades_e_mecanicas/SISTEMA_DE_VEGETACAO.md`](docs/02_entidades_e_mecanicas/SISTEMA_DE_VEGETACAO.md) | Grama, trigo e flores, resistência de hits e recompensas. |
| **🪨 Obstáculos & Ilha** | [`docs/02_entidades_e_mecanicas/SISTEMA_DE_OBSTACULOS_E_TERRENO.md`](docs/02_entidades_e_mecanicas/SISTEMA_DE_OBSTACULOS_E_TERRENO.md) | Ilhas 3D sobre o oceano, contenção costeira e rochas. |
| **🗺️ Level Design & Editor** | [`docs/03_level_design_e_fases/ESTRUTURA_DAS_FASES.md`](docs/03_level_design_e_fases/ESTRUTURA_DAS_FASES.md)<br>[`docs/03_level_design_e_fases/SISTEMA_EDITOR_DE_FASES.md`](docs/03_level_design_e_fases/SISTEMA_EDITOR_DE_FASES.md) | Editor PC, Ilhas 3D, carimbos, JSON e progressão. |
| **🕹️ Controles Touch** | [`docs/04_sistemas_e_gameplay/SISTEMA_DE_CONTROLES_TOUCH.md`](docs/04_sistemas_e_gameplay/SISTEMA_DE_CONTROLES_TOUCH.md) | Joystick flutuante, deadzone e fallback PC. |
| **📊 Interface & HUD** | [`docs/04_sistemas_e_gameplay/SISTEMA_DE_INTERFACE_HUD.md`](docs/04_sistemas_e_gameplay/SISTEMA_DE_INTERFACE_HUD.md) | Top HUD, anel de cronômetro, metas e modais. |
| **🪙 Economia & Oficina** | [`docs/04_sistemas_e_gameplay/ECONOMIA_E_OFICINA.md`](docs/04_sistemas_e_gameplay/ECONOMIA_E_OFICINA.md) | Moedas, upgrades de lâmina, potência, velocidade e multiplicador. |
| **✨ Game Feel & Haptics** | [`docs/04_sistemas_e_gameplay/GAME_FEEL_E_HAPTICS.md`](docs/04_sistemas_e_gameplay/GAME_FEEL_E_HAPTICS.md) | Haptics, impacto seco, câmera isométrica e shake. |
| **🎵 Áudio & Sonoplastia** | [`docs/04_sistemas_e_gameplay/SISTEMA_DE_AUDIO_E_SFX.md`](docs/04_sistemas_e_gameplay/SISTEMA_DE_AUDIO_E_SFX.md) | Barramentos, trilhas, motor contínuo, SFX e pooling. |
| **🏗️ Arquitetura & GDScript** | [`docs/05_arquitetura_e_desenvolvimento/ARQUITETURA_DO_PROJETO.md`](docs/05_arquitetura_e_desenvolvimento/ARQUITETURA_DO_PROJETO.md)<br>[`docs/05_arquitetura_e_desenvolvimento/PADRAO_DE_SCRIPTS.md`](docs/05_arquitetura_e_desenvolvimento/PADRAO_DE_SCRIPTS.md) | Diretórios, tipagem estrita, Zero Warnings e Autoloads. |
| **⚡ Performance & Otimização** | [`docs/05_arquitetura_e_desenvolvimento/PLANO_MESTRE_DE_PERFORMANCE.md`](docs/05_arquitetura_e_desenvolvimento/PLANO_MESTRE_DE_PERFORMANCE.md) | Cache de nós, uniforms globais, culling, água mobile e FSR. |
| **💾 Save & Persistência** | [`docs/05_arquitetura_e_desenvolvimento/SISTEMA_DE_SAVE.md`](docs/05_arquitetura_e_desenvolvimento/SISTEMA_DE_SAVE.md) | Escrita atômica, backup `.bak`, estrelas e auto-save. |
| **🏷️ Versionamento & SemVer** | [`docs/05_arquitetura_e_desenvolvimento/SISTEMA_DE_VERSIONAMENTO.md`](docs/05_arquitetura_e_desenvolvimento/SISTEMA_DE_VERSIONAMENTO.md) | Game SemVer, `GameVersion` e `bump_version`. |
| **📱 Android & Web** | [`docs/05_arquitetura_e_desenvolvimento/PORTABILIDADE_ANDROID.md`](docs/05_arquitetura_e_desenvolvimento/PORTABILIDADE_ANDROID.md)<br>[`docs/05_arquitetura_e_desenvolvimento/PORTABILIDADE_WEB.md`](docs/05_arquitetura_e_desenvolvimento/PORTABILIDADE_WEB.md) | Exportação Android APK/AAB e Web HTML5/Wasm. |
| **💻 Diretrizes & Git** | [`docs/05_arquitetura_e_desenvolvimento/DIRETRIZES_DE_DESENVOLVIMENTO.md`](docs/05_arquitetura_e_desenvolvimento/DIRETRIZES_DE_DESENVOLVIMENTO.md) | PowerShell, UTF-8 sem BOM, SemVer e Git. |

---

## 🔄 Protocolo Operacional Contínuo do Agente

1. **Economia de Contexto (Grafo Godot & Subagente `research`):**
   - Antes de abrir arquivos `.gd` inteiros ou fazer buscas amplas, consulte [`docs/05_arquitetura_e_desenvolvimento/MAPA_DE_SIMBOLOS.md`](docs/05_arquitetura_e_desenvolvimento/MAPA_DE_SIMBOLOS.md) ou execute `python tools/build_gd_graph.py --query <termo>` e leia apenas o intervalo exato (`StartLine`/`EndLine`).
   - Delegue investigações multi-arquivo (3+ arquivos ou varreduras exploratórias) ao subagente `research` (`invoke_subagent`) para receber apenas um resumo enxuto na conversa principal.
2. **Consulta Prévia & Documentação:** Leia o doc canônico relevante em `docs/` antes de editar e atualize a wiki (incluindo `python tools/build_gd_graph.py` via skill `atualizar-documentacao`) ao finalizar.
3. **Changelog & SemVer:** Consolide o relatório em `docs/historico_melhorias/<nome>.md`, indexe no `INDICE_MELHORIAS.md` e incremente a versão em `project.godot`, `export_presets.cfg` e `scripts/core/game_version.gd`.
4. **Git & Sincronização:** Valide 0 warnings, faça commits semânticos e execute `git push origin main` (`BypassSandbox: true` no OneDrive) a cada entrega.
