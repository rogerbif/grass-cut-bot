# Melhoria 019: Migração de Fases para Cenas Godot (.tscn) e Edição Manual da Fase 1 [v0.4.2] 🗺️✂️

## 1. Visão Geral e Contexto
O usuário solicitou uma mudança estrutural no fluxo de level design: *"quero que cada fase seja uma cena no godot no momento estamos somente com a fase 1, quero que coloque os tufos de grama nessa cena, para que eu possa efetuar a edição manualmente"*.

Anteriormente, a Fase 1 e os demais níveis eram montados por laços de código GDScript imperativo dentro de `level_controller.gd`. Esta melhoria transforma cada nível em uma cena Godot própria (`.tscn`), povoando a Fase 1 (`scenes/levels/level_01.tscn`) com todos os tufos de grama instanciados para que o desenvolvedor possa arrastar, duplicar, reposicionar ou excluir elementos visualmente no Viewport 3D da engine.

---

## 2. Implementações Técnicas

### A. Arquitetura da Cena do Nível (`scenes/levels/level_01.tscn`)
A cena da Fase 1 foi estruturada com a seguinte hierarquia visual:
```
Level01 (Node3D - script base_level.gd)
├── Terrain (instância de terrain.tscn com piso e muretas limítrofes)
├── CutterSpawn (Marker3D na posição 0, 0.1, 0)
├── Obstacles (Node3D vazio para adição manual de rochas)
└── Plants (Node3D contendo 56 instâncias de grass_tuft.tscn)
    ├── GrassTuft_01
    ├── ...
    └── GrassTuft_56
```
- **Disposição Inicial:** 56 tufos de grama verde estilizada 3D alinhados no grid padrão com espaçamento de $1.1\text{m}$, mantendo o centro livre ao redor do `CutterSpawn` para partida suave do jogador.

### B. Script de Nível com Detecção Automática (`scripts/level/base_level.gd`)
- **Detecção Reativa de Metas (`get_goals()`):** O script inspeciona recursivamente os filhos de `$Plants`. Qualquer tufo adicionado (seja grama, trigo ou flor) tem sua propriedade `plant_key` registrada dinamicamente nas metas do `GameManager`. O designer não precisa ajustar contadores em código ao alterar a cena.
- **Ponto de Spawn Flexível (`get_spawn_position()`):** Lê a coordenada global do nó `CutterSpawn`, permitindo mudar o local inicial do robô simplesmente movendo o gizmo 3D.
- **Suporte a Execução Rápida (F6):** Se o designer rodar a cena da fase isoladamente pelo atalho F6, `base_level.gd` redireciona para a cena mestre `main.tscn` mantendo o nível ativo selecionado.

### C. Carregador Dinâmico no `level_controller.gd`
- **Busca por Cena de Nível:** Tenta carregar `res://scenes/levels/level_%02d.tscn`.
- **Desativação de Terreno Duplicado:** Como cada cena de nível inclui seu próprio terreno e muretas, o terreno de fallback da cena `main.tscn` é automaticamente desativado (`process_mode = DISABLED` e `visible = false`).
- **Compatibilidade Retroativa com Fallback Procedural:** Fases futuras que ainda não possuam cena montada continuam geradas pelas funções procedurais (`_build_level_2()`, `_build_level_3()`).

---

## 3. Validação e Qualidade
- **Zero Warnings / Zero Erros:** Verificado em execução de debug via Godot MCP (`run_project` e `get_debug_output`).
- **Metas Sincronizadas:** O Top HUD inicia com o contador exato de 56 tufos e atualiza a cada corte.
- **SemVer:** Incrementado para **`v0.4.2`** em `project.godot`.
