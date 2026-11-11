class_name PlantDatabase
extends RefCounted

## Catálogo Data-Driven das Espécies Botânicas do Grass Cut Bot.
## Realiza auto-descoberta dinâmica de recursos PlantSpeciesData em res://data/species/.
## Qualquer novo arquivo .tres colocado nessa pasta é automaticamente assimilado pelo jogo,
## mantendo retrocompatibilidade total com as APIs baseadas em Dictionary existentes.

const PlantSpeciesDataScript = preload("res://scripts/plants/plant_species_data.gd")
const TilePaletteDBScript = preload("res://scripts/editor/tile_palette_db.gd")
const SPECIES_DIR: String = "res://data/species"

# Caches centrais O(1)
static var _resources: Array[PlantSpeciesData] = []
static var _resources_by_key: Dictionary = {}
static var _species_cache: Array[Dictionary] = []
static var _species_by_key: Dictionary = {}

## Força o recarregamento do catálogo botânico a partir do disco
static func reload_species() -> void:
	_resources.clear()
	_resources_by_key.clear()
	_species_cache.clear()
	_species_by_key.clear()
	_load_resources()

## Garante que os recursos estejam carregados em cache
static func _ensure_loaded() -> void:
	if _resources.is_empty():
		_load_resources()

## Varre res://data/species/ via DirAccess e carrega todos os .tres dinamicamente
static func _load_resources() -> void:
	_resources.clear()
	_resources_by_key.clear()
	_species_cache.clear()
	_species_by_key.clear()

	var dir: DirAccess = DirAccess.open(SPECIES_DIR)
	if dir != null:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var res_path: String = "%s/%s" % [SPECIES_DIR, file_name]
				var res: Resource = load(res_path)
				if res is PlantSpeciesData:
					var p_res: PlantSpeciesData = res as PlantSpeciesData
					if not p_res.key.is_empty():
						_resources.append(p_res)
						_resources_by_key[p_res.key] = p_res
			file_name = dir.get_next()
		dir.list_dir_end()

	# Ordena as espécies de forma crescente pelo origin_level (e alfabética em caso de empate)
	_resources.sort_custom(func(a: PlantSpeciesData, b: PlantSpeciesData) -> bool:
		if a.origin_level != b.origin_level:
			return a.origin_level < b.origin_level
		return a.key < b.key
	)

	# Popula os caches de Dictionary para retrocompatibilidade
	for r: PlantSpeciesData in _resources:
		var d: Dictionary = r.to_dict()
		_species_cache.append(d)
		_species_by_key[r.key] = d

## Retorna a lista de todas as instâncias PlantSpeciesData registradas
static func get_all_resources() -> Array[PlantSpeciesData]:
	_ensure_loaded()
	return _resources

## Retorna uma instância PlantSpeciesData pelo seu identificador de chave
static func get_resource(key: String) -> PlantSpeciesData:
	_ensure_loaded()
	if _resources_by_key.has(key):
		return _resources_by_key[key] as PlantSpeciesData
	return null

## Registra dinamicamente uma espécie customizada em tempo de execução
static func register_custom_species(res: PlantSpeciesData) -> void:
	if res == null or res.key.is_empty():
		return
	_ensure_loaded()
	_resources_by_key[res.key] = res
	var d: Dictionary = res.to_dict()
	_species_by_key[res.key] = d

	var found: bool = false
	for i in range(_resources.size()):
		if _resources[i].key == res.key:
			_resources[i] = res
			_species_cache[i] = d
			found = true
			break
	if not found:
		_resources.append(res)
		_species_cache.append(d)
		_resources.sort_custom(func(a: PlantSpeciesData, b: PlantSpeciesData) -> bool:
			if a.origin_level != b.origin_level:
				return a.origin_level < b.origin_level
			return a.key < b.key
		)
		_species_cache.clear()
		for r in _resources:
			_species_cache.append(r.to_dict())

## Retorna todas as espécies como Dictionaries (API retrocompatível)
static func get_all_species() -> Array[Dictionary]:
	_ensure_loaded()
	return _species_cache

## Retorna os dados de uma espécie como Dictionary (API retrocompatível)
static func get_species(key: String) -> Dictionary:
	_ensure_loaded()
	if _species_by_key.has(key):
		return _species_by_key[key] as Dictionary

	# Fallback gracioso para variações visuais registradas no TilePaletteDB
	var v_data: Dictionary = TilePaletteDBScript.get_variation_data(key)
	if not v_data.is_empty():
		return {
			"key": key,
			"category": "flower",
			"name": String(v_data.get("full_name", v_data.get("name", key))),
			"icon": String(v_data.get("icon", "🌸")),
			"color": v_data.get("petal_color", Color.WHITE) as Color,
			"origin_level": 5 if key.begins_with("flower_rose") else (4 if key.begins_with("flower_daisy") else 1),
			"hits": 3,
			"reward_coins": 5,
			"desc": String(v_data.get("full_name", key)),
			"milestones": []
		}
	return {}

## Retorna o nome internacionalizado da espécie ou fallback para o nome canônico
static func get_species_name(species: Dictionary) -> String:
	var key: String = String(species.get("key", ""))
	var trans_key: String = "PLANT_" + key.to_upper()
	var translated: String = TranslationServer.translate(trans_key)
	if translated != trans_key:
		return translated
	return String(species.get("name", ""))
