extends Node3D

const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")
const IslandMeshBuilder = preload("res://scripts/level/island_mesh_builder.gd")
const TilePaletteDB = preload("res://scripts/editor/tile_palette_db.gd")
const IslandAutotiler = preload("res://scripts/editor/island_autotiler.gd")
const BrushPatterns = preload("res://scripts/editor/brush_patterns.gd")
const LevelSerializer = preload("res://scripts/editor/level_serializer.gd")
const VegetationFieldScript = preload("res://scripts/level/vegetation_field.gd")
const VectorGrassFieldScript = preload("res://scripts/level/vector_grass_field.gd")
const VectorTerrainFieldScript = preload("res://scripts/level/vector_terrain_field.gd")
const VegetationGridScript = preload("res://scripts/plants/vegetation_grid.gd")
const ROCK_SCENE: PackedScene = preload("res://scenes/obstacles/rock.tscn")
const FLOWER_SCENE: PackedScene = preload("res://scenes/plants/flower_tuft.tscn")
const FLOWER_ROSE_SCENE: PackedScene = preload("res://scenes/plants/flower_rose.tscn")
const FLOWER_DAISY_SCENE: PackedScene = preload("res://scenes/plants/flower_daisy.tscn")
const FLOWER_SUNFLOWER_SCENE: PackedScene = preload("res://scenes/plants/flower_sunflower.tscn")
const FLOWER_TULIP_SCENE: PackedScene = preload("res://scenes/plants/flower_tulip.tscn")
const FLOWER_BED_SCENE: PackedScene = preload("res://scenes/plants/flower_bed.tscn")
const WHEAT_SCENE: PackedScene = preload("res://scenes/plants/wheat_tuft.tscn")

const CUTTER_SCENE_PATH: String = "res://scenes/cutter/cutter.tscn"
const JOYSTICK_SCENE_PATH: String = "res://scenes/ui/floating_joystick.tscn"
const MAX_UNDO_STEPS: int = 30
const CELL_SIZE: float = 0.40
const COASTAL_GRASS_CORRIDOR: float = 0.48
const ROCK_CLEARANCE_RADIUS: float = 0.90
const SPAWN_CLEARANCE_RADIUS: float = 1.40

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
	SPAWN = 3,
	FLOOD_FILL = 4
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

enum MirrorMode {
	NONE = 0,
	HORIZONTAL_X = 1,
	VERTICAL_Z = 2,
	QUAD_XZ = 3
}

var mirror_mode: int = MirrorMode.NONE

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
var vector_terrain: RefCounted = null
var snap_step: float = 0.50
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
var _last_vector_click_pos: Vector2 = Vector2.ZERO
var _has_last_vector_click: bool = false

var _undo_stack: Array[Dictionary] = []
var _redo_stack: Array[Dictionary] = []
var _last_editor_goals: Dictionary = {}
var is_dirty: bool = false
var layer_visible: Dictionary = { 0: true, 1: true, 2: true }
var preview_3d_grass: bool = false
var _cached_safe_coastal_polys: Array[PackedVector2Array] = []
var _coastal_cache_dirty: bool = true
var _autosave_timer: float = 0.0
const AUTOSAVE_INTERVAL_SEC: float = 45.0

var is_playtesting: bool = false
var _playtest_cutter: CharacterBody3D = null
var _playtest_joystick: Control = null
var _active_veg_grid: Node3D = null

func _ready() -> void:
	_setup_desktop_window()
	_reset_grass_shader_interaction()
	_build_spawn_marker_mesh()
	_connect_ui_signals()

	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null:
		gm.set("current_state", 0) # GameState.READY
		if gm.has_signal("time_updated"):
			gm.connect("time_updated", _on_game_time_updated)
		if gm.has_signal("goal_updated"):
			gm.connect("goal_updated", _on_game_goal_updated)
		if gm.has_signal("level_won"):
			gm.connect("level_won", _on_playtest_won)
		if gm.has_signal("level_lost"):
			gm.connect("level_lost", _on_playtest_lost)

	# Carrega Fase 1 (ou cria a Fase 1 canônica em formato de ilha se não existir JSON ainda)
	vector_terrain = VectorTerrainFieldScript.new()
	var start_lvl: int = int(gm.get("current_level")) if gm != null else 1
	_load_or_init_level(start_lvl)
	_sync_all_ui()
	if ui != null:
		if grid_overlay != null and grid_overlay.has_method("is_grid_visible"):
			ui.update_grid_button(bool(grid_overlay.call("is_grid_visible")))
		ui.update_snap_button(snap_step)

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
	ui.save_and_load_level_requested.connect(_on_save_and_load_level_requested)
	ui.grid_resize_requested.connect(_on_grid_resize_requested)
	ui.time_limit_changed.connect(func(new_t: float) -> void:
		if not is_equal_approx(time_limit, new_t):
			time_limit = new_t
			_mark_dirty(true)
	)
	ui.auto_calc_time_requested.connect(apply_auto_calculated_time)
	ui.layer_visibility_toggled.connect(toggle_layer_visibility)
	ui.toggle_3d_grass_preview_requested.connect(toggle_3d_grass_preview)
	ui.generate_base_island_requested.connect(_on_generate_base_island)
	ui.island_template_requested.connect(apply_island_template)
	ui.save_as_requested.connect(save_level_as)
	ui.clear_terrain_requested.connect(_on_clear_terrain)
	ui.toggle_grid_requested.connect(toggle_grid_visibility)
	ui.cycle_snap_requested.connect(cycle_snap_mode)
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
		_has_last_vector_click = false
		_sync_all_ui(false)
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
		if not is_equal_approx(current_corner_radius, r):
			current_corner_radius = r
			_mark_dirty(true)
			if vector_terrain != null:
				vector_terrain.call("set_corner_radius", r)
				_rebuild_3d_world()
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
	ui.toggle_mirror_mode_requested.connect(toggle_mirror_mode)
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

func _sync_all_ui(recalc_goals: bool = true) -> void:
	if ui == null:
		return
	_update_layers_transparency()
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
		active_adjust_mode,
		mirror_mode
	)
	ui.update_level_header(current_level_id, grid_width, grid_height, time_limit)
	if ui.has_method("update_dirty_indicator"):
		ui.call("update_dirty_indicator", is_dirty)
	if ui.has_method("update_layer_visibility_buttons"):
		ui.call("update_layer_visibility_buttons", layer_visible)
	if ui.has_method("update_3d_grass_button"):
		ui.call("update_3d_grass_button", preview_3d_grass)
	if recalc_goals:
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

			if not is_playtesting:
				if ke.ctrl_pressed and ke.keycode == KEY_S:
					if ke.shift_pressed and ui != null and ui.has_method("open_save_as_dialog"):
						ui.call("open_save_as_dialog", -1)
					else:
						save_current_level_json()
					get_viewport().set_input_as_handled()
					return
				if not ui.has_text_focus():
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
					KEY_5, KEY_K:
						active_tool = ToolMode.FLOOD_FILL
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
					KEY_X:
						toggle_mirror_mode()
					KEY_G:
						toggle_grid_visibility()
					KEY_TAB:
						if ui != null and ui.has_method("toggle_clean_screen_mode"):
							var is_clean: bool = bool(ui.call("toggle_clean_screen_mode"))
							ui.show_toast("🖥️ Modo Tela Limpa: %s [Tab]" % ("ON" if is_clean else "OFF"), Color(0.45, 0.90, 1.0))
						get_viewport().set_input_as_handled()
						return
					KEY_SHIFT:
						_refresh_hover_preview()
		elif not ke.echo and ke.keycode == KEY_SHIFT and not is_playtesting:
			_refresh_hover_preview()

	if is_playtesting:
		return

	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var over_ui: bool = ui.is_mouse_over_ui(mouse_pos) if ui != null else false
	var text_focus: bool = ui.has_text_focus() if ui != null else false

	# Ctrl + Scroll ou Alt + Scroll ajusta tamanho do pincel
	if event is InputEventMouseButton and (Input.is_key_pressed(KEY_ALT) or Input.is_key_pressed(KEY_CTRL)) and not over_ui:
		var mb_alt: InputEventMouseButton = event as InputEventMouseButton
		if mb_alt.pressed and mb_alt.button_index == MOUSE_BUTTON_WHEEL_UP:
			brush_size = clampi(brush_size + 1, 1, 20)
			_sync_all_ui(false)
			_refresh_hover_preview()
			return
		elif mb_alt.pressed and mb_alt.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			brush_size = clampi(brush_size - 1, 1, 20)
			_sync_all_ui(false)
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
			if active_layer == EditLayer.GRASS or active_layer == EditLayer.TERRAIN:
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
				if Input.is_key_pressed(KEY_ALT) and is_hover_in_bounds:
					_pick_at_cursor(hovered_cell, Vector2(last_world_hit.x, last_world_hit.z))
					return
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
				elif active_tool == ToolMode.FLOOD_FILL:
					if is_hover_in_bounds:
						_push_undo_snapshot()
						_apply_flood_fill_at(hovered_cell, Vector2(last_world_hit.x, last_world_hit.z), Input.is_key_pressed(KEY_SHIFT))
				elif active_tool == ToolMode.BRUSH or active_tool == ToolMode.ERASER:
					var is_erase_tool: bool = (active_tool == ToolMode.ERASER)
					var hit_2d: Vector2 = Vector2(last_world_hit.x, last_world_hit.z)
					if (active_layer == EditLayer.GRASS or active_layer == EditLayer.TERRAIN) and Input.is_key_pressed(KEY_SHIFT) and _has_last_vector_click:
						_push_undo_snapshot()
						_apply_straight_line_at(_last_vector_click_pos, hit_2d, is_erase_tool)
						_last_vector_click_pos = hit_2d
						_has_last_vector_click = true
						_refresh_hover_preview()
					else:
						_push_undo_snapshot()
						is_painting_lmb = true
						_stroke_modified = false
						if active_layer == EditLayer.GRASS or active_layer == EditLayer.TERRAIN:
							_last_vector_click_pos = hit_2d
							_has_last_vector_click = true
							if active_shape != BrushPatterns.ShapeType.SINGLE:
								_apply_brush_at(hovered_cell, is_erase_tool)
							else:
								_freehand_points.clear()
								_freehand_points.append(hit_2d)
								_refresh_hover_preview()
						else:
							_apply_brush_at(hovered_cell, is_erase_tool)
			elif not mb.pressed:
				if is_box_dragging:
					is_box_dragging = false
					_apply_box_fill(box_start_cell, hovered_cell)
					_refresh_hover_preview()
				if is_painting_lmb:
					is_painting_lmb = false
					if active_layer == EditLayer.GRASS or active_layer == EditLayer.TERRAIN:
						if active_shape == BrushPatterns.ShapeType.SINGLE:
							var is_erase: bool = (active_tool == ToolMode.ERASER)
							_apply_brush_at(hovered_cell, is_erase)
						_last_vector_click_pos = Vector2(last_world_hit.x, last_world_hit.z)
						_has_last_vector_click = true
						_freehand_points.clear()
						if preview_3d_grass and _stroke_modified:
							_rebuild_3d_world()
						_sync_all_ui(true)
						_refresh_hover_preview()
					elif _stroke_modified:
						_rebuild_3d_world()
						_sync_all_ui(true)

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
						if active_layer == EditLayer.GRASS or active_layer == EditLayer.TERRAIN:
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

	var raw_hit: Vector3 = hit as Vector3
	if snap_step > 0.001 or Input.is_key_pressed(KEY_CTRL):
		var eff_step: float = snap_step if snap_step > 0.001 else 0.50
		last_world_hit = Vector3(
			snappedf(raw_hit.x, eff_step),
			0.0,
			snappedf(raw_hit.z, eff_step)
		)
	else:
		last_world_hit = raw_hit
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
	if not _coastal_cache_dirty:
		return _cached_safe_coastal_polys

	var safe_polys: Array[PackedVector2Array] = []
	var island_polys: Array[PackedVector2Array] = []
	if vector_terrain != null and not vector_terrain.is_empty():
		island_polys = vector_terrain.get_outer_polygons()
	else:
		var terrain_list: Array = []
		for cell_key: Variant in terrain_grid.keys():
			var cell: Vector2i = cell_key as Vector2i
			terrain_list.append({ "gx": cell.x, "gz": cell.y })
		if terrain_list.is_empty():
			_cached_safe_coastal_polys = safe_polys
			_coastal_cache_dirty = false
			return safe_polys
		island_polys = IslandMeshBuilder.convert_tile_grid_to_polygons(
			terrain_list, grid_width, grid_height, CELL_SIZE
		)

	for p: PackedVector2Array in island_polys:
		if p.size() < 3:
			continue
		var p_cw: PackedVector2Array = p.duplicate()
		if not Geometry2D.is_polygon_clockwise(p_cw):
			p_cw.reverse()
		var inset_arr: Array[PackedVector2Array] = Geometry2D.offset_polygon(
			p_cw, -COASTAL_GRASS_CORRIDOR, Geometry2D.JOIN_ROUND
		)
		for ip: PackedVector2Array in inset_arr:
			if ip.size() >= 3:
				safe_polys.append(ip)
	_cached_safe_coastal_polys = safe_polys
	_coastal_cache_dirty = false
	return safe_polys

func _get_box_vector_polygon(start_c: Vector2i, end_c: Vector2i) -> PackedVector2Array:
	var min_gx: int = clampi(mini(start_c.x, end_c.x), 0, grid_width - 1)
	var max_gx: int = clampi(maxi(start_c.x, end_c.x), 0, grid_width - 1)
	var min_gz: int = clampi(mini(start_c.y, end_c.y), 0, grid_height - 1)
	var max_gz: int = clampi(maxi(start_c.y, end_c.y), 0, grid_height - 1)
	var p_min: Vector3 = LevelJsonLoader.grid_to_world(min_gx, min_gz, grid_width, grid_height, CELL_SIZE)
	var p_max: Vector3 = LevelJsonLoader.grid_to_world(max_gx, max_gz, grid_width, grid_height, CELL_SIZE)
	var half_c: float = CELL_SIZE * 0.5
	var x0: float = p_min.x - half_c
	var z0: float = p_min.z - half_c
	var x1: float = p_max.x + half_c
	var z1: float = p_max.z + half_c
	return PackedVector2Array([
		Vector2(x0, z0),
		Vector2(x1, z0),
		Vector2(x1, z1),
		Vector2(x0, z1)
	])

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
	var is_shift_straight: bool = (
		Input.is_key_pressed(KEY_SHIFT)
		and _has_last_vector_click
		and not is_painting_lmb
		and (active_tool == ToolMode.BRUSH or active_tool == ToolMode.ERASER)
	)

	if active_layer == EditLayer.TERRAIN and active_tool != ToolMode.SPAWN:
		# Camada de Terreno com preview holográfico vetorial
		fill_col = Color(0.28, 0.82, 0.48, 0.45)
		line_col = Color(0.55, 0.95, 0.65, 0.95)
		if active_tool == ToolMode.ERASER or is_erasing_rmb:
			fill_col = Color(0.25, 0.65, 0.95, 0.45)
			line_col = Color(0.40, 0.85, 1.0, 0.95)
		elif active_tool == ToolMode.BOX_FILL:
			fill_col = Color(1.0, 0.82, 0.2, 0.40)
			line_col = Color(1.0, 0.92, 0.4, 0.95)

		var hit_2d: Vector2 = Vector2(last_world_hit.x, last_world_hit.z)
		var preview_poly: PackedVector2Array = PackedVector2Array()

		if active_tool == ToolMode.BOX_FILL:
			var sc: Vector2i = box_start_cell if is_box_dragging else hovered_cell
			preview_poly = _get_box_vector_polygon(sc, hovered_cell)
		elif is_shift_straight:
			var bridge_w: float = float(brush_size) * 0.80
			preview_poly = BrushPatterns.create_ribbon_polygon([_last_vector_click_pos, hit_2d], bridge_w)
		elif active_shape != BrushPatterns.ShapeType.SINGLE:
			preview_poly = BrushPatterns.get_vector_stamp_polygon(active_shape, brush_size, hit_2d, float(current_rot_deg), current_corner_radius)
		elif is_painting_lmb and _freehand_points.size() >= 2:
			var ribbon_w: float = float(brush_size) * 0.18 + 0.12
			preview_poly = BrushPatterns.create_ribbon_polygon(_freehand_points, ribbon_w)
		else:
			preview_poly = BrushPatterns.get_vector_stamp_polygon(BrushPatterns.ShapeType.CIRCLE, brush_size, hit_2d, float(current_rot_deg), current_corner_radius)

		grid_overlay.update_brush_preview(preview_cells, Vector2i(-1, -1), current_rot_deg, Color.TRANSPARENT, Color.TRANSPARENT)
		grid_overlay.call("update_vector_preview", preview_poly, line_col, fill_col)
		return

	if active_layer == EditLayer.GRASS and active_tool != ToolMode.SPAWN:
		# Camada de Grama com preview holográfico vetorial
		fill_col = Color(0.25, 0.85, 1.0, 0.38)
		line_col = Color(0.55, 0.95, 1.0, 0.95)
		if active_tool == ToolMode.ERASER or is_erasing_rmb:
			fill_col = Color(1.0, 0.28, 0.28, 0.42)
			line_col = Color(1.0, 0.55, 0.55, 0.95)
		elif active_tool == ToolMode.BOX_FILL:
			fill_col = Color(1.0, 0.82, 0.2, 0.40)
			line_col = Color(1.0, 0.92, 0.4, 0.95)

		var hit_2d: Vector2 = Vector2(last_world_hit.x, last_world_hit.z)
		var preview_poly: PackedVector2Array = PackedVector2Array()

		if active_tool == ToolMode.BOX_FILL:
			var sc: Vector2i = box_start_cell if is_box_dragging else hovered_cell
			preview_poly = _get_box_vector_polygon(sc, hovered_cell)
		elif is_shift_straight:
			var bridge_w: float = float(brush_size) * 0.80
			preview_poly = BrushPatterns.create_ribbon_polygon([_last_vector_click_pos, hit_2d], bridge_w)
		elif active_shape != BrushPatterns.ShapeType.SINGLE:
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
	if active_layer == EditLayer.OBJECTS and active_object_id.begins_with("rock") and active_tool != ToolMode.ERASER:
		clearance_r = ROCK_CLEARANCE_RADIUS
	elif active_tool == ToolMode.SPAWN:
		clearance_r = SPAWN_CLEARANCE_RADIUS

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

		var mirror_info: Array[Dictionary] = _get_mirrored_cells(hovered_cell, current_rot_deg)
		var offsets: Array[Vector2i] = BrushPatterns.get_brush_offsets(active_shape, brush_size)
		for m_item in mirror_info:
			var m_center: Vector2i = m_item["cell"] as Vector2i
			for off in offsets:
				var target_c: Vector2i = m_center + off
				if target_c.x >= 0 and target_c.x < grid_width and target_c.y >= 0 and target_c.y < grid_height:
					if not preview_cells.has(target_c):
						preview_cells.append(target_c)

	grid_overlay.update_brush_preview(preview_cells, hovered_cell, current_rot_deg, fill_col, line_col, clearance_r)

func _apply_vector_polygon_to_active_layer(poly: PackedVector2Array, erase_mode: bool, recalc_goals: bool, center_cell: Vector2i = Vector2i(-1, -1)) -> void:
	if poly.size() < 3:
		return
	var all_polys: Array[PackedVector2Array] = _get_mirrored_polygons(poly)

	if active_layer == EditLayer.GRASS:
		if vector_grass == null:
			return
		var erased_object: bool = false
		for pi in range(all_polys.size()):
			var p_target: PackedVector2Array = all_polys[pi]
			if erase_mode:
				vector_grass.call("clip_shapes", p_target)
				if center_cell.x >= 0 and object_grid.has(center_cell):
					object_grid.erase(center_cell)
					erased_object = true
			else:
				var safe_polys: Array[PackedVector2Array] = _get_safe_coastal_island_polygons()
				var polys_to_add: Array[PackedVector2Array] = []
				if not safe_polys.is_empty():
					for sp: PackedVector2Array in safe_polys:
						polys_to_add.append_array(Geometry2D.intersect_polygons(p_target, sp))
				else:
					polys_to_add.append(p_target)

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
		if erased_object:
			_rebuild_objects_3d()
		_rebuild_grass_3d()
		_update_layers_transparency()
		_sync_all_ui(recalc_goals)
	elif active_layer == EditLayer.TERRAIN:
		if vector_terrain == null:
			return
		for pi in range(all_polys.size()):
			var p_target: PackedVector2Array = all_polys[pi]
			if erase_mode:
				vector_terrain.call("carve_water", p_target)
				if vector_grass != null:
					vector_grass.call("clip_shapes", p_target)
				var to_remove: Array = []
				for ok in object_grid.keys():
					var o_cell: Vector2i = ok as Vector2i
					var owp: Vector3 = LevelJsonLoader.grid_to_world(o_cell.x, o_cell.y, grid_width, grid_height, CELL_SIZE)
					if not vector_terrain.call("is_point_on_land", Vector2(owp.x, owp.z)):
						to_remove.append(ok)
				for ok in to_remove:
					object_grid.erase(ok)
			else:
				vector_terrain.call("add_land", p_target)
				var aabb: Rect2 = _compute_aabb_2d(p_target)
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
		_sync_all_ui(recalc_goals)

func _apply_straight_line_at(from_pt: Vector2, to_pt: Vector2, erase_mode: bool) -> void:
	if not is_hover_in_bounds:
		return
	var bridge_w: float = float(brush_size) * 0.80
	var poly: PackedVector2Array = BrushPatterns.create_ribbon_polygon([from_pt, to_pt], bridge_w)
	_apply_vector_polygon_to_active_layer(poly, erase_mode, true, hovered_cell)

func _apply_brush_at(center: Vector2i, erase_mode: bool) -> void:
	if not is_hover_in_bounds:
		return

	if (active_layer == EditLayer.GRASS or active_layer == EditLayer.TERRAIN) and active_tool != ToolMode.SPAWN:
		var hit_2d: Vector2 = Vector2(last_world_hit.x, last_world_hit.z)
		var poly: PackedVector2Array = PackedVector2Array()

		if active_shape != BrushPatterns.ShapeType.SINGLE:
			poly = BrushPatterns.get_vector_stamp_polygon(active_shape, brush_size, hit_2d, float(current_rot_deg), current_corner_radius)
		elif _freehand_points.size() >= 2:
			var ribbon_w: float = float(brush_size) * 0.18 + 0.12
			poly = BrushPatterns.create_ribbon_polygon(_freehand_points, ribbon_w)
		else:
			poly = BrushPatterns.get_vector_stamp_polygon(BrushPatterns.ShapeType.CIRCLE, brush_size, hit_2d, float(current_rot_deg), current_corner_radius)

		_apply_vector_polygon_to_active_layer(poly, erase_mode, not is_painting_lmb, center)
		return

	# Camada de Terreno ou Objetos em blocos de 0.80m
	var mirror_info: Array[Dictionary] = _get_mirrored_cells(center, current_rot_deg)
	var offsets: Array[Vector2i] = BrushPatterns.get_brush_offsets(active_shape, brush_size)
	var changed_any: bool = false
	for m_item in mirror_info:
		var m_center: Vector2i = m_item["cell"] as Vector2i
		var m_rot: int = int(m_item["rot"])
		for off in offsets:
			var c: Vector2i = m_center + off
			if c.x < 0 or c.x >= grid_width or c.y < 0 or c.y >= grid_height:
				continue
			if _modify_single_cell(c, erase_mode, m_rot):
				changed_any = true

	if changed_any:
		_stroke_modified = true
		if active_layer == EditLayer.OBJECTS:
			_rebuild_objects_3d()
			if active_object_id.begins_with("rock") or erase_mode:
				_rebuild_grass_3d()
			_update_layers_transparency()
		else:
			_rebuild_3d_world()
		_sync_all_ui(not is_painting_lmb)

func _apply_box_fill(start_c: Vector2i, end_c: Vector2i) -> void:
	if active_layer == EditLayer.TERRAIN or active_layer == EditLayer.GRASS:
		var box_poly: PackedVector2Array = _get_box_vector_polygon(start_c, end_c)
		var erase_box: bool = Input.is_key_pressed(KEY_SHIFT)
		_apply_vector_polygon_to_active_layer(box_poly, erase_box, true)
		return

	var cells: Array[Vector2i] = BrushPatterns.get_box_cells(start_c, end_c)
	var changed_any: bool = false
	for c in cells:
		if c.x < 0 or c.x >= grid_width or c.y < 0 or c.y >= grid_height:
			continue
		if _modify_single_cell(c, false):
			changed_any = true
	if changed_any:
		if active_layer == EditLayer.OBJECTS:
			_rebuild_objects_3d()
			if active_object_id.begins_with("rock"):
				_rebuild_grass_3d()
			_update_layers_transparency()
		else:
			_rebuild_3d_world()
		_sync_all_ui(true)

func _modify_single_cell(cell: Vector2i, erase_mode: bool, custom_rot: int = -1) -> bool:
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
			var cell_rot: int = custom_rot if custom_rot >= 0 else current_rot_deg
			if terrain_grid.has(cell):
				var cur: Dictionary = terrain_grid[cell] as Dictionary
				if bool(cur.get("auto", false)) == is_auto and String(cur.get("tile_id", "")) == t_id and int(cur.get("rot", 0)) == cell_rot:
					return false
			terrain_grid[cell] = {
				"tile_id": t_id,
				"rot": cell_rot,
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
			if not active_object_id.begins_with("rock"):
				var target_world: Vector3 = LevelJsonLoader.grid_to_world(cell.x, cell.y, grid_width, grid_height, CELL_SIZE)
				for o_c: Variant in object_grid.keys():
					var oc_pos: Vector2i = o_c as Vector2i
					var o_info: Dictionary = object_grid[oc_pos] as Dictionary
					if String(o_info.get("type", "")).begins_with("rock"):
						var r_world: Vector3 = LevelJsonLoader.grid_to_world(oc_pos.x, oc_pos.y, grid_width, grid_height, CELL_SIZE)
						var dist_xz: float = Vector2(target_world.x - r_world.x, target_world.z - r_world.z).length()
						if dist_xz <= ROCK_CLEARANCE_RADIUS:
							if ui != null:
								ui.show_toast("⚠️ Área protegida da rocha (raio %.1fm)" % ROCK_CLEARANCE_RADIUS, Color(1.0, 0.65, 0.2))
							return false

			var obj_rot: int = custom_rot if custom_rot >= 0 else current_rot_deg
			if active_object_id.begins_with("flower"):
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
			if active_object_id.begins_with("rock"):
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

## Alterna ciclicamente o modo de espelhamento (0: Desligado -> 1: Horizontal X -> 2: Vertical Z -> 3: Quádruplo XZ -> 0)
func toggle_mirror_mode() -> void:
	mirror_mode = (mirror_mode + 1) % 4
	_sync_all_ui()
	_refresh_hover_preview()
	if grid_overlay != null:
		grid_overlay.call("update_mirror_axis", mirror_mode)
	var names: Array[String] = ["Desligada", "Horizontal (Eixo X)", "Vertical (Eixo Z)", "Quádrupla (Eixos X e Z)"]
	if ui != null:
		ui.show_toast("🪞 Simetria: %s" % names[mirror_mode], Color(0.70, 0.55, 0.95))

## Retorna lista de dicionários com células e rotações espelhadas { "cell": Vector2i, "rot": int }
func _get_mirrored_cells(center_cell: Vector2i, base_rot: int = 0) -> Array[Dictionary]:
	var list: Array[Dictionary] = [{ "cell": center_cell, "rot": base_rot }]
	if mirror_mode == MirrorMode.NONE:
		return list

	var mx: int = (grid_width - 1) - center_cell.x
	var mz: int = (grid_height - 1) - center_cell.y
	var rot_x: int = (360 - base_rot) % 360
	var rot_z: int = (540 - base_rot) % 360
	var rot_xz: int = (base_rot + 180) % 360

	match mirror_mode:
		MirrorMode.HORIZONTAL_X:
			var cx: Vector2i = Vector2i(mx, center_cell.y)
			if cx != center_cell:
				list.append({ "cell": cx, "rot": rot_x })
		MirrorMode.VERTICAL_Z:
			var cz: Vector2i = Vector2i(center_cell.x, mz)
			if cz != center_cell:
				list.append({ "cell": cz, "rot": rot_z })
		MirrorMode.QUAD_XZ:
			var cx: Vector2i = Vector2i(mx, center_cell.y)
			var cz: Vector2i = Vector2i(center_cell.x, mz)
			var cxz: Vector2i = Vector2i(mx, mz)
			if cx != center_cell:
				list.append({ "cell": cx, "rot": rot_x })
			if cz != center_cell and cz != cx:
				list.append({ "cell": cz, "rot": rot_z })
			if cxz != center_cell and cxz != cx and cxz != cz:
				list.append({ "cell": cxz, "rot": rot_xz })
	return list

## Retorna lista de polígonos espelhados para grama vetorial analítica
func _get_mirrored_polygons(poly: PackedVector2Array) -> Array[PackedVector2Array]:
	var res: Array[PackedVector2Array] = [poly]
	if mirror_mode == MirrorMode.NONE or poly.size() < 3:
		return res

	if mirror_mode == MirrorMode.HORIZONTAL_X or mirror_mode == MirrorMode.QUAD_XZ:
		var poly_x: PackedVector2Array = PackedVector2Array()
		poly_x.resize(poly.size())
		for i in range(poly.size()):
			poly_x[i] = Vector2(-poly[i].x, poly[i].y)
		res.append(poly_x)

	if mirror_mode == MirrorMode.VERTICAL_Z or mirror_mode == MirrorMode.QUAD_XZ:
		var poly_z: PackedVector2Array = PackedVector2Array()
		poly_z.resize(poly.size())
		for i in range(poly.size()):
			poly_z[i] = Vector2(poly[i].x, -poly[i].y)
		res.append(poly_z)

	if mirror_mode == MirrorMode.QUAD_XZ:
		var poly_xz: PackedVector2Array = PackedVector2Array()
		poly_xz.resize(poly.size())
		for i in range(poly.size()):
			poly_xz[i] = Vector2(-poly[i].x, -poly[i].y)
		res.append(poly_xz)

	return res

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
	if vector_grass != null:
		var sp_pos: Vector3 = LevelJsonLoader.grid_to_world(cell.x, cell.y, grid_width, grid_height, CELL_SIZE)
		var sp_clear_poly: PackedVector2Array = BrushPatterns.get_circle_polygon(
			Vector2(sp_pos.x, sp_pos.z),
			SPAWN_CLEARANCE_RADIUS
		)
		vector_grass.call("clip_shapes", sp_clear_poly)
	_rebuild_3d_world()
	_sync_all_ui()
	ui.show_toast("🤖 Spawn posicionado em [%d, %d]" % [cell.x, cell.y], Color(1.0, 0.85, 0.2))

func _rebuild_3d_world() -> void:
	_rebuild_terrain_3d()
	_rebuild_objects_3d()
	_rebuild_grass_3d()
	_update_layers_transparency()

func _rebuild_terrain_3d() -> void:
	_coastal_cache_dirty = true
	IslandAutotiler.apply_autotile(terrain_grid)

	for c in island_tiles_container.get_children():
		island_tiles_container.remove_child(c)
		c.queue_free()
	for c in coastal_limits_body.get_children():
		coastal_limits_body.remove_child(c)
		c.queue_free()

	var island_polys: Array[PackedVector2Array] = []
	var island_holes: Array[PackedVector2Array] = []

	if vector_terrain != null and not vector_terrain.is_empty():
		island_polys = vector_terrain.get_outer_polygons()
		island_holes = vector_terrain.get_holes()
	else:
		var terrain_list: Array = []
		for cell_key: Variant in terrain_grid.keys():
			var cell: Vector2i = cell_key as Vector2i
			terrain_list.append({ "gx": cell.x, "gz": cell.y })
		island_polys = IslandMeshBuilder.convert_tile_grid_to_polygons(
			terrain_list, grid_width, grid_height, CELL_SIZE
		)

	var island_mesh: ArrayMesh = IslandMeshBuilder.build_island_mesh(island_polys, island_holes)
	if island_mesh != null:
		var island_mi: MeshInstance3D = MeshInstance3D.new()
		island_mi.name = "IslandMesh"
		island_mi.mesh = island_mesh
		island_mi.material_override = IslandMeshBuilder.get_island_material()
		island_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		island_tiles_container.add_child(island_mi)

	IslandMeshBuilder.build_coastal_colliders(coastal_limits_body, island_polys, island_holes)

	var foam_mesh: ArrayMesh = IslandMeshBuilder.build_coastal_foam_mesh(island_polys, island_holes)
	if foam_mesh != null and foam_mesh.get_surface_count() > 0:
		var foam_inst: MeshInstance3D = MeshInstance3D.new()
		foam_inst.name = "CoastalFoamRibbon"
		foam_inst.mesh = foam_mesh
		foam_inst.material_override = IslandMeshBuilder.get_foam_material()
		foam_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		coastal_limits_body.add_child(foam_inst)

func _rebuild_objects_3d() -> void:
	for c in obstacles_container.get_children():
		obstacles_container.remove_child(c)
		c.queue_free()

	for cell_key: Variant in object_grid.keys():
		var cell: Vector2i = cell_key as Vector2i
		var entry: Dictionary = object_grid[cell] as Dictionary
		var o_type: String = String(entry.get("type", ""))
		if o_type.begins_with("rock"):
			var scene_res: PackedScene = LevelJsonLoader.OBJECT_SCENES.get(o_type, ROCK_SCENE) as PackedScene
			var r_inst: Node3D = scene_res.instantiate() as Node3D
			if r_inst != null:
				r_inst.position = LevelJsonLoader.grid_to_world(cell.x, cell.y, grid_width, grid_height, CELL_SIZE)
				r_inst.rotation_degrees.y = float(entry.get("rot", 0))
				obstacles_container.add_child(r_inst)
		elif o_type.begins_with("flower"):
			var f_scene: PackedScene = FLOWER_SCENE
			if o_type.begins_with("flower_rose"):
				f_scene = FLOWER_ROSE_SCENE
			elif o_type.begins_with("flower_daisy"):
				f_scene = FLOWER_DAISY_SCENE
			elif o_type == "flower_sunflower":
				f_scene = FLOWER_SUNFLOWER_SCENE
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
				if VegetationGridScript.FLOWER_MATERIALS.has(o_type):
					f_inst.set("custom_material", VegetationGridScript.FLOWER_MATERIALS[o_type])
				if "plant_key" in f_inst:
					f_inst.set("plant_key", o_type)
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

	if spawn_marker_visual != null:
		var sp_world: Vector3 = LevelJsonLoader.grid_to_world(spawn_cell.x, spawn_cell.y, grid_width, grid_height, CELL_SIZE)
		spawn_marker_visual.position = Vector3(sp_world.x, 0.02, sp_world.z)
		spawn_marker_visual.rotation_degrees.y = float(spawn_rot)

func _rebuild_grass_3d() -> void:
	_build_editor_vector_ground()


func _build_editor_vector_ground() -> void:
	for c: Node in plants_container.get_children():
		plants_container.remove_child(c)
		c.queue_free()

	_active_veg_grid = null

	if vector_grass == null or not vector_grass.has_method("to_dict_list"):
		return

	var vector_field_clone: RefCounted = VectorGrassFieldScript.new()
	vector_field_clone.call("from_dict_list", vector_grass.call("to_dict_list"))

	# Remove polígonos sob rochas
	for cell_key: Variant in object_grid.keys():
		var cell: Vector2i = cell_key as Vector2i
		var entry: Dictionary = object_grid[cell] as Dictionary
		var o_type: String = String(entry.get("type", ""))
		if o_type.begins_with("rock"):
			var r_world: Vector3 = LevelJsonLoader.grid_to_world(cell.x, cell.y, grid_width, grid_height, CELL_SIZE)
			var rock_clip_poly: PackedVector2Array = BrushPatterns.get_circle_polygon(
				Vector2(r_world.x, r_world.z),
				ROCK_CLEARANCE_RADIUS
			)
			vector_field_clone.call("clip_shapes", rock_clip_poly)

	# Remove polígonos na clareira do spawn do bot (raio atual da pedra: 1.40m)
	var sp_world: Vector3 = LevelJsonLoader.grid_to_world(spawn_cell.x, spawn_cell.y, grid_width, grid_height, CELL_SIZE)
	var spawn_clip_poly: PackedVector2Array = BrushPatterns.get_circle_polygon(
		Vector2(sp_world.x, sp_world.z),
		SPAWN_CLEARANCE_RADIUS
	)
	vector_field_clone.call("clip_shapes", spawn_clip_poly)
	if preview_3d_grass and not is_painting_lmb:
		var veg_json_3d: Dictionary = {
			"grid": { "width": grid_width, "height": grid_height, "cell_size": CELL_SIZE },
			"terrain": [],
			"objects": [],
			"grass_vectors": vector_field_clone.call("to_dict_list")
		}
		var preview_vg: Node3D = VegetationGridScript.new() as Node3D
		preview_vg.name = "EditorPreviewVegGrid"
		plants_container.add_child(preview_vg)
		preview_vg.call("build_from_level_json", veg_json_3d, null, null)
		var cw: Node = preview_vg.get_node_or_null("WaterOcean")
		if cw != null:
			preview_vg.remove_child(cw)
			cw.queue_free()
		var cl: Node = preview_vg.get_node_or_null("CoastalLimits")
		if cl != null:
			preview_vg.remove_child(cl)
			cl.queue_free()
		_update_layers_transparency()
		return

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

	_update_layers_transparency()

func _update_layers_transparency() -> void:
	var terrain_t: float = 0.0
	var grass_t: float = 0.0
	var objects_t: float = 0.0
	var vis_terrain: bool = true
	var vis_grass: bool = true
	var vis_objects: bool = true

	if not is_playtesting:
		terrain_t = 0.0 if active_layer == EditLayer.TERRAIN else 0.5
		grass_t = 0.0 if active_layer == EditLayer.GRASS else 0.5
		objects_t = 0.0 if active_layer == EditLayer.OBJECTS else 0.5
		vis_terrain = bool(layer_visible.get(0, true))
		vis_grass = bool(layer_visible.get(1, true))
		vis_objects = bool(layer_visible.get(2, true))

	if island_tiles_container != null:
		island_tiles_container.visible = vis_terrain
		_set_container_transparency(island_tiles_container, terrain_t)
	if coastal_limits_body != null:
		coastal_limits_body.visible = vis_terrain
		_set_container_transparency(coastal_limits_body, terrain_t)
	if plants_container != null:
		plants_container.visible = vis_grass
		_set_container_transparency(plants_container, grass_t)
	if obstacles_container != null:
		obstacles_container.visible = vis_objects
		_set_container_transparency(obstacles_container, objects_t)

func _mark_dirty(dirty: bool = true) -> void:
	is_dirty = dirty
	if ui != null and ui.has_method("update_dirty_indicator"):
		ui.call("update_dirty_indicator", is_dirty)

func toggle_layer_visibility(layer_idx: int) -> void:
	var cur_vis: bool = bool(layer_visible.get(layer_idx, true))
	layer_visible[layer_idx] = not cur_vis
	_update_layers_transparency()
	if ui != null and ui.has_method("update_layer_visibility_buttons"):
		ui.call("update_layer_visibility_buttons", layer_visible)
	var l_names: Array[String] = ["Terreno", "Grama", "Objetos"]
	var l_name: String = l_names[clampi(layer_idx, 0, 2)]
	if ui != null:
		ui.show_toast("👁️ Camada %s: %s" % [l_name, "Visível" if not cur_vis else "Oculta"], Color(0.45, 0.88, 1.0))

func toggle_3d_grass_preview() -> void:
	preview_3d_grass = not preview_3d_grass
	_build_editor_vector_ground()
	if ui != null and ui.has_method("update_3d_grass_button"):
		ui.call("update_3d_grass_button", preview_3d_grass)
	if ui != null:
		ui.show_toast("🌿 Grama 3D no Editor: %s" % ("ATIVADA" if preview_3d_grass else "DESATIVADA (Modo Rápido)"), Color(0.35, 0.95, 0.55))

func _pick_at_cursor(cell: Vector2i, hit_2d: Vector2) -> bool:
	# Ordem visual Z (de cima para baixo no mundo 3D): Spawn -> Objetos (Flores/Rochas/Trigo) -> Grama Vetorial -> Terreno da Ilha
	var check_order: Array[int] = [EditLayer.OBJECTS, EditLayer.GRASS, EditLayer.TERRAIN]

	for layer_cand: int in check_order:
		if layer_cand == EditLayer.OBJECTS:
			if cell == spawn_cell:
				active_layer = EditLayer.OBJECTS
				active_tool = ToolMode.SPAWN
				current_rot_deg = spawn_rot
				_sync_all_ui(false)
				_refresh_hover_preview()
				if ui != null:
					ui.show_toast("💧 Pipeta: 🤖 Spawn do Robô (%d°)" % spawn_rot, Color(1.0, 0.88, 0.25))
				return true
			if object_grid.has(cell):
				var entry: Dictionary = object_grid[cell] as Dictionary
				var o_type: String = String(entry.get("type", "rock"))
				var o_rot: int = int(entry.get("rot", 0))
				active_layer = EditLayer.OBJECTS
				active_tool = ToolMode.BRUSH
				active_object_id = o_type
				current_rot_deg = o_rot
				_sync_all_ui(false)
				_refresh_hover_preview()
				var info_o: Dictionary = TilePaletteDB.get_item_by_id(o_type)
				var label_o: String = String(info_o.get("name", o_type))
				if ui != null:
					ui.show_toast("💧 Pipeta: %s" % label_o, Color(1.0, 0.78, 0.35))
				return true
		elif layer_cand == EditLayer.GRASS:
			if vector_grass != null and vector_grass.has_method("get_type_at_point"):
				var g_type: String = String(vector_grass.call("get_type_at_point", hit_2d))
				if not g_type.is_empty():
					active_layer = EditLayer.GRASS
					active_tool = ToolMode.BRUSH
					active_grass_id = g_type
					_sync_all_ui(false)
					_refresh_hover_preview()
					var info_g: Dictionary = TilePaletteDB.get_item_by_id(g_type)
					var label_g: String = String(info_g.get("name", g_type))
					if ui != null:
						ui.show_toast("💧 Pipeta: %s" % label_g, Color(0.35, 0.92, 1.0))
					return true
		elif layer_cand == EditLayer.TERRAIN:
			var on_land: bool = false
			if vector_terrain != null and vector_terrain.has_method("is_point_on_land"):
				on_land = bool(vector_terrain.call("is_point_on_land", hit_2d))
			elif terrain_grid.has(cell):
				on_land = true
			if on_land:
				active_layer = EditLayer.TERRAIN
				active_tool = ToolMode.BRUSH
				_sync_all_ui(false)
				_refresh_hover_preview()
				if ui != null:
					ui.show_toast("💧 Pipeta: 🏝️ Terreno da Ilha", Color(0.35, 0.92, 0.55))
				return true

	if ui != null:
		ui.show_toast("ℹ️ Pipeta: Nenhum elemento neste ponto", Color(0.65, 0.75, 0.85))
	return false

func calculate_recommended_time_limit() -> float:
	# Abordagem 3 Canônica:
	# Velocidade linear: 6 tiles/s; Diâmetro da serra: 1.80m (4.5 células de 0.40m).
	var land_cells: int = maxi(16, terrain_grid.size())
	if vector_terrain != null and not bool(vector_terrain.call("is_empty")):
		var sampled_land: int = 0
		for gz: int in range(grid_height):
			for gx: int in range(grid_width):
				var wp: Vector3 = LevelJsonLoader.grid_to_world(gx, gz, grid_width, grid_height, CELL_SIZE)
				if bool(vector_terrain.call("is_point_on_land", Vector2(wp.x, wp.z))):
					sampled_land += 1
		if sampled_land > 0:
			land_cells = sampled_land

	var rock_count: int = 0
	var extra_hit_seconds: float = 0.0
	for k_var: Variant in object_grid.keys():
		var e: Dictionary = object_grid[k_var] as Dictionary
		var ot: String = String(e.get("type", ""))
		if ot.begins_with("rock"):
			rock_count += 1
		elif ot.begins_with("flower"):
			extra_hit_seconds += 0.45
		elif ot == "wheat":
			extra_hit_seconds += 0.25

	var swath_cells: float = 4.5 # 1.80m / 0.40m
	var linear_tiles_path: float = float(land_cells) / swath_cells
	var base_sweep_sec: float = linear_tiles_path / 6.0
	var turn_factor: float = 1.40
	var rock_factor: float = 1.0 + minf(0.25, float(rock_count) / 100.0)
	var raw_sec: float = (base_sweep_sec * turn_factor * rock_factor + extra_hit_seconds) * 1.10
	var rounded_5: float = ceilf(raw_sec / 5.0) * 5.0
	return clampf(rounded_5, 20.0, 240.0)

func apply_auto_calculated_time() -> void:
	var rec_t: float = calculate_recommended_time_limit()
	time_limit = rec_t
	_mark_dirty(true)
	if ui != null:
		if ui.has_method("set_level_time_limit"):
			ui.set_level_time_limit(time_limit)
		ui.update_level_header(current_level_id, grid_width, grid_height, time_limit, true)
		ui.show_toast("⚡ Tempo ideal calculado: %.0fs (Abordagem 3 + 10%%)" % time_limit, Color(1.0, 0.85, 0.25))

static func _set_container_transparency(node: Node, alpha_transparency: float) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).transparency = alpha_transparency
	for child: Node in node.get_children():
		_set_container_transparency(child, alpha_transparency)

func _push_undo_snapshot() -> void:
	var snap: Dictionary = {
		"width": grid_width,
		"height": grid_height,
		"spawn_cell": spawn_cell,
		"spawn_rot": spawn_rot,
		"terrain": terrain_grid.duplicate(true),
		"objects": object_grid.duplicate(true),
		"veg_field_data": veg_field.call("to_rows") if veg_field != null else [],
		"grass_vectors_data": vector_grass.call("to_dict_list") if vector_grass != null else [],
		"vector_terrain_data": vector_terrain.call("to_dict") if vector_terrain != null else {}
	}
	_undo_stack.append(snap)
	if _undo_stack.size() > MAX_UNDO_STEPS:
		_undo_stack.pop_front()
	_redo_stack.clear()
	_mark_dirty(true)

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
		"grass_vectors_data": vector_grass.call("to_dict_list") if vector_grass != null else [],
		"vector_terrain_data": vector_terrain.call("to_dict") if vector_terrain != null else {}
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
		"grass_vectors_data": vector_grass.call("to_dict_list") if vector_grass != null else [],
		"vector_terrain_data": vector_terrain.call("to_dict") if vector_terrain != null else {}
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
	if snap.has("vector_terrain_data"):
		vector_terrain = VectorTerrainFieldScript.new()
		vector_terrain.call("from_dict", snap["vector_terrain_data"] as Dictionary)
		current_corner_radius = float(vector_terrain.call("get_corner_radius"))
		ui.set_corner_radius(current_corner_radius)
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
	apply_island_template("retangulo")

func _apply_flood_fill_at(cell: Vector2i, hit_2d: Vector2, replace_all: bool = false) -> void:
	if active_layer == EditLayer.TERRAIN:
		if vector_terrain != null and vector_terrain.has_method("fill_hole_at_point"):
			if bool(vector_terrain.call("fill_hole_at_point", hit_2d)):
				_rebuild_3d_world()
				_sync_all_ui()
				if ui != null:
					ui.show_toast("🪣 Lago / furo fechado com terra firme!", Color(0.28, 0.88, 0.48))
				return
		if vector_terrain == null or bool(vector_terrain.call("is_empty")):
			apply_island_template("retangulo")
		else:
			if ui != null:
				ui.show_toast("ℹ️ Clique dentro de um furo/lago para fechá-lo com o Balde.", Color(0.65, 0.85, 1.0))
		return

	elif active_layer == EditLayer.GRASS:
		if vector_grass == null:
			return
		# 1. Se clicou em cima de uma mancha de grama existente e não está segurando Shift, recolore essa mancha!
		if not replace_all and vector_grass.has_method("recolor_shape_at_point"):
			var existing_type: String = String(vector_grass.call("get_type_at_point", hit_2d))
			if not existing_type.is_empty():
				if existing_type == active_grass_id:
					if ui != null:
						ui.show_toast("ℹ️ Esta mancha já é do tipo %s (use Shift+Clique para preencher toda a ilha)." % active_grass_id, Color(0.65, 0.85, 1.0))
					return
				if bool(vector_grass.call("recolor_shape_at_point", hit_2d, active_grass_id)):
					_rebuild_grass_3d()
					_update_layers_transparency()
					_sync_all_ui()
					if ui != null:
						ui.show_toast("🪣 Mancha recolorida: %s -> %s" % [existing_type, active_grass_id], Color(0.35, 0.95, 0.65))
					return

		# 2. Caso contrário, preenche o solo livre da ilha respeitando corredor costeiro, lagos, rochas e spawn
		var safe_polys: Array[PackedVector2Array] = _get_safe_coastal_island_polygons()
		if safe_polys.is_empty():
			if ui != null:
				ui.show_toast("⚠️ Crie uma ilha na Camada 0 antes de usar o Balde de Grama!", Color(1.0, 0.75, 0.25))
			return

		# Recorta furos internos da ilha expandidos pelo corredor costeiro (0.48m)
		var working_polys: Array[PackedVector2Array] = safe_polys.duplicate()
		if vector_terrain != null and vector_terrain.has_method("get_holes"):
			var holes_arr: Array[PackedVector2Array] = vector_terrain.call("get_holes")
			for h: PackedVector2Array in holes_arr:
				if h.size() < 3:
					continue
				var h_cw: PackedVector2Array = h.duplicate()
				if not Geometry2D.is_polygon_clockwise(h_cw):
					h_cw.reverse()
				var expanded_holes: Array[PackedVector2Array] = Geometry2D.offset_polygon(
					h_cw, COASTAL_GRASS_CORRIDOR, Geometry2D.JOIN_ROUND
				)
				for eh: PackedVector2Array in expanded_holes:
					var next_polys: Array[PackedVector2Array] = []
					for wp: PackedVector2Array in working_polys:
						var clipped: Array[PackedVector2Array] = vector_grass.call("_clip_polygon_without_holes", wp, eh)
						for cp: PackedVector2Array in clipped:
							if cp.size() >= 3:
								next_polys.append(cp)
					working_polys = next_polys

		# Se não estiver em modo replace_all (Shift), preserva manchas existentes de outras cores
		var existing_other_polys: Array[PackedVector2Array] = []
		if not replace_all:
			var shapes_arr: Array = vector_grass.call("get_shapes") as Array
			for s_var: Variant in shapes_arr:
				var s_dict: Dictionary = s_var as Dictionary
				if String(s_dict.get("type", "")) != active_grass_id:
					var sp: PackedVector2Array = s_dict.get("polygon", PackedVector2Array()) as PackedVector2Array
					if sp.size() >= 3:
						existing_other_polys.append(sp.duplicate())
		else:
			vector_grass.call("clear")

		for wp: PackedVector2Array in working_polys:
			var pieces: Array[PackedVector2Array] = [wp]
			for other_p: PackedVector2Array in existing_other_polys:
				var next_pieces: Array[PackedVector2Array] = []
				for pc: PackedVector2Array in pieces:
					var clipped_pc: Array[PackedVector2Array] = vector_grass.call("_clip_polygon_without_holes", pc, other_p)
					for c_part: PackedVector2Array in clipped_pc:
						if c_part.size() >= 3:
							next_pieces.append(c_part)
				pieces = next_pieces
			for final_p: PackedVector2Array in pieces:
				if final_p.size() >= 3:
					vector_grass.call("merge_or_add_shape", active_grass_id, final_p)

		# Recorta clareiras de rochas e do spawn
		for c_key: Variant in object_grid.keys():
			var c_pos: Vector2i = c_key as Vector2i
			var entry: Dictionary = object_grid[c_pos] as Dictionary
			if String(entry.get("type", "")).begins_with("rock"):
				var r_world: Vector3 = LevelJsonLoader.grid_to_world(c_pos.x, c_pos.y, grid_width, grid_height, CELL_SIZE)
				var r_poly: PackedVector2Array = BrushPatterns.get_circle_polygon(Vector2(r_world.x, r_world.z), ROCK_CLEARANCE_RADIUS)
				vector_grass.call("clip_shapes", r_poly)
		var sp_world: Vector3 = LevelJsonLoader.grid_to_world(spawn_cell.x, spawn_cell.y, grid_width, grid_height, CELL_SIZE)
		var sp_poly: PackedVector2Array = BrushPatterns.get_circle_polygon(Vector2(sp_world.x, sp_world.z), SPAWN_CLEARANCE_RADIUS)
		vector_grass.call("clip_shapes", sp_poly)

		_rebuild_grass_3d()
		_update_layers_transparency()
		_sync_all_ui()
		if ui != null:
			ui.show_toast("🪣 Ilha preenchida com %s!" % active_grass_id, Color(0.35, 0.95, 0.65))
		return

	elif active_layer == EditLayer.OBJECTS:
		if not object_grid.has(cell):
			if ui != null:
				ui.show_toast("ℹ️ Na Camada de Objetos, clique com o Balde sobre uma flor/pedra para substituir todas do mesmo tipo.", Color(0.65, 0.85, 1.0))
			return
		var target_entry: Dictionary = object_grid[cell] as Dictionary
		var old_type: String = String(target_entry.get("type", ""))
		if old_type.is_empty() or old_type == active_object_id:
			return
		var replaced_count: int = 0
		for k_cell: Variant in object_grid.keys():
			var c_vec: Vector2i = k_cell as Vector2i
			var e_dict: Dictionary = object_grid[c_vec] as Dictionary
			if String(e_dict.get("type", "")) == old_type:
				e_dict["type"] = active_object_id
				object_grid[c_vec] = e_dict
				replaced_count += 1
		if replaced_count > 0:
			_rebuild_objects_3d()
			_update_layers_transparency()
			_sync_all_ui()
			if ui != null:
				ui.show_toast("🪣 %d objeto(s) '%s' substituídos por '%s'!" % [replaced_count, old_type, active_object_id], Color(0.35, 0.95, 0.65))

func apply_island_template(template_id: String) -> void:
	_push_undo_snapshot()
	terrain_grid.clear()
	if vector_terrain == null:
		vector_terrain = VectorTerrainFieldScript.new()
	vector_terrain.call("clear")

	var half_w: float = (float(grid_width) * CELL_SIZE) * 0.5 - 0.20
	var half_h: float = (float(grid_height) * CELL_SIZE) * 0.5 - 0.20
	var min_half: float = minf(half_w, half_h)

	match template_id:
		"atol":
			var outer_rect: PackedVector2Array = PackedVector2Array([
				Vector2(-half_w, -half_h),
				Vector2(half_w, -half_h),
				Vector2(half_w, half_h),
				Vector2(-half_w, half_h)
			])
			vector_terrain.call("add_land", outer_rect)
			var hole_r: float = maxf(1.2, min_half * 0.42)
			var inner_hole: PackedVector2Array = BrushPatterns.get_circle_polygon(Vector2.ZERO, hole_r, 24)
			vector_terrain.call("carve_water", inner_hole)
			# Posiciona o spawn na faixa sul do atol (terra firme garantida)
			var south_z: float = (half_h + hole_r) * 0.5
			spawn_cell = LevelJsonLoader.world_to_grid(Vector3(0.0, 0.0, south_z), grid_width, grid_height, CELL_SIZE)

		"gemeas":
			var lobe_w: float = half_w * 0.44
			var left_cx: float = -half_w + lobe_w
			var right_cx: float = half_w - lobe_w
			var left_rect: PackedVector2Array = PackedVector2Array([
				Vector2(left_cx - lobe_w, -half_h),
				Vector2(left_cx + lobe_w, -half_h),
				Vector2(left_cx + lobe_w, half_h),
				Vector2(left_cx - lobe_w, half_h)
			])
			var right_rect: PackedVector2Array = PackedVector2Array([
				Vector2(right_cx - lobe_w, -half_h),
				Vector2(right_cx + lobe_w, -half_h),
				Vector2(right_cx + lobe_w, half_h),
				Vector2(right_cx - lobe_w, half_h)
			])
			var bridge_half_h: float = maxf(1.2, half_h * 0.34)
			var bridge_rect: PackedVector2Array = PackedVector2Array([
				Vector2(left_cx, -bridge_half_h),
				Vector2(right_cx, -bridge_half_h),
				Vector2(right_cx, bridge_half_h),
				Vector2(left_cx, bridge_half_h)
			])
			vector_terrain.call("add_land", left_rect)
			vector_terrain.call("add_land", right_rect)
			vector_terrain.call("add_land", bridge_rect)
			spawn_cell = Vector2i(int(float(grid_width) / 2.0), int(float(grid_height) / 2.0))

		"cruz_4":
			var arm_w: float = maxf(1.6, min_half * 0.45)
			var horiz_bar: PackedVector2Array = PackedVector2Array([
				Vector2(-half_w, -arm_w),
				Vector2(half_w, -arm_w),
				Vector2(half_w, arm_w),
				Vector2(-half_w, arm_w)
			])
			var vert_bar: PackedVector2Array = PackedVector2Array([
				Vector2(-arm_w, -half_h),
				Vector2(arm_w, -half_h),
				Vector2(arm_w, half_h),
				Vector2(-arm_w, half_h)
			])
			vector_terrain.call("add_land", horiz_bar)
			vector_terrain.call("add_land", vert_bar)
			spawn_cell = Vector2i(int(float(grid_width) / 2.0), int(float(grid_height) / 2.0))

		"estrela":
			var star_poly: PackedVector2Array = PackedVector2Array()
			var points_count: int = 5
			var outer_r: float = min_half * 0.96
			var inner_r: float = min_half * 0.52
			for i in range(points_count * 2):
				var angle: float = -PI * 0.5 + float(i) * PI / float(points_count)
				var r: float = outer_r if (i % 2 == 0) else inner_r
				star_poly.append(Vector2(cos(angle) * r, sin(angle) * r))
			vector_terrain.call("add_land", star_poly)
			spawn_cell = Vector2i(int(float(grid_width) / 2.0), int(float(grid_height) / 2.0))

		"meia_lua":
			var base_rect: PackedVector2Array = PackedVector2Array([
				Vector2(-half_w, -half_h),
				Vector2(half_w, -half_h),
				Vector2(half_w, half_h),
				Vector2(-half_w, half_h)
			])
			vector_terrain.call("add_land", base_rect)
			var bay_r: float = min_half * 0.58
			var bay_poly: PackedVector2Array = BrushPatterns.get_circle_polygon(Vector2(0.0, -half_h * 0.65), bay_r, 24)
			vector_terrain.call("carve_water", bay_poly)
			var south_pos: Vector3 = Vector3(0.0, 0.0, half_h * 0.45)
			spawn_cell = LevelJsonLoader.world_to_grid(south_pos, grid_width, grid_height, CELL_SIZE)

		_: # "retangulo"
			var rect_poly: PackedVector2Array = PackedVector2Array([
				Vector2(-half_w, -half_h),
				Vector2(half_w, -half_h),
				Vector2(half_w, half_h),
				Vector2(-half_w, half_h)
			])
			vector_terrain.call("add_land", rect_poly)
			spawn_cell = Vector2i(int(float(grid_width) / 2.0), int(float(grid_height) / 2.0))

	vector_terrain.call("set_corner_radius", current_corner_radius)
	# Sincroniza células discretas aproximadas em terrain_grid para métricas e retrocompatibilidade
	for gz in range(grid_height):
		for gx in range(grid_width):
			var w_pos: Vector3 = LevelJsonLoader.grid_to_world(gx, gz, grid_width, grid_height, CELL_SIZE)
			if bool(vector_terrain.call("is_point_on_land", Vector2(w_pos.x, w_pos.z))):
				terrain_grid[Vector2i(gx, gz)] = {
					"tile_id": "island_center",
					"rot": 0,
					"auto": true
				}

	# Remove objetos que tenham ficado sobre a água após aplicar o novo formato de ilha
	var objs_to_remove: Array[Vector2i] = []
	for ok: Variant in object_grid.keys():
		var oc: Vector2i = ok as Vector2i
		var owp: Vector3 = LevelJsonLoader.grid_to_world(oc.x, oc.y, grid_width, grid_height, CELL_SIZE)
		if not bool(vector_terrain.call("is_point_on_land", Vector2(owp.x, owp.z))):
			objs_to_remove.append(oc)
	for rc: Vector2i in objs_to_remove:
		object_grid.erase(rc)

	_rebuild_3d_world()
	_sync_all_ui()
	if ui != null:
		ui.show_toast("🏝️ Template '%s' gerado com sucesso!" % template_id, Color(0.28, 0.88, 0.48))

func _process(delta: float) -> void:
	if is_playtesting:
		return
	if is_dirty:
		_autosave_timer += delta
		if _autosave_timer >= AUTOSAVE_INTERVAL_SEC:
			_autosave_timer = 0.0
			_perform_autosave()
	else:
		_autosave_timer = 0.0

func _perform_autosave() -> bool:
	var configured_goals: Dictionary = ui.get_configured_goals() if ui != null and ui.has_method("get_configured_goals") else {}
	return LevelSerializer.save_autosave_snapshot(
		current_level_id,
		time_limit,
		grid_width,
		grid_height,
		spawn_cell,
		spawn_rot,
		object_grid,
		vector_grass,
		configured_goals,
		CELL_SIZE,
		vector_terrain
	)

func validate_level_before_save() -> Array[String]:
	var warnings: Array[String] = []
	var sp_world: Vector3 = LevelJsonLoader.grid_to_world(spawn_cell.x, spawn_cell.y, grid_width, grid_height, CELL_SIZE)
	var sp_2d: Vector2 = Vector2(sp_world.x, sp_world.z)
	var spawn_on_land: bool = false
	if vector_terrain != null and not bool(vector_terrain.call("is_empty")):
		spawn_on_land = bool(vector_terrain.call("is_point_on_land", sp_2d))
	elif terrain_grid.has(spawn_cell):
		spawn_on_land = true

	if not spawn_on_land:
		warnings.append("⚠️ Spawn do Robô está sobre a água!")

	for k_var: Variant in object_grid.keys():
		var oc: Vector2i = k_var as Vector2i
		var entry: Dictionary = object_grid[oc] as Dictionary
		if String(entry.get("type", "")).begins_with("rock"):
			var rw: Vector3 = LevelJsonLoader.grid_to_world(oc.x, oc.y, grid_width, grid_height, CELL_SIZE)
			if Vector2(rw.x - sp_world.x, rw.z - sp_world.z).length() < 0.85:
				warnings.append("⚠️ Rocha colidindo com o Spawn do Robô!")
				break

	var configured_goals: Dictionary = ui.get_configured_goals() if ui != null and ui.has_method("get_configured_goals") else {}
	var has_any_plant: bool = false
	if vector_grass != null and not (vector_grass.call("get_shapes") as Array).is_empty():
		has_any_plant = true
	else:
		for k_var: Variant in object_grid.keys():
			var e_dict: Dictionary = object_grid[k_var] as Dictionary
			var ot: String = String(e_dict.get("type", ""))
			if ot.begins_with("flower") or ot == "wheat":
				has_any_plant = true
				break
	if configured_goals.is_empty() and not has_any_plant:
		warnings.append("⚠️ Fase sem nenhuma vegetação ou meta!")

	return warnings

func save_level_as(target_lvl_id: int) -> void:
	var clamped_id: int = clampi(target_lvl_id, 1, 200)
	current_level_id = clamped_id
	if ui != null and ui.has_method("get_configured_time_limit"):
		time_limit = ui.get_configured_time_limit()
	IslandAutotiler.apply_autotile(terrain_grid)
	var configured_goals: Dictionary = ui.get_configured_goals() if ui != null and ui.has_method("get_configured_goals") else {}
	var warnings: Array[String] = validate_level_before_save()
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
		CELL_SIZE,
		vector_terrain
	)
	if ok:
		_mark_dirty(false)
		_sync_all_ui(false)
		if ui != null:
			if not warnings.is_empty():
				ui.show_toast("📋 Salvo Fase %02d com aviso: %s" % [current_level_id, warnings[0]], Color(1.0, 0.80, 0.25))
			else:
				ui.show_toast("📋 Fase duplicada e salva como Fase %02d! (⏱️ %.0fs)" % [current_level_id, time_limit], Color(0.30, 0.90, 1.0))
	else:
		if ui != null:
			ui.show_toast("❌ Erro ao salvar cópia na Fase %02d!" % current_level_id, Color(0.95, 0.3, 0.3))

func _on_clear_terrain() -> void:
	_push_undo_snapshot()
	terrain_grid.clear()
	if vector_terrain != null:
		vector_terrain.call("clear")
	if vector_grass != null:
		vector_grass.call("clear")
	object_grid.clear()
	_rebuild_3d_world()
	_sync_all_ui()
	ui.show_toast("🌊 Terreno limpo (Oceano Aberto)", Color(0.40, 0.75, 1.0))

func toggle_grid_visibility() -> void:
	if grid_overlay != null and grid_overlay.has_method("toggle_grid_visibility"):
		var is_vis: bool = bool(grid_overlay.call("toggle_grid_visibility"))
		if ui != null and ui.has_method("update_grid_button"):
			ui.call("update_grid_button", is_vis)
		ui.show_toast("📐 Grade: " + ("Visível" if is_vis else "Oculta"), Color(0.4, 0.8, 1.0))

func cycle_snap_mode() -> void:
	if snap_step >= 0.99:
		snap_step = 0.0
	elif snap_step >= 0.49:
		snap_step = 1.0
	else:
		snap_step = 0.50
	if ui != null and ui.has_method("update_snap_button"):
		ui.call("update_snap_button", snap_step)
	var snap_msg: String = "Livre" if snap_step <= 0.001 else ("%.2fm" % snap_step)
	ui.show_toast("🧲 Magnetismo (Snap): " + snap_msg, Color(0.95, 0.80, 0.30))

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
	grid_width = clampi(new_w, 4, 100)
	grid_height = clampi(new_h, 4, 100)
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

func _on_save_and_load_level_requested(lvl_id: int) -> void:
	save_current_level_json()
	_load_or_init_level(lvl_id)
	_sync_all_ui()

func _on_level_load_requested(lvl_id: int) -> void:
	_load_or_init_level(lvl_id)
	_sync_all_ui()

func _load_or_init_level(lvl_id: int) -> void:
	current_level_id = lvl_id
	_has_last_vector_click = false
	_mark_dirty(false)
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

		vector_terrain = VectorTerrainFieldScript.new()
		if data.has("island_polygons") and not (data["island_polygons"] as Array).is_empty():
			vector_terrain.call("from_dict", data)
		else:
			vector_terrain.call("convert_from_tile_grid", t_arr, orig_width, orig_height, loaded_cell_size)
		current_corner_radius = float(vector_terrain.call("get_corner_radius"))
		ui.set_corner_radius(current_corner_radius)

		object_grid.clear()
		var o_arr: Array = data.get("objects", []) as Array
		for item in o_arr:
			if item is Dictionary:
				var d: Dictionary = item as Dictionary
				var o_type: String = String(d.get("type", ""))
				# Só guarda em object_grid os objetos discretos de tile: rock, flower e wheat
				if o_type.begins_with("rock") or o_type.begins_with("flower") or o_type == "wheat":
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
			if ui.has_method("set_level_time_limit"):
				ui.set_level_time_limit(time_limit)
			ui.update_level_header(current_level_id, grid_width, grid_height, time_limit, true)
			ui.update_goals_summary(terrain_grid.size(), object_grid, veg_field, vector_grass)
		var saved_goals: Dictionary = data.get("goals", {}) as Dictionary
		if ui != null and ui.has_method("set_configured_goals"):
			ui.set_configured_goals(saved_goals)
		if ui != null:
			ui.show_toast("📂 Fase %02d carregada (⏱️ %.0fs)" % [lvl_id, time_limit], Color(0.35, 0.85, 1.0))
	else:
		# Se não existe JSON para este nível ainda, monta uma ilha padrão inicial
		_build_default_island_for_level(lvl_id)
		grid_overlay.rebuild_grid(grid_width, grid_height, CELL_SIZE)
		_rebuild_3d_world()
		if ui != null:
			if ui.has_method("set_level_time_limit"):
				ui.set_level_time_limit(time_limit)
			ui.update_level_header(current_level_id, grid_width, grid_height, time_limit, true)
			ui.update_goals_summary(terrain_grid.size(), object_grid, veg_field, vector_grass)
		if ui != null and ui.has_method("set_configured_goals"):
			ui.set_configured_goals({})
		if ui != null:
			ui.show_toast("✨ Nova Fase %02d iniciada (⏱️ %.0fs)" % [lvl_id, time_limit], Color(0.4, 0.95, 0.6))

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

	vector_terrain = VectorTerrainFieldScript.new()
	var half_w: float = (float(grid_width) * CELL_SIZE) * 0.5 - 0.20
	var half_h: float = (float(grid_height) * CELL_SIZE) * 0.5 - 0.20
	var base_rect: PackedVector2Array = PackedVector2Array([
		Vector2(-half_w, -half_h),
		Vector2(half_w, -half_h),
		Vector2(half_w, half_h),
		Vector2(-half_w, half_h)
	])
	var rounded: PackedVector2Array = IslandMeshBuilder.round_polygon_corners(base_rect, 0.40, 5)
	vector_terrain.call("add_land", rounded)

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
			1, "Fase 1 - Ilha Inicial", time_limit, grid_width, grid_height, spawn_cell, spawn_rot, terrain_grid, object_grid, veg_field, vector_grass, {}, CELL_SIZE, vector_terrain
		)

func save_current_level_json() -> void:
	if ui != null and ui.has_method("get_configured_time_limit"):
		time_limit = ui.get_configured_time_limit()
	IslandAutotiler.apply_autotile(terrain_grid)
	var configured_goals: Dictionary = ui.get_configured_goals() if ui != null and ui.has_method("get_configured_goals") else {}
	var warnings: Array[String] = validate_level_before_save()
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
		CELL_SIZE,
		vector_terrain
	)
	if ok:
		_mark_dirty(false)
		if ui != null:
			if not warnings.is_empty():
				ui.show_toast("💾 Salvo Fase %02d (%s)" % [current_level_id, warnings[0]], Color(1.0, 0.80, 0.25))
			else:
				ui.show_toast("💾 Fase %02d salva! (⏱️ %.0fs)" % [current_level_id, time_limit], Color(0.25, 0.95, 0.5))
	else:
		if ui != null:
			ui.show_toast("❌ Erro ao salvar JSON da fase!", Color(0.95, 0.3, 0.3))

func bake_current_level_tscn() -> void:
	if ui != null and ui.has_method("get_configured_time_limit"):
		time_limit = ui.get_configured_time_limit()
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
		CELL_SIZE,
		vector_terrain
	)
	if ok:
		ui.show_toast("📦 Cena exportada: Fase %02d (⏱️ %.0fs)" % [current_level_id, time_limit], Color(0.7, 0.5, 1.0))
	else:
		ui.show_toast("❌ Falha ao exportar cena .tscn", Color(0.95, 0.3, 0.3))

func toggle_playtest() -> void:
	if is_playtesting:
		_stop_playtest()
	else:
		_start_playtest()

func _start_playtest() -> void:
	var has_vector_land: bool = (vector_terrain != null and not bool(vector_terrain.call("is_empty")))
	if terrain_grid.is_empty() and not has_vector_land:
		ui.show_toast("⚠️ Crie pelo menos 1 bloco de ilha antes de testar!", Color(0.95, 0.65, 0.2))
		return

	_perform_autosave()

	if ui != null and ui.has_method("get_configured_time_limit"):
		time_limit = ui.get_configured_time_limit()

	is_playtesting = true
	is_painting_lmb = false
	is_box_dragging = false

	editor_camera.save_editor_view()
	grid_overlay.visible = false
	spawn_marker_visual.visible = false
	ui.set_playtest_mode(true)
	_update_layers_transparency()

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
		if o_type.begins_with("rock") or o_type.begins_with("flower") or o_type == "wheat":
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
	var cutter_scene: PackedScene = load(CUTTER_SCENE_PATH) as PackedScene
	_playtest_cutter = cutter_scene.instantiate() as CharacterBody3D
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
	var joystick_scene: PackedScene = load(JOYSTICK_SCENE_PATH) as PackedScene
	_playtest_joystick = joystick_scene.instantiate() as Control
	canvas_layer.add_child(_playtest_joystick)
	canvas_layer.move_child(_playtest_joystick, 0)
	if _playtest_joystick.has_signal("joystick_moved"):
		_playtest_joystick.connect("joystick_moved", Callable(_playtest_cutter, "set_input_direction"))

	var goals: Dictionary = {}
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null:
		if not configured_goals.is_empty():
			goals = configured_goals.duplicate()
		elif not _last_editor_goals.is_empty():
			goals = _last_editor_goals.duplicate()
		if goals.is_empty():
			goals = { "grass": 1 }

		gm.call("start_level", current_level_id, goals, time_limit)
		ui.update_playtest_hud(float(gm.get("time_left")), gm.get("goals") as Dictionary)

	if playtest_game_camera != null:
		editor_camera.current = false
		editor_camera.movement_enabled = false
		playtest_game_camera.set("target", _playtest_cutter)
		playtest_game_camera.set("target_path", playtest_game_camera.get_path_to(_playtest_cutter))
		playtest_game_camera.call("reset_cam")
		playtest_game_camera.make_current()
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

	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null:
		gm.set("current_state", 0) # GameState.READY

	_reset_grass_shader_interaction()

	# Reconstrói todos os tufos e elementos cortados durante o teste!
	_rebuild_3d_world()

	grid_overlay.visible = true
	spawn_marker_visual.visible = true
	if playtest_game_camera != null:
		playtest_game_camera.current = false
		playtest_game_camera.set("target", null)
	editor_camera.movement_enabled = true
	editor_camera.make_current()
	editor_camera.restore_editor_view()
	ui.set_playtest_mode(false)
	_sync_all_ui()
	ui.show_toast("🛠️ De volta ao modo Edição (Ilha restaurada)", Color(0.45, 0.85, 1.0))

func _on_game_time_updated(t_left: float) -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if is_playtesting and gm != null:
		ui.update_playtest_hud(t_left, gm.get("goals") as Dictionary)

func _on_game_goal_updated(_p_type: String, _rem: int, _target: int) -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if is_playtesting and gm != null:
		ui.update_playtest_hud(float(gm.get("time_left")), gm.get("goals") as Dictionary)

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
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null:
		gm.set("current_level", current_level_id)
	_restore_mobile_window()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
