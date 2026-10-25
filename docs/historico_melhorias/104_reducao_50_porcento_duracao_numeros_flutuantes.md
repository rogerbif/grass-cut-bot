# Histórico de Melhorias: 104 - Redução em 50% na Duração dos Números Flutuantes ⏱️🪙

**Data:** 25 de Outubro de 2026  
**Versão:** `v0.12.29-alpha`  
**Escopo:** Feedback Visual de Moedas (`scripts/effects/floating_coin_manager.gd`), Game Feel Arcade e Desobstrução Visual.

---

## 1. Contexto e Motivação

Após a calibração que garantiu o spawn estrito dos números flutuantes de colheita (`+1`, `+3`, `+5`) ao lado do corpo do cortador, observou-se em gameplay que os números estavam permanecendo tempo excessivo na tela antes de desaparecer (~$0.68\text{s}$ no total).

Essa permanência prolongada poluía visualmente o campo de visão durante deslocamentos rápidos e ceifadas contínuas. A solicitação determinou a redução em **50% no tempo total de exibição** dos números flutuantes.

---

## 2. Ações Implementadas

### A. Calibração da Curva de Animação do Tween (`floating_coin_manager.gd`)
Todos os tempos da coreografia visual do label foram reduzidos à metade exata:

| Etapa da Animação | Duração Anterior | Nova Duração (-50%) | Parâmetros / Curva |
| :--- | :--- | :--- | :--- |
| **1. Fade-in** | $0.08\text{s}$ | **$0.04\text{s}$** | `modulate:a`: $0.0 \to 1.0$ (`TRANS_QUAD`, `EASE_OUT`) |
| **2. Pop Elástico** | $0.18\text{s}$ | **$0.09\text{s}$** | Escala $0.35 \to 1.30$ em $0.05\text{s}$ e $1.30 \to 1.0$ em $0.04\text{s}$ |
| **3. Subida Vertical** | $0.60\text{s}$ ($+0.70\text{m}$) | **$0.30\text{s}$ ($+0.55\text{m}$)** | Deslocamento vertical $Y$ rápido e expressivo |
| **4. Sustentação (Interval)** | $0.14\text{s}$ | **$0.07\text{s}$** | Intervalo de legibilidade rápida |
| **5. Fade-out** | $0.28\text{s}$ | **$0.14\text{s}$** | `modulate:a`: $1.0 \to 0.0$ (`TRANS_QUAD`, `EASE_IN`) |
| **Tempo Total em Tela** | **~ $0.68\text{s}$** | **~ $0.34\text{s}$** | **Redução de 50% atingida** |

---

## 3. Validação e Qualidade

1. **Teste Automatizado de Spawn e Ancoragem ([`tests/test_floating_coin_manager.tscn`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/tests/test_floating_coin_manager.tscn)):**
   - Comprovada a ancoragem estrita ao lado do corpo do robô ($0.650\text{m}$) e total afastamento do centro da fase ($4.079\text{m}$).
2. **Suíte Completa:** Teste de persistência e inclinação da serra aprovados com 100% de sucesso.
3. **Zero Warnings:** Compilação em modo headless validada sem avisos ou erros.
