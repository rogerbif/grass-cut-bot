# Relatório de Melhoria: Refinamento de Alinhamento, Paddings e Gradientes Holográficos no MapLevelCard

**Versão:** `v0.12.113-alpha`  
**Data:** 04/11/2026  
**Status:** Concluído com Sucesso

---

## 🎯 Objetivos Realizados

1. **Alinhamento dos Blocos Superiores com as Linhas dos Chanfros:**
   - Adicionados `MarginContainer` internos nos blocos do topo:
     - Bloco da esquerda (`Fase 03` e `Ilha Tropical`): recuado com `margin_left = 14`, alinhando exatamente com o início vertical do chanfro da moldura interna de objetivos.
     - Bloco da direita (`Tempo 1:45` e relógio): recuado com `margin_right = 14`, alinhando com a linha de término do chanfro direito da moldura.

2. **Paddings do Card Equalizados e Base Compactada:**
   - `pad_l = 14.0`, `pad_r = 14.0`, `pad_t = 14.0` (laterais e topo rigorosamente com o mesmo valor).
   - `pad_b = 2.0` (padding inferior ultra-compacto, eliminando completamente a faixa escura excedente abaixo de "Objetivos da Fase").

3. **Gradientes de Transparência nas Linhas da Moldura:**
   - Atualizado o arquivo vetorial `assets/ui/map_card/frame_objectives.svg`:
     - Gradientes lineares `stroke_bottom_left` e `stroke_bottom_right` aplicados nos traçados inferiores que ladeiam o texto central "Objetivos da Fase", desvanecendo suavemente para `stop-opacity="0.0"`.
     - Gradientes suaves nas laterais e quinas, criando o efeito de neon holográfico cyber idêntico ao concept art.

4. **Encaixe Preciso do Rótulo "Objetivos da Fase":**
   - Rótulo posicionado com `offset_top = -18.0` e `offset_bottom = 4.0` interceptando exatamente o intervalo recortado pelas linhas da moldura inferior.

---

## 📂 Arquivos Modificados

- `assets/ui/map_card/frame_objectives.svg`: Segmentação e gradientes lineares com transparência (fade-out).
- `scripts/ui/map_level_card.gd`: Margens de recuo lateral de 14px em `top_row`, paddings equalizados (`14px` / `2px`) e calibragem do texto inferior.
- `project.godot` e `scripts/core/game_version.gd`: Incremento de versão para `0.12.113-alpha`.
