# Histórico de Melhoria: Rolagem Rápida, Fling Fluido e Boost de Arrasto Longo no Herbário

**Versão:** `v0.12.200-alpha`  
**Data:** 12/11/2026  
**Tipo:** Game Feel, UX Touch Mobile, Física Cinética de UI  
**Autor:** Antigravity (Google DeepMind Pair Programming)

---

## 🎯 Objetivo

Implementar física de rolagem rápida, arremesso cinético (*fling*) e amplificação inteligente de velocidade (*boost*) em arrastos longos no catálogo do Herbário da Ilha (`TabCollection`). O jogador agora consegue com um único gesto longo e veloz arremessar a lista até o final (ou topo), mantendo controle cirúrgico para toques curtos e parada imediata ao encostar o dedo na tela durante o deslizamento.

---

## 🔍 Diagnóstico e Análise Técnica

### Problemas Anteriores
1. **Atrito Artificial Brutal:**
   - A inércia no `_process` utilizava `_scroll_velocity_y = lerpf(_scroll_velocity_y, 0.0, delta * 9.0)`. Com fator 9.0, a velocidade caía exponencialmente em menos de 0.2 segundos, freando bruscamente a lista independentemente da força do gesto.
2. **Perda de Velocidade no Milissegundo Final do Toque:**
   - A velocidade era calculada exclusivamente a partir do último evento `InputEventScreenDrag`. Como o dedo humano desacelera instintivamente nos últimos milissegundos antes de perder contato físico com o vidro da tela, a velocidade amostrada no `st.pressed = false` era quase nula.
3. **Ausência de Boost para Arremessos Longos:**
   - Um arrasto amplo (cobrindo 300px a 600px na tela) recebia o mesmo tratamento de um micro-deslocamento de 30px, impossibilitando percorrer os 36 cards com conforto e agilidade.

---

## 🛠️ Implementação Realizada

### 1. Buffer de Amostragem em Janela Deslizante (`scripts/menu/tabs/tab_collection.gd`)
- Adicionadas variáveis de estado cinético:
  - `_touch_samples: Array[Dictionary] = []` (buffer com `{time: float, pos_y: float}`).
  - `_drag_start_pos_y: float = 0.0` e `_drag_start_time: float = 0.0`.
- Durante o arrasto (`InputEventScreenDrag`), as coordenadas de toque e timestamps são armazenadas, podando amostras com mais de 120ms.
- Ao soltar o dedo (`st.pressed = false`):
  - Amostras com mais de 100ms são descartadas.
  - Se o dedo manteve movimento até os últimos 80ms antes do release, a velocidade média do arremesso é calculada com alta precisão através do diferencial das amostras (`dy / dt`), blindando o gesto contra a desaceleração final do dedo.
  - Se o dedo permaneceu imóvel na tela por mais de 80ms antes de soltar, a lista não arremessa ($v = 0$), garantindo micro-ajustes perfeitos.

### 2. Boost Dinâmico de Arrasto Longo
- Calculada a distância acumulada percorrida entre o início e o fim do toque: `total_dist = absf(st.position.y - _drag_start_pos_y)`.
- Se o gesto for longo ($> 180\text{px}$) e a velocidade for expressiva ($> 350\text{px/s}$):
  - É aplicado um multiplicador proporcional de arremesso:
    $$\text{boost} = \text{clampf}\left(1.0 + \frac{\text{total\_dist}}{350.0} \times 0.9,\, 1.25,\, 2.4\right)$$
  - Em arremessos longos e rápidos, a velocidade inicial resultante permite que a lista deslize velozmente por dezenas de cards ou até o final do catálogo.

### 3. Decaimento Exponencial Físico e Parada Instantânea
- No `_process`:
  - Substituído o freio linear por decaimento exponencial contínuo:
    $$\text{\_scroll\_velocity\_y} \times= \exp(-\text{friction} \times \delta)$$
    onde $\text{friction} = 3.2$ (calibrado para a sensação orgânica clássica de rolagem do Android/iOS).
  - Quando o usuário toca na tela (`st.pressed = true`) enquanto a lista está voando, a inércia é cancelada no mesmo quadro (`_scroll_velocity_y = 0.0`, `set_process(false)`), fornecendo feedback tátil e controle absoluto.
  - Limites de topo (`scroll_vertical <= 0`) e fim de lista cancelam imediatamente a inércia residual.

---

## 📊 Comparativo de Experiência de Rolagem

| Cenário de Uso | Comportamento Anterior | Novo Comportamento (`v0.12.200-alpha`) |
| :--- | :--- | :--- |
| **Arremesso Rápido Longo** | Parava após 2 a 3 cards (< 0.25s) | Desliza rapidamente até o fim da lista (~1.5s suave) |
| **Toque Curto com Parada** | Funcional, mas rígido | 100% preservado; para onde o dedo soltar |
| **Interrupção em Voo** | Não havia voo para interromper | Toque em qualquer lugar estanca a lista imediatamente |
| **Fórmula de Desaceleração** | `lerpf(..., 9.0 * delta)` | Decaimento exponencial $\exp(-3.2 \times \delta)$ |

---

## 🧪 Testes e Validação de Integridade

- `tests/test_herbarium_perf.tscn`: Aprovado com sucesso (856 nós, 2.11ms troca de filtro, 14.33ms refresh).
- `tests/test_collection_system.tscn`: Aprovado com 100% de sucesso.
- `tests/test_manifest_sync.gd`: Aprovado com 0 erros.
- `godot --headless --import`: Executado com sucesso, 0 warnings e 0 erros.
