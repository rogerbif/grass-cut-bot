class_name PlantSpeciesData
extends Resource

## Define os metadados taxonômicos, de gameplay e de renderização de uma espécie botânica.
## Qualquer arquivo .tres criado em res://data/species/ é automaticamente descoberto
## e incorporado ao catálogo botânico, herbário, metas e renderização do jogo.

@export_group("Identidade & Taxonomia")
@export var key: String = ""
@export_enum("grass", "crop", "flower") var category: String = "grass"
@export var name: String = ""
@export var icon: String = "🌱"
@export var color: Color = Color.WHITE
@export var origin_level: int = 1
@export var hits: int = 1
@export var reward_coins: int = 1
@export_multiline var desc: String = ""
@export var milestones: Array[Dictionary] = []

@export_group("Recursos Visuais & Renderização")
@export_file("*.glb", "*.gltf", "*.tres", "*.res") var mesh_path: String = ""
@export_file("*.tres", "*.res", "*.material") var material_path: String = ""
@export var clipping_color: Color = Color(0.17, 0.36, 0.17, 1.0)
@export var particle_petal_color: Color = Color.WHITE
@export var particle_center_color: Color = Color.YELLOW

## Converte os dados do recurso em Dictionary para retrocompatibilidade total com código existente
func to_dict() -> Dictionary:
	return {
		"key": key,
		"category": category,
		"name": name,
		"icon": icon,
		"color": color,
		"origin_level": origin_level,
		"hits": hits,
		"reward_coins": reward_coins,
		"desc": desc,
		"milestones": milestones,
		"mesh_path": mesh_path,
		"material_path": material_path,
		"clipping_color": clipping_color,
		"particle_petal_color": particle_petal_color,
		"particle_center_color": particle_center_color
	}
