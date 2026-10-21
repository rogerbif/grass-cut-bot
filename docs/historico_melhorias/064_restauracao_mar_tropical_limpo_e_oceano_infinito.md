# Histórico de Melhoria: Restauração do Mar Tropical Limpo e Preservação do Oceano Infinito 🌊🏝️

**ID:** `064_restauracao_mar_tropical_limpo_e_oceano_infinito`  
**Versão:** `v0.10.1-alpha`  
**Data:** 21/10/2026  
**Status:** Concluído e Validado (0 Warnings no Godot 4.7.1)  

---

## 1. Contexto e Diagnóstico

Após o teste com o shader procedural de água ("Wind Waker"), o visual resultante apresentou artefatos visuais indesejados (aparência de manchas brancas caóticas com furos azuis desproporcionais, gerando poluição visual severa em contraste com o gramado e os modelos 3D das ilhas).

Além disso, o estilo visual canônico do projeto estabelecido no **Mandamento 7 do GEMINI.md** determina:
- Estilo Low Poly fosco com cores sólidas vibrantes e superfícies limpas (`roughness = 0.85 ~ 0.95`).
- A sensação de mar é proporcionada com excelência pela cor azul turquesa tropical homogênea em conjunto com a fita animada de espuma costeira (`CoastalFoamRibbon`) nas falésias das ilhas.

---

## 2. Ações Executadas

1. **Restauração do Material Canônico Limpo:**
   - Em `scenes/menu/main_menu.tscn` e `scenes/level/water_ocean.tscn`:
     - Removido o shader de água que gerava as manchas brancas e restaurado o material fosco arcade oficial (`StandardMaterial3D`, `albedo_color = Color(0.18, 0.65, 0.82)` no menu e `Color(0.18, 0.65, 0.78)` no gameplay, `roughness = 0.88`).
     - Excluídos os arquivos temporários `shaders/wind_waker_water.gdshader` e `shaders/wind_waker_water_material.tres`.
2. **Preservação da Correção do Oceano Infinito:**
   - Mantida a ampliação da malha para $320\text{m} \times 320\text{m}$.
   - Mantido o **camera-tracking** em `scripts/menu/main_menu.gd` (`ocean_mesh.global_position.xz = menu_camera.global_position.xz`).
   - Com isso, o problema original (mar que acabava fisicamente logo após a Fase 5 e revelava o céu azul claro de fundo) permanece **100% resolvido**: o mar é contínuo, límpido, homogêneo e sem quebras visuais em todas as 20 fases do mapa.

---

## 3. Validação e Testes

- **Godot Debug Runner (MCP):**
  - Cenas `scenes/menu/main_menu.tscn` e `scenes/main.tscn` executadas sem nenhum erro ou aviso (**0 warnings e 0 erros**).
  - O mar agora é uniforme, limpo, vibrante e esteticamente harmonioso com o estilo do jogo.

---

## 4. Arquivos Modificados

| Arquivo | Descrição |
| :--- | :--- |
| `scenes/menu/main_menu.tscn` | Restauração do material de água limpo fosco mantendo o plano de 320x320m. |
| `scenes/level/water_ocean.tscn` | Restauração do material de água limpo fosco original nas fases jogáveis. |
| `docs/01_visao_geral_e_gdd/DIRECAO_DE_ARTE_E_VISUAL.md` | Atualização da tabela de paleta oficial. |
| `docs/historico_melhorias/INDICE_MELHORIAS.md` | Indexação da melhoria. |
| `scripts/core/game_version.gd`, `project.godot`, `export_presets.cfg` | Atualização SemVer para `v0.10.1-alpha` (code `1001`). |
