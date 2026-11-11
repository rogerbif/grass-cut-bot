# Melhoria 239: Pacote de Performance Mobile (Áudio Throttle, Shaders Mobile ALU e Battery Saver) ⚡📱

**Data:** 11 de Novembro de 2026  
**Versão:** `v0.12.193-alpha` (Build Code: 1393)  
**Status:** ✅ Concluído e Auditado  
**Tipo:** Otimização de Performance / Mobile / Shaders / Áudio / Engine  

---

## 🎯 1. Contexto e Motivação

Com as fundações gráficas e de física já consolidadas (SurfaceTool em 1 draw call, CSR Spatial Indexing, MultiMeshes e Ocean Shader desacoplado de depth texture), identificamos oportunidades cirúrgicas de otimização de baixo esforço e alto impacto no hardware mobile:
1. **Picos na thread de áudio:** Quando lâminas de alta rotação ceifam dezenas de plantas ou colidem com rochas sob inércia, chamadas repetidas e simultâneas ao mixer sobrecarregavam a CPU de áudio e podiam gerar micro-pops por interrupção forçada de canais ativos.
2. **Carga de ALU em fragment shaders:** O shader de grama calculava divisões, clamps e potências (`shadow_ratio`) para cada fragmento na função `light()`, apesar de depender unicamente de parâmetros uniformes estáticos. O shader de água realizava conversões transcendentais caras (`pow 2.4`) em ruídos escalares.
3. **Desperdício de energia e aquecimento ocioso:** O jogo continuava renderizando em alta taxa de quadros (60 a 120 FPS) mesmo durante telas de pausa ou quando minimizado pelo usuário no Android.

---

## 🛠️ 2. Alterações Implementadas

### A. Limitador de Vazão de SFX & Busca por Canais Ociosos (`AudioManager`)
- **Tabela Declarativa de Cooldowns:** Adicionado mapa `SFX_COOLDOWNS` controlando a frequência máxima de reprodução de efeitos sonoros críticos:
  - `slap_rock`: Cooldown de 110ms (evita dezenas de estalos em colisões raspadas).
  - `coin_pickup`: Cooldown de 35ms.
  - `star_pop`: Cooldown de 50ms.
  - `buy`: Cooldown de 80ms.
  - `water_splash`: Cooldown de 100ms.
- **Calibração do Corte:** Redução do cooldown de `play_cut_sfx` de 40ms para 32ms (~30 Hz), garantindo áudio perfeitamente responsivo e contínuo sem engasgos.
- **Polidez do Pool Polifônico (`_get_next_sfx_player`):** O seletor agora prioriza players ociosos (`not p.playing`), eliminando o corte brusco de ondas sonoras em reprodução (*zero micro-clicks*).

### B. Otimização de ALU e Fill-Rate nos Shaders Mobile
- **`shaders/interactive_grass.gdshader`:**
  - O cálculo da proporção cromática de sombra (`v_shadow_ratio`) foi migrado para o `vertex()`, transmitido aos fragmentos via `varying vec3 v_shadow_ratio;`.
  - Eliminadas divisões, `max`, `clamp` e `pow` da função `light()` para cada pixel da vegetação.
  - Eliminada re-normalização redundante de normais que já vinham unitárias do estágio de vértice.
- **`shaders/toon_water.gdshader`:**
  - Texturas de ruído (`surfaceNoise` e `distortNoise`) atualizadas de `source_color` para `hint_default_black`, eliminando o overhead de decodificação sRGB na GPU.
  - Removida a função `_srgb_to_linear_1` e substituída a aproximação de curva por quadratura direta (`x * x`) no perfil compatibilidade.

### C. Gerenciamento de Bateria & Throttling Ocioso (`GameManager`)
- **Constantes de Framerate:**
  - `FPS_PLAYING = 60`: Taxa fluida padrão durante a gameplay.
  - `FPS_PAUSED = 30`: Redução de 50% na carga de GPU enquanto o jogo está pausado.
  - `FPS_BACKGROUND = 15`: Carga mínima quando o app perde o foco ou é minimizado pelo sistema operacional.
- **Integração com `_notification`:**
  - `NOTIFICATION_APPLICATION_PAUSED` e `FOCUS_OUT`: Reduz `Engine.max_fps = 15`.
  - `NOTIFICATION_APPLICATION_RESUMED` e `FOCUS_IN`: Restaura `Engine.max_fps = 30` (se pausado) ou `60` (se jogando).
- **Integração com `toggle_pause`, `restart_level`, `start_level`:** Alternância atômica e instantânea entre 60 FPS e 30 FPS.

---

## 🧪 3. Validação e Testes
- **Godot Engine Headless Import:** 0 erros e 0 warnings no console.
- **Auditoria de Plantas e MultiMeshes:** `tests/test_flower_materials_integrity.gd` passou com 100% de sucesso em todas as 36 espécies e variantes botânicas.
- **Auto-Descoberta de Temas:** `tests/test_theme_auto_discovery.gd` passou com 100% de sucesso.
- **Validação Específica:** `test_performance_trio.gd` validou a integração das 3 frentes com sucesso.
- **Game Feel e Áudio:** Resposta sonora límpida, sem micro-pops, com resposta tátil e haptics preservados.
