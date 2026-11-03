extends Control

## TabCollection: Herbário da Ilha & Itens
## Exibe o catálogo oficial das 15 espécies botânicas ordenadas por fase (origin_level),
## em cards horizontais completos com estética cyber-botânica fiel à referência visual,
## rastreamento de colheitas, progresso da enciclopédia e resgate dos 10 níveis de marcos.

const PlantDatabaseScript = preload("res://scripts/plants/plant_database.gd")

const TEX_CARD_BG: Texture2D = preload("res://assets/ui/collection/card_species_bg.svg")
const TEX_BADGE_DISC: Texture2D = preload("res://assets/ui/collection/badge_discovered.svg")
const TEX_BADGE_LOCK: Texture2D = preload("res://assets/ui/collection/badge_locked.svg")
const TEX_ICON_FRAME: Texture2D = preload("res://assets/ui/collection/icon_frame_cyber.svg")
const TEX_BADGE_MILESTONE: Texture2D = preload("res://assets/ui/collection/badge_milestone_cyber.svg")
const TEX_BTN_CLAIM: Texture2D = preload("res://assets/ui/collection/btn_claim_cyber.svg")

const TEX_ILLUS_GRASS_BASE: Texture2D = preload("res://assets/ui/collection/illus_grass_base.svg")
const TEX_ILLUS_GRASS_BLADES: Texture2D = preload("res://assets/ui/collection/illus_grass_blades.svg")
const TEX_ILLUS_WHEAT: Texture2D = preload("res://assets/ui/collection/illus_wheat_bundle.svg")
const TEX_ILLUS_FLOWER_STEMS: Texture2D = preload("res://assets/ui/collection/illus_flower_stems.svg")
const TEX_ILLUS_FLOWER_PETALS: Texture2D = preload("res://assets/ui/collection/illus_flower_petals.svg")
const TEX_ILLUS_LOCKED: Texture2D = preload("res://assets/ui/collection/illus_locked_plant.svg")

@onready var prog_label: Label = $Panel/MainVBox/HeaderVBox/ProgBox/ProgressOverlay/ProgLabel
@onready var progress_bar: TextureProgressBar = $Panel/MainVBox/HeaderVBox/ProgBox/ProgressOverlay/ProgressBar
@onready var btn_claim_all: Button = $Panel/MainVBox/HeaderVBox/ProgBox/BtnClaimAll
@onready var chip_harvest_label: Label = $Panel/MainVBox/HeaderVBox/ChipsHBox/ChipHarvest/Label
@onready var chip_milestones_label: Label = $Panel/MainVBox/HeaderVBox/ChipsHBox/ChipMilestones/Label
@onready var scroll: ScrollContainer = $Panel/MainVBox/Scroll
@onready var cards_vbox: VBoxContainer = $Panel/MainVBox/Scroll/CardsMargin/CardsVBox

# Variáveis para rolagem inercial touch/mouse suave
var _is_dragging: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var _last_drag_pos: Vector2 = Vector2.ZERO
var _last_drag_time: float = 0.0
var _scroll_velocity_y: float = 0.0

func _ready() -> void:
	_connect_signals()
	refresh_ui()

func _connect_signals() -> void:
	if btn_claim_all != null:
		btn_claim_all.pressed.connect(_on_claim_all_pressed)

	if SaveManager != null:
		SaveManager.save_loaded.connect(refresh_ui)
		SaveManager.plant_harvested.connect(func(_sp: String, _c: int) -> void: refresh_ui())
		SaveManager.milestone_claimed.connect(func(_sp: String, _lvl: int, _r: int) -> void: refresh_ui())

	if scroll != null:
		scroll.gui_input.connect(_on_scroll_gui_input)

func _process(delta: float) -> void:
	if not visible:
		return

	# Inércia suave de rolagem após soltar o dedo/mouse
	if not _is_dragging and absf(_scroll_velocity_y) > 5.0 and scroll != null:
		scroll.scroll_vertical -= int(_scroll_velocity_y * delta)
		_scroll_velocity_y = lerpf(_scroll_velocity_y, 0.0, delta * 9.0)

func _on_scroll_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_is_dragging = true
				_drag_start_pos = mb.position
				_last_drag_pos = mb.position
				_last_drag_time = Time.get_ticks_msec() / 1000.0
				_scroll_velocity_y = 0.0
			else:
				_is_dragging = false
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			if scroll != null:
				scroll.scroll_vertical -= 40
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if scroll != null:
				scroll.scroll_vertical += 40

	elif event is InputEventMouseMotion and _is_dragging:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		var now: float = Time.get_ticks_msec() / 1000.0
		var dt: float = maxf(0.001, now - _last_drag_time)
		var dy: float = mm.position.y - _last_drag_pos.y
		if scroll != null:
			scroll.scroll_vertical -= int(dy)
		_scroll_velocity_y = dy / dt
		_last_drag_pos = mm.position
		_last_drag_time = now

	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			_is_dragging = true
			_drag_start_pos = st.position
			_last_drag_pos = st.position
			_last_drag_time = Time.get_ticks_msec() / 1000.0
			_scroll_velocity_y = 0.0
		else:
			_is_dragging = false

	elif event is InputEventScreenDrag and _is_dragging:
		var sd: InputEventScreenDrag = event as InputEventScreenDrag
		var now_t: float = Time.get_ticks_msec() / 1000.0
		var dt_t: float = maxf(0.001, now_t - _last_drag_time)
		var dy_t: float = sd.position.y - _last_drag_pos.y
		if scroll != null:
			scroll.scroll_vertical -= int(dy_t)
		_scroll_velocity_y = dy_t / dt_t
		_last_drag_pos = sd.position
		_last_drag_time = now_t

func refresh_ui() -> void:
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

	var pct: int = 0 if total_species == 0 else int((float(discovered_species) / float(total_species)) * 100.0)
	if prog_label != null:
		prog_label.text = "Descobertas: %d / %d (%d%%)" % [discovered_species, total_species, pct]

	if progress_bar != null:
		progress_bar.max_value = float(total_species)
		progress_bar.value = float(discovered_species)

	if chip_harvest_label != null:
		chip_harvest_label.text = "Ceifados: %s" % _format_number(total_harvest)
	if chip_milestones_label != null:
		chip_milestones_label.text = "Marcos: %d / %d" % [total_milestones_claimed, total_species * 10]

	var claimable_count: int = _get_claimable_milestones_count(all_species)
	if btn_claim_all != null:
		btn_claim_all.visible = (claimable_count > 0)
		btn_claim_all.text = "Coletar Tudo (%d)" % claimable_count

	refresh_cards()

func _get_claimable_milestones_count(all_species: Array[Dictionary]) -> int:
	var count: int = 0
	for sp: Dictionary in all_species:
		var key: String = String(sp.get("key", ""))
		if not SaveManager.is_species_discovered(key):
			continue
		var harvest_count: int = SaveManager.get_harvest_count(key)
		var claimed_lvl: int = SaveManager.get_claimed_milestone_level(key)
		var milestones: Array = sp.get("milestones", [])
		if claimed_lvl < milestones.size():
			var next_m: Dictionary = milestones[claimed_lvl] as Dictionary
			var target_req: int = int(next_m.get("target", 100))
			if harvest_count >= target_req:
				count += 1
	return count

func refresh_cards() -> void:
	if cards_vbox == null or SaveManager == null:
		return

	for child in cards_vbox.get_children():
		cards_vbox.remove_child(child)
		child.queue_free()

	var all_species: Array[Dictionary] = PlantDatabaseScript.get_all_species()
	for sp: Dictionary in all_species:
		var card: PanelContainer = _build_species_card(sp)
		cards_vbox.add_child(card)

func _build_species_card(sp: Dictionary) -> PanelContainer:
	var key: String = String(sp.get("key", ""))
	var is_disc: bool = SaveManager.is_species_discovered(key)
	var harvest_count: int = SaveManager.get_harvest_count(key)
	var claimed_lvl: int = SaveManager.get_claimed_milestone_level(key)
	var milestones: Array = sp.get("milestones", [])
	var theme_col: Color = sp.get("color", Color(0.3, 0.7, 0.4, 1.0))
	var cat: String = String(sp.get("category", "grass"))
	var hits: int = int(sp.get("hits", 1))
	var coins: int = int(sp.get("reward_coins", 1))
	var origin_lvl: int = int(sp.get("origin_level", 1))

	var card: PanelContainer = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_PASS

	var card_sb: StyleBoxTexture = StyleBoxTexture.new()
	card_sb.texture = TEX_CARD_BG
	card_sb.content_margin_left = 14.0
	card_sb.content_margin_top = 12.0
	card_sb.content_margin_right = 14.0
	card_sb.content_margin_bottom = 12.0
	if not is_disc:
		card_sb.modulate_color = Color(0.72, 0.76, 0.85, 0.92)
	card.add_theme_stylebox_override("panel", card_sb)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_child(hbox)

	# --- 1. Vitrine de Ilustração Botânica 3D (Esquerda - Cantos Retos Chanfrados) ---
	var icon_panel: PanelContainer = PanelContainer.new()
	icon_panel.custom_minimum_size = Vector2(96, 96)
	icon_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_panel.mouse_filter = Control.MOUSE_FILTER_PASS

	var icon_sb: StyleBoxTexture = StyleBoxTexture.new()
	icon_sb.texture = TEX_ICON_FRAME
	icon_sb.texture_margin_left = 14.0
	icon_sb.texture_margin_top = 14.0
	icon_sb.texture_margin_right = 14.0
	icon_sb.texture_margin_bottom = 14.0
	icon_sb.modulate_color = Color(theme_col.r, theme_col.g, theme_col.b, 0.90) if is_disc else Color(0.28, 0.38, 0.52, 0.70)
	icon_panel.add_theme_stylebox_override("panel", icon_sb)

	var illus_layer: Control = Control.new()
	illus_layer.custom_minimum_size = Vector2(88, 88)
	illus_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	icon_panel.add_child(illus_layer)

	if is_disc:
		if cat == "grass":
			var base_rect: TextureRect = TextureRect.new()
			base_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			base_rect.texture = TEX_ILLUS_GRASS_BASE
			base_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			base_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			base_rect.mouse_filter = Control.MOUSE_FILTER_PASS
			illus_layer.add_child(base_rect)

			var blades_rect: TextureRect = TextureRect.new()
			blades_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			blades_rect.texture = TEX_ILLUS_GRASS_BLADES
			blades_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			blades_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			blades_rect.modulate = theme_col
			blades_rect.mouse_filter = Control.MOUSE_FILTER_PASS
			illus_layer.add_child(blades_rect)
		elif cat == "crop":
			var wheat_rect: TextureRect = TextureRect.new()
			wheat_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			wheat_rect.texture = TEX_ILLUS_WHEAT
			wheat_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			wheat_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			wheat_rect.mouse_filter = Control.MOUSE_FILTER_PASS
			illus_layer.add_child(wheat_rect)
		else:
			var stems_rect: TextureRect = TextureRect.new()
			stems_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			stems_rect.texture = TEX_ILLUS_FLOWER_STEMS
			stems_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			stems_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			stems_rect.mouse_filter = Control.MOUSE_FILTER_PASS
			illus_layer.add_child(stems_rect)

			var petals_rect: TextureRect = TextureRect.new()
			petals_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			petals_rect.texture = TEX_ILLUS_FLOWER_PETALS
			petals_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			petals_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			petals_rect.modulate = theme_col
			petals_rect.mouse_filter = Control.MOUSE_FILTER_PASS
			illus_layer.add_child(petals_rect)
	else:
		var lock_rect: TextureRect = TextureRect.new()
		lock_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
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
	tag_bg.texture = TEX_BADGE_DISC if is_disc else TEX_BADGE_LOCK
	tag_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tag_bg.stretch_mode = TextureRect.STRETCH_SCALE
	tag_bg.mouse_filter = Control.MOUSE_FILTER_PASS
	tag_overlay.add_child(tag_bg)

	var tag_lbl: Label = Label.new()
	tag_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	tag_lbl.text = "✓ DESCOBERTA" if is_disc else "BLOQUEADO"
	tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tag_lbl.add_theme_font_size_override("font_size", 10)
	tag_lbl.add_theme_color_override("font_color", Color(0.85, 1.0, 0.92, 1.0) if is_disc else Color(0.95, 0.72, 0.76, 0.92))
	tag_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	tag_overlay.add_child(tag_lbl)

	var header_spacer: Control = Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_spacer.mouse_filter = Control.MOUSE_FILTER_PASS
	header_row.add_child(header_spacer)

	var origin_badge: Label = Label.new()
	origin_badge.text = "Fase %d+" % origin_lvl
	origin_badge.add_theme_font_size_override("font_size", 11)
	origin_badge.add_theme_color_override("font_color", Color(0.45, 0.88, 1.0, 0.95) if is_disc else Color(0.60, 0.68, 0.78, 0.75))
	origin_badge.mouse_filter = Control.MOUSE_FILTER_PASS
	header_row.add_child(origin_badge)

	# Linha 2: Nome da Espécie
	var name_lbl: Label = Label.new()
	name_lbl.text = String(sp.get("name", "Espécie Desconhecida")) if is_disc else "Espécie Não Identificada"
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0) if is_disc else Color(0.72, 0.78, 0.86, 0.92))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	info_vbox.add_child(name_lbl)

	# Linha 3: Atributos no formato do exemplo ("Resistência: X golpe • Recompensa: Y moeda")
	var attr_lbl: Label = Label.new()
	attr_lbl.add_theme_font_size_override("font_size", 11)
	if is_disc:
		attr_lbl.text = "Resistência: %d %s • Recompensa: %d %s" % [
			hits, "golpe" if hits == 1 else "golpes",
			coins, "moeda" if coins == 1 else "moedas"
		]
		attr_lbl.add_theme_color_override("font_color", Color(0.68, 0.88, 1.0, 0.95))
	else:
		attr_lbl.text = "Resistência: ??? • Recompensa: ??? moedas • Bloqueado"
		attr_lbl.add_theme_color_override("font_color", Color(0.55, 0.62, 0.72, 0.80))
	attr_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	info_vbox.add_child(attr_lbl)

	# Linha 4: Descrição Botânica
	var desc_lbl: Label = Label.new()
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 11)
	if is_disc:
		desc_lbl.text = String(sp.get("desc", ""))
		desc_lbl.add_theme_color_override("font_color", Color(0.76, 0.84, 0.92, 0.85))
	else:
		desc_lbl.text = "Espécie rara que habita a ilha a partir da Fase %d. Ceife-a para registrar no herbário!" % origin_lvl
		desc_lbl.add_theme_color_override("font_color", Color(0.52, 0.58, 0.68, 0.75))
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	info_vbox.add_child(desc_lbl)

	# Linha 5 & 6: Colheitas e Barra de Progresso do Marco (quando descoberta)
	if is_disc:
		var prog_hbox: HBoxContainer = HBoxContainer.new()
		prog_hbox.add_theme_constant_override("separation", 6)
		prog_hbox.mouse_filter = Control.MOUSE_FILTER_PASS
		info_vbox.add_child(prog_hbox)

		var count_lbl: Label = Label.new()
		count_lbl.text = "Colhidos: %s" % _format_number(harvest_count)
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

		var m_bg: StyleBoxFlat = StyleBoxFlat.new()
		m_bg.bg_color = Color(0.06, 0.10, 0.18, 1.0)
		m_bg.border_width_left = 1
		m_bg.border_width_top = 1
		m_bg.border_width_right = 1
		m_bg.border_width_bottom = 1
		m_bg.border_color = Color(0.18, 0.38, 0.58, 0.65)
		m_bar.add_theme_stylebox_override("background", m_bg)

		var m_fg: StyleBoxFlat = StyleBoxFlat.new()
		m_fg.bg_color = theme_col
		m_bar.add_theme_stylebox_override("fill", m_fg)
		info_vbox.add_child(m_bar)

		if claimed_lvl < milestones.size():
			var cur_m: Dictionary = milestones[claimed_lvl] as Dictionary
			var target: int = int(cur_m.get("target", 100))
			var m_title: String = String(cur_m.get("title", ""))
			var prev_target: int = 0
			if claimed_lvl > 0:
				var prev_m: Dictionary = milestones[claimed_lvl - 1] as Dictionary
				prev_target = int(prev_m.get("target", 0))

			milestone_title_lbl.text = "Nv %d/10: %s (%d/%d)" % [claimed_lvl + 1, m_title, mini(harvest_count, target), target]
			milestone_title_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.55, 0.95))

			m_bar.min_value = float(prev_target)
			m_bar.max_value = float(target)
			m_bar.value = clampf(float(harvest_count), float(prev_target), float(target))
		else:
			milestone_title_lbl.text = "MESTRE MÁXIMO (10/10)"
			milestone_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.28, 1.0))
			m_bar.min_value = 0.0
			m_bar.max_value = 1.0
			m_bar.value = 1.0

	# --- 3. Coluna Direita: Ação Lateral (Resgate de Marco ou Status) ---
	var action_vbox: VBoxContainer = VBoxContainer.new()
	action_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	action_vbox.custom_minimum_size = Vector2(96, 0)
	action_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	hbox.add_child(action_vbox)

	if not is_disc:
		var lock_lbl: Label = Label.new()
		lock_lbl.text = "BLOQUEADO\nFase %d+" % origin_lvl
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
			claim_btn.text = "COLETAR\n+%d Moedas" % coin_rew
			claim_btn.custom_minimum_size = Vector2(94, 54)
			claim_btn.mouse_filter = Control.MOUSE_FILTER_PASS
			claim_btn.add_theme_font_size_override("font_size", 12)
			claim_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))

			var btn_sb: StyleBoxTexture = StyleBoxTexture.new()
			btn_sb.texture = TEX_BTN_CLAIM
			btn_sb.texture_margin_left = 12.0
			btn_sb.texture_margin_top = 12.0
			btn_sb.texture_margin_right = 12.0
			btn_sb.texture_margin_bottom = 12.0
			btn_sb.content_margin_top = 8.0
			btn_sb.content_margin_bottom = 8.0
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
			var b_sb: StyleBoxTexture = StyleBoxTexture.new()
			b_sb.texture = TEX_BADGE_MILESTONE
			b_sb.texture_margin_left = 12.0
			b_sb.texture_margin_top = 12.0
			b_sb.texture_margin_right = 12.0
			b_sb.texture_margin_bottom = 12.0
			b_sb.content_margin_left = 10.0
			b_sb.content_margin_right = 10.0
			b_sb.content_margin_top = 8.0
			b_sb.content_margin_bottom = 8.0
			badge_panel.add_theme_stylebox_override("panel", b_sb)

			var badge: Label = Label.new()
			badge.text = "Lv %d/10\n+%d Moedas" % [claimed_lvl + 1, coin_rew]
			badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			badge.add_theme_font_size_override("font_size", 11)
			badge.add_theme_color_override("font_color", Color(0.75, 0.86, 0.96, 0.85))
			badge.mouse_filter = Control.MOUSE_FILTER_PASS
			badge_panel.add_child(badge)
			action_vbox.add_child(badge_panel)
	else:
		var max_lbl: Label = Label.new()
		max_lbl.text = "COMPLETO\nMAX"
		max_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		max_lbl.add_theme_font_size_override("font_size", 11)
		max_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25, 1.0))
		max_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
		action_vbox.add_child(max_lbl)

	return card

func _on_claim_milestone_pressed(species_key: String, milestone_lvl: int, coin_reward: int) -> void:
	if SaveManager == null:
		return

	var success: bool = SaveManager.claim_milestone_level(species_key, milestone_lvl, coin_reward)
	if success:
		if AudioManager != null:
			AudioManager.play_sfx("buy")
		if GameManager != null:
			GameManager.trigger_haptic_cut()
		refresh_ui()

func _on_claim_all_pressed() -> void:
	if SaveManager == null:
		return

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
