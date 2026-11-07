class_name GoalIconFactory
extends RefCounted

## Fábrica da ilustração botânica de objetivos (mesmos vetores da tela Coleção).
## Usada pelo HUD de gameplay e pelo Card de Fase do menu (Home/Mapa).

const PlantDatabaseScript = preload("res://scripts/plants/plant_database.gd")
const OUTLINE_SHADER: Shader = preload("res://shaders/goal_icon_outline.gdshader")

const TEX_ILLUS_GRASS_BASE: Texture2D = preload("res://assets/ui/collection/illus_grass_base.svg")
const TEX_ILLUS_GRASS_BLADES: Texture2D = preload("res://assets/ui/collection/illus_grass_blades.svg")
const TEX_ILLUS_WHEAT: Texture2D = preload("res://assets/ui/collection/illus_wheat_bundle.svg")
const TEX_ILLUS_FLOWER_STEMS: Texture2D = preload("res://assets/ui/collection/illus_flower_stems.svg")
const TEX_ILLUS_FLOWER_PETALS: Texture2D = preload("res://assets/ui/collection/illus_flower_petals.svg")


static func _add_layer(parent: Control, tex: Texture2D, tint: Color, apply_outline: bool = true) -> TextureRect:
	var rect: TextureRect = TextureRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.modulate = tint
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if apply_outline:
		var mat: ShaderMaterial = ShaderMaterial.new()
		mat.shader = OUTLINE_SHADER
		mat.set_shader_parameter("outline_color", Color(1.0, 1.0, 1.0, 1.0))
		mat.set_shader_parameter("outline_width", 2.4)
		rect.material = mat
	parent.add_child(rect)
	return rect


## Constrói o container da ilustração (camadas) para o tipo de planta informado.
static func build_goal_icon(plant_type: String, icon_size: float = 34.0, with_outline: bool = true) -> Control:
	var illus: Control = Control.new()
	illus.custom_minimum_size = Vector2(icon_size, icon_size)
	illus.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	illus.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	illus.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sp_data: Dictionary = PlantDatabaseScript.get_species(plant_type)
	var cat: String = String(sp_data.get("category", ""))
	var theme_col: Color = sp_data.get("color", Color.WHITE) as Color

	# Fallback para chaves genéricas ("grass", "flower")
	if cat.is_empty():
		if plant_type.begins_with("flower"):
			cat = "flower"
			theme_col = Color(1.0, 0.18, 0.65)
		elif plant_type == "wheat":
			cat = "crop"
		else:
			cat = "grass"
			theme_col = Color(0.28, 0.81, 0.10)

	if cat == "crop":
		_add_layer(illus, TEX_ILLUS_WHEAT, Color.WHITE, with_outline)
	elif cat == "flower":
		_add_layer(illus, TEX_ILLUS_FLOWER_STEMS, Color.WHITE, with_outline)
		_add_layer(illus, TEX_ILLUS_FLOWER_PETALS, theme_col, with_outline)
	else:
		_add_layer(illus, TEX_ILLUS_GRASS_BASE, Color.WHITE, with_outline)
		_add_layer(illus, TEX_ILLUS_GRASS_BLADES, theme_col, with_outline)
	return illus
