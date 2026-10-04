# Melhoria 002: Shader de Grama Interativa com Flexão Radial e Vento Procedural (Técnica Arnklit) 🌿🤖

**Data:** 03/10/2026  
**Versão:** `v0.2.1-shader`  
**Autor:** Antigravity AI Pair Programmer & Usuário  

---

## 1. Contexto e Objetivo

Integrar a técnica de **Shader Interativo de Grama** inspirada no tutorial canônico de [Arnklit (Interactive Wind & Grass Shader)](https://www.youtube.com/watch?v=qcScJ_vgsGU), permitindo que a vegetação (grama verde, trigo e flores) reaja dinamicamente à presença do robô cortador, curvando-se para longe da lâmina antes do contato direto, além de apresentar oscilação suave de vento e gradiente de cor da raiz à ponta.

---

## 2. O Que Foi Desenvolvido

### 2.1 Shader Espacial e Injeção em Materiais Compartilhados
- Criado o shader espacial [`shaders/interactive_grass.gdshader`](../../shaders/interactive_grass.gdshader) configurado com `render_mode cull_disabled`.
- Utilizados parâmetros uniformes padrão (`uniform vec3 cutter_pos` e `uniform float cutter_interact_radius`), exatamente como na implementação canônica do Arnklit, eliminando qualquer dependência de registros manuais no `ProjectSettings` e evitando erros de compilação.
- No script [`cutter.gd`](../../scripts/cutter/cutter.gd), implementada a função `_update_shader_globals()` transmitindo a posição global do cortador e o raio dinâmico de interação (`blade_radius + 0.95m`) diretamente para os materiais compartilhados (`GRASS_MAT`, `WHEAT_MAT`, `FLOWER_MAT`) a cada frame com custo zero de CPU.


### 2.2 Física Visual de Curvatura e Vento
- No `vertex()` do shader:
  - Vértices convertidos para o espaço de mundo ($XZ$).
  - Vetor unitário apontando na direção oposta ao centro da serra.
  - Deformação atenuada via `smoothstep(cutter_interact_radius, 0.0, dist)`.
  - Altura vertical modulada (`1.0 - UV.y`), mantendo a base fixa ao solo enquanto apenas o topo das folhas/espigas se dobra.
  - Vento procedural com onda senoidal no tempo (`TIME`) gerando balanço suave contínuo.
- No `fragment()` do shader:
  - Gradiente vertical fosco Low Poly (`roughness = 0.9`) da raiz (tom escuro de oclusão) até o topo (iluminado e vibrante).

### 2.3 Materiais e Adaptação dos Tufos
- Criados os materiais dedicados:
  - [`shaders/interactive_grass_material.tres`](../../shaders/interactive_grass_material.tres) (Grama Verde)
  - [`shaders/interactive_wheat_material.tres`](../../shaders/interactive_wheat_material.tres) (Trigo Dourado)
  - [`shaders/interactive_flower_material.tres`](../../shaders/interactive_flower_material.tres) (Flores)
- Cenas atualizadas com subdivisões verticais para flexão suave:
  - [`scenes/plants/grass_tuft.tscn`](../../scenes/plants/grass_tuft.tscn)
  - [`scenes/plants/wheat_tuft.tscn`](../../scenes/plants/wheat_tuft.tscn)
  - [`scenes/plants/flower_tuft.tscn`](../../scenes/plants/flower_tuft.tscn)

### 2.4 Preservação da Mecânica de Colheita
- A detecção de corte radial (`BladeArea` no Layer 4) permanece ativa e exata.
- Ao entrar em contato físico com o disco de serra, a planta é cortada, emite partículas em arco parabólico, atualiza as cotas no HUD, concede moedas e encolhe com animação suave revelando o gramado limpo.

---

## 3. Validação e Testes Realizados

1. **Godot Headless Editor & Compilação de Shaders:**
   - Execução com `--editor --quit`: Código de saída 0, importação sem erros e 0 warnings.
2. **Execução Headless da Simulação da Partida:**
   - Execução com `--quit-after 5`: Código de saída 0, confirmação da atualização dos shader globals e execução sem crashes.
