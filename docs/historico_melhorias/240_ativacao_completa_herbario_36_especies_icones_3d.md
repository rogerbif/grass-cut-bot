# Melhoria 240: Ativação Completa do Herbário da Ilha (36 Espécies, Ícones 3D e Filtros) 🌿📖✨

**Data:** 11 de Novembro de 2026  
**Versão:** `v0.12.194-alpha` (Build Code: 1394)  
**Status:** ✅ Concluído e Auditado  
**Tipo:** Interface / Coleção / Economia / Recursos Data-Driven / Arte 3D / i18n  

---

## 🎯 1. Contexto e Motivação

O **Herbário da Ilha** (`TabCollection`) é a vitrine de progressão e maestria botânica do jogador no *Grass Cut Bot*. Anteriormente, a aba apresentava limitações que impediam o aproveitamento total do rico catálogo ecológico do jogo:
1. **Catálogo Restrito e Desatualizado:** Apenas 13 espécies estavam cadastradas como recursos `.tres`, enquanto 23 variedades de flores e canteiros já presentes no jogo e no editor não apareciam no Herbário.
2. **Ícones 2D Planos em Vez de 3D:** Os cards da coleção utilizavam ícones planos simplificados em SVG (`icon_leaf.svg`, `icon_flower.svg`), destoando do visual 3D toon do jogo e dos badges do HUD.
3. **Ausência de Categorização e Filtros:** Com o catálogo crescendo para 36 espécies, uma lista única e linear dificultava a navegação e a localização de recompensas pendentes de resgate.
4. **Falta de Nomes Localizados:** Muitas variedades botânicas não possuíam nomes canônicos e traduzidos nos idiomas suportados (Português, Inglês e Espanhol).

---

## 🛠️ 2. Alterações Implementadas

### A. 36 Recursos Canônicos Data-Driven (`PlantSpeciesData`)
- Criados e consolidados todos os 36 arquivos `.tres` em `data/species/`:
  - **7 Gramas Coloridas:** `grass_green`, `grass_yellow`, `grass_blue`, `grass_purple`, `grass_red`, `grass_white`, `grass_black`.
  - **1 Cultura Agrícola:** `wheat` (Trigo Dourado).
  - **28 Flores Nobres:**
    - 6 Flores Silvestres: `flower` (vermelha), `flower_blue`, `flower_purple`, `flower_white`, `flower_turquoise`, `flower_sunset`.
    - 7 Rosas Nobres: `flower_rose`, `flower_rose_peach`, `flower_rose_wine`, `flower_rose_blue`, `flower_rose_white`, `flower_rose_yellow`, `flower_rose_black`.
    - 7 Margaridas Radiadas: `flower_daisy`, `flower_daisy_pink`, `flower_daisy_orange`, `flower_daisy_yellow`, `flower_daisy_red`, `flower_daisy_blue`, `flower_daisy_bicolor`.
    - 1 Girassol Majestoso: `flower_sunflower`.
    - 4 Tulipas Imperiais: `flower_tulip`, `flower_tulip_yellow`, `flower_tulip_purple`, `flower_tulip_orange`.
    - 3 Canteiros Floridos: `flower_bed`, `flower_bed_white`, `flower_bed_blue`.
- **10 Marcos Progressivos por Espécie:** Cada recurso possui 10 metas rigorosamente crescentes de ceifa (alvos balanceados de 10 a 5.000) e recompensas em moedas verdes (15 a 500 moedas), totalizando 360 marcos de conquista na ilha.
- **Conformidade com Guardrail 14:** Nenhuma espécie genérica; 100% de individualidade botânica em cada recurso, card e contagem.

### B. Ícones 3D Oficiais Estilo Sticker (`GoalIconFactory`)
- Substituída a renderização plana em SVG por ícones 3D dinâmicos gerados via `GoalIconFactory.build_goal_icon(key, 76.0, true)`.
- Cada espécie exibe seu modelo 3D oficial com iluminação toon e contorno duplo de sticker (1px preto + 2px branco), com silhueta escura sombreada quando a planta ainda não foi descoberta pelo jogador.

### C. Barra de Filtros Dinâmica por Categoria
- Implementada barra de filtros deslizante horizontal (`ScrollContainer` + `HBoxContainer`) no topo da lista:
  - **🌿 Todas:** Exibe as 36 espécies.
  - **🌱 Gramas (7):** Filtra apenas variedades de grama.
  - **🌾 Culturas (1):** Filtra o trigo dourado.
  - **🌸 Flores (28):** Filtra todas as flores, rosas, margaridas, tulipas, girassol e canteiros.
  - **⭐ Resgatar:** Filtra exclusivamente as plantas com marcos concluídos e recompensas aguardando coleta.
- Badges com contagens em tempo real e visual Cyber com botões destacados para o filtro ativo.

### D. Feedback Audiovisual & Resgate em Lote
- Resgate de marco individual com feedback sonoro `AudioManager.play_sfx("buy")` e vibração háptica `GameManager.trigger_haptic_cut()`.
- Botão **"Coletar Tudo"** no topo atualizado para iterar por todas as 36 espécies e recolher atomicamente todos os marcos pendentes.

### E. Internacionalização Completa (i18n)
- Registradas chaves de tradução em `data/translations/translations.csv` para os 36 nomes botânicos e as categorias de filtro nos 3 idiomas suportados: Português (`pt-BR`), Inglês (`en-US`) e Espanhol (`es-ES`).
- Reimportação atômica dos binários `.translation` na engine.

---

## 🧪 3. Validação e Testes

- **`tests/test_collection_system.gd`:** Atualizado para validar 36 espécies, 10 marcos por espécie, persistência no `SaveManager` e comutação de todos os 5 filtros de UI no `TabCollection`. Aprovado com 100% de sucesso.
- **`tests/test_all_botanical_variations.gd`:** Executado com sucesso, garantindo compatibilidade com shaders cel-shaded, grades e fases.
- **Godot Engine Headless Import:** 0 erros e 0 warnings no console.
- **Conformidade com Guardrails:** Nenhuma fase `data/levels/level_*.json` foi tocada (Guardrail 17).
