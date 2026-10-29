# Central de Guardrails e Roteador de Diretrizes: Grass Cut Bot (Godot 4) 🌿🤖

Este documento é a **Central de Guardrails Invariantes e Roteador Mestre** do projeto **Grass Cut Bot**. Ele estabelece as regras invioláveis de alta prioridade e direciona o assistente de IA para a documentação técnica canônica correspondente dentro da pasta `docs/`.

---

## ⚡ Os 13 Mandamentos Invariantes (Guardrails Críticos)

1. **Zero Warnings Estrito:** O console da Godot deve permanecer com 0 warnings a cada execução. Não permita divisões inteiras diretas, variáveis com nomes de métodos/propriedades da engine ou identificadores sombreados.
2. **Terminal PowerShell, UTF-8 sem BOM & Git no OneDrive:** Utilize exclusivamente ponto e vírgula `;` para encadear comandos no Windows PowerShell. Ao gravar/ler arquivos via script/terminal, force `-Encoding UTF8` (sem BOM). Em referências a nós Godot (`$Node`), utilize sempre aspas simples (`@' ... '@`) para impedir que o PowerShell interprete como variável. Ao executar comandos que gravam no índice do Git (`git add`, `git commit`) em diretórios do OneDrive, utilize `BypassSandbox: true` para evitar erros de permissão em `.git/index.lock`.
3. **Resolução e Orientação Mobile Portrait:** A janela base é configurada em `720x1280` (proporção 9:16 vertical), `window/stretch/mode="canvas_items"` e `window/stretch/aspect="keep_width"`. Todos os componentes de HUD devem respeitar a zona segura de celulares modernos.
4. **Camadas de Física 3D Padronizadas:**
   - `Layer 1`: Terreno e Paredes Limítrofes (`collision_layer = 1`)
   - `Layer 2`: Cortador (Serra Circular) (`collision_layer = 2`, `collision_mask = 1 | 8`)
   - `Layer 3`: Vegetação (`collision_layer = 4`, `collision_mask = 0`)
   - `Layer 4`: Obstáculos Sólidos/Rochas (`collision_layer = 8`, `collision_mask = 0`)
5. **Corte Radial por Contato & Desacoplamento:** O corte da serra ocorre exclusivamente por contato radial omnidirecional (`Area3D` do cortador com raio dinâmico via `UpgradeManager`). A lâmina nunca depende de frente ou ré fixa.
6. **Controles Touch de Uma Mão (One-Thumb):** O joystick flutuante deve operar com âncora restrita à metade inferior da tela, garantindo zona morta central para microtoques e suporte a mouse/teclado para desenvolvimento rápido no PC.
7. **Estilo Low Poly Fosco & Performance Mobile:** Materiais 3D utilizam `roughness = 0.85 ~ 0.95` (acabamento fosco/matte sem reflexos especulares plásticos excessivos) e cores sólidas vibrantes. Malhas leves e partículas limpas para garantir 60 FPS estáveis em qualquer aparelho Android.
8. **Feedback Háptico e Sensorial Contínuo (Game Feel):** Cada corte deve disparar feedback háptico sutil (`Input.vibrate_handheld(15)`) e emissão de partículas em arco parabólico. Choques com obstáculos exigem interrupção de inércia, recuo (knockback), faíscas e impacto seco.
9. **UI com Process Mode Always nos Modais:** O nó raiz do HUD e seus modais de pausa/vitória devem rodar com `process_mode = PROCESS_MODE_ALWAYS` (Node 3) para permitir interação contínua mesmo quando `get_tree().paused = true`.
10. **Tipagem Estrita e GDScript 4 Defensivo:** Sempre utilize tipagem estática nos scripts (`var x: int`, `func foo() -> void:`). Nunca acesse dicionários internos sem verificação prévia ou métodos garantidores.
11. **Protocolo Perpétuo de Changelog:** Toda melhoria concluída deve ter seu plano e relatório salvos em `docs/historico_melhorias/<nome_da_melhoria>.md` e indexada no `docs/historico_melhorias/INDICE_MELHORIAS.md`.
12. **Pipeline 3D Blender -> Godot (Export glTF & Orientação Canônica):** Ao exportar modelos 3D do Blender para Godot (`.glb`), force sempre `export_apply=True` e `export_yup=True`. Se o modelo contiver modificadores `Mirror` ou deformadores simétricos, o export sem apply descarta a metade espelhada. Ao ajustar pivôs anatômicos em peças espelhadas, mantenha o centro de simetria no eixo ($X=0$) ou compense os vértices no sentido oposto (`v.co -= offset`) para não deslocar a geometria de mundo.
   - **Orientação Canônica de Tiles 3D:** Em `rot = 0`, a face externa/falésia (mar) deve sempre apontar para o Norte ($-Z$ no Godot, correspondendo a $-Y$ no Blender com `export_yup=True`), enquanto a face interna plana de grama (conexão com vizinhos) conecta em $+Z$ (Sul no Godot, $+Y$ no Blender).
   - **Reimportação Atômica de Cache:** Após exportar novos arquivos `.glb`, execute obrigatoriamente `godot --headless --import` no terminal para que o compilador da Godot regenere os recursos binários `.scn` em `.godot/imported/` antes de testar ou rodar o jogo.
13. **Imunidade de Materiais em glTF & MultiMesh (Zero Overrides em .scn):** O exportador binário da Godot 4 descarta silenciosamente `surface_material_override` em nós filhos herdados de modelos `.glb` ao compilar para `.scn` no APK. Para qualquer malha combinada (`MultiMeshInstance3D` ou `SurfaceTool`), NUNCA dependa de overrides declarados no arquivo `.tscn`. Sempre injete os materiais canônicos programaticamente em GDScript a partir de dicionários pré-carregados (ex: `FLOWER_MATERIALS`, `GRASS_MATERIALS`). Além disso, ao exportar modelos no Blender, garanta que os materiais base utilizem albedo neutro/branco como defesa em profundidade.

---

## 🧭 Matriz Roteadora de Diretrizes por Domínio

Antes de planejar ou executar alterações em qualquer subsistema, o agente DEVE consultar o documento canônico correspondente na pasta `docs/`:

| Domínio de Trabalho | Documento Canônico de Referência | Foco das Diretrizes Detalhadas |
| :--- | :--- | :--- |
| **📜 Visão Geral & GDD** | [`docs/01_visao_geral_e_gdd/GDD_OFICIAL.md`](docs/01_visao_geral_e_gdd/GDD_OFICIAL.md) | Documento Vivo de Design, regras de vitória/derrota, USP e escopo dos níveis. |
| **🎨 Direção de Arte & Visual** | [`docs/01_visao_geral_e_gdd/DIRECAO_DE_ARTE_E_VISUAL.md`](docs/01_visao_geral_e_gdd/DIRECAO_DE_ARTE_E_VISUAL.md) | Cores sólidas, estilo Low Poly fosco, iluminação acolhedora e partículas em arco. |
| **🪚 O Cortador & Lâmina** | [`docs/02_entidades_e_mecanicas/SISTEMA_DO_CORTADOR.md`](docs/02_entidades_e_mecanicas/SISTEMA_DO_CORTADOR.md) | Rotação contínua da serra, movimentação omnidirecional, choque/ricochete e upgrades de raio/potência. |
| **🌾 Vegetação & Colheita** | [`docs/02_entidades_e_mecanicas/SISTEMA_DE_VEGETACAO.md`](docs/02_entidades_e_mecanicas/SISTEMA_DE_VEGETACAO.md) | Tufos de grama, trigo e flores, contagem decrescente, resistência de cortes e recompensas em moedas. |
| **🪨 Obstáculos & Ilha** | [`docs/02_entidades_e_mecanicas/SISTEMA_DE_OBSTACULOS_E_TERRENO.md`](docs/02_entidades_e_mecanicas/SISTEMA_DE_OBSTACULOS_E_TERRENO.md) | Ilhas 3D sobre o oceano sem cercas, contenção costeira invisível, rochas com colisão sólida e física de choque. |
| **🗺️ Level Design & Editor** | [`docs/03_level_design_e_fases/ESTRUTURA_DAS_FASES.md`](docs/03_level_design_e_fases/ESTRUTURA_DAS_FASES.md)<br>[`docs/03_level_design_e_fases/SISTEMA_EDITOR_DE_FASES.md`](docs/03_level_design_e_fases/SISTEMA_EDITOR_DE_FASES.md) | Editor de Fases PC Fullscreen, Ilhas 3D com Auto-Tile, carimbos de formas, persistência JSON e progressão de níveis. |
| **🕹️ Controles Touch (Joystick)** | [`docs/04_sistemas_e_gameplay/SISTEMA_DE_CONTROLES_TOUCH.md`](docs/04_sistemas_e_gameplay/SISTEMA_DE_CONTROLES_TOUCH.md) | Joystick flutuante na metade inferior da tela, deadzone, fallback para mouse e teclado no PC. |
| **📊 Interface & HUD** | [`docs/04_sistemas_e_gameplay/SISTEMA_DE_INTERFACE_HUD.md`](docs/04_sistemas_e_gameplay/SISTEMA_DE_INTERFACE_HUD.md) | Top HUD com anel circular de cronômetro, metas em tempo real com pop, modais de pausa/vitória/derrota. |
| **🪙 Economia & Oficina** | [`docs/04_sistemas_e_gameplay/ECONOMIA_E_OFICINA.md`](docs/04_sistemas_e_gameplay/ECONOMIA_E_OFICINA.md) | Moedas verdes, upgrades da lâmina, potência, velocidade e multiplicador econômico. |
| **✨ Game Feel & Haptics** | [`docs/04_sistemas_e_gameplay/GAME_FEEL_E_HAPTICS.md`](docs/04_sistemas_e_gameplay/GAME_FEEL_E_HAPTICS.md) | Sensação mecânica "satisfying", haptics curto contínuo, impacto seco, câmera isométrica com amortecimento e shake. |
| **🎵 Áudio & Sonoplastia** | [`docs/04_sistemas_e_gameplay/SISTEMA_DE_AUDIO_E_SFX.md`](docs/04_sistemas_e_gameplay/SISTEMA_DE_AUDIO_E_SFX.md) | Barramentos Master/Music/SFX, trilha menu vs gameplay, motor contínuo, corte radial sonoro, pingo de moedas e pooling polifônico. |
| **🏗️ Arquitetura & GDScript** | [`docs/05_arquitetura_e_desenvolvimento/ARQUITETURA_DO_PROJETO.md`](docs/05_arquitetura_e_desenvolvimento/ARQUITETURA_DO_PROJETO.md)<br>[`docs/05_arquitetura_e_desenvolvimento/PADRAO_DE_SCRIPTS.md`](docs/05_arquitetura_e_desenvolvimento/PADRAO_DE_SCRIPTS.md) | Organização de diretórios, regras estritas de tipagem GDScript 4, Zero Warnings e Autoloads. |
| **⚡ Performance & Otimização** | [`docs/05_arquitetura_e_desenvolvimento/PLANO_MESTRE_DE_PERFORMANCE.md`](docs/05_arquitetura_e_desenvolvimento/PLANO_MESTRE_DE_PERFORMANCE.md) | Diretrizes e roadmap de 60 FPS mobile: cache de nós, uniforms globais, culling de sombras, água sem depth texture e FSR. |
| **💾 Save & Persistência** | [`docs/05_arquitetura_e_desenvolvimento/SISTEMA_DE_SAVE.md`](docs/05_arquitetura_e_desenvolvimento/SISTEMA_DE_SAVE.md) | Persistência atômica, backup anti-corrupção, avaliação de 1 a 3 estrelas (⭐), auto-save e reset de progresso. |
| **🏷️ Versionamento & SemVer** | [`docs/05_arquitetura_e_desenvolvimento/SISTEMA_DE_VERSIONAMENTO.md`](docs/05_arquitetura_e_desenvolvimento/SISTEMA_DE_VERSIONAMENTO.md) | Game SemVer (`v0.12.32-alpha`), ciclo de maturidade (Pre-Alpha -> Alpha -> Beta -> 1.0), classe GameVersion e automação com bump_version. |
| **📱 Portabilidade Android & Web** | [`docs/05_arquitetura_e_desenvolvimento/PORTABILIDADE_ANDROID.md`](docs/05_arquitetura_e_desenvolvimento/PORTABILIDADE_ANDROID.md)<br>[`docs/05_arquitetura_e_desenvolvimento/PORTABILIDADE_WEB.md`](docs/05_arquitetura_e_desenvolvimento/PORTABILIDADE_WEB.md) | Configurações de exportação Android APK/AAB e Web HTML5/Wasm, compatibilidade de renderizador e performance. |
| **💻 Diretrizes & Git** | [`docs/05_arquitetura_e_desenvolvimento/DIRETRIZES_DE_DESENVOLVIMENTO.md`](docs/05_arquitetura_e_desenvolvimento/DIRETRIZES_DE_DESENVOLVIMENTO.md) | PowerShell no Windows, UTF-8 sem BOM, SemVer e checkpoints contínuos no Git. |

---

## 🔄 Protocolo Operacional Contínuo do Agente

1. **Consulta Prévia Obrigatória:** Sempre leia o documento canônico relevante em `docs/` antes de propor ou executar planos.
2. **Preservação de Documentação:** Mantenha a wiki 100% atualizada a cada modificação na base de código.
3. **Protocolo Perpétuo de Changelog:** Toda melhoria concluída deve consolidar o plano e a entrega em `docs/historico_melhorias/<nome_da_melhoria>.md`.
4. **Ciclo Game SemVer:** Incremente a versão do projeto em `project.godot` e registre o novo bloco no changelog histórico.
5. **Checkpoints e Sincronização Obrigatória no GitHub:** Valide a integridade do código (0 warnings / sem erros), realize commits semânticos a cada etapa concluída e execute obrigatoriamente `git push origin main` a cada nova versão atualizada (SemVer bump / término de melhoria), mantendo o repositório remoto (`https://github.com/rogerbif/grass-cut-bot.git`) 100% atualizado e sincronizado.
