# Melhoria 109: Expansão da Família de Flores: Rosa, Margarida e Girassol em 3 Hits com Despetalação GPU e Editor 🌹🌼🌻

## 🎯 Objetivo e Contexto
Expansão do catálogo de vegetação nobre de **Grass Cut Bot** incorporando 3 novas espécies de flores a partir do arquivo do Blender (`Object_2` Rosa, `Object_5` Margarida, `Object_6` Girassol):
1. **Otimização Low Poly Mobile (Mandamento 7):** Decimação controlada no Blender reduzindo malhas densas de 14.000–18.000 faces para ~1.700–2.200 faces por flor, preservando 100% da silhueta cartoon fosca sem comprometer os 60 FPS mobile.
2. **Centralização e Isolamento Anatômico:** Pivô centralizado em $(X=0, Y=0)$ com a base rente ao solo ($Z = 0.0$).
3. **Mecânica Universal dos 3 Hits:**
   - **Hit 1 ($3 \rightarrow 2$ HP):** 1ª metade das pétalas ($R = 0.5$) colapsa para escala zero no shader e ejeta burst de partículas de pétala coloridas.
   - **Hit 2 ($2 \rightarrow 1$ HP):** 2ª metade das pétalas ($R = 1.0$) colapsa e ejeta novo burst de pétalas, restando apenas miolo e o caule/folhas verdes.
   - **Hit 3 ($1 \rightarrow 0$ HP - Fatal):** Caule ceifado rente ao solo, saem miolos e folhas verdes, concedendo +5 moedas e fechando a meta.
4. **Dois Slots de Material:**
   - **Slot 0 (`StemLeaves`):** Caule e folhas 100% verdes foscos (`interactive_grass_material.tres`).
   - **Slot 1 (`Petals`):** Pétalas e miolo dinâmicos via `interactive_flower.gdshader`, suportando variações de cores cosméticas.
5. **Integração no Editor de Terreno (Nível de Objetos):** Itens de primeira classe na paleta com ícones dedicados (🌹, 🌼, 🌻), visualização 3D instantânea no grid de 0.80m, metas no HUD e persistência JSON v3.

---

## 🛠️ Alterações Realizadas

### 1. Modelos 3D Exportados (Blender Pipeline)
- **Rosa Encantada (`assets/models/flower_02_rose.glb`):** 2.118 faces, 2 slots de material, despetalação em camadas externa/interna.
- **Margarida do Campo (`assets/models/flower_03_daisy.glb`):** 1.753 faces, 2 slots de material, miolo ouro ($G = 1.0$) e 36 pétalas radiais alternadas em 2 levas.
- **Girassol Solar (`assets/models/flower_04_sunflower.glb`):** 2.211 faces, 2 slots de material, disco central avelã e pétalas em leque dourado.

### 2. Materiais & Shaders
- `shaders/flower_rose_material.tres`: Rosa carmim vibrante com miolo bordô.
- `shaders/flower_daisy_material.tres`: Branco perolado com miolo amarelo ouro.
- `shaders/flower_sunflower_material.tres`: Amarelo solar com miolo marrom avelã.

### 3. Cenas das Entidades
- `scenes/plants/flower_rose.tscn` (🌹)
- `scenes/plants/flower_daisy.tscn` (🌼)
- `scenes/plants/flower_sunflower.tscn` (🌻)

### 4. GPU Instancing MultiMesh (`VegetationGrid`)
- `VEG_TYPES` expandido com `"flower_rose"`, `"flower_daisy"` e `"flower_sunflower"`.
- `_ensure_static_meshes()` atualizado com compilação sob demanda de `_flower_rose_mesh`, `_flower_daisy_mesh` e `_flower_sunflower_mesh`.
- Suporte automático a `use_custom_data = true`, `max_hp = 3`, `_resolve_type_particle_color` e despetalação progressiva por espécie no `cut_in_circle()`.

### 5. Editor de Terreno / Fases (Camada de Objetos)
- `tile_palette_db.gd`: Novas espécies cadastradas com ícones (🌹, 🌼, 🌻) e categorias.
- `level_editor.gd`: Instanciação 3D imediata da espécie correspondente no `_rebuild_3d_world()` e suporte nativo no modo Playtest.
- `level_editor_ui.gd`: Atualização unificada do contador de metas de flores para qualquer espécie colocada na ilha.

---

## 🧪 Validação
1. **Compilação e Reimportação Atômica:** Executado `godot_console.exe --headless --import` com sucesso para os 3 novos arquivos `.glb`.
2. **Execução Headless & Debug:** Projeto rodou em modo debug com 0 erros e 0 warnings.
3. **Editor de Fases:** Cena `level_editor.tscn` inicializada e executada com 0 erros.
4. **Game SemVer:** Incrementado para `v0.12.33-alpha` (code `1233`).
