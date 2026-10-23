# Melhoria 083: Otimização da Malha da Grama em Triângulos Cartoon (Low-Poly Cel-Shaded) [v0.12.7-alpha] 🌿🔺

Este documento registra a remodelagem e substituição do modelo 3D canônico da vegetação (`grass_01.glb`), transacionando do tufo curvo pesado anterior (183 vértices e 105 faces) para uma **malha geométrica estilizada de lâminas triangulares pontiagudas em leque** (36 vértices e 18 faces), reduzindo em **mais de 80% o processamento da GPU** e conferindo a estética cel-shaded cartoon facetada da referência.

---

## 📋 Resumo Executivo
- **Data da Conclusão:** Outubro de 2026
- **Versão SemVer:** `v0.12.7-alpha` (Code: `1207`)
- **Domínio:** Modelagem 3D, Pipeline Blender -> Godot, Otimização Mobile e Direção de Arte
- **Objetivos Entregues:**
  1. **Redução Drástica na Carga Geométrica (80% mais leve):**
     - O tufo anterior possuía 183 vértices e 105 faces;
     - O novo modelo triangular cartoon possui apenas **36 vértices e 18 faces**;
     - Em uma fase com 500 tufos instanciados, a GPU processa **73.500 vértices a menos por frame**;
     - O tamanho do arquivo `.glb` caiu de 11.6 KB para **3.6 KB** (-69%).
  2. **Estética Cel-Shaded Facetada:**
     - 9 lâminas pontiagudas distribuídas em leque com alturas assimétricas ($0.46\text{m} \dots 0.64\text{m}$) e inclinação radial sutil;
     - Cada lâmina possui dobra central em V (2 triângulos por folha com quina frontal), produzindo iluminação facetada cartoon nítida sob o sol;
  3. **Compatibilidade Rigorosa com os Shaders Espaciais:**
     - Coordenadas $UV.y = 0.0$ nas raízes mantêm a base 100% estática e ancorada ao solo;
     - Coordenadas $UV.y = 1.0$ nas pontas garantem curvatura quadrática perfeita sob a lâmina e no balanço;
     - Cores de vértice (`COLOR`) assadas com atributos de fase, ângulo e frequência do vento preservam o movimento independente folha a folha no `interactive_grass.gdshader`.
  4. **Automação e Reprodutibilidade:**
     - Criado o script procedural [`tools/generate_triangle_grass.py`](file:///c:/Users/User/OneDrive/Documentos/grass-cut-bot/tools/generate_triangle_grass.py) executável via Blender 5.2 headless;
     - Backup automático preservado em `assets/models/grass_01_backup_dense.glb`.

---

## 🧪 Testes e Validação
- **MCP Godot Run:** Execução de `res://scenes/main.tscn` e `res://scenes/menu/main_menu.tscn` com 0 erros e 0 warnings no console.
- **SemVer:** Atualizado para `v0.12.7-alpha` (Code: `1207`).
