# Melhoria 130: Correção da Ancoragem e Balanço do Trigo Invertido 🌾🤖

## 1. Resumo Executivo
- **Identificação do Problema:** O usuário reportou que as hastes de trigo (`wheat_01.glb`) estavam visualmente invertidas durante a animação: a parte inferior (raiz no solo) balançava intensamente, enquanto a parte superior (espiga de trigo) ficava completamente travada/estática.
- **Diagnóstico Técnico de Baixo Nível:**
  1. A malha do trigo (`wheat_01.glb`) possui coordenadas UV onde $UV.y$ é matematicamente invertido em relação à altura do mundo ($Y$): na base em contato com o solo ($Y = 0.0$), $UV.y = 1.0$; na ponta superior da espiga ($Y = 1.10$), $UV.y = 0.0$.
  2. Como o shader `interactive_grass.gdshader` computava a curvatura diretamente como $h = \text{clamp}(UV.y, 0.0, 1.0)$ e $\text{bend\_factor} = \text{smoothstep}(0.06, 1.0, h)^2$, a base no solo recebia $\text{bend\_factor} = 1.0$ (balanço máximo com vento e repulsão violenta ao toque da lâmina), enquanto o topo recebia $\text{bend\_factor} = 0.0$ (travamento absoluto como uma âncora fixa).
  3. O gradiente de cores verticais e o rim lighting também estavam invertidos de cabeça para baixo para o trigo.
  4. O exportador glTF gravou os atributos `COLOR` do trigo como `(0, 0, 0, 1)` (preto total), o que ativava indevidamente o branch de atributos assados com ângulo de fase estático zero para todos os trigos da ilha.
- **Solução Implementada:**
  1. Adicionado o parâmetro booleano `uniform bool invert_height = false;` ao shader `interactive_grass.gdshader`.
  2. Computação uniforme de $h = \text{clamp}(\text{invert\_height} ? (1.0 - UV.y) : UV.y, 0.0, 1.0)$ em `vertex()`, `fragment()` e `light()`.
  3. No material `interactive_wheat_material.tres`, ativado `shader_parameter/invert_height = true`.
  4. Refinada a detecção de atributos de vértice com verificação de preto absoluto (`is_all_black`), atribuindo ao trigo balanço espacial orgânico baseado nas coordenadas do tufo no mundo (`world_vert.x * 1.7 + world_vert.z * 2.3`).
  5. Teste automatizado dedicado `tests/test_wheat_shader.gd` validando $bend\_factor = 0.0$ na base e $1.0$ na espiga com 0 warnings e 0 erros.

---

## 2. Análise Técnica e Causa Raiz

### Mapeamento UV e Geometria do Trigo
Inspeção analítica via script Godot na malha `wheat_01.glb`:
```
min_y: 0.0 (UV.y = 1.0)
max_y: 1.10 (UV.y = 0.0)
```
Em contraste com a grama (`grass_01.glb`), onde:
```
min_y: 0.0 (UV.y = 0.0)
max_y: 1.025 (UV.y = 1.0)
```
Ao alimentar o modelo de trigo com a fórmula padrão de grama, as extremidades ficavam trocadas:
- **Antes:**
  - Base da raiz ($Y = 0.0$): $UV.y = 1.0 \implies h = 1.0 \implies \text{bend\_factor} = 1.0$ (deslocamento caótico ao solo).
  - Espiga superior ($Y = 1.10$): $UV.y = 0.0 \implies h = 0.0 \implies \text{bend\_factor} = 0.0$ (estático no ar).
- **Depois (com `invert_height = true`):**
  - Base da raiz ($Y = 0.0$): $raw\_h = 1.0 - 1.0 = 0.0 \implies \text{bend\_factor} = 0.0$ (base 100% ancorada ao solo).
  - Espiga superior ($Y = 1.10$): $raw\_h = 1.0 - 0.0 = 1.0 \implies \text{bend\_factor} = 1.0$ (balanço livre e fluido).

---

## 3. Modificações em Arquivos

1. **`shaders/interactive_grass.gdshader`:**
   - Adicionado `uniform bool invert_height = false;`.
   - Ajustado cálculo de altura no `vertex()`:
     ```glsl
     float raw_h = invert_height ? (1.0 - UV.y) : UV.y;
     float h = clamp(raw_h, 0.0, 1.0);
     ```
   - Refinada detecção de atributos de vértice:
     ```glsl
     bool is_all_black = (COLOR.r < 0.001 && COLOR.g < 0.001 && COLOR.b < 0.001);
     bool is_all_white = (COLOR.r > 0.999 && COLOR.g > 0.999 && COLOR.b > 0.999);
     bool has_baked_attr = !is_all_black && !is_all_white;
     ```
   - Corrigido gradiente no `fragment()` e no `light()` usando a mesma variável `raw_h`.

2. **`shaders/interactive_wheat_material.tres`:**
   - Adicionada a propriedade `shader_parameter/invert_height = true`.

3. **`docs/02_entidades_e_mecanicas/SISTEMA_DE_VEGETACAO.md`:**
   - Documentado o mapeamento UV com inversão e o parâmetro `invert_height`.

4. **`tests/test_wheat_shader.gd`:**
   - Teste unitário de ancoragem física que valida matematicamente que o trigo possui deslocamento nulo na base e amplitude total na espiga.

---

## 4. Verificação e Testes
- **Teste Unitário Automatizado:** `tests/test_wheat_shader.gd` executado com sucesso:
  - Base bend factor: `0.0`
  - Tip bend factor: `1.0`
  - `invert_height` no trigo: `true`
  - `invert_height` na grama: `<null>` (falso por padrão).
- **Teste de Gameplay:** `tests/test_wheat_level_02.tscn` executado e aprovado com 0 erros/warnings.
- **Teste de Metas e Painel:** `tests/test_editor_goals_and_panel.tscn` executado e aprovado com 0 erros/warnings.
- **Teste de Progressão da Lâmina:** `tests/test_blade_progression.tscn` executado e aprovado com 0 erros/warnings.
