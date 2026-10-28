extends Node3D

func _ready() -> void:
	print("--- TEST ISLAND NODE LEVEL 4 ---")
	var island_scene: PackedScene = load("res://scenes/menu/island_node.tscn")
	var island: Node3D = island_scene.instantiate()
	add_child(island)
	island.call("setup_island", 4, true, 0)
	island.call("ensure_content_loaded")
	island.call("set_view_mode", false, true, false) # BOT_VIEW mode (Home view)

	var veg_container: Node = island.get_node_or_null("MiniatureContainer/Veg3DContainer")
	if veg_container != null:
		print("Veg3DContainer found! Children count: ", veg_container.get_child_count())
		for child in veg_container.get_children():
			if child is MultiMeshInstance3D:
				var mmi = child as MultiMeshInstance3D
				print("  Child: ", mmi.name)
				var mm = mmi.multimesh
				if mm != null and mm.mesh != null:
					print("    Instances: ", mm.instance_count)
					print("    Mesh: ", mm.mesh.resource_path, " (", mm.mesh, ")")
					for s in range(mm.mesh.get_surface_count()):
						var mat = mm.mesh.surface_get_material(s)
						print("      Surface ", s, " Material: ", mat)
						if mat is ShaderMaterial:
							print("        Shader: ", (mat as ShaderMaterial).shader.resource_path)
							print("        petal_color: ", (mat as ShaderMaterial).get_shader_parameter("petal_color"))
							print("        center_color: ", (mat as ShaderMaterial).get_shader_parameter("center_color"))
	else:
		print("ERROR: Veg3DContainer not found!")

	get_tree().quit(0)
