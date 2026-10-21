# Histórico de Melhoria: Cena Independente de Calibração da Água (Water Tuner F6) 🌊🎛️

**ID:** `066_cena_independente_water_tuner_f6`  
**Versão:** `v0.10.3-alpha`  
**Data:** 21/10/2026  
**Status:** Concluído e Validado (0 Warnings no Godot 4.7.1)  

---

## 1. Contexto e Objetivo

Para permitir calibração visual perfeita, interativa e em tempo real dos parâmetros do shader de água estilizado (Wind Waker Toon), foi criada uma cena de ferramentas autônoma (`scenes/tools/water_tuner.tscn`), que pode ser aberta e executada diretamente pelo atalho `F6` no Godot.

A ferramenta fornece controle total através de sliders e seletores de cor, permitindo comparar o visual do oceano contra as ilhas reais do jogo, alternar ângulos de câmera (gameplay isométrico vs. mapa aéreo) e copiar a configuração para a área de transferência com um clique.

---

## 2. Recursos da Ferramenta (`WaterTuner`)

### A. Cena 3D Real com Ilhas e Oceano
- Carrega a geometria real e vegetação de qualquer fase canônica (ex: Fase 2 com estrelas de trigo e rochas).
- Plano do oceano com o shader `shaders/wind_waker_water.gdshader`.
- Alternância instantânea de câmera:
  - **Câmera Isométrica de Gameplay:** Ângulo $40^\circ$ próximo da partida.
  - **Câmera Aérea do Mapa de Fases:** Ângulo $58^\circ$ elevado para visão global.

### B. Painel de Controle com Sliders em Tempo Real
- **Cores (ColorPickerButtons):**
  - `water_color`: Cor turquesa principal da água rasa.
  - `water2_color`: Cor azul marinho da água profunda.
  - `foam_color`: Cor branca/ciano das cristas de espuma.
- **Sliders Numéricos:**
  - `uv_scale`: Tamanho e densidade das ondas (`0.02` a `1.00`).
  - `distortion_speed`: Velocidade da ondulação (`0.0` a `4.0`).
  - `distortion_strength`: Força da distorção orgânica (`0.0` a `0.40`).
  - `foam_intensity`: Força e opacidade da espuma (`0.0` a `1.0`).
  - `roughness`: Rugosidade fosca do material (`0.0` a `1.0`).

### C. Ações e Atalhos
- 📋 **Botão "COPIAR PARÂMETROS" [C]:** Copia o bloco de texto formatado para o clipboard do Windows (`DisplayServer.clipboard_set`), pronto para colar no chat.
- 💾 **Botão "Salvar no .tres" [S]:** Salva as alterações diretamente em `res://shaders/wind_waker_water_material.tres`.
- 🎥 **Botão "Alternar Câmera" [V]:** Alterna entre visão do jogo e do mapa.
- 🏝️ **Botão "Alternar Fase" [TAB]:** Alterna entre as fases 1, 2, 5, 6 e 20.
- 👁️ **Atalho [H]:** Oculta/mostra o painel de controles para ver o oceano em tela cheia.

---

## 3. Validação e Testes

- Executada a cena `scenes/tools/water_tuner.tscn` via Godot Runner (MCP): **0 warnings e 0 erros**.
- Interação com sliders, mudança de cores, cópia para o clipboard e alternância de câmera 100% responsivas.

---

## 4. Arquivos Criados / Modificados

| Arquivo | Descrição |
| :--- | :--- |
| `scenes/tools/water_tuner.tscn` | Cena 3D isolada com ilha, mar e painel de sliders para execução direta via F6. |
| `scripts/tools/water_tuner.gd` | Script com lógica de sliders em tempo real, cópia para clipboard, alternância de câmera e fases. |
| `shaders/wind_waker_water.gdshader` | Adicionado uniform `distortion_strength` ajustável. |
| `shaders/wind_waker_water_material.tres` | Material atualizado com o parâmetro de força de distorção. |
| `docs/historico_melhorias/INDICE_MELHORIAS.md` | Indexação da melhoria. |
| `scripts/core/game_version.gd`, `project.godot`, `export_presets.cfg` | Atualização SemVer para `v0.10.3-alpha` (code `1003`). |
