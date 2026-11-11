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
		"color": Color(1.0, 0.58, 0.80),
		"goal_key": "flower",
		"category": "plant"
	},
	{
		"id": "flower_rose",
		"name": "Rosa",
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

# Variações cromáticas por item da paleta (exibidas no Dock inferior quando o item está selecionado)
const ITEM_VARIATIONS: Dictionary = {
	"flower": [
		{
			"id": "flower",
			"name": "Rosa",
			"full_name": "Rosa Silvestre",
			"icon": "🌸",
			"inner_color": Color(0.88, 0.10, 0.48, 1.0),
			"petal_color": Color(1.0, 0.58, 0.80, 1.0),
			"center_color": Color(1.0, 0.88, 0.05, 1.0),
			"material_path": "res://shaders/interactive_flower_material.tres"
		},
		{
			"id": "flower_blue",
			"name": "Azul",
			"full_name": "Azul Celeste",
			"icon": "💠",
			"inner_color": Color(0.12, 0.28, 0.72, 1.0),
			"petal_color": Color(0.40, 0.90, 0.98, 1.0),
			"center_color": Color(0.98, 0.82, 0.08, 1.0),
			"material_path": "res://shaders/interactive_flower_blue_material.tres"
		},
		{
			"id": "flower_sunset",
			"name": "Pôr do Sol",
			"full_name": "Pôr do Sol",
			"icon": "🌅",
			"inner_color": Color(0.78, 0.08, 0.24, 1.0),
			"petal_color": Color(0.99, 0.72, 0.42, 1.0),
			"center_color": Color(0.92, 0.72, 0.03, 1.0),
			"material_path": "res://shaders/interactive_flower_sunset_material.tres"
		},
		{
			"id": "flower_purple",
			"name": "Lilás",
			"full_name": "Lilás Encantado",
			"icon": "🔮",
			"inner_color": Color(0.38, 0.12, 0.56, 1.0),
			"petal_color": Color(0.85, 0.70, 1.00, 1.0),
			"center_color": Color(0.96, 0.97, 0.99, 1.0),
			"material_path": "res://shaders/interactive_flower_purple_material.tres"
		},
		{
			"id": "flower_white",
			"name": "Branca",
			"full_name": "Branca Suave",
			"icon": "🤍",
			"inner_color": Color(1.00, 0.92, 0.50, 1.0),
			"petal_color": Color(1.00, 1.00, 1.00, 1.0),
			"center_color": Color(0.92, 0.70, 0.03, 1.0),
			"material_path": "res://shaders/interactive_flower_white_material.tres"
		},
		{
			"id": "flower_turquoise",
			"name": "Turquesa",
			"full_name": "Turquesa Mística",
			"icon": "💎",
			"inner_color": Color(0.06, 0.48, 0.44, 1.0),
			"petal_color": Color(0.38, 0.94, 0.84, 1.0),
			"center_color": Color(0.96, 0.65, 0.04, 1.0),
			"material_path": "res://shaders/interactive_flower_turquoise_material.tres"
		}
	],
	"flower_rose": [
		{
			"id": "flower_rose",
			"name": "Vermelha",
			"full_name": "Rosa Vermelha",
			"icon": "🌹",
			"inner_color": Color(0.28, 0.01, 0.05, 1.0),
			"petal_color": Color(1.0, 0.15, 0.32, 1.0),
			"center_color": Color(0.35, 0.01, 0.06, 1.0),
			"material_path": "res://shaders/flower_rose_material.tres"
		},
		{
			"id": "flower_rose_white",
			"name": "Branca",
			"full_name": "Rosa Branca",
			"icon": "🤍",
			"inner_color": Color(0.70, 0.58, 0.42, 1.0),
			"petal_color": Color(1.0, 1.0, 1.0, 1.0),
			"center_color": Color(0.85, 0.68, 0.25, 1.0),
			"material_path": "res://shaders/flower_rose_white_material.tres"
		},
		{
			"id": "flower_rose_yellow",
			"name": "Amarela",
			"full_name": "Rosa Amarela",
			"icon": "💛",
			"inner_color": Color(0.78, 0.20, 0.0, 1.0),
			"petal_color": Color(1.0, 0.95, 0.15, 1.0),
			"center_color": Color(0.85, 0.25, 0.0, 1.0),
			"material_path": "res://shaders/flower_rose_yellow_material.tres"
		},
		{
			"id": "flower_rose_blue",
			"name": "Azul",
			"full_name": "Rosa Azul",
			"icon": "💙",
			"inner_color": Color(0.03, 0.08, 0.35, 1.0),
			"petal_color": Color(0.38, 0.80, 1.0, 1.0),
			"center_color": Color(0.04, 0.10, 0.40, 1.0),
			"material_path": "res://shaders/flower_rose_blue_material.tres"
		},
		{
			"id": "flower_rose_wine",
			"name": "Vinho",
			"full_name": "Rosa Vinho",
			"icon": "🍷",
			"inner_color": Color(0.10, 0.02, 0.06, 1.0),
			"petal_color": Color(0.40, 0.08, 0.22, 1.0),
			"center_color": Color(0.16, 0.03, 0.10, 1.0),
			"material_path": "res://shaders/flower_rose_wine_material.tres"
		},
		{
			"id": "flower_rose_black",
			"name": "Negra",
			"full_name": "Rosa Negra",
			"icon": "🖤",
			"inner_color": Color(0.04, 0.015, 0.035, 1.0),
			"petal_color": Color(0.20, 0.05, 0.12, 1.0),
			"center_color": Color(0.07, 0.06, 0.08, 1.0),
			"material_path": "res://shaders/flower_rose_black_material.tres"
		},
		{
			"id": "flower_rose_peach",
			"name": "Pêssego",
			"full_name": "Rosa Pêssego",
			"icon": "🧡",
			"inner_color": Color(0.72, 0.25, 0.15, 1.0),
			"petal_color": Color(1.0, 0.66, 0.52, 1.0),
			"center_color": Color(0.91, 0.51, 0.23, 1.0),
			"material_path": "res://shaders/flower_rose_peach_material.tres"
		}
	],
	"flower_daisy": [
		{
			"id": "flower_daisy",
			"name": "Branca",
			"full_name": "Margarida Branca",
			"icon": "🌼",
			"inner_color": Color(0.0, 0.0, 0.0, 0.0),
			"petal_color": Color(1.0, 1.0, 1.0, 1.0),
			"center_color": Color(1.0, 0.85, 0.0, 1.0),
			"material_path": "res://shaders/flower_daisy_material.tres"
		},
		{
			"id": "flower_daisy_blue",
			"name": "Azul",
			"full_name": "Margarida Azul Celeste",
			"icon": "💙",
			"inner_color": Color(0.25, 0.45, 0.85, 1.0),
			"petal_color": Color(0.43, 0.66, 0.99, 1.0),
			"center_color": Color(1.0, 0.82, 0.0, 1.0),
			"material_path": "res://shaders/flower_daisy_blue_material.tres"
		},
		{
			"id": "flower_daisy_orange",
			"name": "Laranja",
			"full_name": "Margarida Laranja",
			"icon": "🧡",
			"inner_color": Color(0.85, 0.28, 0.02, 1.0),
			"petal_color": Color(1.0, 0.48, 0.10, 1.0),
			"center_color": Color(1.0, 0.75, 0.0, 1.0),
			"material_path": "res://shaders/flower_daisy_orange_material.tres"
		},
		{
			"id": "flower_daisy_yellow",
			"name": "Amarela",
			"full_name": "Margarida Amarela Solar",
			"icon": "💛",
			"inner_color": Color(0.95, 0.65, 0.0, 1.0),
			"petal_color": Color(1.0, 0.88, 0.15, 1.0),
			"center_color": Color(0.90, 0.55, 0.0, 1.0),
			"material_path": "res://shaders/flower_daisy_yellow_material.tres"
		},
		{
			"id": "flower_daisy_red",
			"name": "Vermelha",
			"full_name": "Margarida Vermelha Carmesim",
			"icon": "❤️",
			"inner_color": Color(0.55, 0.04, 0.10, 1.0),
			"petal_color": Color(0.90, 0.15, 0.22, 1.0),
			"center_color": Color(0.98, 0.78, 0.08, 1.0),
			"material_path": "res://shaders/flower_daisy_red_material.tres"
		},
		{
			"id": "flower_daisy_pink",
			"name": "Rosa",
			"full_name": "Margarida Rosa Silvestre",
			"icon": "🌸",
			"inner_color": Color(0.70, 0.15, 0.45, 1.0),
			"petal_color": Color(0.95, 0.42, 0.68, 1.0),
			"center_color": Color(1.0, 0.85, 0.10, 1.0),
			"material_path": "res://shaders/flower_daisy_pink_material.tres"
		},
		{
			"id": "flower_daisy_bicolor",
			"name": "Bicolor",
			"full_name": "Margarida Coroada Bicolor",
			"icon": "✨",
			"inner_color": Color(1.0, 0.85, 0.0, 1.0),
			"petal_color": Color(1.0, 1.0, 1.0, 1.0),
			"center_color": Color(0.92, 0.60, 0.0, 1.0),
			"material_path": "res://shaders/flower_daisy_bicolor_material.tres"
		}
	],
	"flower_tulip": [
		{
			"id": "flower_tulip",
			"name": "Rubi",
			"full_name": "Tulipa Imperial Rubi",
			"icon": "🌷",
			"inner_color": Color(0.35, 0.02, 0.06, 1.0),
			"petal_color": Color(1.0, 0.12, 0.28, 1.0),
			"center_color": Color(0.85, 0.60, 0.05, 1.0),
			"material_path": "res://shaders/flower_tulip_material.tres"
		},
		{
			"id": "flower_tulip_yellow",
			"name": "Solar",
			"full_name": "Tulipa Imperial Solar",
			"icon": "💛",
			"inner_color": Color(0.65, 0.28, 0.02, 1.0),
			"petal_color": Color(1.0, 0.88, 0.05, 1.0),
			"center_color": Color(0.30, 0.15, 0.05, 1.0),
			"material_path": "res://shaders/flower_tulip_yellow_material.tres"
		},
		{
			"id": "flower_tulip_purple",
			"name": "Real",
			"full_name": "Tulipa Imperial Real",
			"icon": "💜",
			"inner_color": Color(0.25, 0.02, 0.35, 1.0),
			"petal_color": Color(0.85, 0.15, 0.80, 1.0),
			"center_color": Color(1.0, 0.85, 0.20, 1.0),
			"material_path": "res://shaders/flower_tulip_purple_material.tres"
		},
		{
			"id": "flower_tulip_orange",
			"name": "Chama",
			"full_name": "Tulipa Imperial Chama",
			"icon": "🧡",
			"inner_color": Color(0.45, 0.05, 0.05, 1.0),
			"petal_color": Color(1.0, 0.45, 0.05, 1.0),
			"center_color": Color(0.95, 0.85, 0.10, 1.0),
			"material_path": "res://shaders/flower_tulip_orange_material.tres"
		}
	],
	"flower_bed": [
		{
			"id": "flower_bed",
			"name": "Misto",
			"full_name": "Canteiro Florido Misto",
			"icon": "🪻",
			"inner_color": Color(0.38, 0.08, 0.55, 1.0),
			"petal_color": Color(0.92, 0.35, 1.0, 1.0),
			"center_color": Color(1.0, 0.90, 0.10, 1.0),
			"material_path": "res://shaders/flower_bed_material.tres"
		},
		{
			"id": "flower_bed_blue",
			"name": "Celeste",
			"full_name": "Canteiro Florido Celeste",
			"icon": "💠",
			"inner_color": Color(0.05, 0.18, 0.55, 1.0),
			"petal_color": Color(0.15, 0.75, 1.0, 1.0),
			"center_color": Color(1.0, 0.95, 0.20, 1.0),
			"material_path": "res://shaders/flower_bed_blue_material.tres"
		},
		{
			"id": "flower_bed_white",
			"name": "Alvorada",
			"full_name": "Canteiro Florido Alvorada",
			"icon": "🤍",
			"inner_color": Color(0.08, 0.28, 0.20, 1.0),
			"petal_color": Color(0.96, 0.98, 1.0, 1.0),
			"center_color": Color(1.0, 0.85, 0.15, 1.0),
			"material_path": "res://shaders/flower_bed_white_material.tres"
		}
	],
	"rock": [
		{
			"id": "rock",
			"name": "Ardósia",
			"full_name": "Rocha Ardósia",
			"icon": "🪨",
			"color": Color(0.48, 0.52, 0.58),
			"category": "obstacle",
			"material_path": ""
		},
		{
			"id": "rock_moss",
			"name": "Musgo",
			"full_name": "Rocha com Musgo",
			"icon": "🌿",
			"color": Color(0.28, 0.72, 0.32),
			"category": "obstacle",
			"material_path": ""
		},
		{
			"id": "rock_spire",
			"name": "Monólito",
			"full_name": "Monólito Pontiagudo",
			"icon": "⛰️",
			"color": Color(0.42, 0.46, 0.52),
			"category": "obstacle",
			"material_path": ""
		},
		{
			"id": "rock_moss_spire",
			"name": "Monólito Musgo",
			"full_name": "Monólito com Musgo",
			"icon": "🪴",
			"color": Color(0.32, 0.68, 0.36),
			"category": "obstacle",
			"material_path": ""
		},
		{
			"id": "rock_sandstone",
			"name": "Arenito",
			"full_name": "Arenito de Praia",
			"icon": "🏜️",
			"color": Color(0.82, 0.48, 0.26),
			"category": "obstacle",
			"material_path": ""
		},
		{
			"id": "rock_boulder",
			"name": "Boulder",
			"full_name": "Boulder Costeiro",
			"icon": "🌑",
			"color": Color(0.36, 0.40, 0.46),
			"category": "obstacle",
			"material_path": ""
		}
	]
}

static func get_variations(base_id: String) -> Array:
	return ITEM_VARIATIONS.get(base_id, [])

static func has_variations(base_id: String) -> bool:
	return ITEM_VARIATIONS.has(base_id) and not (ITEM_VARIATIONS[base_id] as Array).is_empty()

static func get_base_id_for_variant(variant_id: String) -> String:
	for base_id: String in ITEM_VARIATIONS.keys():
		var var_list: Array = ITEM_VARIATIONS[base_id] as Array
		for v_var in var_list:
			if v_var is Dictionary and String(v_var.get("id", "")) == variant_id:
				return base_id
	return variant_id

static func get_variation_data(variant_id: String) -> Dictionary:
	for base_id: String in ITEM_VARIATIONS.keys():
		var var_list: Array = ITEM_VARIATIONS[base_id] as Array
		for v_var in var_list:
			if v_var is Dictionary and String(v_var.get("id", "")) == variant_id:
				return v_var as Dictionary
	return {}

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
	var v_data: Dictionary = get_variation_data(id_str)
	if not v_data.is_empty():
		var v_color: Color = v_data.get("color", v_data.get("petal_color", Color.WHITE)) as Color
		var v_cat: String = String(v_data.get("category", "plant"))
		return {
			"id": v_data["id"],
			"name": v_data["full_name"],
			"icon": v_data["icon"],
			"color": v_color,
			"goal_key": id_str if v_cat != "obstacle" else "",
			"category": v_cat
		}
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
