extends Control

@onready var timer_label: Label = $TopBar/HBox/TimerContainer/TimerLabel
@onready var pause_button: Button = $TopBar/HBox/PauseButton
@onready var coins_label: Label = $TopBar/HBox/CoinsContainer/HBoxCoins/CoinsLabel
@onready var goals_container: HBoxContainer = $TopBar/HBox/GoalsContainer

@onready var pause_modal: Control = $PauseModal
@onready var victory_modal: Control = $VictoryModal
@onready var game_over_modal: Control = $GameOverModal
@onready var workshop_modal: Control = $WorkshopModal

# Elementos da comemoração de vitória e modais
@onready var victory_title_label: Label = $VictoryModal.find_child("Title", true, false) as Label
@onready var star_1_label: Label = $VictoryModal.find_child("Star1", true, false) as Label
@onready var star_2_label: Label = $VictoryModal.find_child("Star2", true, false) as Label
@onready var star_3_label: Label = $VictoryModal.find_child("Star3", true, false) as Label
@onready var victory_time_label: Label = $VictoryModal.find_child("TimeLabel", true, false) as Label
@onready var victory_coins_label: Label = $VictoryModal.find_child("CoinsEarnedLabel", true, false) as Label
@onready var victory_bottom_bar: PanelContainer = $VictoryModal.find_child("BottomBar", true, false) as PanelContainer
@onready var game_over_reason_label: Label = $GameOverModal/Panel/VBox/ReasonLabel

# Dicionário de Goal Cards instanciados: { "grass": { "container": Node, "count_label": Label, ... } }
var goal_cards: Dictionary = {}

func _ready() -> void:
	# Oculta modais inicialmente
	pause_modal.visible = false
	victory_modal.visible = false
	game_over_modal.visible = false
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

	if UpgradeManager != null:
		UpgradeManager.coins_changed.connect(_on_coins_changed)
		_on_coins_changed(UpgradeManager.total_coins)

	# Conecta botões com suporte robusto a clique e touch
	_connect_button(pause_button, _on_pause_pressed)
	_connect_button($PauseModal/Panel/VBox/ResumeBtn, _on_resume_pressed)
	_connect_button($PauseModal/Panel/VBox/RestartBtn, _on_restart_pressed)
	_connect_button($PauseModal/Panel/VBox/WorkshopBtn, _on_open_workshop_pressed)
	if $PauseModal/Panel/VBox.has_node("MenuBtn"):
		_connect_button($PauseModal/Panel/VBox/MenuBtn, _on_menu_pressed)

	var next_btn: Button = $VictoryModal.find_child("NextBtn", true, false) as Button
	if next_btn:
		_connect_button(next_btn, _on_next_level_pressed)
	var restart_btn: Button = $VictoryModal.find_child("RestartBtn", true, false) as Button
	if restart_btn:
		_connect_button(restart_btn, _on_restart_pressed)
	var menu_btn: Button = $VictoryModal.find_child("MenuBtn", true, false) as Button
	if menu_btn:
		_connect_button(menu_btn, _on_menu_pressed)

	if $GameOverModal/Panel/VBox.has_node("RetryBtn"):
		_connect_button($GameOverModal/Panel/VBox/RetryBtn, _on_restart_pressed)
	if $GameOverModal/Panel/VBox.has_node("MenuBtn"):
		_connect_button($GameOverModal/Panel/VBox/MenuBtn, _on_menu_pressed)

	_connect_button($WorkshopModal/Panel/VBox/CloseBtn, _on_close_workshop_pressed)

	# Setup dos botões de upgrade da oficina
	_setup_workshop_buttons()

func _on_menu_pressed() -> void:
	if AudioManager != null:
		AudioManager.play_sfx("confirm")
		AudioManager.stop_engine()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")

func _connect_button(btn: Button, callback: Callable) -> void:
	if btn == null:
		return
	btn.pressed.connect(callback)

var _is_restarting: bool = false

func _on_time_updated(time_left: float) -> void:
	var minutes: int = int(time_left / 60.0)
	var seconds: int = int(time_left) % 60
	if timer_label != null:
		timer_label.text = "%d:%02d" % [minutes, seconds]
		
		# Alerta visual se o tempo estiver acabando (< 15 segundos)
		if time_left <= 15.0:
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
	var card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(70, 70)
	card_panel.pivot_offset = Vector2(35, 35)

	# Estilo arredondado fosco
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.16, 0.2, 0.85)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	card_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var icon_label = Label.new()
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	match plant_type:
		"grass": icon_label.text = "🌿"
		"wheat": icon_label.text = "🌾"
		"flower": icon_label.text = "🌸"
		_: icon_label.text = "🌱"
	icon_label.add_theme_font_size_override("font_size", 24)

	var count_lbl = Label.new()
	count_lbl.text = str(target)
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_lbl.add_theme_font_size_override("font_size", 18)

	vbox.add_child(icon_label)
	vbox.add_child(count_lbl)
	card_panel.add_child(vbox)
	goals_container.add_child(card_panel)

	goal_cards[plant_type] = {
		"container": card_panel,
		"count_label": count_lbl,
		"icon_label": icon_label,
		"style": style
	}

func _on_goal_completed(plant_type: String) -> void:
	if goal_cards.has(plant_type):
		var card = goal_cards[plant_type]
		card["count_label"].text = "✔"
		card["count_label"].modulate = Color(0.3, 1.0, 0.4)
		card["style"].bg_color = Color(0.1, 0.4, 0.2, 0.9)

func _on_coins_changed(new_amount: int) -> void:
	if coins_label != null:
		coins_label.text = "%d" % new_amount

func _on_pause_pressed() -> void:
	GameManager.toggle_pause()

func _on_game_paused(is_paused: bool) -> void:
	pause_modal.visible = is_paused

func _on_resume_pressed() -> void:
	GameManager.toggle_pause()

func _on_restart_pressed() -> void:
	if _is_restarting:
		return
	_is_restarting = true
	if AudioManager != null:
		AudioManager.play_sfx("confirm")
	GameManager.restart_level()

func _on_next_level_pressed() -> void:
	if AudioManager != null:
		AudioManager.play_sfx("fast_forward")
	GameManager.next_level()

func _on_level_won(coins_earned: int, stars_earned: int = 1) -> void:
	if victory_coins_label != null:
		victory_coins_label.text = "+ %d Moedas" % coins_earned

	if victory_time_label != null and GameManager != null:
		var time_taken: float = maxf(0.0, GameManager.time_limit - GameManager.time_left)
		var mins: int = int(time_taken / 60.0)
		var secs: int = int(time_taken) % 60
		victory_time_label.text = "⏱️ %d:%02d" % [mins, secs]

	var next_btn: Button = $VictoryModal.find_child("NextBtn", true, false) as Button
	if GameManager.current_level >= 20:
		if victory_title_label != null:
			victory_title_label.text = "🏆 Campeão do Jardim! 🏆"
		if next_btn != null:
			next_btn.text = "Ciclo Mestre (Fase 1) 👑"
	else:
		if victory_title_label != null:
			victory_title_label.text = "Fase %02d Concluída!" % GameManager.current_level
		if next_btn != null:
			next_btn.text = "Próxima Fase ➔"

	victory_modal.visible = true

	# Configura animação das estrelas em arco
	var stars: Array[Label] = []
	if star_1_label: stars.append(star_1_label)
	if star_2_label: stars.append(star_2_label)
	if star_3_label: stars.append(star_3_label)

	var earned: int = clampi(stars_earned, 1, 3)
	for i in range(stars.size()):
		var lbl: Label = stars[i]
		lbl.scale = Vector2.ZERO
		var is_star_won: bool = (i + 1) <= earned
		var delay: float = 0.25 * float(i)

		if is_star_won:
			lbl.modulate = Color(1.0, 1.0, 1.0, 1.0)
			lbl.text = "⭐"
			get_tree().create_timer(delay, true, false, true).timeout.connect(func() -> void:
				var star_tween: Tween = create_tween()
				star_tween.tween_property(lbl, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				if AudioManager != null:
					AudioManager.play_sfx("star_pop", 0.05)
			)
		else:
			lbl.modulate = Color(0.45, 0.5, 0.6, 0.45)
			lbl.text = "☆"
			get_tree().create_timer(delay, true, false, true).timeout.connect(func() -> void:
				var star_tween: Tween = create_tween()
				star_tween.tween_property(lbl, "scale", Vector2.ONE * 0.85, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
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
	game_over_reason_label.text = reason
	get_tree().create_timer(0.65, true, false, true).timeout.connect(func() -> void:
		game_over_modal.visible = true
	)

func _on_open_workshop_pressed() -> void:
	if AudioManager != null:
		AudioManager.play_sfx("confirm")
	_update_workshop_display()
	workshop_modal.visible = true

func _on_close_workshop_pressed() -> void:
	if AudioManager != null:
		AudioManager.play_sfx("close")
	workshop_modal.visible = false

func _on_state_changed(_new_state: int) -> void:
	pass

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
		$WorkshopModal/Panel/VBox/CoinsBanner.text = "Suas Moedas: %d 🪙\nLâmina: %s" % [UpgradeManager.total_coins, blade_name]
	else:
		$WorkshopModal/Panel/VBox/CoinsBanner.text = "Suas Moedas: %d 🪙" % UpgradeManager.total_coins

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
	cost_btn.text = "%d 🪙" % cost
	cost_btn.disabled = (UpgradeManager.total_coins < cost)
