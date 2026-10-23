# Melhoria 084: Restauração da Condensação, Envergadura e Volume Foliar da Grama [v0.12.8-alpha] 🌿✨

Este documento registra a restauração e análise aprofundada da malha canônica da vegetação (`grass_01.glb`), garantindo que o gramado recupere integralmente a **condensação farta, envergadura ($1.10\text{m} \times 1.24\text{m}$) e volume de 39 folhas** do modelo consagrado, eliminando o aspecto ralo de fiapos isolados do experimento anterior.

---

## 📋 Diagnóstico da Geometria & Lição Aprendida

Ao inspecionar a malha original no Blender 5.2 via script Python, revelou-se a anatomia exata responsável pelo visual exuberante do gramado:
- **Envergadura de Mundo:** $X = 1.09\text{m}$, $Y = 1.24\text{m}$, $Z = 1.05\text{m}$ (área de cobertura ampla que se entrelaça com tufos vizinhos no espaçamento de $0.22\text{m}$ do Poisson Disk, fechando o solo como um tapete contínuo sem buracos);
- **Estrutura de 39 Folhas em 3 Patamares:**
  - Folhas de base ampla ($0.35\text{m} \dots 0.48\text{m}$), muito abertas e inclinadas ($25^\circ \dots 35^\circ$), bloqueando a visão do solo;
  - Folhas intermediárias ($0.65\text{m} \dots 0.80\text{m}$), conferindo textura e profundidade;
  - Folhas centrais altas ($0.95\text{m} \dots 1.05\text{m}$), conferindo porte e volume foliar;
- **Topologia:** O modelo original já é composto estritamente por triângulos low-poly (`faces=[3]`, 183 vértices e 105 faces no total), o que para a GPU moderna via `MultiMeshInstance3D` já roda a 60 FPS cravados sem nenhuma perda de performance.

O experimento anterior tentou sintetizar o tufo com apenas 9 lâminas esguias em um raio minúsculo de $0.04\text{m}$, o que quebrou o entrelaçamento entre os tufos e gerou o aspecto ralo de "fiapos" isolados com o solo marrom visível.

---

## 🛠️ Ação Realizada
1. **Restauração Imediata da Malha Original:**
   - Restaurado o arquivo canônico [`assets/models/grass_01.glb`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/assets/models/grass_01.glb) com seus 183 vértices, 39 lâminas e envergadura de $1.10\text{m}$;
   - Reimportação automática na Godot Engine 4.7.1 validada com **0 erros e 0 warnings**;
2. **Governança:**
   - Game SemVer atualizado para `v0.12.8-alpha` (Code: `1208`).
