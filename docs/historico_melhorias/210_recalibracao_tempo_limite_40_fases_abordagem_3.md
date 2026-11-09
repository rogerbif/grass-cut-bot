# Melhoria 210: Recalibração do Tempo Limite das 40 Fases (Abordagem 3 + 10%) ⏱️🌿

**Data:** 09/11/2026  
**Versão Canônica:** `v0.12.161-alpha`  
**Escopo:** Level Design, Balanceamento, Pacing de Gameplay, Cronômetro (`time_limit`).

---

## 1. Contexto & Motivação

Anteriormente, os tempos limites (`time_limit`) das fases apresentavam grande disparidade: fases pequenas com 145 tiles possuíam até 150 segundos (gerando excesso de folga), enquanto outras fases possuíam tempos desalinhados da física de movimentação e do alcance real da serra do cortador.

Para alinhar a duração de cada partida à extensão territorial da ilha e à velocidade de condução do robô, foi aplicada a **Abordagem 3 (Varredura de Corte Real com Diâmetro da Lâmina + Manobras em Zigue-zague + Obstáculos)** com uma margem de segurança de **+10%**.

---

## 2. Metodologia Matemática Aplicada

1. **Velocidade Linear Base:**
   - 18 tiles em 3 segundos $\implies \mathbf{6\text{ tiles por segundo}}$.
2. **Cobertura por Passada da Lâmina:**
   - Raio base de $0{,}90\text{m} \implies$ **Diâmetro de corte de $1{,}80\text{m}$**.
   - Largura em tiles: $4{,}5\text{ tiles}$ para `cell_size = 0.40m` (Fases 1 a 6) e $2{,}25\text{ tiles}$ para `cell_size = 0.80m` (Fases 7 a 40).
3. **Trajetória e Fator de Manobras:**
   - Trajetória linear necessária: $L_{\text{tiles}} = N_{\text{terreno}} / W_{\text{passada}}$.
   - Adicionado multiplicador de curvas de meia-volta nas bordas ($1{,}4\times$) e desvio de obstáculos/rochas ($1{,}0 + \min(0{,}25, \frac{\text{rochas}}{100})$).
4. **Margem de Segurança:**
   - Acréscimo de $+10\%$ e arredondamento para múltiplos de 5 segundos, respeitando o piso mínimo de 20s.

---

## 3. Resumo dos Tempos Recalibrados

- **Fases 01 a 06:** 40s a 135s (ritmo proporcional à densidade das ilhas iniciais).
- **Fases 07 a 20:** 20s a 35s (dinâmica arcade rápida e focada nos objetivos).
- **Fases 21 a 40:** 35s a 100s (progressão contínua e desafiadora até as mega-ilhas finais de 31x31).

---

## 4. Validação & Integridade

- Smoke test executado via `scripts/tools/verify_levels_integrity.gd` com 100% de sucesso nas 40 fases e 0 erros.
- Auditoria do `git diff` confirmou exatamente 40 arquivos modificados, alterando estritamente a linha `"time_limit"` com precisão decimal padrão JSON.
