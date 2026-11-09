# Melhoria 205: Matriz Canônica de Priorização de Melhorias (Esforço vs. Impacto) 📊🌿

## 📋 Contexto e Diretriz Canônica

Com a consolidação da arquitetura de **Mundos Temáticos** (Mundo 1 Diurno com 100 fases revisadas, seguido pelo Mundo 2 Sunset bloqueado até a conclusão do Mundo 1), a esteira de evolução do **Grass Cut Bot** formalizou sua **Matriz Canônica de Priorização de Melhorias por Esforço versus Impacto**.

Essa matriz separa claramente:
- **Vitórias Rápidas (Quick Wins):** Iniciativas de alto retorno com baixo/médio esforço técnico.
- **Projetos Estratégicos:** Pilares centrais de retenção, customização e jogabilidade.
- **Expansões Condicionadas de Conteúdo:** Grandes marcos dependentes da esteira de 100 fases.

---

## 🧭 Mapeamento Cartesiano

```
        ▲ ALTO IMPACTO
        │
        │  [1. Bônus Diário & Missões]   [4. Expansão 100 Fases Mundo 1]
        │  [2. Loja: Pacotes de Moedas]  [5. Skins & Customização Bot]
        │  [3. Assets Play Store ASO]    [6. Power-ups de Campo]
        │                                [7. Rochas Destrutíveis]
────────┼────────────────────────────────────────────────────────►
        │                                ALTO ESFORÇO
        │                                [8. Mundo 2: Sunset (F101-200)]*
        │                                [9. Bot Arquiteto Mobile]
        │
        ▼ BAIXO IMPACTO
        * Condicionado à conclusão das 100 fases do Mundo 1
```

---

## 📋 Matriz Estruturada de Priorização

| Ordem | Iniciativa / Melhoria | Impacto | Esforço | Categoria | Justificativa Estratégica |
| :---: | :--- | :---: | :---: | :---: | :--- |
| **1º** | **Bônus Diário (Daily Bonus) & Missões Rápidas** | **Alto** | **Baixo/Médio** | Retenção / Metagame | Cria o hábito diário de retorno (D1/D7) com lógica leve no `SaveManager` e modal de resgate. |
| **2º** | **Ativação Real dos Pacotes da Loja (`TabStore`)** | **Médio/Alto** | **Baixo** | Economia / UI | Elimina o texto `"EM BREVE"`, dando função real à aba Loja com resgates e conversões de moedas. |
| **3º** | **Assets Promocionais & ASO da Play Store** | **Alto** | **Baixo/Médio** | Publicação / Marketing | Feature Graphic (1024x500) e Screenshots 9:16 com lettering usando as ferramentas prontas `capture_store_screenshots.tscn` e `icon_photo_studio.tscn`. |
| **4º** | **Skins de Chassi & Trilhas de Lâmina (`TabGarage`)** | **Alto** | **Médio** | Cosmético / Economia | Concede vazão ao excesso de moedas colhidas, estimulando a progressão com pinturas e rastros luminosos. |
| **5º** | **Power-ups Coletáveis de Campo (Turbo / Ímã / Relâmpago)** | **Alto** | **Médio** | Gameplay / Game Feel | Brotam esporadicamente na grama, acelerando a dinâmica do corte e quebrando repetição em fases amplas. |
| **6º** | **Expansão Contínua do Mundo 1 (Fases 41 a 100 Diurnas)** | **Crítico** | **Alto** | Level Design / Conteúdo | Esteira contínua de criação autoral no editor `F2`. Meta mandatória para atingir 100 fases revisadas e liberar o Mundo 2. |
| **7º** | **Obstáculos Interativos: Rochas Rachadas & Troncos** | **Médio/Alto** | **Médio** | Level Design / Física | Rochas que quebram com lâminas avançadas (Tier 3+ / Lv 10 MAX), abrindo atalhos e canteiros nobres. |
| **8º** | **Mundo 2: Ilhas do Entardecer Dourado (Sunset World)** | **Muito Alto** | **Alto** | Expansão / Novo Mundo | **Bloqueio Mandatório:** Iniciado **exclusivamente após as 100 fases do Mundo 1 estarem criadas e auditadas**. 100 novas fases (101 a 200). |
| **9º** | **Modo Construtor Mobile ("Bot Arquiteto")** | **Médio/Alto** | **Muito Alto** | Sandbox Mobile | Ferramenta criativa diegética operada no celular. Demanda adaptação tátil complexa do pipeline vetorial. |

---

## 🛠️ Documentos Atualizados

- **`docs/MELHORIAS_FUTURAS.md`:** Incorporada a Seção 7 com a matriz canônica de priorização e tabela executiva.
- **`docs/historico_melhorias/INDICE_MELHORIAS.md`:** Indexada a presente melhoria como referência histórica.
