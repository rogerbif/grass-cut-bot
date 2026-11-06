extends Control

const PlantDatabaseScript = preload("res://scripts/plants/plant_database.gd")

const ICON_PAUSE: Texture2D = preload("res://assets/icons/icon_pause.svg")
const ICON_COIN: Texture2D = preload("res://assets/icons/icon_coin.svg")
const BADGE_GOAL_BG: Texture2D = preload("res://assets/ui/topbar/badge_goal_bg.svg")
const BADGE_GOAL_DONE_BG: Texture2D = preload("res://assets/ui/topbar/badge_goal_done_bg.svg")

# Ilustrações Botânicas Canônicas da Coleção
const TEX_ILLUS_GRASS_BASE: Texture2D = preload("res://assets/ui/collection/illus_grass_base.svg")
const TEX_ILLUS_GRASS_BLADES: Texture2D = preload("res://assets/ui/collection/illus_grass_blades.svg")
const TEX_ILLUS_WHEAT: Texture2D = preload("res://assets/ui/collection/illus_wheat_bundle.svg")
const TEX_ILLUS_FLOWER_STEMS: Texture2D = preload("res://assets/ui/collection/illus_flower_stems.svg")
const TEX_ILLUS_FLOWER_PETALS: Texture2D = preload("res://assets/ui/collection/illus_flower_petals.svg")

@onready var top_bar: PanelContainer = $TopBar
@onready var timer_label: Label = $TopBar.find_child("TimerLabel", true, false) as Label
@onready var pause_button: BaseButton = $TopBar.find_child("PauseButton", true, false) as BaseButton
@onready var coins_label: Label = $TopBar.find_child("CoinsLabel", true, false) as Label
@onready var goals_container: HBoxContainer = $TopBar.find_child("GoalsContainer", true, false) as HBoxContainer

@onready var pause_modal: Control = $PauseModal
@onready var victory_modal: Control = $VictoryModal
@onready var defeat_modal: Control = $DefeatModal
@onready var workshop_modal: Control = $WorkshopModal

# Elementos da comemoração de vitória e modais
@onready var victory_title_label: Label = $VictoryModal.find_child("Title", true, false) as Label
@onready var star_1_rect: Control = $VictoryModal.find_child("Star1", true, false) as Control
@onready var star_2_rect: Control = $VictoryModal.find_child("Star2", true, false) as Control
@onready var star_3_rect: Control = $VictoryModal.find_child("Star3", true, false) as Control
@onready var victory_time_label: Label = $VictoryModal.find_child("TimeLabel", true, false) as Label
@onready var victory_coins_label: Label = $VictoryModal.find_child("CoinsEarnedLabel", true, false) as Label
@onready var victory_bottom_bar: Control = $VictoryModal.find_child("BottomBar", true, false) as Control
@onready var victory_next_label: Label = $VictoryModal.find_child("NextLabel", true, false) as Label

# Dicionário de Goal Cards instanciados: { "grass": { "container": Node, "count_label": Label, ... } }
var goal_cards: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_safe_area()

	# Oculta modais inicialmente e garante top_bar visível
	if top_bar != null:
		top_bar.visible = true
	if pause_button is Button:
		(pause_button as Button).icon = ICON_PAUSE
		(pause_button as Button).expand_icon = true
		(pause_button as Button).text = ""
	pause_modal.visible = false
	victory_modal.visible = false
	defeat_modal.visible = false
	workshop_modal.visible = false

	# Conecta sinais do GameManager
	if GameManager != null:
		GameManager.time_updated.connect(_on_time_updated)
		GameManager.goal_updated.connect(_on_goal_updated)
		GameManager.goal_completed.connect(_on_goal_completed)
		GameManager.level_won.connect(_on_level_won)
		GameManager.level_lost.connect(_on_level_lost)
		GameManager.game_paused.connect(_on_game_paused)
		GameManager.state_changed.connect(_on_state_changed)
		if not GameManager.goals.is_empty():
			_on_state_changed(GameManager.current_state)
			_on_time_updated(GameManager.time_left)
			for p_type: Variant in GameManager.goals.keys():
				var pt_str: String = String(p_type)
				var g_info: Dictionary = GameManager.goals[p_type] as Dictionary
				var tgt: int = int(g_info.get("target", 0))
				var cur: int = int(g_info.get("current", 0))
				_on_goal_updated(pt_str, maxi(0, tgt - cur), tgt)

	if UpgradeManager != null:
		UpgradeManager.coins_changed.connect(_on_coins_changed)
		_on_coins_changed(UpgradeManager.total_coins)

	# Conecta botões com suporte robusto a clique e touch
	_connect_button(pause_button, _on_pause_pressed)
	if pause_modal != null:
		if pause_modal.has_signal("resume_requested"):
			pause_modal.connect("resume_requested", _on_resume_pressed)
			pause_modal.connect("restart_requested", _on_restart_pressed)
			pause_modal.connect("menu_requested", _on_menu_pressed)
		elif pause_modal.has_node("Panel/VBox"):
			_connect_button(pause_modal.get_node_or_null("Panel/VBox/ResumeBtn") as BaseButton, _on_resume_pressed)
			_connect_button(pause_modal.get_node_or_null("Panel/VBox/RestartBtn") as BaseButton, _on_restart_pressed)
			_connect_button(pause_modal.get_node_or_null("Panel/VBox/WorkshopBtn") as BaseButton, _on_open_workshop_pressed)
			_connect_button(pause_modal.get_node_or_null("Panel/VBox/MenuBtn") as BaseButton, _on_menu_pressed)

	var next_btn: BaseButton = $VictoryModal.find_child("NextBtn", true, false) as BaseButton
	if next_btn:
		_connect_button(next_btn, _on_next_level_pressed)
	var restart_btn: BaseButton = $VictoryModal.find_child("RestartBtn", true, false) as BaseButton
	if restart_btn:
		_connect_button(restart_btn, _on_restart_pressed)
	var menu_btn: BaseButton = $VictoryModal.find_child("MenuBtn", true, false) as BaseButton
	if menu_btn:
		_connect_button(menu_btn, _on_menu_pressed)

	if defeat_modal != null:
		defeat_modal.connect("retry_requested", _on_restart_pressed)
		defeat_modal.connect("extra_time_requested", _on_extra_time_requested)
		defeat_modal.connect("menu_requested", _on_menu_pressed)

	_connect_button($WorkshopModal/Panel/VBox/CloseBtn, _on_close_workshop_pressed)

	# Setup dos botões de upgrade da oficina
	_setup_workshop_buttons()

func _on_menu_pressed() -> void:
	if AudioManager != null:
		AudioManager.play_sfx("confirm")
		AudioManager.stop_engine()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")

func _connect_button(btn: BaseButton, callback: Callable) -> void:
	if btn == null:
		return
	btn.pressed.connect(callback)

const DEFEAT_EXTRA_TIME_SECONDS: float = 15.0

var _is_restarting: bool = false
var _last_displayed_total_seconds: int = -1

func _on_time_updated(time_left: float) -> void:
	var total_sec: int = int(ceilf(time_left))
	if total_sec == _last_displayed_total_seconds:
		return
	_last_displayed_total_seconds = total_sec

	var minutes: int = floori(float(total_sec) / 60.0)
	var seconds: int = total_sec % 60
	if timer_label != null:
		timer_label.text = "%d:%02d" % [minutes, seconds]
		
		# Alerta visual se o tempo estiver acabando (< 15 segundos)
		if time_left <= 10.0:
			timer_label.modulate = Color(1.0, 0.3, 0.3)
			if AudioManager != null:
				AudioManager.play_countdown_alert()
		else:
			timer_label.modulate = Color.WHITE

func _on_goal_updated(plant_type: String, remaining: int, target: int) -> void:
	if not goal_cards.has(plant_type):
		_create_goal_card(plant_type, target)
	
	var card = goal_cards[plant_type]
	card["count_label"].text = str(remaining)
	
	# Efeito de pop/escala quando atualiza
	var tween = create_tween()
	tween.tween_property(card["container"], "scale", Vector2(1.15, 1.15), 0.05)
	tween.tween_property(card["container"], "scale", Vector2.ONE, 0.05)

func _create_goal_card(plant_type: String, target: int) -> void:
	var card_panel: PanelContainer = PanelContainer.new()
	# Simetria exata de altura 52px com os badges superiores
	card_panel.custom_minimum_size = Vector2(88, 52)
	card_panel.pivot_offset = Vector2(44, 26)
	card_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var empty_style: StyleBoxEmpty = StyleBoxEmpty.new()
	card_panel.add_theme_stylebox_override("panel", empty_style)

	var bg_rect: TextureRect = TextureRect.new()
	bg_rect.texture = BADGE_GOAL_BG
	bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_rect.stretch_mode = TextureRect.STRETCH_SCALE
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_panel.add_child(bg_rect)

	var margin: MarginContainer = MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	card_panel.add_child(margin)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 6)

	# Ilustração botânica canônica da Coleção (34x34)
	var illus_container: Control = GoalIconFactory.build_goal_icon(plant_type, 34.0)

	var count_lbl: Label = Label.new()
	count_lbl.text = str(target)
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Fonte 23px idêntica aos badges da Home
	count_lbl.add_theme_font_size_override("font_size", 23)
	count_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	count_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.4))
	count_lbl.add_theme_constant_override("shadow_offset_y", 1)

	var sys_font: SystemFont = SystemFont.new()
	sys_font.font_names = PackedStringArray(["Segoe UI", "Arial Black", "Montserrat", "sans-serif"])
	sys_font.font_weight = 900
	count_lbl.add_theme_font_override("font", sys_font)

	hbox.add_child(illus_container)
	hbox.add_child(count_lbl)
	margin.add_child(hbox)
	goals_container.add_child(card_panel)

	goal_cards[plant_type] = {
		"container": card_panel,
		"count_label": count_lbl,
		"illus_container": illus_container,
		"bg_rect": bg_rect
	}

func _on_goal_completed(plant_type: String) -> void:
	if goal_cards.has(plant_type):
		var card: Dictionary = goal_cards[plant_type] as Dictionary
		var lbl: Label = card["count_label"] as Label
		lbl.text = "OK"
		lbl.modulate = Color(0.22, 1.0, 0.48)
		var bg: TextureRect = card.get("bg_rect") as TextureRect
		if bg != null:
			bg.texture = BADGE_GOAL_DONE_BG

func _on_coins_changed(new_amount: int) -> void:
	if coins_label != null:
		coins_label.text = "%d" % new_amount

func _on_pause_pressed() -> void:
	GameManager.toggle_pause()

func _on_game_paused(is_paused: bool) -> void:
	if pause_modal != null:
		if pause_modal.has_method("open") and pause_modal.has_method("close"):
			if is_paused:
				pause_modal.call("open")
			else:
				pause_modal.call("close")
		else:
			pause_modal.visible = is_paused

func _on_resume_pressed() -> void:
	GameManager.toggle_pause()

func _on_restart_pressed() -> void:
	if _is_restarting:
		return
	_is_restarting = true
	if top_bar != null:
		top_bar.visible = true
	if pause_button is Button:
		(pause_button as Button).icon = ICON_PAUSE
		(pause_button as Button).expand_icon = true
		(pause_button as Button).text = ""
	if AudioManager != null:
		AudioManager.play_sfx("confirm")
	GameManager.restart_level()

func _on_next_level_pressed() -> void:
	if top_bar != null:
		top_bar.visible = true
	if pause_button is Button:
		(pause_button as Button).icon = ICON_PAUSE
		(pause_button as Button).expand_icon = true
		(pause_button as Button).text = ""
	if AudioManager != null:
		AudioManager.play_sfx("fast_forward")
	GameManager.next_level()

func _on_level_won(coins_earned: int, stars_earned: int = 1) -> void:
	if AudioManager != null:
		AudioManager.stop_countdown_alert()
	if top_bar != null:
		top_bar.visible = false
	if victory_coins_label != null:
		victory_coins_label.text = tr("HUD_COINS_EARNED") % coins_earned

	if victory_time_label != null and GameManager != null:
		var time_taken: float = maxf(0.0, GameManager.time_limit - GameManager.time_left)
		var mins: int = int(time_taken / 60.0)
		var secs: int = int(time_taken) % 60
		victory_time_label.text = "%d:%02d" % [mins, secs]

	if GameManager.current_level >= 20:
		if victory_title_label != null:
			victory_title_label.text = tr("HUD_CHAMPION_TITLE")
		if victory_next_label != null:
			victory_next_label.text = tr("HUD_MASTER_CYCLE")
	else:
		if victory_title_label != null:
			victory_title_label.text = tr("HUD_LEVEL_CLEAR") % GameManager.current_level
		if victory_next_label != null:
			victory_next_label.text = tr("HUD_NEXT_LEVEL")

	victory_modal.visible = true

	# Configura animação das estrelas em arco
	var stars: Array[Control] = []
	if star_1_rect: stars.append(star_1_rect)
	if star_2_rect: stars.append(star_2_rect)
	if star_3_rect: stars.append(star_3_rect)

	var earned: int = clampi(stars_earned, 1, 3)
	for i in range(stars.size()):
		var star_node: Control = stars[i]
		star_node.scale = Vector2.ZERO
		var is_star_won: bool = (i + 1) <= earned
		var delay: float = 0.25 * float(i)

		if is_star_won:
			star_node.modulate = Color(1.0, 1.0, 1.0, 1.0)
			get_tree().create_timer(delay, true, false, true).timeout.connect(func() -> void:
				var star_tween: Tween = create_tween()
				star_tween.tween_property(star_node, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				if AudioManager != null:
					AudioManager.play_sfx("star_pop", 0.05)
			)
		else:
			star_node.modulate = Color(0.25, 0.32, 0.42, 0.45)
			get_tree().create_timer(delay, true, false, true).timeout.connect(func() -> void:
				var star_tween: Tween = create_tween()
				star_tween.tween_property(star_node, "scale", Vector2.ONE * 0.85, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			)

	# Anima a entrada da barra inferior deslizando de baixo para cima
	if victory_bottom_bar != null:
		var target_top: float = victory_bottom_bar.offset_top
		var target_bottom: float = victory_bottom_bar.offset_bottom
		victory_bottom_bar.offset_top += 120.0
		victory_bottom_bar.offset_bottom += 120.0
		var bar_tween: Tween = create_tween()
		bar_tween.tween_property(victory_bottom_bar, "offset_top", target_top, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		bar_tween.parallel().tween_property(victory_bottom_bar, "offset_bottom", target_bottom, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_level_lost(reason: String) -> void:
	if top_bar != null:
		top_bar.visible = false
	get_tree().create_timer(0.65, true, false, true).timeout.connect(func() -> void:
		if GameManager.current_state != GameManager.GameState.GAME_OVER:
			return
		defeat_modal.call("open", GameManager.get_progress_ratio(), GameManager.get_remaining_goals(), GameManager.can_grant_extra_time())
	)

## Placeholder de anúncio recompensado: concede tempo extra e retoma a fase (1 uso por tentativa).
func _on_extra_time_requested() -> void:
	if not GameManager.can_grant_extra_time():
		return
	if top_bar != null:
		top_bar.visible = true
	_last_displayed_total_seconds = -1
	GameManager.grant_extra_time(DEFEAT_EXTRA_TIME_SECONDS)

func _on_open_workshop_pressed() -> void:
	if AudioManager != null:
		AudioManager.play_sfx("confirm")
	_update_workshop_display()
	workshop_modal.visible = true

func _on_close_workshop_pressed() -> void:
	if AudioManager != null:
		AudioManager.play_sfx("close")
	workshop_modal.visible = false

func _on_state_changed(new_state: int) -> void:
	_last_displayed_total_seconds = -1
	if new_state == GameManager.GameState.PLAYING:
		if top_bar != null:
			top_bar.visible = true

# Oficina de Upgrades
func _setup_workshop_buttons() -> void:
	$WorkshopModal/Panel/VBox/UpgradesList/RadiusCard/BuyBtn.pressed.connect(func(): _buy_upgrade("radius"))
	$WorkshopModal/Panel/VBox/UpgradesList/PowerCard/BuyBtn.pressed.connect(func(): _buy_upgrade("power"))
	$WorkshopModal/Panel/VBox/UpgradesList/SpeedCard/BuyBtn.pressed.connect(func(): _buy_upgrade("speed"))
	$WorkshopModal/Panel/VBox/UpgradesList/MultiplierCard/BuyBtn.pressed.connect(func(): _buy_upgrade("multiplier"))

func _buy_upgrade(upgrade_name: String) -> void:
	if UpgradeManager != null:
		if UpgradeManager.buy_upgrade(upgrade_name):
			_update_workshop_display()

func _update_workshop_display() -> void:
	if UpgradeManager == null:
		return
	var blade_name: String = UpgradeManager.get_blade_tier_name() if UpgradeManager.has_method("get_blade_tier_name") else ""
	if blade_name != "":
		$WorkshopModal/Panel/VBox/CoinsBanner.text = "Suas Moedas: %d\nLâmina: %s" % [UpgradeManager.total_coins, blade_name]
	else:
		$WorkshopModal/Panel/VBox/CoinsBanner.text = "Suas Moedas: %d" % UpgradeManager.total_coins

	_update_card("radius", $WorkshopModal/Panel/VBox/UpgradesList/RadiusCard, "Raio da Lâmina")
	_update_card("power", $WorkshopModal/Panel/VBox/UpgradesList/PowerCard, "Potência e Fio")
	_update_card("speed", $WorkshopModal/Panel/VBox/UpgradesList/SpeedCard, "Velocidade")
	_update_card("multiplier", $WorkshopModal/Panel/VBox/UpgradesList/MultiplierCard, "Multiplicador de Moedas")

func _update_card(key: String, card: Control, title: String) -> void:
	var lvl = UpgradeManager.get_level(key)
	var cost = UpgradeManager.get_upgrade_cost(key)
	var lbl = card.get_node("Info/Title") as Label
	var cost_btn = card.get_node("BuyBtn") as Button
	lbl.text = "%s (Nv. %d)" % [title, lvl]
	cost_btn.text = "%d" % cost
	cost_btn.icon = ICON_COIN
	cost_btn.add_theme_constant_override("icon_max_width", 18)
	cost_btn.disabled = (UpgradeManager.total_coins < cost)

# ==============================================================================
# Suporte Mobile: Safe Area (Notch / Cutout) & Gesto/Botão "Voltar" (Play Store)
# ==============================================================================

func _get_safe_area_top_margin() -> float:
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	var win_size: Vector2i = DisplayServer.window_get_size()
	if win_size.x <= 0 or win_size.y <= 0:
		return 0.0
	if safe_area.position.y > 0:
		var scale_y: float = float(get_viewport_rect().size.y) / float(win_size.y)
		var inset: float = float(safe_area.position.y) * scale_y
		return clampf(inset, 0.0, 96.0)
	return 0.0

func _apply_safe_area() -> void:
	var top_inset: float = _get_safe_area_top_margin()
	if top_inset > 0.0 and top_bar != null:
		var style: StyleBox = top_bar.get_theme_stylebox("panel")
		if style is StyleBoxFlat:
			var flat: StyleBoxFlat = (style as StyleBoxFlat).duplicate() as StyleBoxFlat
			flat.content_margin_top += top_inset
			top_bar.add_theme_stylebox_override("panel", flat)
		top_bar.offset_bottom += top_inset

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_back_request()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_handle_back_request()

func _handle_back_request() -> void:
	# 1. Se modal da oficina estiver aberto -> fecha a oficina
	if workshop_modal != null and workshop_modal.visible:
		_on_close_workshop_pressed()
		return

	# 2. Se modal de pausa estiver aberto -> fecha a pausa e retoma o jogo
	if pause_modal != null and pause_modal.visible:
		_on_resume_pressed()
		return

	# 3. Se estiver na tela de vitória ou derrota -> volta ao menu principal
	if victory_modal != null and victory_modal.visible:
		_on_menu_pressed()
		return
	if defeat_modal != null and defeat_modal.visible:
		_on_menu_pressed()
		return

	# 4. Se a partida estiver em andamento -> abre o modal de pausa
	if GameManager != null and GameManager.current_state == GameManager.GameState.PLAYING:
		_on_pause_pressed()
