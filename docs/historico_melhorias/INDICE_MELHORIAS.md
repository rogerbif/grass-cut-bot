# Catálogo Mestre do Histórico de Melhorias (Changelog) 📜🌿

Este documento é o **Índice Canônico e Catálogo de Navegação** de todas as implementações, melhorias, refatorações e construções mecânicas realizadas no projeto **Grass Cut Bot**, em conformidade estrita com o [Protocolo Operacional Contínuo do GEMINI.md](../../GEMINI.md).

> Para a visão executiva e o planejamento das próximas etapas, consulte o [Roadmap de Melhorias Futuras](../MELHORIAS_FUTURAS.md).

---

## 🗂️ Categorias do Ecossistema

- [1. Gameplay, Mecânicas e Entidades](#1-gameplay-mecânicas-e-entidades)
- [2. Interface, HUD e Controles](#2-interface-hud-e-controles)
- [3. Infraestrutura, Arquitetura e Documentação](#3-infraestrutura-arquitetura-e-documentação)

---

## 1. Gameplay, Mecânicas e Entidades

| Arquivo | Título da Melhoria | Destaques Técnicos |
| :--- | :--- | :--- |
| [`001_fundacao_mvp_fase_1.md`](./001_fundacao_mvp_fase_1.md) | Fundação do Projeto e MVP da Fase 1 | Cortador circular omnidirecional, corte radial por contato, tufos de grama/trigo/flores, física de ricochete com rochas e partículas parabólicas. |
| [`002_shader_interativo_grama_arnklit.md`](./002_shader_interativo_grama_arnklit.md) | Shader de Grama Interativa (Arnklit) | Deformação radial de vértices via Shader globals, oscilação de vento procedural, gradiente de cores da raiz ao topo e preservação da colheita. |
| [`003_modelo_lamina_primitivas_godot.md`](./003_modelo_lamina_primitivas_godot.md) | Modelagem da Lâmina Estilizada com Primitivas Godot | Hub central com botão em domo azul, asas aerodinâmicas duplas de perfil hélice e arcos crescentes de vento (swoosh trails) de alta rotação. |
| [`004_refinamento_distribuicao_curvatura_grama.md`](./004_refinamento_distribuicao_curvatura_grama.md) | Refinamento da Distribuição em Leque e Curvatura Elástica da Grama | Arquitetura de 5 lâminas PrismMesh em leque/cálice radial com inclinações orgânicas, curvatura elástica não-linear exponencial e compressão Y no corte. |
| [`007_integracao_modelo_3d_robo_e_laminas_loja.md`](./007_integracao_modelo_3d_robo_e_laminas_loja.md) | Integração do Modelo 3D do Robô Cortador, Lâminas Modulares e Evolução na Loja | Modelo 3D oficial do Blender com rotor no blade_container (3 tiers de lâminas), exportação glTF, rolagem de mono-wheel, direção suave e evolução na Oficina. |

---

## 2. Interface, HUD e Controles

| Arquivo | Título da Melhoria | Destaques Técnicos |
| :--- | :--- | :--- |
| [`001_fundacao_mvp_fase_1.md`](./001_fundacao_mvp_fase_1.md) | Controles Touch e Top HUD Dinâmico | Joystick virtual flutuante na metade inferior da tela com deadzone, top HUD com anel de cronômetro regressivo, metas com escala pop e modais completos. |
| [`002_correcao_erros_hud_e_warnings_divisao.md`](./002_correcao_erros_hud_e_warnings_divisao.md) | Correção de Hierarquia do HUD e Eliminação de Warnings | Correção dos caminhos `@onready` da barra superior (`TopBar/HBox`), eliminação de warnings de divisão inteira em `level_controller.gd` e `hud.gd`. |
| [`005_camera_isometrica_translacao_pura_xz.md`](./005_camera_isometrica_translacao_pura_xz.md) | Câmera Isométrica com Translação Pura (X e Z) | Travamento estrito da orientação angular no `_ready()`, eliminação de `look_at()` a cada frame e translação suave exclusiva nos eixos horizontais. |
| [`006_modal_fim_de_fase_e_desativacao_lamina.md`](./006_modal_fim_de_fase_e_desativacao_lamina.md) | Botão Exclusivo de Repetir Fase e Desativação da Lâmina | Botão único "Repetir Fase 🔄" nos modais de vitória e derrota, suporte híbrido a clique e touch, e desativação total de movimento/rotação da lâmina no fim de fase. |

---

## 3. Infraestrutura, Arquitetura e Documentação

| Arquivo | Título da Melhoria | Destaques Técnicos |
| :--- | :--- | :--- |
| [`001_fundacao_mvp_fase_1.md`](./001_fundacao_mvp_fase_1.md) | Estruturação da Wiki e Arquitetura Canônica | Implantação da Central de Guardrails `GEMINI.md`, skill de governança contínua, Hub Mestre `PROJETO_GRASS_CUT_BOT.md` e os 5 Pilares Temáticos. |
