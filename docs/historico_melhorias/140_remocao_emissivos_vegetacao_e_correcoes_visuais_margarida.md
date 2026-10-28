# Melhoria 140: Remoção de Emissivos em Vegetação e Correções Visuais da Margarida 🌿🌼

## 🎯 Objetivo e Contexto
1. **Auditoria e Remoção de Emissivos em Vegetação e Partículas:** Eliminação de brilho autoiluminado / emissão artificial (`EMISSION`, `vibrancy`, `emission_enabled`) em plantas, flores, grama e partículas de corte, assegurando conformidade estrita com o Mandamento 7 de estilo de arte Low Poly fosco/matte (`roughness = 0.85 ~ 0.95`). Preservação exclusiva de emissores que são funcionalmente luzes (LEDs dos olhos do robô, portal de teletransporte e anel de seleção do editor).
2. **Correção Topológica da Margarida (`flower_daisy`):** Resolução do problema visual em que as folhas superiores e cálice da margarida apresentavam manchas e pontas brancas. No modelo original, as ilhas `164..170` estavam com material de pétala (`Mat_Flower_Petals`). Foram reclassificadas canonicamente para `Flower_Leaves`, recebendo o material e tonalidade natural de folhagem.
3. **Calibração de Albedo das Folhas:** O material compartilhado `interactive_flower_leaves_material.tres` utilizava um verde excessivamente claro/neon (`Color(0.3, 0.78, 0.36)`) somado à autoemissão. Foi recalibrado para um verde natural, foliar e profundo (`Color(0.18, 0.52, 0.22)`), perfeitamente harmonizado com o gramado.
4. **Eliminação de Z-Fighting no Solo:** As folhas rasteiras dos modelos de flores que continham vértices em $Z \le 0$ colidiam no buffer de profundidade com o plano do terreno da ilha ($Y = 0.0$), gerando listras horizontais de Z-fighting. Foi aplicada uma elevação de segurança nos vértices inferiores ($Z \ge 0.003$, +3mm), eliminando 100% da sobreposição coplanar sem qualquer impacto na silhueta isométrica.

---

## 🛠️ Alterações Realizadas

### 1. Shaders e Materiais
- **`shaders/interactive_flower.gdshader`:**
  - Removido o uniform `vibrancy`.
  - Removida a linha `EMISSION = base_col * vibrancy;`.
  - Sombreamento puramente difuso toon fosco (`diffuse_toon`).
- **`shaders/interactive_grass.gdshader`:**
  - Removido o uniform `vibrancy`.
  - Removida a linha `EMISSION = base_surface * vibrancy;`.
- **`shaders/interactive_flower_leaves_material.tres`:**
  - Removido `shader_parameter/vibrancy = 0.1`.
  - Atualizado `petal_color` e `center_color` para `Color(0.18, 0.52, 0.22, 1)`.
- **`shaders/interactive_grass_*.tres` e `interactive_wheat_material.tres`:**
  - Removidos parâmetros legados `shader_parameter/vibrancy = 0.0` e garantida ausência de BOM UTF-8.

### 2. Entidades e Partículas (`scripts/plants/plant.gd`)
- Em `_get_or_create_particle_material(col: Color)`:
  - Removidas as linhas `mat.emission_enabled = true`, `mat.emission = col` e `mat.emission_energy_multiplier = 0.22`.
  - Partículas de corte e peças desprendidas (`FlowerDetachPiece`) agora utilizam material `StandardMaterial3D` puramente fosco (`roughness = 0.85`).

### 3. Pipeline de Modelagem 3D (`tools/split_flower_model.py`)
- Em `CONFIG["flower_03_daisy"]`:
  - Adicionadas as ilhas `164, 165, 166, 167, 168, 169, 170` ao grupo `leaves`.
  - Filtragem de pétalas agora exclui estritamente ilhas presentes em `stem_ids` e `leaf_ids`.
- Prevenção canônica de Z-fighting:
  - Vértices dos modelos estáticos (`recenter=False`) com $Z < 0.003$ são elevados para $0.003$.
- Regeneração e exportação dos 8 modelos glTF atualizados (`flower_01` a `flower_08`).

---

## ✅ Verificação e Qualidade
1. **Reimportação Headless:** `godot_console.exe --headless --import` executado com 0 erros e 0 warnings.
2. **Suíte Automatizada:** `tests/test_flower_detach.gd` executada para as 8 espécies botânicas:
   - `flower`: OK
   - `flower_rose`: OK
   - `flower_daisy`: OK
   - `flower_sunflower`: OK
   - `flower_bell`: OK
   - `flower_corolla`: OK
   - `flower_tulip`: OK
   - `flower_bed`: OK
   - `RESULTADO FINAL 8 FLORES: OK` (0 vazamentos de nós de peças soltas, HP final em 2).
3. **Renderização de Confirmação:** Prévia 3D gerada da margarida demonstrando folhagem, sépalas e haste inteiramente verdes foscos, ausência de manchas brancas e eliminação do Z-fighting contra o solo.
