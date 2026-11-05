# Melhoria 178: Caule com Gradiente Escuro de Alto Contraste e Correção da Despetalação da Rosa 🌿🌹

**Data:** 05/11/2026  
**Versão:** `v0.12.124-alpha`  
**Escopo:** Visual 3D das Flores, Shaders, Modelo 3D da Rosa, Mecânica de Despetalação (Hits 1, 2 e 3)  

---

## 🎯 Objetivo da Melhoria

Atender às duas solicitações canônicas de refinamento:
1. **Caule com Alto Contraste e Gradiente Escuro $\rightarrow$ Claro:** O caule das flores utilizava anteriormente o mesmo material padrão de gramado (`interactive_grass_material.tres`), mimetizando-se com o piso de grama. Criação do material dedicado `interactive_flower_stem_material.tres` com base em verde floresta/oliva profundo (`#0F3814`) e transição em gradiente vertical via `COLOR.a` até o topo verde vegetal vivo (`#2E8533`), destacando a silhueta da flor sobre qualquer terreno.
2. **Correção do Bug de Deformação no Corte (Despetalação):** Ao cortar a rosa (Hit 1 / Hit 2), o modelo apresentava estiramentos pontiagudos em cone/agulhas em direção ao solo (conforme evidenciado na imagem `media_1793892307943_543c3d2f.png`). Identificação e erradicação definitiva da causa raiz, reduzindo polígonos inconsistentes a **estrito 0**.

---

## 🔬 Diagnóstico e Solução Técnica

### 1. Causa Raiz do Bug de Corte (Estiramento das Pétalas)
- No shader `interactive_flower.gdshader`, quando o estágio de dano atinge o Hit 1 (`stage >= 0.95 && COLOR.r > 0.35 && COLOR.r < 0.75`), as pétalas externas colapsam para `VERTEX = vec3(0.0)`.
- No modelo 3D anterior da rosa (`flower_02_rose.glb`), 113 polígonos (triângulos) possuíam vértices com atribuições conflitantes de $R$ e $B$ (ex: Vértice 1 com $R = 0.5$ e Vértices 2 e 3 com $R = 1.0$ ou $R = 0.0$).
- Ao sofrer o golpe, apenas o Vértice 1 colapsava para $(0, 0, 0)$ na base do modelo, enquanto os Vértices 2 e 3 permaneciam no topo da corola. O triângulo não se degenerava em área zero; em vez disso, esticava-se verticalmente ao longo de todo o comprimento da flor, gerando as agulhas estiradas visíveis na captura do usuário.
- **Solução Definitiva:** Script de re-atribuição anatômica estrita por ilhas conexas (`face_islands`). As 32 ilhas de `Flower_Petals` foram categorizadas de forma homogênea e determinística:
  - **Miolo / Core (7 ilhas centrais):** $R = 0.0, G = 1.0, B = 0.0, A = 0.0$ (nunca colapsa nos Hits 1 ou 2).
  - **Pétalas Externas (14 ilhas):** $R = 0.5, G = 0.0, A = \text{gradiente}$ (colapsam integralmente e simultaneamente no Hit 1). As ilhas 3 e 12 foram associadas às peças soltas de física ($B = 1.0$).
  - **Pétalas Internas (11 ilhas):** $R = 1.0, G = 0.0, B = 0.0, A = \text{gradiente}$ (colapsam integralmente no Hit 2).
- **Resultado:** Polígonos inconsistentes = **0**. Despetalação perfeitamente limpa sem qualquer deformação espúria.

### 2. Shader e Material do Caule (`interactive_flower_stem_material.tres`)
- Criado o material específico para caules de flor, apontando para `interactive_flower.gdshader` com suporte a vento procedural (`wind_speed = 1.8`, `wind_strength = 0.08`) e curvatura interativa do cortador (`interact_power = 0.22`).
- Parâmetros calibrados:
  - `petal_inner_color`: `Color(0.06, 0.22, 0.08, 1.0)` (base escura no solo)
  - `petal_color`: `Color(0.18, 0.48, 0.22, 1.0)` (ápice vegetal sob o cálice)
  - Gradiente vertical contínuo lido de `COLOR.a` ($Z = 0.003 \rightarrow Z = 0.897$).
- Atualizado em `scenes/plants/flower_rose.tscn` e em todas as outras 7 espécies de flores (`flower_bed`, `flower_bell`, `flower_corolla`, `flower_daisy`, `flower_sunflower`, `flower_tuft`, `flower_tulip`), além de `plant.gd` e `vegetation_grid.gd`.

---

## 🛠️ Arquivos Modificados / Criados

- `assets/models/flower_02_rose.glb`: Re-exportado com 0 polígonos inconsistentes e preservação de RGBA float.
- `shaders/interactive_flower_stem_material.tres`: **Novo material canônico de caule**.
- `scenes/plants/flower_rose.tscn`: Vinculado a `interactive_flower_stem_material.tres`.
- `scenes/plants/flower_*.tscn`: Todas as 8 cenas de flores atualizadas com o novo material de caule.
- `scripts/plants/plant.gd`: `FLOWER_STEM_MATERIAL` e `FLOWER_STEM_COLOR` atualizados.
- `scripts/plants/vegetation_grid.gd`: `FLOWER_STEM_MATERIAL` atualizado.
- `tests/test_rose_cutting_visual.gd`: Novo teste sequencial validando Hits 1, 2 e 3 sem falhas.
- `tests/test_rose_cutting_visual.tscn`: Cena de teste automatizado.

---

## 🧪 Validação Automatizada

- **Teste de Corte da Rosa (`test_rose_cutting_visual.tscn`):** Sucesso em todos os 3 hits com 0 erros.
- **Teste de Desprendimento de Pétalas (`test_flower_detach.gd`):** 8/8 flores aprovadas.
- **Teste de Variações no Editor (`test_flower_variations_editor.tscn`):** 7/7 variações aprovadas.
- **Zero Warnings:** Console Godot mantido estritamente limpo.
