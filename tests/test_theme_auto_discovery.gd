extends SceneTree

const ThemeDatabase = preload("res://scripts/themes/theme_database.gd")
const IslandThemeData = preload("res://scripts/themes/island_theme_data.gd")
const IslandMeshBuilder = preload("res://scripts/level/island_mesh_builder.gd")

const TEST_THEME_PATH: String = "res://data/themes/test_cyber_theme.tres"

func _init() -> void:
	print("==================================================")
	print("🧪 TESTE DE AUTO-DESCOBERTA E INTEGRIDADE DE TEMAS")
	print("==================================================")

	# 1. Validar estado canônico inicial (3 temas)
	var initial_themes: Array[IslandThemeData] = ThemeDatabase.get_all_themes()
	print("Passo 1: Estado inicial com %d temas registrados." % initial_themes.size())
	assert(initial_themes.size() == 3, "Esperado exatamente 3 temas canônicos!")
	assert(ThemeDatabase.has_theme("tropical_day"), "Deve conter 'tropical_day'")
	assert(ThemeDatabase.has_theme("sunset_golden"), "Deve conter 'sunset_golden'")
	assert(ThemeDatabase.has_theme("night_stars"), "Deve conter 'night_stars'")

	# Valida resolução de mundos (Melhoria 204: 100 fases por mundo)
	var t_fase1: IslandThemeData = ThemeDatabase.get_theme_for_level(1)
	assert(t_fase1.id == "tropical_day", "Fase 1 deve ser 'tropical_day'")
	var t_fase40: IslandThemeData = ThemeDatabase.get_theme_for_level(40)
	assert(t_fase40.id == "tropical_day", "Fase 40 deve ser 'tropical_day'")
	var t_fase100: IslandThemeData = ThemeDatabase.get_theme_for_level(100)
	assert(t_fase100.id == "tropical_day", "Fase 100 deve ser 'tropical_day'")
	var t_fase101: IslandThemeData = ThemeDatabase.get_theme_for_level(101)
	assert(t_fase101.id == "sunset_golden", "Fase 101 deve ser 'sunset_golden'")
	var t_fase201: IslandThemeData = ThemeDatabase.get_theme_for_level(201)
	assert(t_fase201.id == "night_stars", "Fase 201 deve ser 'night_stars'")

	# Valida override via JSON
	var t_override: IslandThemeData = ThemeDatabase.get_theme_for_level(1, {"theme": "sunset_golden"})
	assert(t_override.id == "sunset_golden", "Override no JSON deve ter precedência")
	print("✔ Passo 1: 3 temas canônicos e roteamento de mundos validados com sucesso.")

	# 2. Testar aplicação em nós 3D simulados
	var test_env: Environment = Environment.new()
	var test_world_env: WorldEnvironment = WorldEnvironment.new()
	test_world_env.environment = test_env
	var test_sun: DirectionalLight3D = DirectionalLight3D.new()

	t_fase1.apply_to_environment(test_env)
	assert(is_equal_approx(test_env.background_color.r, t_fase1.sky_bg_color.r), "Céu aplicado incorretamente")
	assert(is_equal_approx(test_env.ambient_light_energy, t_fase1.ambient_light_energy), "Energia ambiente incorreta")

	t_fase1.apply_to_sun(test_sun)
	assert(test_sun.light_color == t_fase1.sun_color, "Cor do sol incorreta")
	assert(is_equal_approx(test_sun.light_energy, t_fase1.sun_energy), "Energia do sol incorreta")

	t_fase1.apply_to_island_builder()
	assert(IslandMeshBuilder.ground_base_color == t_fase1.ground_base_color, "Cor do solo da ilha incorreta")

	test_sun.free()
	test_world_env.free()
	print("✔ Passo 2: Aplicação nos nós de Ambiente, Sol e Terreno validada.")

	# 3. Criar dinamicamente novo tema em tempo de execução
	var dyn_theme: IslandThemeData = IslandThemeData.new()
	dyn_theme.id = "cyber_neon"
	dyn_theme.name = "Cyber Neon World"
	dyn_theme.world_id = 4
	dyn_theme.description = "Tema futurista de teste"
	dyn_theme.ground_base_color = Color(0.1, 0.9, 0.8, 1.0)
	dyn_theme.sky_bg_color = Color(0.05, 0.05, 0.15, 1.0)
	dyn_theme.sun_energy = 2.0

	var save_err: Error = ResourceSaver.save(dyn_theme, TEST_THEME_PATH)
	assert(save_err == OK, "Erro ao gravar arquivo de teste .tres em %s" % TEST_THEME_PATH)
	print("✔ Passo 3: Novo arquivo 'test_cyber_theme.tres' gravado com sucesso.")

	# 4. Forçar reload e validar auto-descoberta
	ThemeDatabase.reload()
	var updated_themes: Array[IslandThemeData] = ThemeDatabase.get_all_themes()
	print("Passo 4: Temas após reload: %d" % updated_themes.size())
	assert(updated_themes.size() == 4, "Esperado 4 temas após auto-descoberta!")
	assert(ThemeDatabase.has_theme("cyber_neon"), "Deve conter o novo 'cyber_neon'")
	var fetched_dyn: IslandThemeData = ThemeDatabase.get_theme("cyber_neon")
	assert(fetched_dyn.name == "Cyber Neon World", "Nome do tema dinâmico incorreto")
	print("✔ Passo 4: Auto-descoberta dinâmica de temas comprovada!")

	# 5. Limpeza e restauração
	if FileAccess.file_exists(TEST_THEME_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_THEME_PATH))
	ThemeDatabase.reload()

	var final_themes: Array[IslandThemeData] = ThemeDatabase.get_all_themes()
	assert(final_themes.size() == 3, "Deve retornar para 3 temas canônicos após exclusão")
	assert(not ThemeDatabase.has_theme("cyber_neon"), "Não deve mais conter 'cyber_neon'")
	print("✔ Passo 5: Limpeza do teste e restauração para 3 temas canônicos validada.")

	# Restaura os parâmetros do builder para o padrão tropical diurno
	t_fase1.apply_to_island_builder()

	print("==================================================")
	print(">>> TESTE DE TEMAS PASSOU COM 100% DE SUCESSO! <<<")
	print("==================================================")
	quit(0)
