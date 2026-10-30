# Melhoria 161: Padronização Visual da TopBar (Forma e Efeito de Borda no Badge de Vidas) 🪙❤️⚙️

## 📋 Resumo da Solicitação
O usuário solicitou os seguintes refinamentos na TopBar:
1. **Unificação da Forma e Efeito de Borda:** Aplicar no badge de **Vidas** a mesma geometria chamfrada e o mesmo efeito gradiente/brilho de borda ciano utilizado no badge de **Moedas** (substituindo o formato anterior chanfrado à direita em roxo).
2. **Ajuste de Proporção do Botão de Configurações:** Calibrar a largura do botão de engrenagem no canto direito para espelhar as proporções exatas da referência conceitual (`58x52px`).

---

## 🛠️ Alterações Realizadas

### 1. `assets/ui/topbar/badge_life_bg.svg`
- Substituída a geometria e paleta de borda anterior pelo formato canônico idêntico ao do badge de moedas:
  - Corte chamfrado nos cantos superior-esquerdo (`10px`) e inferior-direito (`12px`).
  - Borda luminosa com gradiente ciano neon (`#2bd9fe` a `#0e5676`).
  - Traço de realce cibernético no topo (`#8bf0ff`).
  - Fundo dark navy profundo (`#0a1d30` a `#050e18`).

### 2. `scenes/menu/main_menu.tscn`
- Botão de configurações (`SettingsButton`) ajustado com largura calibrada em `custom_minimum_size = Vector2(58, 52)`.

---

## 📸 Validação Visual em Tempo de Execução
- Captura de tela gerada em tempo real no Godot 4.7 (`topbar_adjusted_preview.png`) demonstrando simetria e harmonia perfeita entre ambos os badges e o botão de configurações.
- 0 warnings no console da Godot.

---

## 📦 Versionamento SemVer
- Versão incrementada para `0.12.91-alpha` (PATCH +1) em `project.godot`, `game_version.gd` e `export_presets.cfg`.
