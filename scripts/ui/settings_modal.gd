extends Control

signal modal_closed

@onready var graphics_btn: Button = $Panel/VBox/AudioSection/VBox/HBoxToggles.get_node_or_null("GraphicsBtn") as Button
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

var graphics_quality: String = "balanced"
var music_enabled: bool = true
var sfx_enabled: bool = true
var vib_enabled: bool = true
var _reset_confirmation_pending: bool = false
var _version_tap_count: int = 0
var android_vib_hint_btn: Button = null
var _waiting_for_android_haptic_toggle: bool = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if OS.get_name() == "Android" or OS.has_feature("android"):
			var system_haptic_on: bool = _is_android_haptic_feedback_enabled()
			if _waiting_for_android_haptic_toggle:
				_waiting_for_android_haptic_toggle = false
				if system_haptic_on:
					vib_enabled = true
					if SaveManager != null:
						SaveManager.set_setting("vib_enabled", true)
					_update_toggle_visuals()
					Input.vibrate_handheld(200, 1.0)
					_show_toast("Retorno Tátil ativado! Vibração ON 📳")
				else:
					vib_enabled = false
					if SaveManager != null:
						SaveManager.set_setting("vib_enabled", false)
					_update_toggle_visuals()
					_show_toast("Retorno Tátil permanece desligado no celular")
			else:
				if not system_haptic_on and vib_enabled:
					vib_enabled = false
					if SaveManager != null:
						SaveManager.set_setting("vib_enabled", false)
				_update_toggle_visuals()
		else:
			_update_toggle_visuals()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if version_label != null:
		var edition: String = "Web Edition" if OS.has_feature("web") else ("PC Edition" if OS.has_feature("pc") else "Mobile Edition")
		version_label.text = "%s • %s" % [GameVersion.get_display_name(), edition]
		version_label.mouse_filter = Control.MOUSE_FILTER_STOP
		version_label.gui_input.connect(_on_version_gui_input)

	if SaveManager != null:
		music_enabled = bool(SaveManager.get_setting("music_enabled", true))
		sfx_enabled = bool(SaveManager.get_setting("sfx_enabled", true))
		vib_enabled = bool(SaveManager.get_setting("vib_enabled", true))
		graphics_quality = String(SaveManager.get_setting("graphics_quality", "balanced"))

	if OS.get_name() == "Android" or OS.has_feature("android"):
		var system_haptic_on: bool = _is_android_haptic_feedback_enabled()
		if not system_haptic_on:
			vib_enabled = false
			if SaveManager != null:
				SaveManager.set_setting("vib_enabled", false)

		var toggles_box: Node = get_node_or_null("Panel/VBox/AudioSection/VBox/HBoxToggles")
		if toggles_box != null:
			android_vib_hint_btn = Button.new()
			android_vib_hint_btn.custom_minimum_size = Vector2(0, 42)
			android_vib_hint_btn.focus_mode = Control.FOCUS_NONE
			android_vib_hint_btn.add_theme_font_size_override("font_size", 14)
			android_vib_hint_btn.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35, 1.0))
			android_vib_hint_btn.text = "⚙️ Ajustar Vibração no Celular"
			android_vib_hint_btn.pressed.connect(_on_android_vib_hint_pressed)
			toggles_box.add_child(android_vib_hint_btn)

	_update_toggle_visuals()

	if close_btn != null:
		close_btn.pressed.connect(close_modal)
	if graphics_btn != null:
		graphics_btn.pressed.connect(_on_graphics_toggled)
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
	if version_label != null:
		var edition: String = "Web Edition" if OS.has_feature("web") else ("PC Edition" if OS.has_feature("pc") else "Mobile Edition")
		version_label.text = "%s • %s" % [GameVersion.get_display_name(), edition]
	if AudioManager != null:
		AudioManager.play_sfx("confirm")
	visible = true
	modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if toast_label != null:
		toast_label.visible = false

func close_modal() -> void:
	if AudioManager != null:
		AudioManager.play_sfx("close")
	var tw: Tween = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		visible = false
		modal_closed.emit()
	)

func _on_graphics_toggled() -> void:
	match graphics_quality:
		"balanced":
			graphics_quality = "eco"
			_show_toast("Qualidade 3D: Econômica (70% FSR - Bateria)")
		"eco":
			graphics_quality = "high"
			_show_toast("Qualidade 3D: Alta (100% Nativa)")
		"high":
			graphics_quality = "balanced"
			_show_toast("Qualidade 3D: Balanceada (85% FSR) ⭐")
		_:
			graphics_quality = "balanced"
			_show_toast("Qualidade 3D: Balanceada (85% FSR) ⭐")

	if SaveManager != null:
		SaveManager.set_setting("graphics_quality", graphics_quality)
	if GameManager != null:
		GameManager.apply_graphics_quality(graphics_quality)
	_update_toggle_visuals()

func _on_music_toggled() -> void:
	music_enabled = not music_enabled
	_update_toggle_visuals()
	if AudioManager != null:
		AudioManager.set_music_enabled(music_enabled)
	if SaveManager != null:
		SaveManager.set_setting("music_enabled", music_enabled)
	_show_toast("Música " + ("Ativada" if music_enabled else "Desativada"))

func _on_sfx_toggled() -> void:
	sfx_enabled = not sfx_enabled
	_update_toggle_visuals()
	if AudioManager != null:
		AudioManager.set_sfx_enabled(sfx_enabled)
	if SaveManager != null:
		SaveManager.set_setting("sfx_enabled", sfx_enabled)
	_show_toast("Som FX " + ("Ativado" if sfx_enabled else "Desativado"))

func _on_vib_toggled() -> void:
	if vib_enabled:
		vib_enabled = false
		if SaveManager != null:
			SaveManager.set_setting("vib_enabled", false)
		_update_toggle_visuals()
		_show_toast("Vibração Desativada")
	else:
		if OS.get_name() == "Android" or OS.has_feature("android"):
			if not _is_android_haptic_feedback_enabled():
				_waiting_for_android_haptic_toggle = true
				_update_toggle_visuals()
				_show_toast("Ative 'Retorno Tátil' nas configurações do celular!")
				_open_android_sound_settings()
				return
		vib_enabled = true
		if SaveManager != null:
			SaveManager.set_setting("vib_enabled", true)
		_update_toggle_visuals()
		Input.vibrate_handheld(200, 1.0)
		_show_toast("Vibração Ativada! 📳")

func _on_android_vib_hint_pressed() -> void:
	_waiting_for_android_haptic_toggle = true
	_open_android_sound_settings()

func _update_toggle_visuals() -> void:
	if graphics_btn != null:
		match graphics_quality:
			"high":
				graphics_btn.text = "⚡ Gráficos 3D: Alta (100% Nativa)"
			"eco":
				graphics_btn.text = "⚡ Gráficos 3D: Econômica (70% FSR)"
			_:
				graphics_btn.text = "⚡ Gráficos 3D: Balanceada (85% FSR) ⭐"

	if music_btn != null:
		music_btn.text = "🎵 Música: " + ("ON" if music_enabled else "OFF")
	if sfx_btn != null:
		sfx_btn.text = "🔊 FX: " + ("ON" if sfx_enabled else "OFF")
	if vib_btn != null:
		vib_btn.text = "📳 Vibração: " + ("ON" if vib_enabled else "OFF")

	if android_vib_hint_btn != null:
		var haptic_on: bool = _is_android_haptic_feedback_enabled()
		if not haptic_on:
			android_vib_hint_btn.visible = true
			android_vib_hint_btn.text = "⚠️ Retorno Tátil desligado no Android (Abrir ⚙️)"
			android_vib_hint_btn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35, 1.0))
		else:
			android_vib_hint_btn.visible = false

func _is_android_haptic_feedback_enabled() -> bool:
	if not Engine.has_singleton("JavaClassWrapper") or not Engine.has_singleton("AndroidRuntime"):
		return true
	var android_runtime: Object = Engine.get_singleton("AndroidRuntime")
	var activity: Variant = android_runtime.call("getActivity")
	if activity == null:
		return true
	var java_wrapper: Object = Engine.get_singleton("JavaClassWrapper")
	var SettingsSystem: Variant = java_wrapper.call("wrap", "android.provider.Settings$System")
	if SettingsSystem == null:
		return true
	var resolver: Variant = activity.getContentResolver()
	var val: int = int(SettingsSystem.getInt(resolver, "haptic_feedback_enabled", 1))
	return val == 1

func _open_android_sound_settings() -> void:
	if not Engine.has_singleton("JavaClassWrapper") or not Engine.has_singleton("AndroidRuntime"):
		_show_toast("Disponível apenas no dispositivo Android")
		return
	var android_runtime: Object = Engine.get_singleton("AndroidRuntime")
	var activity: Variant = android_runtime.call("getActivity")
	if activity == null:
		return
	var java_wrapper: Object = Engine.get_singleton("JavaClassWrapper")
	var IntentClass: Variant = java_wrapper.call("wrap", "android.content.Intent")
	var SettingsClass: Variant = java_wrapper.call("wrap", "android.provider.Settings")
	if IntentClass != null and SettingsClass != null:
		var intent: Variant = IntentClass.new(SettingsClass.ACTION_SOUND_SETTINGS)
		activity.startActivity(intent)

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

func _on_version_gui_input(event: InputEvent) -> void:
	var pressed: bool = false
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		pressed = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		pressed = st.pressed
	if not pressed:
		return
	_version_tap_count += 1
	if _version_tap_count >= 3:
		_version_tap_count = 0
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/tools/perf_test.tscn")
	else:
		_show_toast("Benchmark Fase 20: mais %d toque(s)..." % (3 - _version_tap_count))

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
