class_name ObstacleDatabase
extends RefCounted

## Catálogo Data-Driven dos Obstáculos e Rochas do Grass Cut Bot.
## Realiza auto-descoberta dinâmica de recursos RockData em res://data/obstacles/.
## Qualquer novo arquivo .tres colocado nessa pasta é automaticamente assimilado pelo jogo,
## paleta do editor e renderização do arquipélago, mantendo retrocompatibilidade total.

const RockDataScript = preload("res://scripts/obstacles/rock_data.gd")
const OBSTACLES_DIR: String = "res://data/obstacles"
const DEFAULT_MATERIAL_PATH: String = "res://shaders/rock_toon_material.tres"

# Caches centrais O(1)
static var _resources: Array[RockData] = []
static var _resources_by_id: Dictionary = {}
static var _mesh_cache: Dictionary = {}
static var _mat_cache: Dictionary = {}
static var _packed_scene_cache: Dictionary = {}
static var _is_loaded: bool = false

## Força o recarregamento do catálogo de obstáculos a partir do disco
static func reload() -> void:
	_resources.clear()
	_resources_by_id.clear()
	_mesh_cache.clear()
	_mat_cache.clear()
	_packed_scene_cache.clear()
	_is_loaded = false
	_load_resources()

## Garante que os recursos estejam carregados em cache
static func _ensure_loaded() -> void:
	if not _is_loaded or _resources.is_empty():
		_load_resources()

## Varre res://data/obstacles/ via DirAccess e carrega todos os .tres dinamicamente
static func _load_resources() -> void:
	_resources.clear()
	_resources_by_id.clear()
	_is_loaded = true

	var dir: DirAccess = DirAccess.open(OBSTACLES_DIR)
	if dir != null:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var res_path: String = "%s/%s" % [OBSTACLES_DIR, file_name]
				var res: Resource = load(res_path)
				if res is RockData:
					var r_data: RockData = res as RockData
					if not r_data.id.is_empty():
						_resources.append(r_data)
						_resources_by_id[r_data.id] = r_data
						for alias in r_data.aliases:
							var a_str: String = String(alias).strip_edges()
							if not a_str.is_empty():
								_resources_by_id[a_str] = r_data
			file_name = dir.get_next()
		dir.list_dir_end()

	# Ordenação determinística por order (prioridade) e ID
	_resources.sort_custom(func(a: RockData, b: RockData) -> bool:
		if a.order != b.order:
			return a.order < b.order
		return a.id < b.id
	)

## Retorna a lista completa de recursos RockData registrados
static func get_all_obstacles() -> Array[RockData]:
	_ensure_loaded()
	return _resources.duplicate()

## Retorna todos os IDs únicos registrados
static func get_all_registered_ids() -> PackedStringArray:
	_ensure_loaded()
	var ids: PackedStringArray = PackedStringArray()
	for r in _resources:
		ids.append(r.id)
	return ids

## Retorna o recurso RockData correspondente ao ID ou alias fornecido
static func get_obstacle(id: String) -> RockData:
	_ensure_loaded()
	return _resources_by_id.get(id, null) as RockData

## Verifica se determinado obstáculo existe no catálogo
static func has_obstacle(id: String) -> bool:
	_ensure_loaded()
	return _resources_by_id.has(id)

## Retorna a malha Mesh3D associada à rocha (com cache O(1))
static func get_mesh(id: String) -> Mesh:
	if _mesh_cache.has(id):
		return _mesh_cache[id] as Mesh

	var r_data: RockData = get_obstacle(id)
	if r_data == null or r_data.mesh_path.is_empty():
		return null

	if not ResourceLoader.exists(r_data.mesh_path):
		return null

	var loaded_res: Resource = load(r_data.mesh_path)
	var resolved_mesh: Mesh = null

	if loaded_res is Mesh:
		resolved_mesh = loaded_res as Mesh
	elif loaded_res is PackedScene:
		var inst: Node = (loaded_res as PackedScene).instantiate()
		var mi: MeshInstance3D = _find_first_mesh_instance(inst)
		if mi != null:
			resolved_mesh = mi.mesh
		inst.free()

	if resolved_mesh != null:
		_mesh_cache[id] = resolved_mesh
		# Registra também sob aliases
		for alias in r_data.aliases:
			_mesh_cache[alias] = resolved_mesh

	return resolved_mesh

## Retorna o material associado à rocha (com cache O(1))
static func get_material(id: String) -> Material:
	if _mat_cache.has(id):
		return _mat_cache[id] as Material

	var r_data: RockData = get_obstacle(id)
	var mat_path: String = r_data.material_path if r_data != null and not r_data.material_path.is_empty() else DEFAULT_MATERIAL_PATH

	if not ResourceLoader.exists(mat_path):
		mat_path = DEFAULT_MATERIAL_PATH

	var mat: Material = null
	if ResourceLoader.exists(mat_path):
		var res: Resource = load(mat_path)
		if res is Material:
			mat = res as Material

	if mat != null:
		_mat_cache[id] = mat
		if r_data != null:
			for alias in r_data.aliases:
				_mat_cache[alias] = mat

	return mat

## Instancia um nó de obstáculo com física estática (Layer 8, grupo "obstacles")
static func instantiate_obstacle_node(id: String, rot_deg: float = 0.0) -> Node3D:
	var r_data: RockData = get_obstacle(id)

	# Se houver scene_path configurada e existente, instancia a cena pré-construída
	if r_data != null and not r_data.scene_path.is_empty() and ResourceLoader.exists(r_data.scene_path):
		var scene_res: PackedScene = null
		if _packed_scene_cache.has(r_data.scene_path):
			scene_res = _packed_scene_cache[r_data.scene_path] as PackedScene
		else:
			scene_res = load(r_data.scene_path) as PackedScene
			if scene_res != null:
				_packed_scene_cache[r_data.scene_path] = scene_res

		if scene_res != null:
			var scn_node: Node3D = scene_res.instantiate() as Node3D
			if scn_node != null:
				if rot_deg != 0.0:
					scn_node.rotation_degrees.y = rot_deg
				return scn_node

	# Fallback procedural puro: constrói StaticBody3D atômico
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "Rock_%s" % (r_data.id if r_data != null else id)
	body.add_to_group("obstacles")
	body.collision_layer = 8
	body.collision_mask = 0

	var c_radius: float = r_data.collision_radius if r_data != null else 0.18
	var c_height: float = r_data.collision_height if r_data != null else 0.8

	var col_shape: CollisionShape3D = CollisionShape3D.new()
	col_shape.name = "CollisionShape3D"
	var cyl: CylinderShape3D = CylinderShape3D.new()
	cyl.radius = c_radius
	cyl.height = c_height
	col_shape.shape = cyl
	col_shape.transform.origin = Vector3(0.0, c_height * 0.5, 0.0)
	body.add_child(col_shape)

	var mesh_res: Mesh = get_mesh(id)
	if mesh_res != null:
		var visual_node: Node3D = Node3D.new()
		visual_node.name = "VisualMesh"
		var mi: MeshInstance3D = MeshInstance3D.new()
		mi.name = "RockMesh"
		mi.mesh = mesh_res
		mi.material_override = get_material(id)
		if r_data != null and r_data.visual_scale != Vector3.ONE:
			mi.scale = r_data.visual_scale
		visual_node.add_child(mi)
		body.add_child(visual_node)

	if rot_deg != 0.0:
		body.rotation_degrees.y = rot_deg

	return body

## Retorna a lista de dicionários formatada para TilePaletteDB.ITEM_VARIATIONS["rock"]
static func get_variations() -> Array[Dictionary]:
	_ensure_loaded()
	var result: Array[Dictionary] = []
	for r in _resources:
		result.append(r.to_dict())
	return result

## Busca recursiva do primeiro MeshInstance3D dentro de uma árvore de nós
static func _find_first_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		var found: MeshInstance3D = _find_first_mesh_instance(child)
		if found != null:
			return found
	return null
