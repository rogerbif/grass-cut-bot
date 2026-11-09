# Melhoria 204: Arquitetura de Mundos e Variabilidade Atmosférica (100 Fases no Mundo 1) 🌍🌿

## 📋 Contexto e Diretriz Canônica

Por diretriz estratégica de design, a esteira de evolução do **Grass Cut Bot** estruturou a melhoria de **Variabilidade Visual de Biomas & Cenários (Alto Impacto / Custo Zero de GPU)** sob uma arquitetura macro orientada a **Mundos Temáticos**:

1. **Mundo 1: Ilhas Tropicais (O Grande Arquipélago):**
   - É o ecossistema atual do jogo, caracterizado por ilhas 3D sem cercas sobre o mar turquesa, falésias estilizadas e vegetação exuberante.
   - O escopo canônico do **Mundo 1 compreende exatamente 100 fases autorais, criadas, balanceadas e revisadas** (atualmente com 40 fases ativas serializadas em JSON v4).
2. **Regra Invariante de Transição entre Mundos:**
   - O **Mundo 2** (próximo bioma temático, ex: *Oásis das Dunas / Cânions de Areia* ou *Arquipélago Glacial*) **será criado exclusivamente após a entrega, revisão e aprovação completa de todas as 100 fases do Mundo 1**.
3. **Variabilidade Atmosférica em 4 Ciclos (Custo Zero de GPU):**
   - Para garantir frescor visual, sensação dinâmica de progressão e evitar monotonia ao longo das 100 fases sem quebrar a identidade tropical e sem nenhum impacto negativo de draw calls ou GPU mobile, a atmosfera é modulada em **4 blocos de 25 fases**:
     - **☀️ Fases 01 a 25 — Ilhas Tropicais Diurnas (Manhã Solar / Sol a Pino):** Céu ciano aberto, mar turquesa (`#46E6FF`) e luz solar direta com sombras limpas.
     - **🌇 Fases 26 a 50 — Entardecer Dourado Tropical (Golden Hour / Pôr do Sol):** Céu alaranjado suave, névoa quente e reflexos acobreados no mar.
     - **🌌 Fases 51 a 75 — Noite Tropical Estrelada (Tropical Night & Vaga-lumes):** Céu azul-marinho profundo pontilhado de estrelas, mar escuro com reflexos lunares, farol frontal do robô iluminando a vegetação e partículas suaves de vaga-lumes.
     - **🌸 Fases 76 a 100 — Alvorada Mística / Névoa das Ilhas (Twilight Dawn):** Gradientes suaves de rosa, lilás e dourado matinal com névoa suave nos horizontes oceânicos até o clímax da Fase 100.

---

## 🛠️ Alterações Documentais Realizadas

1. **`docs/MELHORIAS_FUTURAS.md`:**
   - Atualizada a Seção 1 (Estratégia de Lançamento & Arquitetura de Mundos), fixando a meta canônica de 100 fases revisadas no Mundo 1 e o bloqueio de criação do Mundo 2 até essa meta ser concluída.
   - Atualizada a Seção 3 (Variabilidade Visual de Atmosfera no Mundo 1: Ilhas Tropicais), dividindo as 100 fases nos 4 ciclos de 25 fases com custo zero de GPU.
2. **`docs/01_visao_geral_e_gdd/GDD_OFICIAL.md`:**
   - Seção 7.1 atualizada para registrar o dimensionamento oficial de 100 fases do Mundo 1 e a regra de transição do Mundo 2.
   - Seção 7.2 atualizada com os 4 ciclos de modulação atmosférica tropical.
3. **`docs/03_level_design_e_fases/ESTRUTURA_DAS_FASES.md`:**
   - Seção 3 atualizada com o roteiro canônico de expansão (Fases 41 a 100) e a regra estrita de transição para o Mundo 2.

---

## 🎯 Próximos Passos

1. Criação dos presets de iluminação e shader de ambiente (WorldEnvironment / DirectionalLight3D / Água) para suportar dinamicamente a troca de atmosfera por faixa de nível (Fases 1-25, 26-50, etc.).
2. Planejamento do level design autoral para o bloco de expansão (Fases 41 a 100) no editor in-game (`F2`), com revisão contínua de rotas e balanceamento botânico.
