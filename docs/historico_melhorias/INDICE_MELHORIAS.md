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
| [`020_modelo_unico_blender_variacoes_cenas_godot.md`](./020_modelo_unico_blender_variacoes_cenas_godot.md) | Consolidação de Modelo Único no Blender e Cenas Base Coloridas no Godot | Malha limpa e neutra no Blender sem sub-objetos, cenas base modulares no Godot para cada cor (verde, amarelo, azul, roxo) e redução de 75% na contagem de nós de malha. |
| [`021_reimportacao_tufo_grama_392_vertices.md`](./021_reimportacao_tufo_grama_392_vertices.md) | Reimportação do Tufo de Grama Refinado do Blender (392 Vértices) | Enriquecimento da malha para 392 vértices e 280 faces (área de cobertura de 1m x 1m), preservação da ancoragem UV e recompilação do glTF. |
| [`022_animacao_pendular_folhas_e_particulas_corte.md`](./022_animacao_pendular_folhas_e_particulas_corte.md) | Animação Pendular Independente de Folhas e Partículas de Corte em Pedaços | Balanço lateral e respiração independente por folha via atributos de vértice (COLOR) no Vertex Shader, malha estilizada de folhas partidas (cut_leaf_piece.obj), gravidade física e tumbling 3D. |
| [`023_ancoragem_base_folhas_e_calibracao_particulas.md`](./023_ancoragem_base_folhas_e_calibracao_particulas.md) | Ancoragem Rígida da Base das Folhas e Calibração de Partículas de Corte | Eixo de dobradiça 100% fixo no solo via smoothstep na raiz, compensação de arco em Y, aumento de 50% nas partículas (30 folhas) e lançamento contido com gravidade rápida. |
| [`024_calibracao_escala_grama_e_particulas_ampliadas.md`](./024_calibracao_escala_grama_e_particulas_ampliadas.md) | Calibração da Escala dos Tufos de Grama e Partículas Ampliadas com Variação Dinâmica | Redução da escala da grama em ~20% (0.70 a 0.90), fatiamento imediato (0.04s) sem sensação de murchar e partículas de folhas ampliadas em 50% com escala variável (1.2 a 2.4). |
| [`025_emissao_em_area_giro_3d_e_aleatoriedade_particulas.md`](./025_emissao_em_area_giro_3d_e_aleatoriedade_particulas.md) | Emissão em Área Circular, Giro no Ar e Alta Aleatoriedade de Trajetória | Emissão distribuída por disco de 0.35m (área do tufo), ativação de giro 3D (particle_flag_rotate_y = true de -540° a 540°/s) e espalhamento caótico hemisférico (spread = 85°). |
| [`026_remocao_folga_grade_vegetacao.md`](./026_remocao_folga_grade_vegetacao.md) | Remoção de Folga Livre e Padronização do Gramado Contínuo | Espaçamento canônico reduzido para 0.80m, escala horizontal calibrada (0.95 ~ 1.10m) e sobreposição de folhas sem gaps ou chão visível na grade de fases. |
| [`027_rotacao_lenta_lamina_idle.md`](./027_rotacao_lenta_lamina_idle.md) | Rotação Suave em Marcha Lenta (Idle) da Lâmina | Rotação suave de 90°/s quando parado (idle), aceleração instantânea de corte em movimento e desaceleração inercial ao soltar o joystick. |
| [`029_tileset_terreno_3d_e_cantos_arredondados.md`](./029_tileset_terreno_3d_e_cantos_arredondados.md) | 3D Terrain Tileset Modular com Cantos Arredondados e Aplicação no Editor | Criação de tileset 3D no Blender com quinas cilíndricas suaves (R=0.28m e R=0.80m), lábio de grama sobreposto, textura atlas GRADIENT, exportação GLB otimizada e integração nas 5 cenas do editor de fases com 0 warnings. |



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
| [`028_editor_de_fases_pc_ilhas_3d_e_carimbos.md`](./028_editor_de_fases_pc_ilhas_3d_e_carimbos.md) | Editor de Fases In-Game para PC (Tela Cheia), Ilhas 3D e Carimbos | Editor de fases full-screen PC isolado do mobile, kit de Ilhas 3D sobre o oceano sem cercas com Auto-Tile e colisão costeira invisível, carimbos de formas (Coração, Estrela, Círculo, Quadrado), persistência JSON e Playtest via F1. |
