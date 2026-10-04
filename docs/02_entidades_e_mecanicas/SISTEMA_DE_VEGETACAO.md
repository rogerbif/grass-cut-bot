# Sistema de Vegetação e Colheita 🌾🌸

Este documento define as especificações das espécies vegetais, mecânica de resistência, ciclo de vida dos tufos e geração de partículas em **Grass Cut Bot**.

---

## 1. Classificação das Espécies Vegetais

| Variedade | Cena | Saúde Base | Moedas Ganhas | Partículas | Comportamento e Papel no Jogo |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Grama Verde Básica** | `grass_tuft.tscn` | 1 golpe | 1 moeda | Verde esmeralda | Vegetação fundamental presente em todos os estágios. Ceifada instantaneamente. |
| **Trigo Dourado** | `wheat_tuft.tscn` | 2 golpes | 3 moedas | Dourado ouro | Exige duas passadas ou lâmina com upgrade de potência $\ge 2$. Cota de colheita. |
| **Flores do Campo** | `flower_tuft.tscn` | 2 golpes | 5 moedas | Pétalas magenta | Vegetação nobre com alto valor econômico. Cota de colheita nos níveis avançados. |

---

## 2. Estrutura do Nó de Vegetação (`plant.tscn`)

Cada tufo possui a seguinte árvore:
```
Tuft (Node3D - grupo "plants", script plant.gd)
├── Area3D (Layer 4, Mask 0, grupo "vegetation")
│   └── CollisionShape3D (Cylinder r=0.35m, h=0.6m)
├── VisualMesh (Node3D - malha Low Poly das folhas/espigas)
└── CutParticles (CPUParticles3D - emissão explosiva em arco)
```

- **Variação Orgânica:** No `_ready()`, cada tufo recebe uma rotação aleatória no eixo Y (`0` a $2\pi$) e uma leve oscilação de escala (`0.85` a `1.15`), garantindo que o gramado pareça natural mesmo estando em uma grade uniforme.

---

## 3. Ciclo de Dano e Corte

1. **Golpe Parcial (Resistência Ativa):**
   - Se o tufo receber dano inferior à sua saúde restante (`health > power`):
   - Um Tween de squash & stretch rápido é acionado (`scale * 1.25` em 0.05s voltando ao normal), dando feedback imediato de que a planta sofreu impacto mas resistiu.
2. **Corte Concluído (`_perform_cut`):**
   - O colisor `Area3D` é desativado imediatamente para evitar múltiplos registros acidentais.
   - O emissor `CutParticles` dispara 14-16 fragmentos em arco parabólico com gravidade natural.
   - O `GameManager.register_cut(plant_key, coin_reward)` é notificado:
     - Incrementa as moedas da fase multiplicadas pelo multiplicador ativo.
     - Dispara o pulso háptico suave no celular (`Input.vibrate_handheld(15)`).
     - Decrementa a cota pendente no Top HUD da partida.
   - O modelo 3D é achatado e encolhido a zero via Tween em 0.14s, revelando o piso limpo.
   - O nó aguarda o término das partículas e executa `queue_free()`.
