# Histórico de Melhoria: Reformulação Anatômica da Espiga de Trigo 3D (`wheat_01.glb`) 🌾✨

**Data:** 10 de Novembro de 2026  
**Versão:** `v0.12.178-alpha`  
**Autor:** Antigravity (Google DeepMind)  
**Status:** Concluído ✅  

---

## 1. Contexto e Motivação
O usuário relatou que a ponta da haste de trigo no jogo atual não permitia identificar com clareza o que era (*"a ponta dele não da pra saber o que é"*), apresentando uma silhueta serrilhada confusa em degraus angulares.

### Investigação Técnica no Blender
Ao inspecionar o arquivo original `C:\Users\User\OneDrive\Documentos\3D_Blender\wheat.blend`, constatou-se que:
1. O asset original do Sketchfab (`d53865f1b88b457fa06c0751d734e397.fbx`) utilizava uma textura 2D alpha com recorte transparente (`Image_0.png`) para pintar os grãos de trigo sobre cartões planos.
2. Na migração para o estilo Low Poly toon fosco sem texturas pesadas (Mandamento 7), a textura alpha foi removida, restando apenas uma gaiola estrutural de 6 cilindros escalonados ocos.
3. No Godot, com `cull_disabled`, essa gaiola gerava um contorno pontiagudo e confuso.

---

## 2. Alterações Realizadas

### A. Modelagem 3D Low Poly da Espiga (`wheat.blend` $\to$ `wheat_01.glb`)
1. **Remoção de Polígonos Obsoletos:** Excluídas 106 faces da gaiola antiga acima de $Z = 0.82\text{m}$.
2. **Ráquis Central:** Construída haste dorsal cilíndrica central de $0.80\text{m}$ a $1.12\text{m}$.
3. **11 Níveis de Espiguetas em Espinha de Peixe (Herringbone):**
   - Pares de grãos volumosos facetados (8 triângulos cada) com inclinação de $41^\circ$ para cima.
   - Perfil anatômico suave na base, bojudo no meio ($\approx 0.054\text{m}$ de comprimento x $0.034\text{m}$ de largura) e afilado no topo.
   - Encaixe em escama (*shingles*) abraçando o ráquis.
4. **Aristas Douradas Superiores:** Cerdas finas estilizadas no topo conferindo a silhueta inconfundível de trigo maduro.
5. **Grão Apical:** Fechamento piramidal estilizado no ápice.
6. **Mapeamento UV e Vertex Colors:**
   - $UV.y \in [0.0, 1.0]$ da raiz à ponta da espiga (compatível com flexão de vento e cortador).
   - Cores de vértice em degradê: fendas em âmbar profundo e faces externas em dourado solar.
7. **Exportação Canônica:** Exportado com `export_apply=True` e `export_yup=True` (Mandamento 12) para `assets/models/wheat_01.glb`.
8. **Reimportação Atômica:** Executado `godot --headless --import` para regenerar o cache binário `.scn`.

### B. Preservação de Normais Geométricas no Shader (`interactive_grass.gdshader`)
- Para vegetação com `invert_height == true` (Trigo), o shader preserva as normais geométricas 3D reais das facetas dos grãos, em vez de forçar a normal radial plana de grama.
- Isso permite que a luz Half-Lambert destaque os relevos de cada semente, com sombras quentes nas fendas e brilho dourado nas pontas.

---

## 3. Validação e Testes
- **Captura In-Game Godot:** Canteiro de trigo testado sob iluminação real do jogo (`test_wheat_ingame_new_spike.png` e `test_wheat_closeup_godot.png`), confirmando leitura botânica imediata de espiga de trigo madura.
- **Testes Automatizados:** `tests/test_all_botanical_variations.gd` e `tests/test_wheat_level_02.tscn` executados com **100% de aprovação e 0 warnings**.

---

## 4. Arquivos Modificados
- `assets/models/wheat_01.glb`
- `scripts/tools/remodel_wheat.py`
- `shaders/interactive_grass.gdshader`
- `scripts/core/game_version.gd`
- `project.godot`
- `export_presets.cfg`
- `docs/02_entidades_e_mecanicas/SISTEMA_DE_VEGETACAO.md`
- `docs/historico_melhorias/INDICE_MELHORIAS.md`
- `docs/historico_melhorias/222_reformulacao_anatomica_espiga_trigo_3d.md`
