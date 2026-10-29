# Melhoria 157: Recriação Fiel do Botão Heroico "JOGAR - Fase X ▶" na Home 🎮✨

## 🎯 Contexto e Objetivo
O usuário enviou uma captura de referência contendo um botão estilizado de ação principal:
- Texto em azul-marinho profundo: `"JOGAR - Fase 3 ▶"`.
- Geometria marcante com corte angular inclinado à esquerda e ponta em chevron (seta indicativa) à direita.
- Superfície vibrante em gradiente verde-lima/chartreuse com reflexo vítreo superior.
- Base 3D extrudada em verde-escuro folha com chanfro inferior espesso e flare estelar dourado no centro.
- Molduras cyber tech flutuantes em azul-petróleo escuro com linhas neon ciano/lima contornando o canto inferior esquerdo e o chevron superior-direito.
- O objetivo foi recriar com precisão pixel-perfect esse componente no Hub Principal (`TabHome`), tornando-o dinâmico para a fase selecionada e integrando compressão física tátil, som e feedback háptico.

---

## 🛠️ Alterações Implementadas

### 1. Criação dos Assets Vetoriais Canônicos (SVG)
- **`res://assets/ui/btn_play_banner.svg`**:
  - Dimensões canônicas $430 \times 126$, com `viewBox="14 16 430 126"`.
  - Gradiente de superfície elétrico: `#f8ff0a` (topo) $\rightarrow$ `#ecff05` $\rightarrow$ `#d4ff02` $\rightarrow$ `#b6fa00` (base da face).
  - Chanfro angular à esquerda inclinado a $\sim 62^\circ$, ponta de chevron à direita com cantos arredondados.
  - Brilho especular superior em arco suave (`top_gloss_grad`).
  - Base 3D inferior espessa em gradiente verde folha (`#38b620` a `#187212`) com borda escura inferior e glint dourado central com centro branco.
  - Molduras cyber tech escuras (`#0b2834`) com contornos neon luminosos (`#00f5a8`).
- **`res://assets/ui/btn_play_banner_pressed.svg`**:
  - Versão comprimida da peça: face rebaixada em $6\text{px}$, base 3D comprimida para simular pressão física de arcade.
- **`res://assets/icons/icon_play_triangle.svg`**:
  - Ícone de triângulo sólido reproduzindo exatamente o play da referência, colorido em azul-marinho profundo (`#071826`).

### 2. Componente Dedicado `CyberPlayButton` (`scripts/ui/cyber_play_button.gd`)
- Herda de `Button` nativo da Godot 4, mantendo 100% de compatibilidade com sinais (`pressed`, `button_down`, `button_up`).
- Alternância imediata entre `BgNormal` e `BgPressed` ao pressionar.
- Rebaixamento vertical do conteúdo interno (`hbox_play.position.y += 4.0`) durante o clique.
- Disparo de vibração háptica (`Input.vibrate_handheld(15)`) conforme Mandamento 8.
- Reprodução do SFX de confirmação (`AudioManager.play_sfx("confirm")`).
- Métodos auxiliares `set_level_number(lvl)` e `set_level_text(text)`.

### 3. Integração na Cena Home (`scenes/menu/tabs/tab_home.tscn` & `tab_home.gd`)
- `PlayBtn` atualizado para instanciar o `CyberPlayButton`, com tamanho mínimo confortável ($430 \times 126$).
- Tipografia em negrito pesado (`SystemFont` com `font_weight = 900`), cor `#071826`, tamanho 30pt.
- Formatação dinâmica `"JOGAR - Fase %d"` baseada na fase atual desbloqueada pelo jogador ou selecionada no mapa.
- Botão complementar de alternância (`ToggleViewBtn` - `[ 🗺️ MAP ]`) redimensionado e reposicionado harmoniosamente ao lado do botão principal ($88 \times 88\text{px}$), com borda ciano-neon condizente com a paleta.

---

### 4. Ajuste Fino de Enquadramento e Correção do Corte no Canto Esquerdo
- **Diagnóstico:** O `viewBox` anterior dos SVGs iniciava em $x=14$, o que causava o recorte vertical abrupto das coordenadas mais externas do suporte cyber inferior-esquerdo (que atingiam $x=5$ a $8$ com espessura de traço de $4\text{px}$).
- **Resolução:** O `viewBox` foi expandido para `viewBox="0 10 450 138"`, garantindo margem respirável em todos os 4 eixos (topo, base, esquerda e direita).
- O botão em `tab_home.tscn` foi redimensionado para `Vector2(440, 135)`, preservando a proporção nativa da peça e eliminando 100% de qualquer recorte visual.

### 5. Elevação da Parte Interna & Moldura Estática (Efeito de Afundamento Mecânico)
- **Elevação do Corpo Interno:** O topo da face amarela e base verde foi elevado em $6\text{px}$ (de $y=36$ para $y=30$), diminuindo a folga para com a linha neon superior e deixando o botão mais imponente e volumoso.
- **Moldura Externa 100% Estática no Pressionamento:**
  - O suporte superior-direito com a linha ciano neon e o suporte angular inferior-esquerdo permanecem rigorosamente idênticos e fixos entre o estado normal ([`btn_play_banner.svg`](../../assets/ui/btn_play_banner.svg)) e o estado pressionado ([`btn_play_banner_pressed.svg`](../../assets/ui/btn_play_banner_pressed.svg)).
  - Ao pressionar (`button_down`), **somente o miolo amarelo, base 3D e rótulo de texto descem em $7\text{px}$** (`PRESS_SINK_OFFSET = 7.0`), criando a sensação física nítida de que o botão afunda para dentro do seu chassi tecnológico sem mover a carcaça exterior.

---

## 📊 Validação e Conformidade
1. **Zero Warnings Estrito (Mandamento 1):** Compilação e execução via Godot 4.7 headless sem warnings ou erros.
2. **Reimportação Atômica (Mandamento 12):** Executado `godot --headless --editor --quit` para regenerar o cache de todos os novos SVGs.
3. **Teste Visual:** Captura de tela dos estados normal e pressionado gerada e validada em `state_normal_preview.png` e `state_pressed_preview.png`.
4. **SemVer:** Incrementado para `v0.12.86-alpha`.
