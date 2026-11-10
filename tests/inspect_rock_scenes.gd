extends SceneTree

func _init() -> void:
	print("--- COMPARANDO ROCK vs ROCK_MOSS ---")
	var sc_old: PackedScene = load("res://assets/models/rock.glb") as PackedScene
	var sc_new: PackedScene = load("res://assets/models/rock_moss.glb") as PackedScene
	
	var inst_old: Node3D = sc_old.instantiate() as Node3D
	var inst_new: Node3D = sc_new.instantiate() as Node3D
	
	print("OLD: ", inst_old)
	_dump(inst_old, "  ")
	print("NEW: ", inst_new)
	_dump(inst_new, "  ")
	quit(0)

func _dump(n: Node, indent: String) -> void:
	print(indent, n.name, " class=", n.get_class())
	if n is Node3D:
		var n3d: Node3D = n as Node3D
		print(indent, "  visible=", n3d.visible, " transform=", n3d.transform)
	if n is VisualInstance3D:
		var vi: VisualInstance3D = n as VisualInstance3D
		print(indent, "  layers=", vi.layers)
	if n is MeshInstance3D:
		var mi: MeshInstance3D = n as MeshInstance3D
		print(indent, "  mesh=", mi.mesh, " skin=", mi.skin, " skeleton=", mi.skeleton)
		if mi.mesh:
			print(indent, "  aabb=", mi.mesh.get_aabb())
			for s in range(mi.mesh.get_surface_count()):
				print(indent, "  surf ", s, " mat=", mi.mesh.surface_get_material(s))
	for c in n.get_children():
		_dump(c, indent + "  ")
