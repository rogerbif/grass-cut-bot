extends SceneTree

func _initialize() -> void:
	print("--- TESTANDO OUTLINE SHADER SOBRE COMPOSITE ---")
	var img: Image = Image.load_from_file("res://test_grass_green_composite.png")
	assert(img != null, "Falha ao carregar composite gerado")
	
	var w: int = img.get_width()
	var h: int = img.get_height()
	
	# Simula o shader de outline:
	# Para cada pixel onde a <= 0.12, se houver vizinho com a > 0.12, pinta outline.
	# Conta quantos pixels de outline são externos (conectados ao fundo) vs internos (enclausurados)
	var outline_img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	
	var inner_w: int = 1
	var outer_w: int = 3
	
	var internal_outline_count: int = 0
	
	for y: int in range(h):
		for x: int in range(w):
			var c: Color = img.get_pixel(x, y)
			if c.a > 0.12:
				outline_img.set_pixel(x, y, c)
			else:
				# Verifica raio de vizinhos
				var found: bool = false
				for dy in range(-outer_w, outer_w + 1):
					for dx in range(-outer_w, outer_w + 1):
						var nx = x + dx
						var ny = y + dy
						if nx >= 0 and nx < w and ny >= 0 and ny < h:
							if img.get_pixel(nx, ny).a > 0.12:
								found = true
								break
					if found:
						break
				if found:
					# É outline!
					outline_img.set_pixel(x, y, Color(1, 1, 1, 1))
					
	outline_img.save_png("res://test_grass_green_outlined.png")
	print("✔ Imagem final com contorno salva em res://test_grass_green_outlined.png!")
	quit(0)
