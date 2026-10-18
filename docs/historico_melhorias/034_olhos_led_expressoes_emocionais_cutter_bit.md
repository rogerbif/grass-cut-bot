# Melhoria 034: Olhos de LED e Sistema de Expressões Emocionais do Cutter Bit [v0.7.0] 🌿🤖👁️

Este documento registra a implementação completa do sistema de **Olhos de LED com Expressões Digitais** na cabeça do robô cortador (*Cutter Bit*), baseado na arte conceitual oficial do projeto.

---

## 📋 Resumo Executivo
- **Data da Conclusão:** Outubro de 2026
- **Versão SemVer:** `v0.7.0` (Minor release - Nova funcionalidade visual e comportamental)
- **Domínio:** Modelagem 3D (Blender), Shaders Godot 4, Expressões e Game Feel
- **Objetivos Entregues:**
  1. Modelação da malha do visor digital contínuo (`screen_display`) no Blender com remoção das lentes circulares antigas e mapeamento UV retangular limpo de $(0, 0)$ a $(1, 1)$.
  2. Criação do Atlas Vetorial SVG (`assets/textures/cutter/eyes_atlas.svg`) contendo as 10 expressões canônicas da concept art.
  3. Desenvolvimento do Shader customizado `shaders/eye_display.gdshader` com scanlines de LED, brilho neon emissivo, suporte a cor dinâmica e efeito de piscar procedural via UV.
  4. Implementação do controlador de humor `scripts/cutter/robot_eyes.gd` acoplado à inércia física, aceleração, choque contra rochas, pausa e vitória.
  5. Exportação glTF padronizada para `assets/models/grass_bot.glb` com `export_apply=True` e `export_yup=True`.
  6. Validação estrita de **Zero Warnings** e **Zero Erros** na Godot 4.7.1.

---

## 🎭 As 10 Expressões Canônicas Implementadas

| Índice | Nome | Visual | Comportamento no Jogo |
| :---: | :--- | :--- | :--- |
| **0** | **Padrão (Normal)** | Círculos cheios ciano | Estado base durante locomoção normal; pisca autonomamente a cada 3~6s. |
| **1** | **Feliz (Happy)** | Arcos `^ ^` estilo kawaii | Ativado durante combos de corte contínuo de grama e alta velocidade. |
| **2** | **Triste / Danificado** | Arcos caídos com pálpebras | Reação a danos ou falhas de corte. |
| **3** | **Bravo (Angry)** | Polígonos angulados agressivos | **Modo de Ataque:** ativado com cor vermelha viva ao colidir contra rochas. |
| **4** | **Alerta (Alert)** | Anéis vazados `O O` em amarelo | Reação a proximidade de obstáculos ou avisos de tempo. |
| **5** | **Dormindo (Sleeping)** | Traços horizontais `— —` | Ativado automaticamente após 5.5 segundos sem entrada do jogador (idle). |
| **6** | **Confuso / Pane (Glitch)** | Interrogação `?` e espiral `@` | Pulso de ruído elétrico durante o ricochete de impacto. |
| **7** | **Piscando / Esperto (Wink)** | Círculo `O` e traço `—` | Transição charmosa de piscar de um olho. |
| **8** | **Vitória (Victory)** | Estrela `★` e Coração `♥` | Disparado com pulso de brilho neon quando o jogador conclui a fase. |
| **9** | **Desligado (Off)** | Tela escura com scanlines cinzas | Ativado quando o jogo entra no menu de pausa ou quando sem bateria. |

---

## 🔍 Comparativo: Cenário Anterior vs Novo Cenário

| Componente | Antes (v0.6.0) | Agora (v0.7.0 - Olhos de LED Dinâmicos) |
| :--- | :--- | :--- |
| **Viseira do Robô** | Duas lentes cilíndricas estáticas com material de cor ciano sólida fixa | Tela digital contínua embutida na viseira chanfrada com acabamento fosco e scanlines |
| **Expressões Faciais** | Nenhuma (olhar 100% inanimado e estático) | 10 expressões dinâmicas com piscar procedural suave e olhar direcional de pupila |
| **Reação a Rochas** | Apenas ricochete mecânico e faíscas de serra | Transição instantânea para olhos bravos em vermelho com distorção de glitch elétrico |
| **Fim de Fase** | Apenas abertura da tela de vitória | Robô comemora com olhos de Estrela e Coração iluminados em neon |
| **Pausa de Jogo** | Nenhuma alteração visual no robô | Tela do visor apaga suavemente, mantendo apenas as scanlines digitais da matriz desligada |

---

## 🛡️ Conformidade de Guardrails Invariantes
- **Zero Warnings Estrito (Guardrail 1):** Validado no console Godot 4.7.1 sem avisos.
- **Tipagem Estática (Guardrail 10):** Tipagem forte aplicada em todos os métodos e propriedades de `robot_eyes.gd` e `cutter.gd`.
- **Performance Mobile Estrita (Guardrail 7):** Tela unshaded e leve operando em um único draw call, sem necessidade de SubViewports em tempo real.
- **Pipeline Blender glTF Seguro (Guardrail 12):** Exportado com `export_apply=True` e `export_yup=True`.

---

## 📦 Artefatos e Arquivos Criados/Modificados
- `assets/textures/cutter/eyes_atlas.svg`: Atlas de vetores em alta definição (grid 4x4).
- `shaders/eye_display.gdshader`: Shader espacial com scanlines, piscar procedural e controle de matriz.
- `shaders/eye_display_material.tres`: Recurso de material pré-configurado.
- `scripts/cutter/robot_eyes.gd`: Script do controlador de expressões.
- `scenes/cutter/cutter.tscn`: Nó `RobotEyes` adicionado à hierarquia.
- `scripts/cutter/cutter.gd`: Integração dos eventos mecânicos e de estado de jogo aos olhos.
- `assets/models/grass_bot.glb`: Modelo 3D reexportado com a nova malha do visor.
- `project.godot`: Versão elevada para `v0.7.0`.
