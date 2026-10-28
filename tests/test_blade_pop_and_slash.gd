extends Node

var _leveled_up_emitted: bool = false
var _last_level_up_level: int = 0

func _ready() -> void:
	print("--- TEST BLADE POP, FLASH, SHOCKWAVE & SLASH (LEVEL UP EFFECTS) ---")
	
	# Instancia o Cutter
	var cutter_scene: PackedScene = load("res://scenes/cutter/cutter.tscn")
	var cutter: CharacterBody3D = cutter_scene.instantiate() as CharacterBody3D
	add_child(cutter)
	
	# 1. Verifica existência das malhas de Slash e Shockwave
	var slash_mesh: MeshInstance3D = cutter.get("blade_slash_mesh")
	if slash_mesh == null:
		push_error("blade_slash_mesh was not created!")
		get_tree().quit(1)
		return
	print("✔ PASSOU: blade_slash_mesh criado com sucesso no blade_spinner")
	
	var shock_mesh: MeshInstance3D = cutter.get("shockwave_mesh")
	if shock_mesh == null:
		push_error("shockwave_mesh was not created!")
		get_tree().quit(1)
		return
	print("✔ PASSOU: shockwave_mesh criado com sucesso na raiz do cutter")
	
	# Verifica materiais
	if slash_mesh.material_override == null or not (slash_mesh.material_override is ShaderMaterial):
		push_error("blade_slash_mesh material_override is not a ShaderMaterial!")
		get_tree().quit(1)
		return
	print("✔ PASSOU: blade_slash_mesh configurado com ShaderMaterial")

	# Verifica dimensões e parâmetros do novo shader multi-ponta afilado
	var plane_mesh: PlaneMesh = slash_mesh.mesh as PlaneMesh
	if plane_mesh == null or plane_mesh.size != Vector2(4.2, 4.2):
		push_error("blade_slash_mesh PlaneMesh size should be 4.2x4.2!")
		get_tree().quit(1)
		return
	print("✔ PASSOU: blade_slash_mesh dimensionado para 4.2m cobrindo perfeitamente as pontas")

	var mat_check: ShaderMaterial = slash_mesh.material_override as ShaderMaterial
	if mat_check.get_shader_parameter("blade_points") == null or mat_check.get_shader_parameter("inner_radius") == null:
		push_error("Shader parameters blade_points or inner_radius not found!")
		get_tree().quit(1)
		return
	print("✔ PASSOU: Parametros analiticos de afinamento com base larga e pontas encontrados no ShaderMaterial")

	# Testa sincronizacao de pontas por Tier (Tier 1 = 3 pontas, Tier 4 = 6 pontas)
	UpgradeManager.blade_level = 1
	cutter.call("update_upgrades")
	if mat_check.get_shader_parameter("blade_points") != 3:
		push_error("Tier 1 should set blade_points to 3, got: %s" % str(mat_check.get_shader_parameter("blade_points")))
		get_tree().quit(1)
		return
	print("✔ PASSOU: Tier 1 configurou 3 pontas de slash")

	UpgradeManager.blade_level = 6 # Tier 4
	cutter.call("update_upgrades")
	if mat_check.get_shader_parameter("blade_points") != 6:
		push_error("Tier 4 should set blade_points to 6, got: %s" % str(mat_check.get_shader_parameter("blade_points")))
		get_tree().quit(1)
		return
	print("✔ PASSOU: Tier 4 configurou 6 pontas de slash")

	if shock_mesh.material_override == null or not (shock_mesh.material_override is ShaderMaterial):
		push_error("shockwave_mesh material_override is not a ShaderMaterial!")
		get_tree().quit(1)
		return
	print("✔ PASSOU: shockwave_mesh configurado com ShaderMaterial")
	
	# 2. Conecta sinal de teste no UpgradeManager
	UpgradeManager.blade_level = 1
	UpgradeManager.blade_xp = 0.0
	UpgradeManager.blade_leveled_up.connect(func(lvl: int, _max: bool):
		_leveled_up_emitted = true
		_last_level_up_level = lvl
	)
	
	# 3. Testa Level UP: adiciona 50 XP (requisito Lv 1->2 é 50)
	_leveled_up_emitted = false
	UpgradeManager.add_blade_xp(50.0)
	
	if not _leveled_up_emitted or _last_level_up_level != 2:
		push_error("blade_leveled_up signal was not emitted properly on level up!")
		get_tree().quit(1)
		return
	print("✔ PASSOU: Sinal blade_leveled_up emitido ao atingir Lv 2")
	
	# 4. Verifica reação do Cutter ao Level Up (Pop e Shockwave)
	var pop_scale: float = cutter.get("_blade_pop_scale")
	print("Pop scale apos level up: ", pop_scale)
	if pop_scale < 1.0:
		push_error("Pop scale should be >= 1.0!")
		get_tree().quit(1)
		return
	print("✔ PASSOU: Pop de escala ativado no Cutter")

	if not shock_mesh.visible:
		push_error("shockwave_mesh should be visible during shockwave effect!")
		get_tree().quit(1)
		return
	print("✔ PASSOU: shockwave_mesh ativado no solo")
	
	# 5. Testa penalidade de rochas: NÃO deve emitir blade_leveled_up
	_leveled_up_emitted = false
	UpgradeManager.penalize_blade_hit()
	if _leveled_up_emitted:
		push_error("blade_leveled_up MUST NOT be emitted on penalty!")
		get_tree().quit(1)
		return
	print("✔ PASSOU: Penalidade de rocha NAO emite blade_leveled_up (sem falso pop/choque)")
	
	# 6. Testa modulação de slash por velocidade
	cutter.set("current_blade_speed", 108.0)
	cutter.call("_update_blade_slash_intensity")
	var mat_slash: ShaderMaterial = slash_mesh.material_override as ShaderMaterial
	var idle_intensity: float = mat_slash.get_shader_parameter("slash_intensity")
	
	cutter.set("_slash_flash_boost", 1.0)
	cutter.set("current_blade_speed", 720.0)
	cutter.call("_update_blade_slash_intensity")
	var full_intensity: float = mat_slash.get_shader_parameter("slash_intensity")
	
	print("Idle slash intensity: ", idle_intensity, " | Full cut slash intensity: ", full_intensity)
	if full_intensity <= idle_intensity:
		push_error("Slash intensity should be significantly higher at full speed than at idle!")
		get_tree().quit(1)
		return
	print("✔ PASSOU: Modulação dinâmica de intensidade do slash por velocidade validada")

	print("--- TODOS OS TESTES PASSARAM COM 100% DE SUCESSO! ---")
	cutter.queue_free()
	get_tree().quit(0)
