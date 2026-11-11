class_name ThemeDatabase
extends RefCounted

## Catálogo Data-Driven dos Temas de Ilha e Atmosferas do Grass Cut Bot.
## Realiza auto-descoberta dinâmica de recursos IslandThemeData em res://data/themes/.
## Permite desacoplar as configurações visuais de céu, sol, oceano e solo das fases.

const IslandThemeDataScript = preload("res://scripts/themes/island_theme_data.gd")
const IslandMeshBuilderScript = preload("res://scripts/level/island_mesh_builder.gd")
const THEMES_DIR: String = "res://data/themes"
const DEFAULT_THEME_ID: String = "tropical_day"

## Manifesto canônico de temas para builds exportadas (Android / Web)
const CANONICAL_THEME_PATHS: PackedStringArray = [
	"res://data/themes/theme_tropical_day.tres",
	"res://data/themes/theme_sunset.tres",
	"res://data/themes/theme_night.tres"
]

static var _resources: Array[IslandThemeData] = []
static var _resources_by_id: Dictionary = {}
static var _is_loaded: bool = false

## Força o recarregamento dos temas a partir do disco
static func reload() -> void:
	_resources.clear()
	_resources_by_id.clear()
	_is_loaded = false
	_load_resources()

## Garante que os recursos estejam carregados em cache
static func _ensure_loaded() -> void:
	if not _is_loaded or _resources.is_empty():
		_load_resources()

## Varre res://data/themes/ via DirAccess e carrega todos os .tres dinamicamente
static func _load_resources() -> void:
	_resources.clear()
	_resources_by_id.clear()
	_is_loaded = true

	var dir: DirAccess = DirAccess.open(THEMES_DIR)
	if dir != null:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				var clean_name: String = file_name.trim_suffix(".remap")
				if clean_name.ends_with(".tres") or clean_name.ends_with(".res"):
					var res_path: String = "%s/%s" % [THEMES_DIR, clean_name]
					if ResourceLoader.exists(res_path):
						var res: Resource = load(res_path)
						if res is IslandThemeData:
							var t_data: IslandThemeData = res as IslandThemeData
							if not t_data.id.is_empty() and not _resources_by_id.has(t_data.id):
								_resources.append(t_data)
								_resources_by_id[t_data.id] = t_data
			file_name = dir.get_next()
		dir.list_dir_end()

	# Defesa em profundidade para builds exportadas
	if _resources.is_empty():
		for res_path in CANONICAL_THEME_PATHS:
			if ResourceLoader.exists(res_path):
				var res: Resource = load(res_path)
				if res is IslandThemeData:
					var t_data: IslandThemeData = res as IslandThemeData
					if not t_data.id.is_empty() and not _resources_by_id.has(t_data.id):
						_resources.append(t_data)
						_resources_by_id[t_data.id] = t_data

	# Ordenação determinística por world_id e ID
	_resources.sort_custom(func(a: IslandThemeData, b: IslandThemeData) -> bool:
		if a.world_id != b.world_id:
			return a.world_id < b.world_id
		return a.id < b.id
	)

## Retorna a lista completa de temas registrados
static func get_all_themes() -> Array[IslandThemeData]:
	_ensure_loaded()
	return _resources.duplicate()

## Retorna o tema correspondente ao ID informado (com fallback para tropical_day)
static func get_theme(id: String) -> IslandThemeData:
	_ensure_loaded()
	if _resources_by_id.has(id):
		return _resources_by_id[id] as IslandThemeData
	return _resources_by_id.get(DEFAULT_THEME_ID, null) as IslandThemeData

## Verifica se determinado tema existe no catálogo
static func has_theme(id: String) -> bool:
	_ensure_loaded()
	return _resources_by_id.has(id)

## Resolve o tema canônico correspondente à fase (regra da Melhoria 204: 100 fases por mundo)
static func get_theme_for_level(level_number: int, level_data: Dictionary = {}) -> IslandThemeData:
	_ensure_loaded()

	# Se o JSON da fase declarar um tema explícito e existente, utiliza-o
	if not level_data.is_empty() and level_data.has("theme"):
		var custom_id: String = String(level_data.get("theme", ""))
		if has_theme(custom_id):
			return get_theme(custom_id)

	# Regra canônica por Mundo:
	# Mundo 1: Fases 01 a 100 -> Tropical Diurno
	# Mundo 2: Fases 101 a 200 -> Pôr do Sol Dourado (Sunset)
	# Mundo 3: Fases 201 a 300 -> Noite Tropical Estrelada
	if level_number <= 100:
		return get_theme("tropical_day")
	elif level_number <= 200:
		return get_theme("sunset_golden")
	elif level_number <= 300:
		return get_theme("night_stars")

	return get_theme(DEFAULT_THEME_ID)

## Aplica os parâmetros do tema em toda a cena de gameplay (Ambiente, Sol, Oceano e Terreno)
static func apply_theme_to_scene(
	theme: IslandThemeData,
	world_env: WorldEnvironment,
	sun: DirectionalLight3D,
	water_ocean: Node3D = null
) -> void:
	if theme == null:
		return

	# 1. Aplica no WorldEnvironment (garante cópia única para evitar contaminação do editor)
	if world_env != null and is_instance_valid(world_env):
		if world_env.environment != null:
			world_env.environment = world_env.environment.duplicate() as Environment
			theme.apply_to_environment(world_env.environment)

	# 2. Aplica na iluminação direcional (Sol)
	if sun != null and is_instance_valid(sun):
		theme.apply_to_sun(sun)

	# 3. Aplica no oceano Toon
	if water_ocean != null and is_instance_valid(water_ocean):
		var surf_water: MeshInstance3D = water_ocean.get_node_or_null("SurfaceWater") as MeshInstance3D
		if surf_water != null and surf_water.mesh != null:
			var mat: Material = surf_water.mesh.surface_get_material(0)
			if mat is ShaderMaterial:
				theme.apply_to_water(mat as ShaderMaterial)

	# 4. Aplica no gerador de terreno procedural
	apply_theme_to_island_builder(theme)

## Configura o IslandMeshBuilder para gerar malhas e materiais fiéis ao tema
static func apply_theme_to_island_builder(theme: IslandThemeData) -> void:
	if theme == null:
		return
	IslandMeshBuilderScript.set_ground_parameters(
		theme.ground_base_color,
		theme.ground_brightness,
		theme.ground_diffuse_toon
	)
