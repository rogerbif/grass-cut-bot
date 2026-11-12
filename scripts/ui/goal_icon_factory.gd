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
static var _outline_image_cache: Dictionary = {}
static var _baked_icon_cache: Dictionary = {}
static var _outline_material: ShaderMaterial = null

static func _bake_category_outline(cat: String) -> Image:
	if _outline_image_cache.has(cat):
		return _outline_image_cache[cat] as Image

	var sil_tex: Texture2D = _get_composite_silhouette("", cat)
	var sil_img: Image = sil_tex.get_image()
	sil_img.convert(Image.FORMAT_RGBA8)
	var w: int = sil_img.get_width()
	var h: int = sil_img.get_height()

	var out_img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var raw: PackedByteArray = sil_img.get_data()
	var src_mask: PackedByteArray = PackedByteArray()
	src_mask.resize(w * h)
	for i: int in range(w * h):
		src_mask[i] = 1 if raw[i * 4 + 3] > 30 else 0

	# 1px borda preta interna + 2px borda branca externa adicional (raio 3)
	for y: int in range(h):
		for x: int in range(w):
			var idx: int = y * w + x
			if src_mask[idx] == 1:
				out_img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue

			var is_inner: bool = false
			for dy: int in range(-1, 2):
				var ny: int = y + dy
				if ny < 0 or ny >= h: continue
				for dx: int in range(-1, 2):
					var nx: int = x + dx
					if nx < 0 or nx >= w: continue
					if src_mask[ny * w + nx] == 1:
						is_inner = true
						break
				if is_inner: break

			if is_inner:
				out_img.set_pixel(x, y, Color(0.0, 0.0, 0.0, 1.0))
			else:
				var is_outer: bool = false
				for dy: int in range(-3, 4):
					var ny: int = y + dy
					if ny < 0 or ny >= h: continue
					for dx: int in range(-3, 4):
						if dx * dx + dy * dy > 10: continue
						var nx: int = x + dx
						if nx < 0 or nx >= w: continue
						if src_mask[ny * w + nx] == 1:
							is_outer = true
							break
					if is_outer: break

				if is_outer:
					out_img.set_pixel(x, y, Color(1.0, 1.0, 1.0, 1.0))
				else:
					out_img.set_pixel(x, y, Color(0, 0, 0, 0))

	_outline_image_cache[cat] = out_img
	return out_img

## Retorna a textura composta de 128x128 pré-assada da espécie com contorno de sticker
static func get_baked_icon_texture(plant_type: String, with_outline: bool = true) -> Texture2D:
	var cache_key: String = "%s_%s" % [plant_type, "ol" if with_outline else "no_ol"]
	if _baked_icon_cache.has(cache_key):
		return _baked_icon_cache[cache_key] as Texture2D

	var sp_data: Dictionary = PlantDatabaseScript.get_species(plant_type)
	var cat: String = String(sp_data.get("category", ""))
	var theme_col: Color = sp_data.get("color", Color.WHITE) as Color

	if cat.is_empty():
		if plant_type.begins_with("flower"):
			cat = "flower"
			theme_col = Color(1.0, 0.18, 0.65)
		elif plant_type == "wheat":
			cat = "crop"
		else:
			cat = "grass"
			theme_col = Color(0.28, 0.81, 0.10)

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

	var base_img: Image = tex_base.get_image()
	base_img.convert(Image.FORMAT_RGBA8)
	var w: int = base_img.get_width()
	var h: int = base_img.get_height()

	var final_img: Image
	if with_outline:
		var outline_base: Image = _bake_category_outline(cat)
		final_img = outline_base.duplicate()
	else:
		final_img = Image.create(w, h, false, Image.FORMAT_RGBA8)

	# Mescla a base
	final_img.blend_rect(base_img, Rect2i(0, 0, w, h), Vector2i.ZERO)

	# Mescla a camada colorida (lâminas ou pétalas)
	if tex_top != null:
		var top_img: Image = tex_top.get_image()
		top_img.convert(Image.FORMAT_RGBA8)
		var top_raw: PackedByteArray = top_img.get_data()
		var sz: int = top_raw.size()
		var cr: float = theme_col.r
		var cg: float = theme_col.g
		var cb: float = theme_col.b
		var ca: float = theme_col.a
		for i: int in range(0, sz, 4):
			top_raw[i] = int(top_raw[i] * cr)
			top_raw[i + 1] = int(top_raw[i + 1] * cg)
			top_raw[i + 2] = int(top_raw[i + 2] * cb)
			top_raw[i + 3] = int(top_raw[i + 3] * ca)
		top_img.set_data(w, h, false, Image.FORMAT_RGBA8, top_raw)
		final_img.blend_rect(top_img, Rect2i(0, 0, w, h), Vector2i.ZERO)

	var baked_tex: ImageTexture = ImageTexture.create_from_image(final_img)
	_baked_icon_cache[cache_key] = baked_tex
	return baked_tex


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


static func _get_composite_silhouette(_plant_type: String, cat: String) -> Texture2D:
	if _silhouette_cache.has(cat):
		return _silhouette_cache[cat] as Texture2D

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
	_silhouette_cache[cat] = composite_tex
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
## Retorna um TextureRect único com textura pré-assada (silhueta + contornos + cores mescladas).
static func build_goal_icon(plant_type: String, icon_size: float = 34.0, with_outline: bool = true) -> Control:
	var rect: TextureRect = TextureRect.new()
	rect.custom_minimum_size = Vector2(icon_size, icon_size)
	rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.texture = get_baked_icon_texture(plant_type, with_outline)
	return rect
