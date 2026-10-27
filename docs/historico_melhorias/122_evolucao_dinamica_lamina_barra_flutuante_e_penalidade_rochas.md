# Melhoria 122: Sistema de Evolução Dinâmica da Lâmina, Barra Flutuante 3D e Penalidade por Choque com Rochas 🪚⚡

Este documento registra a implementação do sistema unificado de crescimento em tempo real da serra circular (Níveis 1 a 6 / MAX), escalonamento dinâmico de velocidade, barra de progresso em formato pílula sobre a cabeça do robô com texto interno, penalidade direta por choque com rochas e reestruturação da oficina.

---

## 1. Visão Geral e Motivação

Anteriormente, o cortador dependia de upgrades estáticos comprados exclusivamente na Garagem por moedas para aumentar raio e velocidade. O corte no gameplay não impactava dinamicamente o tamanho da serra nem gerava sensação de bola de neve (*snowball*).

A Melhoria 122 estabelece um ciclo empolgante de **Risco vs Recompensa**:
- **Crescimento Orgânico por Corte:** Conforme o robô ceifa vegetação, acumula XP que preenche uma barra flutuante compacta posicionada sobre sua cabeça.
- **Escalação de Poder e Velocidade:** A lâmina cresce de **0.90m até 1.40m** e a velocidade máxima acelera de **3.25m/s até 4.75m/s** ao atingir o Nível 6 ("MAX").
- **Tensão Mecânica:** Colidir contra rochas e obstáculos penaliza o jogador rebaixando imediatamente 1 nível completo (com cooldown de proteção de 1.2s para evitar perdas em ricochetes duplos).
- **Persistência de Campanha:** O nível e o progresso da lâmina persistem entre fases e são salvos automaticamente no `SaveManager`.
- **Oficina / Garagem Simplificada:** Removidos upgrades legados de multiplicador e potência. O jogador pode comprar níveis da serra diretamente até o Nível 5 com moedas.

---

## 2. Detalhes do Balanceamento Implementado

### Tabela de Níveis e Atributos Físicos
| Nível | Raio da Serra | Diâmetro de Corte | Velocidade Linear | Malha Visual Equipada | XP Necessário | Custo na Garagem |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **1** | **0.90 m** | 1.80 m | **3.25 m/s** | `blade_tier_1` (Tripla) | 50 XP (~4-6s) | Inicial (Grátis) |
| **2** | **1.00 m** | 2.00 m | **3.55 m/s** (+9%) | `blade_tier_1` (Tripla) | 100 XP (~10s) | 75 🪙 |
| **3** | **1.10 m** | 2.20 m | **3.85 m/s** (+18%) | `blade_tier_2` (Quádrupla) | 180 XP (~1 fase) | 150 🪙 |
| **4** | **1.20 m** | 2.40 m | **4.15 m/s** (+27%) | `blade_tier_2` (Quádrupla) | 280 XP (~1.5 fases) | 300 🪙 |
| **5** | **1.30 m** | 2.60 m | **4.45 m/s** (+36%) | `blade_tier_3` (Titânio) | 400 XP (~2 fases) | 550 🪙 |
| **6 (MAX)** | **1.40 m** | 2.80 m | **4.75 m/s** (+46%) | `blade_tier_4` (Hexagonal Dourada) | **0 XP (Barra Cheia / MAX)** | *Exclusivo de Gameplay* |

### Rendimento de XP por Colheita
- **Grama (qualquer cor):** `+1.0 XP` por tufo.
- **Trigo:** `+3.0 XP` por colheita.
- **Flores:** `+5.0 XP` por flor.

---

## 3. Barra Flutuante 3D (`BladeProgressBar3D`)

- **Estrutura:** Ancorada em `Transform3D(0, 1.45, 0)` no cortador, orientada para a câmera isométrica via `BillboardMode` com sombra desativada.
- **Renderização Leve:** `SubViewport` compacto de 140x24 pixels com fundo grafite translúcido fosco e preenchimento verde-lima vibrante (gradiente dourado no nível MAX).
- **Tipografia Central:** Texto `Lv. 1`, `Lv. 2`, ... e `MAX` posicionado **dentro da própria barra**, em fonte branca sólida (`#FFFFFF`) com contorno preto nítido (`outline_size = 2`), garantindo legibilidade absoluta.
- **Micro-Animações de Game Feel:**
  - *Level Up:* Pulso de escala com bounce elástico rápido (1.0 -> 1.35 -> 1.0).
  - *Dano na Rocha:* Piscar vermelho vivo (`#ff4747`) e tremor (*shake*) lateral rápido.

---

## 4. Arquivos Modificados e Criados

1. `scenes/cutter/blade_progress_bar.tscn` (NOVO): Cena da barra flutuante 3D com SubViewport e Sprite3D billboard.
2. `scripts/cutter/blade_progress_bar.gd` (NOVO): Controlador da animação, texto interno e feedback sensorial da barra.
3. `scripts/core/upgrade_manager.gd`: Sistema de XP, cálculo de raio e velocidade por nível, compra até nível 5, penalidade de nível e persistência.
4. `scripts/core/save_manager.gd`: Registro das chaves `blade_level` e `blade_xp` no esquema padrão de save e reset.
5. `scripts/cutter/cutter.gd`: Conexão com os sinais de evolução da serra, cooldown de 1.2s contra perdas consecutivas em rochas e atualização contínua.
6. `scripts/plants/vegetation_grid.gd`: Injeção de concessão de XP a cada corte de tufo ceifado em `cut_in_circle`.
7. `scenes/menu/tabs/tab_garage.tscn`: Limpeza dos cards legados de multiplicador e potência; foco no upgrade unificado de lâmina até nível 5.
8. `scripts/menu/tabs/tab_garage.gd`: Lógica de compra centralizada na serra circular.
9. `tests/test_blade_progression.gd` & `.tscn` (NOVO): Suite de testes automatizados cobrindo toda a matemática de progressão, limits, penalidades e save.

---

## 5. Validação e Testes
- Teste unitário headless executado com 100% de sucesso.
- Execução do jogo principal em modo headless por 100 frames com 0 warnings e 0 erros de runtime.
