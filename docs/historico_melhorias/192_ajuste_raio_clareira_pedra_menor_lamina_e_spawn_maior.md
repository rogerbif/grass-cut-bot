# Melhoria 192: Calibração de Clareiras de Vegetação — Raio Menor da Lâmina para Rochas (0.90m) e Raio da Rocha para Spawn do Bot (1.40m) 🪨🤖🌿

**Versão do Projeto:** `v0.12.142-alpha`  
**Data:** 07/11/2026  
**Status:** Concluído e Validado ✅  

---

## 📌 Contexto e Solicitação do Usuário

Anteriormente:
- As rochas utilizavam o raio máximo de lâmina ($1.40\text{m}$, Nível 6) para recortar/afastar a grama em sua volta, criando uma clareira excessivamente ampla e deixando muito solo nu ao redor dos blocos de pedra.
- O ponto de spawn do robô cortador utilizava um raio de clareira tímido ($0.72\text{m}$), o que podia deixar tufos de grama muito próximos ou sob a lâmina e o chassi do cortador no início da fase.

O usuário solicitou:
1. **Rochas:** Reduzir o raio de afastamento da grama para o **raio menor da lâmina** ($0.90\text{m}$, Tier 1 / Nível 1 base).
2. **Spawn do Bot:** Aumentar a clareira de spawn para o **raio anterior da rocha** ($1.40\text{m}$), garantindo uma área livre e limpa ao redor do robô no ponto inicial.

---

## 🛠️ Implementações Realizadas

### 1. Sistema de Vegetação no Gameplay (`scripts/plants/vegetation_grid.gd`)
- Calibração do recorte sob rochas no campo vetorial (`clip_shapes`) de $1.40\text{m}$ para **$0.90\text{m}$** (raio da lâmina base Nv 1).
- Injeção obrigatória do recorte na clareira do spawn do robô com **$1.40\text{m}$** (raio da lâmina Nv 6 / antiga rocha), assegurando que o bot inicie sobre uma clareira circular limpa e bem definida.

### 2. Renderização de Ilhas no Menu Principal (`scripts/menu/island_node.gd`)
- Atualização em `_build_vector_grass_surface` e `_build_plants_from_json`:
  - Recorte de grama sob rochas calibrado para **$0.90\text{m}$**.
  - Recorte na âncora do robô (`bot_anchor`) calibrado para **$1.40\text{m}$**, mantendo visual limpo ao redor do bot na ilha em foco.

### 3. Editor de Fases (`scripts/editor/level_editor.gd`)
- `ROCK_CLEARANCE_RADIUS = 0.90` (era 1.40).
- `SPAWN_CLEARANCE_RADIUS = 1.40`.
- Hover/Preview do pincel (`clearance_r`):
  - Ao selecionar a ferramenta de Rocha, exibe o círculo de proteção de **$0.90\text{m}$**.
  - Ao selecionar a ferramenta de Spawn, exibe o círculo dourado de **$1.40\text{m}$**.
- Em `_place_spawn_at` e `_rebuild_3d_world`, o recorte é aplicado com $1.40\text{m}$ para o spawn e $0.90\text{m}$ para as rochas.

### 4. Geradores e Auditores de Fases (`generate_all_20_levels.gd` e `generate_all_40_levels.gd`)
- `SPAWN_GRASS_CLEAR_RADIUS = 1.40` (era 0.72).
- `ROCK_GRASS_CLEAR_RADIUS = 0.90`.
- Execução completa dos geradores e regeneração atômica dos 40 arquivos JSON (`level_01.json` até `level_40.json`), todos validados com **0 erros** de auditoria botânica e física.

---

## 📊 Resultados e Validação

- **Rochas:** A grama aproxima-se organicamente até $0.90\text{m}$ do centro da rocha (redução de 35% no vazio ao redor da pedra).
- **Spawn do Bot:** Clareira circular perfeita de $1.40\text{m}$ ao redor do robô no ponto zero.
- **Auditoria 40 Fases:** 40/40 fases regeneradas e auditadas com 0 erros.
- **Console Godot:** 0 warnings e 0 erros.
