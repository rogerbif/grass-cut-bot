# Expansão Canônica para 40 Fases (Mundo 1: Ilhas Tropicais) 🌿🏝️

**Data de Conclusão:** 06/11/2026  
**Tipo:** Feature / Level Design / Arquitetura  
**Escopo:** Mundo 1 (O Grande Arquipélago)  
**Versão Alvo:** Game SemVer `v0.12.132-alpha`  

---

## 1. Visão Geral e Contexto

Com o objetivo de transformar o **Grass Cut Bot** em um jogo completo pronto para publicação na Google Play Store e estruturado em Mundos temáticos (Mundo 1: Ilhas Tropicais ➔ Mundos futuros: Deserto, Gelo, etc.), foi executada a expansão de 20 para **40 fases canônicas serializadas em JSON v4** (`data/levels/level_01.json` até `level_40.json`).

---

## 2. Pilares de Level Design e Gameplay Implementados

1. **Escalonamento Geográfico das Ilhas (até 100 Tiles):**
   - **Tier 1 (Fases 01 a 10):** Ilhas compactas e didáticas (~25 a ~48 tiles), com sessões dinâmicas de 60s a 105s.
   - **Tier 2 (Fases 11 a 20):** Istmos, pontes, canais internos vazados e curvas em "S" (~50 a ~66 tiles).
   - **Tier 3 (Fases 21 a 30):** Grandes arquipélagos interconectados, tabuleiros florais e fortalezas agrícolas (~70 a ~85 tiles).
   - **Tier 4 (Fases 31 a 40):** Mega-ilhas monumentais (~88 a 100 tiles), finalizando na épica **Grande Coroa Real (Fase 40)** com 100 tiles exatos.
2. **Introdução Consciente de Rochas (`rock`):**
   - **Fases 1, 2 e 3:** 100% livres de obstáculos sólidos, garantindo familiarização fluida com a serra e o joystick.
   - **Fase 4:** Estreia da 1ª rocha central destacada.
   - **Fases 5 a 40:** Crescimento progressivo de 2 a 10 rochas por fase, sempre respeitando a distância euclidiana mínima entre rochas ($> 2.80\text{m}$) e 8 vizinhos dentro da ilha (folga costeira anti-estrangulamento).
3. **Cores de Grama Estéticas & Meta Unificada Limpa:**
   - O solo é adornado com mandalas, mosaicos, anéis e faixas em 7 cores cosméticas.
   - Todas as cores de grama abatem uma **meta única de grama 🌿 (`"grass"`)** no HUD.
   - O Top HUD permanece limpo e ultra-legível em telas verticais (1 a 4 objetivos usuais, com teto máximo de 6 no clímax final).
4. **Progressão Botânica Suave:**
   - Apresentação didática de 1 espécie nova por fase no Tier 1 (Trigo, Margarida, Flor Sino, Rosa, Girassol, Tulipa, Corola e Canteiro Floral).
   - Recombinações equilibradas nos Tiers 2, 3 e 4.

---

## 3. Modificações Técnicas na Base de Código

1. **`scripts/tools/generate_all_40_levels.gd`:**
   - Novo script canônico executado headless que constrói matematicamente o Autotile, recortes costeiros de segurança ($0.34\text{m}$), clareira de spawn ($0.72\text{m}$) e calibração de tempo 3 estrelas para as 40 fases.
   - Introdução de algoritmos de posicionamento com validação geométrica estrita.
   - **Resultado:** 40 fases geradas e auditadas com **0 erros** de conformidade.
2. **`scripts/editor/level_serializer.gd`:**
   - Suporte a `custom_goals` direto no salvamento sem necessidade de recomputação redundante via `LevelCardData`.
   - Ampliação da listagem de fases para até 100 níveis (`range(1, 101)`).
3. **`scripts/core/game_manager.gd`:**
   - Atualização do método `next_level()` para avançar sem travas até a Fase 40 (`next_idx > 40`).
4. **`docs/03_level_design_e_fases/ESTRUTURA_DAS_FASES.md` & `docs/01_visao_geral_e_gdd/GDD_OFICIAL.md`:**
   - Documentação canônica 100% atualizada com a tabela detalhada das 40 fases e diretrizes de design.

---

## 4. Validação e Resultados

- Execução headless completa do Godot (`godot --headless --script scripts/tools/generate_all_40_levels.gd`): **0 erros e 0 warnings**.
- Execução do scanner de importação (`godot --headless --import`): regeneração com sucesso.
- Execução do jogo real por 100 frames (`--quit-after 100`): **0 erros de runtime**.
- Mapa do arquipélago no Hub Principal: varredura automática e exibição completa das 40 ilhas em ziguezague.
