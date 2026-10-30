extends RefCounted

# Catálogo de itens de Terreno (Camada 0: Ilha 3D sobre o Oceano)
const TERRAIN_ITEMS: Array[Dictionary] = [
	{
		"id": "auto_island",
		"name": "Ilha Auto-Tile",
		"icon": "🏝️",
		"color": Color(0.28, 0.72, 0.32),
		"desc": "Adapta bordas, quinas e falésias automaticamente",
		"is_auto": true
	},
	{
		"id": "island_center",
		"name": "Piso Grama (Centro)",
		"icon": "🟩",
		"color": Color(0.32, 0.64, 0.24),
		"desc": "Bloco central de ilha (0.8m x 0.8m)",
		"is_auto": false
	},
	{
		"id": "island_dirt",
		"name": "Piso Terra / Trilha",
		"icon": "🟫",
		"color": Color(0.56, 0.41, 0.27),
		"desc": "Bloco de trilha de terra na ilha",
		"is_auto": false
	},
	{
		"id": "island_edge",
		"name": "Borda Reta Costeira",
		"icon": "🌊",
		"color": Color(0.24, 0.56, 0.48),
		"desc": "Borda de falésia reta [R para girar]",
		"is_auto": false
	},
	{
		"id": "island_corner_out",
		"name": "Quina Externa Ilha",
		"icon": "📐",
		"color": Color(0.22, 0.52, 0.58),
		"desc": "Canto convexo voltado ao mar [R para girar]",
		"is_auto": false
	},
	{
		"id": "island_corner_in",
		"name": "Quina Interna (Curva L)",
		"icon": "⤵️",
		"color": Color(0.26, 0.60, 0.42),
		"desc": "Canto côncavo interno da ilha [R para girar]",
		"is_auto": false
	},
	{
		"id": "island_end",
		"name": "Ponta de Península",
		"icon": "🧴",
		"color": Color(0.20, 0.48, 0.52),
		"desc": "Extremidade de caminho 1x1 [R para girar]",
		"is_auto": false
	}
]

# Catálogo de Grama e Vegetação Orgânica (Camada 1: Campo Fino 0.20m)
const GRASS_ITEMS: Array[Dictionary] = [
	{
		"id": "grass_green",
		"name": "Grama Verde",
		"icon": "🌿",
		"color": Color(0.28, 0.81, 0.10),
		"goal_key": "grass",
		"category": "grass"
	},
	{
		"id": "grass_yellow",
		"name": "Grama Amarela (1x)",
		"icon": "🌼",
		"color": Color(0.95, 0.83, 0.35),
		"goal_key": "grass",
		"category": "grass"
	},
	{
		"id": "grass_blue",
		"name": "Grama Azul",
		"icon": "💠",
		"color": Color(0.39, 0.74, 0.96),
		"goal_key": "grass",
		"category": "grass"
	},
	{
		"id": "grass_purple",
		"name": "Grama Violeta",
		"icon": "🔮",
		"color": Color(0.76, 0.46, 0.92),
		"goal_key": "grass",
		"category": "grass"
	},
	{
		"id": "grass_white",
		"name": "Grama Branca",
		"icon": "🤍",
		"color": Color(0.92, 0.94, 0.98),
		"goal_key": "grass",
		"category": "grass"
	},
	{
		"id": "grass_red",
		"name": "Grama Vermelha",
		"icon": "❤️",
		"color": Color(0.95, 0.37, 0.38),
		"goal_key": "grass",
		"category": "grass"
	},
	{
		"id": "grass_black",
		"name": "Grama Preta",
		"icon": "🖤",
		"color": Color(0.28, 0.28, 0.34),
		"goal_key": "grass",
		"category": "grass"
	}
]

# Catálogo de Objetos e Obstáculos (Camada 2: Tile de 0.80m)
const OBJECT_ITEMS: Array[Dictionary] = [
	{
		"id": "rock",
		"name": "Rocha Sólida",
		"icon": "🪨",
		"color": Color(0.52, 0.56, 0.62),
		"goal_key": "",
		"category": "obstacle"
	},
	{
		"id": "flower",
		"name": "Flor Silvestre",
		"icon": "🌸",
		"color": Color(1.0, 0.18, 0.65),
		"goal_key": "flower",
		"category": "plant"
	},
	{
		"id": "flower_rose",
		"name": "Rosa Nobre",
		"icon": "🌹",
		"color": Color(1.0, 0.08, 0.35),
		"goal_key": "flower_rose",
		"category": "plant"
	},
	{
		"id": "flower_daisy",
		"name": "Margarida",
		"icon": "🌼",
		"color": Color(1.0, 1.0, 1.0),
		"goal_key": "flower_daisy",
		"category": "plant"
	},
	{
		"id": "flower_sunflower",
		"name": "Girassol",
		"icon": "🌻",
		"color": Color(1.0, 0.88, 0.0),
		"goal_key": "flower_sunflower",
		"category": "plant"
	},
	{
		"id": "flower_bell",
		"name": "Flor Sino",
		"icon": "🔔",
		"color": Color(0.12, 0.65, 1.0),
		"goal_key": "flower_bell",
		"category": "plant"
	},
	{
		"id": "flower_corolla",
		"name": "Cravo Corola",
		"icon": "🏵️",
		"color": Color(1.0, 0.50, 0.05),
		"goal_key": "flower_corolla",
		"category": "plant"
	},
	{
		"id": "flower_tulip",
		"name": "Tulipa Imperial",
		"icon": "🌷",
		"color": Color(1.0, 0.08, 0.24),
		"goal_key": "flower_tulip",
		"category": "plant"
	},
	{
		"id": "flower_bed",
		"name": "Canteiro Florido",
		"icon": "🪻",
		"color": Color(0.88, 0.30, 1.0),
		"goal_key": "flower_bed",
		"category": "plant"
	},
	{
		"id": "wheat",
		"name": "Trigo Maduro",
		"icon": "🌾",
		"color": Color(0.92, 0.68, 0.18),
		"goal_key": "wheat",
		"category": "plant"
	},
	{
		"id": "cutter_spawn",
		"name": "Spawn do Robô",
		"icon": "🤖",
		"color": Color(1.0, 0.78, 0.15),
		"goal_key": "",
		"category": "spawn"
	}
]

static func get_item_by_id(id_str: String) -> Dictionary:
	for item in GRASS_ITEMS:
		if String(item["id"]) == id_str:
			return item
	for item in TERRAIN_ITEMS:
		if String(item["id"]) == id_str:
			return item
	for item in OBJECT_ITEMS:
		if String(item["id"]) == id_str:
			return item
	return {}

static func get_terrain_info(tile_id: String) -> Dictionary:
	for item in TERRAIN_ITEMS:
		if String(item["id"]) == tile_id:
			return item
	return TERRAIN_ITEMS[1]

static func get_grass_info(grass_id: String) -> Dictionary:
	for item in GRASS_ITEMS:
		if String(item["id"]) == grass_id:
			return item
	return GRASS_ITEMS[0]

static func get_object_info(obj_id: String) -> Dictionary:
	for item in OBJECT_ITEMS:
		if String(item["id"]) == obj_id:
			return item
	return OBJECT_ITEMS[0]
