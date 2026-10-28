# Melhoria 146: Paridade Total da Câmera Playtest F1 e Atalhos de Escala (S) e Rotação (R) com Teclas +/- e Shift (25°) 🎥📐🔄🌿

**Data:** 28 de Outubro de 2026  
**Versão:** `v0.12.72-alpha`  
**Status:** Concluído com Sucesso e Testado (100% Aprovado)

---

## 1. Contexto e Objetivos

O Editor de Fases In-Game para PC recebeu duas grandes melhorias de precisão de teste e ergonomia de modelagem:

1. **Paridade Absoluta da Câmera no Playtest (F1):**
   - No modo anterior, a câmera de teste no editor utilizava a própria câmera de prancheta (`EditorCamera`), com distância estática de $11.14\text{m}$, FOV 46 e cálculo dinâmico de `look_at_from_position` a cada frame em `_process`, fazendo com que a câmera oscilasse e o robô parecesse muito menor e distante do que no jogo real.
   - A demanda foi garantir que a visão de teste F1 seja exatamente idêntica à experiência de jogo mobile.
2. **Sistema Unificado de Ajuste com Atalho `S` (Escala), `R` (Rotação), Teclas `+`/`-` e `Shift` (25°):**
   - O atalho `S` passa a ativar o ajuste de escala do pincel.
   - As teclas `+` e `-` aumentam e diminuem a escala (com saltos de 5 com `Shift`).
   - O atalho `R` ativa a rotação e gira no sentido horário.
   - As teclas `+` e `-` giram para a direita (horário) e esquerda (anti-horário).
   - O incremento angular padrão de $5^\circ$ passa a ser de **$25^\circ$** quando a tecla `Shift` estiver pressionada.

---

## 2. Diagnóstico Comparativo: Câmera Playtest F1 vs Câmera do Jogo

| Parâmetro | Câmera Anterior do F1 (`EditorCamera`) | Nova Câmera do F1 (`PlaytestGameCamera`) | Paridade com `main.tscn` |
| :--- | :--- | :--- | :--- |
| **Script do Nó** | `editor_camera.gd` | `isometric_camera.gd` | **100% idêntico** |
| **Distância ao Cortador** | $11.14\text{m}$ (arbitrário e distante) | $6.0\text{m}$ (Lv 1) a $12.0\text{m}$ (Lv 6) | **Perfeita:** Escala com nível da lâmina |
| **FOV (Field of View)** | $46.0$ | $48.0$ | **Exato** |
| **Ângulo Isométrico (Pitch)** | Flutuante (wobble ao perseguir alvo) | Travado rigidamente em $-40.23^\circ$ | **Zero distorção** |
| **Physics Interpolation** | Roda em `_process` (render frame) | Roda em `_physics_process` sincrono com CharacterBody3D | **Suavidade mecânica pura** |
| **Feedback de Impacto** | Sem resposta a choques | Reage a `camera_shake` em colisões com rochas | **Idêntico ao jogo** |

---

## 3. Arquitetura do Sistema de Atalhos e Interface

### 3.1 Modos de Ajuste Rápido (`QuickAdjustMode`)
- `QuickAdjustMode.ROTATION` (0) e `QuickAdjustMode.SCALE` (1).
- Pressionar **`S`** (sem `Ctrl`) define o modo ativo para Escala e destaca a caixa na UI com borda verde-água brilhante.
- Pressionar **`R`** define o modo ativo para Rotação e executa o giro para a direita.

### 3.2 Teclas Universais `+` e `-`
- Mapeamento completo de `KEY_PLUS`, `KEY_EQUAL`, `KEY_KP_ADD` e `KEY_MINUS`, `KEY_KP_SUBTRACT`:
  - **No Modo Escala:**
    - `+`: aumenta a escala em $+1$ (ou $+5$ se `Shift` estiver pressionado).
    - `-`: diminui a escala em $-1$ (ou $-5$ se `Shift` estiver pressionado).
    - Limitado rigidamente entre $1$ e $20$.
  - **No Modo Rotação:**
    - `+`: gira para a **DIREITA** (horário) em $+5^\circ$ (ou $+25^\circ$ com `Shift`; $+90^\circ$ no terreno).
    - `-`: gira para a **ESQUERDA** (anti-horário) em $-5^\circ$ (ou $-25^\circ$ com `Shift`; $-90^\circ$ no terreno).
    - Ângulos são normalizados no intervalo circular $[0^\circ, 359^\circ]$ via `posmod(deg, 360)`.

### 3.3 Barra Lateral Interativa
- **Escala:** Botão `➖ [-]`, Label `[S] Escala: %d` e Botão `➕ [+]`.
- **Rotação:** Botão `◀ [-]` (gira esquerda), Botão `🔄 Girar [R]: %d° (±5°/±25°)` e Botão `[+] ▶` (gira direita).
- Suporte a cliques diretos com mouse ou atalhos de teclado de forma transparente.

---

## 4. Validação e Resultados

- **Suíte de Câmera e Atalhos:** [`tests/test_editor_camera_and_shortcuts.tscn`](../../tests/test_editor_camera_and_shortcuts.tscn) com 4 testes automatizados aprovados com **100% de sucesso**.
- **Suíte de Regressão do Editor:** [`tests/test_editor_enhancements.tscn`](../../tests/test_editor_enhancements.tscn) com 7 testes aprovados com **100% de sucesso**.
- **Godot Console:** 0 warnings e 0 erros.
