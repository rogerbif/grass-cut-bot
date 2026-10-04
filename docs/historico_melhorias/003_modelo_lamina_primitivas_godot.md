# Melhoria 003: Modelagem da Lâmina Estilizada com Primitivas Nativas da Godot 🪚✨

Este documento consolida o plano de implementação, a execução técnica e o walkthrough da recriação visual da lâmina do cortador em **Grass Cut Bot**, utilizando exclusivamente primitivas geométricas 3D nativas da engine (sem dependência de malhas externas), fiel à referência de design fornecida.

---

## 📋 Resumo Executivo
- **Data da Conclusão:** Outubro de 2026
- **Versão SemVer:** `v0.2.3`
- **Domínio:** Gameplay, Entidades e Arte Visual 3D
- **Objetivo:** Substituir a lâmina genérica inicial por uma lâmina estilizada com estética arcade/hiper casual vibrante, composta por um hub motor central azul com botão em domo celeste, asas aerodinâmicas duplas com perfil de hélice e arcos crescentes de vento (*swoosh trails*) que acompanham a alta rotação da serra.

---

## 🎯 Arquitetura da Solução Técnica

### 1. Hub Central Azul do Motor
- **Base do Hub:** `CylinderMesh` (`top_radius = 0.20m`, `bottom_radius = 0.23m`, `height = 0.08m`, 32 segmentos radiais). Material fosco acetinado azul vibrante (`Color(0.0, 0.46, 0.96)`, `roughness = 0.25`).
- **Botão Superior em Domo:** `SphereMesh` achatada (`radius = 0.14m`, `height = 0.075m`, 32 segmentos, 16 anéis) posicionada no topo com acabamento brilhante azul celeste (`Color(0.14, 0.70, 1.0)`, `roughness = 0.18`).

### 2. Asas Aerodinâmicas Duplas (`WingRight` e `WingLeft`)
- **Raiz Estrutural (`RootBase`):** `BoxMesh` (`0.20m x 0.035m x 0.20m`) totalmente oculta sob o cilindro azul do hub para garantir transição suave e sem z-fighting.
- **Cunha Aerodinâmica Principal (`MainWedge`):** `PrismMesh` (`size = Vector3(0.28, 0.54, 0.035)`, `left_to_right = 0.40`) reorientado via matriz ortonormal `Basis(Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0))` para o plano horizontal. A propriedade `left_to_right = 0.40` confere a curvatura aerodinâmica assimétrica de aerofólio.
- **Espinha Central (`Spine`):** `CapsuleMesh` (`radius = 0.032m`, `height = 0.48m`) reorientada ao longo do eixo da lâmina, conferindo volume tridimensional e suavidade de reflexo.
- **Ponta Arredondada (`TipRound`):** `SphereMesh` suave (`radius = 0.024m`) na extremidade exterior (`x = 0.625m`).
- **Simetria Rotacional:** `WingLeft` é idêntica à `WingRight`, posicionada com rotação de 180° em Y (`Transform3D(-1, 0, 0, 0, 1, 0, 0, 0, -1, ...)`).

### 3. Rastros Dinâmicos de Vento (*Swoosh Trails*)
- Dois pares de arcos crescentes posicionados estrategicamente atrás da ponta de cada asa no sentido do giro (quadrantes +Z para a asa direita e -Z para a asa esquerda):
  - **Arco Externo:** 10 instâncias de `CapsuleMesh` tangentes ao círculo de rotação em $R = 0.66\text{m}$, com raios escalados senoidalmente de $0.005\text{m}$ nas pontas até $0.018\text{m}$ no centro.
  - **Arco Interno:** 8 instâncias de `CapsuleMesh` tangentes em $R = 0.52\text{m}$, com raios de $0.004\text{m}$ até $0.014\text{m}$.
  - **Material dos Arcos:** `StandardMaterial3D` transparente (`Color(1.0, 1.0, 1.0, 0.65)`), `shading_mode = SHADING_MODE_UNSHADED` e `cull_mode = CULL_DISABLED`.

---

## 📸 Renderização e Verificação Visual

![Lâmina Estilizada Preview](../assets/blade_preview.png)

A lâmina foi testada e renderizada diretamente pelo renderizador Vulkan Mobile da engine, confirmando:
1. Alinhamento perfeito do hub e inexistência de artefatos visuais ou recortes.
2. Formato aerodinâmico suave da asa sem aspecto de faca ou agulha.
3. Rastro de movimento que se move sincronizadamente com o giro de 1200°/s da serra circular.
4. Compatibilidade total com upgrades de raio: a escala visual se propaga pelo nó pai `SawMesh`.

---

## 🛡️ Conformidade de Guardrails
- **Zero Warnings:** 0 avisos no console da engine Godot 4.
- **Primitivas Nativas:** 100% construído com nós e recursos nativos da engine (`CylinderMesh`, `SphereMesh`, `PrismMesh`, `CapsuleMesh`, `BoxMesh`).
- **Performance Mobile:** Sem geração de geometria em tempo real na CPU; malhas estáticas leves e materiais reutilizados.
