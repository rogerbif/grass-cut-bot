# Game Design Document (GDD) — Grass Cut Bot 🌿🤖

> [!NOTE]
> **Documento Canônico Vivo:**  
> O Game Design Document oficial e vivo deste projeto é mantido e atualizado continuamente em:  
> 👉 **[`docs/01_visao_geral_e_gdd/GDD_OFICIAL.md`](docs/01_visao_geral_e_gdd/GDD_OFICIAL.md)**

---

## 📌 Resumo Rápido de Design

- **Gênero:** Hiper-casual, Simulação Arcade, Satisfying Game Feel.
- **Plataforma Principal:** Android (Mobile Portrait 720x1280, 9:16 vertical).
- **Controle:** Joystick virtual flutuante de uma mão (*one-thumb play*) ancorado na metade inferior da tela.
- **Protagonista:** Robô cortador *Cutter Bit* com mono-wheel, carcaça amarela de impacto, olhos expressivos de LED e rotor de serra circular omnidirecional.
- **Cenário:** Ilhas 3D flutuantes sobre o oceano azul turquesa toon, falésias marrons arredondadas e colisão costeira invisível (Zero Cercas).
- **Core Loop:** Entrar na ilha ➔ Conduzir o robô com o joystick ➔ Ceifar a vegetação requerida contra o relógio ➔ Zerar as metas do HUD ➔ Ganhar moedas verdes ➔ Adquirir melhorias de lâmina, potência, raio e velocidade na Oficina.
- **Metas e Variedades:** Grama comum verde (1 golpe, 1 moeda), Trigo dourado resistente (2 golpes, 3 moedas) e Flores nobres (2 golpes, 5 moedas). Regra de lote: 10 tufos físicos ceifados = 1 unidade de meta abatida.

Para detalhes completos de balanceamento, física, tiers de lâminas e progressão de níveis, consulte a documentação técnica canônica na pasta [`docs/`](docs/PROJETO_GRASS_CUT_BOT.md).
