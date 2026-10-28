extends Control

## TabCollection: Herbário Botânico da Ilha
## Exibe o catálogo oficial das 15 espécies botânicas, rastreamento de colheitas,
## progresso da enciclopédia e resgate de recompensas dos 10 níveis de marcos de maestria.

const PlantDatabaseScript = preload("res://scripts/plants/plant_database.gd")

@onready var prog_label: Label = $Panel/MainVBox/HeaderVBox/ProgBox/ProgLabel
@onready var progress_bar: ProgressBar = $Panel/MainVBox/HeaderVBox/ProgBox/ProgressBar
@onready var percent_label: Label = $Panel/MainVBox/HeaderVBox/ProgBox/PercentLabel
@onready var chip_harvest_label: Label = $Panel/MainVBox/HeaderVBox/ChipsHBox/ChipHarvest/Label
@onready var chip_milestones_label: Label = $Panel/MainVBox/HeaderVBox/ChipsHBox/ChipMilestones/Label

@onready var btn_all: Button = $Panel/MainVBox/FilterHBox/BtnAll
@onready var btn_grass: Button = $Panel/MainVBox/FilterHBox/BtnGrass
@onready var btn_crops: Button = $Panel/MainVBox/FilterHBox/BtnCrops
@onready var btn_flowers: Button = $Panel/MainVBox/FilterHBox/BtnFlowers

@onready var cards_vbox: VBoxContainer = $Panel/MainVBox/Scroll/CardsVBox

var current_filter: String = "all" # "all", "grass", "crop", "flower"

var _filter_active_style: StyleBoxFlat
var _filter_normal_style: StyleBoxFlat

func _ready() -> void:
	_setup_styles()
	_connect_signals()
	refresh_ui()

func _setup_styles() -> void:
	_filter_active_style = StyleBoxFlat.new()
	_filter_active_style.bg_color = Color(0.20, 0.58, 0.35, 0.95)
	_filter_active_style.corner_radius_top_left = 10
	_filter_active_style.corner_radius_top_right = 10
	_filter_active_style.corner_radius_bottom_right = 10
	_filter_active_style.corner_radius_bottom_left = 10
	_filter_active_style.content_margin_left = 10.0
	_filter_active_style.content_margin_right = 10.0
	_filter_active_style.content_margin_top = 6.0
	_filter_active_style.content_margin_bottom = 6.0

	_filter_normal_style = StyleBoxFlat.new()
	_filter_normal_style.bg_color = Color(0.14, 0.18, 0.25, 0.8)
	_filter_normal_style.corner_radius_top_left = 10
	_filter_normal_style.corner_radius_top_right = 10
	_filter_normal_style.corner_radius_bottom_right = 10
	_filter_normal_style.corner_radius_bottom_left = 10
	_filter_normal_style.content_margin_left = 10.0
	_filter_normal_style.content_margin_right = 10.0
	_filter_normal_style.content_margin_top = 6.0
	_filter_normal_style.content_margin_bottom = 6.0

func _connect_signals() -> void:
	if btn_all != null:
		btn_all.pressed.connect(func() -> void: _set_filter("all"))
	if btn_grass != null:
		btn_grass.pressed.connect(func() -> void: _set_filter("grass"))
	if btn_crops != null:
		btn_crops.pressed.connect(func() -> void: _set_filter("crop"))
	if btn_flowers != null:
		btn_flowers.pressed.connect(func() -> void: _set_filter("flower"))

	if SaveManager != null:
		SaveManager.save_loaded.connect(refresh_ui)
		SaveManager.plant_harvested.connect(func(_sp: String, _c: int) -> void: refresh_ui())
		SaveManager.milestone_claimed.connect(func(_sp: String, _lvl: int, _r: int) -> void: refresh_ui())

func _set_filter(filter_name: String) -> void:
	current_filter = filter_name
	if AudioManager != null:
		AudioManager.play_sfx("confirm")
	_update_filter_buttons()
	refresh_cards()

func _update_filter_buttons() -> void:
	if btn_all != null:
		btn_all.add_theme_stylebox_override("normal", _filter_active_style if current_filter == "all" else _filter_normal_style)
	if btn_grass != null:
		btn_grass.add_theme_stylebox_override("normal", _filter_active_style if current_filter == "grass" else _filter_normal_style)
	if btn_crops != null:
		btn_crops.add_theme_stylebox_override("normal", _filter_active_style if current_filter == "crop" else _filter_normal_style)
	if btn_flowers != null:
		btn_flowers.add_theme_stylebox_override("normal", _filter_active_style if current_filter == "flower" else _filter_normal_style)

func refresh_ui() -> void:
	if SaveManager == null:
		return

	var all_species: Array[Dictionary] = PlantDatabaseScript.get_all_species()
	var total_species: int = all_species.size()
	var discovered_species: int = SaveManager.get_discovered_species_count()
	var total_harvest: int = SaveManager.get_total_harvest_count()

	# Calcula total de marcos resgatados (0 a 150)
	var total_milestones_claimed: int = 0
	for sp: Dictionary in all_species:
		var k: String = String(sp["key"])
		total_milestones_claimed += SaveManager.get_claimed_milestone_level(k)

	if prog_label != null:
		prog_label.text = "Descobertas: %d / %d" % [discovered_species, total_species]
	if progress_bar != null:
		progress_bar.max_value = float(total_species)
		progress_bar.value = float(discovered_species)
	if percent_label != null:
		var pct: int = 0 if total_species == 0 else int((float(discovered_species) / float(total_species)) * 100.0)
		percent_label.text = "%d%%" % pct

	if chip_harvest_label != null:
		chip_harvest_label.text = "🌾 Ceifados: %s" % _format_number(total_harvest)
	if chip_milestones_label != null:
		chip_milestones_label.text = "⭐ Marcos: %d / %d" % [total_milestones_claimed, total_species * 10]

	_update_filter_buttons()
	refresh_cards()

func refresh_cards() -> void:
	if cards_vbox == null or SaveManager == null:
		return

	for child in cards_vbox.get_children():
		cards_vbox.remove_child(child)
		child.queue_free()

	var all_species: Array[Dictionary] = PlantDatabaseScript.get_all_species()
	for sp: Dictionary in all_species:
		var category: String = String(sp.get("category", "grass"))
		if current_filter != "all" and category != current_filter:
			continue

		var card: PanelContainer = _build_species_card(sp)
		cards_vbox.add_child(card)

func _build_species_card(sp: Dictionary) -> PanelContainer:
	var key: String = String(sp.get("key", ""))
	var is_disc: bool = SaveManager.is_species_discovered(key)
	var harvest_count: int = SaveManager.get_harvest_count(key)
	var claimed_lvl: int = SaveManager.get_claimed_milestone_level(key)
	var milestones: Array = sp.get("milestones", [])
	var theme_col: Color = sp.get("color", Color(0.3, 0.7, 0.4, 1.0))

	var card: PanelContainer = PanelContainer.new()
	var card_sb: StyleBoxFlat = StyleBoxFlat.new()
	card_sb.bg_color = Color(0.12, 0.16, 0.22, 0.90) if is_disc else Color(0.08, 0.10, 0.14, 0.75)
	card_sb.corner_radius_top_left = 14
	card_sb.corner_radius_top_right = 14
	card_sb.corner_radius_bottom_right = 14
	card_sb.corner_radius_bottom_left = 14
	card_sb.content_margin_left = 12.0
	card_sb.content_margin_top = 10.0
	card_sb.content_margin_right = 12.0
	card_sb.content_margin_bottom = 10.0
	if is_disc:
		card_sb.border_width_left = 3
		card_sb.border_color = theme_col
	card.add_theme_stylebox_override("panel", card_sb)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	card.add_child(hbox)

	# --- 1. Caixa de Ícone / Avatar ---
	var icon_panel: PanelContainer = PanelContainer.new()
	var icon_sb: StyleBoxFlat = StyleBoxFlat.new()
	icon_sb.bg_color = Color(theme_col.r, theme_col.g, theme_col.b, 0.20) if is_disc else Color(0.12, 0.14, 0.18, 0.6)
	icon_sb.corner_radius_top_left = 12
	icon_sb.corner_radius_top_right = 12
	icon_sb.corner_radius_bottom_right = 12
	icon_sb.corner_radius_bottom_left = 12
	icon_sb.border_width_left = 1
	icon_sb.border_width_top = 1
	icon_sb.border_width_right = 1
	icon_sb.border_width_bottom = 1
	icon_sb.border_color = theme_col if is_disc else Color(0.3, 0.35, 0.4, 0.5)
	icon_sb.content_margin_left = 8.0
	icon_sb.content_margin_right = 8.0
	icon_sb.content_margin_top = 8.0
	icon_sb.content_margin_bottom = 8.0
	icon_panel.add_theme_stylebox_override("panel", icon_sb)
	icon_panel.custom_minimum_size = Vector2(56, 56)

	var icon_lbl: Label = Label.new()
	icon_lbl.text = String(sp.get("icon", "🌱")) if is_disc else "❓"
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 28 if is_disc else 24)
	icon_panel.add_child(icon_lbl)
	hbox.add_child(icon_panel)

	# --- 2. Informações e Progresso ---
	var info_vbox: VBoxContainer = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(info_vbox)

	# Título e Fase de Origem
	var top_hbox: HBoxContainer = HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 8)
	info_vbox.add_child(top_hbox)

	var name_lbl: Label = Label.new()
	name_lbl.text = String(sp.get("name", "Espécie Desconhecida")) if is_disc else "Espécie Não Identificada"
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0) if is_disc else Color(0.65, 0.70, 0.75, 1.0))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(name_lbl)

	var origin_lvl: int = int(sp.get("origin_level", 1))
	var origin_badge: Label = Label.new()
	origin_badge.text = "Fase %d+" % origin_lvl
	origin_badge.add_theme_font_size_override("font_size", 11)
	origin_badge.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0, 0.9))
	top_hbox.add_child(origin_badge)

	# Descrição e Atributos de Jogo
	var desc_lbl: Label = Label.new()
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 11)
	if is_disc:
		var hits: int = int(sp.get("hits", 1))
		var coins: int = int(sp.get("reward_coins", 1))
		desc_lbl.text = "%d %s • +%d %s\n%s" % [
			hits, "golpe" if hits == 1 else "golpes",
			coins, "moeda" if coins == 1 else "moedas",
			String(sp.get("desc", ""))
		]
		desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.90, 0.85))
	else:
		desc_lbl.text = "Bloqueada. Explore e ceife a vegetação a partir da Fase %d para identificá-la!" % origin_lvl
		desc_lbl.add_theme_color_override("font_color", Color(0.55, 0.60, 0.65, 0.8))
	info_vbox.add_child(desc_lbl)

	# Se descoberta, exibe barra de marco e colheitas
	if is_disc:
		var prog_hbox: HBoxContainer = HBoxContainer.new()
		prog_hbox.add_theme_constant_override("separation", 6)
		info_vbox.add_child(prog_hbox)

		var count_lbl: Label = Label.new()
		count_lbl.text = "Colhidos: %s" % _format_number(harvest_count)
		count_lbl.add_theme_font_size_override("font_size", 11)
		count_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5, 1.0))
		count_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		prog_hbox.add_child(count_lbl)

		var milestone_title_lbl: Label = Label.new()
		milestone_title_lbl.add_theme_font_size_override("font_size", 11)
		prog_hbox.add_child(milestone_title_lbl)

		# Barra de Progresso do Marco
		var m_bar: ProgressBar = ProgressBar.new()
		m_bar.custom_minimum_size = Vector2(0, 8)
		m_bar.show_percentage = false

		var m_bg: StyleBoxFlat = StyleBoxFlat.new()
		m_bg.bg_color = Color(0.10, 0.13, 0.18, 1.0)
		m_bg.corner_radius_top_left = 4
		m_bg.corner_radius_top_right = 4
		m_bg.corner_radius_bottom_right = 4
		m_bg.corner_radius_bottom_left = 4
		m_bar.add_theme_stylebox_override("background", m_bg)

		var m_fg: StyleBoxFlat = StyleBoxFlat.new()
		m_fg.bg_color = theme_col
		m_fg.corner_radius_top_left = 4
		m_fg.corner_radius_top_right = 4
		m_fg.corner_radius_bottom_right = 4
		m_fg.corner_radius_bottom_left = 4
		m_bar.add_theme_stylebox_override("fill", m_fg)
		info_vbox.add_child(m_bar)

		# Configura valores do próximo marco
		if claimed_lvl < milestones.size():
			var cur_m: Dictionary = milestones[claimed_lvl] as Dictionary
			var target: int = int(cur_m.get("target", 100))
			var m_title: String = String(cur_m.get("title", ""))
			var prev_target: int = 0
			if claimed_lvl > 0:
				var prev_m: Dictionary = milestones[claimed_lvl - 1] as Dictionary
				prev_target = int(prev_m.get("target", 0))

			milestone_title_lbl.text = "Nv %d/10: %s" % [claimed_lvl + 1, m_title]
			milestone_title_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.60, 0.9))

			m_bar.min_value = float(prev_target)
			m_bar.max_value = float(target)
			m_bar.value = clampf(float(harvest_count), float(prev_target), float(target))
		else:
			milestone_title_lbl.text = "⭐ MESTRE MÁXIMO (10/10)"
			milestone_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
			m_bar.min_value = 0.0
			m_bar.max_value = 1.0
			m_bar.value = 1.0

	# --- 3. Ação Lateral (Botão de Resgatar ou Badge de Status) ---
	var action_vbox: VBoxContainer = VBoxContainer.new()
	action_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	action_vbox.custom_minimum_size = Vector2(92, 0)
	hbox.add_child(action_vbox)

	if not is_disc:
		var lock_lbl: Label = Label.new()
		lock_lbl.text = "BLOQUEADA\n🔒"
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.add_theme_font_size_override("font_size", 11)
		lock_lbl.add_theme_color_override("font_color", Color(0.55, 0.60, 0.65, 0.75))
		action_vbox.add_child(lock_lbl)
	elif claimed_lvl < milestones.size():
		var next_m: Dictionary = milestones[claimed_lvl] as Dictionary
		var target_req: int = int(next_m.get("target", 100))
		var coin_rew: int = int(next_m.get("reward", 10))

		if harvest_count >= target_req:
			# Botão Ativo de Coleta
			var claim_btn: Button = Button.new()
			claim_btn.text = "COLETAR\n+%d 🪙" % coin_rew
			claim_btn.add_theme_font_size_override("font_size", 12)

			var btn_sb: StyleBoxFlat = StyleBoxFlat.new()
			btn_sb.bg_color = Color(0.20, 0.75, 0.38, 0.98)
			btn_sb.corner_radius_top_left = 10
			btn_sb.corner_radius_top_right = 10
			btn_sb.corner_radius_bottom_right = 10
			btn_sb.corner_radius_bottom_left = 10
			btn_sb.content_margin_top = 8.0
			btn_sb.content_margin_bottom = 8.0
			claim_btn.add_theme_stylebox_override("normal", btn_sb)

			claim_btn.pressed.connect(func() -> void:
				_on_claim_milestone_pressed(key, claimed_lvl + 1, coin_rew)
			)
			action_vbox.add_child(claim_btn)
		else:
			# Mostra próximo marco pendente
			var badge: Label = Label.new()
			badge.text = "Lv %d/10\n+%d 🪙" % [claimed_lvl, coin_rew]
			badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			badge.add_theme_font_size_override("font_size", 11)
			badge.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85, 0.7))
			action_vbox.add_child(badge)
	else:
		var max_lbl: Label = Label.new()
		max_lbl.text = "COMPLETO\n👑 MAX"
		max_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		max_lbl.add_theme_font_size_override("font_size", 11)
		max_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0, 1.0))
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
