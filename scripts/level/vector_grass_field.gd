class_name VectorGrassField
extends RefCounted

## Gerenciador e Processador de Grama por Desenho Vetorial 2D (Grass Cut Bot).
## Armazena formas contínuas fechadas (polígonos e furos no plano XZ em metros),
## executa operações booleanas (Clipper C++ via Geometry2D), amostragem orgânica
## de Poisson Disk (Blue Noise) e triangulação plana para o piso da ilha.

const MIN_TUFT_DISTANCE: float = 0.22
const EDGE_TAPER_DISTANCE: float = 0.16

# Array de dicionários representando cada ilha/mancha vetorial de grama:
# {
#   "id": int,
#   "type": String, # "grass_green", "grass_yellow", ..., "wheat"
#   "polygon": PackedVector2Array, # Vértices externos no plano XZ em metros
#   "holes": Array[PackedVector2Array] # Furos internos opcionais
# }
var shapes: Array[Dictionary] = []
var _next_id: int = 1

func _init() -> void:
	shapes = []
	_next_id = 1

func clear() -> void:
	shapes.clear()
	_next_id = 1

func get_shapes() -> Array[Dictionary]:
	return shapes

## Adiciona uma nova forma vetorial fechada
func add_shape(type_name: String, outer_poly: PackedVector2Array, holes_list: Array = []) -> int:
	if outer_poly.size() < 3:
		return -1
	# Garante orientação horária/anti-horária consistente (orientação positiva para polígono externo)
	var poly_clean: PackedVector2Array = outer_poly
	if not Geometry2D.is_polygon_clockwise(poly_clean):
		# Em Clipper/Geometry2D da Godot, polígonos externos devem ter sentido horário
		poly_clean.reverse()

	var typed_holes: Array[PackedVector2Array] = []
	for h: Variant in holes_list:
		if h is PackedVector2Array and (h as PackedVector2Array).size() >= 3:
			var hole_arr: PackedVector2Array = h as PackedVector2Array
			# Furos devem ter sentido oposto ao contorno externo
			if Geometry2D.is_polygon_clockwise(hole_arr):
				hole_arr.reverse()
			typed_holes.append(hole_arr)

	var shape_id: int = _next_id
	_next_id += 1

	shapes.append({
		"id": shape_id,
		"type": type_name,
		"polygon": poly_clean,
		"holes": typed_holes
	})
	return shape_id

## Mescla um novo polígono desenhado nas formas existentes do mesmo tipo (Auto-Merge via Clipper C++)
func merge_or_add_shape(type_name: String, new_poly: PackedVector2Array) -> void:
	if new_poly.size() < 3:
		return

	var poly_to_merge: PackedVector2Array = new_poly
	if not Geometry2D.is_polygon_clockwise(poly_to_merge):
		poly_to_merge.reverse()

	# Procura formas existentes da mesma cor que colidam/sobreponham o novo polígono
	var merged_indices: Array[int] = []
	var accumulated_polys: Array[PackedVector2Array] = [poly_to_merge]

	for i: int in range(shapes.size()):
		var s: Dictionary = shapes[i]
		if String(s.get("type", "")) != type_name:
			continue
		var existing_poly: PackedVector2Array = s.get("polygon", PackedVector2Array()) as PackedVector2Array
		if existing_poly.is_empty():
			continue

		# Testa interseção rápida de AABB antes do teste de polígono
		var aabb_e: Rect2 = _compute_poly_aabb(existing_poly)
		var aabb_n: Rect2 = _compute_poly_aabb(poly_to_merge)
		if not aabb_e.intersects(aabb_n.grow(0.05)):
			continue

		# Testa se há sobreposição real usando Geometry2D.intersect_polygons
		var test_intersect: Array[PackedVector2Array] = Geometry2D.intersect_polygons(existing_poly, poly_to_merge)
		if not test_intersect.is_empty():
			merged_indices.append(i)
			accumulated_polys.append(existing_poly)

	if merged_indices.is_empty():
		# Não cruza nenhuma forma existente: adiciona como nova forma independente
		add_shape(type_name, poly_to_merge)
		return

	# Executa união com Clipper
	var result_polys: Array[PackedVector2Array] = [accumulated_polys[0]]
	for idx: int in range(1, accumulated_polys.size()):
		var to_merge: PackedVector2Array = accumulated_polys[idx]
		var union_step: Array[PackedVector2Array] = []
		var did_merge: bool = false
		for existing: PackedVector2Array in result_polys:
			var m: Array[PackedVector2Array] = Geometry2D.merge_polygons(existing, to_merge)
			if m.size() == 1:
				union_step.append(m[0])
				did_merge = true
			else:
				union_step.append(existing)
		if not did_merge:
			union_step.append(to_merge)
		result_polys = union_step

	# Remove as formas antigas mescladas (de trás para frente)
	merged_indices.sort()
	for rev_i: int in range(merged_indices.size() - 1, -1, -1):
		shapes.remove_at(merged_indices[rev_i])

	# Adiciona os polígonos resultantes da união
	for res_p: PackedVector2Array in result_polys:
		add_shape(type_name, res_p)

## Aplica corte/subtração booleana em todas as formas vetoriais com a borracha
func clip_shapes(eraser_poly: PackedVector2Array) -> bool:
	if eraser_poly.size() < 3 or shapes.is_empty():
		return false

	var eraser_clean: PackedVector2Array = eraser_poly
	if not Geometry2D.is_polygon_clockwise(eraser_clean):
		eraser_clean.reverse()

	var eraser_aabb: Rect2 = _compute_poly_aabb(eraser_clean)
	var modified: bool = false
	var new_shapes: Array[Dictionary] = []

	for s: Dictionary in shapes:
		var s_type: String = String(s.get("type", "grass_green"))
		var s_poly: PackedVector2Array = s.get("polygon", PackedVector2Array()) as PackedVector2Array
		var s_aabb: Rect2 = _compute_poly_aabb(s_poly)

		if not s_aabb.intersects(eraser_aabb):
			new_shapes.append(s)
			continue

		# Executa recorte via Clipper C++
		var clipped: Array[PackedVector2Array] = Geometry2D.clip_polygons(s_poly, eraser_clean)
		if clipped.is_empty():
			# O polígono foi 100% apagado pela borracha
			modified = true
		else:
			modified = true
			for part: PackedVector2Array in clipped:
				if part.size() >= 3:
					var new_id: int = _next_id
					_next_id += 1
					new_shapes.append({
						"id": new_id,
						"type": s_type,
						"polygon": part,
						"holes": []
					})

	if modified:
		shapes = new_shapes
	return modified

## Amostra tufos em distribuição Poisson Disk / Blue Noise dentro de todos os polígonos
## Retorna Array[Dictionary]: [{ "pos": Vector3, "type": String, "scale_factor": float, "seed": float }]
func sample_all_tufts(min_dist: float = MIN_TUFT_DISTANCE) -> Array[Dictionary]:
	var result_tufts: Array[Dictionary] = []
	var global_seed: int = 101

	for s: Dictionary in shapes:
		var s_type: String = String(s.get("type", "grass_green"))
		var poly: PackedVector2Array = s.get("polygon", PackedVector2Array()) as PackedVector2Array
		var holes_list: Array = s.get("holes", []) as Array

		if poly.size() < 3:
			continue

		var points_sampled: Array[Vector2] = _sample_poisson_in_polygon(poly, holes_list, min_dist, global_seed)
		global_seed += points_sampled.size() + 17

		for pt: Vector2 in points_sampled:
			# Calcula a distância do tufo até a borda do polígono para atenuação suave de escala
			var edge_dist: float = _compute_min_distance_to_polygon_edge(pt, poly)
			var edge_t: float = smoothstep(0.0, EDGE_TAPER_DISTANCE, edge_dist)
			var scale_factor: float = lerpf(0.50, 1.0, edge_t)

			var sub_seed: float = float(int(absf(pt.x * 7919.0) + absf(pt.y * 3137.0)) % 10000)

			result_tufts.append({
				"pos": Vector3(pt.x, 0.0, pt.y),
				"type": s_type,
				"scale_factor": scale_factor,
				"seed": sub_seed
			})

	return result_tufts

## Gera uma malha plana 2D/3D (ArrayMesh) rente ao piso triangulando os polígonos de cada cor
func generate_ground_meshes() -> Dictionary:
	var meshes_by_type: Dictionary = {}
	# Agrupa polígonos por tipo
	var polys_by_type: Dictionary = {}
	for s: Dictionary in shapes:
		var t: String = String(s.get("type", "grass_green"))
		if not polys_by_type.has(t):
			var arr: Array[PackedVector2Array] = []
			polys_by_type[t] = arr
		(polys_by_type[t] as Array[PackedVector2Array]).append(s.get("polygon", PackedVector2Array()) as PackedVector2Array)

	for t: String in polys_by_type.keys():
		var plist: Array[PackedVector2Array] = polys_by_type[t] as Array[PackedVector2Array]
		var st: SurfaceTool = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

		for poly: PackedVector2Array in plist:
			if poly.size() < 3:
				continue
			var indices: PackedInt32Array = Geometry2D.triangulate_polygon(poly)
			if indices.is_empty():
				continue

			# Mapeia vértices no SurfaceTool
			var v_count: int = poly.size()
			for i_idx: int in range(0, indices.size(), 3):
				var i0: int = indices[i_idx]
				var i1: int = indices[i_idx + 1]
				var i2: int = indices[i_idx + 2]
				if i0 >= v_count or i1 >= v_count or i2 >= v_count:
					continue

				var p0: Vector2 = poly[i0]
				var p1: Vector2 = poly[i1]
				var p2: Vector2 = poly[i2]

				st.set_normal(Vector3.UP)
				st.set_uv(Vector2(p0.x * 0.5, p0.y * 0.5))
				st.add_vertex(Vector3(p0.x, 0.002, p0.y))

				st.set_normal(Vector3.UP)
				st.set_uv(Vector2(p1.x * 0.5, p1.y * 0.5))
				st.add_vertex(Vector3(p1.x, 0.002, p1.y))

				st.set_normal(Vector3.UP)
				st.set_uv(Vector2(p2.x * 0.5, p2.y * 0.5))
				st.add_vertex(Vector3(p2.x, 0.002, p2.y))

		var mesh_res: ArrayMesh = st.commit()
		meshes_by_type[t] = mesh_res

	return meshes_by_type

## Serialização para Array de Dicionários JSON v3
func to_dict_list() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s: Dictionary in shapes:
		var poly: PackedVector2Array = s.get("polygon", PackedVector2Array()) as PackedVector2Array
		var pts_raw: Array = []
		for p: Vector2 in poly:
			# Arredonda para 3 casas decimais (1 milímetro de precisão, economizando caracteres)
			pts_raw.append([snappedf(p.x, 0.001), snappedf(p.y, 0.001)])

		var holes_raw: Array = []
		var holes_list: Array = s.get("holes", []) as Array
		for h: Variant in holes_list:
			if h is PackedVector2Array:
				var h_pts: Array = []
				for hp: Vector2 in (h as PackedVector2Array):
					h_pts.append([snappedf(hp.x, 0.001), snappedf(hp.y, 0.001)])
				holes_raw.append(h_pts)

		out.append({
			"id": int(s.get("id", 1)),
			"type": String(s.get("type", "grass_green")),
			"polygon": pts_raw,
			"holes": holes_raw
		})
	return out

## Desserialização a partir de Array JSON v3
func from_dict_list(arr: Array) -> void:
	clear()
	for item: Variant in arr:
		if not (item is Dictionary):
			continue
		var d: Dictionary = item as Dictionary
		var t_name: String = String(d.get("type", "grass_green"))
		var pts_in: Array = d.get("polygon", []) as Array
		var poly: PackedVector2Array = PackedVector2Array()
		for pt_pair: Variant in pts_in:
			if pt_pair is Array and (pt_pair as Array).size() >= 2:
				poly.append(Vector2(float((pt_pair as Array)[0]), float((pt_pair as Array)[1])))

		var holes_in: Array = d.get("holes", []) as Array
		var holes_list: Array[PackedVector2Array] = []
		for h_arr: Variant in holes_in:
			if h_arr is Array:
				var h_poly: PackedVector2Array = PackedVector2Array()
				for h_pair: Variant in (h_arr as Array):
					if h_pair is Array and (h_pair as Array).size() >= 2:
						h_poly.append(Vector2(float((h_pair as Array)[0]), float((h_pair as Array)[1])))
				if h_poly.size() >= 3:
					holes_list.append(h_poly)

		if poly.size() >= 3:
			add_shape(t_name, poly, holes_list)

## Conversor Retrocompatível: Converte células de grid (0.20m ou 0.80m) em polígonos vetoriais contornados
func convert_from_legacy_field(field: RefCounted, width_blocks: int, height_blocks: int, block_cell_size: float = 0.80) -> void:
	clear()
	if field == null:
		return

	var cols: int = int(field.get("cols"))
	var rows: int = int(field.get("rows"))
	var sub_res: float = 0.20

	# Agrupa retângulos de células contíguas por tipo de planta
	var polys_by_type: Dictionary = {}

	for r: int in range(rows):
		for c: int in range(cols):
			var tid: int = int(field.call("get_cell", c, r))
			if tid == 0:
				continue
			var t_name: String = "grass_green"
			if tid == 2: t_name = "grass_yellow"
			elif tid == 3: t_name = "grass_blue"
			elif tid == 4: t_name = "grass_purple"
			elif tid == 5: t_name = "grass_white"
			elif tid == 6: t_name = "grass_red"
			elif tid == 7: t_name = "grass_black"
			elif tid == 8: t_name = "wheat"

			var wpos: Vector3 = field.call("cell_to_world", c, r, block_cell_size) as Vector3
			var half_s: float = sub_res * 0.505 # Leve sobreposição para merge limpo sem frestas
			var cell_rect_poly: PackedVector2Array = PackedVector2Array([
				Vector2(wpos.x - half_s, wpos.z - half_s),
				Vector2(wpos.x + half_s, wpos.z - half_s),
				Vector2(wpos.x + half_s, wpos.z + half_s),
				Vector2(wpos.x - half_s, wpos.z + half_s)
			])

			if not polys_by_type.has(t_name):
				var arr: Array[PackedVector2Array] = []
				polys_by_type[t_name] = arr

			(polys_by_type[t_name] as Array[PackedVector2Array]).append(cell_rect_poly)

	# Executa união com Clipper por tipo
	for t_name: String in polys_by_type.keys():
		var cell_polys: Array[PackedVector2Array] = polys_by_type[t_name] as Array[PackedVector2Array]
		var merged_set: Array[PackedVector2Array] = []

		for cp: PackedVector2Array in cell_polys:
			if merged_set.is_empty():
				merged_set.append(cp)
				continue
			# Tenta unir com o conjunto acumulado
			var union_step: Array[PackedVector2Array] = []
			var did_merge: bool = false
			for existing: PackedVector2Array in merged_set:
				var m: Array[PackedVector2Array] = Geometry2D.merge_polygons(existing, cp)
				if m.size() == 1:
					union_step.append(m[0])
					did_merge = true
				else:
					union_step.append(existing)
			if not did_merge:
				union_step.append(cp)
			merged_set = union_step

		for final_p: PackedVector2Array in merged_set:
			if final_p.size() >= 3:
				add_shape(t_name, final_p)

# --- Funções Matemáticas Auxiliares Privadas ---

func _compute_poly_aabb(poly: PackedVector2Array) -> Rect2:
	if poly.is_empty():
		return Rect2()
	var min_p: Vector2 = poly[0]
	var max_p: Vector2 = poly[0]
	for i: int in range(1, poly.size()):
		var p: Vector2 = poly[i]
		min_p.x = minf(min_p.x, p.x)
		min_p.y = minf(min_p.y, p.y)
		max_p.x = maxf(max_p.x, p.x)
		max_p.y = maxf(max_p.y, p.y)
	return Rect2(min_p, max_p - min_p)

## Amostragem Poisson Disk (Bridson modificado com busca em grade espacial)
func _sample_poisson_in_polygon(poly: PackedVector2Array, holes_list: Array, min_dist: float, seed_val: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var aabb: Rect2 = _compute_poly_aabb(poly)
	if aabb.size.x <= 0.0 or aabb.size.y <= 0.0:
		return result

	var cell_size: float = min_dist / 1.41421356 # r / sqrt(2)
	var grid_w: int = maxi(1, int(ceilf(aabb.size.x / cell_size)) + 1)
	var grid_h: int = maxi(1, int(ceilf(aabb.size.y / cell_size)) + 1)
	var grid: PackedInt32Array = PackedInt32Array()
	grid.resize(grid_w * grid_h)
	grid.fill(-1)

	var active_list: Array[Vector2] = []
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val

	# Ponto inicial dentro do polígono
	var start_pt: Vector2 = Vector2.ZERO
	var found_start: bool = false
	for attempt: int in range(50):
		var cand: Vector2 = Vector2(
			aabb.position.x + rng.randf() * aabb.size.x,
			aabb.position.y + rng.randf() * aabb.size.y
		)
		if Geometry2D.is_point_in_polygon(cand, poly) and not _is_point_in_any_hole(cand, holes_list):
			start_pt = cand
			found_start = true
			break

	if not found_start:
		return result

	active_list.append(start_pt)
	result.append(start_pt)
	var gx0: int = clampi(int((start_pt.x - aabb.position.x) / cell_size), 0, grid_w - 1)
	var gy0: int = clampi(int((start_pt.y - aabb.position.y) / cell_size), 0, grid_h - 1)
	grid[gy0 * grid_w + gx0] = 0

	const K_CANDIDATES: int = 18
	var min_dist_sq: float = min_dist * min_dist

	while not active_list.is_empty():
		var rand_idx: int = rng.randi_range(0, active_list.size() - 1)
		var base_p: Vector2 = active_list[rand_idx]
		var found_neighbor: bool = false

		for _k: int in range(K_CANDIDATES):
			var angle: float = rng.randf() * TAU
			var dist: float = rng.randf_range(min_dist, min_dist * 2.0)
			var candidate: Vector2 = base_p + Vector2(cos(angle), sin(angle)) * dist

			if not aabb.has_point(candidate):
				continue
			if not Geometry2D.is_point_in_polygon(candidate, poly) or _is_point_in_any_hole(candidate, holes_list):
				continue

			var cgx: int = int((candidate.x - aabb.position.x) / cell_size)
			var cgy: int = int((candidate.y - aabb.position.y) / cell_size)
			if cgx < 0 or cgx >= grid_w or cgy < 0 or cgy >= grid_h:
				continue

			# Checa vizinhança na grade de Poisson (janela 5x5)
			var too_close: bool = false
			var min_x: int = maxi(0, cgx - 2)
			var max_x: int = mini(grid_w - 1, cgx + 2)
			var min_y: int = maxi(0, cgy - 2)
			var max_y: int = mini(grid_h - 1, cgy + 2)

			for ny: int in range(min_y, max_y + 1):
				for nx: int in range(min_x, max_x + 1):
					var existing_idx: int = grid[ny * grid_w + nx]
					if existing_idx != -1:
						var other_p: Vector2 = result[existing_idx]
						if candidate.distance_squared_to(other_p) < min_dist_sq:
							too_close = true
							break
				if too_close:
					break

			if not too_close:
				var new_idx: int = result.size()
				result.append(candidate)
				active_list.append(candidate)
				grid[cgy * grid_w + cgx] = new_idx
				found_neighbor = true
				break

		if not found_neighbor:
			active_list.remove_at(rand_idx)

	return result

func _is_point_in_any_hole(pt: Vector2, holes_list: Array) -> bool:
	for h: Variant in holes_list:
		if h is PackedVector2Array and Geometry2D.is_point_in_polygon(pt, h as PackedVector2Array):
			return true
	return false

func _compute_min_distance_to_polygon_edge(pt: Vector2, poly: PackedVector2Array) -> float:
	var min_d: float = 999.0
	var n: int = poly.size()
	for i: int in range(n):
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % n]
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(pt, a, b)
		var d: float = pt.distance_to(closest)
		if d < min_d:
			min_d = d
	return min_d
