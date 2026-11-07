class_name GoalIconFactory
extends RefCounted

## Fábrica da ilustração botânica de objetivos (mesmos vetores da tela Coleção).
## Usada pelo HUD de gameplay e pelo Card de Fase do menu (Home/Mapa).
##
## ARQUITETURA DE CONTORNO EXTERNO LIMPO (v0.12.144-alpha):
## As camadas visíveis de base e lâminas são renderizadas 100% limpas (sem shader interno).
## O contorno duplo (1px preto + 2px branco) é renderizado exclusivamente na silhueta unificada
## externa subjacente, eliminando totalmente linhas pretas ou brancas no interior das lâminas ou solo.

const PlantDatabaseScript = preload("res://scripts/plants/plant_database.gd")
const OUTLINE_SHADER: Shader = preload("res://shaders/goal_icon_outline.gdshader")

const TEX_ILLUS_GRASS_BASE: Texture2D = preload("res://assets/ui/collection/illus_grass_base.svg")
const TEX_ILLUS_GRASS_BLADES: Texture2D = preload("res://assets/ui/collection/illus_grass_blades.svg")
const TEX_ILLUS_WHEAT: Texture2D = preload("res://assets/ui/collection/illus_wheat_bundle.svg")
const TEX_ILLUS_FLOWER_STEMS: Texture2D = preload("res://assets/ui/collection/illus_flower_stems.svg")
const TEX_ILLUS_FLOWER_PETALS: Texture2D = preload("res://assets/ui/collection/illus_flower_petals.svg")

static var _silhouette_cache: Dictionary = {}
static var _outline_material: ShaderMaterial = null


static func _get_outline_material() -> ShaderMaterial:
	if _outline_material == null:
		var mat: ShaderMaterial = ShaderMaterial.new()
		mat.shader = OUTLINE_SHADER
		mat.set_shader_parameter("inner_outline_color", Color(0.0, 0.0, 0.0, 1.0))
		mat.set_shader_parameter("outer_outline_color", Color(1.0, 1.0, 1.0, 1.0))
		mat.set_shader_parameter("inner_width", 1.2)
		mat.set_shader_parameter("outer_width", 3.6)
		_outline_material = mat
	return _outline_material


static func _get_composite_silhouette(plant_type: String, cat: String) -> Texture2D:
	if _silhouette_cache.has(plant_type):
		return _silhouette_cache[plant_type] as Texture2D

	var tex_base: Texture2D = null
	var tex_top: Texture2D = null

	if cat == "crop":
		tex_base = TEX_ILLUS_WHEAT
	elif cat == "flower":
		tex_base = TEX_ILLUS_FLOWER_STEMS
		tex_top = TEX_ILLUS_FLOWER_PETALS
	else:
		tex_base = TEX_ILLUS_GRASS_BASE
		tex_top = TEX_ILLUS_GRASS_BLADES

	var img: Image = tex_base.get_image()
	img.convert(Image.FORMAT_RGBA8)
	var w: int = img.get_width()
	var h: int = img.get_height()

	# 1. Elimina o glow ambiente radial e sombras difusas para manter somente geometria sólida
	for y: int in range(h):
		for x: int in range(w):
			var c: Color = img.get_pixel(x, y)
			if c.a < 0.60:
				img.set_pixel(x, y, Color(0, 0, 0, 0))

	# 2. Mescla a camada superior (lâminas ou pétalas)
	if tex_top != null:
		var top_img: Image = tex_top.get_image()
		top_img.convert(Image.FORMAT_RGBA8)
		img.blend_rect(top_img, Rect2i(0, 0, w, h), Vector2i.ZERO)

	# 3. Flood fill a partir das 4 bordas para identificar a área exterior
	var visited: Array = []
	for y: int in range(h):
		var row: Array = []
		row.resize(w)
		row.fill(false)
		visited.append(row)

	var queue: Array[Vector2i] = []
	for x: int in range(w):
		if img.get_pixel(x, 0).a < 0.12:
			queue.append(Vector2i(x, 0))
			visited[0][x] = true
		if img.get_pixel(x, h - 1).a < 0.12:
			queue.append(Vector2i(x, h - 1))
			visited[h - 1][x] = true
	for y: int in range(h):
		if img.get_pixel(0, y).a < 0.12 and not visited[y][0]:
			queue.append(Vector2i(0, y))
			visited[y][0] = true
		if img.get_pixel(w - 1, y).a < 0.12 and not visited[y][w - 1]:
			queue.append(Vector2i(w - 1, y))
			visited[y][w - 1] = true

	var head: int = 0
	var dirs: Array[Vector2i] = [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]
	while head < queue.size():
		var pt: Vector2i = queue[head]
		head += 1
		for d: Vector2i in dirs:
			var nx: int = pt.x + d.x
			var ny: int = pt.y + d.y
			if nx >= 0 and nx < w and ny >= 0 and ny < h:
				if not visited[ny][nx] and img.get_pixel(nx, ny).a < 0.12:
					visited[ny][nx] = true
					queue.append(Vector2i(nx, ny))

	# 4. Preenche cavidades internas enclausuradas para que NENHUM contorno apareça dentro da silhueta
	for y: int in range(h):
		for x: int in range(w):
			if not visited[y][x] and img.get_pixel(x, y).a < 0.12:
				img.set_pixel(x, y, Color(1, 1, 1, 1))

	var composite_tex: ImageTexture = ImageTexture.create_from_image(img)
	_silhouette_cache[plant_type] = composite_tex
	return composite_tex


static func _make_sprite_rect(tex: Texture2D, tint: Color) -> TextureRect:
	var rect: TextureRect = TextureRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.modulate = tint
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


## Constrói o container da ilustração para o tipo de planta informado.
static func build_goal_icon(plant_type: String, icon_size: float = 34.0, with_outline: bool = true) -> Control:
	var illus: Control = Control.new()
	illus.custom_minimum_size = Vector2(icon_size, icon_size)
	illus.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	illus.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	illus.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sp_data: Dictionary = PlantDatabaseScript.get_species(plant_type)
	var cat: String = String(sp_data.get("category", ""))
	var theme_col: Color = sp_data.get("color", Color.WHITE) as Color

	# Fallback para chaves genéricas ("grass", "flower")
	if cat.is_empty():
		if plant_type.begins_with("flower"):
			cat = "flower"
			theme_col = Color(1.0, 0.18, 0.65)
		elif plant_type == "wheat":
			cat = "crop"
		else:
			cat = "grass"
			theme_col = Color(0.28, 0.81, 0.10)

	# 1. Camadas visíveis limpas (Child 0 = Base / Stems / Wheat; Child 1 = Blades / Petals)
	if cat == "crop":
		var wheat_rect: TextureRect = _make_sprite_rect(TEX_ILLUS_WHEAT, Color.WHITE)
		illus.add_child(wheat_rect)
	elif cat == "flower":
		var stems_rect: TextureRect = _make_sprite_rect(TEX_ILLUS_FLOWER_STEMS, Color.WHITE)
		illus.add_child(stems_rect)
		var petals_rect: TextureRect = _make_sprite_rect(TEX_ILLUS_FLOWER_PETALS, theme_col)
		illus.add_child(petals_rect)
	else:
		var base_rect: TextureRect = _make_sprite_rect(TEX_ILLUS_GRASS_BASE, Color.WHITE)
		illus.add_child(base_rect)
		var blades_rect: TextureRect = _make_sprite_rect(TEX_ILLUS_GRASS_BLADES, theme_col)
		illus.add_child(blades_rect)

	# 2. Contorno externo subjacente (silhueta contínua sem vazamentos internos)
	if with_outline:
		var outline_rect: TextureRect = TextureRect.new()
		outline_rect.name = "OutlineRect"
		outline_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		outline_rect.texture = _get_composite_silhouette(plant_type, cat)
		outline_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		outline_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		outline_rect.material = _get_outline_material()
		outline_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		outline_rect.show_behind_parent = true
		outline_rect.z_index = -1
		illus.add_child(outline_rect)

	return illus
