extends Node

## Gerador Automatizado de Screenshots para Google Play Store
## Captura 4 telas em 1080x1920 (9:16 Portrait) com estado de jogo realista:
## 1. Gameplay 3D (Cutter, ceifa, vegetação, HUD)
## 2. Mapa do Arquipélago (Ilhas 3D, caminhos, fases 1-6)
## 3. Oficina do Robô (Visual 3D, upgrades da lâmina, velocidade, força)
## 4. Herbário Botânico (Espécies descobertas, marcos de colheita)

const OUTPUT_DIR: String = "res://assets/brand/screenshots/"
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const MENU_SCENE: PackedScene = preload("res://scenes/menu/main_menu.tscn")

enum Step {
	PREPARE,
	CAPTURE_GAMEPLAY,
	CAPTURE_MAP,
	CAPTURE_WORKSHOP,
	CAPTURE_HERBARIUM,
	RESTORE_AND_FINISH
}

var current_step: Step = Step.PREPARE
var step_frames: int = 0
var original_save_backup: Dictionary = {}
var active_scene_instance: Node = null

func _ready() -> void:
	print("==================================================")
	print(">>> INICIANDO CAPTURA DE SCREENSHOTS DA LOJA <<<")
	print("==================================================")
	
	# Garante que a pasta de destino exista
	DirAccess.make_dir_recursive_absolute("res://assets/brand/screenshots")
	
	_backup_and_apply_promo_save()
	_advance_to_step(Step.CAPTURE_GAMEPLAY)

func _backup_and_apply_promo_save() -> void:
	if SaveManager != null:
		original_save_backup = SaveManager.save_data.duplicate(true)
		
		# Injeta dados promocionais visualmente atrativos
		var promo_data: Dictionary = SaveManager.get_default_save()
		promo_data["player"]["total_coins"] = 2850
		promo_data["player"]["max_unlocked_level"] = 6
		promo_data["player"]["last_played_level"] = 2
		
		promo_data["upgrades"] = {
			"blade_level": 2,
			"blade_xp": 150.0,
			"radius_level": 2,
			"power_level": 2,
			"speed_level": 2,
			"multiplier_level": 1
		}
		
		promo_data["levels"] = {
			"1": {"completed": true, "stars": 3, "best_time": 24.5},
			"2": {"completed": true, "stars": 3, "best_time": 32.1},
			"3": {"completed": true, "stars": 3, "best_time": 41.8},
			"4": {"completed": true, "stars": 2, "best_time": 54.0},
			"5": {"completed": true, "stars": 3, "best_time": 47.3},
			"6": {"completed": false, "stars": 0, "best_time": 0.0}
		}
		
		promo_data["collection"] = {
			"discovered": {
				"grass_tuft": true,
				"wheat_tuft": true,
				"flower_sunflower": true,
				"flower_rose": true,
				"flower_tulip": true,
				"flower_daisy": true
			},
			"harvest_counts": {
				"grass_tuft": 520,
				"wheat_tuft": 210,
				"flower_sunflower": 95,
				"flower_rose": 48,
				"flower_tulip": 84,
				"flower_daisy": 115
			},
			"claimed_milestone_levels": {
				"grass_tuft": 3,
				"wheat_tuft": 2,
				"flower_sunflower": 1,
				"flower_rose": 1,
				"flower_daisy": 2
			}
		}
		
		SaveManager.save_data = promo_data
		if UpgradeManager != null:
			UpgradeManager.load_from_dict(promo_data["upgrades"], 2850)

func _advance_to_step(next_step: Step) -> void:
	current_step = next_step
	step_frames = 0
	
	if active_scene_instance != null:
		active_scene_instance.queue_free()
		active_scene_instance = null
	
	match current_step:
		Step.CAPTURE_GAMEPLAY:
			print("[1/4] Montando cena de Gameplay (Level 02)...")
			GameManager.current_level = 2
			active_scene_instance = MAIN_SCENE.instantiate()
			add_child(active_scene_instance)
			
		Step.CAPTURE_MAP:
			print("[2/4] Montando cena do Mapa do Arquipélago...")
			active_scene_instance = MENU_SCENE.instantiate()
			add_child(active_scene_instance)
			
		Step.CAPTURE_WORKSHOP:
			print("[3/4] Montando cena da Oficina (Tab Garage)...")
			active_scene_instance = MENU_SCENE.instantiate()
			add_child(active_scene_instance)
			
		Step.CAPTURE_HERBARIUM:
			print("[4/4] Montando cena do Herbário (Tab Collection)...")
			active_scene_instance = MENU_SCENE.instantiate()
			add_child(active_scene_instance)
			
		Step.RESTORE_AND_FINISH:
			_restore_save_and_quit()

func _process(_delta: float) -> void:
	step_frames += 1
	
	match current_step:
		Step.CAPTURE_GAMEPLAY:
			_process_gameplay()
		Step.CAPTURE_MAP:
			_process_map()
		Step.CAPTURE_WORKSHOP:
			_process_workshop()
		Step.CAPTURE_HERBARIUM:
			_process_herbarium()

func _process_gameplay() -> void:
	if active_scene_instance == null:
		return
	
	var cutter: CharacterBody3D = active_scene_instance.get_node_or_null("LevelController/Cutter") as CharacterBody3D
	if cutter != null and step_frames < 30:
		# Faz a lâmina girar ativamente
		var blade_pivot: Node3D = cutter.get_node_or_null("BladePivot") as Node3D
		if blade_pivot != null:
			blade_pivot.rotate_y(0.35)
	
	if step_frames == 35:
		_save_screenshot("01_gameplay_3d_island.png")
		_advance_to_step(Step.CAPTURE_MAP)

func _process_map() -> void:
	if active_scene_instance == null:
		return
	
	var menu: Node3D = active_scene_instance as Node3D
	if step_frames == 5:
		var fade: ColorRect = menu.get_node_or_null("CanvasLayer/FadeRect") as ColorRect
		if fade != null:
			fade.visible = false
		
		# Alterna para a visão do Mapa
		if menu.has_method("_on_toggle_view_requested"):
			menu.call("_on_toggle_view_requested")
	
	# Aguarda 50 frames para transição suave de câmera da ilha
	if step_frames == 55:
		_save_screenshot("02_archipelago_map.png")
		_advance_to_step(Step.CAPTURE_WORKSHOP)

func _process_workshop() -> void:
	if active_scene_instance == null:
		return
	
	var menu: Node3D = active_scene_instance as Node3D
	if step_frames == 5:
		if menu.has_method("_switch_tab"):
			menu.call("_switch_tab", 1) # Índice 1 = Garagem/Oficina
		var fade: ColorRect = menu.get_node_or_null("CanvasLayer/FadeRect") as ColorRect
		if fade != null:
			fade.visible = false
	
	if step_frames == 25:
		_save_screenshot("03_robot_workshop.png")
		_advance_to_step(Step.CAPTURE_HERBARIUM)

func _process_herbarium() -> void:
	if active_scene_instance == null:
		return
	
	var menu: Node3D = active_scene_instance as Node3D
	if step_frames == 5:
		if menu.has_method("_switch_tab"):
			menu.call("_switch_tab", 2) # Índice 2 = Herbário/Coleção
		var fade: ColorRect = menu.get_node_or_null("CanvasLayer/FadeRect") as ColorRect
		if fade != null:
			fade.visible = false
	
	if step_frames == 25:
		_save_screenshot("04_botanical_herbarium.png")
		_advance_to_step(Step.RESTORE_AND_FINISH)

func _save_screenshot(filename: String) -> void:
	var img: Image = get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		push_error("Falha ao capturar imagem do viewport para: " + filename)
		return
	
	# Converte para 1080x1920 (Full HD 9:16) com interpolação de alta qualidade
	if img.get_width() != 1080 or img.get_height() != 1920:
		img.resize(1080, 1920, Image.INTERPOLATE_LANCZOS)
	
	# Converte para RGB8 sem canal alfa (requisito Google Play)
	if img.has_mipmaps():
		img.clear_mipmaps()
	if img.get_format() != Image.FORMAT_RGB8:
		img.convert(Image.FORMAT_RGB8)
	
	var path: String = OUTPUT_DIR + filename
	var global_path: String = ProjectSettings.globalize_path(path)
	var err: Error = img.save_png(global_path)
	if err == OK:
		print("✔ Screenshot salva com sucesso: ", global_path)
	else:
		push_error("Erro ao salvar screenshot: " + str(err))

func _restore_save_and_quit() -> void:
	print("[FINALIZANDO] Restaurando dados de save originais...")
	if SaveManager != null and not original_save_backup.is_empty():
		SaveManager.save_data = original_save_backup
		SaveManager.save_game()
	
	print("==================================================")
	print(">>> TODAS AS 4 SCREENSHOTS GERADAS COM SUCESSO! <<<")
	print("==================================================")
	get_tree().quit(0)
