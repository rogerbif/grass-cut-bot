extends Node

func _ready() -> void:
	print("--- TEST CAMERA ZOOM LEVELS (LV 2 TO LV 5 RANGE) ---")
	var cam_script: GDScript = load("res://scripts/camera/isometric_camera.gd")
	var cam: Camera3D = Camera3D.new()
	cam.set_script(cam_script)
	
	var base_canonical: Vector3 = cam.get("base_canonical_offset")
	var full_dist: float = base_canonical.length()
	print("Base canonical distance: ", full_dist)
	
	# Level 1 offset and distance
	var off_lv1: Vector3 = cam.get_target_offset_for_level(1)
	var dist_lv1: float = off_lv1.length()
	print("Lv 1 (Inicial): dist = ", dist_lv1, " | offset = ", off_lv1)
	
	# Level 6 offset and distance
	var off_lv6: Vector3 = cam.get_target_offset_for_level(6)
	var dist_lv6: float = off_lv6.length()
	print("Lv 6 (Final/MAX): dist = ", dist_lv6, " | offset = ", off_lv6)
	
	# Verify Lv 1 corresponds to 60% of base canonical (which was Level 2 distance)
	var expected_lv1_ratio: float = 0.60
	var actual_lv1_ratio: float = dist_lv1 / full_dist
	print("Lv 1 ratio: ", actual_lv1_ratio, " (expected: ", expected_lv1_ratio, ")")
	if absf(actual_lv1_ratio - expected_lv1_ratio) > 0.001:
		push_error("Lv 1 zoom distance is not equal to Level 2 (60%)!")
		get_tree().quit(1)
		return
		
	# Verify Lv 6 corresponds to 90% of base canonical (which was Level 5 distance)
	var expected_lv6_ratio: float = 0.90
	var actual_lv6_ratio: float = dist_lv6 / full_dist
	print("Lv 6 ratio: ", actual_lv6_ratio, " (expected: ", expected_lv6_ratio, ")")
	if absf(actual_lv6_ratio - expected_lv6_ratio) > 0.001:
		push_error("Lv 6 zoom distance is not equal to Level 5 (90%)!")
		get_tree().quit(1)
		return
		
	for lvl in range(1, 7):
		var off: Vector3 = cam.get_target_offset_for_level(lvl)
		print("Level ", lvl, ": dist = ", snappedf(off.length(), 0.01), "m, offset = ", off)

	print("✔ TODOS OS TESTES DE ZOOM DA CÂMERA PASSARAM COM SUCESSO!")
	cam.free()
	get_tree().quit(0)
