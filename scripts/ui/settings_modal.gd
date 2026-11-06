extends Control

signal modal_closed

const TEX_TOGGLE_ON: Texture2D = preload("res://assets/ui/settings/toggle_on.svg")
const TEX_TOGGLE_OFF: Texture2D = preload("res://assets/ui/settings/toggle_off.svg")

@onready var graphics_btn: BaseButton = find_child("GraphicsBtn", true, false) as BaseButton
@onready var music_btn: BaseButton = find_child("MusicBtn", true, false) as BaseButton
@onready var music_state_label: Label = music_btn.get_node_or_null("StateLabel") as Label if music_btn != null else null
@onready var sfx_btn: BaseButton = find_child("SfxBtn", true, false) as BaseButton
@onready var sfx_state_label: Label = sfx_btn.get_node_or_null("StateLabel") as Label if sfx_btn != null else null
@onready var vib_btn: BaseButton = find_child("VibBtn", true, false) as BaseButton
@onready var vib_state_label: Label = vib_btn.get_node_or_null("StateLabel") as Label if vib_btn != null else null

@onready var save_local_btn: BaseButton = find_child("SaveLocalBtn", true, false) as BaseButton
@onready var google_btn: BaseButton = find_child("GoogleBtn", true, false) as BaseButton
@onready var fb_btn: BaseButton = find_child("FacebookBtn", true, false) as BaseButton
@onready var reset_btn: BaseButton = find_child("ResetBtn", true, false) as BaseButton
@onready var reset_label: Label = reset_btn.find_child("Label", true, false) as Label if reset_btn != null else null

@onready var support_btn: BaseButton = find_child("SupportBtn", true, false) as BaseButton
@onready var version_label: Label = find_child("VersionLabel", true, false) as Label
@onready var close_btn: BaseButton = find_child("CloseBtn", true, false) as BaseButton
@onready var toast_label: Label = find_child("ToastLabel", true, false) as Label

@onready var btn_lang_pt: Button = find_child("BtnLangPT", true, false) as Button
@onready var btn_lang_en: Button = find_child("BtnLangEN", true, false) as Button
@onready var btn_lang_es: Button = find_child("BtnLangES", true, false) as Button

# Nós para atualização dinâmica de tradução
@onready var modal_title_label: Label = find_child("Title", true, false) as Label
@onready var audio_section_label: Label = get_node_or_null("Panel/VBox/AudioSection/VBox/Label") as Label
@onready var music_title_label: Label = get_node_or_null("Panel/VBox/AudioSection/VBox/InnerCard/HBoxToggles/MusicRow/TitleLabel") as Label
@onready var sfx_title_label: Label = get_node_or_null("Panel/VBox/AudioSection/VBox/InnerCard/HBoxToggles/SfxRow/TitleLabel") as Label
@onready var vib_title_label: Label = get_node_or_null("Panel/VBox/AudioSection/VBox/InnerCard/HBoxToggles/VibRow/TitleLabel") as Label
@onready var lang_title_label: Label = get_node_or_null("Panel/VBox/AudioSection/VBox/InnerCard/HBoxToggles/LanguageRow/TitleLabel") as Label
@onready var save_section_label: Label = get_node_or_null("Panel/VBox/SaveSection/VBoxSave/Label") as Label
@onready var save_local_label: Label = get_node_or_null("Panel/VBox/SaveSection/VBoxSave/SaveLocalBtn/HBox/Label") as Label
@onready var google_label: Label = get_node_or_null("Panel/VBox/SaveSection/VBoxSave/GoogleBtn/HBox/Label") as Label
@onready var fb_label: Label = get_node_or_null("Panel/VBox/SaveSection/VBoxSave/FacebookBtn/HBox/Label") as Label
@onready var support_label: Label = get_node_or_null("Panel/VBox/SupportSection/SupportBtn/HBox/Label") as Label

var graphics_quality: String = "balanced"
var music_enabled: bool = true
var sfx_enabled: bool = true
var vib_enabled: bool = true
var _reset_confirmation_pending: bool = false
var _version_tap_count: int = 0
var android_vib_hint_btn: Button = null
var _waiting_for_android_haptic_toggle: bool = false
var _is_closing: bool = false
var _style_lang_active: StyleBoxFlat = null
var _style_lang_inactive: StyleBoxFlat = null

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_all_localized_texts()
		return
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
					_show_toast("Retorno Tátil ativado! Vibração ON")
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

		var toggles_box: Node = find_child("HBoxToggles", true, false)
		if toggles_box != null:
			android_vib_hint_btn = Button.new()
			android_vib_hint_btn.custom_minimum_size = Vector2(0, 42)
			android_vib_hint_btn.focus_mode = Control.FOCUS_NONE
			android_vib_hint_btn.add_theme_font_size_override("font_size", 14)
			android_vib_hint_btn.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35, 1.0))
			android_vib_hint_btn.text = "Ajustar Vibração no Celular"
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

	if btn_lang_pt != null:
		btn_lang_pt.pressed.connect(func() -> void: _set_language("pt_BR"))
	if btn_lang_en != null:
		btn_lang_en.pressed.connect(func() -> void: _set_language("en"))
	if btn_lang_es != null:
		btn_lang_es.pressed.connect(func() -> void: _set_language("es"))

	_init_language_styles()
	var current_loc: String = SaveManager.get_locale() if SaveManager != null else TranslationServer.get_locale()
	_update_language_buttons(current_loc)
	_update_all_localized_texts()

func is_open() -> bool:
	return visible and not _is_closing

func _unhandled_input(event: InputEvent) -> void:
	if not visible or _is_closing:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_modal()

func open_modal() -> void:
	_is_closing = false
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
	if _is_closing:
		return
	_is_closing = true
	if AudioManager != null:
		AudioManager.play_sfx("close")
	var tw: Tween = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		visible = false
		_is_closing = false
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
			_show_toast("Qualidade 3D: Balanceada (85% FSR)")
		_:
			graphics_quality = "balanced"
			_show_toast("Qualidade 3D: Balanceada (85% FSR)")

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
		_show_toast("Vibração Ativada!")

func _on_android_vib_hint_pressed() -> void:
	_waiting_for_android_haptic_toggle = true
	_open_android_sound_settings()

func _apply_switch_state(btn: BaseButton, state_lbl: Label, is_on: bool) -> void:
	if btn is TextureButton:
		var tb: TextureButton = btn as TextureButton
		tb.texture_normal = TEX_TOGGLE_ON if is_on else TEX_TOGGLE_OFF
		tb.texture_pressed = TEX_TOGGLE_ON if is_on else TEX_TOGGLE_OFF
	if state_lbl != null:
		state_lbl.text = tr("SETTINGS_ON") if is_on else tr("SETTINGS_OFF")
		state_lbl.offset_left = 12.0 if is_on else 42.0
		state_lbl.offset_right = -40.0 if is_on else -10.0
		state_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0) if is_on else Color(0.62, 0.72, 0.85, 1.0))

func _update_toggle_visuals() -> void:
	if graphics_btn is Button:
		var gb: Button = graphics_btn as Button
		match graphics_quality:
			"high":
				gb.text = "Gráficos 3D: Alta (100% Nativa)"
			"eco":
				gb.text = "Gráficos 3D: Econômica (70% FSR)"
			_:
				gb.text = "Gráficos 3D: Balanceada (85% FSR)"

	_apply_switch_state(music_btn, music_state_label, music_enabled)
	_apply_switch_state(sfx_btn, sfx_state_label, sfx_enabled)
	_apply_switch_state(vib_btn, vib_state_label, vib_enabled)

	if android_vib_hint_btn != null:
		var haptic_on: bool = _is_android_haptic_feedback_enabled()
		if not haptic_on:
			android_vib_hint_btn.visible = true
			android_vib_hint_btn.text = "Retorno Tátil desligado no Android (Abrir Config)"
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
			_show_toast(tr("SETTINGS_TOAST_SAVED"))
		else:
			_show_toast("Erro ao gravar dados no armazenamento.")
	else:
		_show_toast(tr("SETTINGS_TOAST_SAVED"))

func _on_reset_pressed() -> void:
	if not _reset_confirmation_pending:
		_reset_confirmation_pending = true
		_show_toast(tr("SETTINGS_RESET_CONFIRM"))
		if reset_label != null:
			reset_label.text = tr("SETTINGS_RESET_CONFIRM")
		var tw: Tween = create_tween()
		tw.tween_interval(4.0)
		tw.tween_callback(func() -> void:
			_reset_confirmation_pending = false
			if reset_label != null:
				reset_label.text = tr("SETTINGS_RESET")
		)
	else:
		_reset_confirmation_pending = false
		if reset_label != null:
			reset_label.text = tr("SETTINGS_RESET")
		if SaveManager != null:
			SaveManager.reset_to_defaults()
		_show_toast(tr("SETTINGS_TOAST_RESET"))

func _init_language_styles() -> void:
	if _style_lang_active != null:
		return
	_style_lang_active = StyleBoxFlat.new()
	_style_lang_active.bg_color = Color(0.08, 0.35, 0.28, 0.95)
	_style_lang_active.border_color = Color(0.25, 0.95, 0.65, 1.0)
	_style_lang_active.border_width_left = 2
	_style_lang_active.border_width_top = 2
	_style_lang_active.border_width_right = 2
	_style_lang_active.border_width_bottom = 2
	_style_lang_active.corner_radius_top_left = 6
	_style_lang_active.corner_radius_top_right = 6
	_style_lang_active.corner_radius_bottom_right = 6
	_style_lang_active.corner_radius_bottom_left = 6

	_style_lang_inactive = StyleBoxFlat.new()
	_style_lang_inactive.bg_color = Color(0.06, 0.1, 0.16, 0.75)
	_style_lang_inactive.border_color = Color(0.18, 0.26, 0.38, 0.8)
	_style_lang_inactive.border_width_left = 1
	_style_lang_inactive.border_width_top = 1
	_style_lang_inactive.border_width_right = 1
	_style_lang_inactive.border_width_bottom = 1
	_style_lang_inactive.corner_radius_top_left = 6
	_style_lang_inactive.corner_radius_top_right = 6
	_style_lang_inactive.corner_radius_bottom_right = 6
	_style_lang_inactive.corner_radius_bottom_left = 6

func _apply_lang_button_style(btn: Button, is_active: bool) -> void:
	if btn == null:
		return
	var style: StyleBoxFlat = _style_lang_active if is_active else _style_lang_inactive
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0) if is_active else Color(0.55, 0.68, 0.82, 0.9))

func _update_language_buttons(active_locale: String) -> void:
	if _style_lang_active == null or _style_lang_inactive == null:
		_init_language_styles()

	var is_pt: bool = active_locale.begins_with("pt")
	var is_es: bool = active_locale.begins_with("es")
	var is_en: bool = not is_pt and not is_es

	_apply_lang_button_style(btn_lang_pt, is_pt)
	_apply_lang_button_style(btn_lang_en, is_en)
	_apply_lang_button_style(btn_lang_es, is_es)

func _set_language(new_locale: String) -> void:
	if SaveManager != null:
		SaveManager.set_locale(new_locale)
	else:
		TranslationServer.set_locale(new_locale)
	_update_language_buttons(new_locale)
	_update_all_localized_texts()
	if AudioManager != null:
		AudioManager.play_sfx("confirm")

func _update_all_localized_texts() -> void:
	if modal_title_label != null:
		modal_title_label.text = tr("SETTINGS_TITLE")
	if audio_section_label != null:
		audio_section_label.text = tr("SETTINGS_AUDIO_SECTION")
	if music_title_label != null:
		music_title_label.text = tr("SETTINGS_MUSIC")
	if sfx_title_label != null:
		sfx_title_label.text = tr("SETTINGS_SFX")
	if vib_title_label != null:
		vib_title_label.text = tr("SETTINGS_VIBRATION")
	if lang_title_label != null:
		lang_title_label.text = tr("SETTINGS_LANGUAGE")
	if save_section_label != null:
		save_section_label.text = tr("SETTINGS_SAVE_SECTION")
	if save_local_label != null:
		save_local_label.text = tr("SETTINGS_SAVE_LOCAL")
	if google_label != null:
		google_label.text = tr("SETTINGS_CONNECT_GOOGLE")
	if fb_label != null:
		fb_label.text = tr("SETTINGS_CONNECT_FB")
	if reset_label != null and not _reset_confirmation_pending:
		reset_label.text = tr("SETTINGS_RESET")
	if support_label != null:
		support_label.text = tr("SETTINGS_SUPPORT")
	_update_toggle_visuals()

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
