# Melhoria 078: Calibração de Safe Zone para Ícone Adaptativo Android [v0.12.20-alpha] 📱🌿🤖

Este documento registra a correção e calibração arquitetural de toda a suíte de ícones de marca do **Grass Cut Bot**, adequando o emblema oficial aos requisitos canônicos de **Adaptive Icons** do Android (Google Safe Zone de 72dp em canvas de 108dp) e eliminando qualquer corte em telas de aparelhos modernos (Xiaomi HyperOS / MIUI, Samsung One UI, Google Pixel, etc.).

---

## 📋 Resumo Executivo
- **Data da Conclusão:** Outubro de 2026
- **Versão SemVer:** `v0.12.20-alpha` (Code: `1220`)
- **Domínio:** Brand Assets, Portabilidade Android, Identidade Visual e Exportação Mobile
- **Objetivos Entregues:**
  1. **Diagnóstico da Máscara do Launcher:** Identificação de que o ícone oficial anterior preenchia 100% da área do canvas 432x432, fazendo com que a máscara do squircle do Xiaomi cortasse o letreiro "GRASS CUT BOT", o topo da cabeça do robô e a base da ilha.
  2. **Calibração da Safe Zone (~67%):** Redimensionamento proporcional de alta fidelidade (Bicubic + AntiAlias) do emblema completo (logo estilizado, robô Cutter Bit sorrindo, lâminas e ilha sobre o mar) para ocupar os 288px centrais (72dp) do canvas de 432px (e escalas proporcionais nos demais tamanhos).
  3. **Extensão de Fundo Tropical:** Implementação de gradiente vertical suave de céu tropical para oceano profundo (`#6EE6FD` a `#1E98D0`), preenchendo as bordas de 432x432 px sem bordas pretas ou espaços vazios.
  4. **Camadas Adaptive Foreground & Background:**
     - `res://assets/brand/icon_432.png`: Camada frontal calibrada na Safe Zone.
     - `res://assets/brand/icon_adaptive_background_432.png`: Nova camada de fundo contínuo dedicada.
     - `export_presets.cfg` atualizado vinculando ambas as camadas.
  5. **Atualização da Suíte de Marca Completa:**
     - `icon.png` e `assets/brand/icon_1024.png` (1024x1024)
     - `assets/brand/icon_512.png` (512x512)
     - `assets/brand/icon_192.png` (192x192)
     - `icon.svg` com novo vetor Base64 embutido.
  6. **Sincronização Game SemVer:** Bump para `v0.12.20-alpha` (`version/code=1220`) em `GameVersion`, `project.godot` e `export_presets.cfg`.

---

## 🛡️ Conformidade de Guardrails Invariantes
- **Zero Warnings Estrito (Guardrail 1):** Zero warnings e zero erros validados na engine.
- **Portabilidade Mobile (Guardrail 3 e 10):** Conformidade rigorosa com a especificação de Adaptive Icons do Android 8.0+.
- **PowerShell e Sem BOM (Guardrail 2):** Todos os assets e arquivos de configuração gravados em UTF-8 sem BOM.
- **Versionamento e Git (Guardrail 11 & Protocolo Skill):** Sincronização remota via `git push origin main`.
