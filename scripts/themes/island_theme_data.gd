class_name IslandThemeData
extends Resource

const IslandMeshBuilderScript = preload("res://scripts/level/island_mesh_builder.gd")

## Define os parâmetros visuais, cromáticos, solares e atmosféricos de um tema/mundo.
## Qualquer arquivo .tres criado em res://data/themes/ é automaticamente descoberto
## e incorporado ao catálogo de temas do jogo.

@export_group("Identidade")
@export var id: String = ""
@export var name: String = ""
@export var world_id: int = 1
@export_multiline var description: String = ""

@export_group("Terreno da Ilha (IslandMeshBuilder)")
@export var ground_base_color: Color = Color(0.15, 0.59, 0.22, 1.0)
@export var ground_brightness: float = 0.85
@export var ground_diffuse_toon: bool = true
@export var cliff_color: Color = Color(0.745, 0.427, 0.25, 1.0)
@export var dirt_color: Color = Color(0.538, 0.364, 0.231, 1.0)

@export_group("Oceano (Toon Water)")
@export var water_shallow_color: Color = Color(0.18, 0.65, 0.82, 1.0)
@export var water_deep_color: Color = Color(0.084, 0.52, 0.743, 1.0)
@export var foam_color: Color = Color(0.88, 0.98, 1.0, 1.0)
@export var water_roughness: float = 0.48

@export_group("Sol & Iluminação Direcional (DirectionalLight3D)")
@export var sun_color: Color = Color.WHITE
@export var sun_energy: float = 1.0
@export var sun_pitch: float = -45.0
@export var sun_yaw: float = 30.0
@export var sun_shadows: bool = true

@export_group("Ambiente & Céu (WorldEnvironment)")
@export var sky_bg_color: Color = Color(0.68, 0.85, 0.90, 1.0)
@export var ambient_light_color: Color = Color(0.85, 0.92, 0.88, 1.0)
@export var ambient_light_energy: float = 0.85
@export var tonemap_mode: int = 2 # Filmic
@export var fog_enabled: bool = false
@export var fog_color: Color = Color(0.80, 0.85, 0.90, 1.0)
@export var fog_density: float = 0.001

## Aplica os parâmetros de céu e luz ambiente no recurso Environment
func apply_to_environment(env: Environment) -> void:
	if env == null:
		return
	env.background_mode = Environment.BG_COLOR
	env.background_color = sky_bg_color
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = ambient_light_color
	env.ambient_light_energy = ambient_light_energy
	env.tonemap_mode = tonemap_mode as Environment.ToneMapper

## Aplica a orientação, energia e cor na luz direcional do Sol
func apply_to_sun(sun: DirectionalLight3D) -> void:
	if sun == null:
		return
	sun.light_color = sun_color
	sun.light_energy = sun_energy
	sun.shadow_enabled = sun_shadows
	# Calcula rotação Y (yaw) e X (pitch)
	var basis: Basis = Basis(Vector3.UP, deg_to_rad(sun_yaw))
	basis = basis * Basis(Vector3.RIGHT, deg_to_rad(sun_pitch))
	sun.basis = basis

## Aplica as cores de gradiente de profundidade no material do oceano
func apply_to_water(water_mat: ShaderMaterial) -> void:
	if water_mat == null:
		return
	water_mat.set_shader_parameter("_DepthGradientShallow", water_shallow_color)
	water_mat.set_shader_parameter("_DepthGradientDeep", water_deep_color)
	water_mat.set_shader_parameter("foam_color", foam_color)
	water_mat.set_shader_parameter("roughness", water_roughness)

## Configura o IslandMeshBuilder para gerar malhas com os Vertex Colors do tema
func apply_to_island_builder() -> void:
	IslandMeshBuilderScript.set_ground_parameters(
		ground_base_color,
		ground_brightness,
		ground_diffuse_toon,
		cliff_color,
		dirt_color
	)

## Converte os metadados do tema em Dictionary
func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"world_id": world_id,
		"description": description,
		"ground_base_color": ground_base_color,
		"ground_brightness": ground_brightness,
		"ground_diffuse_toon": ground_diffuse_toon,
		"cliff_color": cliff_color,
		"dirt_color": dirt_color,
		"water_shallow_color": water_shallow_color,
		"water_deep_color": water_deep_color,
		"foam_color": foam_color,
		"sun_color": sun_color,
		"sun_energy": sun_energy,
		"sun_pitch": sun_pitch,
		"sun_yaw": sun_yaw,
		"sky_bg_color": sky_bg_color,
		"ambient_light_color": ambient_light_color,
		"ambient_light_energy": ambient_light_energy
	}
