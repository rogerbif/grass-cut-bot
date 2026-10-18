# Melhoria 034: Criação das Primeiras 20 Fases Canônicas Únicas com Progressão de Dificuldade 🌿🗺️🎮

**Data:** 18/10/2026  
**Versão:** `v0.6.0`  
**Autor:** Antigravity AI Pair Programmer & Usuário  

---

## 1. Contexto e Motivação

O projeto **Grass Cut Bot** possuía suas mecânicas fundamentais (corte radial, física de obstáculos, joystick touch, shaders e upgrades da oficina) consolidadas, mas necessitava de uma biblioteca rica de níveis para proporcionar a experiência de jogo completa no padrão hiper-casual mobile.

A demanda exigiu a concepção e implementação das **20 primeiras fases**, com duas premissas centrais e inegociáveis:
1. **Todas Diferentes:** Cada uma das 20 fases possui silhueta e geometria de ilha 3D única, biomas diferenciados e arranjos exclusivos de obstáculos.
2. **Progressão Gradual de Dificuldade:** Uma curva de aprendizado distribuída em 5 Tiers bem calibrados, desde o aprendizado suave dos controles até desafios táticos com chicanes, labirintos rochosos e alta densidade de vegetação resistente.

---

## 2. Ações Implementadas

### 2.1 Concepção dos 5 Tiers e Matriz de 20 Fases Canônicas
As fases foram projetadas com foco nos 12 Mandamentos Invariantes de `GEMINI.md` (Zero Cercas, Ilhas 3D Flutuantes sobre o oceano, contenção costeira invisível `Layer 1` com espuma e rochas sólidas `Layer 4`):

- **Tier 1 (Fases 1 a 4) — O Despertar do Jardineiro:**
  - *Fase 01 (Praia Inicial):* Retângulo aberto, corte puro de grama verde, tutorial suave (90s).
  - *Fase 02 (Baía Amarela):* Ovalada com enseada sul, introdução da grama amarela e 2 rochas isoladas (85s).
  - *Fase 03 (Campos Dourados):* Retângulo chanfrado, introdução do Trigo (2 golpes da lâmina) (85s).
  - *Fase 04 (Jardim das Orquídeas):* Cruz Grega com pátio central de terra e Flores Nobres de alta pontuação (80s).
- **Tier 2 (Fases 5 a 8) — Expansão Geográfica & Istmos:**
  - *Fase 05 (Ilhas Gêmeas):* Dois círculos unidos por ponte estreita de terra de 2 blocos (85s).
  - *Fase 06 (Lagoa Serena):* Atol circular em anel (Donut) com lagoa interna de água azul (80s).
  - *Fase 07 (Vale da Ampulheta):* Dois platôs largos unidos por gargalo central (80s).
  - *Fase 08 (Três Picos):* Arquipélago tríade em "Y" com biomas em 3 cores (85s).
- **Tier 3 (Fases 9 a 12) — Desafio Tático & Chicanes:**
  - *Fase 09 (Serpentina de Coral):* Península longa em "S" com cotovelos protegidos por rochas (80s).
  - *Fase 10 (Labirinto das Pedras):* Paredes internas de rocha formando corredores e grama roxa (85s).
  - *Fase 11 (Trevo da Sorte):* 4 pétalas tangentes com 4 cores de grama, trigo e flores (85s).
  - *Fase 12 (Estrela do Oceano):* Estrela de 5 pontas exigindo navegação em pontas estreitas (80s).
- **Tier 4 (Fases 13 a 16) — Maestria & Economia:**
  - *Fase 13 (Tridente de Netuno):* Base sul com 3 hastes longas e alta concentração de trigo (80s).
  - *Fase 14 (Coração Selvagem):* Silhueta cardioide matemática com núcleo florido (80s).
  - *Fase 15 (Passadiço dos Abismos):* 4 ilhotas em degraus interligadas por pontes estreitas (85s).
  - *Fase 16 (Fortaleza Espiral):* Espiral em caracol contínuo até o santuário central (85s).
- **Tier 5 (Fases 17 a 20) — Níveis Épicos & Clímax:**
  - *Fase 17 (Tabuleiro Proibido):* Mosaico de 9 plataformas interconectadas por 12 pontes (90s).
  - *Fase 18 (Santuário Solar):* Disco solar central com 8 satélites radiais (90s).
  - *Fase 19 (Labirinto do Minotauro):* Malha de ruelas estreitas com trigo e 28 rochas navegáveis (95s).
  - *Fase 20 (A Grande Coroa Real):* Monumental coroa de 5 pontas, pátio real e 222 plantas para coroação triunfal (110s).

### 2.2 Gerador Automatizado & Validador de Integridade
- Criado o script [`scripts/tools/generate_levels.js`](../../scripts/tools/generate_levels.js) que executa o algoritmo oficial de Autotile (`IslandAutotiler`) e exporta os arquivos JSON canônicos com formatação e UTF-8 sem BOM para `res://data/levels/level_01.json` até `level_20.json`.
- Criado o script [`scripts/tools/verify_levels.js`](../../scripts/tools/verify_levels.js) que audita automaticamente todos os arquivos JSON quanto a limites de grid, spawn sobre terra, sem colisão com rochas e presença balanceada de metas.

### 2.3 Suporte no HUD e Ciclo Mestre de Fases
- Adicionado o botão `NextBtn` ("Próxima Fase ➔") no `VictoryModal` de [`scenes/ui/hud.tscn`](../../scenes/ui/hud.tscn) e conectado dinamicamente em [`scripts/ui/hud.gd`](../../scripts/ui/hud.gd).
- Atualizado `GameManager.next_level()` em [`scripts/core/game_manager.gd`](../../scripts/core/game_manager.gd) para reiniciar triunfalmente no Ciclo Mestre (Fase 1) após a conclusão da Fase 20, preservando todo o progresso de moedas e upgrades adquiridos na Oficina.

---

## 3. Validação e Resultados

1. **Testes Automatizados:** 100% de aprovação no validador `verify_levels.js` em todas as 20 fases.
2. **Zero Warnings:** Total conformidade com as diretrizes do Godot 4 e `GEMINI.md`.
3. **Versão do Projeto:** Incremento para `v0.6.0` em `project.godot`.
