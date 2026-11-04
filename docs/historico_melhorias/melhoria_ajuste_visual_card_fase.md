# Relatório de Melhoria: Calibração Geométrica, Alinhamento e Proporção do MapLevelCard

**Versão:** `v0.12.112-alpha`  
**Data:** 04/11/2026  
**Status:** Concluído com Sucesso

---

## 🎯 Objetivos Realizados

1. **Largura mais Estreita Harmonizada com os Botões:**
   - Redução da largura do card de 660px para 606px (`offset_left = -303`, `offset_right = 303`), criando um recuo lateral perfeitamente integrado e simétrico em relação à extensão dos botões `JOGAR - Fase X` e `MAPA`.

2. **Redução de 50% no Padding Inferior & Equalização dos Paddings:**
   - O `StyleBoxTexture` do painel do card agora aplica padding balanceado e uniforme: `10px` superior e laterais, e `6px` inferior (redução de 50% em relação aos 12px anteriores), eliminando o vão excessivo na base.

3. **Alinhamento Estrito do Topo (Linha Guia Unificada):**
   - Os três blocos da linha superior (Esquerda: Fase / Bioma, Centro: Estrelas, Direita: Tempo) foram equalizados em linhas de altura simétrica (`36px` para os elementos principais e `20px` para as legendas), eliminando qualquer descompasso visual horizontal.

4. **Borda Inferior da Moldura Interceptando o Texto "Objetivos da Fase":**
   - Atualização do traçado vetorial em `frame_objectives.svg` para desenhar o recorte central chanfrado na linha inferior.
   - Posicionamento relativo do texto "Objetivos da Fase" repousando exatamente no entalhe da borda inferior da moldura, com total fidelidade à referência do design.

---

## 📂 Arquivos Modificados

- `assets/ui/map_card/frame_objectives.svg`: Novo traçado com recorte central na linha inferior.
- `scripts/ui/map_level_card.gd`: Redução de largura (`606px`), alinhamento do topo em `top_row`, paddings equalizados (`10px` / `6px`) e reposicionamento do título dos objetivos.
- `scenes/menu/tabs/tab_home.tscn`: Margens ajustadas para a nova largura estreita (`-303` a `+303`).
- `project.godot` e `scripts/core/game_version.gd`: Incremento de versão para `0.12.112-alpha`.
