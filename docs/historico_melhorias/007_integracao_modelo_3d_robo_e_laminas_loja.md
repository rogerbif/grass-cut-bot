# Melhoria 007: Integração do Modelo 3D do Robô Cortador, Lâminas Modulares e Evolução na Loja 🤖🪚🪙

Este documento consolida o diagnóstico, plano de implementação e a entrega da integração oficial do modelo 3D do robô cortador no Blender (`grass_bot_00.blend`), modelagem e calibragem das lâminas centrais no interior do `blade_container`, exportação otimizada glTF/GLB para Godot 4 e a evolução visual e mecânica das lâminas através da Oficina de Upgrades.

---

## 📋 Resumo Executivo
- **Data da Conclusão:** Outubro de 2026
- **Versão SemVer:** `v0.3.0`
- **Domínio:** Modelagem 3D, Gameplay, Entidades do Cortador e Economia/Oficina
- **Objetivos Entregues:**
  1. Revisão completa da malha do robô no Blender: solda de vértices, recálculo de normais voltadas para o exterior e aplicação de materiais PBR Low Poly foscos (`roughness 0.85 ~ 0.95`) fiéis ao concept art ortogonal.
  2. Modelagem do rotor central de corte no vão interior do `blade_container` com 3 variantes de lâminas modulares (Tier 1: Aço Básico 16 dentes; Tier 2: Serra Dupla Turbo 20 dentes; Tier 3: Titânio Estelar 12 lâminas angulares).
  3. Estruturação de hierarquia limpa com pivôs dedicados: eixo da roda mono-wheel centralizado para rolagem física e pivô do rotor central para giro ininterrupto a 1200°/s.
  4. Pipeline de exportação glTF/GLB automatizado para `res://assets/models/grass_bot.glb` (123 KB, otimizado para mobile 60 FPS).
  5. Reestruturação de `cutter.tscn` e `cutter.gd` com desacoplamento visual: o chassi vira suavemente na direção de condução com rolagem da roda, enquanto a serra gira radialmente e corta omnidirecionalmente.
  6. Integração com `UpgradeManager` e `HUD`: a lâmina equipada evolui visualmente em tempo real entre os Tiers 1, 2 e 3 conforme os upgrades de Raio e Potência são adquiridos na Oficina, com exibição dinâmica do modelo no banner da loja.

---

## 🔍 Diagnóstico do Cenário Anterior
1. **Lâmina Provisória de Primitivas:** O cortador utilizava blocos geométricos primitivos temporários criados diretamente no Godot (`PrismMesh`, `BoxMesh`, `CapsuleMesh`), sem carcaça de robô, cabeça, rodas ou chassis.
2. **Modelo do Blender sem Lâmina Central:** O arquivo `grass_bot_00.blend` continha a carcaça, o mono-wheel e o `blade_container` com modificador Mirror em Z, mas faltava o rotor com as lâminas cortantes no vão central de 0.09m entre as placas do container.
3. **Ausência de Materiais no Blender:** Todas as peças 3D estavam sem slots de materiais (`Materials: []`), e as faces frontais da cabeça estavam com normais invertidas para dentro.
4. **Falta de Suporte a Lâminas Modulares na Loja:** A Oficina apenas aumentava valores numéricos sem refletir uma progressão visual de modelos de lâminas para o jogador.

---

## 🎯 Arquitetura da Solução Técnica

### 1. Revisão e Materiais no Blender (`grass_bot_00.blend`)
- **Normais e Geometria:** Recálculo unificado de normais externas em todas as malhas (`recalc_face_normals`) e ajuste do pivô da mono-wheel para o centro geométrico de seu eixo `(0.0, 0.007, 0.620)`.
- **Materiais PBR Foscos (Mobile 60 FPS):**
  - `M_Carcaca_Amarela`: Albedo `#F5A623`, Roughness `0.88`, Metallic `0.0`.
  - `M_Metal_Branco`: Albedo `#E8ECEF`, Roughness `0.85`, Metallic `0.1`.
  - `M_Borracha_Preta`: Albedo `#202428`, Roughness `0.92`, Metallic `0.0`.
  - `M_Aco_Lamina`: Albedo `#CBD3DC`, Roughness `0.55`, Metallic `0.85`.
  - `M_Ouro_Titanio`: Albedo `#F2C738`, Roughness `0.35`, Metallic `0.90`.
  - `M_Sensor_Ciano`: Albedo `#102028`, Emission `#18D8F0` nas lentes dos sensores frontais da cabeça.
  - `M_LED_Traseiro`: Albedo `#301010`, Emission `#FF4400` no LED traseiro.

### 2. Modelagem das Lâminas Modulares
No vão central do `blade_container` (Z = 0.642m), foram criados 3 modelos de rotores de corte:
- **`blade_tier_1` (Lâmina Básica de Aço):** 16 dentes angulares em aço temperado projetados de raio $0.74\text{m}$ até $0.94\text{m}$ para fora do anel protetor.
- **`blade_tier_2` (Serra Dupla Turbo):** 20 dentes duplos com perfil de serra alternada e raio de corte estendido até $0.98\text{m}$.
- **`blade_tier_3` (Lâmina Estelar de Titânio):** 12 lâminas em diamante de alto impacto com bisel dourado e alcance radial até $1.02\text{m}$.

### 3. Hierarquia do Modelo glTF/GLB
```
Robot (Node3D)
├── Body (Node3D - Carcaça, Cabeça, Bateria, Paralama, Container)
│   └── wheel (MeshInstance3D - Rolagem no eixo local X)
└── BladeSpinner (Node3D - Rotação contínua no eixo Y a 1200°/s)
    ├── blade_tier_1 (MeshInstance3D)
    ├── blade_tier_2 (MeshInstance3D)
    └── blade_tier_3 (MeshInstance3D)
```

### 4. Integração na Cena `cutter.tscn` e Script `cutter.gd`
- **Escala Canônica:** A instância visual `GrassBot` opera com escala $0.70$, casando perfeitamente a malha da lâmina ($r = 0.94 \times 0.70 \approx 0.658\text{m}$) com o `BladeArea` ($r = 0.65\text{m}$) e a mono-wheel ($r = 0.64 \times 0.70 \approx 0.45\text{m}$) com o `BodyCollision` ($r = 0.45\text{m}$).
- **Desacoplamento Visual e Físico:**
  - `BladeSpinner` gira continuamente a 1200°/s em $Y$, garantindo corte radial omnidirecional.
  - `robot_body` realiza interpolação angular suave (`lerp_angle`) para orientar o robô de frente para a direção de movimento fornecida pelo joystick virtual:
    $$\theta_{\text{alvo}} = \text{atan2}(-v_x, -v_z)$$
  - `wheel` rola fisicamente no eixo local $X$ proporcionalmente à velocidade linear real dividida pelo raio efetivo da roda.

### 5. Progressão de Lâminas na Oficina (`UpgradeManager` & `hud.gd`)
- `UpgradeManager.get_blade_tier()` calcula dinamicamente o tier ativo com base no progresso em **Raio da Lâmina** e **Potência e Fio**:
  - Nível 1 a 2: Tier 1 (`Lâmina Básica de Aço`).
  - Nível 3 a 4: Tier 2 (`Serra Dupla Turbo`).
  - Nível 5+: Tier 3 (`Lâmina Estelar de Titânio`).
- `hud.gd` exibe o nome da lâmina equipada no topo do modal da Oficina (`WorkshopModal`).
- Ao comprar uma melhoria, `cutter.gd` atualiza a visibilidade dos nós de lâmina instantaneamente, sem travar ou interromper a partida.

---

## 🛡️ Conformidade de Guardrails Invariantes
- **Zero Warnings:** 0 warnings e 0 erros no Godot 4.7.
- **Camadas de Física Inalteradas:** Camada 2 (Cortador) com máscara 1 | 8, e área de lâmina com máscara 4 (Vegetação).
- **Corte Radial Omnidirecional Preservado:** A rotação visual do robô não afeta o corte, que continua uniforme em 360°.
- **Performance Mobile Estrita:** Malha leve única de 123 KB, baixa contagem poligonal e materiais foscos sem custos pesados de reflexão.
