# Melhoria 010: Escurecimento do Material Preto da Borracha e Calibração de Escala da Lâmina [v0.3.3] 🖤🪚

## 1. Visão Geral e Contexto
Após a integração inicial do modelo 3D oficial e expansão de escala da rodada anterior, o usuário identificou que:
1. O material preto da borracha (pneu, visor ao redor dos olhos, pescoço e grelhas) apresentava reflexo cinza lavado sob a iluminação ambiente do Godot 4.
2. A lâmina e seu receptáculo (`blade_container`) ficaram desproporcionalmente grandes em relação ao chassi do robô, requerendo a redução em 0.5 (retorno à escala base 1.0x equilibrada de ~1.88m de diâmetro na serra).

---

## 2. Implementações Realizadas

### A. Escurecimento do Material Preto (`M_Borracha_Preta`)
- **Ajuste no Blender:** O `Principled BSDF` do material `M_Borracha_Preta` teve sua `Base Color` reduzida de linear `(0.125, 0.140, 0.160)` para preto puro profundo `(0.010, 0.010, 0.012, 1.0)` (sRGB `#141416`), `Roughness = 0.88` e `Specular = 0.20`.
- **Efeito Visual no Godot:** O pneu mono-wheel, a moldura dos sensores da cabeça e o pescoço do robô agora exibem preto grafite profundo de alto contraste com o amarelo e o branco da carcaça, mesmo sob iluminação ambiente (`ambient_light_energy = 0.85`).

### B. Redução e Calibração de Escala da Lâmina (`1.0x`)
- **Ajuste no Blender:** Redução de escala em 0.5 (fator $1.0 / 1.5$) nas malhas `blade_container`, `blade_tier_1`, `blade_tier_2` e `blade_tier_3`, aplicando as transformações (`transform_apply(scale=True)`):
  - `blade_container`: $1.61\text{m} \times 1.61\text{m} \times 0.19\text{m}$
  - `blade_tier_1`: $1.88\text{m} \times 1.88\text{m} \times 0.024\text{m}$
  - `blade_tier_2`: $1.96\text{m} \times 1.96\text{m} \times 0.028\text{m}$
  - `blade_tier_3`: $1.97\text{m} \times 1.97\text{m} \times 0.032\text{m}$
- **Reexportação glTF:** Modelo reexportado para `assets/models/grass_bot.glb` (160 KB).

### C. Sincronização da Física e Shaders no Godot
- **`scenes/cutter/cutter.tscn`:** Raio do `CollisionShape3D` (`BladeArea`) redefinido para `radius = 0.65m` (correspondente ao diâmetro de $1.88\text{m} \times 0.7 = 1.31\text{m}$ do robô na cena).
- **`scripts/core/upgrade_manager.gd`:** Raio base retornado para `0.65m` com progressão $+0.12\text{m}$ por nível.
- **`scripts/cutter/cutter.gd`:** Constantes e cálculos de escala visual do rotor atualizados para base `0.65m`.

---

## 3. Validação e Qualidade
- **Zero Warnings:** Projeto executado e verificado com 0 warnings e 0 erros no Godot 4.7.1.
- **Game Feel & Visual:** Pneu e visor escuros com visual tático profissional; serra em proporção mecânica ideal em relação ao corpo do robô.
