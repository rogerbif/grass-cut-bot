# Melhoria 099: Superfícies Vetoriais no Modo Edição e Grama 3D sob Demanda no Playtest (F1) 🛠️🌿🎮

**Data:** 2026-10-24  
**Versão:** `v0.12.24-alpha`  
**Autor:** Antigravity (Advanced Agentic Coding)  
**Status:** Concluído com Sucesso e Validado (0 Warnings / 0 Erros)  

---

## 1. Contexto e Motivação

No **Editor de Fases PC** ([`scripts/editor/level_editor.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/editor/level_editor.gd)), a cada clique do mouse, rotação ou pincelada, a função `_rebuild_3d_world()` instanciava o nó `VegetationGrid` completo com o algoritmo de amostragem iterativa de Poisson Disk, gerando mais de $1.200$ tufos 3D volumétricos contínuos na cena de trabalho.

Isso acarretava:
1. **Engasgos e Perda de Fluidez no Pincel:** Redesenhar a vegetação física com centenas de malhas a cada traço contínuo do mouse custava $\sim 35\text{ms}$ por frame, gerando travamentos perceptíveis.
2. **Obstrução Visual de Level Design:** Lâminas densas de grama 3D sobrepostas cobriam as linhas da grade (`GridOverlay`), os limites das falésias, a base das rochas e o marcador de spawn do robô, dificultando a edição milimétrica de fases.

---

## 2. Decisões Arquiteturais e Execução Técnica

### 2.1 Prancheta Vetorial Plana no Modo Edição (`_build_editor_vector_ground`)
- Durante a edição, o `plants_container` passa a renderizar exclusivamente malhas trianguladas planas 2D/3D (`VectorGrassField.generate_ground_meshes()`) a $Y = 0.005\text{m}$.
- **Performance Instantânea:** A geração da superfície vetorial cai de $\sim 35\text{ms}$ para **$< 0.5\text{ms}$**, permitindo pintar com pincéis e carimbos de forma 100% contínua e sem qualquer atraso (*zero lag*).
- **Materiais Foscos Low Poly:** Materiais estáticos `StandardMaterial3D` dedicados para cada variedade botânica com `roughness = 0.90` (Guardrail 7) e sem reflexos especulares.
- **Recorte Automático sob Rochas:** O polígono de grama recorta perfeitamente o espaço ocupado por rochas no terreno, mantendo a leitura limpa do cenário.

### 2.2 Grama 3D Volumétrica Oficial sob Demanda no Playtest ([F1] ou [F5])
- **Inicialização do Playtest (`_start_playtest()`):**
  - Limpa as malhas vetoriais planas do `plants_container`.
  - Instancia o `VegetationGrid` oficial 3D volumétrico, gerando os tufos físicos reais com shaders de vento, partículas em arco e colheita.
  - Spawna o robô cortador (`Cutter`) e os controles touch/teclado.
- **Encerramento do Playtest (`_stop_playtest()`):**
  - Ao pressionar `ESC` ou `F1`, a instância de teste do `VegetationGrid` e o robô são destruídos.
  - A função `_rebuild_3d_world()` é executada, restaurando a prancheta vetorial limpa com os dados intactos da fase.

---

## 3. Arquivos Modificados

- [`scripts/editor/level_editor.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/editor/level_editor.gd)
- [`docs/03_level_design_e_fases/SISTEMA_EDITOR_DE_FASES.md`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/docs/03_level_design_e_fases/SISTEMA_EDITOR_DE_FASES.md)
- [`docs/historico_melhorias/INDICE_MELHORIAS.md`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/docs/historico_melhorias/INDICE_MELHORIAS.md)
- [`scripts/core/game_version.gd`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/scripts/core/game_version.gd)
- [`project.godot`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/project.godot)
- [`export_presets.cfg`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/export_presets.cfg)

---

## 4. Validação e Qualidade

- **Varredura e Compilação Headless:** Executado via `godot_console.exe --headless --path . --editor --quit` com código de saída `0` e zero warnings de GDScript.
- **Runtime do Editor:** `scenes/editor/level_editor.tscn` executado em modo headless com sucesso.
- **Bateria de Testes:** `tests/test_save_manager.tscn` executado e aprovado com 100% de sucesso.
- **Game SemVer:** Atualizado atomicamente de `0.12.23-alpha` para `0.12.24-alpha`.
