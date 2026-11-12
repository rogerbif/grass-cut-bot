extends Node

## Pacote 0: linha de base de custo do Herbário (CPU: construção e layout).
## Não mede desenho nem FPS reais; isso exige o aparelho (Remote Debugger).

func _count_nodes(n: Node) -> int:
	var c: int = 1
	for ch: Node in n.get_children():
		c += _count_nodes(ch)
	return c

func _collect_styles(n: Node, seen: Dictionary) -> void:
	if n is Control:
		var ctl: Control = n as Control
		for slot: String in ["panel", "background", "fill", "normal", "hover", "pressed"]:
			if ctl.has_theme_stylebox_override(slot):
				var sb: StyleBox = ctl.get_theme_stylebox(slot)
				seen[sb.get_instance_id()] = true
	for ch: Node in n.get_children():
		_collect_styles(ch, seen)

func _ready() -> void:
	print("--- PERFORMANCE DO HERBÁRIO (Pacote 0) ---")
	var save_mgr: Node = get_node_or_null("/root/SaveManager")
	assert(save_mgr != null, "SaveManager deve existir como autoload")
	save_mgr.reset_to_defaults()
	# Estado realista: espécies descobertas, algumas com marcos prontos
	save_mgr.record_plant_harvest("grass_green", 600)
	save_mgr.record_plant_harvest("grass_yellow", 80)
	save_mgr.record_plant_harvest("wheat", 120)
	save_mgr.record_plant_harvest("flower_rose", 40)
	save_mgr.record_plant_harvest("flower_daisy", 15)

	var scene: PackedScene = load("res://scenes/menu/tabs/tab_collection.tscn")
	var t0: int = Time.get_ticks_usec()
	var tab: Control = scene.instantiate() as Control
	add_child(tab)
	var first_ms: float = float(Time.get_ticks_usec() - t0) / 1000.0

	var cards: VBoxContainer = tab.get_node("Panel/MainVBox/Scroll/CardsMargin/CardsVBox") as VBoxContainer
	var runs: int = 10
	var t1: int = Time.get_ticks_usec()
	for i: int in range(runs):
		tab.call("refresh_cards")
	var avg_refresh_ms: float = float(Time.get_ticks_usec() - t1) / 1000.0 / float(runs)

	var styles: Dictionary = {}
	_collect_styles(tab, styles)

	# Resgate de 1 marco (grass_green nível 1 = 50 colheitas)
	var t2: int = Time.get_ticks_usec()
	tab.call("_on_claim_milestone_pressed", "grass_green", 1, 15)
	var claim_ms: float = float(Time.get_ticks_usec() - t2) / 1000.0

	# Medição do tempo de alternância de filtros (Pacote 3)
	var filter_list: Array[String] = ["grass", "crop", "flower", "claimable", "all"]
	var t3: int = Time.get_ticks_usec()
	var filter_switches: int = 50
	for i: int in range(filter_switches):
		var target_fid: String = filter_list[i % filter_list.size()]
		tab.call("_on_filter_selected", target_fid)
	var avg_filter_switch_ms: float = float(Time.get_ticks_usec() - t3) / 1000.0 / float(filter_switches)

	print("PERF cards=%d" % cards.get_child_count())
	print("PERF nodes=%d" % _count_nodes(tab))
	print("PERF unique_styleboxes=%d" % styles.size())
	print("PERF first_build_ms=%.2f" % first_ms)
	print("PERF avg_refresh_cards_ms=%.2f" % avg_refresh_ms)
	print("PERF avg_filter_switch_ms=%.3f" % avg_filter_switch_ms)
	print("PERF claim_one_milestone_ms=%.2f" % claim_ms)

	assert(cards.get_child_count() == 36, "Deve haver 36 cards instanciados")
	tab.queue_free()
	await get_tree().create_timer(0.5).timeout
	get_tree().quit(0)
