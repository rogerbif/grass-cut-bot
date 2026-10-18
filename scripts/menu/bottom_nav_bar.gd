extends Control

signal tab_changed(tab_index: int)

enum Tabs { GARAGE = 0, HOME = 1, COLLECTION = 2, STORE = 3 }

@onready var btn_garage: Button = $HBox/BtnGarage
@onready var btn_home: Button = $HBox/BtnHome
@onready var btn_collection: Button = $HBox/BtnCollection
@onready var btn_store: Button = $HBox/BtnStore

var current_tab: int = Tabs.HOME

func _ready() -> void:
	if btn_garage != null:
		btn_garage.pressed.connect(func() -> void: select_tab(Tabs.GARAGE))
	if btn_home != null:
		btn_home.pressed.connect(func() -> void: select_tab(Tabs.HOME))
	if btn_collection != null:
		btn_collection.pressed.connect(func() -> void: select_tab(Tabs.COLLECTION))
	if btn_store != null:
		btn_store.pressed.connect(func() -> void: select_tab(Tabs.STORE))

	select_tab(Tabs.HOME, false)

func select_tab(index: int, emit_sig: bool = true) -> void:
	current_tab = index
	_update_buttons()
	if emit_sig:
		tab_changed.emit(current_tab)

func _update_buttons() -> void:
	var buttons: Array[Button] = [btn_garage, btn_home, btn_collection, btn_store]
	for i in range(buttons.size()):
		var btn: Button = buttons[i]
		if btn == null:
			continue
		var is_active: bool = (i == current_tab)
		if is_active:
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
			var tw: Tween = create_tween()
			tw.tween_property(btn, "scale", Vector2(1.08, 1.08), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			btn.modulate = Color(0.72, 0.78, 0.85, 0.85)
			var tw: Tween = create_tween()
			tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
