# Melhoria 197: Expansão da Lâmina para 10 Níveis, Rebalanceamento de XP (12k) e Penalidade Fixa de Rocha (-1000 XP)

- **Data:** 07/11/2026
- **Versão:** `v0.12.147-alpha`
- **Autor:** Antigravity AI & Roger Bif
- **Status:** Concluído & Validado

---

## 🎯 Objetivo da Melhoria

1. **Expansão de Progressão:** Expandir a progressão da serra/lâmina do cortador de 6 para 10 níveis, estabelecendo o nível 10 como o ápice máximo ("MAX").
2. **Rebalanceamento de XP (12.000 XP Acumulados):** Substituir a curva anterior por metas de XP bem calibradas e arredondadas que totalizam exatamente 12.000 XP acumulados para atingir o nível 10.
3. **Escalonamento de Velocidade (+25% no Topo):** Manter a velocidade inicial do bot em `1.95 m/s` e atingir `3.57 m/s` no nível 10 (+25% de ganho final), com incremento linear arredondado de `0.18 m/s` por nível.
4. **Preservação de Escala e Câmera:**
   - Raio da lâmina preservado na faixa de `0.90m` (Nv. 1) até `1.40m` (Nv. 10), distribuído em 9 intervalos uniformes (`0.50 / 9.0 ≈ 0.0556m` por nível).
   - Distância da câmera isométrica preservada entre `8.40m` (Nv. 1) e `12.00m` (Nv. 10), interpolando suavemente em 10 níveis.
5. **Economia da Oficina (Garagem):** Compra na oficina limitada até o nível 8 com custos progressivos de moedas verdes ($100 \to 3.800$), deixando os níveis 9 e 10 como conquistas exclusivas dentro da gameplay.
6. **Penalidade de Rocha com Dedução de XP Fixo (-1000 XP):** Ao colidir com rochas/obstáculos sólidos, em vez de rebaixar 1 nível completo sumariamente, deduz exatamente 1.000 XP acumulados. Apenas ocorre despromoção de nível se a dedução de 1.000 XP exceder a reserva do nível atual (no Nv. 1, apenas reseta para 0 XP sem valores negativos).
7. **Tiers Visuais:** Mantém o modelo hexagonal de aço cromado no nível 10 (Tier 4), reservando a lâmina dourada para atualizações futuras.

---

## 🛠️ Implementações Realizadas

### 1. Sistema Central de Upgrades (`scripts/core/upgrade_manager.gd`)
- `MAX_BLADE_LEVEL = 10`
- `BLADE_ROCK_PENALTY_XP = 1000.0`
- Tabela de XP por nível:
  - Nv. 1 -> 2: 200 XP
  - Nv. 2 -> 3: 350 XP
  - Nv. 3 -> 4: 550 XP
  - Nv. 4 -> 5: 800 XP
  - Nv. 5 -> 6: 1.200 XP
  - Nv. 6 -> 7: 1.700 XP
  - Nv. 7 -> 8: 2.400 XP
  - Nv. 8 -> 9: 3.300 XP
  - Nv. 9 -> 10: 1.500 XP
  - Total acumulado para atingir Lv 10: **12.000 XP**
- Custos progressivos na oficina:
  - Nv. 2: 100 moedas
  - Nv. 3: 250 moedas
  - Nv. 4: 500 moedas
  - Nv. 5: 900 moedas
  - Nv. 6: 1.500 moedas
  - Nv. 7: 2.400 moedas
  - Nv. 8: 3.800 moedas
  - Nv. 9 e 10: Bloqueados na oficina (compra retorna `-1`)
- Mapeamento de Tiers Visuais:
  - Níveis 1 a 3: Tier 1 (Lâmina Tripla)
  - Níveis 4 a 6: Tier 2 (Lâmina Quádrupla)
  - Níveis 7 e 8: Tier 3 (Lâmina Titânio Estelar)
  - Níveis 9 e 10: Tier 4 (Lâmina Hexagonal de Aço)
- Dedução de XP de Rocha (`penalize_blade_hit`):
  - Deduz `1000.0` XP.
  - Ao atingir o nível 10 e bater em rocha, converte para Nível 9 com `1500 - 1000 = 500 XP`.
  - Se a dedução for maior que o XP acumulado no nível, desce de nível sequencialmente consumindo o saldo restante. No nível 1, grampeia em `0.0`.

### 2. Câmera Isométrica (`scripts/camera/isometric_camera.gd`)
- Normalização do zoom ajustada para 10 níveis: `t = clampf(float(lvl - 1) / 9.0, 0.0, 1.0)`.
- Distância inicial mantida em `8.40m` e distância final mantida em `12.00m`.

### 3. Barra Flutuante de XP do Cortador (`scripts/cutter/blade_progress_bar.gd`)
- Condição de "MAX" atualizada para considerar `new_level >= 10`.

### 4. Interface da Garagem / Oficina (`scripts/menu/tabs/tab_garage.gd`)
- Botão exibe "MÁX LOJA" ao atingir o nível 8.
- Nível 10 identificado como "Nível MAX (10)".

### 5. Localização (`data/translations/translations.csv`)
- Atualizadas as chaves `GARAGE_STATS_MAX_FMT` e `GARAGE_TIP` em PT, EN e ES para referenciar o Nível 10 e a nova regra de perda de 1.000 XP por colisão com pedras.

### 6. Documentação Canônica
- Atualizados os arquivos `docs/04_sistemas_e_gameplay/ECONOMIA_E_OFICINA.md` e `docs/04_sistemas_e_gameplay/GAME_FEEL_E_HAPTICS.md` com as novas tabelas de progressão, custos e descrições da penalidade de rochas.

---

## 🧪 Validação e Testes Automatizados

1. **`res://tests/test_blade_progression.tscn`:**
   - 41 asserções cobrindo todos os 10 níveis, raio, velocidade, tiers visuais, compras na oficina até nível 8, bloqueio nos níveis 9 e 10, perda de 1.000 XP em múltiplos cenários (Lv 10 -> Lv 9 com 500 XP, cascata de níveis, limite no Lv 1).
   - **Resultado:** 100% de sucesso.
2. **`res://tests/test_blade_pop_and_slash.tscn`:**
   - Validação da emissão do sinal `blade_leveled_up`, pop de escala, slash e ondas de choque adaptadas aos novos níveis.
   - **Resultado:** 100% de sucesso.
3. **`res://tests/test_wheat_level_02.tscn`:**
   - Validação de gameplay e integridade da colheita.
   - **Resultado:** 100% de sucesso.
