# Melhoria 177: Contraste Aprimorado das Rosas, Rosa Negra 40% Mais Escura e Nova Variação Rosa Vinho 🌹🍷

**Data:** 05/11/2026  
**Versão:** `v0.12.123-alpha`  
**Escopo:** Visual 3D das Rosas, Shaders, Paleta do Editor de Fases, Level Loader e VegetationGrid  

---

## 🎯 Objetivo da Melhoria

Atender à solicitação de refinamento visual das rosas marcadas na avaliação:
1. **Contraste Acentuado entre Base e Ponta das Pétalas:** Redução de achatamento e aumento de definição do gradiente da base para a ponta de cada pétala individual nas rosas Vermelha, Branca, Amarela e Azul.
2. **Rosa Negra 40% Mais Escura:** Escurecimento em 40% das tonalidades da Rosa Negra (`flower_rose_black`), criando uma verdadeira rosa ônix/veludo negro profundo.
3. **Nova Variação Rosa Vinho Nobre:** Preservação da cor bordô/vinho aveludado anterior no catálogo oficial sob o identificador `flower_rose_wine` ("Rosa Vinho Nobre" 🍷), totalizando **7 variações nobres** de rosas no jogo.

---

## 🔬 Diagnóstico e Solução Técnica

### 1. Diagnóstico da Exportação glTF 2.0 no Blender
- Identificou-se que o atributo de cor nativo do Blender criado como `BYTE_COLOR` levava o exportador glTF a descartar o canal Alfa ao gerar `COLOR_0`, exportando apenas `VEC3` (`A = 1.0` fixo em todas as faces).
- **Correção:** Criação de camada `float_color` explícita (`bm.loops.layers.float_color.new("Color")`) e exportação forçada via `export_vertex_color='ACTIVE'`, garantindo 4 canais `RGBA` (`VEC4`) de precisão de ponto flutuante.

### 2. Dual Gradient (Per-Island + Global Radial Span)
- Para garantir que tanto as pétalas externas quanto as internas exibam contraste nítido da base até a borda externa, o canal $A$ foi modelado como combinação convexa:
  $$A = 0.65 \times t_{local} + 0.35 \times t_{global}$$
  onde $t_{local}$ é a extensão radial da ilha individual da pétala ($d - \min_{isl} / \max_{isl} - \min_{isl}$) e $t_{global}$ é a distância relativa ao núcleo da flor.

### 3. Calibração Cromática dos Materiais e Shaders
- **Vermelha Nobre (`flower_rose`):** Base carmim profundo (`#47030F`) $\to$ Pontas rubi vivo (`#FF2652`).
- **Branca Imperial (`flower_rose_white`):** Base mel âmbar quente (`#B3946B`) $\to$ Pontas branco pérola puro (`#FFFFFF`).
- **Amarela Dourada (`flower_rose_yellow`):** Base âmbar fogo (`#C73300`) $\to$ Pontas amarelo canário radiante (`#FFF226`).
- **Azul Mística (`flower_rose_blue`):** Base azul noturno índigo (`#081459`) $\to$ Pontas azul celeste gelo (`#61CCFF`).
- **Rosa Vinho Nobre (`flower_rose_wine` - Nova):** Base rubi profundo (`#1A050F`) $\to$ Pontas vinho aveludado (`#661438`).
- **Rosa Negra (`flower_rose_black`):** 40% mais escura: base ônix carvão (`#0A0409`) $\to$ Pontas veludo negro profundo (`#330D1F`).
- **Rosa Pêssego Salmão (`flower_rose_peach`):** Mantida conforme aprovada.

---

## 🛠️ Arquivos Modificados / Criados

- `assets/models/flower_02_rose.glb`: Re-exportado com float RGBA dual-gradient ativo.
- `shaders/flower_rose_material.tres`: Contraste ampliado.
- `shaders/flower_rose_white_material.tres`: Contraste ampliado com centro âmbar e pontas brancas.
- `shaders/flower_rose_yellow_material.tres`: Contraste ampliado com centro fogo e pontas limão.
- `shaders/flower_rose_blue_material.tres`: Contraste ampliado com base navy e pontas cerúleas.
- `shaders/flower_rose_black_material.tres`: 40% mais escura.
- `shaders/flower_rose_wine_material.tres`: **Novo material** para a Rosa Vinho.
- `scripts/editor/tile_palette_db.gd`: Adicionado `flower_rose_wine` às variações e atualizado cores.
- `scripts/plants/plant.gd`: Mapeadas cores em `get_flower_colors`.
- `scripts/plants/vegetation_grid.gd`: Registrado em `FLOWER_MATERIALS`, `VEG_TYPES`, `_ensure_flower_meshes` e `_resolve_clipping_color`.
- `scripts/level/level_json_loader.gd`: Registrado em `FLOWER_VARIATION_MATERIALS` e `OBJECT_SCENES`.
- `tests/test_flower_variations_editor.gd`: Atualizado para validar 7 variações.
- `docs/02_entidades_e_mecanicas/SISTEMA_DE_VEGETACAO.md`: Tabela canônica de flores atualizada.

---

## 🧪 Validação Automatizada

- **Testes de Variação no Editor (`test_flower_variations_editor.tscn`):** 7 variações validadas com 0 erros.
- **Teste de Desprendimento de Pétalas (`test_flower_detach.gd`):** Sucesso em todas as 8 espécies de flor.
- **Zero Warnings:** Console Godot mantido limpo.
