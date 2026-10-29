# Melhoria 159: Nova Navbar Modular em Atomic Design (CyberNavButton) 🧭🤖

## 📋 Resumo da Solicitação
O usuário solicitou a recriação completa dos botões da **BottomNavBar** no estilo visual das referências conceituais, mantendo os ícones e rótulos atuais, com arquitetura modular baseada em **Atomic Design** e com a nova ordem visual canônica das abas aprovada: `[Home = 0, Garage = 1, Collection = 2, Store = 3]`.

---

## 🛠️ Arquitetura e Implementação Técnica

### 1. Átomos (Atoms)
- **`assets/ui/navbar/nav_tab_active_bg.svg`**:
  - Badge trapezoidal elevado (`180x110`) com quinas superiores chanfradas em ~45°, gradiente vertical cyber marinho profundo (`#054564` a `#011626`) e contorno luminoso em gradiente ciano neon (`#00f5ff` a `#005580`).
- **`assets/ui/navbar/nav_tab_indicator.svg`**:
  - Pílula neon luminosa horizontal (`90x12`) com halo difuso e núcleo vítreo branco/ciano (`#20e9fe`), posicionada na borda inferior da aba ativa.
- **`assets/ui/navbar/nav_bar_chassis.svg`**:
  - Chassi de base da barra (`720x96`) com extremidades cortadas em ângulo chanfrado cyber, contorno de topo ciano e recortes tecnológicos.
- **Ícones Silhueta Vetoriais Monocromáticos (`assets/icons/navbar/`)**:
  - `nav_icon_home.svg`: Silhueta branca da casa com porta vazada.
  - `nav_icon_garage.svg`: Silhueta branca da chave inglesa com anel vazado.
  - `nav_icon_collection.svg`: Silhueta branca do broto com 3 folhas orgânicas e haste.
  - `nav_icon_store.svg`: Silhueta branca da loja com toldo ondulado e vitrine vazada.
  - Permite colorização e modulação perfeitas via `modulate = Color(...)` no Godot.

### 2. Molécula: `CyberNavButton` (`scenes/ui/cyber_nav_button.tscn` + `scripts/ui/cyber_nav_button.gd`)
- Componente independente instanciável para cada botão da barra.
- Propriedades exportadas: `tab_id`, `title_text`, `icon_texture`.
- Gerenciamento reativo de estado:
  - **Ativo:** Badge elevado visível, indicador neon inferior aceso, escala ampliada (`1.06x`) e cor em ciano elétrico vibrante (`#0efaff`).
  - **Inativo:** Badge oculto, sem indicador, escala neutra (`1.0x`) e cor suave em azul-aço acinzentado (`#6b8cb8`).
- Transições animadas suaves via `Tween` paralelo para `modulate` e `scale`.
- Feedback háptico de 15ms (`Input.vibrate_handheld(15)`) e áudio de confirmação (`AudioManager.play_sfx("confirm")`).

### 3. Organismo: `BottomNavBar` (`scenes/menu/bottom_nav_bar.tscn` + `scripts/menu/bottom_nav_bar.gd`)
- Orquestrador modular com chassi contínuo e contêiner `HBoxContainer`.
- Garante seleção exclusiva: ao ativar uma aba, desativa a anterior com interpolação de retorno.
- Dispara o sinal unificado `tab_changed(tab_id: int)`.
- Ordem visual aprovada:
  1. `BtnHome` (`tab_id = 0`)
  2. `BtnGarage` (`tab_id = 1`)
  3. `BtnCollection` (`tab_id = 2`)
  4. `BtnStore` (`tab_id = 3`)

### 4. Integração no `main_menu.gd`
- Atualização do mapeamento de abas para `[tab_home, tab_garage, tab_collection, tab_store]`.
- Jogo inicializa diretamente na aba Home (`_switch_tab(0)`).

---

## 📸 Validação Visual em Tempo de Execução
- Validadas todas as 4 abas ativas via script de teste no motor Godot 4.7:
  - `navbar_tab_home.png`
  - `navbar_tab_garage.png`
  - `navbar_tab_collection.png`
  - `navbar_tab_store.png`
- Console com 0 warnings e conformidade estrita de tipagem GDScript.

---

## 📦 Versionamento SemVer
- Versão incrementada para `0.12.89-alpha` (PATCH +1) em `project.godot`, `game_version.gd` e `export_presets.cfg`.
