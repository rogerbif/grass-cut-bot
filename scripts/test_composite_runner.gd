extends SceneTree

func _initialize() -> void:
	print("--- TESTANDO COMPOSITOR DE ÍCONES ---")
	
	# Teste 1: Grama Verde
	var img_green: Image = _build_composite_image("grass_green")
	assert(img_green != null, "Falha ao gerar composite de grass_green")
	var err1 = img_green.save_png("res://test_grass_green_composite.png")
	print("Grama verde salva: ", err1 == OK)
	
	# Teste 2: Grama Amarela
	var img_yellow: Image = _build_composite_image("grass_yellow")
	assert(img_yellow != null, "Falha ao gerar composite de grass_yellow")
	var err2 = img_yellow.save_png("res://test_grass_yellow_composite.png")
	print("Grama amarela salva: ", err2 == OK)

	# Teste 3: Trigo
	var img_wheat: Image = _build_composite_image("wheat")
	assert(img_wheat != null, "Falha ao gerar composite de wheat")
	var err3 = img_wheat.save_png("res://test_wheat_composite.png")
	print("Trigo salvo: ", err3 == OK)

	# Teste 4: Flor
	var img_flower: Image = _build_composite_image("flower")
	assert(img_flower != null, "Falha ao gerar composite de flower")
	var err4 = img_flower.save_png("res://test_flower_composite.png")
	print("Flor salva: ", err4 == OK)

	print("✔ Todos os composites gerados com sucesso!")
	quit(0)

func _build_composite_image(plant_type: String) -> Image:
	var gif_script = load("res://scripts/ui/goal_icon_factory.gd")
	var pd_script = load("res://scripts/plants/plant_database.gd")
	
	var sp_data: Dictionary = pd_script.get_species(plant_type)
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
	var top_tint: Color = theme_col
	
	if cat == "crop":
		tex_base = load("res://assets/ui/collection/illus_wheat_bundle.svg")
	elif cat == "flower":
		tex_base = load("res://assets/ui/collection/illus_flower_stems.svg")
		tex_top = load("res://assets/ui/collection/illus_flower_petals.svg")
	else:
		tex_base = load("res://assets/ui/collection/illus_grass_base.svg")
		tex_top = load("res://assets/ui/collection/illus_grass_blades.svg")
		
	var img: Image = tex_base.get_image()
	img.convert(Image.FORMAT_RGBA8)
	var w: int = img.get_width()
	var h: int = img.get_height()
	
	# Remove halos/glows de baixa opacidade (como o radial glow do SVG de fundo)
	for y: int in range(h):
		for x: int in range(w):
			var c: Color = img.get_pixel(x, y)
			if c.a < 0.60:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				
	if tex_top != null:
		var top_img: Image = tex_top.get_image()
		top_img.convert(Image.FORMAT_RGBA8)
		# Tint do topo
		for y: int in range(h):
			for x: int in range(w):
				var c: Color = top_img.get_pixel(x, y)
				if c.a > 0.01:
					top_img.set_pixel(x, y, Color(c.r * top_tint.r, c.g * top_tint.g, c.b * top_tint.b, c.a * top_tint.a))
		img.blend_rect(top_img, Rect2i(0, 0, w, h), Vector2i.ZERO)
		
	# Flood fill a partir das 4 bordas para identificar a área externa
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
					
	# Preenche buracos internos enclausurados para não gerar contornos internos
	var fill_col: Color = top_tint if tex_top != null else Color(0.85, 0.70, 0.20, 1.0)
	for y: int in range(h):
		for x: int in range(w):
			if not visited[y][x] and img.get_pixel(x, y).a < 0.12:
				img.set_pixel(x, y, Color(fill_col.r * 0.75, fill_col.g * 0.75, fill_col.b * 0.75, 1.0))
				
	return img
