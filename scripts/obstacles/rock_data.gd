class_name RockData
extends Resource

## Define os metadados físicos, de gameplay e de renderização de um obstáculo de rocha.
## Qualquer arquivo .tres criado em res://data/obstacles/ é automaticamente descoberto
## e incorporado ao catálogo de obstáculos, editor de fases e renderização do jogo.

@export_group("Identidade")
@export var id: String = ""
@export var aliases: PackedStringArray = []
@export var name: String = ""
@export var full_name: String = ""
@export var icon: String = "🪨"
@export var color: Color = Color(0.48, 0.52, 0.58)
@export var category: String = "obstacle"
@export var order: int = 0

@export_group("Física & Gameplay")
@export var collision_radius: float = 0.18
@export var collision_height: float = 0.8
@export var clearance_radius: float = 0.90
@export var xp_penalty: int = 1000

@export_group("Recursos Visuais & 3D")
@export_file("*.glb", "*.gltf", "*.tres", "*.res") var mesh_path: String = ""
@export_file("*.tres", "*.res", "*.material") var material_path: String = "res://shaders/rock_toon_material.tres"
@export_file("*.tscn") var scene_path: String = ""
@export var visual_scale: Vector3 = Vector3.ONE

## Converte os metadados do recurso em Dictionary para retrocompatibilidade com TilePaletteDB e o editor
func to_dict() -> Dictionary:
	return {
		"id": id,
		"aliases": aliases,
		"name": name,
		"full_name": full_name,
		"icon": icon,
		"color": color,
		"category": category,
		"order": order,
		"collision_radius": collision_radius,
		"collision_height": collision_height,
		"clearance_radius": clearance_radius,
		"xp_penalty": xp_penalty,
		"mesh_path": mesh_path,
		"material_path": material_path,
		"scene_path": scene_path,
		"visual_scale": visual_scale
	}
