# Melhoria 154: Polimento de Ícones UI, Estrelas de Vitória Vetoriais e Legibilidade da Barra da Lâmina

## 📌 Contexto & Motivação
A partir do feedback do usuário acompanhado de capturas de tela do jogo no navegador/mobile, identificamos pontos críticos de alinhamento, estética e legibilidade na interface:
1. **Ícone da Collection:** Substituição do ícone de lâmpada pelo ícone de planta/folha (`icon_leaf.svg`) na barra de navegação inferior.
2. **Oficina/Garage:** O ícone de moeda no botão de compra estava excessivamente afastado do valor numérico, e o título carecia do ícone de ferramenta (`icon_wrench.svg`).
3. **Botões da Home:** O botão "Level 1" e seu ícone de play, bem como o botão "MAP" e o pin, possuíam grande espaçamento vazio decorrente do alinhamento padrão em botões largos da Godot.
4. **Estrelas de Vitória:** Os nós de estrelas estavam configurados como `Label` com emoji `"⭐"`, gerando caracteres substitutos (tofu `[2B 50]`) na compilação WebAssembly.
5. **HUD Timer:** Adição de ícone de relógio analógico clássico ao lado do cronômetro de partida.
6. **Legibilidade da Barra da Lâmina (3D):** O texto "MAX" e níveis na barra flutuante utilizavam baixa resolução (140x24) e texto claro sobre fundo dourado/amarelo, tornando-se ilegíveis.

---

## 🛠️ Alterações Implementadas

### 1. Ícone da Collection (`bottom_nav_bar.tscn`)
- Alterada a textura do botão `BtnCollection` de `icon_collection.svg` para `icon_leaf.svg`.

### 2. Título e Alinhamento na Garage (`tab_garage.tscn` & `tab_garage.gd`)
- Adicionado container `TitleBar` centralizado contendo `icon_wrench.svg` (28x28) ao lado do título `"Oficina do Bot"`.
- O botão `BuyBtn` passou a conter um `HBoxContainer` interno centralizado (mouse_filter=ignore), mantendo o ícone de moeda e o custo adjacentes (espaçamento de 6px).

### 3. Agrupamento Centralizado na Home (`tab_home.tscn` & `tab_home.gd`)
- Reformulados os botões `PlayBtn` e `ToggleViewBtn` para conterem containers horizontais internos (`HBoxPlay` e `HBoxToggle`) com alinhamento centralizado.
- O texto "Level 1" e o triângulo de Play agora ficam colados no centro; o ícone de mapa e a label "MAP" ficam agrupados de forma compacta e equilibrada.

### 4. Estrelas de Vitória Vetoriais (`hud.tscn` & `hud.gd`)
- Convertidos os nós `Star1`, `Star2` e `Star3` de `Label` para `TextureRect` utilizando `icon_star.svg` vetorial com `expand_mode = 1` e `stretch_mode = 5`.
- Preservada a animação de entrada com bounce e pop sonoro em `hud.gd`, eliminando 100% dos tofu boxes `[2B 50]`.

### 5. Ícone de Relógio no HUD (`hud.tscn` & `hud.gd`)
- Baixado o ícone oficial `icon_clock.svg` (Icons8).
- Adicionado `HBoxTimer` dentro de `TimerContainer` no HUD com o ícone de relógio (20x20) à esquerda do tempo `TimerLabel`.

### 6. Contraste e Alta Resolução na Barra da Lâmina (`blade_progress_bar.tscn` & `blade_progress_bar.gd`)
- Resolução do `SubViewport` dobrada de 140x24 para 280x52, com `pixel_size = 0.003` no `Sprite3D`.
- Estilização com cantos arredondados (10px) e borda de 2px.
- No estado "MAX": fundo dourado vibrante e tipografia em cinza-escuro/chumbo profundo (`#141A24`) sem outline, garantindo contraste absoluto sobre o ouro e excelente visibilidade em qualquer ângulo de câmera.
- Nos níveis 1 a 5: texto branco com contorno preto espesso (6px) sobre a barra verde-limão.

---

## 🏷️ Versão & Validação
- **Game SemVer:** Incrementado para `v0.12.80-alpha`.
- **Godot Headless Import & Test:** 0 warnings e 0 erros.
- **Exportação Web:** Build atualizada com sucesso em `build/web/`.
