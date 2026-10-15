# Melhoria 015: Família de Lâminas Estreladas Geométricas (3, 4, 5 e 6 Pontas) e Amarelo Vibrante [v0.3.8] ⭐🤖

## 1. Visão Geral e Contexto
Nesta melhoria, atendemos às seguintes solicitações do usuário:
1. **Intensificação da Cor Amarela do Robô:** Ajuste do material `M_Carcaca_Amarela` no Blender para um amarelo industrial/arcade mais saturado, quente e vibrante, eliminando o tom pálido/bege anterior.
2. **Nova Lâmina de 5 Pontas (Tier 3):** Modelagem de uma estrela geométrica regular de 5 pontas com furo circular de montagem no centro, baseada na referência visual enviada.
3. **Reformulação das Lâminas de 3 e 4 Pontas com Arestas Retas:** As lâminas de Tier 1 (3 pontas) e Tier 2 (4 pontas) foram remodeladas para adotar a mesma linguagem geométrica angular com arestas retas e furo central, estabelecendo uma família estética coesa.
4. **Nova Lâmina de 6 Pontas (Tier 4):** Modelagem de uma estrela geométrica de 6 pontas (hexagrama) com furo central para expansão do sistema de progressão.
5. **Uniformização da Cor em Aço Cinza:** Todas as lâminas compartilham o mesmo acabamento metálico em aço cinza reflexivo (`M_Aco_Lamina`).

---

## 2. Implementações Realizadas

### A. Calibração Cromática no Blender (`grass_bot_00.blend`)
- **`M_Carcaca_Amarela`:** Base color ajustado para `(1.0, 0.48, 0.0, 1.0)` em espaço linear com roughness fosco suave de `0.70`, garantindo saturação expressiva e destaque visual no gramado.
- **`M_Aco_Lamina`:** Padronizado para `(0.75, 0.77, 0.80, 1.0)`, metallic `0.88` e roughness `0.38` para reflexos de corte nítidos.

### B. Modelagem Paramétrica das 4 Lâminas Estreladas
Todas as 4 lâminas foram geradas a partir de malhas quad-based com diâmetro máximo de corte unificado:
- **Alcance Máximo:** $R_{\text{tip}} = 1.66\text{m}$ (equivalente a $1.18\text{m}$ na Godot sob `VisualPivot.scale = 0.7`).
- **Furo Central de Fixação:** $R_{\text{hole}} = 0.29\text{m}$ (contornando o cubo do `blade_container`).
- **Espessura e Fio:** $0.042\text{m}$ com chanfro de corte via modificador `Bevel` (offset de $0.0035\text{m}$) e `EdgeSplit` a $40^\circ$.
- **Alinhamento Frontal:** Tip inicial orientada rigorosamente para $+Y$ ($90^\circ$), garantindo simetria bilateral exata ao longo de $X = 0$.

| Nó no glTF | Geometria | Raio do Vale ($R_{\text{valley}}$) | Material |
| :--- | :--- | :--- | :--- |
| **`blade_tier_1`** | Estrela de 3 pontas (triangular) | $0.58\text{m}$ | `M_Aco_Lamina` (cinza) |
| **`blade_tier_2`** | Estrela de 4 pontas (cruz ninja) | $0.63\text{m}$ | `M_Aco_Lamina` (cinza) |
| **`blade_tier_3`** | Estrela regular de 5 pontas | $0.634\text{m}$ (proporção áurea $0.382$) | `M_Aco_Lamina` (cinza) |
| **`blade_tier_4`** | Estrela de 6 pontas (hexagrama) | $0.70\text{m}$ (proporção $0.422$) | `M_Aco_Lamina` (cinza) |

### C. Integração e Suporte no Godot 4
- **Exportação glTF:** Exportada conforme o Mandamento 12 com `export_apply=True` e `export_yup=True` para `assets/models/grass_bot.glb`.
- **`scripts/cutter/cutter.gd`:** Adição de `@onready var blade_tier_4` e chaveamento de visibilidade para 4 patamares.
- **`scripts/core/upgrade_manager.gd`:** Mapeamento de 4 tiers no método `get_blade_tier()` (níveis 1-2, 3-4, 5-6, 7+) e nomenclatura estelar correspondente.

---

## 3. Validação e Qualidade
- **Zero Warnings / Zero Erros:** Verificado em execução de debug pelo Godot MCP (`run_project` e `get_debug_output`).
- **Consistência Estética:** Todas as 4 lâminas compartilham proporções harmônicas e o mesmo material cinza de aço, com rotação contínua a 1200°/s.
