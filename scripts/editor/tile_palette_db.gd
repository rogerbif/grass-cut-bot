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
	}
]

# Catálogo de Objetos e Vegetação (Camada 1: Sobre a Ilha)
const OBJECT_ITEMS: Array[Dictionary] = [
	{
		"id": "grass_green",
		"name": "Grama Verde",
		"icon": "🌿",
		"color": Color(0.25, 0.78, 0.32),
		"goal_key": "grass",
		"category": "plant"
	},
	{
		"id": "grass_yellow",
		"name": "Grama Dourada",
		"icon": "🌼",
		"color": Color(0.95, 0.80, 0.20),
		"goal_key": "grass",
		"category": "plant"
	},
	{
		"id": "grass_blue",
		"name": "Grama Azul",
		"icon": "💠",
		"color": Color(0.25, 0.68, 0.96),
		"goal_key": "grass",
		"category": "plant"
	},
	{
		"id": "grass_purple",
		"name": "Grama Violeta",
		"icon": "🔮",
		"color": Color(0.72, 0.35, 0.92),
		"goal_key": "grass",
		"category": "plant"
	},
	{
		"id": "wheat",
		"name": "Trigo Maduro (2x)",
		"icon": "🌾",
		"color": Color(0.92, 0.68, 0.18),
		"goal_key": "wheat",
		"category": "plant"
	},
	{
		"id": "flower",
		"name": "Flor Nobre",
		"icon": "🌸",
		"color": Color(0.95, 0.38, 0.68),
		"goal_key": "flower",
		"category": "plant"
	},
	{
		"id": "rock",
		"name": "Rocha Sólida",
		"icon": "🪨",
		"color": Color(0.52, 0.56, 0.62),
		"goal_key": "",
		"category": "obstacle"
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

static func get_terrain_info(tile_id: String) -> Dictionary:
	for item in TERRAIN_ITEMS:
		if String(item["id"]) == tile_id:
			return item
	return TERRAIN_ITEMS[1]

static func get_object_info(obj_id: String) -> Dictionary:
	for item in OBJECT_ITEMS:
		if String(item["id"]) == obj_id:
			return item
	return OBJECT_ITEMS[0]
