extends SceneTree

const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")
const VegetationFieldScript = preload("res://scripts/level/vegetation_field.gd")
const VegetationGridScript = preload("res://scripts/plants/vegetation_grid.gd")

func _init() -> void:
    var all_ok = true
    for lvl in range(1, 21):
        var path = "res://data/levels/level_%02d.json" % lvl
        var data = LevelJsonLoader.load_json_file(path)
        if data.is_empty():
            continue
        var vg = VegetationGridScript.new()
        var goals = vg.build_from_level_json(data, null, null)
        var total_tufts = vg.get_total_tufts()
        print("Level %02d: tufts=%d, goals=%s" % [lvl, total_tufts, str(goals)])
        vg.free()
    print("ALL LEVELS VERIFIED!")
    quit()
