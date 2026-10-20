extends Node3D

const ISLAND_SCENE: PackedScene = preload("res://scenes/menu/island_node.tscn")
const CLOUDS_END_SCENE: PackedScene = preload("res://scenes/menu/clouds_end_node.tscn")

@onready var menu_camera: Camera3D = $MenuCamera3D
@onready var islands_container: Node3D = $World/IslandsContainer
@onready var menu_bot: Node3D = $World/MenuBot

# Top Bar
@onready var coins_label: Label = $CanvasLayer/TopBar/HBox/CoinsContainer/HBoxCoins/CoinsLabel
@onready var energy_label: Label = $CanvasLayer/TopBar/HBox/EnergyContainer/EnergyLabel
@onready var title_label: Label = $CanvasLayer/TopBar/HBox/TitleContainer/TitleLabel
@onready var settings_btn: Button = $CanvasLayer/TopBar/HBox/SettingsButton

# Modais e Abas
@onready var settings_modal: Control = $CanvasLayer/SettingsModal
@onready var bottom_nav: Control = $CanvasLayer/BottomNavBar
@onready var tab_garage: Control = $CanvasLayer/TabViews/TabGarage
@onready var tab_home: Control = $CanvasLayer/TabViews/TabHome
@onready var tab_collection: Control = $CanvasLayer/TabViews/TabCollection
@onready var tab_store: Control = $CanvasLayer/TabViews/TabStore
@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect
@onready var version_badge: Label = $CanvasLayer.get_node_or_null("VersionBadge") as Label

var total_levels_count: int = 20
var island_nodes: Array[Node3D] = []
var selected_level: int = 1

func _ready() -> void:
	if version_badge != null:
		version_badge.text = GameVersion.get_version_string()

	if fade_rect != null:
		fade_rect.visible = true
		fade_rect.modulate.a = 1.0
		var tw: Tween = create_tween()
		tw.tween_property(fade_rect, "modulate:a", 0.0, 0.35)
		tw.tween_callback(func() -> void: fade_rect.visible = false)

	if settings_modal != null:
		settings_modal.visible = false

	# Sincroniza moedas e status
	_update_top_bar()
	if UpgradeManager != null:
		UpgradeManager.coins_changed.connect(func(_new_amt: int) -> void: _update_top_bar())

	if SaveManager != null:
		SaveManager.save_reset.connect(_on_save_reset)

	# Detecta fases e constrói o arquipélago 3D
	_detect_levels_and_build_archipelago()

	# Conecta sinais da interface
	if settings_btn != null and settings_modal != null:
		settings_btn.pressed.connect(settings_modal.open_modal)

	if bottom_nav != null:
		bottom_nav.tab_changed.connect(_on_tab_changed)

	if tab_home != null:
		tab_home.play_level_requested.connect(_on_play_level_requested)
		tab_home.toggle_view_requested.connect(_on_toggle_view_requested)

	if menu_camera != null:
		menu_camera.view_mode_changed.connect(_on_camera_view_mode_changed)
		menu_camera.island_snapped.connect(_on_camera_island_snapped)

	# Inicia na aba Home e visão do Bot
	_switch_tab(1)
	_update_plaques_view_mode(false, false)

func _on_save_reset() -> void:
	_update_top_bar()
	_detect_levels_and_build_archipelago()

func _detect_levels_and_build_archipelago() -> void:
	# Limpa ilhas anteriores se houver
	for c in islands_container.get_children():
		c.queue_free()
	island_nodes.clear()

	# Identifica quantidade de fases existentes (cobre as 20 fases canônicas)
	var level_count: int = 0
	for lvl in range(1, 21):
		var json_path: String = "res://data/levels/level_%02d.json" % lvl
		var scene_path: String = "res://scenes/levels/level_%02d.tscn" % lvl
		if FileAccess.file_exists(json_path) or ResourceLoader.exists(scene_path):
			level_count = lvl

	total_levels_count = maxi(level_count, 20)

	# Garante que selected_level e GameManager.current_level estejam em faixa válida
	var cur_lvl: int = GameManager.current_level if GameManager != null else 1
	if SaveManager != null:
		cur_lvl = SaveManager.get_last_played_level()
	selected_level = clampi(cur_lvl, 1, total_levels_count)

	var z_spacing: float = 7.2
	var current_z: float = 0.0

	for i in range(1, total_levels_count + 1):
		var island: Node3D = ISLAND_SCENE.instantiate() as Node3D
		islands_container.add_child(island)

		# Padrão em ziguezague no arquipélago tropical
		var x_offset: float = 0.0
		if i == 1:
			x_offset = 0.0
		elif i % 2 == 0:
			x_offset = 2.4
		else:
			x_offset = -2.2

		current_z = -float(i - 1) * z_spacing
		island.position = Vector3(x_offset, 0.0, current_z)

		var is_unlocked: bool = true
		var stars: int = 0
		if SaveManager != null:
			is_unlocked = SaveManager.is_level_unlocked(i)
			stars = SaveManager.get_level_stars(i)
		else:
			is_unlocked = (i <= selected_level)
			stars = 3 if (i < selected_level) else 0

		if island.has_method("setup_island"):
			island.setup_island(i, is_unlocked, stars)
		if island.has_signal("island_selected"):
			island.island_selected.connect(_on_island_clicked)

		island_nodes.append(island)

	# Instancia o banco terminal de nuvens 3D com "Em breve mais fases..."
	var clouds_end: Node3D = CLOUDS_END_SCENE.instantiate() as Node3D
	islands_container.add_child(clouds_end)
	var end_z: float = current_z - 7.5
	clouds_end.position = Vector3(0.0, 0.0, end_z)

	# Configura limites da rolagem e parâmetros da câmera
	if menu_camera != null:
		menu_camera.total_levels = total_levels_count
		menu_camera.z_spacing = z_spacing
		menu_camera.set_scroll_bounds(0.0, end_z)
		var waypoints: Array[Vector3] = []
		for isl in island_nodes:
			waypoints.append(isl.position)
		waypoints.append(clouds_end.position)
		menu_camera.set_island_positions(waypoints)

	# Posiciona o robô na ilha da fase atual
	_update_bot_position()

func _update_bot_position() -> void:
	var idx: int = selected_level - 1
	if idx >= 0 and idx < island_nodes.size():
		var island: Node3D = island_nodes[idx]
		var bot_target: Vector3 = Vector3(0, 0.15, 0)
		if island.has_method("get_bot_position"):
			bot_target = island.get_bot_position()
		else:
			bot_target = island.global_position + Vector3(0, 0.15, 0)

		if menu_bot != null:
			if menu_bot.has_method("set_base_position"):
				menu_bot.set_base_position(bot_target)
			else:
				menu_bot.position = bot_target

		if menu_camera != null:
			menu_camera.set_bot_target(bot_target)

	if tab_home != null and tab_home.has_method("update_level_display"):
		tab_home.update_level_display(selected_level)

func _on_island_clicked(lvl_num: int) -> void:
	if lvl_num <= total_levels_count:
		var can_select: bool = true
		if SaveManager != null:
			can_select = SaveManager.is_level_unlocked(lvl_num)
		if can_select:
			selected_level = lvl_num
			if SaveManager != null:
				SaveManager.set_last_played_level(selected_level)
			if menu_camera != null:
				if menu_camera.current_mode == menu_camera.CameraMode.MAP_VIEW:
					menu_camera.snap_to_level(selected_level, true)
				else:
					_update_bot_position()
			if tab_home != null and tab_home.has_method("update_level_display"):
				tab_home.update_level_display(selected_level)
			if GameManager != null:
				GameManager.trigger_haptic_cut()

func _on_camera_island_snapped(snapped_lvl: int) -> void:
	selected_level = snapped_lvl
	if tab_home != null and tab_home.has_method("update_level_display"):
		tab_home.update_level_display(selected_level)

func _on_toggle_view_requested() -> void:
	if menu_camera != null:
		menu_camera.toggle_mode()

func _on_camera_view_mode_changed(is_map: bool) -> void:
	if tab_home != null and tab_home.has_method("set_view_mode"):
		tab_home.set_view_mode(is_map)
	if title_label != null:
		title_label.text = "Mapa de Fases" if is_map else "Ilha Tropical"
	_update_plaques_view_mode(is_map, true)

func _update_plaques_view_mode(is_map: bool, animated: bool = true) -> void:
	for island in island_nodes:
		if island != null and island.has_method("set_view_mode"):
			var is_active: bool = (island.level_number == selected_level)
			island.set_view_mode(is_map, is_active, animated)

func _on_tab_changed(tab_idx: int) -> void:
	_switch_tab(tab_idx)

func _switch_tab(tab_idx: int) -> void:
	var tabs: Array[Control] = [tab_garage, tab_home, tab_collection, tab_store]
	for i in range(tabs.size()):
		var t: Control = tabs[i]
		if t != null:
			t.visible = (i == tab_idx)

	# Se for para outra aba que não a Home, garante visão do bot ou reseta mapa
	if tab_idx != 1 and menu_camera != null:
		if menu_camera.current_mode == menu_camera.CameraMode.MAP_VIEW:
			menu_camera.switch_to_bot_view()

func _update_top_bar() -> void:
	if coins_label != null and UpgradeManager != null:
		coins_label.text = str(UpgradeManager.total_coins)
	if energy_label != null:
		energy_label.text = "❤️ 5 Max"

func _on_play_level_requested(lvl_to_play: int) -> void:
	if GameManager != null:
		GameManager.current_level = lvl_to_play

	# Transição de fade out para o gameplay
	if fade_rect != null:
		fade_rect.visible = true
		fade_rect.modulate.a = 0.0
		var tw: Tween = create_tween()
		tw.tween_property(fade_rect, "modulate:a", 1.0, 0.25)
		tw.tween_callback(func() -> void:
			get_tree().change_scene_to_file("res://scenes/main.tscn")
		)
	else:
		get_tree().change_scene_to_file("res://scenes/main.tscn")
