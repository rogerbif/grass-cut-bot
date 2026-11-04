class_name MapLevelCard
extends PanelContainer

## Card de Fase (Home/Bot e Mapa): número da fase, bioma, estrelas conquistadas,
## tempo limite e objetivos (mesmos ícones botânicos da Coleção/HUD).
## Construído em código; ancorado acima dos botões JOGAR/MAPA pela cena tab_home.tscn.

const TEX_CARD_BG: Texture2D = preload("res://assets/ui/map_card/card_level_bg.svg")
const TEX_FRAME_OBJ: Texture2D = preload("res://assets/ui/map_card/frame_objectives.svg")
const TEX_STAR_FULL: Texture2D = preload("res://assets/ui/victory/star_3d_gold.svg")
const TEX_STAR_EMPTY: Texture2D = preload("res://assets/ui/map_card/star_empty_cyber.svg")
const TEX_ISLAND: Texture2D = preload("res://assets/ui/map_card/icon_island_palm.svg")
const TEX_CLOCK: Texture2D = preload("res://assets/icons/icon_clock.svg")
const TEX_LOCK: Texture2D = preload("res://assets/ui/collection/icon_cyber_lock.svg")
const TEX_GOAL_BG: Texture2D = preload("res://assets/ui/topbar/badge_goal_bg.svg")

const COL_WHITE: Color = Color(1.0, 1.0, 1.0, 1.0)
const COL_SUB: Color = Color(0.50, 0.65, 0.80, 1.0)
const COL_LOCKED: Color = Color(0.62, 0.68, 0.80, 1.0)

const CARD_WIDTH: float = 606.0
const GOAL_INNER_WIDTH: float = 540.0
const GOAL_CARD_HEIGHT: float = 70.0
const GOAL_GAP: float = 6.0

const GOAL_ORDER: Array[String] = [
	"grass", "grass_green", "grass_yellow", "grass_blue", "grass_purple", "grass_white",
	"grass_red", "grass_black", "wheat", "flower", "flower_daisy", "flower_bell",
	"flower_rose", "flower_sunflower", "flower_tulip", "flower_corolla", "flower_bed"
]

var _font: SystemFont = null
var _title_icon: TextureRect = null
var _title_lbl: Label = null
var _biome_lbl: Label = null
var _star_rects: Array[TextureRect] = []
var _stars_caption: Label = null
var _time_lbl: Label = null
var _goals_box: HBoxContainer = null
var _current_level: int = -1
var _fade_tween: Tween = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(CARD_WIDTH, 0.0)
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Segoe UI", "Arial Black", "Montserrat", "sans-serif"])
	_font.font_weight = 900
	_build_ui()


func _make_label(txt: String, font_size: int, color: Color) -> Label:
	var lbl: Label = Label.new()
	lbl.text = txt
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", _font)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.4))
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	return lbl


func _make_icon(tex: Texture2D, icon_size: Vector2) -> TextureRect:
	var rect: TextureRect = TextureRect.new()
	rect.texture = tex
	rect.custom_minimum_size = icon_size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _make_texture_style(tex: Texture2D, tex_margin: float, pad_l: float, pad_t: float, pad_r: float, pad_b: float) -> StyleBoxTexture:
	var sb: StyleBoxTexture = StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = tex_margin
	sb.texture_margin_right = tex_margin
	sb.texture_margin_top = tex_margin
	sb.texture_margin_bottom = tex_margin
	sb.content_margin_left = pad_l
	sb.content_margin_right = pad_r
	sb.content_margin_top = pad_t
	sb.content_margin_bottom = pad_b
	return sb


func _build_ui() -> void:
	# Laterais, superior e inferior com o mesmo tamanho uniforme (14px)
	add_theme_stylebox_override("panel", _make_texture_style(TEX_CARD_BG, 26.0, 14.0, 14.0, 14.0, 14.0))

	var root_vbox: VBoxContainer = VBoxContainer.new()
	root_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_vbox.add_theme_constant_override("separation", 6)
	add_child(root_vbox)

	# --- Linha superior: Fase/Bioma | Estrelas | Tempo ---
	# Todos com alinhamento vertical estrito (linha guia)
	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_theme_constant_override("separation", 8)
	root_vbox.add_child(top_row)

	# 1. Bloco Esquerda (Fase XX / Ilha Tropical)
	# MarginContainer interno para recuar para a direita (alinhado com o chanfro da moldura)
	var left_margin: MarginContainer = MarginContainer.new()
	left_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_margin.add_theme_constant_override("margin_left", 14)
	top_row.add_child(left_margin)

	var left_vbox: VBoxContainer = VBoxContainer.new()
	left_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	left_vbox.add_theme_constant_override("separation", 2)
	left_margin.add_child(left_vbox)

	var title_row: HBoxContainer = HBoxContainer.new()
	title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	title_row.add_theme_constant_override("separation", 6)
	title_row.custom_minimum_size = Vector2(0.0, 36.0)
	left_vbox.add_child(title_row)

	_title_icon = _make_icon(TEX_ISLAND, Vector2(30.0, 30.0))
	title_row.add_child(_title_icon)
	_title_lbl = _make_label("Fase 01", 24, COL_WHITE)
	title_row.add_child(_title_lbl)

	_biome_lbl = _make_label(LevelCardData.BIOME_NAME, 16, COL_SUB)
	_biome_lbl.custom_minimum_size = Vector2(0.0, 20.0)
	left_vbox.add_child(_biome_lbl)

	# 2. Bloco Central (Trio de Estrelas / Estrelas)
	var center_vbox: VBoxContainer = VBoxContainer.new()
	center_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center_vbox.add_theme_constant_override("separation", 2)
	top_row.add_child(center_vbox)

	var stars_row: HBoxContainer = HBoxContainer.new()
	stars_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stars_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stars_row.add_theme_constant_override("separation", 4)
	stars_row.custom_minimum_size = Vector2(0.0, 36.0)
	center_vbox.add_child(stars_row)

	var star_sizes: Array[float] = [30.0, 38.0, 30.0]
	for s_size: float in star_sizes:
		var star_rect: TextureRect = _make_icon(TEX_STAR_EMPTY, Vector2(s_size, s_size))
		star_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		stars_row.add_child(star_rect)
		_star_rects.append(star_rect)

	_stars_caption = _make_label("Estrelas", 16, COL_SUB)
	_stars_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stars_caption.custom_minimum_size = Vector2(0.0, 20.0)
	center_vbox.add_child(_stars_caption)

	# 3. Bloco Direita (Relógio / 1:40 / Tempo)
	# MarginContainer interno para recuar da borda direita (alinhado com o chanfro da moldura)
	var right_margin: MarginContainer = MarginContainer.new()
	right_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_margin.add_theme_constant_override("margin_right", 14)
	top_row.add_child(right_margin)

	var right_vbox: VBoxContainer = VBoxContainer.new()
	right_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	right_vbox.add_theme_constant_override("separation", 2)
	right_margin.add_child(right_vbox)

	var time_row: HBoxContainer = HBoxContainer.new()
	time_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	time_row.alignment = BoxContainer.ALIGNMENT_END
	time_row.add_theme_constant_override("separation", 6)
	time_row.custom_minimum_size = Vector2(0.0, 36.0)
	right_vbox.add_child(time_row)

	time_row.add_child(_make_icon(TEX_CLOCK, Vector2(28.0, 28.0)))
	_time_lbl = _make_label("1:30", 25, COL_WHITE)
	time_row.add_child(_time_lbl)

	var time_caption: Label = _make_label("Tempo", 16, COL_SUB)
	time_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_caption.custom_minimum_size = Vector2(0.0, 20.0)
	right_vbox.add_child(time_caption)

	# --- Faixa de objetivos ---
	# A moldura envolve os mini-cards e o texto "Objetivos da Fase" se posiciona
	# exatamente interceptando/tangenciando a linha inferior recortada da moldura.
	var frame_wrapper: Control = Control.new()
	frame_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_wrapper.custom_minimum_size = Vector2(0.0, 102.0)
	root_vbox.add_child(frame_wrapper)

	var frame: PanelContainer = PanelContainer.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_stylebox_override("panel", _make_texture_style(TEX_FRAME_OBJ, 24.0, 16.0, 6.0, 16.0, 16.0))
	frame_wrapper.add_child(frame)

	_goals_box = HBoxContainer.new()
	_goals_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_goals_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_goals_box.add_theme_constant_override("separation", int(GOAL_GAP))
	_goals_box.custom_minimum_size = Vector2(0.0, GOAL_CARD_HEIGHT)
	frame.add_child(_goals_box)

	var obj_caption: Label = _make_label("Objetivos da Fase", 16, COL_SUB)
	obj_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	obj_caption.anchor_top = 1.0
	obj_caption.anchor_bottom = 1.0
	obj_caption.anchor_left = 0.0
	obj_caption.anchor_right = 1.0
	obj_caption.offset_top = -14.0
	obj_caption.offset_bottom = 6.0
	obj_caption.grow_vertical = Control.GROW_DIRECTION_BEGIN
	frame_wrapper.add_child(obj_caption)

	if _current_level > 0:
		var lvl: int = _current_level
		_current_level = -1
		show_level(lvl, _is_unlocked(lvl))


func _is_unlocked(lvl: int) -> bool:
	if SaveManager != null:
		return SaveManager.is_level_unlocked(lvl)
	return lvl <= 1


func _goal_rank(key: String) -> int:
	var idx: int = GOAL_ORDER.find(key)
	return idx if idx >= 0 else 99


## Atualiza todo o conteúdo do card para a fase informada.
func show_level(lvl: int, unlocked: bool) -> void:
	if _title_lbl == null:
		_current_level = lvl
		return

	var changed: bool = (lvl != _current_level)
	_current_level = lvl

	var card_data: Dictionary = LevelCardData.get_level_card_data(lvl)
	_title_lbl.text = "Fase %02d" % lvl
	_biome_lbl.text = String(card_data.get("name", LevelCardData.BIOME_NAME))
	_time_lbl.text = LevelCardData.format_time(float(card_data.get("time", 90.0)))
	_title_icon.texture = TEX_ISLAND if unlocked else TEX_LOCK

	var stars: int = 0
	if SaveManager != null and unlocked:
		stars = SaveManager.get_level_stars(lvl)
	for i: int in range(_star_rects.size()):
		_star_rects[i].texture = TEX_STAR_FULL if i < stars else TEX_STAR_EMPTY
	_stars_caption.text = "Estrelas" if unlocked else "Bloqueada"

	_rebuild_goals(card_data.get("goals", {}) as Dictionary)

	var target_mod: Color = COL_WHITE if unlocked else COL_LOCKED
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	if changed and is_inside_tree():
		modulate = Color(target_mod.r, target_mod.g, target_mod.b, 0.55)
		_fade_tween = create_tween()
		_fade_tween.tween_property(self, "modulate", target_mod, 0.14)
	else:
		modulate = target_mod


func _rebuild_goals(goals: Dictionary) -> void:
	for child: Node in _goals_box.get_children():
		_goals_box.remove_child(child)
		child.queue_free()

	if goals.is_empty():
		_goals_box.add_child(_make_label("—", 26, COL_SUB))
		return

	var keys: Array[String] = []
	for k: Variant in goals.keys():
		keys.append(String(k))
	keys.sort_custom(func(a: String, b: String) -> bool:
		var ra: int = _goal_rank(a)
		var rb: int = _goal_rank(b)
		return ra < rb if ra != rb else a < b
	)

	var count: int = keys.size()
	var card_w: float = floorf((GOAL_INNER_WIDTH - GOAL_GAP * float(count - 1)) / float(count))
	card_w = clampf(card_w, 48.0, 66.0)

	for key: String in keys:
		_goals_box.add_child(_make_goal_card(key, int(goals[key]), card_w))


func _make_goal_card(plant_type: String, amount: int, card_w: float) -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.custom_minimum_size = Vector2(card_w, GOAL_CARD_HEIGHT)
	card.add_theme_stylebox_override("panel", _make_texture_style(TEX_GOAL_BG, 12.0, 4.0, 4.0, 4.0, 4.0))

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 0)
	card.add_child(vbox)

	vbox.add_child(GoalIconFactory.build_goal_icon(plant_type, 36.0))
	var amount_lbl: Label = _make_label(str(amount), 21, COL_WHITE)
	amount_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(amount_lbl)
	return card
