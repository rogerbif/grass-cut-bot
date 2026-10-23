# Melhoria 081: Números Flutuantes no Círculo Interno da Lâmina em 3 Pontos (Esquerda, Centro e Direita) [v0.12.5-alpha] 💥🌿

Este documento registra a implementação do posicionamento direcional dos **Números Flutuantes Cartoon 3D** ancorados no **círculo interno da lâmina** do robô cortador (**Cutter Bit**), distribuídos entre **3 setores (Esquerda, Centro e Direita)** com base na projeção lateral do corte, e a introdução da nova coreografia em fases: **surgir em fase (fade-in) $\rightarrow$ crescer $\rightarrow$ diminuir $\rightarrow$ subir flutuando $\rightarrow$ desaparecer em fase (fade-out)**.

---

## 📋 Resumo Executivo
- **Data da Conclusão:** Outubro de 2026
- **Versão SemVer:** `v0.12.5-alpha` (Code: `1205`)
- **Domínio:** Gameplay, Game Feel, Efeitos Visuais 3D e Dinâmica de Cortador
- **Objetivos Entregues:**
  1. **Ancoragem no Círculo Interno da Lâmina:**
     - Em vez de surgirem no solo espalhados sobre o tufo ceifado, os números surgem diretamente sobre o anel interno da serra circular do robô ($R \approx 0.40\text{m} \dots 0.48\text{m}$, $Y \approx 0.28\text{m}$), garantindo proximidade visual imediata com a ação do cortador.
  2. **3 Setores Direcionais Dinâmicos (Esquerda, Centro e Direita):**
     - O robô mede a componente lateral do corte (`to_cut.dot(right)`) relativa ao seu ângulo frontal (`robot_body.rotation.y`);
     - **Esquerda:** `forward * 0.42 - right * 0.38` (corte no flanco esquerdo da lâmina);
     - **Centro:** `forward * 0.50` (corte frontal central do bico);
     - **Direita:** `forward * 0.42 + right * 0.38` (corte no flanco direito da lâmina).
  3. **Nova Coreografia em Fases (*Fade In $\rightarrow$ Scale Pop $\rightarrow$ Settle $\rightarrow$ Float Up $\rightarrow$ Fade Out*):**
     - **Aparecer em fase:** Fade-in rápido de opacidade (`0.0 -> 1.0` em 0.08s);
     - **Crescer:** Expansão elástica de escala (`0.35 -> 1.30` em 0.10s com `TRANS_BACK`);
     - **Diminuir:** Assentamento suave para a escala base (`1.30 -> 1.0` em 0.08s);
     - **Subir:** Flutuação vertical de $+0.70\text{m}$ em 0.60s com `TRANS_QUAD`;
     - **Desaparecer em fase:** Desvanecimento suave de opacidade (`1.0 -> 0.0` em 0.28s) até a reciclagem no pool estático de 32 nós.
  4. **Grupo Global do Cortador:**
     - O robô se registra no grupo `"cutter"` no `_ready()`, permitindo busca limpa e desacoplada pelo gerenciador de efeitos 3D.
  5. **Zero Warnings & Estabilidade:**
     - 100% testado na Godot 4.7.1 via Godot MCP com 0 erros e 0 warnings no console.

---

## 🔍 Detalhamento Técnico das Modificações

### 1. `scripts/cutter/cutter.gd`
- Inclusão do nó no grupo `"cutter"` no `_ready()`.
- Criação do método público:
  ```gdscript
  func get_inner_blade_point(cut_pos: Vector3) -> Vector3
  ```
  Calcula os vetores `forward` e `right` a partir de `robot_body.rotation.y`, classifica o setor lateral e retorna o ponto 3D no círculo interno com micro-jitter de $\pm 0.03\text{m}$.

### 2. `scripts/effects/floating_coin_manager.gd`
- Adicionado helper `_get_cutter()` via grupo `"cutter"`.
- Inicialização do número com `scale = Vector3(0.35, 0.35, 0.35)` e `modulate:a = 0.0`.
- Tween orquestrado com:
  - Fade-in de opacidade (0.0 a 1.0 em 0.08s);
  - Expansão de escala para 1.30 em 0.10s (`TRANS_BACK`), seguida de contração para 1.0 em 0.08s (`TRANS_QUAD`);
  - Elevação vertical em Y de $+0.70\text{m}$ em 0.60s;
  - Sustentação (0.14s) e Fade-out de opacidade para 0.0 em 0.28s (`TRANS_QUAD`, `EASE_IN`);
  - Reciclagem automática e visibilidade desligada ao término.

---

## 🧪 Testes e Validação
- **MCP Godot Run:** Execução de `res://scenes/main.tscn` e `res://scenes/editor/level_editor.tscn` com 0 erros e 0 warnings no console.
- **Suíte de Testes:** Suítes de Save e Áudio executadas.
- **SemVer:** Atualizado para `v0.12.5-alpha` (Code: `1205`).
