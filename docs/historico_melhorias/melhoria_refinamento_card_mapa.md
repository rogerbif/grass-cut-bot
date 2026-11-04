# Relatório de Melhoria: Refinamento de Alinhamento, Paddings e Gradientes Holográficos no MapLevelCard

**Versão:** `v0.12.115-alpha`  
**Data:** 04/11/2026  
**Status:** Concluído com Sucesso

---

## 🎯 Objetivos Realizados

1. **Alinhamento dos Blocos Superiores com as Linhas dos Chanfros:**
   - Adicionados `MarginContainer` internos nos blocos do topo:
     - Bloco da esquerda (`Fase 03` e `Ilha Tropical`): recuado com `margin_left = 14`, alinhando exatamente com o início vertical do chanfro da moldura interna de objetivos.
     - Bloco da direita (`Tempo 1:45` e relógio): recuado com `margin_right = 14`, alinhando com a linha de término do chanfro direito da moldura.

2. **Gradientes de Transparência nas Linhas Superior e Inferior da Moldura:**
   - Atualizado o arquivo vetorial `assets/ui/map_card/frame_objectives.svg`:
     - **Linha Superior:** Segmentada em dois trechos (`M 24 3 L 76 3` e `M 224 3 L 276 3`) com gradientes lineares (`stroke_top_left` e `stroke_top_right`) que desvanecem suavemente para transparência (`stop-opacity="0.0"`), deixando o vão central aberto de forma idêntica à linha inferior.
     - **Linha Inferior:** Gradientes lineares `stroke_bottom_left` e `stroke_bottom_right` aplicados nos traçados inferiores que ladeiam o texto central "Objetivos da Fase".
     - Gradientes suaves nas laterais e quinas, criando o efeito de neon holográfico cyber idêntico à arte de referência.

3. **Paddings Rigorosamente Equalizados (Superior, Laterais e Inferior a 14px):**
   - No `MapLevelCard.gd`: `content_margin_left = 14.0`, `content_margin_top = 14.0`, `content_margin_right = 14.0` e `content_margin_bottom = 14.0` (todos rigorosamente com 14px).
   - Na cena `tab_home.tscn`: ajuste da âncora vertical para `offset_top = -456.0` e `offset_bottom = -262.0` (altura real de 194px em vez de 232px forçados), eliminando completamente a sobra de espaço vazia na base e alinhando o card proporcionalmente acima dos botões JOGAR/MAPA.

4. **Espaçamento e Tipografia de "Objetivos da Fase":**
   - Fonte e cor unificadas com a legenda "Estrelas": tamanho 16 e cor `COL_SUB` (`Color(0.50, 0.65, 0.80, 1.0)`).
   - Espaçamento vertical ampliado entre os mini-cards de metas e o texto para ~12px (`frame_wrapper` expandido para 102px com `pad_b = 16.0` e `offset_top = -14.0`), garantindo respiração visual perfeita e alinhamento do texto na abertura inferior da moldura.

---

## 📂 Arquivos Modificados

- `assets/ui/map_card/frame_objectives.svg`: Segmentação das linhas superior e inferior com gradientes lineares com transparência (fade-out).
- `scripts/ui/map_level_card.gd`: Margens de recuo lateral de 14px em `top_row`, paddings equalizados a 14px, fonte/cor de "Objetivos da Fase" igualadas a "Estrelas" (16px `COL_SUB`) e ampliação do espaçamento vertical.
- `scenes/menu/tabs/tab_home.tscn`: Altura calibrada para 194px (`offset_top = -456.0`).
- `project.godot` e `scripts/core/game_version.gd`: Incremento de versão para `0.12.115-alpha`.
