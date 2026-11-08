# Melhoria 203: Convivência Harmônica Flores com Grama e Exibição Exclusiva de Metas Presentes no Editor 🌸🌿🎯

**Data:** 08/11/2026  
**Versão:** `v0.12.157-alpha`  
**Escopo:** Editor de Fases (`LevelEditorUI`), Construtor de Vegetação (`VegetationGrid`) e Testes Automatizados.

---

## 📋 Resumo Executivo

Nesta melhoria, resolvemos dois comportamentos críticos de usabilidade e física botânica:
1. **Convivência de Flores com Grama:** Anteriormente, em `VegetationGrid`, ao posicionar flores (rosas, margaridas, flores silvestres, etc.), uma clareira de `0.26m` de raio era aplicada em torno do caule da flor, descartando os tufos de grama ao redor e deixando um buraco no gramado. Conforme alinhamento de design, **as flores devem ficar junto com a grama** (aninhadas nos tufos), e **somente as rochas** devem limpar o espaço ao redor (clareira de 1.40m).
2. **Exibição Exclusiva de Objetos Presentes no Painel de Metas do Editor:** No painel lateral direito do Editor de Fases (`LevelEditorUI`), na seção `🎯 METAS DA FASE (OBJETIVOS)`, espécies com 0 unidades na fase permaneciam visíveis como cards inativos (`0 tufos`, `0 flores`), poluindo a interface. Agora, todos os cards iniciam ocultos e são exibidos **apenas se a espécie existir na fase** (`total_count > 0`).

---

## 🛠️ Alterações Implementadas

### 1. Convivência de Flores com Grama (`scripts/plants/vegetation_grid.gd`)
- **Remoção de `stem_positions` para flores:** Eliminada a coleta de caules de flores e o descarte de tufos de grama próximos (`t_xz.distance_squared_to(sp_xz) < 0.0676`).
- **Preservação de clareira estrita apenas para rochas:** As rochas (`rock`) continuam recortando o terreno e a vegetação com o raio canônico de 1.40m via `clip_shapes`.
- **Independência de células lógicas:** Chave de agrupamento lógico ajustada para incluir o tipo de vegetação (`lkey = "%d_%d_%s" % [lx, lz, v_type]`), garantindo que flores e grama no mesmo espaço físico mantenham contagens de metas, recompensas em moedas e instâncias de corte totalmente individuais.

### 2. Filtro Estrito de Metas no Editor (`scripts/editor/level_editor_ui.gd`)
- **Inicialização Oculta:** Todos os cards de `GOALS_CATALOG` iniciam com `card.visible = false`.
- **Atualização Dinâmica (`update_goals_summary` e `set_configured_goals`):** Cada card tem sua visibilidade controlada diretamente por `card.visible = (total_count > 0)`.
- **Dica Informativa de Estado Vazio:** Adicionado o label `lbl_no_goals_hint` exibido apenas quando o mapa não contém nenhuma vegetação ou flor, instruindo o usuário a desenhar grama ou posicionar flores.

### 3. Validação Automatizada (`tests/test_flower_grass_coexistence.gd`)
Criada suíte automatizada `test_flower_grass_coexistence.gd` (executável via Godot Headless CLI) contendo 4 testes:
- **Teste 1:** Painel do editor oculta cards ausentes e exibe apenas espécies com `total_count > 0`.
- **Teste 2:** Mapa sem vegetação oculta todos os cards e exibe dica informativa.
- **Teste 3:** Vegetação sob e ao redor de flores mantém 100% dos tufos físicos de grama íntegros.
- **Teste 4:** Rochas continuam recortando e limpando o raio ao redor conforme o guardrail físico.

---

## 🧪 Resultados dos Testes

Execução via terminal:
```powershell
& "C:\Users\User\OneDrive\Documentos\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --headless --script tests/test_flower_grass_coexistence.gd
```
Saída:
```
=== INICIANDO TESTE: CONVIVÊNCIA DE FLORES COM GRAMA E VISIBILIDADE DE METAS ===
[PASS] Teste 1: Painel do editor oculta cards ausentes e exibe apenas espécies presentes
[PASS] Teste 2: Mapa sem vegetação oculta todos os cards e exibe aviso informativo
[PASS] Teste 3: Tufos de grama permanecem íntegros e convivem com a flor no mesmo local
[PASS] Teste 4: Rocha recorta e mantém espaço limpo ao redor conforme regra canônica

>>> SUCESSO: Todos os 4 testes passaram com êxito! <<<
```
Zero warnings e zero erros na engine Godot.
