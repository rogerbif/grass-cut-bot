# Melhoria 110: Novas Flores do Pack Plants1 (Flor Sino, Cravo Corola, Tulipa Imperial e Canteiro Florido) 🌸🔔🌷

**Data:** 26 de Outubro de 2026  
**Versão:** `v0.12.34-alpha`  
**Escopo:** Pipeline 3D Blender, Shaders Cel-Shaded sem Texturas, Sistema de 3 Hits de Despetalação, GPU MultiMesh Instancing e Editor de Fases.

---

## 🎯 1. Objetivos da Melhoria
1. **Zero Texturas Estrito:** Extrair 4 novas espécies de flores do arquivo `Plants1` no Blender eliminando 100% de imagens raster/atlas, utilizando exclusivamente **materiais nativos foscos (`roughness = 0.90`)** e canais de **Vertex Color** para despetalação em tempo real na GPU.
2. **Novas Espécies Florais:**
   - **Flor Sino / Campânula (`flower_bell`):** 232 faces, formato em sino azul celeste com pétalas pendentes.
   - **Cravo Corola (`flower_corolla`):** 288 faces, flor espalmada exuberante em tom coral/damasco.
   - **Tulipa Imperial (`flower_tulip`):** 288 faces, flor ereta em cálice taça rubi imperial.
   - **Canteiro Florido (`flower_bed`):** 228 faces, tufo horizontal salpicado com 9 florzinhas lilás/violeta.
3. **Mecânica Universal dos 3 Hits com Despetalação:**
   - **Hit 1 (HP $3 \rightarrow 2$):** 1ª leva de pétalas colapsa na GPU (`R = 0.5`) e ejeta burst de partículas da flor.
   - **Hit 2 (HP $2 \rightarrow 1$):** 2ª leva de pétalas colapsa (`R = 1.0`), restando apenas o miolo e caule/folhas verdes intactos.
   - **Hit 3 (HP $1 \rightarrow 0$ - Fatal):** Caule ceifado rente ao solo, gerando aparas de chão, +5 moedas e fechando a meta.
4. **Preservação do Caule/Folhas Verdes e Customização de Cores:**
   - Slot 0 (`StemLeaves`): Caule e folhagem verde fosco sólido.
   - Slot 1 (`Petals`): Pétalas dinâmicas via `interactive_flower.gdshader`, permitindo qualquer variação cromática alterando apenas o material `.tres`.
5. **Integração no Editor de Fases:** Cadastrar as 4 novas espécies na paleta de **Objetos** (tile 0.80m) com visualização 3D, ícones dedicados (🔔, 🏵️, 🌷, 🪻), resumo de metas e persistência JSON v3.

---

## 🛠️ 2. Arquivos Implementados e Modificados

| Arquivo | Ação | Descrição |
| :--- | :---: | :--- |
| `assets/models/flower_05_bell.glb` | Novo | Modelo 3D exportado do Blender com 232 faces e Vertex Color assado |
| `assets/models/flower_06_corolla.glb` | Novo | Modelo 3D exportado com 288 faces (3 corolas) e Vertex Color assado |
| `assets/models/flower_07_tulip.glb` | Novo | Modelo 3D exportado com 288 faces (3 cálices) e Vertex Color assado |
| `assets/models/flower_08_bed.glb` | Novo | Modelo 3D exportado com 228 faces (canteiro de 9 flores) e Vertex Color |
| `shaders/flower_bell_material.tres` | Novo | Material Shader cel-shaded Toon azul campânula (`Color(0.22, 0.58, 0.95)`) |
| `shaders/flower_corolla_material.tres` | Novo | Material Shader cel-shaded Toon coral damasco (`Color(0.98, 0.52, 0.18)`) |
| `shaders/flower_tulip_material.tres` | Novo | Material Shader cel-shaded Toon vermelho rubi (`Color(0.92, 0.18, 0.24)`) |
| `shaders/flower_bed_material.tres` | Novo | Material Shader cel-shaded Toon lilás violeta (`Color(0.78, 0.38, 0.92)`) |
| `scenes/plants/flower_bell.tscn` | Novo | Cena da entidade Flor Sino (🔔) com colisor e materiais |
| `scenes/plants/flower_corolla.tscn` | Novo | Cena da entidade Cravo Corola (🏵️) com colisor e materiais |
| `scenes/plants/flower_tulip.tscn` | Novo | Cena da entidade Tulipa Imperial (🌷) com colisor e materiais |
| `scenes/plants/flower_bed.tscn` | Novo | Cena da entidade Canteiro Florido (🪻) com colisor ampliado e materiais |
| `scripts/level/level_json_loader.gd` | Modificado | Adicionado mapeamento das 4 novas flores em `OBJECT_SCENES` |
| `scripts/editor/tile_palette_db.gd` | Modificado | Cadastrado as 4 novas flores na paleta `OBJECT_ITEMS` do Editor |
| `scripts/editor/level_editor.gd` | Modificado | Preloads e instanciação 3D em tempo real no grid de objetos |
| `scripts/plants/vegetation_grid.gd` | Modificado | Suporte a `VEG_TYPES`, pré-carregamento de malhas combinadas, clipping colors e partículas |
| `scripts/ui/hud.gd` | Modificado | Mapeamento dos novos ícones no Top HUD de metas (🔔, 🏵️, 🌷, 🪻) |
| `docs/02_entidades_e_mecanicas/SISTEMA_DE_VEGETACAO.md` | Modificado | Tabela canônica de espécies atualizada |

---

## 🧪 3. Validação e Qualidade
- **Reimportação Atômica:** Executado `godot --headless --import` com sucesso sem nenhum erro.
- **Zero Warnings / Zero Erros:** Execução Headless tanto do jogo quanto do Level Editor rodando perfeitamente limpos.
- **Runtime Test:** Cenas de todas as flores instanciadas e validadas com 100% de sucesso.
