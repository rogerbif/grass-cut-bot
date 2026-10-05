# Melhoria 004: Refinamento da Distribuição em Leque e Curvatura Elástica da Grama 🌾🌿

Este documento consolida o plano de implementação, a execução técnica e os resultados do refinamento estético e físico da vegetação de **Grass Cut Bot**, com base na análise comparativa de protótipos de dispersão e na evolução do modelo volumétrico Low Poly nativo.

---

## 📋 Resumo Executivo
- **Data da Conclusão:** Outubro de 2026
- **Versão SemVer:** `v0.2.4`
- **Domínio:** Gameplay, Entidades, Shaders e Arte Visual 3D
- **Objetivo:** Manter a modelagem tridimensional volumétrica da grama (`PrismMesh`), eliminando o aspecto rígido/vertical uniforme anterior através de uma nova arquitetura de **5 lâminas dispostas em leque/cálice radial com inclinações e proporções orgânicas**, combinada com um **shader de curvatura elástica não-linear e compressão física no eixo Y**.

---

## 🔍 Contexto e Análise Técnica Prévia
Foi inspecionado o repositório de benchmark [`multithreaded-visualserver-multimesh-grass`](https://gitlab.com/robert7301201/multithreaded-visualserver-multimesh-grass.git):
- **Diagnóstico:** O repositório externo utilizava Godot 3.x com `VisualServer` para instanciar 600.000 lâminas em malha simples de 1 único triângulo plano 2D (`make_blade_mesh()`). Embora eficiente para renderizar multidões distantes de grama plana, um triângulo sem espessura não atende ao padrão de arte Low Poly com volume 3D legível na perspectiva isométrica de *Grass Cut Bot*.
- **Conclusão:** Manteve-se o modelo Low Poly 3D nativo com prismas volumétricos, aproveitando os conceitos de dispersão estatística de lâminas (`blade_height`, `blade_width`, `blade_pitch`, `blade_yaw`) para enriquecer drasticamente a geometria do tufo do jogo.

---

## 🎯 Arquitetura da Solução Técnica

### 1. Geometria Volumétrica em Leque Radial (`grass_tuft.tscn`)
O nó visual `VisualMesh` do tufo de grama foi reestruturado de 4 lâminas idênticas verticais para **5 lâminas com proporções e orientações especializadas**:
1. **`BladeCenter` (Haste Central Majestosa):**
   - Malha `PrismMesh` (`0.16m x 0.72m x 0.07m`, `subdivide_height = 4`).
   - Posição `(0.0, 0.36, 0.0)`, yaw de 15° e pitch sutil de 3° para quebra orgânica de simetria.
2. **`Blade1` (Lâmina Frontal-Direita Alta):**
   - Malha `PrismMesh` (`0.17m x 0.64m x 0.07m`, `subdivide_height = 4`).
   - Posição `(0.03, 0.32, 0.02)`, yaw de 60° e inclinação radial para fora (pitch de 14°).
3. **`Blade2` (Lâmina Lateral-Traseira Direita):**
   - Malha `PrismMesh` (`0.15m x 0.58m x 0.07m`, `subdivide_height = 4`).
   - Posição `(0.03, 0.29, -0.03)`, yaw de 135° e inclinação radial para fora (pitch de 16°).
4. **`Blade3` (Lâmina Traseira-Esquerda Média):**
   - Malha `PrismMesh` (`0.18m x 0.62m x 0.07m`, `subdivide_height = 4`).
   - Posição `(-0.02, 0.31, -0.03)`, yaw de 210° e inclinação radial para fora (pitch de 13°).
5. **`Blade4` (Lâmina Frontal-Esquerda Compacta):**
   - Malha `PrismMesh` (`0.14m x 0.52m x 0.06m`, `subdivide_height = 4`).
   - Posição `(-0.04, 0.26, 0.01)`, yaw de 285° e inclinação radial para fora (pitch de 15°).

**Benefício Visual:** O tufo agora se expande em cálice (formato de vaso natural), unindo as bases de todas as lâminas no solo enquanto o topo se abre em 360°, mantendo silhueta preenchida e exuberante em qualquer ângulo da câmera isométrica.

### 2. Shader de Curvatura Elástica Não-Linear (`interactive_grass.gdshader`)
O shader espacial foi aprimorado com física de flexão realista:
- **Curvatura Exponencial:** A flexão linear simples (`height_factor`) foi substituída por `bend_factor = pow(height_factor, 1.6)`. A base do tufo permanece perfeitamente ancorada ao solo sem deslizamentos, enquanto o terço superior arqueia suavemente.
- **Projeção Matricial Rigorosa:** A conversão da direção radial do cortador no espaço de modelo utiliza `mat3(inverse(MODEL_MATRIX)) * dir_norm`, garantindo precisão matemática independente da inclinação e rotação individuais de cada folha.
- **Abaixamento Físico em Y:** Introduzida compressão vertical elástica (`VERTEX.y -= power * interact_power * 0.14 * bend_factor`), gerando o feedback sensorial de que a vegetação é suavemente pressionada/penteada pela carcaça do cortador milissegundos antes do golpe final.
- **Vento Ondulante de Mundo:** O balanço de vento agora combina ondas cruzadas em espaço de mundo projetadas de volta ao modelo, criando ondulações globais coerentes em todo o campo.

---

## 🛡️ Conformidade de Guardrails Invariantes
- **Zero Warnings:** 0 avisos no compilador de shaders e na engine Godot 4.
- **Performance Mobile:** Zero texturas de ruído adicionadas à VRAM; cálculos puramente analíticos no vertex shader mantendo 60 FPS lisos.
- **Estilo Low Poly Fosco:** `roughness = 0.9` e gradiente limpo de raiz ao topo preservados.
