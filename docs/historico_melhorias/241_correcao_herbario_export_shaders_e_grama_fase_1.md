# Melhoria 241: Correção Crítica de Recursos Exportados, Shaders de Água e Grama e Herbário 🌿🌊🛠️

**Data:** 11 de Novembro de 2026  
**Versão:** `v0.12.196-alpha` (Build Code: 1396)  
**Status:** ✅ Concluído e Auditado  
**Tipo:** Hotfix / Portabilidade Mobile / Shaders / Data-Driven / MultiMesh  

---

## 🎯 1. Contexto e Diagnóstico dos Problemas

Após o deploy das versões `v0.12.194-alpha` e `v0.12.195-alpha`, foram observadas 3 anomalias críticas ao executar a build nos dispositivos móveis:
1. **Herbário Vazio na Aba Coleção:** A lista de espécies não carregava nenhum card e exibia contadores zerados.
2. **Efeito da Água Esbranquiçado e Estourado:** O mar aparecia com manchas densas e brancas de espuma cobrindo quase toda a superfície do oceano.
3. **Fase 1 Vazia Sem Tufos de Grama 3D:** A ilha renderizava apenas o plano de terreno verde plano, sem tufos de grama 3D, com os cards de objetivo exibindo valores anômalos.

### 🔍 Diagnóstico das Causas Raízes

- **Causa 1 (Herbário e Grama Ausente no Mobile):**
  Em projetos Godot 4 exportados (como APK/AAB no Android ou Web HTML5), recursos textuais `.tres` empacotados sofrem remap para `.tres.remap`. A varredura de diretório `DirAccess.open("res://data/species")` filtrando estritamente por `ends_with(".tres")` não encontrava nenhum arquivo.
  - Consequência 1: O `PlantDatabase` ficava com lista de recursos vazia no Android, esvaziando o Herbário.
  - Consequência 2: `PlantDatabase.get_all_registered_types()` não continha nenhuma grama (`grass_green`, `grass_yellow`, etc.).
  - Consequência 3: No `VegetationGrid.build_from_level_json`, ao tentar agrupar os tufos da Fase 1, `tufts_by_type.has(vt)` retornava falso para `grass_green`, resultando em falha ao associar MultiMeshes e impedindo a renderização dos 549 tufos físicos da Fase 1.
  - A mesma vulnerabilidade afetava `ObstacleDatabase` e `ThemeDatabase` em builds empacotadas.

- **Causa 2 (Água Estourada em Espuma Branca):**
  No shader `toon_water.gdshader`, a substituição do hint dos samplers de ruído de `source_color` para `hint_default_black` e a remoção da linearização sRGB alteraram a interpretação de `PerlinNoise.png` e `WaterDistortion.png`. Como as texturas são 8-bit em sRGB, ler os dados sem conversão fez com que grande parte das amostras superasse o limiar `surface_noise_cutoff = 0.52`, gerando espuma branca por todo o oceano.

- **Causa 3 (Shader de Grama):**
  No `interactive_grass.gdshader`, o uso de `OUTPUT_IS_SRGB` dentro do estágio `vertex()` violava a disponibilidade desse built-in (exclusivo para `fragment()` e `light()`).

---

## 🛠️ 2. Correções Implementadas

### A. Defesa em Profundidade Absoluta nos Catálogos Data-Driven
1. **`PlantDatabase` (`scripts/plants/plant_database.gd`):**
   - Suporte a sufixo `.remap` via `file_name.trim_suffix(".remap")` e aceitação de `.tres` e `.res`.
   - Adicionado manifesto estático canônico `CANONICAL_SPECIES_PATHS` com os caminhos dos 36 recursos. Caso a varredura via `DirAccess` retorne 0 itens (comum em pacotes de assets em certos ambientes Android/Web), o carregamento automático via manifesto canônico garante 100% de disponibilidade de todas as 36 espécies.
   - Fallback de segurança em `get_all_registered_types()`.

2. **`ObstacleDatabase` (`scripts/obstacles/obstacle_database.gd`):**
   - Suporte a `.trim_suffix(".remap")` e manifesto canônico `CANONICAL_OBSTACLE_PATHS` com as 6 rochas canônicas.

3. **`ThemeDatabase` (`scripts/themes/theme_database.gd`):**
   - Suporte a `.trim_suffix(".remap")` e manifesto canônico `CANONICAL_THEME_PATHS` com os 3 temas canônicos.

4. **`VegetationGrid` (`scripts/plants/vegetation_grid.gd`):**
   - `get_veg_types()` agora possui fallback defensivo para a constante canônica `VEG_TYPES`.
   - Em `build_from_level_json`, garantia de criação segura da lista em `tufts_by_type` antes de realizar o append de tufos.

### B. Restauração Fiel dos Shaders Canônicos
1. **`shaders/toon_water.gdshader`:**
   - Restaurados os samplers originais `source_color, filter_linear_mipmap, repeat_enable`.
   - Restaurada a conversão sRGB-para-linear `_srgb_to_linear_1` e a curva de potência original (`pow(max(surfaceNoiseSample, 0.0001), 2.15)`), restaurando as ondas suaves e a espuma calibrada.
2. **`shaders/interactive_grass.gdshader`:**
   - Restaurado o cálculo do Toon Ramp e `shadow_ratio` na função `light()`, eliminando chamadas inválidas no `vertex()`.

---

## 🧪 3. Validação e Testes

- **`tests/test_collection_system.gd`:** Executado no Godot Headless e aprovado com 100% de sucesso (36 espécies, 10 marcos, filtros e persistência).
- **`tests/test_wheat_level_02.gd`:** Executado e aprovado com 100% de sucesso.
- **`tests/test_all_botanical_variations.gd`:** Executado e aprovado com 100% de sucesso.
- **`tests/test_obstacle_auto_discovery.gd` & `tests/test_theme_auto_discovery.gd`:** 100% de sucesso na auto-descoberta dinâmica e conformidade dos manifestos.
- **Godot Headless Import:** 0 erros e 0 warnings.
