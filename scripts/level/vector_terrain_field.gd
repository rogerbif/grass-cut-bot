class_name VectorTerrainField
extends RefCounted

## Gerenciador e Processador de Terreno da Ilha por Desenho Vetorial 2D (Grass Cut Bot).
## Armazena o contorno perimetral e furos/lagos da ilha no plano XZ (em metros mundo),
## executa operações booleanas de união (adicionar terra) e recorte (borracha/lagos/baías)
## utilizando Clipper C++ via Geometry2D da Godot Engine.

var outer_polygons: Array[PackedVector2Array] = []
var holes: Array[PackedVector2Array] = []

func _init() -> void:
	clear()


func clear() -> void:
	outer_polygons = []
	holes = []


func is_empty() -> bool:
	return outer_polygons.is_empty()


func get_outer_polygons() -> Array[PackedVector2Array]:
	return outer_polygons


func get_holes() -> Array[PackedVector2Array]:
	return holes


func set_outer_polygons(polys: Array[PackedVector2Array]) -> void:
	outer_polygons = []
	for p: PackedVector2Array in polys:
		if p.size() >= 3:
			var clean_p: PackedVector2Array = p
			if not Geometry2D.is_polygon_clockwise(clean_p):
				clean_p.reverse()
			outer_polygons.append(clean_p)


func set_holes(hole_polys: Array[PackedVector2Array]) -> void:
	holes = []
	for h: PackedVector2Array in hole_polys:
		if h.size() >= 3:
			var clean_h: PackedVector2Array = h
			if Geometry2D.is_polygon_clockwise(clean_h):
				clean_h.reverse()
			holes.append(clean_h)


## Clona profundamente este campo de terreno para o histórico Undo/Redo
func duplicate_field() -> VectorTerrainField:
	var clone: VectorTerrainField = VectorTerrainField.new()
	var polys_copy: Array[PackedVector2Array] = []
	for p: PackedVector2Array in outer_polygons:
		polys_copy.append(p.duplicate())
	var holes_copy: Array[PackedVector2Array] = []
	for h: PackedVector2Array in holes:
		holes_copy.append(h.duplicate())
	clone.outer_polygons = polys_copy
	clone.holes = holes_copy
	return clone


## Retorna se um ponto contínuo 2D (X, Z no mundo) está sobre terra firme (dentro da ilha e fora de lagos)
func is_point_on_land(pt: Vector2) -> bool:
	var inside_outer: bool = false
	for p: PackedVector2Array in outer_polygons:
		if p.size() >= 3 and Geometry2D.is_point_in_polygon(pt, p):
			inside_outer = true
			break

	if not inside_outer:
		return false

	for h: PackedVector2Array in holes:
		if h.size() >= 3 and Geometry2D.is_point_in_polygon(pt, h):
			return false

	return true


## Adiciona/funde nova porção de terra à ilha (Pincel de Terreno)
func add_land(new_poly: PackedVector2Array) -> void:
	if new_poly.size() < 3:
		return

	var poly_clean: PackedVector2Array = new_poly
	if not Geometry2D.is_polygon_clockwise(poly_clean):
		poly_clean.reverse()

	# 1. Se o novo terreno sobrepuser algum lago/furo existente, preenche essa porção
	if not holes.is_empty():
		var remaining_holes: Array[PackedVector2Array] = []
		var new_poly_aabb: Rect2 = _compute_aabb(poly_clean)
		for h: PackedVector2Array in holes:
			var h_aabb: Rect2 = _compute_aabb(h)
			if not h_aabb.intersects(new_poly_aabb):
				remaining_holes.append(h)
				continue

			# Clipper clip: corta o furo contra o novo terreno (preenchendo a água)
			var h_cw: PackedVector2Array = h
			if not Geometry2D.is_polygon_clockwise(h_cw):
				h_cw.reverse()
			var clipped_holes: Array[PackedVector2Array] = Geometry2D.clip_polygons(h_cw, poly_clean)
			for ch: PackedVector2Array in clipped_holes:
				if ch.size() >= 3:
					if Geometry2D.is_polygon_clockwise(ch):
						ch.reverse() # Mantém sentido anti-horário padrão para furos
					remaining_holes.append(ch)
		holes = remaining_holes

	# 2. Se a ilha estiver vazia, apenas adiciona o polígono
	if outer_polygons.is_empty():
		outer_polygons.append(poly_clean)
		return

	# 3. Mescla com polígonos externos existentes
	var poly_aabb: Rect2 = _compute_aabb(poly_clean)
	var merged_indices: Array[int] = []
	var accumulated_polys: Array[PackedVector2Array] = [poly_clean]

	for i: int in range(outer_polygons.size()):
		var existing: PackedVector2Array = outer_polygons[i]
		var e_aabb: Rect2 = _compute_aabb(existing)
		if not e_aabb.intersects(poly_aabb.grow(0.05)):
			continue

		var test_intersect: Array[PackedVector2Array] = Geometry2D.intersect_polygons(existing, poly_clean)
		if not test_intersect.is_empty():
			merged_indices.append(i)
			accumulated_polys.append(existing)

	if merged_indices.is_empty():
		outer_polygons.append(poly_clean)
		return

	# Recompõe outer_polygons unindo as partes sobrepostas
	var unaffected_polys: Array[PackedVector2Array] = []
	for i: int in range(outer_polygons.size()):
		if not merged_indices.has(i):
			unaffected_polys.append(outer_polygons[i])

	var union_result: Array[PackedVector2Array] = [accumulated_polys[0]]
	for idx: int in range(1, accumulated_polys.size()):
		var to_merge: PackedVector2Array = accumulated_polys[idx]
		var next_step: Array[PackedVector2Array] = []
		var did_merge: bool = false
		for base_p: PackedVector2Array in union_result:
			var res: Array[PackedVector2Array] = Geometry2D.merge_polygons(base_p, to_merge)
			if res.size() == 1:
				to_merge = res[0]
				did_merge = true
			else:
				next_step.append(base_p)
		next_step.append(to_merge)
		if did_merge and next_step.size() > 1:
			union_result = _reduce_overlapping_polygons(next_step)
		else:
			union_result = next_step

	for up: PackedVector2Array in union_result:
		if up.size() >= 3:
			if not Geometry2D.is_polygon_clockwise(up):
				up.reverse()
			unaffected_polys.append(up)

	outer_polygons = _reduce_overlapping_polygons(unaffected_polys)


## Recorta terra / abre água (Borracha de Terreno, lagos, canais e baías)
func carve_water(cutter_poly: PackedVector2Array) -> void:
	if cutter_poly.size() < 3 or outer_polygons.is_empty():
		return

	var cutter_clean: PackedVector2Array = cutter_poly
	if not Geometry2D.is_polygon_clockwise(cutter_clean):
		cutter_clean.reverse()

	var cutter_aabb: Rect2 = _compute_aabb(cutter_clean)
	var new_outer: Array[PackedVector2Array] = []

	for p: PackedVector2Array in outer_polygons:
		var p_aabb: Rect2 = _compute_aabb(p)
		if not p_aabb.intersects(cutter_aabb):
			new_outer.append(p)
			continue

		var test_intersect: Array[PackedVector2Array] = Geometry2D.intersect_polygons(p, cutter_clean)
		if test_intersect.is_empty():
			new_outer.append(p)
			continue

		# Executa recorte com Clipper
		var clipped_parts: Array[PackedVector2Array] = Geometry2D.clip_polygons(p, cutter_clean)
		for cp: PackedVector2Array in clipped_parts:
			if cp.size() >= 3:
				if not Geometry2D.is_polygon_clockwise(cp):
					cp.reverse()
				new_outer.append(cp)

	outer_polygons = _reduce_overlapping_polygons(new_outer)

	# Se houver furos que agora ficaram fora de qualquer terra firme, limpa-os
	if not holes.is_empty():
		var valid_holes: Array[PackedVector2Array] = []
		for h: PackedVector2Array in holes:
			var h_center: Vector2 = _compute_poly_center(h)
			if _is_point_in_any_outer(h_center):
				valid_holes.append(h)
		holes = valid_holes


## Converte uma grade de tiles legada ({gx, gz}) em polígonos vetoriais contínuos
func convert_from_tile_grid(
	terrain_list: Array,
	width: int,
	height: int,
	cell_size: float = 0.80,
	corner_radius: float = 0.28,
	arc_steps: int = 5
) -> void:
	clear()
	var polys: Array[PackedVector2Array] = IslandMeshBuilder.convert_tile_grid_to_polygons(
		terrain_list, width, height, cell_size, corner_radius, arc_steps
	)
	set_outer_polygons(polys)


## Converte para Dicionário pronto para gravação em JSON
func to_dict() -> Dictionary:
	var polys_data: Array = []
	for p: PackedVector2Array in outer_polygons:
		var pts: Array = []
		for pt: Vector2 in p:
			pts.append([snappedf(pt.x, 0.001), snappedf(pt.y, 0.001)])
		polys_data.append(pts)

	var holes_data: Array = []
	for h: PackedVector2Array in holes:
		var h_pts: Array = []
		for pt: Vector2 in h:
			h_pts.append([snappedf(pt.x, 0.001), snappedf(pt.y, 0.001)])
		holes_data.append(h_pts)

	return {
		"island_polygons": polys_data,
		"island_holes": holes_data
	}


## Carrega estado a partir de um Dicionário JSON ou lista de polígonos
func from_dict(data: Dictionary) -> void:
	clear()
	if data.has("island_polygons") and data["island_polygons"] is Array:
		var raw_list: Array = data["island_polygons"] as Array
		var loaded_polys: Array[PackedVector2Array] = []
		for item: Variant in raw_list:
			if item is Array:
				var pts: PackedVector2Array = PackedVector2Array()
				for pt_var: Variant in (item as Array):
					if pt_var is Array and (pt_var as Array).size() >= 2:
						var pt_arr: Array = pt_var as Array
						pts.append(Vector2(float(pt_arr[0]), float(pt_arr[1])))
				if pts.size() >= 3:
					loaded_polys.append(pts)
		set_outer_polygons(loaded_polys)

	if data.has("island_holes") and data["island_holes"] is Array:
		var raw_holes: Array = data["island_holes"] as Array
		var loaded_holes: Array[PackedVector2Array] = []
		for item: Variant in raw_holes:
			if item is Array:
				var pts: PackedVector2Array = PackedVector2Array()
				for pt_var: Variant in (item as Array):
					if pt_var is Array and (pt_var as Array).size() >= 2:
						var pt_arr: Array = pt_var as Array
						pts.append(Vector2(float(pt_arr[0]), float(pt_arr[1])))
				if pts.size() >= 3:
					loaded_holes.append(pts)
		set_holes(loaded_holes)


## Helpers geométricos internos
static func _compute_aabb(poly: PackedVector2Array) -> Rect2:
	if poly.is_empty():
		return Rect2()
	var min_pt: Vector2 = poly[0]
	var max_pt: Vector2 = poly[0]
	for i in range(1, poly.size()):
		var p: Vector2 = poly[i]
		min_pt.x = minf(min_pt.x, p.x)
		min_pt.y = minf(min_pt.y, p.y)
		max_pt.x = maxf(max_pt.x, p.x)
		max_pt.y = maxf(max_pt.y, p.y)
	return Rect2(min_pt, max_pt - min_pt)


static func _compute_poly_center(poly: PackedVector2Array) -> Vector2:
	if poly.is_empty():
		return Vector2.ZERO
	var sum: Vector2 = Vector2.ZERO
	for pt: Vector2 in poly:
		sum += pt
	return sum / float(poly.size())


func _is_point_in_any_outer(pt: Vector2) -> bool:
	for p: PackedVector2Array in outer_polygons:
		if p.size() >= 3 and Geometry2D.is_point_in_polygon(pt, p):
			return true
	return false


static func _reduce_overlapping_polygons(polys: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	if polys.size() <= 1:
		return polys

	var current: Array[PackedVector2Array] = polys.duplicate()
	var changed: bool = true
	var max_passes: int = 10
	var current_pass: int = 0

	while changed and current_pass < max_passes:
		changed = false
		current_pass += 1
		var n: int = current.size()
		var merged: Array[PackedVector2Array] = []
		var skip: Array[bool] = []
		skip.resize(n)
		skip.fill(false)

		for i: int in range(n):
			if skip[i]:
				continue
			var cur_p: PackedVector2Array = current[i]
			for j: int in range(i + 1, n):
				if skip[j]:
					continue
				var other_p: PackedVector2Array = current[j]
				var aabb_a: Rect2 = _compute_aabb(cur_p)
				var aabb_b: Rect2 = _compute_aabb(other_p)
				if not aabb_a.intersects(aabb_b.grow(0.02)):
					continue

				var res: Array[PackedVector2Array] = Geometry2D.merge_polygons(cur_p, other_p)
				if res.size() == 1:
					cur_p = res[0]
					skip[j] = true
					changed = true

			merged.append(cur_p)
		current = merged

	return current
