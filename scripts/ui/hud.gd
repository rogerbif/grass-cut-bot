extends Control

@onready var timer_label: Label = $TopBar/HBox/TimerContainer/TimerLabel
@onready var pause_button: Button = $TopBar/HBox/PauseButton
@onready var coins_label: Label = $TopBar/HBox/CoinsContainer/HBoxCoins/CoinsLabel
@onready var goals_container: HBoxContainer = $TopBar/HBox/GoalsContainer

@onready var pause_modal: Control = $PauseModal
@onready var victory_modal: Control = $VictoryModal
@onready var game_over_modal: Control = $GameOverModal
@onready var workshop_modal: Control = $WorkshopModal

# Elementos das janelas de fim de jogo e pausa
@onready var victory_coins_label: Label = $VictoryModal/Panel/VBox/CoinsEarnedLabel
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

	# Conecta botões
	pause_button.pressed.connect(_on_pause_pressed)
	$PauseModal/Panel/VBox/ResumeBtn.pressed.connect(_on_resume_pressed)
	$PauseModal/Panel/VBox/RestartBtn.pressed.connect(_on_restart_pressed)
	$PauseModal/Panel/VBox/WorkshopBtn.pressed.connect(_on_open_workshop_pressed)

	$VictoryModal/Panel/VBox/NextBtn.pressed.connect(_on_next_level_pressed)
	$VictoryModal/Panel/VBox/RestartBtn.pressed.connect(_on_restart_pressed)
	$VictoryModal/Panel/VBox/WorkshopBtn.pressed.connect(_on_open_workshop_pressed)

	$GameOverModal/Panel/VBox/RetryBtn.pressed.connect(_on_restart_pressed)
	$GameOverModal/Panel/VBox/WorkshopBtn.pressed.connect(_on_open_workshop_pressed)

	$WorkshopModal/Panel/VBox/CloseBtn.pressed.connect(_on_close_workshop_pressed)

	# Setup dos botões de upgrade da oficina
	_setup_workshop_buttons()

func _on_time_updated(time_left: float) -> void:
	var minutes: int = int(time_left / 60.0)
	var seconds: int = int(time_left) % 60
	if timer_label != null:
		timer_label.text = "%d:%02d" % [minutes, seconds]
		
		# Alerta visual se o tempo estiver acabando (< 15 segundos)
		if time_left <= 15.0:
			timer_label.modulate = Color(1.0, 0.3, 0.3)
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
	GameManager.restart_level()

func _on_next_level_pressed() -> void:
	GameManager.next_level()

func _on_level_won(coins_earned: int) -> void:
	victory_coins_label.text = "+ %d Moedas" % coins_earned
	victory_modal.visible = true

func _on_level_lost(reason: String) -> void:
	game_over_reason_label.text = reason
	game_over_modal.visible = true

func _on_open_workshop_pressed() -> void:
	_update_workshop_display()
	workshop_modal.visible = true

func _on_close_workshop_pressed() -> void:
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
	cost_btn.text = "%d 🪙" % cost
	cost_btn.disabled = (UpgradeManager.total_coins < cost)
