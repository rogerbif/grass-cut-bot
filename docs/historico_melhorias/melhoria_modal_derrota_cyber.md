# Relatório de Melhoria: Novo Modal de Derrota Cyberpunk Neon (`DefeatModal`) 💥🌿

**Versão:** `v0.12.128-alpha`
**Status:** Concluído com Sucesso

## 🎯 Entregas
1. **Novo componente `DefeatModal`** (`scenes/ui/defeat_modal.tscn`, `scripts/ui/defeat_modal.gd`) substituindo o `GameOverModal` legado do `hud.tscn`: card chanfrado vermelho/roxo neon, animação Grow + Fade, pulso de brilho, UI 100% programática (Guardrail 13).
2. **Dados dinâmicos:** Progresso do Corte (%) com barra gradiente, metas restantes com ícones da Coleção e subtítulo variável (≥ 70% = "Faltou pouco...").
3. **Ações:** Repetir Fase, **Pegar Mais Tempo** (placeholder de anúncio recompensado: +15s, 1 uso por tentativa) e Menu Inicial.
4. **`GameManager`:** `get_progress_ratio()`, `get_remaining_goals()`, `can_grant_extra_time()` e `grant_extra_time(seconds)`.
5. **Novos SVGs** em `assets/ui/defeat/` (card, botões retry/extra time, cronômetro vermelho, alerta, TV, restart laranja).

## ✅ Validação
- Captura do modal renderizado e teste de fluxo (derrota → tempo extra → estado `PLAYING` com 15s → segunda derrota sem botão de tempo extra), sem erros de script.

## 📂 Arquivos
`scripts/ui/defeat_modal.gd`, `scenes/ui/defeat_modal.tscn`, `scenes/ui/hud.tscn`, `scripts/ui/hud.gd`, `scripts/core/game_manager.gd`, `assets/ui/defeat/*`, `project.godot`, `scripts/core/game_version.gd`, `docs/04_sistemas_e_gameplay/SISTEMA_DE_INTERFACE_HUD.md`.