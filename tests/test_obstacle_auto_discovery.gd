extends SceneTree

const ObstacleDatabase = preload("res://scripts/obstacles/obstacle_database.gd")
const TilePaletteDB = preload("res://scripts/editor/tile_palette_db.gd")
const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")
const RockDataScript = preload("res://scripts/obstacles/rock_data.gd")

const TEST_ROCK_PATH: String = "res://data/obstacles/test_crystal_rock.tres"

func _init() -> void:
	print("--- TESTE DE AUTO-DESCOBERTA DINÂMICA DE OBSTÁCULOS E ROCHAS ---")

	# 1. Validar estado canônico inicial (6 variantes)
	var initial_obs: Array[RockData] = ObstacleDatabase.get_all_obstacles()
	print("Passo 1: Estado inicial com %d obstáculos registrados." % initial_obs.size())
	assert(initial_obs.size() == 6, "Esperado exatamente 6 variantes iniciais!")
	assert(ObstacleDatabase.has_obstacle("rock"), "Deve conter 'rock'")
	assert(ObstacleDatabase.has_obstacle("rock_slate"), "Deve resolver alias 'rock_slate'")
	assert(ObstacleDatabase.has_obstacle("rock_moss"), "Deve conter 'rock_moss'")
	assert(ObstacleDatabase.has_obstacle("rock_spire"), "Deve conter 'rock_spire'")
	assert(ObstacleDatabase.has_obstacle("rock_moss_spire"), "Deve conter 'rock_moss_spire'")
	assert(ObstacleDatabase.has_obstacle("rock_sandstone"), "Deve conter 'rock_sandstone'")
	assert(ObstacleDatabase.has_obstacle("rock_boulder"), "Deve conter 'rock_boulder'")

	var initial_palette_vars: Array = TilePaletteDB.get_variations("rock")
	assert(initial_palette_vars.size() == 6, "TilePaletteDB deve reportar 6 variações para 'rock'")
	print("✔ Passo 1: Estado inicial validado com 6 variantes e aliases perfeitos.")

	# 2. Criar dinamicamente novo recurso de rocha em tempo de execução
	var test_rock: RockData = RockDataScript.new()
	test_rock.id = "rock_crystal"
	test_rock.aliases = PackedStringArray(["crystal_rock"])
	test_rock.name = "Cristal"
	test_rock.full_name = "Rocha de Cristal Cósmico"
	test_rock.icon = "💎"
	test_rock.color = Color(0.2, 0.9, 0.95, 1.0)
	test_rock.category = "obstacle"
	test_rock.collision_radius = 0.25
	test_rock.collision_height = 0.9
	test_rock.clearance_radius = 0.90
	test_rock.xp_penalty = 1200
	test_rock.mesh_path = "res://assets/models/rock.glb"
	test_rock.material_path = "res://shaders/rock_toon_material.tres"

	var save_err: Error = ResourceSaver.save(test_rock, TEST_ROCK_PATH)
	assert(save_err == OK, "Erro ao gravar arquivo de teste .tres em %s" % TEST_ROCK_PATH)
	print("✔ Passo 2: Novo arquivo 'test_crystal_rock.tres' gravado com sucesso.")

	# 3. Forçar reload do ObstacleDatabase e validar assimilação dinâmica
	ObstacleDatabase.reload()

	var updated_obs: Array[RockData] = ObstacleDatabase.get_all_obstacles()
	print("Passo 3: Obstáculos após reload: %d" % updated_obs.size())
	assert(updated_obs.size() == 7, "Deveria ter 7 obstáculos após auto-descoberta!")
	assert(ObstacleDatabase.has_obstacle("rock_crystal"), "Deve conter o novo 'rock_crystal'")
	assert(ObstacleDatabase.has_obstacle("crystal_rock"), "Deve resolver o alias 'crystal_rock'")

	var dyn_palette_vars: Array = TilePaletteDB.get_variations("rock")
	assert(dyn_palette_vars.size() == 7, "TilePaletteDB deve assimilar a 7ª variação automaticamente!")
	assert(TilePaletteDB.get_base_id_for_variant("rock_crystal") == "rock", "Base id deve ser 'rock'")

	# Validar instanciação do nó físico com colisão e grupo
	var test_node: Node3D = ObstacleDatabase.instantiate_obstacle_node("rock_crystal", 45.0)
	assert(test_node != null, "Falha ao instanciar nó da rocha dinâmica")
	assert(test_node.is_in_group("obstacles"), "Nó dinâmico deve estar no grupo 'obstacles'")
	assert(test_node is CollisionObject3D, "Nó dinâmico deve ser CollisionObject3D")
	var col_obj: CollisionObject3D = test_node as CollisionObject3D
	assert(col_obj.collision_layer == 8, "Nó dinâmico deve ter collision_layer == 8")
	var col_shape: CollisionShape3D = test_node.get_node_or_null("CollisionShape3D") as CollisionShape3D
	assert(col_shape != null, "Nó dinâmico deve possuir CollisionShape3D")
	assert(col_shape.shape is CylinderShape3D, "Nó dinâmico deve possuir CylinderShape3D")
	var cyl: CylinderShape3D = col_shape.shape as CylinderShape3D
	assert(is_equal_approx(cyl.radius, 0.25), "Raio do colisor deve ser 0.25")
	assert(is_equal_approx(test_node.rotation_degrees.y, 45.0), "Rotação Y deve ser 45.0 graus")
	test_node.free()

	# Validar LevelJsonLoader delegando para ObstacleDatabase
	var loader_node: Node3D = LevelJsonLoader.instantiate_object_node("rock_crystal", 90)
	assert(loader_node != null, "LevelJsonLoader deve instanciar nó auto-descoberto")
	assert(loader_node.is_in_group("obstacles"), "Nó via LevelJsonLoader deve estar no grupo 'obstacles'")
	loader_node.free()

	print("✔ Passo 3: Auto-descoberta dinâmica de obstáculos comprovada com sucesso!")

	# 4. Limpeza do arquivo de teste e validação de restauração
	if FileAccess.file_exists(TEST_ROCK_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_ROCK_PATH))
	ObstacleDatabase.reload()

	var final_obs: Array[RockData] = ObstacleDatabase.get_all_obstacles()
	assert(final_obs.size() == 6, "Deve retornar para 6 variantes após exclusão do teste")
	assert(not ObstacleDatabase.has_obstacle("rock_crystal"), "Não deve mais conter 'rock_crystal'")
	assert(TilePaletteDB.get_variations("rock").size() == 6, "TilePaletteDB deve retornar a 6 variações")
	print("✔ Passo 4: Limpeza do teste e restauração para 6 variantes canônicas validada.")

	print("==================================================")
	print(">>> TESTE DE AUTO-DESCOBERTA DE OBSTÁCULOS PASSOU COM 100% DE SUCESSO! <<<")
	print("==================================================")
	quit(0)
