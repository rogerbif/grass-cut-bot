extends Node3D

const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")
const IslandMeshBuilder = preload("res://scripts/level/island_mesh_builder.gd")
const TilePaletteDB = preload("res://scripts/editor/tile_palette_db.gd")
const IslandAutotiler = preload("res://scripts/editor/island_autotiler.gd")
const BrushPatterns = preload("res://scripts/editor/brush_patterns.gd")
const LevelSerializer = preload("res://scripts/editor/level_serializer.gd")
const VegetationFieldScript = preload("res://scripts/level/vegetation_field.gd")
const VectorGrassFieldScript = preload("res://scripts/level/vector_grass_field.gd")
const VegetationGridScript = preload("res://scripts/plants/vegetation_grid.gd")
const ROCK_SCENE: PackedScene = preload("res://scenes/obstacles/rock.tscn")
const FLOWER_SCENE: PackedScene = preload("res://scenes/plants/flower_tuft.tscn")
const FLOWER_ROSE_SCENE: PackedScene = preload("res://scenes/plants/flower_rose.tscn")
const FLOWER_DAISY_SCENE: PackedScene = preload("res://scenes/plants/flower_daisy.tscn")
const FLOWER_SUNFLOWER_SCENE: PackedScene = preload("res://scenes/plants/flower_sunflower.tscn")
const FLOWER_BELL_SCENE: PackedScene = preload("res://scenes/plants/flower_bell.tscn")
const FLOWER_COROLLA_SCENE: PackedScene = preload("res://scenes/plants/flower_corolla.tscn")
const FLOWER_TULIP_SCENE: PackedScene = preload("res://scenes/plants/flower_tulip.tscn")
const FLOWER_BED_SCENE: PackedScene = preload("res://scenes/plants/flower_bed.tscn")
const WHEAT_SCENE: PackedScene = preload("res://scenes/plants/wheat_tuft.tscn")

const CUTTER_SCENE: PackedScene = preload("res://scenes/cutter/cutter.tscn")
const JOYSTICK_SCENE: PackedScene = preload("res://scenes/ui/floating_joystick.tscn")
const MAX_UNDO_STEPS: int = 30
const CELL_SIZE: float = 0.40
const COASTAL_GRASS_CORRIDOR: float = 0.48
const ROCK_CLEARANCE_RADIUS: float = 1.40

static var _editor_vector_materials: Dictionary = {}

static func _get_editor_vector_material(v_type: String) -> StandardMaterial3D:
	if _editor_vector_materials.has(v_type):
		return _editor_vector_materials[v_type] as StandardMaterial3D

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.roughness = 0.90
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	match v_type:
		"grass_yellow":
			mat.albedo_color = Color(0.88, 0.80, 0.32, 1.0)
		"grass_blue":
			mat.albedo_color = Color(0.34, 0.62, 0.90, 1.0)
		"grass_purple":
			mat.albedo_color = Color(0.69, 0.39, 0.85, 1.0)
		"grass_white":
			mat.albedo_color = Color(0.92, 0.94, 0.96, 1.0)
		"grass_red":
			mat.albedo_color = Color(0.88, 0.35, 0.37, 1.0)
		"grass_black":
			mat.albedo_color = Color(0.18, 0.18, 0.22, 1.0)
		"wheat":
			mat.albedo_color = Color(0.92, 0.72, 0.20, 1.0)
		"flower":
			mat.albedo_color = Color(0.95, 0.35, 0.65, 1.0)
		_:
			mat.albedo_color = Color(0.34, 0.72, 0.37, 1.0) # grass_green

	_editor_vector_materials[v_type] = mat
	return mat

enum EditLayer {
	TERRAIN = 0,
	GRASS = 1,
	OBJECTS = 2
}

enum ToolMode {
	BRUSH = 0,
	ERASER = 1,
	BOX_FILL = 2,
	SPAWN = 3
}

@onready var editor_camera: Camera3D = $EditorCamera
@onready var playtest_game_camera: Camera3D = get_node_or_null("PlaytestGameCamera")
@onready var grid_overlay: Node3D = $GridOverlay
@onready var water_ocean: Node3D = $WaterOcean
@onready var island_tiles_container: Node3D = $IslandTilesContainer
@onready var coastal_limits_body: StaticBody3D = $CoastalLimitsBody
@onready var plants_container: Node3D = $PlantsContainer
@onready var obstacles_container: Node3D = $ObstaclesContainer
@onready var spawn_marker_visual: Node3D = $SpawnMarkerVisual
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var ui: Control = $CanvasLayer/LevelEditorUI

enum QuickAdjustMode {
	ROTATION = 0,
	SCALE = 1
}

var current_level_id: int = 1
var grid_width: int = 12
var grid_height: int = 8
var time_limit: float = 90.0

var active_layer: int = EditLayer.TERRAIN
var active_tool: int = ToolMode.BRUSH
var active_shape: int = BrushPatterns.ShapeType.SINGLE
var brush_size: int = 1
var current_corner_radius: float = 0.28
var current_rot_deg: int = 0
var active_adjust_mode: int = QuickAdjustMode.SCALE

var active_terrain_id: String = "auto_island"
var active_grass_id: String = "grass_green"
var active_object_id: String = "rock"

# Matrizes de dados do nível em memória
# terrain_grid: Vector2i -> { "tile_id": String, "rot": int, "auto": bool }
var terrain_grid: Dictionary = {}
# object_grid: Vector2i -> { "type": String, "rot": int }
var object_grid: Dictionary = {}
var veg_field: RefCounted = null
var vector_grass: RefCounted = null
var spawn_cell: Vector2i = Vector2i(6, 4)
var spawn_rot: int = 0

var hovered_cell: Vector2i = Vector2i(-1, -1)
var is_hover_in_bounds: bool = false
var last_world_hit: Vector3 = Vector3.ZERO
var _freehand_points: Array[Vector2] = []

var is_painting_lmb: bool = false
var is_erasing_rmb: bool = false
var rmb_press_pos: Vector2 = Vector2.ZERO
var rmb_dragged: bool = false
var is_box_dragging: bool = false
var box_start_cell: Vector2i = Vector2i.ZERO
var _stroke_modified: bool = false

var _undo_stack: Array[Dictionary] = []
var _redo_stack: Array[Dictionary] = []
var _last_editor_goals: Dictionary = {}

var is_playtesting: bool = false
var _playtest_cutter: CharacterBody3D = null
var _playtest_joystick: Control = null
var _active_veg_grid: Node3D = null

func _ready() -> void:
	_setup_desktop_window()
	_reset_grass_shader_interaction()
	_build_spawn_marker_mesh()
	_connect_ui_signals()

	if GameManager != null:
		GameManager.current_state = GameManager.GameState.READY
		GameManager.time_updated.connect(_on_game_time_updated)
		GameManager.goal_updated.connect(_on_game_goal_updated)
		GameManager.level_won.connect(_on_playtest_won)
		GameManager.level_lost.connect(_on_playtest_lost)

	# Carrega Fase 1 (ou cria a Fase 1 canônica em formato de ilha se não existir JSON ainda)
	var start_lvl: int = GameManager.current_level if GameManager != null else 1
	_load_or_init_level(start_lvl)
	_sync_all_ui()

func _reset_grass_shader_interaction() -> void:
	RenderingServer.global_shader_parameter_set("global_cutter_pos", Vector3(0.0, -9999.0, 0.0))
	RenderingServer.global_shader_parameter_set("global_cutter_interact_radius", 0.0)

func _setup_desktop_window() -> void:
	var win: Window = get_window()
	if win != null:
		win.content_scale_size = Vector2i(1920, 1080)
		win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	if not OS.has_feature("mobile") and not OS.has_feature("android"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var screen_rect: Rect2i = DisplayServer.screen_get_usable_rect()
		var target_w: int = mini(1600, int(float(screen_rect.size.x) * 0.90))
		var target_h: int = mini(900, int(float(screen_rect.size.y) * 0.88))
		var target_size: Vector2i = Vector2i(target_w, target_h)
		DisplayServer.window_set_size(target_size)
		var centered_pos: Vector2i = screen_rect.position + Vector2i(
			int(float(screen_rect.size.x - target_size.x) / 2.0),
			int(float(screen_rect.size.y - target_size.y) / 2.0)
		)
		DisplayServer.window_set_position(centered_pos)

func _restore_mobile_window() -> void:
	if not OS.has_feature("mobile") and not OS.has_feature("android"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var mobile_size: Vector2i = Vector2i(450, 800)
		DisplayServer.window_set_size(mobile_size)
		var screen_rect: Rect2i = DisplayServer.screen_get_usable_rect()
		var centered_pos: Vector2i = screen_rect.position + Vector2i(
			int(float(screen_rect.size.x - mobile_size.x) / 2.0),
			int(float(screen_rect.size.y - mobile_size.y) / 2.0)
		)
		DisplayServer.window_set_position(centered_pos)
	var win: Window = get_window()
	if win != null:
		win.content_scale_size = Vector2i(720, 1280)
		win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP_WIDTH

func _build_spawn_marker_mesh() -> void:
	if spawn_marker_visual == null:
		return
	for c in spawn_marker_visual.get_children():
		c.queue_free()

	var ring_mesh: CylinderMesh = CylinderMesh.new()
	ring_mesh.top_radius = 0.34
	ring_mesh.bottom_radius = 0.34
	ring_mesh.height = 0.06
	var ring_mat: StandardMaterial3D = StandardMaterial3D.new()
	ring_mat.albedo_color = Color(1.0, 0.82, 0.15, 0.9)
	ring_mat.roughness = 0.4
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(1.0, 0.75, 0.1)
	ring_mat.emission_energy_multiplier = 0.5
	ring_mesh.material = ring_mat

	var ring_inst: MeshInstance3D = MeshInstance3D.new()
	ring_inst.mesh = ring_mesh
	ring_inst.position = Vector3(0.0, 0.04, 0.0)
	spawn_marker_visual.add_child(ring_inst)

	var bot_beacon: CylinderMesh = CylinderMesh.new()
	bot_beacon.top_radius = 0.14
	bot_beacon.bottom_radius = 0.20
	bot_beacon.height = 0.35
	var beacon_mat: StandardMaterial3D = StandardMaterial3D.new()
	beacon_mat.albedo_color = Color(0.15, 0.85, 1.0)
	beacon_mat.roughness = 0.5
	bot_beacon.material = beacon_mat

	var beacon_inst: MeshInstance3D = MeshInstance3D.new()
	beacon_inst.mesh = bot_beacon
	beacon_inst.position = Vector3(0.0, 0.22, 0.0)
	spawn_marker_visual.add_child(beacon_inst)

func _connect_ui_signals() -> void:
	if ui == null:
		return
	ui.level_load_requested.connect(_on_level_load_requested)
	ui.grid_resize_requested.connect(_on_grid_resize_requested)
	ui.time_limit_changed.connect(func(new_t: float) -> void: time_limit = new_t)
	ui.generate_base_island_requested.connect(_on_generate_base_island)
	ui.clear_objects_requested.connect(_on_clear_objects)
	ui.clear_all_requested.connect(_on_clear_all)
	ui.undo_requested.connect(perform_undo)
	ui.redo_requested.connect(perform_redo)
	ui.save_json_requested.connect(save_current_level_json)
	ui.bake_tscn_requested.connect(bake_current_level_tscn)
	ui.playtest_toggled.connect(toggle_playtest)
	ui.exit_to_game_requested.connect(_on_exit_to_game)

	ui.layer_changed.connect(func(l_idx: int) -> void:
		active_layer = l_idx
		_sync_all_ui()
		_refresh_hover_preview()
	)
	ui.tool_changed.connect(func(t_idx: int) -> void:
		active_tool = t_idx
		_sync_all_ui()
		_refresh_hover_preview()
	)
	ui.brush_shape_changed.connect(func(s_idx: int) -> void:
		active_shape = s_idx
		if active_tool == ToolMode.BOX_FILL or active_tool == ToolMode.SPAWN:
			active_tool = ToolMode.BRUSH
		_sync_all_ui()
		_refresh_hover_preview()
	)
	ui.brush_size_changed.connect(func(delta_sz: int) -> void:
		active_adjust_mode = QuickAdjustMode.SCALE
		_adjust_scale(delta_sz)
	)
	ui.corner_radius_changed.connect(func(r: float) -> void:
		current_corner_radius = r
		_refresh_hover_preview()
	)
	ui.rotate_requested.connect(func() -> void:
		active_adjust_mode = QuickAdjustMode.ROTATION
		_rotate_active_step_dir(1, Input.is_key_pressed(KEY_SHIFT))
	)
	ui.rotate_step_requested.connect(func(direction: int, is_shift: bool) -> void:
		active_adjust_mode = QuickAdjustMode.ROTATION
		_rotate_active_step_dir(direction, is_shift)
	)
	ui.adjust_mode_changed.connect(func(mode: int) -> void:
		active_adjust_mode = mode
		_sync_all_ui()
	)
	ui.toggle_camera_view_requested.connect(func() -> void:
		editor_camera.toggle_top_down()
		_sync_all_ui()
	)
	ui.terrain_tile_selected.connect(func(t_id: String) -> void:
		active_terrain_id = t_id
		active_layer = EditLayer.TERRAIN
		if active_tool == ToolMode.SPAWN or active_tool == ToolMode.ERASER:
			active_tool = ToolMode.BRUSH
		_sync_all_ui()
		_refresh_hover_preview()
	)
	ui.grass_item_selected.connect(func(g_id: String) -> void:
		active_grass_id = g_id
		active_layer = EditLayer.GRASS
		if active_tool == ToolMode.SPAWN or active_tool == ToolMode.ERASER:
			active_tool = ToolMode.BRUSH
		_sync_all_ui()
		_refresh_hover_preview()
	)
	ui.convert_yellow_to_wheat_requested.connect(_on_convert_yellow_to_wheat)
	ui.object_item_selected.connect(func(o_id: String) -> void:
		if o_id == "cutter_spawn":
			active_tool = ToolMode.SPAWN
			active_layer = EditLayer.OBJECTS
		else:
			active_object_id = o_id
			active_layer = EditLayer.OBJECTS
			if active_object_id.begins_with("flower"):
				current_rot_deg = 0
			if active_tool == ToolMode.SPAWN or active_tool == ToolMode.ERASER:
				active_tool = ToolMode.BRUSH
		_sync_all_ui()
		_refresh_hover_preview()
	)

func _adjust_scale(delta_sz: int) -> void:
	brush_size = clampi(brush_size + delta_sz, 1, 20)
	_sync_all_ui()
	_refresh_hover_preview()

func _rotate_active_step_dir(direction: int, is_shift: bool) -> void:
	if active_layer == EditLayer.TERRAIN:
		current_rot_deg = posmod(current_rot_deg + direction * 90, 360)
	else:
		var step_deg: int = 25 if is_shift else 5
		current_rot_deg = posmod(current_rot_deg + direction * step_deg, 360)
	_sync_all_ui()
	_refresh_hover_preview()

func _rotate_active_step() -> void:
	_rotate_active_step_dir(1, false)

func _sync_all_ui() -> void:
	if ui == null:
		return
	ui.sync_state(
		active_layer,
		active_tool,
		active_shape,
		brush_size,
		current_rot_deg,
		active_terrain_id,
		active_grass_id,
		active_object_id,
		editor_camera.is_top_down if editor_camera != null else false,
		active_adjust_mode
	)
	ui.update_level_header(current_level_id, grid_width, grid_height, time_limit)
	ui.update_goals_summary(terrain_grid.size(), object_grid, veg_field, vector_grass)

func _input(event: InputEvent) -> void:
	# Ignora eventos sintéticos de touch gerados pelo emulate_touch_from_mouse no modo Edição
	if not is_playtesting and (event is InputEventScreenTouch or event is InputEventScreenDrag):
		return

	if event is InputEventKey:
		var ke: InputEventKey = event as InputEventKey
		if ke.pressed and not ke.echo:
			if ke.keycode == KEY_F1 or ke.keycode == KEY_F5:
				toggle_playtest()
				get_viewport().set_input_as_handled()
				return
			if is_playtesting and ke.keycode == KEY_ESCAPE:
				toggle_playtest()
				get_viewport().set_input_as_handled()
				return

			if not is_playtesting and not ui.has_text_focus():
				if ke.ctrl_pressed and ke.keycode == KEY_S:
					save_current_level_json()
					get_viewport().set_input_as_handled()
					return
				if ke.ctrl_pressed and ke.keycode == KEY_Z:
					perform_undo()
					get_viewport().set_input_as_handled()
					return
				if ke.ctrl_pressed and ke.keycode == KEY_Y:
					perform_redo()
					get_viewport().set_input_as_handled()
					return

				match ke.keycode:
					KEY_1, KEY_B:
						active_tool = ToolMode.BRUSH
						_sync_all_ui()
						_refresh_hover_preview()
					KEY_2, KEY_E:
						active_tool = ToolMode.ERASER
						_sync_all_ui()
						_refresh_hover_preview()
					KEY_3, KEY_F:
						active_tool = ToolMode.BOX_FILL
						_sync_all_ui()
						_refresh_hover_preview()
					KEY_4:
						active_tool = ToolMode.SPAWN
						_sync_all_ui()
						_refresh_hover_preview()
					KEY_S:
						active_adjust_mode = QuickAdjustMode.SCALE
						_sync_all_ui()
						_refresh_hover_preview()
					KEY_R:
						active_adjust_mode = QuickAdjustMode.ROTATION
						_rotate_active_step_dir(1, ke.shift_pressed)
					KEY_BRACKETLEFT, KEY_MINUS, KEY_KP_SUBTRACT:
						if active_adjust_mode == QuickAdjustMode.SCALE:
							var step_sz: int = 5 if ke.shift_pressed else 1
							_adjust_scale(-step_sz)
						else:
							_rotate_active_step_dir(-1, ke.shift_pressed)
					KEY_BRACKETRIGHT, KEY_PLUS, KEY_EQUAL, KEY_KP_ADD:
						if active_adjust_mode == QuickAdjustMode.SCALE:
							var step_sz: int = 5 if ke.shift_pressed else 1
							_adjust_scale(step_sz)
						else:
							_rotate_active_step_dir(1, ke.shift_pressed)
					KEY_V:
						editor_camera.toggle_top_down()
						_sync_all_ui()

	if is_playtesting:
		return

	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var over_ui: bool = ui.is_mouse_over_ui(mouse_pos) if ui != null else false
	var text_focus: bool = ui.has_text_focus() if ui != null else false

	# Alt + Scroll ajusta tamanho do pincel
	if event is InputEventMouseButton and Input.is_key_pressed(KEY_ALT) and not over_ui:
		var mb_alt: InputEventMouseButton = event as InputEventMouseButton
		if mb_alt.pressed and mb_alt.button_index == MOUSE_BUTTON_WHEEL_UP:
			brush_size = clampi(brush_size + 1, 1, 20)
			_sync_all_ui()
			_refresh_hover_preview()
			return
		elif mb_alt.pressed and mb_alt.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			brush_size = clampi(brush_size - 1, 1, 20)
			_sync_all_ui()
			_refresh_hover_preview()
			return

	if editor_camera != null:
		editor_camera.handle_camera_input(event, text_focus, over_ui)

	if event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		if is_erasing_rmb and mm.position.distance_to(rmb_press_pos) > 6.0:
			rmb_dragged = true
		_update_hovered_cell(mm.position)
		if is_painting_lmb and not over_ui:
			if active_layer == EditLayer.GRASS:
				var hit_2d: Vector2 = Vector2(last_world_hit.x, last_world_hit.z)
				if active_shape == BrushPatterns.ShapeType.SINGLE:
					if _freehand_points.is_empty() or _freehand_points[-1].distance_to(hit_2d) >= 0.08:
						_freehand_points.append(hit_2d)
						_refresh_hover_preview()
				else:
					if _freehand_points.is_empty() or _freehand_points[-1].distance_to(hit_2d) >= float(brush_size) * 0.35:
						_freehand_points.clear()
						_freehand_points.append(hit_2d)
						var is_erase: bool = (active_tool == ToolMode.ERASER)
						_apply_brush_at(hovered_cell, is_erase)
			else:
				if active_tool == ToolMode.BRUSH:
					_apply_brush_at(hovered_cell, false)
				elif active_tool == ToolMode.ERASER:
					_apply_brush_at(hovered_cell, true)

	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		_update_hovered_cell(mb.position)

		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and not over_ui:
				if text_focus:
					get_viewport().gui_release_focus()
				if active_tool == ToolMode.BOX_FILL:
					if is_hover_in_bounds:
						_push_undo_snapshot()
						is_box_dragging = true
						box_start_cell = hovered_cell
						_refresh_hover_preview()
				elif active_tool == ToolMode.SPAWN:
					if is_hover_in_bounds:
						_push_undo_snapshot()
						_place_spawn_at(hovered_cell)
				elif active_tool == ToolMode.BRUSH:
					_push_undo_snapshot()
					is_painting_lmb = true
					_stroke_modified = false
					if active_layer == EditLayer.GRASS:
						if active_shape != BrushPatterns.ShapeType.SINGLE:
							_apply_brush_at(hovered_cell, false)
						else:
							_freehand_points.clear()
							_freehand_points.append(Vector2(last_world_hit.x, last_world_hit.z))
							_refresh_hover_preview()
					else:
						_apply_brush_at(hovered_cell, false)
				elif active_tool == ToolMode.ERASER:
					_push_undo_snapshot()
					is_painting_lmb = true
					_stroke_modified = false
					if active_layer == EditLayer.GRASS:
						if active_shape != BrushPatterns.ShapeType.SINGLE:
							_apply_brush_at(hovered_cell, true)
						else:
							_freehand_points.clear()
							_freehand_points.append(Vector2(last_world_hit.x, last_world_hit.z))
							_refresh_hover_preview()
					else:
						_apply_brush_at(hovered_cell, true)
			elif not mb.pressed:
				if is_box_dragging:
					is_box_dragging = false
					_apply_box_fill(box_start_cell, hovered_cell)
					_refresh_hover_preview()
				if is_painting_lmb:
					is_painting_lmb = false
					if active_layer == EditLayer.GRASS:
						if active_shape == BrushPatterns.ShapeType.SINGLE:
							var is_erase: bool = (active_tool == ToolMode.ERASER)
							_apply_brush_at(hovered_cell, is_erase)
						_freehand_points.clear()
						_refresh_hover_preview()
					elif _stroke_modified:
						_rebuild_3d_world()
						_sync_all_ui()

		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed and not over_ui:
				is_erasing_rmb = true
				rmb_press_pos = mb.position
				rmb_dragged = false
			elif not mb.pressed and is_erasing_rmb:
				is_erasing_rmb = false
				# Se foi um clique direito rápido (sem arrastar a câmera), apaga na célula atual
				if not rmb_dragged and not over_ui and is_hover_in_bounds:
					_push_undo_snapshot()
					_stroke_modified = false
					# Se a célula clicada possui um objeto em object_grid (pedra ou flor), apaga o objeto!
					if object_grid.has(hovered_cell):
						object_grid.erase(hovered_cell)
						_stroke_modified = true
					if not _stroke_modified or active_layer != EditLayer.OBJECTS:
						if active_layer == EditLayer.GRASS:
							_freehand_points.clear()
							_freehand_points.append(Vector2(last_world_hit.x, last_world_hit.z))
						_apply_brush_at(hovered_cell, true)
						_freehand_points.clear()
					if _stroke_modified:
						_rebuild_3d_world()
						_sync_all_ui()

func _update_hovered_cell(screen_pos: Vector2) -> void:
	if editor_camera == null:
		return
	var ray_origin: Vector3 = editor_camera.project_ray_origin(screen_pos)
	var ray_dir: Vector3 = editor_camera.project_ray_normal(screen_pos)
	var ground_plane: Plane = Plane(Vector3.UP, 0.0)
	var hit: Variant = ground_plane.intersects_ray(ray_origin, ray_dir)
	if hit == null:
		is_hover_in_bounds = false
		var empty_arr: Array[Vector2i] = []
		grid_overlay.update_brush_preview(empty_arr, Vector2i(-1, -1), current_rot_deg, Color.TRANSPARENT, Color.TRANSPARENT)
		return

	last_world_hit = hit as Vector3
	var cell: Vector2i = LevelJsonLoader.world_to_grid(last_world_hit, grid_width, grid_height, CELL_SIZE)
	hovered_cell = cell
	is_hover_in_bounds = (cell.x >= 0 and cell.x < grid_width and cell.y >= 0 and cell.y < grid_height)

	if ui != null:
		ui.update_status_bar(hovered_cell, is_hover_in_bounds, last_world_hit)
	_refresh_hover_preview()

func _compute_aabb_2d(poly: PackedVector2Array) -> Rect2:
	if poly.is_empty():
		return Rect2()
	var min_p: Vector2 = poly[0]
	var max_p: Vector2 = poly[0]
	for i: int in range(1, poly.size()):
		var p: Vector2 = poly[i]
		min_p.x = minf(min_p.x, p.x)
		min_p.y = minf(min_p.y, p.y)
		max_p.x = maxf(max_p.x, p.x)
		max_p.y = maxf(max_p.y, p.y)
	return Rect2(min_p, max_p - min_p)


func _get_safe_coastal_island_polygons() -> Array[PackedVector2Array]:
	var terrain_list: Array = []
	for cell_key: Variant in terrain_grid.keys():
		var cell: Vector2i = cell_key as Vector2i
		terrain_list.append({ "gx": cell.x, "gz": cell.y })
	if terrain_list.is_empty():
		return []

	var island_polys: Array[PackedVector2Array] = IslandMeshBuilder.convert_tile_grid_to_polygons(
		terrain_list, grid_width, grid_height, CELL_SIZE
	)
	var safe_polys: Array[PackedVector2Array] = []
	for p: PackedVector2Array in island_polys:
		if p.size() < 3:
			continue
		var inset_arr: Array[PackedVector2Array] = Geometry2D.offset_polygon(
			p, -COASTAL_GRASS_CORRIDOR, Geometry2D.JOIN_ROUND
		)
		for ip: PackedVector2Array in inset_arr:
			if ip.size() >= 3:
				safe_polys.append(ip)
	return safe_polys

func _refresh_hover_preview() -> void:
	if grid_overlay == null or is_playtesting:
		return
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var preview_cells: Array[Vector2i] = []
	if not is_hover_in_bounds or (ui != null and ui.is_mouse_over_ui(mouse_pos)):
		grid_overlay.update_brush_preview(preview_cells, Vector2i(-1, -1), current_rot_deg, Color.TRANSPARENT, Color.TRANSPARENT)
		grid_overlay.call("update_vector_preview", PackedVector2Array(), Color.TRANSPARENT, Color.TRANSPARENT)
		return

	var fill_col: Color = Color(0.2, 1.0, 0.55, 0.38)
	var line_col: Color = Color(0.4, 1.0, 0.75, 0.95)

	if active_layer == EditLayer.GRASS and active_tool != ToolMode.SPAWN:
		# Camada de Grama com preview holográfico vetorial
		fill_col = Color(0.25, 0.85, 1.0, 0.38)
		line_col = Color(0.55, 0.95, 1.0, 0.95)
		if active_tool == ToolMode.ERASER or is_erasing_rmb:
			fill_col = Color(1.0, 0.28, 0.28, 0.42)
			line_col = Color(1.0, 0.55, 0.55, 0.95)

		var hit_2d: Vector2 = Vector2(last_world_hit.x, last_world_hit.z)
		var preview_poly: PackedVector2Array = PackedVector2Array()

		if active_shape != BrushPatterns.ShapeType.SINGLE:
			preview_poly = BrushPatterns.get_vector_stamp_polygon(active_shape, brush_size, hit_2d, float(current_rot_deg), current_corner_radius)
		elif is_painting_lmb and _freehand_points.size() >= 2:
			var ribbon_w: float = float(brush_size) * 0.18 + 0.12
			preview_poly = BrushPatterns.create_ribbon_polygon(_freehand_points, ribbon_w)
		else:
			preview_poly = BrushPatterns.get_vector_stamp_polygon(BrushPatterns.ShapeType.CIRCLE, brush_size, hit_2d, float(current_rot_deg), current_corner_radius)

		# Recorta o preview ao corredor costeiro seguro
		if preview_poly.size() >= 3 and not (active_tool == ToolMode.ERASER or is_erasing_rmb):
			var safe_polys: Array[PackedVector2Array] = _get_safe_coastal_island_polygons()
			if not safe_polys.is_empty():
				var clipped_prev: Array[PackedVector2Array] = []
				for sp: PackedVector2Array in safe_polys:
					clipped_prev.append_array(Geometry2D.intersect_polygons(preview_poly, sp))
				if not clipped_prev.is_empty():
					preview_poly = clipped_prev[0]
				else:
					preview_poly.clear()

		grid_overlay.update_brush_preview(preview_cells, Vector2i(-1, -1), current_rot_deg, Color.TRANSPARENT, Color.TRANSPARENT)
		grid_overlay.call("update_vector_preview", preview_poly, line_col, fill_col)
		return

	# Camada de Terreno ou Objetos (em blocos refinados de 0.40m)
	grid_overlay.call("update_vector_preview", PackedVector2Array(), Color.TRANSPARENT, Color.TRANSPARENT)

	var clearance_r: float = 0.0
	if active_layer == EditLayer.OBJECTS and active_object_id == "rock" and active_tool != ToolMode.ERASER:
		clearance_r = ROCK_CLEARANCE_RADIUS

	if active_tool == ToolMode.BOX_FILL:
		fill_col = Color(1.0, 0.82, 0.2, 0.40)
		line_col = Color(1.0, 0.92, 0.4, 0.95)
		if is_box_dragging:
			preview_cells = BrushPatterns.get_box_cells(box_start_cell, hovered_cell)
		else:
			preview_cells.append(hovered_cell)
	elif active_tool == ToolMode.SPAWN:
		fill_col = Color(1.0, 0.88, 0.15, 0.50)
		line_col = Color(1.0, 0.95, 0.5, 1.0)
		preview_cells.append(hovered_cell)
	else:
		if active_tool == ToolMode.ERASER:
			fill_col = Color(1.0, 0.28, 0.28, 0.42)
			line_col = Color(1.0, 0.55, 0.55, 0.95)
		elif active_layer == EditLayer.OBJECTS:
			fill_col = Color(1.0, 0.65, 0.25, 0.40)
			line_col = Color(1.0, 0.80, 0.45, 0.95)
		elif active_layer == EditLayer.TERRAIN:
			fill_col = Color(0.2, 1.0, 0.55, 0.38)
			line_col = Color(0.4, 1.0, 0.75, 0.95)

		var offsets: Array[Vector2i] = BrushPatterns.get_brush_offsets(active_shape, brush_size)
		for off in offsets:
			var target_c: Vector2i = hovered_cell + off
			if target_c.x >= 0 and target_c.x < grid_width and target_c.y >= 0 and target_c.y < grid_height:
				preview_cells.append(target_c)

	grid_overlay.update_brush_preview(preview_cells, hovered_cell, current_rot_deg, fill_col, line_col, clearance_r)

func _apply_brush_at(center: Vector2i, erase_mode: bool) -> void:
	if not is_hover_in_bounds:
		return

	if active_layer == EditLayer.GRASS and active_tool != ToolMode.SPAWN:
		if vector_grass == null:
			return

		var hit_2d: Vector2 = Vector2(last_world_hit.x, last_world_hit.z)
		var poly: PackedVector2Array = PackedVector2Array()

		if active_shape != BrushPatterns.ShapeType.SINGLE:
			poly = BrushPatterns.get_vector_stamp_polygon(active_shape, brush_size, hit_2d, float(current_rot_deg), current_corner_radius)
		elif _freehand_points.size() >= 2:
			var ribbon_w: float = float(brush_size) * 0.18 + 0.12
			poly = BrushPatterns.create_ribbon_polygon(_freehand_points, ribbon_w)
		else:
			poly = BrushPatterns.get_vector_stamp_polygon(BrushPatterns.ShapeType.CIRCLE, brush_size, hit_2d, float(current_rot_deg), current_corner_radius)

		if poly.size() < 3:
			return

		if erase_mode:
			vector_grass.call("clip_shapes", poly)
			if object_grid.has(center):
				object_grid.erase(center)
		else:
			# Garante corredor costeiro afastado da borda da ilha ao colocar grama
			var safe_polys: Array[PackedVector2Array] = _get_safe_coastal_island_polygons()
			var polys_to_add: Array[PackedVector2Array] = []
			if not safe_polys.is_empty():
				for sp: PackedVector2Array in safe_polys:
					polys_to_add.append_array(Geometry2D.intersect_polygons(poly, sp))
			else:
				polys_to_add.append(poly)

			for part: PackedVector2Array in polys_to_add:
				if part.size() < 3:
					continue
				vector_grass.call("merge_or_add_shape", active_grass_id, part)
				var aabb: Rect2 = _compute_aabb_2d(part)
				var min_gx: int = clampi(int(floori((aabb.position.x + float(grid_width) * CELL_SIZE * 0.5) / CELL_SIZE)), 0, grid_width - 1)
				var max_gx: int = clampi(int(ceili((aabb.end.x + float(grid_width) * CELL_SIZE * 0.5) / CELL_SIZE)), 0, grid_width - 1)
				var min_gz: int = clampi(int(floori((aabb.position.y + float(grid_height) * CELL_SIZE * 0.5) / CELL_SIZE)), 0, grid_height - 1)
				var max_gz: int = clampi(int(ceili((aabb.end.y + float(grid_height) * CELL_SIZE * 0.5) / CELL_SIZE)), 0, grid_height - 1)
				for gz: int in range(min_gz, max_gz + 1):
					for gx: int in range(min_gx, max_gx + 1):
						var bcell: Vector2i = Vector2i(gx, gz)
						if not terrain_grid.has(bcell):
							terrain_grid[bcell] = {
								"tile_id": "island_center",
								"rot": 0,
								"auto": true
							}

		_stroke_modified = true
		_rebuild_3d_world()
		_sync_all_ui()
		return

	# Camada de Terreno ou Objetos em blocos de 0.80m
	var offsets: Array[Vector2i] = BrushPatterns.get_brush_offsets(active_shape, brush_size)
	var changed_any: bool = false
	for off in offsets:
		var c: Vector2i = center + off
		if c.x < 0 or c.x >= grid_width or c.y < 0 or c.y >= grid_height:
			continue
		if _modify_single_cell(c, erase_mode):
			changed_any = true

	if changed_any:
		_stroke_modified = true
		_rebuild_3d_world()
		_sync_all_ui()

func _apply_box_fill(start_c: Vector2i, end_c: Vector2i) -> void:
	var cells: Array[Vector2i] = BrushPatterns.get_box_cells(start_c, end_c)
	var changed_any: bool = false
	for c in cells:
		if c.x < 0 or c.x >= grid_width or c.y < 0 or c.y >= grid_height:
			continue
		if _modify_single_cell(c, false):
			changed_any = true
	if changed_any:
		_rebuild_3d_world()
		_sync_all_ui()

func _modify_single_cell(cell: Vector2i, erase_mode: bool) -> bool:
	if active_layer == EditLayer.TERRAIN:
		if erase_mode:
			if not terrain_grid.has(cell):
				return false
			terrain_grid.erase(cell)
			# Regra de integridade costeira: remove objeto se o bloco de ilha virou mar
			if object_grid.has(cell):
				object_grid.erase(cell)
			# Também limpa o campo fino sob esse bloco
			if veg_field != null:
				for dz in range(4):
					for dx in range(4):
						veg_field.call("set_cell", cell.x * 4 + dx, cell.y * 4 + dz, 0)
			return true
		else:
			var is_auto: bool = (active_terrain_id == "auto_island")
			var t_id: String = "island_center" if is_auto else active_terrain_id
			if terrain_grid.has(cell):
				var cur: Dictionary = terrain_grid[cell] as Dictionary
				if bool(cur.get("auto", false)) == is_auto and String(cur.get("tile_id", "")) == t_id and int(cur.get("rot", 0)) == current_rot_deg:
					return false
			terrain_grid[cell] = {
				"tile_id": t_id,
				"rot": current_rot_deg,
				"auto": is_auto
			}
			return true
	elif active_layer == EditLayer.OBJECTS:
		if erase_mode:
			# Apaga qualquer objeto do tile (pedra ou flor)
			if not object_grid.has(cell):
				return false
			object_grid.erase(cell)
			return true
		else:
			# Se não havia bloco de ilha debaixo do objeto, cria automaticamente um bloco de ilha!
			if not terrain_grid.has(cell):
				terrain_grid[cell] = {
					"tile_id": "island_center",
					"rot": 0,
					"auto": true
				}
			# Não coloca pedra/flor em cima do spawn
			if cell == spawn_cell and active_object_id != "cutter_spawn":
				return false
			if active_object_id == "cutter_spawn":
				spawn_cell = cell
				spawn_rot = current_rot_deg
				if object_grid.has(cell):
					object_grid.erase(cell)
				return true

			# Se for flor ou trigo, impede colocação dentro do raio de 1.40m de qualquer rocha
			if active_object_id != "rock":
				var target_world: Vector3 = LevelJsonLoader.grid_to_world(cell.x, cell.y, grid_width, grid_height, CELL_SIZE)
				for o_c: Variant in object_grid.keys():
					var oc_pos: Vector2i = o_c as Vector2i
					var o_info: Dictionary = object_grid[oc_pos] as Dictionary
					if String(o_info.get("type", "")) == "rock":
						var r_world: Vector3 = LevelJsonLoader.grid_to_world(oc_pos.x, oc_pos.y, grid_width, grid_height, CELL_SIZE)
						var dist_xz: float = Vector2(target_world.x - r_world.x, target_world.z - r_world.z).length()
						if dist_xz <= ROCK_CLEARANCE_RADIUS:
							if ui != null:
								ui.show_toast("⚠️ Área protegida da rocha (raio %.1fm)" % ROCK_CLEARANCE_RADIUS, Color(1.0, 0.65, 0.2))
							return false

			var obj_rot: int = current_rot_deg
			if active_object_id.begins_with("flower") and active_adjust_mode == QuickAdjustMode.SCALE:
				obj_rot = 0

			if object_grid.has(cell):
				var cur_o: Dictionary = object_grid[cell] as Dictionary
				if String(cur_o.get("type", "")) == active_object_id and int(cur_o.get("rot", 0)) == obj_rot:
					return false
			object_grid[cell] = {
				"type": active_object_id,
				"rot": obj_rot
			}

			# Se for rocha, limpa grama e plantas no raio da maior serra (1.40m)
			if active_object_id == "rock":
				var r_pos: Vector3 = LevelJsonLoader.grid_to_world(cell.x, cell.y, grid_width, grid_height, CELL_SIZE)
				var rock_clear_poly: PackedVector2Array = BrushPatterns.get_circle_polygon(
					Vector2(r_pos.x, r_pos.z),
					ROCK_CLEARANCE_RADIUS
				)
				if vector_grass != null:
					vector_grass.call("clip_shapes", rock_clear_poly)

				# Remove qualquer planta existente dentro do raio da rocha
				var to_remove: Array[Vector2i] = []
				for o_key: Variant in object_grid.keys():
					var other_c: Vector2i = o_key as Vector2i
					if other_c == cell:
						continue
					var o_pos: Vector3 = LevelJsonLoader.grid_to_world(other_c.x, other_c.y, grid_width, grid_height, CELL_SIZE)
					var d_rock: float = Vector2(o_pos.x - r_pos.x, o_pos.z - r_pos.z).length()
					if d_rock <= ROCK_CLEARANCE_RADIUS:
						to_remove.append(other_c)
				for rc in to_remove:
					object_grid.erase(rc)

				if veg_field != null:
					for dz in range(4):
						for dx in range(4):
							veg_field.call("set_cell", cell.x * 4 + dx, cell.y * 4 + dz, 0)
			return true
	return false

func _place_spawn_at(cell: Vector2i) -> void:
	spawn_cell = cell
	spawn_rot = current_rot_deg
	# Garante que há chão de ilha debaixo do spawn e limpa eventual planta/rocha naquela célula
	if not terrain_grid.has(cell):
		terrain_grid[cell] = {
			"tile_id": "island_center",
			"rot": 0,
			"auto": true
		}
	if object_grid.has(cell):
		object_grid.erase(cell)
	_rebuild_3d_world()
	_sync_all_ui()
	ui.show_toast("🤖 Spawn posicionado em [%d, %d]" % [cell.x, cell.y], Color(1.0, 0.85, 0.2))

func _rebuild_3d_world() -> void:
	# 1. Aplica Auto-Tile inteligente na ilha
	IslandAutotiler.apply_autotile(terrain_grid)

	# 2. Limpa containers 3D imediatamente da árvore antes de liberar memória
	for c in island_tiles_container.get_children():
		island_tiles_container.remove_child(c)
		c.queue_free()
	for c in coastal_limits_body.get_children():
		coastal_limits_body.remove_child(c)
		c.queue_free()
	for c in plants_container.get_children():
		plants_container.remove_child(c)
		c.queue_free()
	for c in obstacles_container.get_children():
		obstacles_container.remove_child(c)
		c.queue_free()

	# 3. Constrói a malha procedural única da ilha (1 Draw Call sem frestas)
	var terrain_list: Array = []
	for cell_key: Variant in terrain_grid.keys():
		var cell: Vector2i = cell_key as Vector2i
		terrain_list.append({ "gx": cell.x, "gz": cell.y })

	var island_polys: Array[PackedVector2Array] = IslandMeshBuilder.convert_tile_grid_to_polygons(
		terrain_list, grid_width, grid_height, CELL_SIZE
	)
	var island_mesh: ArrayMesh = IslandMeshBuilder.build_island_mesh(island_polys)
	if island_mesh != null:
		var island_mi: MeshInstance3D = MeshInstance3D.new()
		island_mi.name = "IslandMesh"
		island_mi.mesh = island_mesh
		island_mi.material_override = IslandMeshBuilder.get_island_material()
		island_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		island_tiles_container.add_child(island_mi)

	# 4. Constrói barreiras invisíveis de contenção costeira (Layer 1) e fita de espuma contínua
	IslandMeshBuilder.build_coastal_colliders(coastal_limits_body, island_polys)

	var foam_mesh: ArrayMesh = IslandMeshBuilder.build_coastal_foam_mesh(island_polys)
	if foam_mesh != null and foam_mesh.get_surface_count() > 0:
		var foam_inst: MeshInstance3D = MeshInstance3D.new()
		foam_inst.name = "CoastalFoamRibbon"
		foam_inst.mesh = foam_mesh
		foam_inst.material_override = IslandMeshBuilder.get_foam_material()
		foam_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		coastal_limits_body.add_child(foam_inst)

	# 5. Instancia obstáculos (Rochas 3D) em obstacles_container
	for cell_key: Variant in object_grid.keys():
		var cell: Vector2i = cell_key as Vector2i
		var entry: Dictionary = object_grid[cell] as Dictionary
		var o_type: String = String(entry.get("type", ""))
		if o_type == "rock":
			var r_inst: Node3D = ROCK_SCENE.instantiate() as Node3D
			if r_inst != null:
				r_inst.position = LevelJsonLoader.grid_to_world(cell.x, cell.y, grid_width, grid_height, CELL_SIZE)
				r_inst.rotation_degrees.y = float(entry.get("rot", 0))
				obstacles_container.add_child(r_inst)
		elif o_type.begins_with("flower"):
			var f_scene: PackedScene = FLOWER_SCENE
			if o_type == "flower_rose":
				f_scene = FLOWER_ROSE_SCENE
			elif o_type == "flower_daisy":
				f_scene = FLOWER_DAISY_SCENE
			elif o_type == "flower_sunflower":
				f_scene = FLOWER_SUNFLOWER_SCENE
			elif o_type == "flower_bell":
				f_scene = FLOWER_BELL_SCENE
			elif o_type == "flower_corolla":
				f_scene = FLOWER_COROLLA_SCENE
			elif o_type == "flower_tulip":
				f_scene = FLOWER_TULIP_SCENE
			elif o_type == "flower_bed":
				f_scene = FLOWER_BED_SCENE
			var f_inst: Node3D = f_scene.instantiate() as Node3D
			if f_inst != null:
				if "randomize_rotation" in f_inst:
					f_inst.set("randomize_rotation", false)
				f_inst.position = LevelJsonLoader.grid_to_world(cell.x, cell.y, grid_width, grid_height, CELL_SIZE)
				f_inst.rotation_degrees.y = float(entry.get("rot", 0))
				var vm: Node3D = f_inst.get_node_or_null("VisualMesh") as Node3D
				if vm != null:
					vm.rotation.y = 0.0
					vm.scale = Vector3(0.68, 0.68, 0.68)
				obstacles_container.add_child(f_inst)
		elif o_type == "wheat":
			var w_inst: Node3D = WHEAT_SCENE.instantiate() as Node3D
			if w_inst != null:
				w_inst.position = LevelJsonLoader.grid_to_world(cell.x, cell.y, grid_width, grid_height, CELL_SIZE)
				w_inst.rotation_degrees.y = float(entry.get("rot", 0))
				obstacles_container.add_child(w_inst)

	# 6. Constrói a prancheta vetorial plana colorida (Modo Edição Instantâneo, <0.5ms)
	_build_editor_vector_ground()

	# 7. Posiciona indicador visual do Spawn
	if spawn_marker_visual != null:
		var sp_world: Vector3 = LevelJsonLoader.grid_to_world(spawn_cell.x, spawn_cell.y, grid_width, grid_height, CELL_SIZE)
		spawn_marker_visual.position = Vector3(sp_world.x, 0.02, sp_world.z)
		spawn_marker_visual.rotation_degrees.y = float(spawn_rot)


func _build_editor_vector_ground() -> void:
	for c: Node in plants_container.get_children():
		plants_container.remove_child(c)
		c.queue_free()

	_active_veg_grid = null

	if vector_grass == null or not vector_grass.has_method("to_dict_list"):
		return

	var vector_field_clone: RefCounted = VectorGrassFieldScript.new()
	vector_field_clone.call("from_dict_list", vector_grass.call("to_dict_list"))

	# Remove polígonos sob rochas e adiciona flores
	for cell_key: Variant in object_grid.keys():
		var cell: Vector2i = cell_key as Vector2i
		var entry: Dictionary = object_grid[cell] as Dictionary
		var o_type: String = String(entry.get("type", ""))
		if o_type == "rock":
			var r_world: Vector3 = LevelJsonLoader.grid_to_world(cell.x, cell.y, grid_width, grid_height, CELL_SIZE)
			var rock_clip_poly: PackedVector2Array = BrushPatterns.get_circle_polygon(
				Vector2(r_world.x, r_world.z),
				ROCK_CLEARANCE_RADIUS
			)
			vector_field_clone.call("clip_shapes", rock_clip_poly)
		# As flores são modelos 3D no obstacles_container, sem necessidade de carimbar polígono falso no piso
	var ground_meshes: Dictionary = vector_field_clone.call("generate_ground_meshes") as Dictionary
	var vt_idx: int = 0
	for vt_var: Variant in ground_meshes.keys():
		var vt: String = String(vt_var)
		var mesh_res: Mesh = ground_meshes[vt] as Mesh
		if mesh_res == null:
			continue
		var mi: MeshInstance3D = MeshInstance3D.new()
		mi.name = "EditorGroundMesh_%s" % vt
		mi.mesh = mesh_res
		mi.material_override = _get_editor_vector_material(vt)
		# Afastamento físico de 1 milésimo (0.001m) em Y para erradicar Z-fighting entre camadas
		mi.position.y = float(vt_idx) * 0.001
		mi.sorting_offset = float(vt_idx) * 0.001
		plants_container.add_child(mi)
		vt_idx += 1

func _push_undo_snapshot() -> void:
	var snap: Dictionary = {
		"width": grid_width,
		"height": grid_height,
		"spawn_cell": spawn_cell,
		"spawn_rot": spawn_rot,
		"terrain": terrain_grid.duplicate(true),
		"objects": object_grid.duplicate(true),
		"veg_field_data": veg_field.call("to_rows") if veg_field != null else [],
		"grass_vectors_data": vector_grass.call("to_dict_list") if vector_grass != null else []
	}
	_undo_stack.append(snap)
	if _undo_stack.size() > MAX_UNDO_STEPS:
		_undo_stack.pop_front()
	_redo_stack.clear()

func perform_undo() -> void:
	if _undo_stack.is_empty():
		ui.show_toast("Nada para desfazer", Color(0.6, 0.6, 0.6))
		return
	var current_snap: Dictionary = {
		"width": grid_width,
		"height": grid_height,
		"spawn_cell": spawn_cell,
		"spawn_rot": spawn_rot,
		"terrain": terrain_grid.duplicate(true),
		"objects": object_grid.duplicate(true),
		"veg_field_data": veg_field.call("to_rows") if veg_field != null else [],
		"grass_vectors_data": vector_grass.call("to_dict_list") if vector_grass != null else []
	}
	_redo_stack.append(current_snap)
	var prev: Dictionary = _undo_stack.pop_back()
	_restore_snapshot(prev)
	ui.show_toast("↩️ Ação desfeita", Color(0.5, 0.8, 1.0))

func perform_redo() -> void:
	if _redo_stack.is_empty():
		ui.show_toast("Nada para refazer", Color(0.6, 0.6, 0.6))
		return
	var current_snap: Dictionary = {
		"width": grid_width,
		"height": grid_height,
		"spawn_cell": spawn_cell,
		"spawn_rot": spawn_rot,
		"terrain": terrain_grid.duplicate(true),
		"objects": object_grid.duplicate(true),
		"veg_field_data": veg_field.call("to_rows") if veg_field != null else [],
		"grass_vectors_data": vector_grass.call("to_dict_list") if vector_grass != null else []
	}
	_undo_stack.append(current_snap)
	var next_s: Dictionary = _redo_stack.pop_back()
	_restore_snapshot(next_s)
	ui.show_toast("↪️ Ação refeita", Color(0.5, 0.8, 1.0))

func _restore_snapshot(snap: Dictionary) -> void:
	grid_width = int(snap["width"])
	grid_height = int(snap["height"])
	spawn_cell = snap["spawn_cell"] as Vector2i
	spawn_rot = int(snap["spawn_rot"])
	terrain_grid = (snap["terrain"] as Dictionary).duplicate(true)
	object_grid = (snap["objects"] as Dictionary).duplicate(true)
	if snap.has("grass_vectors_data"):
		vector_grass = VectorGrassFieldScript.new()
		vector_grass.call("from_dict_list", snap["grass_vectors_data"] as Array)
	elif snap.has("veg_field_data") and veg_field != null:
		veg_field.call("resize_blocks", grid_width, grid_height)
		veg_field.call("from_rows", snap["veg_field_data"] as Array)
		vector_grass = VectorGrassFieldScript.new()
		vector_grass.call("convert_from_legacy_field", veg_field, grid_width, grid_height, CELL_SIZE)
	grid_overlay.rebuild_grid(grid_width, grid_height, CELL_SIZE)
	_rebuild_3d_world()
	_sync_all_ui()

func _on_generate_base_island() -> void:
	_push_undo_snapshot()
	terrain_grid.clear()
	for gz in range(grid_height):
		for gx in range(grid_width):
			terrain_grid[Vector2i(gx, gz)] = {
				"tile_id": "island_center",
				"rot": 0,
				"auto": true
			}
	spawn_cell = Vector2i(int(float(grid_width) / 2.0), int(float(grid_height) / 2.0))
	_rebuild_3d_world()
	_sync_all_ui()
	ui.show_toast("🏝️ Ilha 3D base gerada com falésias e bordas!", Color(0.28, 0.88, 0.48))

func _on_clear_objects() -> void:
	_push_undo_snapshot()
	object_grid.clear()
	if vector_grass != null:
		vector_grass.call("clear")
	if veg_field != null:
		veg_field.call("clear")
	_rebuild_3d_world()
	_sync_all_ui()
	ui.show_toast("🌿 Plantas e rochas removidas", Color(0.95, 0.65, 0.25))

func _on_clear_all() -> void:
	_push_undo_snapshot()
	terrain_grid.clear()
	object_grid.clear()
	if vector_grass != null:
		vector_grass.call("clear")
	if veg_field != null:
		veg_field.call("clear")
	_rebuild_3d_world()
	_sync_all_ui()
	ui.show_toast("🌊 Mapa limpo (Oceano aberto)", Color(0.35, 0.78, 0.95))

func _on_convert_yellow_to_wheat() -> void:
	if vector_grass == null:
		return
	var count: int = int(vector_grass.call("convert_shapes_type", "grass_yellow", "wheat"))
	if count > 0:
		_push_undo_snapshot()
		_rebuild_3d_world()
		_sync_all_ui()
		ui.show_toast("🌾 %d forma(s) de Grama Amarela convertidas em Trigo!" % count, Color(1.0, 0.85, 0.3))
	else:
		ui.show_toast("ℹ️ Nenhuma forma de Grama Amarela no mapa para converter.", Color(0.6, 0.8, 1.0))

func _on_grid_resize_requested(new_w: int, new_h: int) -> void:
	_push_undo_snapshot()
	grid_width = clampi(new_w, 4, 36)
	grid_height = clampi(new_h, 4, 36)
	if veg_field != null:
		veg_field.call("resize_blocks", grid_width, grid_height)

	# Remove células fora dos novos limites
	for k in terrain_grid.keys():
		var c: Vector2i = k as Vector2i
		if c.x < 0 or c.x >= grid_width or c.y < 0 or c.y >= grid_height:
			terrain_grid.erase(c)
	for k in object_grid.keys():
		var c: Vector2i = k as Vector2i
		if c.x < 0 or c.x >= grid_width or c.y < 0 or c.y >= grid_height:
			object_grid.erase(c)

	spawn_cell.x = clampi(spawn_cell.x, 0, grid_width - 1)
	spawn_cell.y = clampi(spawn_cell.y, 0, grid_height - 1)

	grid_overlay.rebuild_grid(grid_width, grid_height, CELL_SIZE)
	_rebuild_3d_world()
	_sync_all_ui()
	ui.show_toast("📐 Grade ajustada para %dx%d" % [grid_width, grid_height], Color(0.4, 0.85, 1.0))

func _on_level_load_requested(lvl_id: int) -> void:
	_load_or_init_level(lvl_id)
	_sync_all_ui()

func _load_or_init_level(lvl_id: int) -> void:
	current_level_id = lvl_id
	_undo_stack.clear()
	_redo_stack.clear()

	var json_path: String = LevelSerializer.get_json_path(lvl_id)
	var data: Dictionary = LevelJsonLoader.load_json_file(json_path)

	if not data.is_empty():
		time_limit = float(data.get("time_limit", 90.0))
		var g_dict: Dictionary = data.get("grid", {}) as Dictionary
		var loaded_cell_size: float = float(g_dict.get("cell_size", 0.80))
		var orig_width: int = int(g_dict.get("width", 12))
		var orig_height: int = int(g_dict.get("height", 8))

		var is_legacy_080: bool = (loaded_cell_size > 0.50)
		if is_legacy_080:
			grid_width = orig_width * 2
			grid_height = orig_height * 2
		else:
			grid_width = orig_width
			grid_height = orig_height

		var sp_dict: Dictionary = data.get("spawn", {}) as Dictionary
		var orig_sp_gx: int = int(sp_dict.get("gx", int(float(orig_width) / 2.0)))
		var orig_sp_gz: int = int(sp_dict.get("gz", int(float(orig_height) / 2.0)))
		spawn_cell = Vector2i(orig_sp_gx * 2, orig_sp_gz * 2) if is_legacy_080 else Vector2i(orig_sp_gx, orig_sp_gz)
		spawn_rot = int(sp_dict.get("rot", 0))

		terrain_grid.clear()
		var t_arr: Array = data.get("terrain", []) as Array
		for item in t_arr:
			if item is Dictionary:
				var d: Dictionary = item as Dictionary
				var ogx: int = int(d.get("gx", 0))
				var ogz: int = int(d.get("gz", 0))
				var t_id: String = String(d.get("tile_id", "island_center"))
				var t_rot: int = int(d.get("rot", 0))
				var t_auto: bool = bool(d.get("auto", true))
				if is_legacy_080:
					for sub_z in range(2):
						for sub_x in range(2):
							var sc: Vector2i = Vector2i(ogx * 2 + sub_x, ogz * 2 + sub_z)
							terrain_grid[sc] = {
								"tile_id": t_id,
								"rot": t_rot,
								"auto": t_auto
							}
				else:
					terrain_grid[Vector2i(ogx, ogz)] = {
						"tile_id": t_id,
						"rot": t_rot,
						"auto": t_auto
					}

		object_grid.clear()
		var o_arr: Array = data.get("objects", []) as Array
		for item in o_arr:
			if item is Dictionary:
				var d: Dictionary = item as Dictionary
				var o_type: String = String(d.get("type", ""))
				# Só guarda em object_grid os objetos discretos de tile: rock, flower e wheat
				if o_type == "rock" or o_type.begins_with("flower") or o_type == "wheat":
					var ogx: int = int(d.get("gx", 0))
					var ogz: int = int(d.get("gz", 0))
					var c: Vector2i = Vector2i(ogx * 2, ogz * 2) if is_legacy_080 else Vector2i(ogx, ogz)
					object_grid[c] = {
						"type": o_type,
						"rot": int(d.get("rot", 0))
					}

		# Carrega campo de vegetação vetorial v3 ou converte de v2/v1
		vector_grass = VectorGrassFieldScript.new()
		if data.has("grass_vectors") and data["grass_vectors"] is Array:
			vector_grass.call("from_dict_list", data["grass_vectors"] as Array)
		else:
			if data.has("vegetation") and data["vegetation"] is Dictionary:
				var vdict: Dictionary = data["vegetation"] as Dictionary
				var rows_arr: Array = vdict.get("rows", []) as Array
				veg_field = VegetationFieldScript.new(grid_width, grid_height)
				veg_field.call("from_rows", rows_arr)
			else:
				veg_field = VegetationFieldScript.new(grid_width, grid_height)
				veg_field.call("from_legacy_objects", o_arr, grid_width, grid_height)
			vector_grass.call("convert_from_legacy_field", veg_field, grid_width, grid_height, CELL_SIZE)

		grid_overlay.rebuild_grid(grid_width, grid_height, CELL_SIZE)
		_rebuild_3d_world()
		if ui != null:
			ui.update_goals_summary(terrain_grid.size(), object_grid, veg_field, vector_grass)
		var saved_goals: Dictionary = data.get("goals", {}) as Dictionary
		if ui != null and ui.has_method("set_configured_goals"):
			ui.set_configured_goals(saved_goals)
		if ui != null:
			ui.show_toast("📂 Fase %02d carregada (%s)" % [lvl_id, json_path.get_file()], Color(0.35, 0.85, 1.0))
	else:
		# Se não existe JSON para este nível ainda, monta uma ilha padrão inicial
		_build_default_island_for_level(lvl_id)
		grid_overlay.rebuild_grid(grid_width, grid_height, CELL_SIZE)
		_rebuild_3d_world()
		if ui != null:
			ui.update_goals_summary(terrain_grid.size(), object_grid, veg_field, vector_grass)
		if ui != null and ui.has_method("set_configured_goals"):
			ui.set_configured_goals({})
		if ui != null:
			ui.show_toast("✨ Nova Fase %02d iniciada (Ilha 3D)" % lvl_id, Color(0.4, 0.95, 0.6))

func _build_default_island_for_level(lvl_id: int) -> void:
	grid_width = 24
	grid_height = 16
	time_limit = 90.0
	terrain_grid.clear()
	object_grid.clear()

	# Cria ilha 24x16 (0.40m) com margem costeira livre e grama no interior
	for gz in range(grid_height):
		for gx in range(grid_width):
			terrain_grid[Vector2i(gx, gz)] = {
				"tile_id": "island_center",
				"rot": 0,
				"auto": true
			}

	spawn_cell = Vector2i(12, 8)
	spawn_rot = 0

	vector_grass = VectorGrassFieldScript.new()
	var default_poly: PackedVector2Array = PackedVector2Array([
		Vector2(-3.6, -2.0),
		Vector2(3.6, -2.0),
		Vector2(3.6, 2.0),
		Vector2(-3.6, 2.0)
	])
	vector_grass.call("add_shape", "grass_green", default_poly)

	IslandAutotiler.apply_autotile(terrain_grid)

	if lvl_id == 1:
		LevelSerializer.save_level_json(
			1, "Fase 1 - Ilha Inicial", time_limit, grid_width, grid_height, spawn_cell, spawn_rot, terrain_grid, object_grid, veg_field, vector_grass, {}, CELL_SIZE
		)

func save_current_level_json() -> void:
	IslandAutotiler.apply_autotile(terrain_grid)
	var configured_goals: Dictionary = ui.get_configured_goals() if ui != null and ui.has_method("get_configured_goals") else {}
	var ok: bool = LevelSerializer.save_level_json(
		current_level_id,
		"Fase %02d" % current_level_id,
		time_limit,
		grid_width,
		grid_height,
		spawn_cell,
		spawn_rot,
		terrain_grid,
		object_grid,
		veg_field,
		vector_grass,
		configured_goals,
		CELL_SIZE
	)
	if ok:
		ui.show_toast("💾 Salvo em res://data/levels/level_%02d.json" % current_level_id, Color(0.25, 0.95, 0.5))
	else:
		ui.show_toast("❌ Erro ao salvar JSON da fase!", Color(0.95, 0.3, 0.3))

func bake_current_level_tscn() -> void:
	IslandAutotiler.apply_autotile(terrain_grid)
	var configured_goals: Dictionary = ui.get_configured_goals() if ui != null and ui.has_method("get_configured_goals") else {}
	var ok: bool = LevelSerializer.bake_to_tscn(
		current_level_id,
		time_limit,
		grid_width,
		grid_height,
		spawn_cell,
		spawn_rot,
		terrain_grid,
		object_grid,
		veg_field,
		vector_grass,
		configured_goals,
		CELL_SIZE
	)
	if ok:
		ui.show_toast("📦 Cena exportada: res://scenes/levels/level_%02d.tscn" % current_level_id, Color(0.7, 0.5, 1.0))
	else:
		ui.show_toast("❌ Falha ao exportar cena .tscn", Color(0.95, 0.3, 0.3))

func toggle_playtest() -> void:
	if is_playtesting:
		_stop_playtest()
	else:
		_start_playtest()

func _start_playtest() -> void:
	if terrain_grid.is_empty():
		ui.show_toast("⚠️ Crie pelo menos 1 bloco de ilha antes de testar!", Color(0.95, 0.65, 0.2))
		return

	is_playtesting = true
	is_painting_lmb = false
	is_box_dragging = false

	editor_camera.save_editor_view()
	grid_overlay.visible = false
	spawn_marker_visual.visible = false
	ui.set_playtest_mode(true)

	# 1. Limpa malhas vetoriais temporárias de edição
	for c: Node in plants_container.get_children():
		plants_container.remove_child(c)
		c.queue_free()

	# 2. Prepara dados e limpa obstáculos para instanciação do VegetationGrid oficial
	var veg_json: Dictionary = {
		"grid": { "width": grid_width, "height": grid_height, "cell_size": CELL_SIZE },
		"terrain": [],
		"objects": [],
		"grass_vectors": vector_grass.call("to_dict_list") if vector_grass != null else []
	}
	for cell_key: Variant in object_grid.keys():
		var cell: Vector2i = cell_key as Vector2i
		var entry: Dictionary = object_grid[cell] as Dictionary
		var o_type: String = String(entry.get("type", ""))
		if o_type == "rock" or o_type.begins_with("flower") or o_type == "wheat":
			veg_json["objects"].append({
				"gx": cell.x,
				"gz": cell.y,
				"type": o_type,
				"rot": int(entry.get("rot", 0))
			})

	for c: Node in obstacles_container.get_children():
		obstacles_container.remove_child(c)
		c.queue_free()

	var veg_grid_inst: Node3D = VegetationGridScript.new() as Node3D
	veg_grid_inst.name = "PlaytestVegGrid"
	plants_container.add_child(veg_grid_inst)
	_active_veg_grid = veg_grid_inst

	var configured_goals: Dictionary = ui.get_configured_goals() if ui != null and ui.has_method("get_configured_goals") else {}
	if not configured_goals.is_empty():
		veg_json["goals"] = configured_goals

	_last_editor_goals = veg_grid_inst.call("build_from_level_json", veg_json, obstacles_container, null) as Dictionary
	var child_water: Node = veg_grid_inst.get_node_or_null("WaterOcean")
	if child_water != null:
		child_water.queue_free()
	var child_limits: Node = veg_grid_inst.get_node_or_null("CoastalLimits")
	if child_limits != null:
		child_limits.queue_free()

	# Instancia o Cortador
	_playtest_cutter = CUTTER_SCENE.instantiate() as CharacterBody3D
	var sp_world: Vector3 = LevelJsonLoader.grid_to_world(spawn_cell.x, spawn_cell.y, grid_width, grid_height, CELL_SIZE)
	_playtest_cutter.position = Vector3(sp_world.x, 0.1, sp_world.z)
	if _playtest_cutter.has_method("reset_orientation_to_camera"):
		_playtest_cutter.reset_orientation_to_camera()
	add_child(_playtest_cutter)
	if _playtest_cutter.has_method("rebuild_obstacles_cache"):
		_playtest_cutter.call("rebuild_obstacles_cache")
	if _active_veg_grid != null:
		_playtest_cutter.set("vegetation_grid", _active_veg_grid)

	# Instancia o Joystick para suporte a mouse/touch e teclado WASD/Setas
	_playtest_joystick = JOYSTICK_SCENE.instantiate() as Control
	canvas_layer.add_child(_playtest_joystick)
	canvas_layer.move_child(_playtest_joystick, 0)
	if _playtest_joystick.has_signal("joystick_moved"):
		_playtest_joystick.connect("joystick_moved", Callable(_playtest_cutter, "set_input_direction"))

	var goals: Dictionary = {}
	if GameManager != null:
		if not configured_goals.is_empty():
			goals = configured_goals.duplicate()
		elif not _last_editor_goals.is_empty():
			goals = _last_editor_goals.duplicate()
		if goals.is_empty():
			goals = { "grass": 1 }

		GameManager.start_level(current_level_id, goals, time_limit)
		ui.update_playtest_hud(GameManager.time_left, GameManager.goals)

	if playtest_game_camera != null:
		editor_camera.current = false
		playtest_game_camera.current = true
		playtest_game_camera.set("target_path", playtest_game_camera.get_path_to(_playtest_cutter))
		playtest_game_camera.call("reset_cam")
	else:
		editor_camera.follow_target = _playtest_cutter
	ui.show_toast("🎮 Playtest Iniciado! Câmera Oficial Ativa", Color(0.35, 0.95, 0.5))

func _stop_playtest() -> void:
	is_playtesting = false

	if _playtest_joystick != null and is_instance_valid(_playtest_joystick):
		_playtest_joystick.queue_free()
		_playtest_joystick = null

	if _playtest_cutter != null and is_instance_valid(_playtest_cutter):
		_playtest_cutter.queue_free()
		_playtest_cutter = null

	if GameManager != null:
		GameManager.current_state = GameManager.GameState.READY

	_reset_grass_shader_interaction()

	# Reconstrói todos os tufos e elementos cortados durante o teste!
	_rebuild_3d_world()

	grid_overlay.visible = true
	spawn_marker_visual.visible = true
	if playtest_game_camera != null:
		playtest_game_camera.current = false
		playtest_game_camera.set("target", null)
	editor_camera.current = true
	editor_camera.restore_editor_view()
	ui.set_playtest_mode(false)
	_sync_all_ui()
	ui.show_toast("🛠️ De volta ao modo Edição (Ilha restaurada)", Color(0.45, 0.85, 1.0))

func _on_game_time_updated(t_left: float) -> void:
	if is_playtesting and GameManager != null:
		ui.update_playtest_hud(t_left, GameManager.goals)

func _on_game_goal_updated(_p_type: String, _rem: int, _target: int) -> void:
	if is_playtesting and GameManager != null:
		ui.update_playtest_hud(GameManager.time_left, GameManager.goals)

func _on_playtest_won(coins: int, _stars: int = 1) -> void:
	if is_playtesting:
		ui.show_toast("🏆 Fase Concluída no Teste! (+%d moedas) — Pressione [F1] ou [ESC]" % coins, Color(1.0, 0.85, 0.2))

func _on_playtest_lost(reason: String) -> void:
	if is_playtesting:
		ui.show_toast("⏱️ Fim do Teste: %s — Pressione [F1] ou [ESC]" % reason, Color(0.95, 0.35, 0.35))

func _on_exit_to_game() -> void:
	if is_playtesting:
		_stop_playtest()
	save_current_level_json()
	if GameManager != null:
		GameManager.current_level = current_level_id
	_restore_mobile_window()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
