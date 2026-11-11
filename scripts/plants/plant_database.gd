class_name PlantDatabase
extends RefCounted

## Catálogo Data-Driven das Espécies Botânicas do Grass Cut Bot.
## Realiza auto-descoberta dinâmica de recursos PlantSpeciesData em res://data/species/.
## Qualquer novo arquivo .tres colocado nessa pasta é automaticamente assimilado pelo jogo,
## mantendo retrocompatibilidade total com as APIs baseadas em Dictionary existentes.

const PlantSpeciesDataScript = preload("res://scripts/plants/plant_species_data.gd")
const TilePaletteDBScript = preload("res://scripts/editor/tile_palette_db.gd")
const SPECIES_DIR: String = "res://data/species"

## Manifesto canônico de espécies para garantir carregamento instantâneo e à prova de falhas
## em builds exportadas (Android APK/AAB, Web HTML5) onde DirAccess pode não listar arquivos empacotados.
const CANONICAL_SPECIES_PATHS: PackedStringArray = [
	"res://data/species/grass_green.tres",
	"res://data/species/grass_yellow.tres",
	"res://data/species/grass_blue.tres",
	"res://data/species/grass_purple.tres",
	"res://data/species/grass_red.tres",
	"res://data/species/grass_white.tres",
	"res://data/species/grass_black.tres",
	"res://data/species/wheat.tres",
	"res://data/species/flower.tres",
	"res://data/species/flower_blue.tres",
	"res://data/species/flower_purple.tres",
	"res://data/species/flower_white.tres",
	"res://data/species/flower_turquoise.tres",
	"res://data/species/flower_sunset.tres",
	"res://data/species/flower_rose.tres",
	"res://data/species/flower_rose_peach.tres",
	"res://data/species/flower_rose_wine.tres",
	"res://data/species/flower_rose_blue.tres",
	"res://data/species/flower_rose_white.tres",
	"res://data/species/flower_rose_yellow.tres",
	"res://data/species/flower_rose_black.tres",
	"res://data/species/flower_daisy.tres",
	"res://data/species/flower_daisy_pink.tres",
	"res://data/species/flower_daisy_orange.tres",
	"res://data/species/flower_daisy_yellow.tres",
	"res://data/species/flower_daisy_red.tres",
	"res://data/species/flower_daisy_blue.tres",
	"res://data/species/flower_daisy_bicolor.tres",
	"res://data/species/flower_sunflower.tres",
	"res://data/species/flower_tulip.tres",
	"res://data/species/flower_tulip_yellow.tres",
	"res://data/species/flower_tulip_purple.tres",
	"res://data/species/flower_tulip_orange.tres",
	"res://data/species/flower_bed.tres",
	"res://data/species/flower_bed_blue.tres",
	"res://data/species/flower_bed_white.tres"
]

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
			if not dir.current_is_dir():
				var clean_name: String = file_name.trim_suffix(".remap")
				if clean_name.ends_with(".tres") or clean_name.ends_with(".res"):
					var res_path: String = "%s/%s" % [SPECIES_DIR, clean_name]
					if ResourceLoader.exists(res_path):
						var res: Resource = load(res_path)
						if res is PlantSpeciesData:
							var p_res: PlantSpeciesData = res as PlantSpeciesData
							if not p_res.key.is_empty() and not _resources_by_key.has(p_res.key):
								_resources.append(p_res)
								_resources_by_key[p_res.key] = p_res
			file_name = dir.get_next()
		dir.list_dir_end()

	# Defesa em profundidade essencial para builds exportadas (Android APK/AAB e Web HTML5):
	# Se a listagem do DirAccess não encontrou recursos no pacote, carrega diretamente do manifesto canônico
	if _resources.is_empty():
		for path in CANONICAL_SPECIES_PATHS:
			if ResourceLoader.exists(path):
				var res: Resource = load(path)
				if res is PlantSpeciesData:
					var p_res: PlantSpeciesData = res as PlantSpeciesData
					if not p_res.key.is_empty() and not _resources_by_key.has(p_res.key):
						_resources.append(p_res)
						_resources_by_key[p_res.key] = p_res

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

## Retorna a lista unificada de todos os tipos e variações de vegetação registrados no jogo
static func get_all_registered_types() -> PackedStringArray:
	_ensure_loaded()
	var types: PackedStringArray = PackedStringArray()

	# 1. Adiciona todas as espécies base descobertas em res://data/species/
	for r: PlantSpeciesData in _resources:
		if not types.has(r.key):
			types.append(r.key)

	# 2. Adiciona as variações cosméticas registradas no TilePaletteDB
	for base_id: String in TilePaletteDBScript.ITEM_VARIATIONS.keys():
		var var_list: Array = TilePaletteDBScript.ITEM_VARIATIONS[base_id] as Array
		for v in var_list:
			if v is Dictionary:
				var vid: String = String(v.get("id", ""))
				if not vid.is_empty() and not types.has(vid):
					types.append(vid)

	# 3. Fallback de segurança se nenhuma espécie foi resolvida
	if types.is_empty():
		for path in CANONICAL_SPECIES_PATHS:
			var base_k: String = path.get_file().get_basename()
			if not types.has(base_k):
				types.append(base_k)

	return types

