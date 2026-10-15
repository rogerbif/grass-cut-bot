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
| [`008_colorizacao_detalhada_robo_concept_art.md`](./008_colorizacao_detalhada_robo_concept_art.md) | Colorização Detalhada do Robô Conforme Arte Conceitual | Pintura mecha/arcade no Blender: máscara dos olhos, pupilas ciano, placas de blindagem brancas, cubo da mono-wheel detalhado e LED traseiro. |
| [`009_ajuste_escala_lamina_e_orientacao_frontal.md`](./009_ajuste_escala_lamina_e_orientacao_frontal.md) | Lâmina 1.5x Maior e Correção da Orientação Frontal do Robô | Ampliação da lâmina e deck em 1.5x (raio 0.98m) e correção angular da frente do robô para olhar no sentido de condução. |
| [`010_ajuste_preto_borracha_e_retorno_escala_lamina.md`](./010_ajuste_preto_borracha_e_retorno_escala_lamina.md) | Escurecimento do Preto da Borracha e Calibração de Escala da Lâmina | Escurecimento do material M_Borracha_Preta para preto grafite profundo (#141416) e calibração da lâmina para o tamanho base 1.0x (raio 0.65m). |
| [`011_correcao_mirror_export_gltf_modelo_robo.md`](./011_correcao_mirror_export_gltf_modelo_robo.md) | Correção do Mirror Modifier no Export glTF do Robô Cortador | Ativação obrigatória de export_apply=True no glTF exporter do Blender para inclusão simétrica de ambos os lados do chassi do robô. |
| [`012_nova_lamina_tripla_tier_1.md`](./012_nova_lamina_tripla_tier_1.md) | Nova Lâmina Tripla de Aço (3 Pontas) para o Tier 1 | Modelagem da lâmina de 3 pontas inspirada em roçadeira/shuriken, substituindo a lâmina básica nos níveis 1 e 2. |
| [`013_nova_lamina_quadrupla_tier_2.md`](./013_nova_lamina_quadrupla_tier_2.md) | Nova Lâmina Quádrupla Ninja (4 Pontas) para o Tier 2 | Modelagem da lâmina de 4 pontas em cruz com o mesmo alcance da Tier 1 e integração ao Tier 2 da Oficina. |
| [`014_suspensao_procedural_e_inclinacao_dinamica_robo.md`](./014_suspensao_procedural_e_inclinacao_dinamica_robo.md) | Suspensão Procedural, Inclinação Dinâmica e Articulações do Robô | Suspensão vertical com bobbing reativo da roda, rotação compensatória dos braços em X, pitch/roll do chassi, estabilização do pescoço e antecipação de olhar da cabeça. |
| [`015_familia_laminas_estreladas_e_amarelo_vibrante.md`](./015_familia_laminas_estreladas_e_amarelo_vibrante.md) | Família de Lâminas Estreladas Geométricas (3, 4, 5 e 6 Pontas) e Amarelo Vibrante | 4 lâminas estreladas com arestas retas, furo central e acabamento uniforme em aço cinza reflexivo, além de amarelo mais forte e saturado no robô. |
| [`016_variacoes_grama_grass_01_cores_solidas.md`](./016_variacoes_grama_grass_01_cores_solidas.md) | Variações de Grama Low Poly Estilizada (grass_01) em Cores Sólidas | Malha compacta de 112 vértices (grass_varien_4_grass_0), remoção total de texturas rasterizadas, 4 variações de cores sólidas foscas (verde, amarelo, azul, roxo) dispostas lado a lado e exportação glTF para Godot 4. |
| [`017_substituicao_grama_pelo_modelo_grass_01.md`](./017_substituicao_grama_pelo_modelo_grass_01.md) | Substituição da Grama do Jogo pelo Novo Modelo 3D (grass_01) | Integração de grass_01.glb em grass_tuft.tscn com origens centradas, suporte dinâmico a 4 variantes de cor no plant.gd e corte responsivo no gameplay. |
| [`018_restauracao_animacao_vento_e_interacao_grama_3d.md`](./018_restauracao_animacao_vento_e_interacao_grama_3d.md) | Restauração da Animação de Vento e Interatividade no Modelo 3D | Aplicação do shader espacial interactive_grass em todas as 4 variantes de cores, balanço orgânico de vento e curvatura/compressão reativa à serra. |
| [`019_migracao_fases_para_cenas_godot_edicao_manual.md`](./019_migracao_fases_para_cenas_godot_edicao_manual.md) | Migração de Fases para Cenas Godot (.tscn) e Edição Manual da Fase 1 | Conversão das fases em cenas independentes (level_01.tscn), 56 tufos editáveis visualmente no Viewport 3D, detecção reativa de metas e carregador dinâmico com fallback procedural. |


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
