# 229 — Pacote 1: Sanitização do Projeto, Isolamento `.gdignore` e Filtros de Exportação (`v0.12.183-alpha`)

## Contexto e Motivação
Durante a revisão arquitetural e de performance do projeto **Grass Cut Bot**, identificou-se que:
1. Imagens geradas por testes anteriores na raiz do projeto (`test_flower_composite.png`, `test_grass_green_composite.png`, `test_grass_green_outlined.png`, `test_grass_yellow_composite.png`, `test_wheat_composite.png`) estavam sendo importadas pela Godot como `CompressedTexture2D` e empacotadas no build final.
2. As pastas `scripts/tools/play_store_uploader/` (contendo `node_modules/`), `tools/`, `scratch/` e `build/` não possuíam arquivos `.gdignore`, fazendo com que a Godot escaneasse dependências Node.js e reimportasse imagens geradas em `build/web/`.
3. Os presets de exportação Android e Web em `export_presets.cfg` estavam com `exclude_filter=""` vazio.
4. Os arquivos `assets/models/cut_leaf_piece.obj` e `cut_leaf_piece.mtl` eram redundantes em relação ao modelo oficial `cut_leaf_piece.glb`.

## Alterações Executadas
1. **Remoção de Arquivos Órfãos e Redundantes:**
   - Excluídas as 5 imagens `test_*.png` e seus `.import` da raiz, pacotes `.apk`/`.idsig` e logs temporários (`godot.log`, `test.log`).
   - Excluídos `assets/models/cut_leaf_piece.obj`, `cut_leaf_piece.obj.import` e `cut_leaf_piece.mtl`.
   - Excluídos os arquivos `.import` gerados indevidamente dentro de `build/web/`.
2. **Isolamento do Scanner da Godot com `.gdignore`:**
   - Criados arquivos `.gdignore` em `scripts/tools/play_store_uploader/`, `tools/`, `scratch/` e `build/`.
3. **Blindagem de Exportação (`export_presets.cfg` e `.gitignore`):**
   - Configurado `exclude_filter="tests/*, scripts/tools/*, tools/*, scratch/*, build/*, *.md, *.ps1, *.apk, *.aab, *.idsig, *.log, *.jks, *.keystore, play_service_account.json"` em ambos os presets (`grasscutbot` Android e `grasscutbot_Web`).
   - Adicionada regra `scratch/*` (preservando `!scratch/.gdignore`) no `.gitignore`.

## Validação
- Executado `godot --headless --import` e `godot --headless --quit` na Godot v4.7.2 com **0 warnings**.
