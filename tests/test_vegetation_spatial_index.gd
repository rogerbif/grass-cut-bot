extends Node3D

## Teste de equivalência do índice espacial do VegetationGrid (Pacote 3).
## Varre cut_in_circle em sequência determinística e resolve_rigid_plant_collision em
## posições de borda, imprimindo linhas "GOLDEN|..." para comparação entre versões do código.
## Execução: godot --headless --quit-after 600 res://tests/test_vegetation_spatial_index.tscn

const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")
const VegetationGridScript = preload("res://scripts/plants/vegetation_grid.gd")

const LEVELS: Array[int] = [1, 3, 12, 20, 40]
const GOLDEN_PATH: String = "res://tests/golden_vegetation_spatial_index.txt"

var _lines: PackedStringArray = PackedStringArray()


func _ready() -> void:
	print("--- TEST VEGETATION SPATIAL INDEX START ---")
	# Lâmina no nível máximo: add_blade_xp retorna cedo (sem XP e sem gravação em disco).
	UpgradeManager.load_from_dict({"blade_level": 10, "blade_xp": 0.0}, 0)
	GameManager.current_state = GameManager.GameState.PLAYING

	for lvl: int in LEVELS:
		_run_level(lvl)

	_finish()


func _emit(line: String) -> void:
	_lines.append(line)
	print(line)


func _finish() -> void:
	if OS.get_cmdline_user_args().has("write-golden"):
		var fw: FileAccess = FileAccess.open(ProjectSettings.globalize_path(GOLDEN_PATH), FileAccess.WRITE)
		fw.store_string("\n".join(_lines) + "\n")
		fw.close()
		print("GOLDEN_RESULT|WRITTEN|%d linhas" % _lines.size())
		get_tree().quit(0)
		return
	var fr: FileAccess = FileAccess.open(GOLDEN_PATH, FileAccess.READ)
	if fr == null:
		printerr("GOLDEN_RESULT|FAIL|arquivo golden ausente")
		get_tree().quit(1)
		return
	var expected: PackedStringArray = fr.get_as_text().strip_edges().split("\n")
	fr.close()
	var ok: bool = expected.size() == _lines.size()
	for i: int in range(mini(expected.size(), _lines.size())):
		if expected[i].strip_edges() != _lines[i].strip_edges():
			printerr("GOLDEN_RESULT|DIFF|linha %d" % i)
			printerr("  esperado: %s" % expected[i])
			printerr("  obtido:   %s" % _lines[i])
			ok = false
	print("GOLDEN_RESULT|%s" % ("PASS" if ok else "FAIL"))
	get_tree().quit(0 if ok else 1)


func _run_level(lvl: int) -> void:
	var path: String = "res://data/levels/level_%02d.json" % lvl
	var data: Dictionary = LevelJsonLoader.load_json_file(path)
	if data.is_empty():
		_emit("GOLDEN|level_%02d|MISSING" % lvl)
		return

	var vg: Node3D = VegetationGridScript.new() as Node3D
	add_child(vg)
	vg.call("build_from_level_json", data, null, null)
	var total: int = int(vg.call("get_total_tufts"))

	# 1) Colisão rígida com todas as plantas vivas, inclusive fora dos limites da grade.
	var coll_text: String = ""
	var cx: float = -14.0
	while cx <= 14.0:
		var cz: float = -14.0
		while cz <= 14.0:
			var res: Dictionary = vg.call("resolve_rigid_plant_collision", Vector3(cx, 0.0, cz), Vector3(1.0, 0.0, 0.5), 0.3) as Dictionary
			var rp: Vector3 = res["position"] as Vector3
			var rv: Vector3 = res["velocity"] as Vector3
			coll_text += "%.4f,%.4f,%.4f,%.4f;" % [rp.x, rp.z, rv.x, rv.z]
			cz += 1.3
		cx += 1.3
	for far: Vector3 in [Vector3(500, 0, 500), Vector3(-500, 0, -500), Vector3(0, 0, 900), Vector3(-900, 0, 0)]:
		var res_far: Dictionary = vg.call("resolve_rigid_plant_collision", far, Vector3.ZERO, 0.3) as Dictionary
		var fp: Vector3 = res_far["position"] as Vector3
		coll_text += "%.4f,%.4f;" % [fp.x, fp.z]

	# 2) Varredura de corte determinística. power = 3 mata qualquer planta em 1 golpe,
	#    eliminando a dependência do cooldown em tempo real dos multi-hits.
	var seq_hash: int = 7
	var cut_calls: int = 0
	var step: int = 0
	var x: float = -13.0
	while x <= 13.0:
		var z: float = -13.0
		while z <= 13.0:
			var before: PackedByteArray = (vg.get("_is_cut") as PackedByteArray).duplicate()
			var radius: float = 0.9 + float(step % 6) * 0.1
			vg.call("cut_in_circle", Vector3(x, 0.0, z), radius, 3)
			var after: PackedByteArray = vg.get("_is_cut") as PackedByteArray
			for i: int in range(total):
				if before[i] != after[i]:
					seq_hash = (seq_hash * 31 + i + 1) % 2147483647
					cut_calls += 1
			seq_hash = (seq_hash * 31 + step) % 2147483647
			step += 1
			z += 0.9
		x += 0.9

	var cut_total: int = 0
	var is_cut: PackedByteArray = vg.get("_is_cut") as PackedByteArray
	for i: int in range(total):
		cut_total += int(is_cut[i])

	_emit("GOLDEN|level_%02d|tufts=%d|cut_total=%d|cut_events=%d|seq_hash=%d" % [lvl, total, cut_total, cut_calls, seq_hash])
	_emit("GOLDEN|level_%02d|clip_counts=%s|rem_grass=%s" % [lvl, str(vg.get("_clipping_counts")), str(vg.get("_remaining_grass_by_type"))])
	_emit("GOLDEN|level_%02d|rem_phys=%d/%d/%d|coll_hash=%d" % [
		lvl,
		int(vg.get("_remaining_physical_grass")),
		int(vg.get("_remaining_physical_wheat")),
		int(vg.get("_remaining_physical_flower")),
		coll_text.hash()
	])

	# 3) reset_all_plants deve restaurar o estado inicial por completo.
	vg.call("reset_all_plants")
	var after_reset: PackedByteArray = vg.get("_is_cut") as PackedByteArray
	var cut_after_reset: int = 0
	for i: int in range(total):
		cut_after_reset += int(after_reset[i])
	_emit("GOLDEN|level_%02d|after_reset_cut=%d|after_reset_clip=%s" % [lvl, cut_after_reset, str(vg.get("_clipping_counts"))])

	vg.queue_free()
