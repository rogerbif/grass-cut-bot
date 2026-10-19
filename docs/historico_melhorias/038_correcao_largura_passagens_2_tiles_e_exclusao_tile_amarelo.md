# Melhoria 038: Correção de Largura Mínima de Passagem ($\ge 2$ Tiles), Exclusão do Tile Amarelo e Calibração Física 🛠️🌿

**Data:** 18 de Outubro de 2026  
**Versão:** `v0.7.1`  
**Autor:** Antigravity AI Pair Programmer & Usuário  

---

## 1. Contexto e Diagnóstico

Durante os testes de gameplay nas 20 fases canônicas, foram identificadas duas limitações críticas:
1. **Bloqueio do Robô em Canais de 1 Tile:**
   - Cada célula do grid mede $0.80\text{m}$.
   - Com os colisores de contenção costeira invisível (`LevelJsonLoader`) nas faces voltadas para o mar, o vão livre interno útil de um canal de 1 tile cercado por água ficava em torno de $0.68\text{m}$ a $0.72\text{m}$.
   - O colisor físico de corpo do robô (`BodyCollision`) possuía raio $R = 0.45\text{m}$ (diâmetro de $0.90\text{m}$). Como $0.90\text{m} > 0.72\text{m}$, o robô ficava fisicamente entalado sem conseguir atravessar passagens estreitas para alcançar o restante da colheita (ex: campos de trigo).
   - O colisor das rochas possuía raio $R = 0.55\text{m}$ (diâmetro de $1.10\text{m}$), transbordando para os tiles adjacentes.
2. **Tile Amarelo Bugado (`tile_island_dirt`):**
   - O modelo `tile_island_dirt.glb` continha coordenadas UV que caíam em uma região amarela neon sólida do atlas de texturas, gerando um retângulo amarelo chapado destoante no meio do gramado tropical.

---

## 2. Ações Implementadas

### 2.1 Regra Invariante de Level Design — Largura Mínima $\ge 2$ Tiles ($1.60\text{m}$)
- O gerador de fases [`scripts/tools/generate_levels.js`](../../scripts/tools/generate_levels.js) foi completamente reformulado:
  - Nenhuma ponte, canal, curva em S, cotovelo ou istmo possui menos de 2 tiles contíguos de terra.
  - As pistas da Serpentina (Fase 09), os corredores do Tridente (Fase 13) e as voltas da Fortaleza Espiral (Fase 16) foram ampliadas para 3 a 4 tiles de largura.
  - Todas as rochas foram reposicionadas com folga mínima de 2 tiles de passagem livre ao seu redor.

### 2.2 Calibração dos Colisores de Física
- **Cortador ([`scenes/cutter/cutter.tscn`](../../scenes/cutter/cutter.tscn)):**
  - Redução do raio do `BodyCollision` de $0.45\text{m}$ para **$0.30\text{m}$** (diâmetro de $0.60\text{m}$).
  - Ajuste na escala visual do `VisualPivot` de $0.70$ para **$0.62$**, mantendo o robô perfeitamente proporcionado e ágil.
- **Rochas ([`scenes/obstacles/rock.tscn`](../../scenes/obstacles/rock.tscn)):**
  - Redução do raio do colisor cilíndrico de $0.55\text{m}$ para **$0.36\text{m}$**, cobrindo com precisão a malha visual e impedindo qualquer invasão de colisão em células vizinhas.

### 2.3 Exclusão Definitiva do Tile Amarelo
- Removido o tipo `island_dirt` de todas as 20 fases.
- Redirecionado `"island_dirt"` no dicionário `TILE_SCENES` de [`scripts/level/level_json_loader.gd`](../../scripts/level/level_json_loader.gd) para apontar para `tile_island_center.tscn` (piso de grama verde esmeralda estilizado).
- Atualizado o validador [`scripts/tools/verify_levels.js`](../../scripts/tools/verify_levels.js) para auditar e barrar automaticamente qualquer ocorrência de `island_dirt`.

---

## 3. Validação e Resultados

1. **Testes Automatizados:** 100% de sucesso na regeração e validação das 20 fases com `verify_levels.js`.
2. **Navegabilidade:** O robô navega livremente por pontes, curvas e corredores sem travar nas margens.
3. **Estética:** Zero tiles amarelos indesejados no terreno das ilhas.
4. **Game SemVer:** Versão atualizada para `v0.7.1` em `project.godot` e `export_presets.cfg`.
