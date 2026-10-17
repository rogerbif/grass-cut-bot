# Melhoria 031: Remoção do Botão do Editor da UI e Exclusão no Export Mobile [v0.5.4] 🛠️🚫📱

## 1. Visão Geral e Contexto
O usuário solicitou: *"remova da UI dentro do jogo o botão de abrir o editor, ele não deve abrir no jogo e nem ser compilado junto"*.
O Editor de Fases é uma ferramenta interna exclusiva para uso em desenvolvimento local na Godot. Ele não deve estar presente ou acessível em builds de jogo e não deve inflar o tamanho do APK final distribuído para os jogadores.

---

## 2. Implementações Técnicas

### A. Limpeza Completa de UI e Código em `scripts/main.gd`
- **Remoção do Botão Dev:** Eliminada a função `_create_pc_dev_editor_button()` que injetava dinamicamente o botão `🛠️ Editor [F2]` no `CanvasLayer` do HUD.
- **Remoção de Atalhos e Chamadas:** Removido o evento `_unhandled_input` que capturava a tecla `F2` para trocar de cena e removido o método `_open_level_editor()`.
- **Eliminação de Dependência Direta:** Removida a constante `const EDITOR_SCENE_PATH = "res://scenes/editor/level_editor.tscn"`. O script `main.gd` agora é estritamente enxuto, conectando apenas o joystick virtual ao cortador.

### B. Filtro de Exclusão no Preset de Exportação Android (`export_presets.cfg`)
- Configurado o parâmetro `exclude_filter` no preset Android (`[preset.0]`):
  ```ini
  exclude_filter="scenes/editor/level_editor.tscn, scenes/editor/level_editor_ui.tscn, scripts/editor/*"
  ```
- **Preservação das Malhas de Ilha:** Mantidas normalmente as cenas modulares de terreno 3D em `scenes/editor/tiles/*`, que são utilizadas pelo `level_json_loader.gd` para montar as ilhas nos níveis do jogo.
- As ferramentas de edição (`level_editor.tscn`, `level_editor_ui.tscn` e todos os scripts da pasta `scripts/editor/`) não são empacotadas no arquivo `.pck` / `.apk`.

---

## 3. Validação e Qualidade
- **Zero Warnings / Zero Erros:** Verificado em execução de debug contínua via Godot MCP (`run_project` e `get_debug_output`).
- **SemVer:** Incrementado para **`v0.5.4`** em `project.godot`.
