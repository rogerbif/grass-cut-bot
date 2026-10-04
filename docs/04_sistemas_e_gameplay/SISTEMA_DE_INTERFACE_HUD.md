# Sistema de Interface e HUD 📊📱

Este documento especifica a interface de usuário (HUD), os componentes visuais de status e o fluxo de telas modais em **Grass Cut Bot**.

---

## 1. Top HUD Durante a Partida

O Top HUD é posicionado na parte superior da tela e utiliza estilo *flat matte* com cantos arredondados:

```
TopBar (PanelContainer)
├── TimerContainer (PanelContainer) -> TimerLabel ("1:30")
├── CoinsContainer (PanelContainer) -> Ícone Moeda + CoinsLabel ("0")
├── GoalsContainer (HBoxContainer)  -> Cards Dinâmicos de Metas (🌿 60, 🌾 15, 🌸 8)
└── PauseButton (Button)            -> Ícone "⏸"
```

### Componentes em Destaque:
1. **Cronômetro Regressivo:**
   - Exibe o tempo restante no formato Minutos e Segundos (`M:SS`).
   - Alerta Crítico: Quando o tempo restante é menor ou igual a 15 segundos, o texto muda dinamicamente para vermelho vivo (`Color(1.0, 0.3, 0.3)`), sinalizando urgência.
2. **Cards Dinâmicos de Metas:**
   - Criados sob demanda pelo `HUD` conforme as espécies exigidas no nível atual.
   - Cada card possui o emoji da planta e a quantidade pendente.
   - **Efeito Visual de Pop:** A cada tufo ceifado, o card correspondente sofre uma rápida animação de escala (`1.15x` -> `1.0x` em 0.1s).
   - **Meta Batida:** Ao zerar o contador, o número é substituído por um check verde (`✔`) e o fundo do card ganha tonalidade verde esmeralda.
3. **Contador de Moedas:**
   - Reflete o total de moedas acumuladas pelo jogador na sessão, atualizado em tempo real via sinal `UpgradeManager.coins_changed`.

---

## 2. Modais e Telas de Fim de Partida

Todos os modais rodam com `process_mode = PROCESS_MODE_ALWAYS` para continuar respondendo a toques mesmo quando a árvore do jogo está pausada (`get_tree().paused = true`).

### 2.1 Modal de Pausa (`PauseModal`)
- Acionado pelo botão de pausa no Top HUD.
- Congela física e cronômetro.
- **Ações:**
  - `Continuar ▶`: Despausa o jogo e fecha o modal.
  - `Reiniciar Fase 🔄`: Recarrega o estágio restaurando a contagem de tempo e metas.
  - `Oficina ⚙`: Abre a oficina para compra de melhorias imediatas.

### 2.2 Modal de Vitória (`VictoryModal`)
- Disparado automaticamente quando todas as metas chegam a zero antes do tempo expirar.
- Exibe o bônus de moedas obtidas na fase.
- **Ações:**
  - `Próxima Fase ⏩`: Avança para o próximo nível.
  - `Repetir Fase 🔄`: Joga o estágio novamente para acumular mais moedas.
  - `Oficina ⚙`: Abre a loja de melhorias.

### 2.3 Modal de Derrota (`GameOverModal`)
- Disparado caso o cronômetro atinja `0:00` antes de bater as cotas.
- Exibe mensagem explicativa de falha.
- **Ações:**
  - `Tentar Novamente 🔄`: Reinicia a fase imediatamente.
  - `Oficina ⚙`: Permite melhorar o cortador para superar a fase.
