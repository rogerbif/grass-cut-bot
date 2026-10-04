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

---

## 2. Interface, HUD e Controles

| Arquivo | Título da Melhoria | Destaques Técnicos |
| :--- | :--- | :--- |
| [`001_fundacao_mvp_fase_1.md`](./001_fundacao_mvp_fase_1.md) | Controles Touch e Top HUD Dinâmico | Joystick virtual flutuante na metade inferior da tela com deadzone, top HUD com anel de cronômetro regressivo, metas com escala pop e modais completos. |
| [`002_correcao_erros_hud_e_warnings_divisao.md`](./002_correcao_erros_hud_e_warnings_divisao.md) | Correção de Hierarquia do HUD e Eliminação de Warnings | Correção dos caminhos `@onready` da barra superior (`TopBar/HBox`), eliminação de warnings de divisão inteira em `level_controller.gd` e `hud.gd`. |

---

## 3. Infraestrutura, Arquitetura e Documentação

| Arquivo | Título da Melhoria | Destaques Técnicos |
| :--- | :--- | :--- |
| [`001_fundacao_mvp_fase_1.md`](./001_fundacao_mvp_fase_1.md) | Estruturação da Wiki e Arquitetura Canônica | Implantação da Central de Guardrails `GEMINI.md`, skill de governança contínua, Hub Mestre `PROJETO_GRASS_CUT_BOT.md` e os 5 Pilares Temáticos. |
