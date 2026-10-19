# Melhoria 040: Novo Ícone Oficial do Jogo (Fotografia 3D do Cutter Bit Sorrindo) [v0.7.3] 🌿🤖📸

Este documento registra a recriação do ícone oficial do jogo **Grass Cut Bot**, substituindo o antigo vetor genérico por uma fotografia 3D estilizada de alta resolução do protagonista **Cutter Bit** sorrindo.

---

## 📋 Resumo Executivo
- **Data da Conclusão:** Outubro de 2026
- **Versão SemVer:** `v0.7.3` (Patch release - Identidade visual, novo ícone de aplicativo e assets de loja)
- **Domínio:** Identidade Visual, Renderização 3D (Godot 4.7), Shaders e Exportação Mobile
- **Objetivos Entregues:**
  1. **Estúdio Fotográfico Automatizado (`scenes/tools/icon_photo_studio.tscn`):** Cenário de estúdio dedicado configurado com câmera isométrica elevada em $3/4$ (+17°), iluminação profissional de 3 pontos (Key Sun Light, Sky Fill Light e Rim Back Light) e pedestal de gramado insular.
  2. **Expressão Feliz (Sorrindo):** O robô foi configurado na pose carismática com cabeça inclinada e o display de olhos de LED travado na expressão canônica `HAPPY` (arcos ciano luminosos com `emission_energy = 2.2`).
  3. **Cenário e Composição Harmônica:** Fundo com gradiente radial estilizado em azul tropical profundo e halo solar centralizado atrás do capacete (`shaders/icon_backdrop.gdshader`), com lâmina ninja prateada e tufos de grama verde fatiada na base.
  4. **Geração Multirresolução:** Produção automática do Master 1024x1024 (`icon.png`), versão para Google Play / App Store 512x512, Foreground Adaptativo Android 432x432 e Launcher Mobile 192x192.
  5. **Atualização do Projeto e Exportação:** Atualização de `project.godot` para `config/icon="res://icon.png"`, configuração dos ícones em `export_presets.cfg` e vetorização embutida em `icon.svg`.

---

## 🔍 Comparativo: Cenário Anterior vs Novo Cenário

| Componente | Antes | Agora |
| :--- | :--- | :--- |
| **Ícone do Jogo** | Desenho SVG 2D genérico de serra circular plana | Fotografia 3D estilizada do Cutter Bit sorrindo com iluminação de estúdio |
| **Expressão do Robô** | Inexistente (sem personagem no ícone) | Olhos de LED acesos em ciano na expressão `HAPPY` (`^ ^`) |
| **Paleta de Cores** | Verde escuro e cinza industrial | Amarelo solar, branco titanio, ciano emissivo e azul tropical |
| **Pacote de Marcas** | Apenas um `icon.svg` na raiz | Suíte completa em `res://assets/brand/` (1024, 512, 432, 192px) |
| **Launcher Android** | Sem ícones configurados no preset | Vinculado aos novos assets de launcher e adaptive foreground |

---

## 🛡️ Conformidade de Guardrails Invariantes
- **Zero Warnings Estrito (Guardrail 1):** Validação no Godot 4.7.1 com 0 warnings e 0 erros.
- **Tipagem Estática GDScript 4 (Guardrail 10):** Scripts de ferramentas fortemente tipados.
- **Formato UTF-8 sem BOM (Guardrail 2):** Todos os arquivos de configuração e documentação gravados sem BOM.

---

## 📦 Artefatos e Arquivos Modificados
- `icon.png`: Novo ícone mestre de alta resolução (1024x1024).
- `icon.svg`: Vetor SVG com a nova fotografia do robô embutida.
- `assets/brand/icon_1024.png`: Master arquival 1024x1024.
- `assets/brand/icon_512.png`: Ícone para lojas de aplicativos (512x512).
- `assets/brand/icon_432.png`: Ícone foreground adaptativo para Android (432x432).
- `assets/brand/icon_192.png`: Ícone de launcher mobile (192x192).
- `scripts/tools/take_icon_photo.gd`: Script de estúdio fotográfico com pose e salvamento de imagens.
- `scenes/tools/icon_photo_studio.tscn`: Cena 3D do estúdio com iluminação de três pontos e pedestal.
- `shaders/icon_backdrop.gdshader`: Shader espacial unshaded com gradiente de céu e halo solar.
- `project.godot`: Apontamento de `config/icon` para `"res://icon.png"` e bump SemVer para `0.7.3`.
- `export_presets.cfg`: Configuração de launcher e adaptive foreground icons.
