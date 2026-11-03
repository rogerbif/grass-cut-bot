extends Control

## TabCollection: Herbário da Ilha & Itens
## Exibe o catálogo botânico das espécies nativas e itens descobertos em layout Grid 2 colunas,
## com rolagem inercial touch/mouse garantida e resgate individual ou em lote ("Coletar Tudo").

const PlantDatabaseScript = preload("res://scripts/plants/plant_database.gd")

const TEX_CARD_BG: Texture2D = preload("res://assets/ui/collection/card_species_bg.svg")
const TEX_BADGE_DISC: Texture2D = preload("res://assets/ui/collection/badge_discovered.svg")
const TEX_BADGE_LOCK: Texture2D = preload("res://assets/ui/collection/badge_locked.svg")
const TEX_ICON_LOCK: Texture2D = preload("res://assets/ui/collection/icon_cyber_lock.svg")

const TEX_ICON_LEAF: Texture2D = preload("res://assets/icons/icon_leaf.svg")
const TEX_ICON_WHEAT: Texture2D = preload("res://assets/icons/icon_wheat.svg")
const TEX_ICON_FLOWER: Texture2D = preload("res://assets/icons/icon_flower.svg")

@onready var prog_label: Label = $Panel/MainVBox/HeaderVBox/ProgBox/ProgressOverlay/ProgLabel
@onready var progress_bar: TextureProgressBar = $Panel/MainVBox/HeaderVBox/ProgBox/ProgressOverlay/ProgressBar
@onready var btn_claim_all: Button = $Panel/MainVBox/HeaderVBox/ProgBox/BtnClaimAll
@onready var scroll: ScrollContainer = $Panel/MainVBox/Scroll
@onready var cards_grid: GridContainer = $Panel/MainVBox/Scroll/GridMargin/CardsGrid

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

	var pct: int = 0 if total_species == 0 else int((float(discovered_species) / float(total_species)) * 100.0)
	if prog_label != null:
		prog_label.text = "Descobertas: %d / %d (%d%%)" % [discovered_species, total_species, pct]

	if progress_bar != null:
		progress_bar.max_value = float(total_species)
		progress_bar.value = float(discovered_species)

	# Verifica se há marcos prontos para coleta para exibir o botão "Coletar Tudo"
	var claimable_count: int = _get_claimable_milestones_count(all_species)
	if btn_claim_all != null:
		btn_claim_all.visible = (claimable_count > 0)
		btn_claim_all.text = "Coletar Tudo (%d) ✨" % claimable_count

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
	if cards_grid == null or SaveManager == null:
		return

	for child in cards_grid.get_children():
		cards_grid.remove_child(child)
		child.queue_free()

	var all_species: Array[Dictionary] = PlantDatabaseScript.get_all_species()
	for sp: Dictionary in all_species:
		var card: Control = _build_grid_card(sp)
		cards_grid.add_child(card)

func _build_grid_card(sp: Dictionary) -> Control:
	var key: String = String(sp.get("key", ""))
	var is_disc: bool = SaveManager.is_species_discovered(key)
	var harvest_count: int = SaveManager.get_harvest_count(key)
	var claimed_lvl: int = SaveManager.get_claimed_milestone_level(key)
	var milestones: Array = sp.get("milestones", [])
	var theme_col: Color = sp.get("color", Color(0.3, 0.7, 0.4, 1.0))
	var cat: String = String(sp.get("category", "grass"))
	var hits: int = int(sp.get("hits", 1))
	var coins: int = int(sp.get("reward_coins", 1))

	# Container Raiz do Cartão
	var card_panel: PanelContainer = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(160, 260)
	card_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_panel.mouse_filter = Control.MOUSE_FILTER_PASS

	var card_sb: StyleBoxTexture = StyleBoxTexture.new()
	card_sb.texture = TEX_CARD_BG
	card_sb.content_margin_left = 10.0
	card_sb.content_margin_top = 10.0
	card_sb.content_margin_right = 10.0
	card_sb.content_margin_bottom = 12.0
	if not is_disc:
		card_sb.modulate_color = Color(0.65, 0.70, 0.80, 0.90)
	card_panel.add_theme_stylebox_override("panel", card_sb)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	card_panel.add_child(vbox)

	# 1. Tag Superior (DESCOBERTA ou BLOQUEADO)
	var tag_overlay: Control = Control.new()
	tag_overlay.custom_minimum_size = Vector2(0, 26)
	tag_overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(tag_overlay)

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
	tag_lbl.add_theme_font_size_override("font_size", 11)
	tag_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0) if is_disc else Color(0.95, 0.70, 0.75, 0.9))
	tag_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	tag_overlay.add_child(tag_lbl)

	# 2. Área Central da Imagem / Ícone
	var icon_container: PanelContainer = PanelContainer.new()
	icon_container.custom_minimum_size = Vector2(0, 84)
	icon_container.mouse_filter = Control.MOUSE_FILTER_PASS

	var icon_sb: StyleBoxFlat = StyleBoxFlat.new()
	icon_sb.bg_color = Color(theme_col.r, theme_col.g, theme_col.b, 0.14) if is_disc else Color(0.06, 0.10, 0.18, 0.6)
	icon_sb.corner_radius_top_left = 12
	icon_sb.corner_radius_top_right = 12
	icon_sb.corner_radius_bottom_right = 12
	icon_sb.corner_radius_bottom_left = 12
	icon_sb.border_width_left = 1
	icon_sb.border_width_top = 1
	icon_sb.border_width_right = 1
	icon_sb.border_width_bottom = 1
	icon_sb.border_color = Color(theme_col.r, theme_col.g, theme_col.b, 0.35) if is_disc else Color(0.18, 0.24, 0.35, 0.4)
	icon_container.add_theme_stylebox_override("panel", icon_sb)

	var icon_rect: TextureRect = TextureRect.new()
	icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_PASS
	if is_disc:
		if cat == "flower":
			icon_rect.texture = TEX_ICON_FLOWER
		elif cat == "crop":
			icon_rect.texture = TEX_ICON_WHEAT
		else:
			icon_rect.texture = TEX_ICON_LEAF
		icon_rect.modulate = theme_col
	else:
		icon_rect.texture = TEX_ICON_LOCK
		icon_rect.modulate = Color(0.0, 0.95, 0.85, 0.85)

	icon_container.add_child(icon_rect)
	vbox.add_child(icon_container)

	# 3. Título / Nome da Espécie
	var name_lbl: Label = Label.new()
	name_lbl.text = String(sp.get("name", "Espécie")) if is_disc else "???"
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0) if is_disc else Color(0.65, 0.72, 0.82, 0.9))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(name_lbl)

	# 4. Atributos (Resistência e Recompensa)
	var attr_lbl: Label = Label.new()
	attr_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	attr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	attr_lbl.add_theme_font_size_override("font_size", 10)
	if is_disc:
		attr_lbl.text = "Resistência: %d %s\nRecompensa: %d %s" % [
			hits, "golpe" if hits == 1 else "golpes",
			coins, "moeda" if coins == 1 else "moedas"
		]
		attr_lbl.add_theme_color_override("font_color", Color(0.72, 0.82, 0.92, 0.85))
	else:
		var origin_lvl: int = int(sp.get("origin_level", 1))
		attr_lbl.text = "Fase %d+\nBloqueado" % origin_lvl
		attr_lbl.add_theme_color_override("font_color", Color(0.55, 0.62, 0.70, 0.7))
	attr_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(attr_lbl)

	# Espaçador flexível para empurrar o botão de ação para a base do cartão
	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(spacer)

	# 5. Ação ou Progresso de Marco na Base
	if is_disc:
		if claimed_lvl < milestones.size():
			var next_m: Dictionary = milestones[claimed_lvl] as Dictionary
			var target_req: int = int(next_m.get("target", 100))
			var coin_rew: int = int(next_m.get("reward", 10))

			if harvest_count >= target_req:
				# Botão Ativo de Coleta
				var claim_btn: Button = Button.new()
				claim_btn.text = "COLETAR +%d" % coin_rew
				claim_btn.add_theme_font_size_override("font_size", 11)
				claim_btn.custom_minimum_size = Vector2(0, 32)
				claim_btn.focus_mode = Control.FOCUS_NONE

				var btn_sb: StyleBoxFlat = StyleBoxFlat.new()
				btn_sb.bg_color = Color(0.18, 0.72, 0.35, 0.98)
				btn_sb.corner_radius_top_left = 8
				btn_sb.corner_radius_top_right = 8
				btn_sb.corner_radius_bottom_right = 8
				btn_sb.corner_radius_bottom_left = 8
				claim_btn.add_theme_stylebox_override("normal", btn_sb)

				claim_btn.pressed.connect(func() -> void:
					_on_claim_single_milestone(key, claimed_lvl + 1, coin_rew)
				)
				vbox.add_child(claim_btn)
			else:
				# Exibe barra e contagem de progresso para o próximo marco
				var prog_lbl: Label = Label.new()
				prog_lbl.text = "%d / %d" % [harvest_count, target_req]
				prog_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				prog_lbl.add_theme_font_size_override("font_size", 10)
				prog_lbl.add_theme_color_override("font_color", Color(0.70, 0.85, 0.65, 0.9))
				prog_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
				vbox.add_child(prog_lbl)
		else:
			var max_lbl: Label = Label.new()
			max_lbl.text = "⭐ MESTRE"
			max_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			max_lbl.add_theme_font_size_override("font_size", 11)
			max_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0, 1.0))
			max_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
			vbox.add_child(max_lbl)

	return card_panel

func _on_claim_single_milestone(species_key: String, milestone_lvl: int, coin_reward: int) -> void:
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
	var total_claimed_coins: int = 0
	var claimed_any: bool = false

	for sp: Dictionary in all_species:
		var key: String = String(sp.get("key", ""))
		if not SaveManager.is_species_discovered(key):
			continue
		var harvest_count: int = SaveManager.get_harvest_count(key)
		var claimed_lvl: int = SaveManager.get_claimed_milestone_level(key)
		var milestones: Array = sp.get("milestones", [])
		while claimed_lvl < milestones.size():
			var next_m: Dictionary = milestones[claimed_lvl] as Dictionary
			var target_req: int = int(next_m.get("target", 100))
			var coin_rew: int = int(next_m.get("reward", 10))
			if harvest_count >= target_req:
				if SaveManager.claim_milestone_level(key, claimed_lvl + 1, coin_rew):
					total_claimed_coins += coin_rew
					claimed_any = true
					claimed_lvl += 1
				else:
					break
			else:
				break

	if claimed_any:
		if AudioManager != null:
			AudioManager.play_sfx("buy")
		if GameManager != null:
			GameManager.trigger_haptic_cut()
		refresh_ui()
