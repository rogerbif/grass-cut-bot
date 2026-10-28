class_name PlantDatabase
extends RefCounted

## Catálogo Canônico das 15 Espécies Botânicas do Grass Cut Bot.
## Define metadados, categorias, cores temáticas, fase de origem e 10 níveis de marcos de maestria.

const GRASS_MILESTONES: Array[Dictionary] = [
	{ "level": 1, "target": 50, "reward": 10, "title": "Brotamento" },
	{ "level": 2, "target": 150, "reward": 20, "title": "Aparador Iniciante" },
	{ "level": 3, "target": 350, "reward": 35, "title": "Ceifador Ágil" },
	{ "level": 4, "target": 700, "reward": 50, "title": "Jardineiro Dedicado" },
	{ "level": 5, "target": 1200, "reward": 75, "title": "Podador Experiente" },
	{ "level": 6, "target": 2000, "reward": 100, "title": "Trator dos Prados" },
	{ "level": 7, "target": 3200, "reward": 150, "title": "Ceifa Implacável" },
	{ "level": 8, "target": 5000, "reward": 200, "title": "Guardião da Grama" },
	{ "level": 9, "target": 7500, "reward": 300, "title": "Lenda dos Gramados" },
	{ "level": 10, "target": 10000, "reward": 500, "title": "Mestre da Clorofila" }
]

const CROP_MILESTONES: Array[Dictionary] = [
	{ "level": 1, "target": 15, "reward": 15, "title": "Primeira Colheita" },
	{ "level": 2, "target": 40, "reward": 25, "title": "Ceifador do Campo" },
	{ "level": 3, "target": 80, "reward": 40, "title": "Colheita de Ouro" },
	{ "level": 4, "target": 150, "reward": 60, "title": "Agrônomo da Ilha" },
	{ "level": 5, "target": 250, "reward": 90, "title": "Moagem Precisa" },
	{ "level": 6, "target": 400, "reward": 130, "title": "Celeiro Farto" },
	{ "level": 7, "target": 650, "reward": 180, "title": "Colheita Dourada" },
	{ "level": 8, "target": 1000, "reward": 250, "title": "Ceifa dos Ventos" },
	{ "level": 9, "target": 1500, "reward": 350, "title": "Patrono da Espiga" },
	{ "level": 10, "target": 2200, "reward": 600, "title": "Grão-Mestre da Seara" }
]

const FLOWER_MILESTONES: Array[Dictionary] = [
	{ "level": 1, "target": 10, "reward": 20, "title": "Florista Amador" },
	{ "level": 2, "target": 25, "reward": 35, "title": "Aroma Suave" },
	{ "level": 3, "target": 50, "reward": 50, "title": "Despetalador Hábil" },
	{ "level": 4, "target": 90, "reward": 80, "title": "Buquê Nobre" },
	{ "level": 5, "target": 150, "reward": 120, "title": "Jardineiro Botânico" },
	{ "level": 6, "target": 240, "reward": 170, "title": "Pétalas de Aço" },
	{ "level": 7, "target": 380, "reward": 230, "title": "Conservador Floral" },
	{ "level": 8, "target": 600, "reward": 320, "title": "Orvalho Real" },
	{ "level": 9, "target": 900, "reward": 450, "title": "Mestre Botânico" },
	{ "level": 10, "target": 1300, "reward": 750, "title": "Guardião das Pétalas" }
]

static var _species_cache: Array[Dictionary] = []
static var _species_by_key: Dictionary = {}

static func get_all_species() -> Array[Dictionary]:
	if not _species_cache.is_empty():
		return _species_cache

	_species_cache = [
		# --- 1. GRAMAS (7 Cores) ---
		{
			"key": "grass_green",
			"category": "grass",
			"name": "Grama Verde Esmeralda",
			"icon": "🌱",
			"color": Color(0.22, 0.69, 0.20, 1.0),
			"origin_level": 1,
			"hits": 1,
			"reward_coins": 1,
			"desc": "A vegetação nativa mais abundante do arquipélago. Macia e relaxante ao toque da lâmina.",
			"milestones": GRASS_MILESTONES
		},
		{
			"key": "grass_yellow",
			"category": "grass",
			"name": "Grama Dourada Solar",
			"icon": "🌾",
			"color": Color(0.95, 0.82, 0.15, 1.0),
			"origin_level": 1,
			"hits": 1,
			"reward_coins": 1,
			"desc": "Aquecida pela luz do sol do meio-dia, colore clareiras e canteiros ensolarados.",
			"milestones": GRASS_MILESTONES
		},
		{
			"key": "grass_blue",
			"category": "grass",
			"name": "Grama Azul Costeira",
			"icon": "🌊",
			"color": Color(0.18, 0.58, 0.92, 1.0),
			"origin_level": 2,
			"hits": 1,
			"reward_coins": 1,
			"desc": "Nutrida pela maresia do oceano turquesa, cresce vigorosa à beira das falésias.",
			"milestones": GRASS_MILESTONES
		},
		{
			"key": "grass_purple",
			"category": "grass",
			"name": "Grama Violeta Crepúsculo",
			"icon": "🔮",
			"color": Color(0.62, 0.31, 0.87, 1.0),
			"origin_level": 4,
			"hits": 1,
			"reward_coins": 1,
			"desc": "Espécie exótica aromática que reflete os tons mágicos do entardecer nas ilhas.",
			"milestones": GRASS_MILESTONES
		},
		{
			"key": "grass_white",
			"category": "grass",
			"name": "Grama Branca Cristalina",
			"icon": "❄️",
			"color": Color(0.88, 0.88, 0.92, 1.0),
			"origin_level": 5,
			"hits": 1,
			"reward_coins": 1,
			"desc": "Folhas de textura aveludada clara que formam mosaicos geométricos deslumbrantes.",
			"milestones": GRASS_MILESTONES
		},
		{
			"key": "grass_red",
			"category": "grass",
			"name": "Grama Carmesim Vulcânica",
			"icon": "🔥",
			"color": Color(0.90, 0.22, 0.27, 1.0),
			"origin_level": 8,
			"hits": 1,
			"reward_coins": 1,
			"desc": "Brota sobre solos ricos e quentes com vigor ardente e coloração rubra viva.",
			"milestones": GRASS_MILESTONES
		},
		{
			"key": "grass_black",
			"category": "grass",
			"name": "Grama Negra Obsidiana",
			"icon": "🌑",
			"color": Color(0.24, 0.24, 0.30, 1.0),
			"origin_level": 12,
			"hits": 1,
			"reward_coins": 1,
			"desc": "Rara e imponente, cresce nas rochas escuras das ilhas vulcânicas mais profundas.",
			"milestones": GRASS_MILESTONES
		},

		# --- 2. CULTURAS AGRÍCOLAS (1 Espécie) ---
		{
			"key": "wheat",
			"category": "crop",
			"name": "Trigo Dourado Enraizado",
			"icon": "🌾",
			"color": Color(0.91, 0.77, 0.42, 1.0),
			"origin_level": 3,
			"hits": 2,
			"reward_coins": 3,
			"desc": "Haste agrícola rígida de 2 golpes com sementes valiosas. Requer precisão e potência.",
			"milestones": CROP_MILESTONES
		},

		# --- 3. FLORES NOBRES & CANTEIROS (7 Espécies) ---
		{
			"key": "flower_daisy",
			"category": "flower",
			"name": "Margarida Silvestre",
			"icon": "🌼",
			"color": Color(0.95, 0.95, 0.80, 1.0),
			"origin_level": 4,
			"hits": 3,
			"reward_coins": 5,
			"desc": "Pétalas brancas com miolo amarelo brilhante. Despetala em 3 golpes concedendo alto valor.",
			"milestones": FLOWER_MILESTONES
		},
		{
			"key": "flower_bell",
			"category": "flower",
			"name": "Flor de Sino Cerúlea",
			"icon": "🔔",
			"color": Color(0.28, 0.79, 0.90, 1.0),
			"origin_level": 4,
			"hits": 3,
			"reward_coins": 5,
			"desc": "Cálice em forma de sino pendular que tilinta suavemente ao balanço da brisa do mar.",
			"milestones": FLOWER_MILESTONES
		},
		{
			"key": "flower_rose",
			"category": "flower",
			"name": "Rosa Rubra Encantada",
			"icon": "🌹",
			"color": Color(0.90, 0.15, 0.28, 1.0),
			"origin_level": 5,
			"hits": 3,
			"reward_coins": 5,
			"desc": "A nobreza dos jardins da ilha. Pétalas encorpadas de fragrância intensa e valiosa.",
			"milestones": FLOWER_MILESTONES
		},
		{
			"key": "flower_sunflower",
			"category": "flower",
			"name": "Girassol Radiante",
			"icon": "🌻",
			"color": Color(1.0, 0.72, 0.01, 1.0),
			"origin_level": 5,
			"hits": 3,
			"reward_coins": 5,
			"desc": "Imponente disco solar que acompanha o movimento do sol sobre as águas do arquipélago.",
			"milestones": FLOWER_MILESTONES
		},
		{
			"key": "flower_tulip",
			"category": "flower",
			"name": "Tulipa Imperial",
			"icon": "🌷",
			"color": Color(0.97, 0.15, 0.52, 1.0),
			"origin_level": 9,
			"hits": 3,
			"reward_coins": 5,
			"desc": "Cálice real magenta que adorna alamedas e caminhos cerimoniais das grandes ilhas.",
			"milestones": FLOWER_MILESTONES
		},
		{
			"key": "flower_corolla",
			"category": "flower",
			"name": "Corola Vulcânica",
			"icon": "🏵️",
			"color": Color(0.98, 0.52, 0.0, 1.0),
			"origin_level": 12,
			"hits": 3,
			"reward_coins": 5,
			"desc": "Espécie termófila com pétalas flamejantes que desabrocham sobre a lava adormecida.",
			"milestones": FLOWER_MILESTONES
		},
		{
			"key": "flower_bed",
			"category": "flower",
			"name": "Canteiro de Flores Mistas",
			"icon": "🪻",
			"color": Color(0.55, 0.25, 0.75, 1.0),
			"origin_level": 15,
			"hits": 3,
			"reward_coins": 5,
			"desc": "Arranjo ornamental denso reunindo múltiplos botões aromáticos em uma só jardineira.",
			"milestones": FLOWER_MILESTONES
		}
	]

	_species_by_key.clear()
	for s: Dictionary in _species_cache:
		_species_by_key[String(s["key"])] = s

	return _species_cache

static func get_species(key: String) -> Dictionary:
	if _species_by_key.is_empty():
		get_all_species()
	return _species_by_key.get(key, {})
