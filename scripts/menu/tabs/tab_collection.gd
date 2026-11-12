extends Control

## TabCollection: Herbário da Ilha & Itens
## Exibe o catálogo oficial das 36 espécies botânicas ordenadas por fase (origin_level),
## em cards horizontais completos com estética cyber-botânica fiel à referência visual,
## rastreamento de colheitas, progresso da enciclopédia e resgate dos 10 níveis de marcos.

const PlantDatabaseScript = preload("res://scripts/plants/plant_database.gd")
const GoalIconFactoryScript = preload("res://scripts/ui/goal_icon_factory.gd")

const TEX_CARD_BG: Texture2D = preload("res://assets/ui/collection/card_species_bg.svg")
const TEX_BADGE_DISC: Texture2D = preload("res://assets/ui/collection/badge_discovered.svg")
const TEX_BADGE_LOCK: Texture2D = preload("res://assets/ui/collection/badge_locked.svg")
const TEX_ICON_FRAME: Texture2D = preload("res://assets/ui/collection/icon_frame_cyber.svg")
const TEX_BADGE_MILESTONE: Texture2D = preload("res://assets/ui/collection/badge_milestone_cyber.svg")
const TEX_BTN_CLAIM: Texture2D = preload("res://assets/ui/collection/btn_claim_cyber.svg")
const TEX_ILLUS_LOCKED: Texture2D = preload("res://assets/ui/collection/illus_locked_plant.svg")

@onready var title_label: Label = $Panel/MainVBox/HeaderVBox/TitleHBox/Title
@onready var subtitle_label: Label = $Panel/MainVBox/HeaderVBox/Subtitle
@onready var prog_label: Label = $Panel/MainVBox/HeaderVBox/ProgBox/ProgressOverlay/ProgLabel
@onready var progress_bar: TextureProgressBar = $Panel/MainVBox/HeaderVBox/ProgBox/ProgressOverlay/ProgressBar
@onready var btn_claim_all: Button = $Panel/MainVBox/HeaderVBox/ProgBox/BtnClaimAll
@onready var chip_harvest_label: Label = $Panel/MainVBox/HeaderVBox/ChipsHBox/ChipHarvest/Label
@onready var chip_milestones_label: Label = $Panel/MainVBox/HeaderVBox/ChipsHBox/ChipMilestones/Label
@onready var scroll: ScrollContainer = $Panel/MainVBox/Scroll
@onready var cards_vbox: VBoxContainer = $Panel/MainVBox/Scroll/CardsMargin/CardsVBox

# Filtros por Categoria Botânica
var _filter_scroll: ScrollContainer = null
var _filter_hbox: HBoxContainer = null
var _selected_filter: String = "all"
var _filter_buttons: Dictionary = {}

# Cache de cards para reaproveitamento e visibilidade instantânea (Pacote 3)
var _cards_by_key: Dictionary = {}
var _cards_built: bool = false

# Variáveis para o embalo (inércia) da rolagem; o arrasto em si é do ScrollContainer
var _is_dragging: bool = false
var _last_drag_time: float = 0.0
var _scroll_velocity_y: float = 0.0

# Atualização sob demanda: evita reconstruir cards com a aba oculta ou a cada marco em lote
var _dirty: bool = false
var _batch_claiming: bool = false

# Estilos compartilhados entre todos os cards (criados uma única vez)
static var _sb_card: Dictionary = {}
static var _sb_icon_frame: StyleBoxTexture = null
static var _sb_bar_bg: StyleBoxFlat = null
static var _sb_bar_fill: Dictionary = {}
static var _sb_claim: StyleBoxTexture = null
static var _sb_badge: StyleBoxTexture = null
static var _sb_filter: Dictionary = {}

static func _get_card_sb(is_disc: bool) -> StyleBoxTexture:
	if not _sb_card.has(is_disc):
		var sb: StyleBoxTexture = StyleBoxTexture.new()
		sb.texture = TEX_CARD_BG
		sb.content_margin_left = 14.0
		sb.content_margin_top = 12.0
		sb.content_margin_right = 14.0
		sb.content_margin_bottom = 12.0
		if not is_disc:
			sb.modulate_color = Color(0.72, 0.76, 0.85, 0.92)
		_sb_card[is_disc] = sb
	return _sb_card[is_disc] as StyleBoxTexture

static func _get_icon_frame_sb() -> StyleBoxTexture:
	if _sb_icon_frame == null:
		var sb: StyleBoxTexture = StyleBoxTexture.new()
		sb.texture = TEX_ICON_FRAME
		sb.texture_margin_left = 14.0
		sb.texture_margin_top = 14.0
		sb.texture_margin_right = 14.0
		sb.texture_margin_bottom = 14.0
		_sb_icon_frame = sb
	return _sb_icon_frame

static func _get_bar_bg_sb() -> StyleBoxFlat:
	if _sb_bar_bg == null:
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = Color(0.06, 0.10, 0.18, 1.0)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.18, 0.38, 0.58, 0.65)
		_sb_bar_bg = sb
	return _sb_bar_bg

static func _get_bar_fill_sb(col: Color) -> StyleBoxFlat:
	if not _sb_bar_fill.has(col):
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = col
		_sb_bar_fill[col] = sb
	return _sb_bar_fill[col] as StyleBoxFlat

static func _get_claim_sb() -> StyleBoxTexture:
	if _sb_claim == null:
		var sb: StyleBoxTexture = StyleBoxTexture.new()
		sb.texture = TEX_BTN_CLAIM
		sb.texture_margin_left = 12.0
		sb.texture_margin_top = 12.0
		sb.texture_margin_right = 12.0
		sb.texture_margin_bottom = 12.0
		sb.content_margin_top = 8.0
		sb.content_margin_bottom = 8.0
		_sb_claim = sb
	return _sb_claim

static func _get_badge_sb() -> StyleBoxTexture:
	if _sb_badge == null:
		var sb: StyleBoxTexture = StyleBoxTexture.new()
		sb.texture = TEX_BADGE_MILESTONE
		sb.texture_margin_left = 12.0
		sb.texture_margin_top = 12.0
		sb.texture_margin_right = 12.0
		sb.texture_margin_bottom = 12.0
		sb.content_margin_left = 10.0
		sb.content_margin_right = 10.0
		sb.content_margin_top = 8.0
		sb.content_margin_bottom = 8.0
		_sb_badge = sb
	return _sb_badge

static func _get_filter_sb(is_active: bool) -> StyleBoxFlat:
	if not _sb_filter.has(is_active):
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.set_corner_radius_all(6)
		sb.content_margin_left = 10.0
		sb.content_margin_right = 10.0
		sb.content_margin_top = 4.0
		sb.content_margin_bottom = 4.0
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		if is_active:
			sb.bg_color = Color(0.12, 0.38, 0.65, 0.95)
			sb.border_color = Color(0.35, 0.85, 1.0, 1.0)
		else:
			sb.bg_color = Color(0.06, 0.12, 0.22, 0.75)
			sb.border_color = Color(0.18, 0.30, 0.45, 0.55)
		_sb_filter[is_active] = sb
	return _sb_filter[is_active] as StyleBoxFlat

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		refresh_ui()

func _ready() -> void:
	set_process(false)
	_init_filter_bar()
	_connect_signals()
	refresh_ui()

func _connect_signals() -> void:
	if btn_claim_all != null:
		btn_claim_all.pressed.connect(_on_claim_all_pressed)

	if SaveManager != null:
		SaveManager.save_loaded.connect(refresh_ui)
		SaveManager.plant_harvested.connect(_on_plant_harvested)
		SaveManager.milestone_claimed.connect(_on_milestone_claimed)

	visibility_changed.connect(_on_visibility_changed)

	if scroll != null:
		scroll.gui_input.connect(_on_scroll_gui_input)

## Colheitas só ocorrem em gameplay; com a aba oculta apenas marca como suja e
## reconstrói uma única vez quando a aba voltar a ser exibida.
func _on_plant_harvested(_species_key: String, _new_count: int) -> void:
	if is_visible_in_tree():
		refresh_ui()
	else:
		_dirty = true

func _on_visibility_changed() -> void:
	if is_visible_in_tree() and _dirty:
		_dirty = false
		refresh_ui()

## Resgate de marco: atualiza cabeçalho/filtros e reconstrói somente o card afetado.
func _on_milestone_claimed(species_key: String, _lvl: int, _reward: int) -> void:
	if _batch_claiming:
		return
	_refresh_header()
	_refresh_single_card(species_key)

func _process(delta: float) -> void:
	# Inércia após soltar o dedo/mouse. Só roda enquanto há velocidade residual.
	if _is_dragging or scroll == null:
		return
	if absf(_scroll_velocity_y) <= 5.0:
		_scroll_velocity_y = 0.0
		set_process(false)
		return
	var before: int = scroll.scroll_vertical
	scroll.scroll_vertical -= int(_scroll_velocity_y * delta)
	if scroll.scroll_vertical == before:
		# Chegou ao topo/fim da lista: encerra o embalo
		_scroll_velocity_y = 0.0
		set_process(false)
		return
	_scroll_velocity_y = lerpf(_scroll_velocity_y, 0.0, delta * 9.0)

## O arrasto e a roda do mouse são tratados pelo próprio ScrollContainer (uma única fonte
## de movimento). Este handler apenas mede a velocidade para o embalo ao soltar o dedo.
## Usa só eventos de toque: com emulate_touch_from_mouse o mouse também gera ScreenTouch/Drag,
## e ignorar MouseButton/MouseMotion evita contar o mesmo gesto duas vezes.
func _on_scroll_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			_is_dragging = true
			_last_drag_time = Time.get_ticks_msec() / 1000.0
			_scroll_velocity_y = 0.0
		else:
			_is_dragging = false
			if absf(_scroll_velocity_y) > 5.0:
				set_process(true)

	elif event is InputEventScreenDrag and _is_dragging:
		var sd: InputEventScreenDrag = event as InputEventScreenDrag
		var now_t: float = Time.get_ticks_msec() / 1000.0
		var dt_t: float = maxf(0.001, now_t - _last_drag_time)
		# Suaviza a velocidade para evitar picos de um único evento
		_scroll_velocity_y = lerpf(_scroll_velocity_y, sd.relative.y / dt_t, 0.5)
		_last_drag_time = now_t

func _init_filter_bar() -> void:
	if _filter_scroll != null:
		return
	var header_vbox: VBoxContainer = get_node_or_null("Panel/MainVBox/HeaderVBox") as VBoxContainer
	if header_vbox == null:
		return

	_filter_scroll = ScrollContainer.new()
	_filter_scroll.name = "FilterScroll"
	_filter_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_filter_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_filter_scroll.custom_minimum_size = Vector2(0, 36)
	_filter_scroll.mouse_filter = Control.MOUSE_FILTER_PASS

	_filter_hbox = HBoxContainer.new()
	_filter_hbox.name = "FilterHBox"
	_filter_hbox.add_theme_constant_override("separation", 8)
	_filter_hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	_filter_scroll.add_child(_filter_hbox)

	header_vbox.add_child(_filter_scroll)

	var filter_configs: Array[Dictionary] = [
		{"id": "all", "label": "HERBARIUM_FILTER_ALL", "icon": "🌿"},
		{"id": "grass", "label": "HERBARIUM_FILTER_GRASS", "icon": "🌱"},
		{"id": "crop", "label": "HERBARIUM_FILTER_CROP", "icon": "🌾"},
		{"id": "flower", "label": "HERBARIUM_FILTER_FLOWER", "icon": "🌸"},
		{"id": "claimable", "label": "HERBARIUM_FILTER_CLAIMABLE", "icon": "⭐"}
	]

	for cfg in filter_configs:
		var btn: Button = Button.new()
		var fid: String = String(cfg["id"])
		btn.name = "FilterBtn_" + fid
		btn.custom_minimum_size = Vector2(80, 30)
		btn.mouse_filter = Control.MOUSE_FILTER_PASS
		btn.add_theme_font_size_override("font_size", 11)
		btn.pressed.connect(func() -> void: _on_filter_selected(fid))
		_filter_hbox.add_child(btn)
		_filter_buttons[fid] = btn

func _on_filter_selected(fid: String) -> void:
	if _selected_filter == fid:
		return
	_selected_filter = fid
	if AudioManager != null:
		AudioManager.play_sfx("confirm")
	_update_filter_buttons()
	_apply_active_filter()

func _apply_active_filter() -> void:
	if not _cards_built:
		refresh_cards()
		return
	var all_species: Array[Dictionary] = PlantDatabaseScript.get_all_species()
	for sp: Dictionary in all_species:
		var key: String = String(sp.get("key", ""))
		var card: PanelContainer = _cards_by_key.get(key) as PanelContainer
		if card != null:
			card.visible = _is_matching_filter(key, sp, _selected_filter)

## Retorna a quantidade de cards atualmente visíveis no catálogo (conforme filtro ativo).
func get_visible_cards_count() -> int:
	if cards_vbox == null:
		return 0
	var count: int = 0
	for c: Node in cards_vbox.get_children():
		if c is CanvasItem and (c as CanvasItem).visible:
			count += 1
	return count

func _is_matching_filter(key: String, sp: Dictionary, filter_id: String) -> bool:
	if filter_id == "all":
		return true
	var cat: String = String(sp.get("category", "grass"))
	if filter_id == "grass":
		return cat == "grass"
	elif filter_id == "crop":
		return cat == "crop"
	elif filter_id == "flower":
		return cat == "flower"
	elif filter_id == "claimable":
		if SaveManager == null or not SaveManager.is_species_discovered(key):
			return false
		var harvest_count: int = SaveManager.get_harvest_count(key)
		var claimed_lvl: int = SaveManager.get_claimed_milestone_level(key)
		var milestones: Array = sp.get("milestones", [])
		if claimed_lvl >= milestones.size():
			return false
		var next_m: Dictionary = milestones[claimed_lvl] as Dictionary
		var target_req: int = int(next_m.get("target", 100))
		return harvest_count >= target_req
	return true

func _update_filter_buttons(all_species: Array[Dictionary] = []) -> void:
	if _filter_buttons.is_empty():
		return
	if all_species.is_empty():
		all_species = PlantDatabaseScript.get_all_species()

	var total_sp: int = all_species.size()
	var grass_sp: int = 0
	var crop_sp: int = 0
	var flower_sp: int = 0
	for sp in all_species:
		var cat: String = String(sp.get("category", "grass"))
		if cat == "grass":
			grass_sp += 1
		elif cat == "crop":
			crop_sp += 1
		elif cat == "flower":
			flower_sp += 1

	var claimable_sp: int = 0
	for sp in all_species:
		var key: String = String(sp.get("key", ""))
		if SaveManager != null and SaveManager.is_species_discovered(key):
			var hc: int = SaveManager.get_harvest_count(key)
			var cl: int = SaveManager.get_claimed_milestone_level(key)
			var ms: Array = sp.get("milestones", [])
			if cl < ms.size():
				var next_m: Dictionary = ms[cl] as Dictionary
				if hc >= int(next_m.get("target", 100)):
					claimable_sp += 1

	var counts: Dictionary = {
		"all": total_sp,
		"grass": grass_sp,
		"crop": crop_sp,
		"flower": flower_sp,
		"claimable": claimable_sp
	}

	var labels: Dictionary = {
		"all": tr("HERBARIUM_FILTER_ALL"),
		"grass": tr("HERBARIUM_FILTER_GRASS"),
		"crop": tr("HERBARIUM_FILTER_CROP"),
		"flower": tr("HERBARIUM_FILTER_FLOWER"),
		"claimable": tr("HERBARIUM_FILTER_CLAIMABLE")
	}

	var icons: Dictionary = {
		"all": "🌿",
		"grass": "🌱",
		"crop": "🌾",
		"flower": "🌸",
		"claimable": "⭐"
	}

	for fid: String in _filter_buttons.keys():
		var btn: Button = _filter_buttons[fid] as Button
		if btn == null:
			continue
		var count: int = int(counts.get(fid, 0))
		var title: String = String(labels.get(fid, fid))
		var icon: String = String(icons.get(fid, ""))
		btn.text = "%s %s (%d)" % [icon, title, count]

		var is_active: bool = (_selected_filter == fid)
		var sb: StyleBoxFlat = _get_filter_sb(is_active)
		if is_active:
			btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		else:
			btn.add_theme_color_override("font_color", Color(0.68, 0.78, 0.88, 0.85))

		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)

func refresh_ui() -> void:
	if SaveManager == null:
		return
	_refresh_header()
	refresh_cards()

## Atualiza título, progresso, chips, botão "Coletar Tudo" e contadores dos filtros (sem tocar nos cards).
func _refresh_header() -> void:
	if SaveManager == null:
		return

	var all_species: Array[Dictionary] = PlantDatabaseScript.get_all_species()
	var total_species: int = all_species.size()
	var discovered_species: int = SaveManager.get_discovered_species_count()
	var total_harvest: int = SaveManager.get_total_harvest_count()

	var total_milestones_claimed: int = 0
	for sp: Dictionary in all_species:
		var k: String = String(sp.get("key", ""))
		total_milestones_claimed += SaveManager.get_claimed_milestone_level(k)

	if title_label != null:
		title_label.text = tr("HERBARIUM_FULL_TITLE")
	if subtitle_label != null:
		subtitle_label.text = tr("HERBARIUM_SUBTITLE")

	var pct: int = 0 if total_species == 0 else int((float(discovered_species) / float(total_species)) * 100.0)
	if prog_label != null:
		prog_label.text = tr("HERBARIUM_PROGRESS_FMT") % [discovered_species, total_species, pct]

	if progress_bar != null:
		progress_bar.max_value = float(total_species)
		progress_bar.value = float(discovered_species)

	if chip_harvest_label != null:
		chip_harvest_label.text = tr("HERBARIUM_CHIP_HARVEST_FMT") % _format_number(total_harvest)
	if chip_milestones_label != null:
		chip_milestones_label.text = tr("HERBARIUM_CHIP_MILESTONES_FMT") % [total_milestones_claimed, total_species * 10]

	var claimable_count: int = _get_claimable_milestones_count(all_species)
	if btn_claim_all != null:
		btn_claim_all.visible = (claimable_count > 0)
		btn_claim_all.text = tr("HERBARIUM_CLAIM_ALL_FMT") % claimable_count

	_update_filter_buttons(all_species)

## Atualiza apenas os dados do card em-place e sua visibilidade se no filtro 'claimable'.
func _refresh_single_card(species_key: String) -> void:
	if not _cards_built or not _cards_by_key.has(species_key):
		refresh_cards()
		return
	var sp: Dictionary = PlantDatabaseScript.get_species(species_key)
	if sp.is_empty():
		return
	var card: PanelContainer = _cards_by_key[species_key] as PanelContainer
	_update_card_view(card, sp)
	card.visible = _is_matching_filter(species_key, sp, _selected_filter)

func _get_claimable_milestones_count(all_species: Array[Dictionary]) -> int:
	var count: int = 0
	for sp: Dictionary in all_species:
		var key: String = String(sp.get("key", ""))
		if not SaveManager.is_species_discovered(key):
			continue
		var harvest_count: int = SaveManager.get_harvest_count(key)
		var claimed_lvl: int = SaveManager.get_claimed_milestone_level(key)
		var milestones: Array = sp.get("milestones", [])
		for i in range(claimed_lvl, milestones.size()):
			var next_m: Dictionary = milestones[i] as Dictionary
			var target_req: int = int(next_m.get("target", 100))
			if harvest_count >= target_req:
				count += 1
			else:
				break
	return count

func refresh_cards() -> void:
	if cards_vbox == null or SaveManager == null:
		return

	var all_species: Array[Dictionary] = PlantDatabaseScript.get_all_species()

	# Constrói os cards uma única vez para reaproveitamento permanente (Pacote 3)
	if not _cards_built:
		for child: Node in cards_vbox.get_children():
			cards_vbox.remove_child(child)
			child.queue_free()
		_cards_by_key.clear()

		for sp: Dictionary in all_species:
			var key: String = String(sp.get("key", ""))
			var card: PanelContainer = _build_species_card(sp)
			cards_vbox.add_child(card)
			_cards_by_key[key] = card
		_cards_built = true

	# Atualiza o estado dos cards e ajusta visibilidade conforme o filtro
	for sp: Dictionary in all_species:
		var key: String = String(sp.get("key", ""))
		var card: PanelContainer = _cards_by_key.get(key) as PanelContainer
		if card != null:
			_update_card_view(card, sp)
			card.visible = _is_matching_filter(key, sp, _selected_filter)

func _build_species_card(sp: Dictionary) -> PanelContainer:
	var key: String = String(sp.get("key", ""))

	var card: PanelContainer = PanelContainer.new()
	card.set_meta("species_key", key)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_PASS

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_child(hbox)

	# --- 1. Vitrine de Ilustração Botânica 3D Oficial (Esquerda) ---
	var icon_panel: PanelContainer = PanelContainer.new()
	icon_panel.custom_minimum_size = Vector2(96, 96)
	icon_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	icon_panel.add_theme_stylebox_override("panel", _get_icon_frame_sb())

	var illus_layer: CenterContainer = CenterContainer.new()
	illus_layer.custom_minimum_size = Vector2(88, 88)
	illus_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	icon_panel.add_child(illus_layer)

	var icon_view: Control = GoalIconFactoryScript.build_goal_icon(key, 76.0, true)
	icon_view.mouse_filter = Control.MOUSE_FILTER_PASS
	illus_layer.add_child(icon_view)

	var lock_rect: TextureRect = TextureRect.new()
	lock_rect.custom_minimum_size = Vector2(36, 36)
	lock_rect.texture = TEX_ILLUS_LOCKED
	lock_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lock_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lock_rect.mouse_filter = Control.MOUSE_FILTER_PASS
	illus_layer.add_child(lock_rect)

	hbox.add_child(icon_panel)

	# --- 2. Coluna Central: Status, Título, Atributos, Descrição e Progresso ---
	var info_vbox: VBoxContainer = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)
	info_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	hbox.add_child(info_vbox)

	# Linha 1: Tag Trapezoidal (✓ DESCOBERTA / BLOQUEADO) + Badge da Fase de Origem
	var header_row: HBoxContainer = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)
	header_row.mouse_filter = Control.MOUSE_FILTER_PASS
	info_vbox.add_child(header_row)

	var tag_overlay: Control = Control.new()
	tag_overlay.custom_minimum_size = Vector2(138, 22)
	tag_overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	header_row.add_child(tag_overlay)

	var tag_bg: TextureRect = TextureRect.new()
	tag_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	tag_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tag_bg.stretch_mode = TextureRect.STRETCH_SCALE
	tag_bg.mouse_filter = Control.MOUSE_FILTER_PASS
	tag_overlay.add_child(tag_bg)

	var tag_lbl: Label = Label.new()
	tag_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tag_lbl.add_theme_font_size_override("font_size", 10)
	tag_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	tag_overlay.add_child(tag_lbl)

	var header_spacer: Control = Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_spacer.mouse_filter = Control.MOUSE_FILTER_PASS
	header_row.add_child(header_spacer)

	var origin_badge: Label = Label.new()
	origin_badge.add_theme_font_size_override("font_size", 11)
	origin_badge.mouse_filter = Control.MOUSE_FILTER_PASS
	header_row.add_child(origin_badge)

	# Linha 2: Nome da Espécie
	var name_lbl: Label = Label.new()
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	info_vbox.add_child(name_lbl)

	# Linha 3: Atributos
	var attr_lbl: Label = Label.new()
	attr_lbl.add_theme_font_size_override("font_size", 11)
	attr_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	info_vbox.add_child(attr_lbl)

	# Linha 4: Descrição Botânica
	var desc_lbl: Label = Label.new()
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	info_vbox.add_child(desc_lbl)

	# Linha 5 & 6: Container de Progresso (Colheitas e Barra de Progresso)
	var prog_container: VBoxContainer = VBoxContainer.new()
	prog_container.add_theme_constant_override("separation", 4)
	prog_container.mouse_filter = Control.MOUSE_FILTER_PASS
	info_vbox.add_child(prog_container)

	var prog_hbox: HBoxContainer = HBoxContainer.new()
	prog_hbox.add_theme_constant_override("separation", 6)
	prog_hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	prog_container.add_child(prog_hbox)

	var count_lbl: Label = Label.new()
	count_lbl.add_theme_font_size_override("font_size", 11)
	count_lbl.add_theme_color_override("font_color", Color(0.38, 0.95, 0.58, 1.0))
	count_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	count_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	prog_hbox.add_child(count_lbl)

	var milestone_title_lbl: Label = Label.new()
	milestone_title_lbl.add_theme_font_size_override("font_size", 11)
	milestone_title_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	prog_hbox.add_child(milestone_title_lbl)

	var m_bar: ProgressBar = ProgressBar.new()
	m_bar.custom_minimum_size = Vector2(0, 8)
	m_bar.show_percentage = false
	m_bar.mouse_filter = Control.MOUSE_FILTER_PASS
	m_bar.add_theme_stylebox_override("background", _get_bar_bg_sb())
	prog_container.add_child(m_bar)

	# --- 3. Coluna Direita: Ação Lateral (Resgate de Marco ou Status) ---
	var action_vbox: VBoxContainer = VBoxContainer.new()
	action_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	action_vbox.custom_minimum_size = Vector2(96, 0)
	action_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	hbox.add_child(action_vbox)

	var refs: Dictionary = {
		"icon_panel": icon_panel,
		"icon_view": icon_view,
		"lock_rect": lock_rect,
		"tag_bg": tag_bg,
		"tag_lbl": tag_lbl,
		"origin_badge": origin_badge,
		"name_lbl": name_lbl,
		"attr_lbl": attr_lbl,
		"desc_lbl": desc_lbl,
		"prog_container": prog_container,
		"count_lbl": count_lbl,
		"milestone_title_lbl": milestone_title_lbl,
		"m_bar": m_bar,
		"action_vbox": action_vbox
	}
	card.set_meta("refs", refs)

	_update_card_view(card, sp)
	return card

func _update_card_view(card: PanelContainer, sp: Dictionary) -> void:
	var refs: Dictionary = card.get_meta("refs", {}) as Dictionary
	if refs.is_empty() or SaveManager == null:
		return

	var key: String = String(sp.get("key", ""))
	var is_disc: bool = SaveManager.is_species_discovered(key)
	var harvest_count: int = SaveManager.get_harvest_count(key)
	var claimed_lvl: int = SaveManager.get_claimed_milestone_level(key)
	var milestones: Array = sp.get("milestones", [])
	var theme_col: Color = sp.get("color", Color(0.3, 0.7, 0.4, 1.0))
	var hits: int = int(sp.get("hits", 1))
	var coins: int = int(sp.get("reward_coins", 1))
	var origin_lvl: int = int(sp.get("origin_level", 1))

	# 0. Estilo do Card
	card.add_theme_stylebox_override("panel", _get_card_sb(is_disc))

	# 1. Vitrine de Ilustração Botânica
	var icon_panel: PanelContainer = refs["icon_panel"] as PanelContainer
	icon_panel.self_modulate = Color(theme_col.r, theme_col.g, theme_col.b, 0.90) if is_disc else Color(0.28, 0.38, 0.52, 0.70)

	var icon_view: Control = refs["icon_view"] as Control
	icon_view.modulate = Color(1.0, 1.0, 1.0, 1.0) if is_disc else Color(0.18, 0.26, 0.38, 0.70)

	var lock_rect: TextureRect = refs["lock_rect"] as TextureRect
	lock_rect.visible = not is_disc

	# 2. Tag e Header
	var tag_bg: TextureRect = refs["tag_bg"] as TextureRect
	tag_bg.texture = TEX_BADGE_DISC if is_disc else TEX_BADGE_LOCK

	var tag_lbl: Label = refs["tag_lbl"] as Label
	tag_lbl.text = tr("COLLECTION_TAG_DISC") if is_disc else tr("COLLECTION_TAG_LOCK")
	tag_lbl.add_theme_color_override("font_color", Color(0.85, 1.0, 0.92, 1.0) if is_disc else Color(0.95, 0.72, 0.76, 0.92))

	var origin_badge: Label = refs["origin_badge"] as Label
	origin_badge.text = tr("COLLECTION_ORIGIN_LVL") % origin_lvl
	origin_badge.add_theme_color_override("font_color", Color(0.45, 0.88, 1.0, 0.95) if is_disc else Color(0.60, 0.68, 0.78, 0.75))

	var name_lbl: Label = refs["name_lbl"] as Label
	name_lbl.text = PlantDatabaseScript.get_species_name(sp) if is_disc else tr("HERBARIUM_UNIDENTIFIED")
	name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0) if is_disc else Color(0.72, 0.78, 0.86, 0.92))

	var attr_lbl: Label = refs["attr_lbl"] as Label
	if is_disc:
		attr_lbl.text = tr("COLLECTION_ATTR_FMT") % [
			hits, tr("COLLECTION_HITS_SINGULAR") if hits == 1 else tr("COLLECTION_HITS_PLURAL"),
			coins, tr("COLLECTION_COINS_SINGULAR") if coins == 1 else tr("COLLECTION_COINS_PLURAL")
		]
		attr_lbl.add_theme_color_override("font_color", Color(0.68, 0.88, 1.0, 0.95))
	else:
		attr_lbl.text = tr("COLLECTION_ATTR_LOCKED")
		attr_lbl.add_theme_color_override("font_color", Color(0.55, 0.62, 0.72, 0.80))

	var desc_lbl: Label = refs["desc_lbl"] as Label
	if is_disc:
		desc_lbl.text = String(sp.get("desc", ""))
		desc_lbl.add_theme_color_override("font_color", Color(0.76, 0.84, 0.92, 0.85))
	else:
		desc_lbl.text = tr("COLLECTION_DESC_LOCKED") % origin_lvl
		desc_lbl.add_theme_color_override("font_color", Color(0.52, 0.58, 0.68, 0.75))

	# 3. Progresso
	var prog_container: Control = refs["prog_container"] as Control
	prog_container.visible = is_disc
	if is_disc:
		var count_lbl: Label = refs["count_lbl"] as Label
		count_lbl.text = tr("COLLECTION_HARVEST_COUNT_FMT") % _format_number(harvest_count)

		var milestone_title_lbl: Label = refs["milestone_title_lbl"] as Label
		var m_bar: ProgressBar = refs["m_bar"] as ProgressBar
		m_bar.add_theme_stylebox_override("fill", _get_bar_fill_sb(theme_col))

		if claimed_lvl < milestones.size():
			var cur_m: Dictionary = milestones[claimed_lvl] as Dictionary
			var target: int = int(cur_m.get("target", 100))
			var m_title: String = String(cur_m.get("title", ""))
			var prev_target: int = 0
			if claimed_lvl > 0:
				var prev_m: Dictionary = milestones[claimed_lvl - 1] as Dictionary
				prev_target = int(prev_m.get("target", 0))

			milestone_title_lbl.text = tr("COLLECTION_MILESTONE_PROG_FMT") % [claimed_lvl + 1, m_title, mini(harvest_count, target), target]
			milestone_title_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.55, 0.95))

			m_bar.min_value = float(prev_target)
			m_bar.max_value = float(target)
			m_bar.value = clampf(float(harvest_count), float(prev_target), float(target))
		else:
			milestone_title_lbl.text = tr("COLLECTION_MILESTONE_MAX")
			milestone_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.28, 1.0))
			m_bar.min_value = 0.0
			m_bar.max_value = 1.0
			m_bar.value = 1.0

	# 4. Ação Lateral
	var action_vbox: VBoxContainer = refs["action_vbox"] as VBoxContainer
	for c in action_vbox.get_children():
		action_vbox.remove_child(c)
		c.queue_free()

	if not is_disc:
		var lock_lbl: Label = Label.new()
		lock_lbl.text = "%s\n%s" % [tr("COLLECTION_TAG_LOCK"), tr("COLLECTION_ORIGIN_LVL") % origin_lvl]
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.add_theme_font_size_override("font_size", 11)
		lock_lbl.add_theme_color_override("font_color", Color(0.62, 0.68, 0.76, 0.75))
		lock_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
		action_vbox.add_child(lock_lbl)
	elif claimed_lvl < milestones.size():
		var next_m: Dictionary = milestones[claimed_lvl] as Dictionary
		var target_req: int = int(next_m.get("target", 100))
		var coin_rew: int = int(next_m.get("reward", 10))

		if harvest_count >= target_req:
			var claim_btn: Button = Button.new()
			claim_btn.text = tr("COLLECTION_CLAIM_BTN_FMT") % coin_rew
			claim_btn.custom_minimum_size = Vector2(94, 54)
			claim_btn.mouse_filter = Control.MOUSE_FILTER_PASS
			claim_btn.add_theme_font_size_override("font_size", 12)
			claim_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))

			var btn_sb: StyleBoxTexture = _get_claim_sb()
			claim_btn.add_theme_stylebox_override("normal", btn_sb)
			claim_btn.add_theme_stylebox_override("hover", btn_sb)
			claim_btn.add_theme_stylebox_override("pressed", btn_sb)

			claim_btn.pressed.connect(func() -> void:
				_on_claim_milestone_pressed(key, claimed_lvl + 1, coin_rew)
			)
			action_vbox.add_child(claim_btn)
		else:
			var badge_panel: PanelContainer = PanelContainer.new()
			badge_panel.mouse_filter = Control.MOUSE_FILTER_PASS
			badge_panel.add_theme_stylebox_override("panel", _get_badge_sb())

			var badge: Label = Label.new()
			badge.text = tr("COLLECTION_BADGE_LOCKED_FMT") % [claimed_lvl + 1, coin_rew]
			badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			badge.add_theme_font_size_override("font_size", 11)
			badge.add_theme_color_override("font_color", Color(0.75, 0.86, 0.96, 0.85))
			badge.mouse_filter = Control.MOUSE_FILTER_PASS
			badge_panel.add_child(badge)
			action_vbox.add_child(badge_panel)
	else:
		var max_lbl: Label = Label.new()
		max_lbl.text = tr("COLLECTION_ACTION_COMPLETE")
		max_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		max_lbl.add_theme_font_size_override("font_size", 11)
		max_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25, 1.0))
		max_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
		action_vbox.add_child(max_lbl)

func _on_claim_milestone_pressed(species_key: String, milestone_lvl: int, coin_reward: int) -> void:
	if SaveManager == null:
		return

	var success: bool = SaveManager.claim_milestone_level(species_key, milestone_lvl, coin_reward)
	if success:
		if AudioManager != null:
			AudioManager.play_sfx("buy")
		if GameManager != null:
			GameManager.trigger_haptic_cut()
		# _on_milestone_claimed já atualiza o cabeçalho e somente o card afetado

func _on_claim_all_pressed() -> void:
	if SaveManager == null:
		return

	_batch_claiming = true
	var all_species: Array[Dictionary] = PlantDatabaseScript.get_all_species()
	var any_claimed: bool = false

	for sp: Dictionary in all_species:
		var key: String = String(sp.get("key", ""))
		if not SaveManager.is_species_discovered(key):
			continue
		var harvest_count: int = SaveManager.get_harvest_count(key)
		var milestones: Array = sp.get("milestones", [])

		while true:
			var claimed_lvl: int = SaveManager.get_claimed_milestone_level(key)
			if claimed_lvl >= milestones.size():
				break
			var next_m: Dictionary = milestones[claimed_lvl] as Dictionary
			var target_req: int = int(next_m.get("target", 100))
			var coin_rew: int = int(next_m.get("reward", 10))
			if harvest_count >= target_req:
				if SaveManager.claim_milestone_level(key, claimed_lvl + 1, coin_rew):
					any_claimed = true
				else:
					break
			else:
				break

	_batch_claiming = false
	if any_claimed:
		if AudioManager != null:
			AudioManager.play_sfx("buy")
		if GameManager != null:
			GameManager.trigger_haptic_cut()
		refresh_ui()

func _format_number(n: int) -> String:
	var s: String = str(n)
	var out: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "." + out
	return out
