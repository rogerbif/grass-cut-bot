extends Node3D

# Gerencia um SubViewport leve (256x256) que pinta a trilha contínua da serra
# gerando uma máscara suave (canal R) para o decal de solo orgânico.

var viewport: SubViewport
var brush_node: Node2D
var island_origin: Vector2 = Vector2.ZERO
var island_size: Vector2 = Vector2(10.0, 10.0)
var _last_painted_world: Vector2 = Vector2(99999.0, 99999.0)
var _brush_radius_uv: float = 0.05
var _points_to_draw: Array[Vector2] = []

func _init(w_origin: Vector2, w_size: Vector2) -> void:
	island_origin = w_origin
	island_size = w_size

func _ready() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(256, 256)
	viewport.transparent_bg = true
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)

	brush_node = Node2D.new()
	brush_node.name = "TrailCanvas"
	viewport.add_child(brush_node)
	brush_node.draw.connect(_on_brush_draw)

func get_trail_texture() -> ViewportTexture:
	if viewport != null:
		return viewport.get_texture()
	return null

func paint(world_pos: Vector3, blade_radius: float) -> void:
	if island_size.x <= 0.01 or island_size.y <= 0.01:
		return

	var current_2d: Vector2 = Vector2(world_pos.x, world_pos.z)
	if current_2d.distance_squared_to(_last_painted_world) < 0.005:
		return

	var uv_x: float = (world_pos.x - island_origin.x) / island_size.x
	var uv_z: float = (world_pos.z - island_origin.y) / island_size.y

	if uv_x < -0.1 or uv_x > 1.1 or uv_z < -0.1 or uv_z > 1.1:
		return

	var vp_pos: Vector2 = Vector2(uv_x * 256.0, uv_z * 256.0)
	_brush_radius_uv = (blade_radius / maxf(island_size.x, island_size.y)) * 256.0

	_points_to_draw.append(vp_pos)
	_last_painted_world = current_2d

	if brush_node != null:
		brush_node.queue_redraw()

func _on_brush_draw() -> void:
	if _points_to_draw.is_empty():
		return
	for pt: Vector2 in _points_to_draw:
		brush_node.draw_circle(pt, _brush_radius_uv, Color(1.0, 1.0, 1.0, 0.85))
	_points_to_draw.clear()

func reset_trail() -> void:
	_last_painted_world = Vector2(99999.0, 99999.0)
	_points_to_draw.clear()
	if viewport != null:
		viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
