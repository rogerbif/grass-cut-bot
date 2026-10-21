extends Node3D

const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")
const TilePaletteDB = preload("res://scripts/editor/tile_palette_db.gd")
const IslandAutotiler = preload("res://scripts/editor/island_autotiler.gd")
const BrushPatterns = preload("res://scripts/editor/brush_patterns.gd")
const LevelSerializer = preload("res://scripts/editor/level_serializer.gd")
const VegetationFieldScript = preload("res://scripts/level/vegetation_field.gd")
const VegetationGridScript = preload("res://scripts/plants/vegetation_grid.gd")

const CUTTER_SCENE: PackedScene = preload("res://scenes/cutter/cutter.tscn")
const JOYSTICK_SCENE: PackedScene = preload("res://scenes/ui/floating_joystick.tscn")
const MAX_UNDO_STEPS: int = 30
const CELL_SIZE: float = 0.80

enum EditLayer {
	TERRAIN = 0,
	OBJECTS = 1
}

enum ToolMode {
	BRUSH = 0,
	ERASER = 1,
	BOX_FILL = 2,
	SPAWN = 3
}

@onready var editor_camera: Camera3D = $EditorCamera
@onready var grid_overlay: Node3D = $GridOverlay
@onready var water_ocean: Node3D = $WaterOcean
@onready var island_tiles_container: Node3D = $IslandTilesContainer
@onready var coastal_limits_body: StaticBody3D = $CoastalLimitsBody
@onready var plants_container: Node3D = $PlantsContainer
@onready var obstacles_container: Node3D = $ObstaclesContainer
@onready var spawn_marker_visual: Node3D = $SpawnMarkerVisual
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var ui: Control = $CanvasLayer/LevelEditorUI

var current_level_id: int = 1
var grid_width: int = 12
var grid_height: int = 8
var time_limit: float = 90.0

var active_layer: int = EditLayer.TERRAIN
var active_tool: int = ToolMode.BRUSH
var active_shape: int = BrushPatterns.ShapeType.SINGLE
var brush_size: int = 1
var current_rot_deg: int = 0

var active_terrain_id: String = "auto_island"
var active_object_id: String = "grass_green"

# Matrizes de dados do nível em memória
# terrain_grid: Vector2i -> { "tile_id": String, "rot": int, "auto": bool }
var terrain_grid: Dictionary = {}
# object_grid: Vector2i -> { "type": String, "rot": int }
var object_grid: Dictionary = {}
var veg_field: RefCounted = null
var spawn_cell: Vector2i = Vector2i(6, 4)
var spawn_rot: int = 0

var hovered_cell: Vector2i = Vector2i(-1, -1)
var is_hover_in_bounds: bool = false
var last_world_hit: Vector3 = Vector3.ZERO

var is_painting_lmb: bool = false
var is_erasing_rmb: bool = false
var rmb_press_pos: Vector2 = Vector2.ZERO
var rmb_dragged: bool = false
var is_box_dragging: bool = false
var box_start_cell: Vector2i = Vector2i.ZERO
var _stroke_modified: bool = false

var _undo_stack: Array[Dictionary] = []
var _redo_stack: Array[Dictionary] = []

var is_playtesting: bool = false
var _playtest_cutter: CharacterBody3D = null
var _playtest_joystick: Control = null

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
	var mat_paths: Array[String] = [
		"res://shaders/interactive_grass_material.tres",
		"res://shaders/interactive_grass_yellow_material.tres",
		"res://shaders/interactive_grass_blue_material.tres",
		"res://shaders/interactive_grass_purple_material.tres",
		"res://shaders/interactive_grass_white_material.tres",
		"res://shaders/interactive_grass_red_material.tres",
		"res://shaders/interactive_grass_black_material.tres",
		"res://shaders/interactive_wheat_material.tres",
		"res://shaders/interactive_flower_material.tres"
	]
	for mp in mat_paths:
		if ResourceLoader.exists(mp):
			var mat: ShaderMaterial = load(mp) as ShaderMaterial
			if mat != null:
				mat.set_shader_parameter("cutter_pos", Vector3(0.0, -9999.0, 0.0))
				mat.set_shader_parameter("cutter_interact_radius", 0.0)

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
		brush_size = clampi(brush_size + delta_sz, 1, 4)
		_sync_all_ui()
		_refresh_hover_preview()
	)
	ui.rotate_requested.connect(_rotate_active_step)
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
	ui.object_item_selected.connect(func(o_id: String) -> void:
		if o_id == "cutter_spawn":
			active_tool = ToolMode.SPAWN
		else:
			active_object_id = o_id
			active_layer = EditLayer.OBJECTS
			if active_tool == ToolMode.SPAWN or active_tool == ToolMode.ERASER:
				active_tool = ToolMode.BRUSH
		_sync_all_ui()
		_refresh_hover_preview()
	)

func _rotate_active_step() -> void:
	current_rot_deg = (current_rot_deg + 90) % 360
	_sync_all_ui()
	_refresh_hover_preview()

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
		active_object_id,
		editor_camera.is_top_down if editor_camera != null else false
	)
	ui.update_level_header(current_level_id, grid_width, grid_height, time_limit)
	ui.update_goals_summary(terrain_grid.size(), object_grid)

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
					KEY_R:
						_rotate_active_step()
					KEY_V:
						editor_camera.toggle_top_down()
						_sync_all_ui()
					KEY_BRACKETLEFT:
						brush_size = clampi(brush_size - 1, 1, 4)
						_sync_all_ui()
						_refresh_hover_preview()
					KEY_BRACKETRIGHT:
						brush_size = clampi(brush_size + 1, 1, 4)
						_sync_all_ui()
						_refresh_hover_preview()

	if is_playtesting:
		return

	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var over_ui: bool = ui.is_mouse_over_ui(mouse_pos) if ui != null else false
	var text_focus: bool = ui.has_text_focus() if ui != null else false

	# Alt + Scroll ajusta tamanho do pincel
	if event is InputEventMouseButton and Input.is_key_pressed(KEY_ALT) and not over_ui:
		var mb_alt: InputEventMouseButton = event as InputEventMouseButton
		if mb_alt.pressed and mb_alt.button_index == MOUSE_BUTTON_WHEEL_UP:
			brush_size = clampi(brush_size + 1, 1, 4)
			_sync_all_ui()
			_refresh_hover_preview()
			return
		elif mb_alt.pressed and mb_alt.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			brush_size = clampi(brush_size - 1, 1, 4)
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
					_apply_brush_at(hovered_cell, false)
				elif active_tool == ToolMode.ERASER:
					_push_undo_snapshot()
					is_painting_lmb = true
					_stroke_modified = false
					_apply_brush_at(hovered_cell, true)
			elif not mb.pressed:
				if is_box_dragging:
					is_box_dragging = false
					_apply_box_fill(box_start_cell, hovered_cell)
					_refresh_hover_preview()
				if is_painting_lmb:
					is_painting_lmb = false
					if _stroke_modified:
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
					_apply_brush_at(hovered_cell, true)
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

func _refresh_hover_preview() -> void:
	if grid_overlay == null or is_playtesting:
		return
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var preview_cells: Array[Vector2i] = []
	if not is_hover_in_bounds or (ui != null and ui.is_mouse_over_ui(mouse_pos)):
		grid_overlay.update_brush_preview(preview_cells, Vector2i(-1, -1), current_rot_deg, Color.TRANSPARENT, Color.TRANSPARENT)
		grid_overlay.call("update_field_preview", preview_cells, Color.TRANSPARENT, Color.TRANSPARENT)
		return

	var fill_col: Color = Color(0.2, 1.0, 0.55, 0.38)
	var line_col: Color = Color(0.4, 1.0, 0.75, 0.95)

	if active_layer == EditLayer.OBJECTS and active_object_id != "rock" and active_tool != ToolMode.SPAWN:
		# Camada de Vegetação com preview fino de 0.20m
		fill_col = Color(0.25, 0.85, 1.0, 0.38)
		line_col = Color(0.55, 0.95, 1.0, 0.95)
		if active_tool == ToolMode.ERASER:
			fill_col = Color(1.0, 0.28, 0.28, 0.42)
			line_col = Color(1.0, 0.55, 0.55, 0.95)

		var field_cells: Array[Vector2i] = []
		if veg_field != null:
			var center_sub: Vector2i = veg_field.call("world_to_cell", last_world_hit, CELL_SIZE) as Vector2i
			var offsets: Array[Vector2i] = BrushPatterns.get_field_offsets(active_shape, brush_size)
			var cols: int = int(veg_field.get("cols"))
			var rows: int = int(veg_field.get("rows"))
			for off: Vector2i in offsets:
				var tc: Vector2i = center_sub + off
				if tc.x >= 0 and tc.x < cols and tc.y >= 0 and tc.y < rows:
					field_cells.append(tc)

		grid_overlay.update_brush_preview(preview_cells, Vector2i(-1, -1), current_rot_deg, Color.TRANSPARENT, Color.TRANSPARENT)
		grid_overlay.call("update_field_preview", field_cells, line_col, fill_col)
		return

	# Camada de Terreno, Rocha ou Spawn (em blocos de 0.80m)
	grid_overlay.call("update_field_preview", preview_cells, Color.TRANSPARENT, Color.TRANSPARENT)

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
			fill_col = Color(0.25, 0.85, 1.0, 0.38)
			line_col = Color(0.55, 0.95, 1.0, 0.95)

		var offsets: Array[Vector2i] = BrushPatterns.get_brush_offsets(active_shape, brush_size)
		for off in offsets:
			var target_c: Vector2i = hovered_cell + off
			if target_c.x >= 0 and target_c.x < grid_width and target_c.y >= 0 and target_c.y < grid_height:
				preview_cells.append(target_c)

	grid_overlay.update_brush_preview(preview_cells, hovered_cell, current_rot_deg, fill_col, line_col)

func _apply_brush_at(center: Vector2i, erase_mode: bool) -> void:
	if not is_hover_in_bounds:
		return

	if active_layer == EditLayer.OBJECTS and active_object_id != "rock" and active_tool != ToolMode.SPAWN:
		# Pinta vegetação no campo fino de 0.20m com formas analíticas suaves
		if veg_field == null:
			return
		var center_sub: Vector2i = veg_field.call("world_to_cell", last_world_hit, CELL_SIZE) as Vector2i
		var offsets: Array[Vector2i] = BrushPatterns.get_field_offsets(active_shape, brush_size)
		var tid: int = 0 if erase_mode else VegetationFieldScript.type_name_to_id(active_object_id)
		var cols: int = int(veg_field.get("cols"))
		var rows: int = int(veg_field.get("rows"))
		var changed: bool = false

		for off: Vector2i in offsets:
			var sc: Vector2i = center_sub + off
			if sc.x < 0 or sc.x >= cols or sc.y < 0 or sc.y >= rows:
				continue
			var cur_v: int = int(veg_field.call("get_cell", sc.x, sc.y))
			if cur_v != tid:
				veg_field.call("set_cell", sc.x, sc.y, tid)
				changed = true
				# Se não havia ilha debaixo da grama pintada, cria bloco de ilha
				if tid != 0:
					var bx: int = sc.x / 4
					var bz: int = sc.y / 4
					var bcell: Vector2i = Vector2i(bx, bz)
					if not terrain_grid.has(bcell):
						terrain_grid[bcell] = {
							"tile_id": "island_center",
							"rot": 0,
							"auto": true
						}

		if changed:
			_stroke_modified = true
			_rebuild_3d_world()
			_sync_all_ui()
		return

	# Camada de Terreno, Rocha ou Spawn em blocos de 0.80m
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
			# Regra de integridade costeira: remove planta/pedra se o bloco de ilha virou mar
			if object_grid.has(cell):
				object_grid.erase(cell)
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
	else:
		if erase_mode:
			if not object_grid.has(cell):
				return false
			object_grid.erase(cell)
			return true
		else:
			# Se não havia bloco de ilha debaixo da planta/pedra, cria automaticamente um bloco de ilha!
			if not terrain_grid.has(cell):
				terrain_grid[cell] = {
					"tile_id": "island_center",
					"rot": 0,
					"auto": true
				}
			# Não planta grama exatamente em cima do spawn do robô
			if cell == spawn_cell and active_object_id != "cutter_spawn":
				return false
			if object_grid.has(cell):
				var cur_o: Dictionary = object_grid[cell] as Dictionary
				if String(cur_o.get("type", "")) == active_object_id and int(cur_o.get("rot", 0)) == current_rot_deg:
					return false
			object_grid[cell] = {
				"type": active_object_id,
				"rot": current_rot_deg
			}
			return true

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

	# 2. Limpa containers 3D
	for c in island_tiles_container.get_children():
		c.queue_free()
	for c in coastal_limits_body.get_children():
		c.queue_free()
	for c in plants_container.get_children():
		c.queue_free()
	for c in obstacles_container.get_children():
		c.queue_free()

	# 3. Instancia blocos 3D da ilha
	for cell_key in terrain_grid.keys():
		var cell: Vector2i = cell_key as Vector2i
		var entry: Dictionary = terrain_grid[cell] as Dictionary
		var t_id: String = String(entry.get("tile_id", "island_center"))
		var t_rot: int = int(entry.get("rot", 0))
		var t_node: Node3D = LevelJsonLoader.instantiate_tile_node(t_id, t_rot)
		if t_node != null:
			t_node.position = LevelJsonLoader.grid_to_world(cell.x, cell.y, grid_width, grid_height, CELL_SIZE)
			island_tiles_container.add_child(t_node)

	# 4. Constrói barreiras invisíveis de contenção costeira (Layer 1) e espumas na água
	LevelJsonLoader.build_coastal_colliders_and_foam(coastal_limits_body, terrain_grid, grid_width, grid_height, CELL_SIZE)

	# 5. Instancia vegetação via VegetationGrid oficial (MultiMesh WYSIWYG) e rochas
	var veg_json: Dictionary = {
		"grid": { "width": grid_width, "height": grid_height, "cell_size": CELL_SIZE },
		"terrain": [],
		"objects": [],
		"vegetation": {
			"res": 0.20,
			"rows": veg_field.call("to_rows") if veg_field != null else []
		}
	}

	# Inclui rochas em objects
	for cell_key: Variant in object_grid.keys():
		var cell: Vector2i = cell_key as Vector2i
		var entry: Dictionary = object_grid[cell] as Dictionary
		if String(entry.get("type", "")) == "rock":
			veg_json["objects"].append({
				"gx": cell.x,
				"gz": cell.y,
				"type": "rock",
				"rot": int(entry.get("rot", 0))
			})

	var veg_grid_inst: Node3D = VegetationGridScript.new() as Node3D
	veg_grid_inst.name = "EditorVegGrid"
	plants_container.add_child(veg_grid_inst)
	# Desativa água e limites costeiros do grid filho para não duplicar os do editor
	veg_grid_inst.call("build_from_level_json", veg_json, obstacles_container, null)
	var child_water: Node = veg_grid_inst.get_node_or_null("WaterOcean")
	if child_water != null:
		child_water.queue_free()
	var child_limits: Node = veg_grid_inst.get_node_or_null("CoastalLimits")
	if child_limits != null:
		child_limits.queue_free()

	# 6. Posiciona indicador visual do Spawn
	if spawn_marker_visual != null:
		var sp_world: Vector3 = LevelJsonLoader.grid_to_world(spawn_cell.x, spawn_cell.y, grid_width, grid_height, CELL_SIZE)
		spawn_marker_visual.position = Vector3(sp_world.x, 0.02, sp_world.z)
		spawn_marker_visual.rotation_degrees.y = float(spawn_rot)

func _push_undo_snapshot() -> void:
	var snap: Dictionary = {
		"width": grid_width,
		"height": grid_height,
		"spawn_cell": spawn_cell,
		"spawn_rot": spawn_rot,
		"terrain": terrain_grid.duplicate(true),
		"objects": object_grid.duplicate(true),
		"veg_field_data": veg_field.call("to_rows") if veg_field != null else []
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
		"veg_field_data": veg_field.call("to_rows") if veg_field != null else []
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
		"veg_field_data": veg_field.call("to_rows") if veg_field != null else []
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
	if snap.has("veg_field_data") and veg_field != null:
		veg_field.call("resize_blocks", grid_width, grid_height)
		veg_field.call("from_rows", snap["veg_field_data"] as Array)
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
	if veg_field != null:
		veg_field.call("clear")
	_rebuild_3d_world()
	_sync_all_ui()
	ui.show_toast("🌿 Plantas e rochas removidas", Color(0.95, 0.65, 0.25))

func _on_clear_all() -> void:
	_push_undo_snapshot()
	terrain_grid.clear()
	object_grid.clear()
	if veg_field != null:
		veg_field.call("clear")
	_rebuild_3d_world()
	_sync_all_ui()
	ui.show_toast("🌊 Mapa limpo (Oceano aberto)", Color(0.35, 0.78, 0.95))

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
		grid_width = int(g_dict.get("width", 12))
		grid_height = int(g_dict.get("height", 8))

		var sp_dict: Dictionary = data.get("spawn", {}) as Dictionary
		spawn_cell = Vector2i(
			int(sp_dict.get("gx", int(float(grid_width) / 2.0))),
			int(sp_dict.get("gz", int(float(grid_height) / 2.0)))
		)
		spawn_rot = int(sp_dict.get("rot", 0))

		terrain_grid.clear()
		var t_arr: Array = data.get("terrain", []) as Array
		for item in t_arr:
			if item is Dictionary:
				var d: Dictionary = item as Dictionary
				var c: Vector2i = Vector2i(int(d.get("gx", 0)), int(d.get("gz", 0)))
				terrain_grid[c] = {
					"tile_id": String(d.get("tile_id", "island_center")),
					"rot": int(d.get("rot", 0)),
					"auto": bool(d.get("auto", true))
				}

		object_grid.clear()
		var o_arr: Array = data.get("objects", []) as Array
		for item in o_arr:
			if item is Dictionary:
				var d: Dictionary = item as Dictionary
				var c: Vector2i = Vector2i(int(d.get("gx", 0)), int(d.get("gz", 0)))
				object_grid[c] = {
					"type": String(d.get("type", "grass_green")),
					"rot": int(d.get("rot", 0))
				}

		# Carrega campo de vegetação v2 ou converte de objects v1
		if data.has("vegetation") and data["vegetation"] is Dictionary:
			var vdict: Dictionary = data["vegetation"] as Dictionary
			var rows_arr: Array = vdict.get("rows", []) as Array
			veg_field = VegetationFieldScript.new(grid_width, grid_height)
			veg_field.call("from_rows", rows_arr)
		else:
			veg_field = VegetationFieldScript.new(grid_width, grid_height)
			veg_field.call("from_legacy_objects", o_arr, grid_width, grid_height)

		grid_overlay.rebuild_grid(grid_width, grid_height, CELL_SIZE)
		_rebuild_3d_world()
		if ui != null:
			ui.show_toast("📂 Fase %02d carregada (%s)" % [lvl_id, json_path.get_file()], Color(0.35, 0.85, 1.0))
	else:
		# Se não existe JSON para este nível ainda, monta uma ilha padrão inicial
		_build_default_island_for_level(lvl_id)
		grid_overlay.rebuild_grid(grid_width, grid_height, CELL_SIZE)
		_rebuild_3d_world()
		if ui != null:
			ui.show_toast("✨ Nova Fase %02d iniciada (Ilha 3D)" % lvl_id, Color(0.4, 0.95, 0.6))

func _build_default_island_for_level(lvl_id: int) -> void:
	grid_width = 12
	grid_height = 8
	time_limit = 90.0
	terrain_grid.clear()
	object_grid.clear()

	# Cria ilha 12x8 com margem costeira livre e 56 tufos de grama no interior (10x6)
	for gz in range(grid_height):
		for gx in range(grid_width):
			terrain_grid[Vector2i(gx, gz)] = {
				"tile_id": "island_center",
				"rot": 0,
				"auto": true
			}

	spawn_cell = Vector2i(5, 3)
	spawn_rot = 0

	for gz in range(1, grid_height - 1):
		for gx in range(1, grid_width - 1):
			var wp: Vector3 = LevelJsonLoader.grid_to_world(gx, gz, grid_width, grid_height, CELL_SIZE)
			if wp.length() < 0.7:
				continue
			object_grid[Vector2i(gx, gz)] = {
				"type": "grass_green",
				"rot": 0
			}

	IslandAutotiler.apply_autotile(terrain_grid)

	if lvl_id == 1:
		LevelSerializer.save_level_json(
			1, "Fase 1 - Ilha Inicial", time_limit, grid_width, grid_height, spawn_cell, spawn_rot, terrain_grid, object_grid, veg_field
		)

func save_current_level_json() -> void:
	IslandAutotiler.apply_autotile(terrain_grid)
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
		veg_field
	)
	if ok:
		ui.show_toast("💾 Salvo em res://data/levels/level_%02d.json" % current_level_id, Color(0.25, 0.95, 0.5))
	else:
		ui.show_toast("❌ Erro ao salvar JSON da fase!", Color(0.95, 0.3, 0.3))

func bake_current_level_tscn() -> void:
	save_current_level_json()
	var ok: bool = LevelSerializer.bake_to_tscn(
		current_level_id,
		time_limit,
		grid_width,
		grid_height,
		spawn_cell,
		spawn_rot,
		terrain_grid,
		object_grid,
		veg_field
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

	# Calcula metas reais da ilha a partir do VegetationGrid
	var goals: Dictionary = {}
	var editor_vg: Node3D = plants_container.get_node_or_null("EditorVegGrid") as Node3D

	# Instancia o Cortador
	_playtest_cutter = CUTTER_SCENE.instantiate() as CharacterBody3D
	var sp_world: Vector3 = LevelJsonLoader.grid_to_world(spawn_cell.x, spawn_cell.y, grid_width, grid_height, CELL_SIZE)
	_playtest_cutter.position = Vector3(sp_world.x, 0.1, sp_world.z)
	add_child(_playtest_cutter)
	if editor_vg != null:
		_playtest_cutter.set("vegetation_grid", editor_vg)

	# Instancia o Joystick para suporte a mouse/touch e teclado WASD/Setas
	_playtest_joystick = JOYSTICK_SCENE.instantiate() as Control
	canvas_layer.add_child(_playtest_joystick)
	canvas_layer.move_child(_playtest_joystick, 0)
	if _playtest_joystick.has_signal("joystick_moved"):
		_playtest_joystick.connect("joystick_moved", Callable(_playtest_cutter, "set_input_direction"))

	if GameManager != null:
		# Define metas a partir do campo de vegetação
		if veg_field != null:
			var rows: int = int(veg_field.get("rows"))
			var cols: int = int(veg_field.get("cols"))
			var logical_subcells: Dictionary = {}
			for r: int in range(rows):
				for c: int in range(cols):
					var tid: int = int(veg_field.call("get_cell", c, r))
					if tid == 0:
						continue
					var lkey: Vector2i = Vector2i(c / 2, r / 2)
					if not logical_subcells.has(lkey):
						logical_subcells[lkey] = tid
					elif tid == 9 or (tid == 8 and logical_subcells[lkey] != 9):
						logical_subcells[lkey] = tid
			for lkey: Vector2i in logical_subcells.keys():
				var tid: int = int(logical_subcells[lkey])
				var p_key: String = "grass"
				if tid == 8:
					p_key = "wheat"
				elif tid == 9:
					p_key = "flower"
				goals[p_key] = int(goals.get(p_key, 0)) + 1

		if goals.is_empty():
			goals = { "grass": 1 }

		GameManager.start_level(current_level_id, goals, time_limit)
		ui.update_playtest_hud(GameManager.time_left, GameManager.goals)

	editor_camera.follow_target = _playtest_cutter
	ui.show_toast("🎮 Playtest Iniciado! Use WASD / Setas ou Mouse", Color(0.35, 0.95, 0.5))

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
