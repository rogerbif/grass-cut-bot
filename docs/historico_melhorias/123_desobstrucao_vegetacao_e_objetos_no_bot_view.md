# Melhoria 123: Desobstrução Automática de Vegetação e Objetos Frontais no Menu Inicial (`BOT_VIEW`) 🌿🤖🔍

> **Data:** 27 de Outubro de 2026  
> **Versão:** `v0.12.48-alpha`  
> **Status:** Concluído e Validado  
> **Tipo:** Interface / Polish Visual / Menu Inicial  

---

## 1. Contexto e Diagnóstico

Na aba `Home` do Menu Inicial (`MainMenu`), o jogador pode alternar a visualização da ilha ativa entre o modo mapa aberto (`MAP_VIEW`) e o modo de câmera aproximada no robô cortador (`BOT_VIEW`).

Na visão `BOT_VIEW`:
- A câmera aproxima-se do robô (`target_bot_pos + Vector3(0, 1.25, 4.0)` com pitch de $-8^\circ$), posicionada em $+Z$ olhando diretamente para $-Z$.
- O robô cortador repousa no ponto de spawn da fase olhando em $+Z$ diretamente para a câmera.
- Em determinadas fases (como a Fase 5 e fases com rochas frontais como as Fases 9, 12, 16 e 18), espigas volumosas de trigo, flores nobres altas, tufos de grama densos ou blocos de rocha situados no setor sul ($+Z$) da ilha ficavam posicionados diretamente entre a lente da câmera e o robô, cobrindo seu corpo, olhos mecha, lâmina circular e os botões de navegação inferiores da interface.

O objetivo desta melhoria foi implementar um sistema de desobstrução automática no `IslandNode` que detecta e desativa todos os elementos (gramas, trigos, flores e rochas) situados no cone frontal do robô quando em `BOT_VIEW`, sem afetar a integridade visual da ilha no `MAP_VIEW`.

---

## 2. Solução Técnica Implementada

### 2.1 Método Analítico de Detecção Frontal (`_is_in_front_of_bot`)

Em `scripts/menu/island_node.gd`, foi introduzida a função analítica `_is_in_front_of_bot(pos: Vector3) -> bool`:

```gdscript
func _is_in_front_of_bot(pos: Vector3) -> bool:
	if bot_anchor == null:
		return false
	var bot_pos: Vector3 = bot_anchor.position
	var dz: float = pos.z - bot_pos.z
	var dx: float = absf(pos.x - bot_pos.x)
	# Na visão BOT_VIEW (modo Home), o robô fica voltado para +Z em direção à câmera.
	# Qualquer elemento no setor frontal do robô (dz > -0.30m) dentro do enquadramento (dx < 3.2m)
	# obstrui o corpo, cabeça, lâmina ou a área de avanço frontal do bot.
	return dz > -0.30 and dx < 3.2
```

### 2.2 Supressão na Geração da Vegetação 3D (`_ensure_3d_veg_built`)

Durante a instanciação da vegetação volumétrica da ilha ativa:
- **Trigo e Flores de Tile:** Verificados via `_is_in_front_of_bot(f_pos)` e `_is_in_front_of_bot(w_pos)`. Instâncias no setor frontal são descartadas antes da criação dos `MultiMesh`.
- **Tufos de Grama e Flores Vetoriais:** A amostragem de tufos (`sample_all_tufts()`) e grade discreta passa pelo filtro `_is_in_front_of_bot(tuft_pos)`, eliminando qualquer tufo de grama situado na frente do bot.
- As transformações filtradas são consolidadas no dicionário `veg_transforms_by_type`, preservando apenas os elementos situados ao redor e atrás do robô, conferindo um fundo verde acolhedor com profundidade sem qualquer obstrução em primeiro plano.

### 2.3 Supressão e Restauração Dinâmica de Rochas (`_set_rocks_in_front_hidden`)

Para as rochas renderizadas no `MiniRocksMMI`:
- No `_apply_mode_visibility()`, ao ativar `BOT_VIEW` na ilha ativa, o método `_set_rocks_in_front_hidden(true)` é executado.
- Instâncias de rochas frontais têm sua escala reduzida para zero e posição deslocada para $Y = -999.0$, tornando-as invisíveis sem necessidade de recriar a estrutura do `MultiMesh`.
- Ao retornar para `MAP_VIEW`, `_set_rocks_in_front_hidden(false)` restaura imediatamente as matrizes de transformação originais em `_rock_transforms`.

---

## 3. Validação e Testes Automatizados

Foi criado o teste de unidade e integração `tests/test_menu_bot_view_clearance.gd` (e cena `tests/test_menu_bot_view_clearance.tscn`):
1. **Fase 5 (Vegetação e Trigo):**
   - Instanciação de `IslandNode` com dados do `level_05.json`.
   - Transição para `BOT_VIEW`.
   - Inspeção de 475 instâncias de vegetação 3D: **0 instâncias** presentes no setor frontal ($dz > -0.30\text{m}$ e $dx < 3.2\text{m}$). O trigo e tufos frontais foram perfeitamente suprimidos.
2. **Fase 9 (Rochas Frontais):**
   - Instanciação do `level_09.json`.
   - Identificação da rocha frontal em $gx=8, gz=11$ (em frente ao spawn $gx=8, gz=8$).
   - Validação da ocultação dinâmica sem impacto nas rochas laterais ou no modo mapa.
3. **Execução Headless:** Executado via console da Godot 4 com `exit code 0` e 0 warnings.
4. **Execução Contínua da Cena Principal:** `scenes/main.tscn` rodou por 100 frames sem erros ou avisos de engine.

---

## 4. Arquivos Modificados e Criados

| Arquivo | Descrição das Modificações |
| :--- | :--- |
| `scripts/menu/island_node.gd` | Adicionado `_is_in_front_of_bot()`, `_set_rocks_in_front_hidden()`, integração no `_ensure_3d_veg_built()` e membro `veg_transforms_by_type`. |
| `tests/test_menu_bot_view_clearance.gd` | Suíte de testes automatizados para desobstrução de vegetação, flores e rochas no `BOT_VIEW`. |
| `tests/test_menu_bot_view_clearance.tscn` | Cena de execução do teste automatizado. |
| `docs/04_sistemas_e_gameplay/SISTEMA_DE_INTERFACE_HUD.md` | Documentação canônica do enquadramento `BOT_VIEW` e do filtro de desobstrução. |
| `docs/03_level_design_e_fases/ESTRUTURA_DAS_FASES.md` | Seção sobre miniaturas do Menu Inicial e supressão frontal. |
| `scripts/core/game_version.gd` | Incremento da versão SemVer para `v0.12.48-alpha`. |
| `project.godot` | Atualização do parâmetro `config/version="0.12.48-alpha"`. |
| `export_presets.cfg` | Atualização de `version/name` e `version/code`. |
| `docs/historico_melhorias/INDICE_MELHORIAS.md` | Indexação da melhoria 123 no catálogo mestre. |
