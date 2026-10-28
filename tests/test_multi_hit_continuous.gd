extends Node3D

const VegetationGridScript = preload("res://scripts/plants/vegetation_grid.gd")
const CutterScript = preload("res://scripts/cutter/cutter.gd")

func _ready() -> void:
	print("--- TEST MULTI-HIT CONTINUOUS START ---")

	# 1. Verifica constante de cooldown calibrada para 0.28s
	var vg: Node3D = VegetationGridScript.new() as Node3D
	add_child(vg)
	assert(vg.get("MULTI_HIT_COOLDOWN_SEC") == 0.28, "MULTI_HIT_COOLDOWN_SEC deve ser 0.28")
	print("MULTI_HIT_COOLDOWN_SEC validado: 0.28s")

	# 1.1. Verifica sincronizacao dinamica de versao com project.godot
	var expected_ver: String = "v" + String(ProjectSettings.get_setting("application/config/version"))
	var ver_str: String = GameVersion.get_version_string()
	var disp_str: String = GameVersion.get_display_name()
	print("GameVersion string: ", ver_str)
	print("GameVersion display: ", disp_str)
	assert(ver_str == expected_ver, "GameVersion deve refletir a versao do project.godot (%s vs %s)" % [ver_str, expected_ver])
	assert(disp_str.contains(expected_ver), "Display name deve conter a versao atual")

	# 2. Verifica ausência de knockback e stun no cortador ao colidir com vegetação
	var cutter_scene: PackedScene = preload("res://scenes/cutter/cutter.tscn")
	var cutter: CharacterBody3D = cutter_scene.instantiate() as CharacterBody3D
	add_child(cutter)
	cutter.velocity = Vector3(2.5, 0.0, 1.0)
	cutter.is_stunned = false
	cutter.call("_trigger_plant_first_hit_knockback", Vector3(1.0, 0.0, 0.0))

	assert(cutter.is_stunned == false, "O cortador NAO deve entrar em estado is_stunned em plantas")
	assert(cutter.velocity == Vector3(2.5, 0.0, 1.0), "A velocidade do cortador NAO deve sofrer knockback reverso em plantas")
	assert(cutter.shock_compression < 0.0, "Deve haver leve compressao mecanica na suspensao")
	print("Comportamento do cortador contra plantas validado com sucesso (zero stun, zero knockback)")

	print("--- TEST MULTI-HIT CONTINUOUS SUCCESS! ---")
	get_tree().quit(0)
