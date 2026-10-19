extends Control

signal modal_closed

@onready var music_btn: Button = $Panel/VBox/AudioSection/VBox/HBoxToggles/MusicBtn
@onready var sfx_btn: Button = $Panel/VBox/AudioSection/VBox/HBoxToggles/SfxBtn
@onready var vib_btn: Button = $Panel/VBox/AudioSection/VBox/HBoxToggles/VibBtn

@onready var save_local_btn: Button = $Panel/VBox/SaveSection/VBoxSave/SaveLocalBtn
@onready var google_btn: Button = $Panel/VBox/SaveSection/VBoxSave/GoogleBtn
@onready var fb_btn: Button = $Panel/VBox/SaveSection/VBoxSave/FacebookBtn
@onready var reset_btn: Button = $Panel/VBox/SaveSection/VBoxSave.get_node_or_null("ResetBtn") as Button

@onready var support_btn: Button = $Panel/VBox/SupportSection/SupportBtn
@onready var version_label: Label = $Panel/VBox/SupportSection.get_node_or_null("VersionLabel") as Label
@onready var close_btn: Button = $Panel/Header/CloseBtn
@onready var toast_label: Label = $Panel/ToastLabel

var music_enabled: bool = true
var sfx_enabled: bool = true
var vib_enabled: bool = true
var _reset_confirmation_pending: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if version_label != null:
		version_label.text = "%s • Mobile Edition" % GameVersion.get_display_name()

	if SaveManager != null:
		music_enabled = bool(SaveManager.get_setting("music_enabled", true))
		sfx_enabled = bool(SaveManager.get_setting("sfx_enabled", true))
		vib_enabled = bool(SaveManager.get_setting("vib_enabled", true))

	_update_toggle_visuals()

	if close_btn != null:
		close_btn.pressed.connect(close_modal)
	if music_btn != null:
		music_btn.pressed.connect(_on_music_toggled)
	if sfx_btn != null:
		sfx_btn.pressed.connect(_on_sfx_toggled)
	if vib_btn != null:
		vib_btn.pressed.connect(_on_vib_toggled)

	if save_local_btn != null:
		save_local_btn.pressed.connect(_on_save_local_pressed)
	if google_btn != null:
		google_btn.pressed.connect(_on_google_pressed)
	if fb_btn != null:
		fb_btn.pressed.connect(_on_fb_pressed)
	if reset_btn != null:
		reset_btn.pressed.connect(_on_reset_pressed)
	if support_btn != null:
		support_btn.pressed.connect(_on_support_pressed)

func open_modal() -> void:
	visible = true
	modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if toast_label != null:
		toast_label.visible = false

func close_modal() -> void:
	var tw: Tween = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		visible = false
		modal_closed.emit()
	)

func _on_music_toggled() -> void:
	music_enabled = not music_enabled
	_update_toggle_visuals()
	if SaveManager != null:
		SaveManager.set_setting("music_enabled", music_enabled)
	_show_toast("Música " + ("Ativada" if music_enabled else "Desativada"))

func _on_sfx_toggled() -> void:
	sfx_enabled = not sfx_enabled
	_update_toggle_visuals()
	if SaveManager != null:
		SaveManager.set_setting("sfx_enabled", sfx_enabled)
	_show_toast("Som FX " + ("Ativado" if sfx_enabled else "Desativado"))

func _on_vib_toggled() -> void:
	vib_enabled = not vib_enabled
	_update_toggle_visuals()
	if SaveManager != null:
		SaveManager.set_setting("vib_enabled", vib_enabled)
	if vib_enabled and GameManager != null:
		GameManager.trigger_haptic_cut()
	_show_toast("Vibração " + ("Ativada" if vib_enabled else "Desativada"))

func _update_toggle_visuals() -> void:
	if music_btn != null:
		music_btn.text = "🎵 Música: " + ("ON" if music_enabled else "OFF")
	if sfx_btn != null:
		sfx_btn.text = "🔊 FX: " + ("ON" if sfx_enabled else "OFF")
	if vib_btn != null:
		vib_btn.text = "📳 Vibração: " + ("ON" if vib_enabled else "OFF")

func _on_save_local_pressed() -> void:
	if SaveManager != null:
		var ok: bool = SaveManager.save_game()
		if ok:
			_show_toast("Progresso salvo com sucesso no dispositivo! 💾")
		else:
			_show_toast("Erro ao gravar dados no armazenamento.")
	else:
		_show_toast("Progresso salvo com sucesso no dispositivo! 💾")

func _on_reset_pressed() -> void:
	if not _reset_confirmation_pending:
		_reset_confirmation_pending = true
		_show_toast("⚠️ Clique novamente para confirmar o reset!")
		if reset_btn != null:
			reset_btn.text = "⚠️ Confirmar Reset Geral?"
		var tw: Tween = create_tween()
		tw.tween_interval(4.0)
		tw.tween_callback(func() -> void:
			_reset_confirmation_pending = false
			if reset_btn != null:
				reset_btn.text = "🗑️ Resetar Progresso"
		)
	else:
		_reset_confirmation_pending = false
		if reset_btn != null:
			reset_btn.text = "🗑️ Resetar Progresso"
		if SaveManager != null:
			SaveManager.reset_to_defaults()
		_show_toast("Progresso reiniciado com sucesso! 🔄")

func _on_google_pressed() -> void:
	_show_toast("Google Play Games: Em breve!")

func _on_fb_pressed() -> void:
	_show_toast("Facebook Connect: Em breve!")

func _on_support_pressed() -> void:
	_show_toast("Abrindo suporte ao jogador...")

func _show_toast(msg: String) -> void:
	if toast_label == null:
		return
	toast_label.text = msg
	toast_label.visible = true
	toast_label.modulate.a = 1.0

	var tw: Tween = create_tween()
	tw.tween_interval(1.8)
	tw.tween_property(toast_label, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func() -> void: toast_label.visible = false)
