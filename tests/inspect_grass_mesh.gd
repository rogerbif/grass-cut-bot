extends SceneTree

func _init() -> void:
	var packed: PackedScene = load("res://assets/models/wheat_01.glb")
	if packed == null:
		print("Erro ao carregar wheat_01.glb")
		quit()
		return
	var inst: Node = packed.instantiate()
	var mi: MeshInstance3D = null
	for child in inst.get_children():
		if child is MeshInstance3D:
			mi = child
			break
	if mi == null:
		print("Nenhum MeshInstance3D em wheat")
		quit()
		return
	var mesh: Mesh = mi.mesh
	var arrays: Array = mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	print("Wheat Verts total: ", verts.size())
	print("Wheat Tem colors? ", colors != null and colors.size() > 0)
	print("Wheat Tem uvs? ", uvs != null and uvs.size() > 0)
	if colors != null and colors.size() > 0:
		for i in [0, 10, 50, 100, 200]:
			if i < colors.size():
				print("Wheat Vert[%d] pos: %s, col: %s, uv: %s" % [i, verts[i], colors[i], uvs[i] if uvs != null else "none"])
	quit()
