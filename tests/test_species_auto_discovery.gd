extends SceneTree

const PlantSpeciesDataScript = preload("res://scripts/plants/plant_species_data.gd")
const PlantDatabaseScript = preload("res://scripts/plants/plant_database.gd")

func _initialize() -> void:
	print("--- TESTE DE AUTO-DESCOBERTA DINÂMICA DE NOVA ESPÉCIE BOTÂNICA ---")

	# 1. Estado inicial: 13 espécies canônicas
	var initial_resources: Array[PlantSpeciesData] = PlantDatabaseScript.get_all_resources()
	assert(initial_resources.size() == 13, "Inicialmente deve haver 13 espécies. Atual: %d" % initial_resources.size())
	print("✔ Passo 1: Estado inicial com 13 espécies verificado com sucesso.")

	# 2. Cria um novo arquivo .tres em tempo de execução na pasta data/species/
	var test_path: String = "res://data/species/test_crystal_flower.tres"
	var new_species: PlantSpeciesData = PlantSpeciesDataScript.new()
	new_species.key = "test_crystal_flower"
	new_species.category = "flower"
	new_species.name = "Flor de Cristal Luminosa"
	new_species.icon = "💎"
	new_species.color = Color(0.40, 0.90, 1.0, 1.0)
	new_species.origin_level = 99
	new_species.hits = 3
	new_species.reward_coins = 10
	new_species.desc = "Espécie bioluminescente rara de pétalas translúcidas de cristal."
	new_species.clipping_color = Color(0.30, 0.80, 0.95, 1.0)

	var err: Error = ResourceSaver.save(new_species, test_path)
	assert(err == OK, "Falha ao gravar arquivo .tres de teste: %d" % err)
	print("✔ Passo 2: Novo arquivo de espécie 'test_crystal_flower.tres' gravado em res://data/species/.")

	# 3. Força reload dinâmico via DirAccess
	PlantDatabaseScript.reload_species()

	var after_resources: Array[PlantSpeciesData] = PlantDatabaseScript.get_all_resources()
	var after_species: Array[Dictionary] = PlantDatabaseScript.get_all_species()

	assert(after_resources.size() == 14, "Após auto-descoberta, deve haver 14 espécies! Atual: %d" % after_resources.size())
	assert(after_species.size() == 14, "Após auto-descoberta, Dictionary list deve ter 14 espécies! Atual: %d" % after_species.size())

	var retrieved: PlantSpeciesData = PlantDatabaseScript.get_resource("test_crystal_flower")
	assert(retrieved != null, "get_resource deve recuperar a nova espécie!")
	assert(retrieved.name == "Flor de Cristal Luminosa", "Nome deve corresponder!")
	assert(retrieved.clipping_color == Color(0.30, 0.80, 0.95, 1.0), "Clipping color deve corresponder!")

	var retrieved_dict: Dictionary = PlantDatabaseScript.get_species("test_crystal_flower")
	assert(not retrieved_dict.is_empty(), "get_species (Dictionary) deve retornar dados da nova espécie!")
	assert(String(retrieved_dict.get("icon", "")) == "💎", "Ícone de Dictionary deve corresponder!")
	print("✔ Passo 3: Auto-descoberta comprovada! Nova espécie assimilada dinamicamente sem tocar em código.")

	# 4. Limpa arquivo temporário e valida retorno ao estado canônico de 13 espécies
	var da: DirAccess = DirAccess.open("res://data/species")
	if da != null:
		da.remove("test_crystal_flower.tres")
	PlantDatabaseScript.reload_species()

	var final_resources: Array[PlantSpeciesData] = PlantDatabaseScript.get_all_resources()
	assert(final_resources.size() == 13, "Após remoção e reload, deve voltar a 13 espécies! Atual: %d" % final_resources.size())
	print("✔ Passo 4: Limpeza do teste e restauração para 13 espécies canônicas validada.")

	print("==================================================")
	print(">>> TESTE DE AUTO-DESCOBERTA PASSOU COM 100% DE SUCESSO! <<<")
	print("==================================================")
	quit(0)
