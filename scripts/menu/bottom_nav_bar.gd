extends Control

## Organismo da Navbar inferior no padrão Atomic Design.
## Orquestra exclusivamente os botões CyberNavButton e emite tab_changed.

signal tab_changed(tab_index: int)

enum Tabs { HOME = 0, GARAGE = 1, COLLECTION = 2, STORE = 3 }

@onready var btn_home: CyberNavButton = $HBox/BtnHome as CyberNavButton
@onready var btn_garage: CyberNavButton = $HBox/BtnGarage as CyberNavButton
@onready var btn_collection: CyberNavButton = $HBox/BtnCollection as CyberNavButton
@onready var btn_store: CyberNavButton = $HBox/BtnStore as CyberNavButton

var current_tab: int = Tabs.HOME
var _buttons: Array[CyberNavButton] = []

func _ready() -> void:
	_buttons = [btn_home, btn_garage, btn_collection, btn_store]
	for btn: CyberNavButton in _buttons:
		if btn != null:
			btn.nav_button_pressed.connect(_on_nav_button_pressed)
	select_tab(Tabs.HOME, false)

func select_tab(tab_id: int, emit_sig: bool = true) -> void:
	current_tab = tab_id
	for i: int in range(_buttons.size()):
		var btn: CyberNavButton = _buttons[i]
		if btn != null:
			btn.set_active(i == tab_id)
	if emit_sig:
		tab_changed.emit(current_tab)

func _on_nav_button_pressed(tab_id: int) -> void:
	if tab_id == current_tab:
		return
	select_tab(tab_id)
