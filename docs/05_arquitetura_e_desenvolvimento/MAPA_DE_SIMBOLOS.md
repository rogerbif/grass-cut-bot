# Mapa de Símbolos GDScript & Cenas (CodeGraph Godot 4) 🗺️⚡

> Índice estrutural gerado automaticamente por `tools/build_gd_graph.py`. Consulte este mapa (ou use `python tools/build_gd_graph.py --query <termo>`) antes de abrir scripts completos para ler apenas o intervalo exato de linhas.

- **Scripts indexados:** 72 | **Funções:** 1004 | **Signals:** 85
- **Cenas indexadas:** 52

---

## 1. Scripts GDScript (`scripts/`)

### `scripts/camera/isometric_camera.gd` (172 linhas · `extends Camera3D`)
- **Consts:** `MIN_DISTANCE_RATIO`, `MAX_DISTANCE_RATIO`, `ZOOM_TWEEN_DURATION`, `VICTORY_OFFSET`, `VICTORY_ROTATION`
- **Funções:**
  - `L37-L67` `func _ready() -> void`
  - `L69-L72` `func get_target_offset_for_level(lvl: int) -> Vector3`
  - `L74-L90` `func _apply_blade_level_zoom(lvl: int, animate: bool = true) -> void`
  - `L92-L93` `func _on_blade_level_changed(new_level: int, _is_max: bool) -> void`
  - `L95-L97` `func _on_state_changed(new_state: int) -> void`
  - `L99-L100` `func _on_level_won(_coins: int, _stars: int) -> void`
  - `L102-L103` `func _on_level_lost(_reason: String) -> void`
  - `L105-L121` `func transition_to_victory_cam() -> void`
  - `L123-L136` `func reset_cam() -> void`
  - `L138-L140` `func _on_shake_requested(intensity: float, duration: float) -> void`
  - `L142-L172` `func _physics_process(delta: float) -> void`

### `scripts/core/audio_manager.gd` (349 linhas · `extends Node`)
- **Consts:** `MUSIC_MENU`, `MUSIC_GAMEPLAY`, `SFX_GRASS_CUT`, `SFX_CUT_FRUIT`, `SFX_SLAP_ROCK`, `SFX_ELECTRIC_ENGINE`, `SFX_COIN_PICKUP`, `SFX_TIMER_COUNTDOWN`, `SFX_GOAL_COMPLETED`, `SFX_LEVEL_COMPLETED`, `SFX_STAR_POP`, `SFX_MACHINE_POWER_OFF` *(+14)*
- **Funções:**
  - `L63-L71` `func _ready() -> void`
  - `L73-L94` `func _init_sfx_map() -> void`
  - `L96-L127` `func _create_audio_players() -> void`
  - `L129-L135` `func _sync_settings_from_save() -> void`
  - `L141-L142` `func play_menu_music(fade_duration: float = 0.4) -> void`
  - `L144-L145` `func play_gameplay_music(fade_duration: float = 0.4) -> void`
  - `L147-L157` `func stop_music(fade_duration: float = 0.4) -> void`
  - `L159-L182` `func _switch_music_stream(target_stream: AudioStream, target_volume_db: float, fade_duration: float) -> void`
  - `L188-L212` `func play_sfx(key: String, pitch_range: float = 0.0, volume_offset_db: float = 0.0) -> void`
  - `L214-L226` `func _get_next_sfx_player() -> AudioStreamPlayer`
  - `L232-L251` `func play_cut_sfx(is_special: bool = false) -> void`
  - `L253-L267` `func play_coin_sfx() -> void`
  - `L269-L278` `func play_countdown_alert() -> void`
  - `L280-L282` `func stop_countdown_alert() -> void`
  - `L288-L294` `func start_engine() -> void`
  - `L296-L298` `func stop_engine() -> void`
  - `L300-L315` `func update_engine_speed(speed_ratio: float) -> void`
  - `L321-L332` `func set_music_enabled(enabled: bool) -> void`
  - `L334-L343` `func set_sfx_enabled(enabled: bool) -> void`
  - `L345-L346` `func is_music_enabled() -> bool`
  - `L348-L349` `func is_sfx_enabled() -> bool`

### `scripts/core/game_manager.gd` (471 linhas · `extends Node`)
- **Signals:** `state_changed(new_state: int)`, `time_updated(time_left: float)`, `goal_updated(plant_type: String, remaining: int, target: int)`, `goal_completed(plant_type: String)`, `level_won(coins_earned: int, stars_earned: int)`, `level_lost(reason: String)`, `game_paused(is_paused: bool)`, `camera_shake_requested(intensity: float, duration: float)`, `coin_popup_requested(world_pos: Vector3, amount: int, plant_type: String)`, `goal_item_collected(plant_type: String, world_pos: Vector3)`
- **Consts:** `TilePaletteDB`, `DEFEAT_REASON_TIME_UP`, `DEFEAT_REASON_ROBOT_BROKEN`, `FPS_PLAYING`, `FPS_PAUSED`, `FPS_BACKGROUND`, `HAPTIC_CUT_COOLDOWN_MS`, `HAPTIC_CUT_DURATION_MS`, `HAPTIC_CUT_AMPLITUDE`, `HAPTIC_IMPACT_DURATION_MS`, `HAPTIC_IMPACT_AMPLITUDE`, `HAPTIC_UI_COOLDOWN_MS` *(+2)*
- **Funções:**
  - `L54-L61` `func _enter_tree() -> void`
  - `L63-L68` `func _ready() -> void`
  - `L70-L82` `func _notification(what: int) -> void`
  - `L84-L87` `func _init_graphics_quality() -> void`
  - `L89-L90` `func is_eco_graphics() -> bool`
  - `L92-L111` `func apply_graphics_quality(profile: String) -> void`
  - `L113-L117` `func _apply_shadow_quality_recursive(node: Node, shadows_enabled: bool) -> void`
  - `L119-L124` `func _on_scene_node_added(node: Node) -> void`
  - `L126-L131` `func _scan_and_connect_buttons(node: Node) -> void`
  - `L133-L142` `func _process(delta: float) -> void`
  - `L144-L173` `func start_level(level_index: int, level_goals: Dictionary, duration_seconds: float) -> void`
  - `L175-L223` `func register_cut(plant_type: String, base_coins: int = 1, cut_pos: Vector3 = Vector3.ZERO) -> void`
  - `L226-L239` `func get_remaining_goal(plant_type: String) -> int`
  - `L241-L252` `func _check_victory() -> void`
  - `L254-L273` `func _trigger_victory_celebration() -> void`
  - `L276-L286` `func get_progress_ratio() -> float`
  - `L289-L296` `func get_remaining_goals() -> Dictionary`
  - `L299-L310` `func get_goals_summary() -> Array[Dictionary]`
  - `L313-L314` `func can_grant_extra_time() -> bool`
  - `L317-L327` `func grant_extra_time(seconds: float) -> void`
  - `L330-L341` `func repair_robot_and_continue() -> void`
  - `L344-L347` `func trigger_robot_broken() -> void`
  - `L349-L360` `func _check_game_over(reason: String) -> void`
  - `L362-L380` `func toggle_pause() -> void`
  - `L384-L393` `func get_total_levels() -> int`
  - `L395-L398` `func restart_level() -> void`
  - `L400-L414` `func next_level() -> void`
  - `L416-L432` `func trigger_haptic_cut() -> void`
  - `L434-L441` `func trigger_haptic_impact() -> void`
  - `L443-L459` `func trigger_haptic_ui() -> void`
  - `L461-L465` `func _unhandled_input(event: InputEvent) -> void`
  - `L467-L471` `func toggle_fullscreen() -> void`

### `scripts/core/game_version.gd` (87 linhas · `class_name GameVersion` · `extends RefCounted`)
- **Consts:** `MAJOR`, `MINOR`, `PATCH`, `STAGE`, `BUILD_TYPE`
- **Funções:**
  - `L16-L23` `static func get_raw_version() -> String`
  - `L26-L30` `static func get_version_string() -> String`
  - `L33-L34` `static func get_display_name() -> String`
  - `L37-L43` `static func get_version_code() -> int`
  - `L46-L47` `static func is_pre_alpha() -> bool`
  - `L50-L51` `static func is_alpha() -> bool`
  - `L54-L55` `static func is_beta() -> bool`
  - `L58-L59` `static func is_rc() -> bool`
  - `L62-L63` `static func is_release() -> bool`
  - `L66-L87` `static func get_full_info() -> Dictionary`

### `scripts/core/save_manager.gd` (728 linhas · `extends Node`)
- **Signals:** `save_completed(success: bool)`, `save_loaded`, `save_reset`, `plant_harvested(species_key: String, new_count: int)`, `milestone_claimed(species_key: String, milestone_level: int, reward: int)`, `lives_changed(current_lives: int, max_lives: int)`, `daily_bonus_claimed(day_index: int, coin_reward: int)`
- **Consts:** `TilePaletteDB`, `SAVE_PATH`, `TEMP_PATH`, `BAK_PATH`, `CURRENT_SAVE_VERSION`, `MAX_LIVES`, `LIFE_REGEN_SECONDS`, `DAILY_BONUS_REWARDS`
- **Funções:**
  - `L29-L34` `func _ready() -> void`
  - `L36-L42` `func _process(delta: float) -> void`
  - `L44-L52` `func _notification(what: int) -> void`
  - `L54-L93` `func get_default_save() -> Dictionary`
  - `L95-L144` `func load_game() -> bool`
  - `L146-L200` `func _merge_with_defaults(loaded: Dictionary) -> Dictionary`
  - `L202-L217` `func _apply_loaded_data_to_systems() -> void`
  - `L219-L223` `func save_game_deferred() -> void`
  - `L225-L227` `func _flush_deferred_save() -> void`
  - `L229-L296` `func save_game() -> bool`
  - `L298-L349` `func record_level_victory(level_num: int, time_left: float, time_limit: float, coins_earned: int) -> int`
  - `L351-L358` `func get_level_best_time_taken(level_num: int) -> float`
  - `L360-L366` `func get_level_completion_count(level_num: int) -> int`
  - `L368-L369` `func has_level_record(level_num: int) -> bool`
  - `L371-L376` `func is_level_unlocked(level_num: int) -> bool`
  - `L378-L383` `func get_level_stars(level_num: int) -> int`
  - `L385-L387` `func get_max_unlocked_level() -> int`
  - `L389-L391` `func get_last_played_level() -> int`
  - `L393-L399` `func set_last_played_level(lvl: int) -> void`
  - `L401-L403` `func get_setting(key: String, default_val: Variant) -> Variant`
  - `L405-L409` `func set_setting(key: String, val: Variant) -> void`
  - `L411-L416` `func get_locale() -> String`
  - `L418-L420` `func set_locale(new_locale: String) -> void`
  - `L422-L430` `func detect_default_locale() -> String`
  - `L432-L434` `func apply_saved_locale() -> void`
  - `L436-L458` `func record_plant_harvest(species_key: String, amount: int = 1) -> void`
  - `L460-L463` `func is_species_discovered(species_key: String) -> bool`
  - `L465-L468` `func get_harvest_count(species_key: String) -> int`
  - `L470-L476` `func get_total_harvest_count() -> int`
  - `L478-L485` `func get_discovered_species_count() -> int`
  - `L487-L490` `func get_claimed_milestone_level(species_key: String) -> int`
  - `L492-L508` `func claim_milestone_level(species_key: String, milestone_lvl: int, coin_reward: int) -> bool`
  - `L510-L530` `func reset_to_defaults() -> void`
  - `L536-L570` `func _refresh_lives_regen(save_if_changed: bool = true) -> void`
  - `L572-L575` `func get_lives() -> int`
  - `L577-L588` `func get_seconds_to_next_life() -> int`
  - `L590-L604` `func consume_life() -> bool`
  - `L606-L618` `func add_lives(amount: int) -> void`
  - `L620-L621` `func refill_lives_full() -> void`
  - `L627-L640` `func _get_local_day_index() -> int`
  - `L642-L648` `func can_claim_daily_bonus() -> bool`
  - `L650-L664` `func get_daily_bonus_effective_streak() -> int`
  - `L666-L670` `func get_daily_bonus_next_day() -> int`
  - `L672-L674` `func get_daily_bonus_reward_for_day(day_num: int) -> int`
  - `L676-L691` `func get_seconds_until_next_daily_bonus() -> int`
  - `L693-L728` `func claim_daily_bonus() -> Dictionary`

### `scripts/core/upgrade_manager.gd` (263 linhas · `extends Node`)
- **Signals:** `coins_changed(new_amount: int)`, `upgrade_purchased(upgrade_name: String, new_level: int)`, `blade_level_changed(new_level: int, is_max: bool)`, `blade_leveled_up(new_level: int, is_max: bool)`, `blade_xp_changed(current_xp: float, max_xp: float, progress_ratio: float)`, `blade_penalized(new_level: int)`
- **Consts:** `MAX_BLADE_LEVEL`, `BLADE_ROCK_PENALTY_XP`, `XP_REQUIREMENTS`, `BLADE_COSTS`, `MAX_BLADE_RADIUS`
- **Funções:**
  - `L55-L59` `func _ready() -> void`
  - `L61-L70` `func load_from_dict(upgrades: Dictionary, coins: int) -> void`
  - `L72-L80` `func export_to_dict() -> Dictionary`
  - `L82-L83` `func add_coins(amount: int) -> void`
  - `L85-L89` `func spend_coins(amount: int) -> bool`
  - `L92-L95` `func get_xp_required_for_next_level() -> float`
  - `L97-L103` `func get_progress_ratio() -> float`
  - `L105-L106` `func is_max_level() -> bool`
  - `L108-L127` `func add_blade_xp(amount: float) -> void`
  - `L131-L172` `func penalize_blade_hit(penalty_amount: float = BLADE_ROCK_PENALTY_XP) -> bool`
  - `L177-L178` `static func get_max_blade_radius() -> float`
  - `L180-L182` `func get_blade_radius() -> float`
  - `L184-L186` `func get_cutter_speed() -> float`
  - `L188-L189` `func get_cutter_power() -> int`
  - `L191-L192` `func get_coin_multiplier() -> int`
  - `L194-L201` `func get_blade_tier() -> int`
  - `L203-L209` `func get_blade_tier_name() -> String`
  - `L212-L216` `func get_blade_upgrade_cost() -> int`
  - `L218-L222` `func can_buy_blade_upgrade() -> bool`
  - `L224-L247` `func buy_blade_upgrade() -> bool`
  - `L250-L253` `func get_upgrade_cost(upgrade_name: String) -> int`
  - `L255-L258` `func buy_upgrade(upgrade_name: String) -> bool`
  - `L260-L263` `func get_level(upgrade_name: String) -> int`

### `scripts/cutter/blade_progress_bar.gd` (164 linhas · `class_name BladeProgressBar` · `extends Node3D`)
- **Consts:** `TEXTURE_FILL_NORMAL`, `TEXTURE_FILL_MAX`, `COLOR_FLASH_DAMAGE`, `COLOR_LABEL_NORMAL`, `COLOR_LABEL_MAX`, `COLOR_OUTLINE_NORMAL`, `COLOR_OUTLINE_MAX`, `SCREEN_OFFSET`
- **Funções:**
  - `L31-L52` `func _ready() -> void`
  - `L54-L57` `func _process(_delta: float) -> void`
  - `L59-L61` `func _request_viewport_update() -> void`
  - `L63-L69` `func _set_progress_value(val: float) -> void`
  - `L71-L85` `func _setup_styles() -> void`
  - `L87-L94` `func _on_blade_level_changed(new_level: int, is_max: bool) -> void`
  - `L96-L109` `func _on_blade_xp_changed(_current_xp: float, _max_xp: float, progress_ratio: float) -> void`
  - `L111-L112` `func _on_blade_penalized(_new_level: int) -> void`
  - `L114-L116` `func _notification(what: int) -> void`
  - `L118-L140` `func _update_visual_theme() -> void`
  - `L142-L149` `func play_level_up_reaction() -> void`
  - `L151-L164` `func play_penalty_reaction() -> void`

### `scripts/cutter/cutter.gd` (1034 linhas · `extends CharacterBody3D`)
- **Funções:**
  - `L98-L140` `func _ready() -> void`
  - `L142-L146` `func _exit_tree() -> void`
  - `L148-L158` `func _apply_compat_blade_tint(mi: MeshInstance3D) -> void`
  - `L161-L174` `func _setup_eyes() -> void`
  - `L176-L211` `func _on_game_state_changed(new_state: int) -> void`
  - `L214-L237` `func reset_orientation_to_camera() -> void`
  - `L239-L319` `func play_victory_celebration() -> void`
  - `L321-L350` `func _process_victory_idle_behavior(delta: float) -> void`
  - `L352-L390` `func play_defeat_reaction() -> void`
  - `L392-L400` `func _update_shader_globals() -> void`
  - `L402-L403` `func _on_upgrade_purchased(_upgrade_name: String, _level: int) -> void`
  - `L405-L406` `func _on_blade_level_changed(_new_level: int, _is_max: bool) -> void`
  - `L408-L409` `func _on_blade_leveled_up(_new_level: int, _is_max: bool) -> void`
  - `L411-L442` `func _setup_blade_slash_and_shockwave() -> void`
  - `L444-L464` `func _start_gpu_warmup() -> void`
  - `L466-L509` `func _trigger_level_up_effects() -> void`
  - `L511-L523` `func _update_blade_slash_intensity() -> void`
  - `L525-L547` `func update_upgrades() -> void`
  - `L549-L561` `func _sync_blade_spinner_transform() -> void`
  - `L563-L587` `func _update_blade_tier_visual() -> void`
  - `L589-L593` `func set_input_direction(dir: Vector2) -> void`
  - `L595-L705` `func _physics_process(delta: float) -> void`
  - `L707-L793` `func _process_procedural_motion(delta: float, target_speed: float) -> void`
  - `L796-L848` `func rebuild_obstacles_cache() -> void`
  - `L850-L896` `func _check_obstacle_collisions() -> void`
  - `L898-L906` `func _check_slide_collisions() -> void`
  - `L908-L948` `func _trigger_obstacle_shock(normal: Vector3, spark_pos: Vector3 = Vector3.ZERO) -> void`
  - `L950-L955` `func _sync_initial_overlaps() -> void`
  - `L957-L962` `func _on_blade_area_entered(area: Area3D) -> void`
  - `L964-L967` `func _on_blade_area_exited(area: Area3D) -> void`
  - `L969-L972` `func _trigger_plant_first_hit_knockback(_normal: Vector3) -> void`
  - `L974-L993` `func _cut_vegetation_area(area: Area3D) -> bool`
  - `L995-L1016` `func _process_cutting() -> void`
  - `L1020-L1028` `func get_body_side_local_offset(cut_pos: Vector3) -> Vector3`
  - `L1032-L1033` `func get_inner_blade_point(cut_pos: Vector3) -> Vector3`

### `scripts/cutter/robot_eyes.gd` (207 linhas · `class_name RobotEyes` · `extends Node`)
- **Consts:** `COLOR_CYAN`, `COLOR_RED_ANGRY`, `COLOR_YELLOW_ALERT`
- **Funções:**
  - `L43-L46` `func _ready() -> void`
  - `L48-L61` `func _init_screen_material() -> void`
  - `L63-L85` `func _process(delta: float) -> void`
  - `L87-L88` `func _reset_blink_timer() -> void`
  - `L91-L113` `func set_expression(expr: EyeExpression, custom_color: Color = Color.TRANSPARENT, duration: float = 0.0) -> void`
  - `L116-L134` `func play_blink(duration: float = 0.16) -> void`
  - `L137-L140` `func set_look_direction(direction: Vector2) -> void`
  - `L143-L159` `func trigger_obstacle_reaction() -> void`
  - `L162-L175` `func trigger_victory_reaction() -> void`
  - `L178-L187` `func trigger_defeat_reaction() -> void`
  - `L190-L194` `func set_screen_off(is_off: bool) -> void`
  - `L196-L207` `func _animate_color(new_color: Color, duration: float) -> void`

### `scripts/editor/brush_patterns.gd` (594 linhas · `extends RefCounted`)
- **Consts:** `SHAPE_INFO`, `IMAGE_PRESETS_META`, `HEART_SMALL`, `HEART_MEDIUM`, `HEART_LARGE`
- **Funções:**
  - `L69-L134` `static func get_brush_offsets(shape: int, brush_size: int, custom_params: Dictionary = {}) -> Array[Vector2i]`
  - `L136-L146` `static func get_box_cells(start_cell: Vector2i, end_cell: Vector2i) -> Array[Vector2i]`
  - `L148-L162` `static func _bitmap_to_offsets(rows: Array[String]) -> Array[Vector2i]`
  - `L165-L236` `static func get_field_offsets(shape: int, brush_size: int) -> Array[Vector2i]`
  - `L239-L246` `static func get_circle_polygon(center: Vector2, radius_m: float, segments: int = 24) -> PackedVector2Array`
  - `L403-L418` `static func get_normalized_image_polygons(image_id: String, invert: bool = false, epsilon: float = 1.5) -> Array[PackedVector2Array]`
  - `L420-L458` `static func extract_normalized_polygons_from_image(img: Image, invert: bool = false, epsilon: float = 1.5) -> Array[PackedVector2Array]`
  - `L460-L562` `static func get_or_build_brush_image(image_id: String) -> Image`
  - `L565-L594` `static func create_ribbon_polygon(stroke_points: Array[Vector2], width_m: float) -> PackedVector2Array`

### `scripts/editor/editor_camera.gd` (132 linhas · `extends Camera3D`)
- **Funções:**
  - `L20-L26` `func _ready() -> void`
  - `L28-L30` `func save_editor_view() -> void`
  - `L32-L37` `func restore_editor_view() -> void`
  - `L39-L42` `func toggle_top_down() -> bool`
  - `L44-L46` `func center_on_origin() -> void`
  - `L48-L82` `func handle_camera_input(event: InputEvent, ui_has_focus: bool, mouse_over_ui: bool) -> bool`
  - `L84-L116` `func _process(delta: float) -> void`
  - `L118-L132` `func _update_camera_transform(delta: float) -> void`

### `scripts/editor/grid_overlay.gd` (360 linhas · `extends Node3D`)
- **Consts:** `LevelJsonLoader`
- **Funções:**
  - `L19-L60` `func _ready() -> void`
  - `L183-L223` `func rebuild_grid(width: int, height: int, c_size: float = 0.40) -> void`
  - `L321-L346` `func update_mirror_axis(mirror_mode: int) -> void`
  - `L348-L352` `func toggle_grid_visibility() -> bool`
  - `L354-L356` `func set_grid_visible(p_visible: bool) -> void`
  - `L358-L359` `func is_grid_visible() -> bool`

### `scripts/editor/island_autotiler.gd` (69 linhas · `extends RefCounted`)
- **Funções:**
  - `L5-L14` `static func apply_autotile(terrain_grid: Dictionary) -> void`
  - `L16-L69` `static func compute_tile_for_cell(cell: Vector2i, terrain_grid: Dictionary) -> Dictionary`

### `scripts/editor/level_editor.gd` (2606 linhas · `extends Node3D`)
- **Consts:** `LevelJsonLoader`, `IslandMeshBuilder`, `TilePaletteDB`, `IslandAutotiler`, `BrushPatterns`, `LevelSerializer`, `VegetationFieldScript`, `VectorGrassFieldScript`, `VectorTerrainFieldScript`, `VegetationGridScript`, `FLOWER_SCENE`, `FLOWER_ROSE_SCENE` *(+13)*
- **Funções:**
  - `L31-L62` `static func _get_editor_vector_material(v_type: String) -> StandardMaterial3D`
  - `L130-L131` `func get_current_brush_params() -> Dictionary`
  - `L176-L202` `func _ready() -> void`
  - `L204-L206` `func _reset_grass_shader_interaction() -> void`
  - `L208-L224` `func _setup_desktop_window() -> void`
  - `L226-L240` `func _restore_mobile_window() -> void`
  - `L242-L277` `func _build_spawn_marker_mesh() -> void`
  - `L279-L392` `func _connect_ui_signals() -> void`
  - `L394-L397` `func _adjust_scale(delta_sz: int) -> void`
  - `L399-L406` `func _rotate_active_step_dir(direction: int, is_shift: bool) -> void`
  - `L408-L433` `func _sync_all_ui(recalc_goals: bool = true) -> void`
  - `L435-L670` `func _input(event: InputEvent) -> void`
  - `L672-L701` `func _update_hovered_cell(screen_pos: Vector2) -> void`
  - `L703-L714` `func _compute_aabb_2d(poly: PackedVector2Array) -> Rect2`
  - `L717-L752` `func _get_safe_coastal_island_polygons() -> Array[PackedVector2Array]`
  - `L754-L771` `func _get_box_vector_polygon(start_c: Vector2i, end_c: Vector2i) -> PackedVector2Array`
  - `L773-L909` `func _refresh_hover_preview() -> void`
  - `L911-L995` `func _apply_vector_polygon_to_active_layer(poly: PackedVector2Array, erase_mode: bool, recalc_goals: bool, center_cell: Vector2i = Vector2i(-1, -1)`
  - `L997-L1002` `func _apply_straight_line_at(from_pt: Vector2, to_pt: Vector2, erase_mode: bool) -> void`
  - `L1004-L1064` `func _apply_brush_at(center: Vector2i, erase_mode: bool) -> void`
  - `L1066-L1088` `func _apply_box_fill(start_c: Vector2i, end_c: Vector2i) -> void`
  - `L1090-L1199` `func _modify_single_cell(cell: Vector2i, erase_mode: bool, custom_rot: int = -1) -> bool`
  - `L1202-L1210` `func toggle_mirror_mode() -> void`
  - `L1213-L1243` `func _get_mirrored_cells(center_cell: Vector2i, base_rot: int = 0) -> Array[Dictionary]`
  - `L1246-L1272` `func _get_mirrored_polygons(poly: PackedVector2Array) -> Array[PackedVector2Array]`
  - `L1274-L1295` `func _place_spawn_at(cell: Vector2i) -> void`
  - `L1297-L1301` `func _rebuild_3d_world() -> void`
  - `L1303-L1347` `func _rebuild_terrain_3d() -> void`
  - `L1349-L1400` `func _rebuild_objects_3d() -> void`
  - `L1402-L1403` `func _rebuild_grass_3d() -> void`
  - `L1406-L1478` `func _build_editor_vector_ground() -> void`
  - `L1480-L1507` `func _update_layers_transparency() -> void`
  - `L1509-L1512` `func _mark_dirty(dirty: bool = true) -> void`
  - `L1514-L1523` `func toggle_layer_visibility(layer_idx: int) -> void`
  - `L1525-L1531` `func toggle_3d_grass_preview() -> void`
  - `L1533-L1594` `func _pick_at_cursor(cell: Vector2i, hit_2d: Vector2) -> bool`
  - `L1596-L1629` `func calculate_recommended_time_limit() -> float`
  - `L1631-L1639` `func apply_auto_calculated_time() -> void`
  - `L1641-L1645` `static func _set_container_transparency(node: Node, alpha_transparency: float) -> void`
  - `L1647-L1663` `func _push_undo_snapshot() -> void`
  - `L1665-L1683` `func perform_undo() -> void`
  - `L1685-L1703` `func perform_redo() -> void`
  - `L1705-L1727` `func _restore_snapshot(snap: Dictionary) -> void`
  - `L1729-L1730` `func _on_generate_base_island() -> void`
  - `L1732-L1864` `func _apply_flood_fill_at(cell: Vector2i, hit_2d: Vector2, replace_all: bool = false) -> void`
  - `L1866-L2000` `func apply_island_template(template_id: String) -> void`
  - `L2002-L2011` `func _process(delta: float) -> void`
  - `L2013-L2027` `func _perform_autosave() -> bool`
  - `L2029-L2065` `func validate_level_before_save() -> Array[String]`
  - `L2067-L2101` `func save_level_as(target_lvl_id: int) -> void`
  - `L2103-L2113` `func _on_clear_terrain() -> void`
  - `L2115-L2120` `func toggle_grid_visibility() -> void`
  - `L2122-L2132` `func cycle_snap_mode() -> void`
  - `L2134-L2143` `func _on_clear_objects() -> void`
  - `L2145-L2155` `func _on_clear_all() -> void`
  - `L2157-L2167` `func _on_convert_yellow_to_wheat() -> void`
  - `L2169-L2192` `func _on_grid_resize_requested(new_w: int, new_h: int) -> void`
  - `L2194-L2197` `func _on_save_and_load_level_requested(lvl_id: int) -> void`
  - `L2199-L2201` `func _on_level_load_requested(lvl_id: int) -> void`
  - `L2203-L2324` `func _load_or_init_level(lvl_id: int) -> void`
  - `L2326-L2371` `func _build_default_island_for_level(lvl_id: int) -> void`
  - `L2373-L2404` `func save_current_level_json() -> void`
  - `L2406-L2429` `func bake_current_level_tscn() -> void`
  - `L2431-L2435` `func toggle_playtest() -> void`
  - `L2437-L2546` `func _start_playtest() -> void`
  - `L2548-L2578` `func _stop_playtest() -> void`
  - `L2580-L2583` `func _on_game_time_updated(t_left: float) -> void`
  - `L2585-L2588` `func _on_game_goal_updated(_p_type: String, _rem: int, _target: int) -> void`
  - `L2590-L2592` `func _on_playtest_won(coins: int, _stars: int = 1) -> void`
  - `L2594-L2596` `func _on_playtest_lost(reason: String) -> void`
  - `L2598-L2606` `func _on_exit_to_game() -> void`

### `scripts/editor/level_editor_ui.gd` (2194 linhas · `extends Control`)
- **Signals:** `level_load_requested(level_id: int)`, `grid_resize_requested(new_width: int, new_height: int)`, `time_limit_changed(new_time: float)`, `generate_base_island_requested()`, `clear_terrain_requested()`, `toggle_grid_requested()`, `cycle_snap_requested()`, `clear_objects_requested()`, `clear_all_requested()`, `undo_requested()`, `redo_requested()`, `save_json_requested()`, `bake_tscn_requested()`, `playtest_toggled()`, `exit_to_game_requested()`, `layer_changed(layer_idx: int)`, `tool_changed(tool_idx: int)`, `brush_shape_changed(shape_idx: int)`, `corner_radius_changed(radius: float)`, `brush_size_changed(new_size: int)`, `rotate_requested()`, `rotate_step_requested(direction: int, is_shift: bool)`, `adjust_mode_changed(mode: int)`, `toggle_camera_view_requested()`, `toggle_mirror_mode_requested()`, `terrain_tile_selected(tile_id: String)`, `grass_item_selected(grass_id: String)`, `object_item_selected(obj_id: String)`, `convert_yellow_to_wheat_requested()`, `auto_calc_time_requested()`, `layer_visibility_toggled(layer_idx: int)`, `toggle_3d_grass_preview_requested()`, `save_and_load_level_requested(level_id: int)`, `island_template_requested(template_id: String)`, `save_as_requested(target_level_id: int)`, `brush_custom_params_changed(params: Dictionary)`
- **Consts:** `TilePaletteDB`, `BrushPatterns`, `GOALS_CATALOG`, `ISLAND_TEMPLATES_META`
- **Funções:**
  - `L278-L281` `func _ready() -> void`
  - `L283-L291` `func is_mouse_over_ui(mouse_pos: Vector2) -> bool`
  - `L293-L297` `func has_text_focus() -> bool`
  - `L299-L314` `func _build_ui() -> void`
  - `L316-L326` `func _make_panel_style(bg: Color, border: Color, radius: int = 10) -> StyleBoxFlat`
  - `L328-L338` `func _make_btn_style(bg: Color, border: Color, radius: int = 7) -> StyleBoxFlat`
  - `L340-L351` `func _create_styled_button(text_str: String, accent: Color, min_size: Vector2 = Vector2(0, 34)`
  - `L353-L361` `func _set_button_selected(btn: Button, selected: bool, accent: Color) -> void`
  - `L363-L574` `func _build_top_bar() -> void`
  - `L576-L1031` `func _build_left_panel() -> void`
  - `L1033-L1187` `func _build_right_panel() -> void`
  - `L1189-L1304` `func _build_goals_metric_section(parent_box: VBoxContainer) -> void`
  - `L1306-L1323` `func _build_bottom_bar() -> void`
  - `L1325-L1361` `func _build_variations_dock() -> void`
  - `L1363-L1427` `func _create_variation_card(v_data: Dictionary) -> Button`
  - `L1429-L1453` `func _set_variation_card_selected(btn: Button, selected: bool, v_data: Dictionary) -> void`
  - `L1455-L1505` `func _update_variations_dock(active_layer: int, active_object_id: String) -> void`
  - `L1507-L1532` `func _build_playtest_bar() -> void`
  - `L1534-L1543` `func _build_toast_container() -> void`
  - `L1545-L1565` `func show_toast(message: String, border_color: Color = Color(0.3, 0.9, 0.55)`
  - `L1567-L1569` `func set_corner_radius(r: float) -> void`
  - `L1571-L1588` `func set_active_layer(layer_idx: int) -> void`
  - `L1734-L1748` `func update_level_header(level_id: int, width: int, height: int, time_limit: float, force_time_sync: bool = false) -> void`
  - `L1750-L1756` `func set_level_time_limit(new_time: float) -> void`
  - `L1758-L1765` `func get_configured_time_limit() -> float`
  - `L1901-L1910` `func get_configured_goals() -> Dictionary`
  - `L1912-L1964` `func set_configured_goals(goals: Dictionary) -> void`
  - `L1966-L1972` `func update_status_bar(cell: Vector2i, in_bounds: bool, world_pos: Vector3) -> void`
  - `L1974-L1978` `func set_playtest_mode(active: bool) -> void`
  - `L1980-L2022` `func update_playtest_hud(time_left: float, goals: Dictionary) -> void`
  - `L2024-L2027` `func update_grid_button(is_grid_visible: bool) -> void`
  - `L2029-L2036` `func update_snap_button(snap_step: float) -> void`
  - `L2038-L2042` `func update_3d_grass_button(enabled: bool) -> void`
  - `L2044-L2056` `func update_layer_visibility_buttons(vis_dict: Dictionary) -> void`
  - `L2058-L2066` `func update_dirty_indicator(is_dirty: bool) -> void`
  - `L2068-L2083` `func _build_unsaved_dialog() -> void`
  - `L2085-L2093` `func _request_level_switch(target_lvl: int) -> void`
  - `L2095-L2100` `func _find_next_free_level_id() -> int`
  - `L2102-L2111` `func _update_save_as_status_label(target_id: int) -> void`
  - `L2113-L2156` `func _build_save_as_dialog() -> void`
  - `L2158-L2164` `func open_save_as_dialog(suggested_id: int = -1) -> void`
  - `L2166-L2172` `func toggle_clean_screen_mode() -> bool`
  - `L2174-L2179` `func _select_image_brush(img_id: String) -> void`
  - `L2181-L2191` `func _build_brush_file_dialog() -> void`

### `scripts/editor/level_serializer.gd` (312 linhas · `extends RefCounted`)
- **Consts:** `LevelJsonLoader`, `IslandMeshBuilder`, `LevelCardDataScript`, `LEVELS_JSON_DIR`, `LEVELS_TSCN_DIR`, `CELL_SIZE`
- **Funções:**
  - `L12-L13` `static func get_json_path(level_id: int) -> String`
  - `L16-L17` `static func get_tscn_path(level_id: int) -> String`
  - `L272-L279` `static func list_existing_levels() -> Array[int]`

### `scripts/editor/tile_palette_db.gd` (615 linhas · `extends RefCounted`)
- **Consts:** `ObstacleDatabaseScript`, `TERRAIN_ITEMS`, `GRASS_ITEMS`, `OBJECT_ITEMS`, `ITEM_VARIATIONS`
- **Funções:**
  - `L541-L546` `static func get_variations(base_id: String) -> Array`
  - `L548-L551` `static func has_variations(base_id: String) -> bool`
  - `L553-L561` `static func get_base_id_for_variant(variant_id: String) -> String`
  - `L563-L573` `static func get_variation_data(variant_id: String) -> Dictionary`
  - `L575-L597` `static func get_item_by_id(id_str: String) -> Dictionary`
  - `L599-L603` `static func get_terrain_info(tile_id: String) -> Dictionary`
  - `L605-L609` `static func get_grass_info(grass_id: String) -> Dictionary`
  - `L611-L615` `static func get_object_info(obj_id: String) -> Dictionary`

### `scripts/effects/floating_coin_manager.gd` (172 linhas · `class_name FloatingCoinManager` · `extends Node3D`)
- **Consts:** `POOL_SIZE`, `MAX_LOCAL_RADIUS_XZ`, `MIN_LATERAL_X`, `COLOR_GRASS`, `COLOR_WHEAT`, `COLOR_FLOWER`
- **Funções:**
  - `L24-L32` `func _ready() -> void`
  - `L35-L36` `func _process(_delta: float) -> void`
  - `L39-L44` `func _sync_to_cutter() -> CharacterBody3D`
  - `L47-L69` `func _init_pool() -> void`
  - `L72-L84` `func _get_cutter() -> CharacterBody3D`
  - `L87-L172` `func _on_coin_popup_requested(world_pos: Vector3, amount: int, plant_type: String) -> void`

### `scripts/level/island_mesh_builder.gd` (746 linhas · `class_name IslandMeshBuilder` · `extends RefCounted`)
- **Consts:** `CLIFF_DEPTH`, `BEVEL_DEPTH`, `BEVEL_OUTSET`, `FOAM_Y_LEVEL`, `FOAM_INSET`, `FOAM_WIDTH`, `BOUNDARY_WALL_HEIGHT`, `BOUNDARY_WALL_THICKNESS`, `DEFAULT_CORNER_RADIUS`, `DEFAULT_CORNER_ARC_STEPS`, `FIXED_MESH_AABB`, `UV_GRASS_TOP` *(+4)*
- **Funções:**
  - `L39-L40` `static func _is_compatibility_renderer() -> bool`
  - `L43-L52` `static func get_final_ground_color() -> Color`
  - `L55-L58` `static func get_final_cliff_color() -> Color`
  - `L77-L92` `static func get_island_material() -> StandardMaterial3D`
  - `L95-L106` `static func get_foam_material() -> ShaderMaterial`
  - `L314-L372` `static func _clip_cap_with_holes(outer: PackedVector2Array, holes: Array[PackedVector2Array]) -> Array[PackedVector2Array]`
  - `L688-L713` `static func _reduce_overlapping_polygons(input_polys: Array[PackedVector2Array]) -> Array[PackedVector2Array]`
  - `L717-L738` `static func _compute_vertex_normals(poly: PackedVector2Array) -> Array[Vector2]`
  - `L741-L746` `static func _reverse_polygon(poly: PackedVector2Array) -> PackedVector2Array`

### `scripts/level/level_card_data.gd` (162 linhas · `class_name LevelCardData` · `extends RefCounted`)
- **Consts:** `LevelJsonLoader`, `BIOME_NAME`, `LEVELS_DIR`, `CANONICAL_ISLAND_METAS`
- **Funções:**
  - `L74-L81` `static func get_cached_level_json(level_num: int) -> Dictionary`
  - `L85-L121` `static func get_cached_island_meta(level_num: int) -> Dictionary`
  - `L125-L132` `static func compute_goals(data: Dictionary) -> Dictionary`
  - `L136-L151` `static func get_level_card_data(level_num: int) -> Dictionary`
  - `L154-L157` `static func clear_cache() -> void`
  - `L160-L162` `static func format_time(seconds: float) -> String`

### `scripts/level/level_controller.gd` (88 linhas · `extends Node3D`)
- **Consts:** `LevelJsonLoader`, `VegetationGridScript`, `ThemeDatabase`, `IslandThemeData`
- **Funções:**
  - `L16-L17` `func _ready() -> void`
  - `L20-L84` `func generate_level(level_num: int) -> void`
  - `L87-L88` `func get_vegetation_grid() -> Node3D`

### `scripts/level/level_json_loader.gd` (180 linhas · `extends RefCounted`)
- **Consts:** `ObstacleDatabaseScript`, `DEFAULT_CELL_SIZE`, `WATER_OCEAN_SCENE`, `FLOWER_VARIATION_MATERIALS`, `OBJECT_SCENES`
- **Funções:**
  - `L77-L84` `static func grid_to_world(gx: int, gz: int, width: int, height: int, cell_size: float = DEFAULT_CELL_SIZE) -> Vector3`
  - `L86-L91` `static func world_to_grid(world_pos: Vector3, width: int, height: int, cell_size: float = DEFAULT_CELL_SIZE) -> Vector2i`
  - `L93-L112` `static func load_json_file(path: String) -> Dictionary`
  - `L114-L140` `static func get_island_polygons(data: Dictionary) -> Array[PackedVector2Array]`
  - `L143-L162` `static func get_island_holes(data: Dictionary) -> Array[PackedVector2Array]`
  - `L164-L180` `static func instantiate_object_node(obj_type: String, rot_deg: int = 0) -> Node3D`

### `scripts/level/vector_grass_field.gd` (741 linhas · `class_name VectorGrassField` · `extends RefCounted`)
- **Consts:** `MIN_TUFT_DISTANCE`, `EDGE_TAPER_DISTANCE`
- **Funções:**
  - `L29-L30` `static func clear_global_cache() -> void`
  - `L32-L36` `func _init() -> void`
  - `L38-L42` `func clear() -> void`
  - `L44-L45` `func get_shapes() -> Array[Dictionary]`
  - `L48-L54` `func convert_shapes_type(from_type: String, to_type: String) -> int`
  - `L57-L84` `func add_shape(type_name: String, outer_poly: PackedVector2Array, holes_list: Array = []) -> int`
  - `L87-L96` `func get_shape_index_at_point(point: Vector2) -> int`
  - `L99-L109` `func recolor_shape_at_point(point: Vector2, new_type: String) -> bool`
  - `L112-L116` `func get_type_at_point(point: Vector2) -> String`
  - `L120-L184` `func merge_or_add_shape(type_name: String, new_poly: PackedVector2Array) -> void`
  - `L187-L232` `func clip_shapes_except(excluded_type: String, cutter_poly: PackedVector2Array) -> bool`
  - `L235-L277` `func clip_shapes(eraser_poly: PackedVector2Array) -> bool`
  - `L280-L335` `func _clip_polygon_without_holes(subject: PackedVector2Array, eraser: PackedVector2Array) -> Array[PackedVector2Array]`
  - `L339-L392` `func sample_all_tufts(min_dist: float = MIN_TUFT_DISTANCE) -> Array[Dictionary]`
  - `L395-L464` `func generate_ground_meshes() -> Dictionary`
  - `L467-L491` `func to_dict_list() -> Array[Dictionary]`
  - `L494-L519` `func from_dict_list(arr: Array) -> void`
  - `L522-L588` `func convert_from_legacy_field(field: RefCounted, _width_blocks: int, _height_blocks: int, block_cell_size: float = 0.80) -> void`
  - `L592-L603` `func _compute_poly_aabb(poly: PackedVector2Array) -> Rect2`
  - `L606-L701` `func _sample_poisson_in_polygon(poly: PackedVector2Array, holes_list: Array, min_dist: float, seed_val: int) -> Array[Vector2]`
  - `L703-L707` `func _is_point_in_any_hole(pt: Vector2, holes_list: Array) -> bool`
  - `L709-L741` `func _compute_min_distance_to_polygon_edge(pt: Vector2, poly: PackedVector2Array, max_dist: float = EDGE_TAPER_DISTANCE) -> float`

### `scripts/level/vector_terrain_field.gd` (588 linhas · `class_name VectorTerrainField` · `extends RefCounted`)
- **Funções:**
  - `L17-L18` `func _init() -> void`
  - `L21-L25` `func clear() -> void`
  - `L28-L29` `func is_empty() -> bool`
  - `L32-L33` `func get_outer_polygons() -> Array[PackedVector2Array]`
  - `L36-L37` `func get_holes() -> Array[PackedVector2Array]`
  - `L40-L41` `func get_base_outer_polygons() -> Array[PackedVector2Array]`
  - `L44-L45` `func get_base_holes() -> Array[PackedVector2Array]`
  - `L48-L49` `func get_corner_radius() -> float`
  - `L52-L54` `func set_corner_radius(r: float) -> void`
  - `L57-L69` `func _update_derived_polygons() -> void`
  - `L72-L80` `func set_outer_polygons(polys: Array[PackedVector2Array]) -> void`
  - `L83-L91` `func set_holes(hole_polys: Array[PackedVector2Array]) -> void`
  - `L95-L107` `func duplicate_field() -> VectorTerrainField`
  - `L111-L125` `func is_point_on_land(pt: Vector2) -> bool`
  - `L129-L137` `func fill_hole_at_point(pt: Vector2) -> bool`
  - `L141-L242` `func add_land(new_poly: PackedVector2Array) -> void`
  - `L246-L328` `func carve_water(cutter_poly: PackedVector2Array) -> void`
  - `L349-L389` `func to_dict() -> Dictionary`
  - `L393-L448` `func from_dict(data: Dictionary) -> void`
  - `L452-L463` `static func _compute_aabb(poly: PackedVector2Array) -> Rect2`
  - `L466-L472` `static func _compute_poly_center(poly: PackedVector2Array) -> Vector2`
  - `L475-L486` `static func _is_hole_inside_any_outer(h: PackedVector2Array, outers: Array[PackedVector2Array]) -> bool`
  - `L490-L532` `static func _merge_land_polygons(poly_a: PackedVector2Array, poly_b: PackedVector2Array) -> Dictionary`
  - `L535-L583` `static func _reduce_overlapping_polygons_with_holes(polys: Array[PackedVector2Array]) -> Dictionary`
  - `L586-L588` `static func _reduce_overlapping_polygons(polys: Array[PackedVector2Array]) -> Array[PackedVector2Array]`

### `scripts/level/vegetation_field.gd` (216 linhas · `extends RefCounted`)
- **Consts:** `CELL_RES`, `SUB_PER_BLOCK`, `TYPE_NAMES`, `CHAR_TO_TYPE`, `TYPE_TO_CHAR`
- **Funções:**
  - `L55-L56` `func _init(w_blocks: int = 12, h_blocks: int = 8) -> void`
  - `L58-L64` `func resize_blocks(w_blocks: int, h_blocks: int) -> void`
  - `L66-L67` `func clear() -> void`
  - `L69-L72` `func get_cell(cx: int, cz: int) -> int`
  - `L74-L77` `func set_cell(cx: int, cz: int, type_id: int) -> void`
  - `L79-L81` `static func type_name_to_id(t_name: String) -> int`
  - `L83-L86` `static func type_id_to_name(t_id: int) -> String`
  - `L89-L96` `func world_to_cell(world_pos: Vector3, block_cell_size: float = 0.80) -> Vector2i`
  - `L99-L108` `func cell_to_world(cx: int, cz: int, block_cell_size: float = 0.80) -> Vector3`
  - `L111-L120` `func to_rows() -> Array[String]`
  - `L122-L128` `func from_rows(row_strings: Array) -> void`
  - `L131-L165` `func from_legacy_objects(objects_arr: Array, w_blocks: int, h_blocks: int) -> void`
  - `L168-L215` `func compute_sdf_depth_map() -> PackedFloat32Array`

### `scripts/main.gd` (12 linhas · `extends Node3D`)
- **Funções:**
  - `L6-L8` `func _ready() -> void`
  - `L10-L12` `func _on_joystick_moved(direction: Vector2) -> void`

### `scripts/menu/bottom_nav_bar.gd` (37 linhas · `extends Control`)
- **Signals:** `tab_changed(tab_index: int)`
- **Funções:**
  - `L18-L23` `func _ready() -> void`
  - `L25-L32` `func select_tab(tab_id: int, emit_sig: bool = true) -> void`
  - `L34-L37` `func _on_nav_button_pressed(tab_id: int) -> void`

### `scripts/menu/island_node.gd` (755 linhas · `extends Node3D`)
- **Signals:** `island_selected(level_number: int)`
- **Consts:** `VegetationGrid`, `VegetationFieldScript`, `VectorGrassFieldScript`, `BrushPatterns`, `LevelJsonLoader`, `LevelCardDataScript`, `ObstacleDatabaseScript`, `ROCK_MODEL`, `MAT_ACTIVE_GRASS_GREEN`, `MAT_ACTIVE_GRASS_YELLOW`, `MAT_ACTIVE_GRASS_BLUE`, `MAT_ACTIVE_GRASS_PURPLE` *(+4)*
- **Funções:**
  - `L71-L76` `func setup_island(lvl: int, unlocked: bool, stars: int) -> void`
  - `L79-L85` `func read_island_metadata(lvl: int) -> void`
  - `L88-L97` `func _is_in_front_of_bot(pos: Vector3) -> bool`
  - `L100-L124` `func _set_rocks_in_front_hidden(hidden: bool) -> void`
  - `L127-L132` `func ensure_content_loaded() -> void`
  - `L135-L146` `static func _ensure_rock_mesh() -> void`
  - `L149-L180` `static func _get_vector_material(v_type: String) -> StandardMaterial3D`
  - `L183-L212` `static func _init_materials() -> void`
  - `L215-L257` `func set_grass_animated(enabled: bool) -> void`
  - `L260-L415` `func build_miniature_from_json(lvl: int) -> void`
  - `L418-L463` `func _get_base_clipped_vector_field() -> RefCounted`
  - `L466-L507` `func _build_vector_ground(data: Dictionary, width: int, height: int, cell_size: float) -> void`
  - `L510-L696` `func _ensure_3d_veg_built() -> void`
  - `L699-L722` `func _apply_mode_visibility() -> void`
  - `L725-L732` `func set_active_in_tree(is_active: bool) -> void`
  - `L735-L738` `func set_view_mode(map_view: bool, active_island: bool, _animated: bool = true) -> void`
  - `L741-L742` `func get_island_dimensions() -> Vector2`
  - `L745-L748` `func get_bot_position() -> Vector3`
  - `L751-L755` `func _on_click_area_input_event(_camera: Camera3D, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void`

### `scripts/menu/main_menu.gd` (658 linhas · `extends Node3D`)
- **Consts:** `ISLAND_SCENE`, `CLOUDS_END_SCENE`, `MenuGestureDetectorScript`
- **Funções:**
  - `L38-L117` `func _ready() -> void`
  - `L119-L122` `func _process(_delta: float) -> void`
  - `L124-L126` `func _on_save_reset() -> void`
  - `L128-L144` `func _setup_daily_bonus_button() -> void`
  - `L146-L156` `func _update_daily_bonus_indicator() -> void`
  - `L158-L256` `func _detect_levels_and_build_archipelago() -> void`
  - `L258-L281` `func _update_bot_position() -> void`
  - `L283-L310` `func _teleport_bot_to_level(lvl: int) -> void`
  - `L312-L334` `func _on_island_clicked(lvl_num: int) -> void`
  - `L336-L345` `func _on_camera_island_snapped(snapped_lvl: int) -> void`
  - `L347-L351` `func _on_camera_scroll_focus_changed(focused_lvl: int) -> void`
  - `L353-L355` `func _on_toggle_view_requested() -> void`
  - `L357-L363` `func _on_camera_view_mode_changed(is_map: bool) -> void`
  - `L365-L401` `func _update_islands_visibility(is_map: bool, focal_level: int) -> void`
  - `L403-L409` `func _load_surrounding_islands(focal_lvl: int) -> void`
  - `L411-L415` `func _update_plaques_view_mode(is_map: bool, animated: bool = true) -> void`
  - `L417-L420` `func _on_tab_changed(tab_idx: int) -> void`
  - `L422-L444` `func _switch_tab(tab_idx: int) -> void`
  - `L446-L456` `func _update_top_bar() -> void`
  - `L458-L461` `func _on_badge_plus_pressed() -> void`
  - `L464-L487` `func _on_play_level_requested(lvl_to_play: int) -> void`
  - `L493-L504` `func _get_safe_area_top_margin() -> float`
  - `L506-L525` `func _apply_safe_area() -> void`
  - `L527-L532` `func _notification(what: int) -> void`
  - `L534-L537` `func _unhandled_input(event: InputEvent) -> void`
  - `L540-L553` `func _input(event: InputEvent) -> void`
  - `L556-L566` `func _are_modals_open() -> bool`
  - `L569-L576` `func _on_gesture_swipe_horizontal(direction: int) -> void`
  - `L579-L581` `func _on_gesture_swipe_vertical(direction: int) -> void`
  - `L584-L616` `func _navigate_level_by_delta(delta: int) -> void`
  - `L619-L625` `func _trigger_level_boundary_feedback(direction: int) -> void`
  - `L627-L658` `func _handle_back_request() -> void`

### `scripts/menu/menu_bot.gd` (441 linhas · `extends Node3D`)
- **Consts:** `TELEPORT_SHADER`
- **Funções:**
  - `L66-L92` `func _ready() -> void`
  - `L94-L104` `func _apply_compat_blade_tint(mi: MeshInstance3D) -> void`
  - `L107-L122` `func _setup_eyes() -> void`
  - `L124-L140` `func _process(delta: float) -> void`
  - `L142-L152` `func _sync_blade_spinner_transform() -> void`
  - `L154-L219` `func _process_locomotion(delta: float) -> void`
  - `L221-L239` `func _process_head_motion(delta: float) -> void`
  - `L241-L257` `func _process_random_expressions(delta: float) -> void`
  - `L259-L260` `func _reset_state_timer(seconds: float) -> void`
  - `L262-L263` `func _reset_head_timer(seconds: float) -> void`
  - `L265-L266` `func _reset_expression_timer(seconds: float) -> void`
  - `L268-L292` `func update_blade_tier() -> void`
  - `L294-L309` `func _setup_blade_slash() -> void`
  - `L311-L312` `func _on_upgrade_purchased(_upgrade_name: String, _new_level: int) -> void`
  - `L314-L316` `func set_base_position(new_pos: Vector3) -> void`
  - `L322-L324` `func _set_teleport_mode(m: int) -> void`
  - `L326-L328` `func _set_teleport_world_y(y: float) -> void`
  - `L330-L338` `func _collect_mesh_instances(node: Node) -> Array[MeshInstance3D]`
  - `L340-L375` `func _apply_teleport_materials() -> void`
  - `L377-L385` `func _clear_teleport_materials() -> void`
  - `L387-L441` `func teleport_to_position(target_pos: Vector3, on_complete: Callable = Callable()`

### `scripts/menu/menu_camera.gd` (353 linhas · `extends Camera3D`)
- **Signals:** `view_mode_changed(is_map_view: bool)`, `island_snapped(level_number: int)`, `scroll_focus_changed(focused_level: int)`
- **Funções:**
  - `L42-L45` `func _ready() -> void`
  - `L47-L70` `func _process(delta: float) -> void`
  - `L72-L85` `func calculate_camera_z_offset(cam_y: float) -> float`
  - `L87-L89` `func set_island_waypoints(waypoints: Array[Vector3], dimensions: Array[Vector2] = []) -> void`
  - `L91-L92` `func set_island_positions(positions: Array[Vector3]) -> void`
  - `L94-L96` `func calculate_island_target_height(dim: Vector2) -> float`
  - `L98-L122` `func get_camera_height_at_z(scroll_z: float) -> float`
  - `L124-L151` `func get_camera_x_at_z(scroll_z: float) -> float`
  - `L153-L159` `func get_ground_z(screen_pos: Vector2) -> float`
  - `L161-L169` `func get_pixel_to_ground_ratio() -> float`
  - `L171-L200` `func _input(event: InputEvent) -> void`
  - `L202-L208` `func _start_drag(screen_pos: Vector2) -> void`
  - `L210-L227` `func _process_drag(current_screen_pos: Vector2) -> void`
  - `L229-L243` `func _end_drag() -> void`
  - `L245-L249` `func get_level_z(lvl: int) -> float`
  - `L251-L263` `func find_closest_level(scroll_z: float) -> int`
  - `L265-L281` `func snap_to_level(lvl: int, animated: bool = true) -> void`
  - `L283-L286` `func set_bot_target(bot_pos: Vector3) -> void`
  - `L288-L290` `func set_scroll_bounds(z_start: float, z_end: float) -> void`
  - `L292-L296` `func toggle_mode() -> void`
  - `L298-L326` `func switch_to_map_view() -> void`
  - `L328-L346` `func switch_to_bot_view() -> void`
  - `L348-L349` `func _on_transition_finished() -> void`
  - `L351-L353` `func _apply_bot_view_instant() -> void`

### `scripts/menu/menu_gesture_detector.gd` (124 linhas · `class_name MenuGestureDetector` · `extends RefCounted`)
- **Signals:** `swipe_horizontal(direction: int)`, `swipe_vertical(direction: int)`
- **Consts:** `MIN_SWIPE_DISTANCE`, `FLICK_VELOCITY_THRESHOLD`, `AXIS_DOMINANCE_RATIO`, `MAX_SWIPE_DURATION_SEC`
- **Funções:**
  - `L28-L32` `func reset() -> void`
  - `L37-L72` `func process_input(event: InputEvent) -> bool`
  - `L75-L80` `func _start_tracking(pos: Vector2, touch_id: int) -> void`
  - `L83-L124` `func _end_tracking(end_pos: Vector2) -> bool`

### `scripts/menu/tabs/tab_collection.gd` (915 linhas · `extends Control`)
- **Consts:** `PlantDatabaseScript`, `GoalIconFactoryScript`, `TEX_CARD_BG`, `TEX_BADGE_DISC`, `TEX_BADGE_LOCK`, `TEX_ICON_FRAME`, `TEX_BADGE_MILESTONE`, `TEX_BTN_CLAIM`, `TEX_ILLUS_LOCKED`
- **Funções:**
  - `L59-L70` `static func _get_card_sb(is_disc: bool) -> StyleBoxTexture`
  - `L72-L81` `static func _get_icon_frame_sb() -> StyleBoxTexture`
  - `L83-L93` `static func _get_bar_bg_sb() -> StyleBoxFlat`
  - `L95-L100` `static func _get_bar_fill_sb(col: Color) -> StyleBoxFlat`
  - `L102-L113` `static func _get_claim_sb() -> StyleBoxTexture`
  - `L115-L128` `static func _get_badge_sb() -> StyleBoxTexture`
  - `L130-L149` `static func _get_filter_sb(is_active: bool) -> StyleBoxFlat`
  - `L151-L153` `func _notification(what: int) -> void`
  - `L155-L163` `func _ready() -> void`
  - `L165-L177` `func _connect_signals() -> void`
  - `L181-L185` `func _on_plant_harvested(_species_key: String, _new_count: int) -> void`
  - `L187-L190` `func _on_visibility_changed() -> void`
  - `L193-L197` `func _on_milestone_claimed(species_key: String, _lvl: int, _reward: int) -> void`
  - `L199-L216` `func _process(delta: float) -> void`
  - `L220-L268` `func _on_scroll_gui_input(event: InputEvent) -> void`
  - `L270-L309` `func _init_filter_bar() -> void`
  - `L311-L318` `func _on_filter_selected(fid: String) -> void`
  - `L320-L329` `func _apply_active_filter() -> void`
  - `L332-L339` `func get_visible_cards_count() -> int`
  - `L341-L362` `func _is_matching_filter(key: String, sp: Dictionary, filter_id: String) -> bool`
  - `L364-L437` `func _update_filter_buttons(all_species: Array[Dictionary] = []) -> void`
  - `L439-L443` `func refresh_ui() -> void`
  - `L446-L483` `func _refresh_header() -> void`
  - `L486-L495` `func _refresh_single_card(species_key: String) -> void`
  - `L497-L513` `func _get_claimable_milestones_count(all_species: Array[Dictionary]) -> int`
  - `L515-L541` `func refresh_cards() -> void`
  - `L543-L700` `func _build_species_card(sp: Dictionary) -> PanelContainer`
  - `L702-L854` `func _update_card_view(card: PanelContainer, sp: Dictionary) -> void`
  - `L856-L865` `func _on_claim_milestone_pressed(species_key: String, milestone_lvl: int, coin_reward: int) -> void`
  - `L868-L904` `func _on_claim_all_pressed() -> void`
  - `L906-L915` `func _format_number(n: int) -> String`

### `scripts/menu/tabs/tab_garage.gd` (100 linhas · `extends Control`)
- **Funções:**
  - `L15-L17` `func _notification(what: int) -> void`
  - `L19-L28` `func _ready() -> void`
  - `L30-L84` `func refresh_ui() -> void`
  - `L86-L91` `func _on_buy_blade_pressed() -> void`
  - `L93-L94` `func _on_upgrade_purchased(_u_name: String, _new_lvl: int) -> void`
  - `L96-L97` `func _on_blade_level_changed(_new_lvl: int, _is_max: bool) -> void`
  - `L99-L100` `func _on_coins_changed(_new_val: int) -> void`

### `scripts/menu/tabs/tab_home.gd` (74 linhas · `extends Control`)
- **Signals:** `play_level_requested(level_number: int)`, `toggle_view_requested`
- **Consts:** `ICON_PLAY`, `ICON_MAP`
- **Funções:**
  - `L19-L22` `func _notification(what: int) -> void`
  - `L24-L29` `func _ready() -> void`
  - `L31-L37` `func update_level_display(lvl: int) -> void`
  - `L40-L46` `func preview_level(lvl: int) -> void`
  - `L48-L49` `func refresh_ui() -> void`
  - `L51-L61` `func set_view_mode(map_view: bool) -> void`
  - `L63-L69` `func _on_play_pressed() -> void`
  - `L71-L74` `func _on_toggle_pressed() -> void`

### `scripts/menu/tabs/tab_store.gd` (201 linhas · `extends Control`)
- **Consts:** `ICON_HEART`, `ICON_COIN`, `TEX_CARD_BG`, `TEX_BTN_BG`, `LIFE_REFILL_COST`
- **Funções:**
  - `L29-L31` `func _notification(what: int) -> void`
  - `L33-L41` `func _ready() -> void`
  - `L43-L49` `func _process(delta: float) -> void`
  - `L51-L53` `func refresh_ui() -> void`
  - `L55-L111` `func _build_lives_refill_card() -> void`
  - `L113-L144` `func _update_lives_card() -> void`
  - `L146-L161` `func _on_buy_lives_pressed() -> void`
  - `L163-L187` `func _refresh_texts() -> void`
  - `L189-L201` `func _on_free_pack_pressed() -> void`

### `scripts/obstacles/obstacle_database.gd` (251 linhas · `extends RefCounted`)
- **Consts:** `RockDataScript`, `OBSTACLES_DIR`, `DEFAULT_MATERIAL_PATH`, `CANONICAL_OBSTACLE_PATHS`
- **Funções:**
  - `L32-L39` `static func reload() -> void`
  - `L42-L44` `static func _ensure_loaded() -> void`
  - `L47-L95` `static func _load_resources() -> void`
  - `L98-L100` `static func get_all_obstacles() -> Array[RockData]`
  - `L103-L108` `static func get_all_registered_ids() -> PackedStringArray`
  - `L111-L113` `static func get_obstacle(id: String) -> RockData`
  - `L116-L118` `static func has_obstacle(id: String) -> bool`
  - `L121-L150` `static func get_mesh(id: String) -> Mesh`
  - `L153-L175` `static func get_material(id: String) -> Material`
  - `L178-L233` `static func instantiate_obstacle_node(id: String, rot_deg: float = 0.0) -> Node3D`
  - `L236-L241` `static func get_variations() -> Array[Dictionary]`
  - `L244-L251` `static func _find_first_mesh_instance(node: Node) -> MeshInstance3D`

### `scripts/obstacles/rock_data.gd` (49 linhas · `class_name RockData` · `extends Resource`)
- **Funções:**
  - `L31-L49` `func to_dict() -> Dictionary`

### `scripts/plants/flower_detach_piece.gd` (127 linhas · `class_name FlowerDetachPiece` · `extends Node3D`)
- **Consts:** `GRAVITY`, `GROUND_CLEARANCE`, `SHRINK_SEC`, `MAX_FLIGHT_SEC`, `POOL_MAX_SIZE`, `POOL_HOST_NAME`
- **Funções:**
  - `L28-L39` `static func _get_or_create_pool_host(tree: SceneTree) -> Node3D`
  - `L43-L59` `static func acquire() -> FlowerDetachPiece`
  - `L63-L74` `static func release(piece: FlowerDetachPiece) -> void`
  - `L103-L106` `func _recycle() -> void`
  - `L109-L127` `func _process(delta: float) -> void`

### `scripts/plants/plant.gd` (635 linhas · `extends Node3D`)
- **Consts:** `POOL_SIZE`, `FLOWER_STEM_COLOR`, `FLOWER_LEAVES_MATERIAL`, `FLOWER_STEM_MATERIAL`, `DETACH_CONFIG_BY_TYPE`, `DETACH_UP_SPEED_MIN`, `DETACH_UP_SPEED_MAX`
- **Funções:**
  - `L98-L124` `func _ready() -> void`
  - `L126-L198` `static func _ensure_particle_meshes() -> void`
  - `L200-L295` `static func get_flower_colors(flower_type: String) -> Dictionary`
  - `L297-L327` `func _apply_visual_material(target: Node) -> void`
  - `L329-L359` `func cut(power: int) -> void`
  - `L361-L368` `func _apply_flower_damage_stage(remaining_hp: int) -> void`
  - `L370-L374` `func _set_flower_stage_recursive(target: Node, stage: float) -> void`
  - `L376-L403` `func _perform_cut() -> void`
  - `L405-L421` `func _resolve_particle_color() -> Color`
  - `L423-L457` `static func _emit_sub_burst(scene_root: Node, pos: Vector3, mesh: Mesh, col: Color, count: int) -> void`
  - `L460-L465` `static func spawn_grass_cut_particles(scene_root: Node, world_pos: Vector3, col: Color) -> void`
  - `L468-L481` `static func spawn_flower_cut_particles(scene_root: Node, world_pos: Vector3, flower_type: String) -> void`
  - `L484-L488` `static func spawn_flower_petal_burst(scene_root: Node, world_pos: Vector3, flower_type: String) -> void`
  - `L491-L504` `static func _resolve_flower_base_type(flower_type: String) -> String`
  - `L507-L526` `static func _ensure_detach_meshes(flower_type: String) -> Dictionary`
  - `L529-L557` `static func spawn_flower_detach_pieces(scene_root: Node, flower_xform: Transform3D, flower_type: String) -> void`
  - `L559-L568` `static func _get_or_create_particle_material(col: Color) -> StandardMaterial3D`
  - `L570-L615` `static func _init_particle_pool(scene_root: Node) -> void`
  - `L617-L635` `static func warmup_particle_pool(scene_root: Node, warmup_pos: Vector3) -> void`

### `scripts/plants/plant_database.gd` (228 linhas · `class_name PlantDatabase` · `extends RefCounted`)
- **Consts:** `PlantSpeciesDataScript`, `TilePaletteDBScript`, `SPECIES_DIR`, `CANONICAL_SPECIES_PATHS`
- **Funções:**
  - `L61-L66` `static func reload_species() -> void`
  - `L69-L71` `static func _ensure_loaded() -> void`
  - `L74-L122` `static func _load_resources() -> void`
  - `L125-L127` `static func get_all_resources() -> Array[PlantSpeciesData]`
  - `L130-L134` `static func get_resource(key: String) -> PlantSpeciesData`
  - `L137-L162` `static func register_custom_species(res: PlantSpeciesData) -> void`
  - `L165-L167` `static func get_all_species() -> Array[Dictionary]`
  - `L170-L190` `static func get_species(key: String) -> Dictionary`
  - `L193-L199` `static func get_species_name(species: Dictionary) -> String`
  - `L202-L227` `static func get_all_registered_types() -> PackedStringArray`

### `scripts/plants/plant_species_data.gd` (45 linhas · `class_name PlantSpeciesData` · `extends Resource`)
- **Funções:**
  - `L28-L45` `func to_dict() -> Dictionary`

### `scripts/plants/vegetation_grid.gd` (1504 linhas · `extends Node3D`)
- **Consts:** `VegetationFieldScript`, `VectorGrassFieldScript`, `LevelJsonLoader`, `BrushPatterns`, `PlantScript`, `GRASS_MODEL`, `WHEAT_SCENE`, `FLOWER_SCENE`, `FLOWER_ROSE_SCENE`, `FLOWER_DAISY_SCENE`, `FLOWER_SUNFLOWER_SCENE`, `FLOWER_TULIP_SCENE` *(+12)*
- **Funções:**
  - `L103-L108` `static func get_veg_types() -> PackedStringArray`
  - `L110-L166` `static func _resolve_mesh_for_type(v_type: String) -> Mesh`
  - `L168-L184` `static func _resolve_material_for_type(v_type: String) -> Material`
  - `L267-L273` `static func _ensure_static_meshes() -> void`
  - `L276-L293` `static func _build_flower_combined_mesh(flower_type: String, packed_scene: PackedScene) -> ArrayMesh`
  - `L332-L339` `static func _find_first_mesh_instance(node: Node) -> MeshInstance3D`
  - `L342-L345` `static func _build_combined_mesh_from_hierarchy(root_node: Node, root_xform: Transform3D) -> ArrayMesh`
  - `L378-L410` `func _clear_state() -> void`
  - `L610-L679` `static func _resolve_clipping_color(v_type: String) -> Color`
  - `L682-L738` `static func _get_or_create_clippings_mesh(v_type: String) -> ArrayMesh`
  - `L1025-L1076` `func _build_spatial_index() -> void`
  - `L1082-L1083` `func _get_cut_transform(p_idx: int) -> Transform3D`
  - `L1086-L1118` `func _resolve_type_particle_color(v_type: String) -> Color`
  - `L1121-L1130` `func _get_game_manager() -> Node`
  - `L1133-L1345` `func cut_in_circle(center: Vector3, blade_radius: float, power: int) -> Vector3`
  - `L1348-L1356` `func _restore_plant_transform(p_idx: int) -> void`
  - `L1360-L1407` `func resolve_rigid_plant_collision(cutter_pos: Vector3, cutter_vel: Vector3, body_radius: float, plant_radius: float = 0.18) -> Dictionary`
  - `L1410-L1411` `func get_total_tufts() -> int`
  - `L1414-L1449` `func set_benchmark_visibility(vegetation_on: bool, density_step: int) -> void`
  - `L1452-L1471` `func reset_all_plants() -> void`
  - `L1474-L1491` `static func _get_remaining_goal_safe(p_type: String) -> int`
  - `L1494-L1504` `static func _has_goal_safe(p_type: String) -> bool`

### `scripts/test_composite_runner.gd` (130 linhas · `extends SceneTree`)
- **Funções:**
  - `L3-L31` `func _initialize() -> void`
  - `L33-L130` `func _build_composite_image(plant_type: String) -> Image`

### `scripts/test_outline_sim.gd` (45 linhas · `extends SceneTree`)
- **Funções:**
  - `L3-L45` `func _initialize() -> void`

### `scripts/themes/island_theme_data.gd` (109 linhas · `class_name IslandThemeData` · `extends Resource`)
- **Consts:** `IslandMeshBuilderScript`
- **Funções:**
  - `L46-L54` `func apply_to_environment(env: Environment) -> void`
  - `L57-L66` `func apply_to_sun(sun: DirectionalLight3D) -> void`
  - `L69-L75` `func apply_to_water(water_mat: ShaderMaterial) -> void`
  - `L78-L85` `func apply_to_island_builder() -> void`
  - `L88-L109` `func to_dict() -> Dictionary`

### `scripts/themes/theme_database.gd` (158 linhas · `extends RefCounted`)
- **Consts:** `IslandThemeDataScript`, `IslandMeshBuilderScript`, `THEMES_DIR`, `DEFAULT_THEME_ID`, `CANONICAL_THEME_PATHS`
- **Funções:**
  - `L25-L29` `static func reload() -> void`
  - `L32-L34` `static func _ensure_loaded() -> void`
  - `L37-L77` `static func _load_resources() -> void`
  - `L80-L82` `static func get_all_themes() -> Array[IslandThemeData]`
  - `L85-L89` `static func get_theme(id: String) -> IslandThemeData`
  - `L92-L94` `static func has_theme(id: String) -> bool`
  - `L97-L117` `static func get_theme_for_level(level_number: int, level_data: Dictionary = {}) -> IslandThemeData`
  - `L151-L158` `static func apply_theme_to_island_builder(theme: IslandThemeData) -> void`

### `scripts/tools/bump_version.gd` (211 linhas · `class_name BumpVersionTool` · `extends RefCounted`)
- **Consts:** `GAME_VERSION_PATH`, `PROJECT_GODOT_PATH`, `EXPORT_PRESETS_PATH`, `MAJOR`, `MINOR`, `PATCH`, `STAGE`, `BUILD_TYPE`
- **Funções:**
  - `L26-L28` `func _run() -> void`
  - `L30-L72` `static func bump(mode: BumpMode = BumpMode.PATCH) -> void`
  - `L87-L94` `static func get_raw_version() -> String`
  - `L97-L101` `static func get_version_string() -> String`
  - `L104-L105` `static func get_display_name() -> String`
  - `L108-L114` `static func get_version_code() -> int`
  - `L117-L118` `static func is_pre_alpha() -> bool`
  - `L121-L122` `static func is_alpha() -> bool`
  - `L125-L126` `static func is_beta() -> bool`
  - `L129-L130` `static func is_rc() -> bool`
  - `L133-L134` `static func is_release() -> bool`
  - `L137-L211` `static func get_full_info() -> Dictionary`

### `scripts/tools/calibrate_levels_layout.gd` (314 linhas · `extends SceneTree`)
- **Consts:** `IslandAutotiler`, `LevelJsonLoader`
- **Funções:**
  - `L13-L21` `func _init() -> void`
  - `L23-L201` `func calibrate_level(path: String, lvl_num: int) -> void`
  - `L203-L218` `func _find_border_cells(terrain_grid: Dictionary) -> Dictionary`
  - `L220-L227` `func _dist_to_borders(cell: Vector2i, border_cells: Dictionary) -> int`
  - `L229-L230` `func _chebyshev(a: Vector2i, b: Vector2i) -> int`
  - `L232-L258` `func _find_nearest_deep_cell(origin: Vector2i, terrain: Dictionary, borders: Dictionary, existing_rocks: Array[Vector2i]) -> Vector2i`
  - `L260-L271` `func _find_safe_spawn(terrain: Dictionary, borders: Dictionary, rocks: Array[Vector2i]) -> Vector2i`
  - `L273-L295` `func _expand_island_by_rings(orig_terrain: Dictionary, orig_w: int, orig_h: int, rings: int) -> Dictionary`
  - `L297-L314` `func _get_level_plant_palette(data: Dictionary, lvl_num: int) -> Array[String]`

### `scripts/tools/capture_store_screenshots.gd` (242 linhas · `extends Node`)
- **Consts:** `OUTPUT_DIR`, `MAIN_SCENE`, `MENU_SCENE`
- **Funções:**
  - `L28-L37` `func _ready() -> void`
  - `L39-L95` `func _backup_and_apply_promo_save() -> void`
  - `L97-L128` `func _advance_to_step(next_step: Step) -> void`
  - `L130-L141` `func _process(_delta: float) -> void`
  - `L143-L156` `func _process_gameplay() -> void`
  - `L158-L175` `func _process_map() -> void`
  - `L177-L191` `func _process_workshop() -> void`
  - `L193-L207` `func _process_herbarium() -> void`
  - `L209-L231` `func _save_screenshot(filename: String) -> void`
  - `L233-L242` `func _restore_save_and_quit() -> void`

### `scripts/tools/convert_levels_to_vector_island.gd` (52 linhas · `extends SceneTree`)
- **Consts:** `IslandMeshBuilderScript`, `LevelJsonLoader`
- **Funções:**
  - `L6-L52` `func _init() -> void`

### `scripts/tools/generate_procedural_levels.gd` (1533 linhas · `extends SceneTree`)
- **Consts:** `IslandAutotiler`, `LevelJsonLoader`, `LevelSerializer`, `VectorGrassFieldScript`, `VectorTerrainFieldScript`, `CELL_SIZE`, `MIN_SPAWN_CLEAR_DIST`, `MIN_ROCK_SPACING`, `SPAWN_GRASS_CLEAR_RADIUS`, `ROCK_GRASS_CLEAR_RADIUS`
- **Funções:**
  - `L27-L76` `func _init() -> void`
  - `L79-L1029` `func generate_level(lvl: int) -> int`
  - `L1033-L1077` `func _add_valid_rock(terrain_grid: Dictionary, object_grid: Dictionary, spawn_cell: Vector2i, pref: Vector2i) -> Vector2i`
  - `L1080-L1112` `func _add_valid_flower(terrain_grid: Dictionary, object_grid: Dictionary, spawn_cell: Vector2i, pref: Vector2i, flower_type: String) -> Vector2i`
  - `L1115-L1116` `func _add_valid_wheat(terrain_grid: Dictionary, object_grid: Dictionary, spawn_cell: Vector2i, pref: Vector2i) -> Vector2i`
  - `L1312-L1315` `func _add_rect_island(grid: Dictionary, x0: int, z0: int, w: int, h: int) -> void`
  - `L1317-L1323` `func _add_chamfered_rect_island(grid: Dictionary, x0: int, z0: int, w: int, h: int, chamfer: int) -> void`
  - `L1325-L1331` `func _add_octagon_island(grid: Dictionary, cx: int, cz: int, radius: int) -> void`
  - `L1333-L1344` `func _add_rounded_cross_island(grid: Dictionary, cx: int, cz: int, arm_len: int, arm_w: int) -> void`
  - `L1346-L1352` `func _add_diamond_island(grid: Dictionary, cx: int, cz: int, radius: int) -> void`
  - `L1354-L1356` `func _add_star_island(grid: Dictionary, cx: int, cz: int, outer_r: int, inner_r: int) -> void`
  - `L1358-L1363` `func _add_clover_island(grid: Dictionary, cx: int, cz: int) -> void`
  - `L1367-L1369` `func _add_grass_circle(vf: RefCounted, type_name: String, gx: int, gz: int, width: int, height: int, radius: float) -> void`
  - `L1371-L1377` `func _add_grass_circle_world(vf: RefCounted, type_name: String, center: Vector2, radius: float) -> void`
  - `L1379-L1389` `func _add_grass_ring(vf: RefCounted, type_name: String, gx: int, gz: int, width: int, height: int, r_in: float, r_out: float) -> void`
  - `L1391-L1404` `func _add_grass_rect(vf: RefCounted, type_name: String, gx0: int, gz0: int, gx1: int, gz1: int, width: int, height: int) -> void`
  - `L1406-L1434` `func _add_diagonal_stripes(vf: RefCounted, width: int, height: int, types: Array[String], stripe_w: float) -> void`
  - `L1436-L1443` `func _add_grass_diamond_world(vf: RefCounted, type_name: String, center: Vector2, radius: float) -> void`
  - `L1445-L1452` `func _add_grass_star_world(vf: RefCounted, type_name: String, center: Vector2, r_out: float, r_in: float, points: int) -> void`
  - `L1456-L1461` `func _get_procedural_level_name(lvl: int) -> String`

### `scripts/tools/lighting_lab.gd` (980 linhas · `extends Node3D`)
- **Consts:** `LevelJsonLoader`, `VegetationGridScript`, `IslandMeshBuilder`, `CUTTER_SCENE`, `WATER_MATERIAL`, `MODEL_BOT`, `MODEL_GRASS`, `MODEL_WHEAT`, `MODEL_FLOWER_ROSE`, `MODEL_FLOWER_DAISY`, `MODEL_FLOWER_SUNFLOWER`, `MODEL_FLOWER_BELL` *(+5)*
- **Funções:**
  - `L200-L216` `func _ready() -> void`
  - `L218-L222` `func _init_grass_materials() -> void`
  - `L224-L236` `func _setup_options() -> void`
  - `L238-L292` `func _connect_signals() -> void`
  - `L294-L319` `func _process(delta: float) -> void`
  - `L321-L336` `func _handle_gameplay_input() -> void`
  - `L338-L390` `func _unhandled_input(event: InputEvent) -> void`
  - `L392-L398` `func _update_free_camera_transform() -> void`
  - `L400-L405` `func _reset_camera() -> void`
  - `L411-L426` `func _set_display_mode(mode: DisplayMode) -> void`
  - `L428-L432` `func _toggle_display_mode() -> void`
  - `L434-L481` `func _load_level(lvl: int) -> void`
  - `L483-L534` `func _load_studio_model(model_enum: StudioModel) -> void`
  - `L536-L546` `func _on_prev_item_pressed() -> void`
  - `L548-L558` `func _on_next_item_pressed() -> void`
  - `L560-L566` `func _update_header_status() -> void`
  - `L572-L591` `func _set_camera_mode(game_cam: bool) -> void`
  - `L593-L594` `func _toggle_camera_mode() -> void`
  - `L596-L598` `func _toggle_ui_visibility() -> void`
  - `L600-L603` `func _toggle_drawer() -> void`
  - `L609-L614` `func _update_sun_orientation() -> void`
  - `L616-L619` `func _on_sun_energy_changed(v: float) -> void`
  - `L621-L623` `func _on_sun_pitch_changed(v: float) -> void`
  - `L625-L627` `func _on_sun_yaw_changed(v: float) -> void`
  - `L629-L631` `func _on_sun_color_changed(c: Color) -> void`
  - `L633-L635` `func _on_sun_shadows_toggled(pressed: bool) -> void`
  - `L641-L644` `func _on_ambient_energy_changed(v: float) -> void`
  - `L646-L648` `func _on_ambient_color_changed(c: Color) -> void`
  - `L650-L652` `func _on_sky_color_changed(c: Color) -> void`
  - `L654-L656` `func _on_tonemap_selected(idx: int) -> void`
  - `L658-L661` `func _on_exposure_changed(v: float) -> void`
  - `L667-L672` `func _on_grass_material_selected(idx: int) -> void`
  - `L674-L711` `func _sync_ui_from_material() -> void`
  - `L713-L715` `func _on_shader_color_light_changed(c: Color) -> void`
  - `L717-L719` `func _on_shader_color_shadow_changed(c: Color) -> void`
  - `L721-L723` `func _on_shader_color_base_changed(c: Color) -> void`
  - `L725-L728` `func _on_shader_ramp_offset_changed(v: float) -> void`
  - `L730-L733` `func _on_shader_ramp_smooth_changed(v: float) -> void`
  - `L735-L738` `func _on_shader_vert_grad_changed(v: float) -> void`
  - `L740-L742` `func _on_shader_rim_toggled(pressed: bool) -> void`
  - `L744-L746` `func _on_shader_rim_color_changed(c: Color) -> void`
  - `L748-L751` `func _on_shader_rim_power_changed(v: float) -> void`
  - `L753-L756` `func _on_shader_rim_bright_changed(v: float) -> void`
  - `L758-L761` `func _on_shader_roughness_changed(v: float) -> void`
  - `L767-L769` `func _on_ground_color_changed(c: Color) -> void`
  - `L771-L774` `func _on_ground_bright_changed(v: float) -> void`
  - `L776-L778` `func _on_ground_toon_toggled(pressed: bool) -> void`
  - `L780-L782` `func _on_cliff_color_changed(_c: Color) -> void`
  - `L784-L788` `func _reload_island_mesh() -> void`
  - `L790-L792` `func _on_ocean_visible_toggled(pressed: bool) -> void`
  - `L794-L796` `func _on_water_shallow_changed(c: Color) -> void`
  - `L798-L800` `func _on_water_deep_changed(c: Color) -> void`
  - `L806-L840` `func _apply_preset_canonical() -> void`
  - `L842-L861` `func _apply_preset_current() -> void`
  - `L863-L878` `func _apply_preset_golden() -> void`
  - `L880-L898` `func _apply_preset_pop() -> void`
  - `L900-L914` `func _apply_preset_dusk() -> void`
  - `L920-L932` `func _on_btn_save_game_pressed() -> void`
  - `L934-L974` `func _on_btn_copy_code_pressed() -> void`
  - `L976-L980` `func _show_toast(msg: String) -> void`

### `scripts/tools/perf_probe.gd` (104 linhas · `extends CanvasLayer`)
- **Signals:** `action_triggered(action_id: String)`
- **Consts:** `REFRESH_INTERVAL`
- **Funções:**
  - `L18-L49` `func _ready() -> void`
  - `L51-L75` `func _create_action_button(title: String, action_id: String) -> void`
  - `L77-L104` `func _process(delta: float) -> void`

### `scripts/tools/perf_test.gd` (152 linhas · `extends Node`)
- **Consts:** `PerfProbeScript`, `MAIN_SCENE`, `SCALE_STEPS`
- **Funções:**
  - `L30-L66` `func _ready() -> void`
  - `L68-L73` `func _exit_tree() -> void`
  - `L75-L97` `func _unhandled_key_input(event: InputEvent) -> void`
  - `L99-L132` `func _on_probe_action(action_id: String) -> void`
  - `L134-L136` `func _set_density(step: int) -> void`
  - `L138-L140` `func _apply_visibility() -> void`
  - `L142-L152` `func _refresh_extra() -> void`

### `scripts/tools/take_icon_photo.gd` (157 linhas · `extends Node3D`)
- **Funções:**
  - `L12-L15` `func _ready() -> void`
  - `L17-L101` `func _setup_bot_pose() -> void`
  - `L103-L107` `func _process(_delta: float) -> void`
  - `L109-L157` `func _capture_and_save_icon() -> void`

### `scripts/tools/verify_levels.gd` (20 linhas)
- **Consts:** `LevelJsonLoader`, `VegetationFieldScript`, `VegetationGridScript`
- **Funções:**
  - `L7-L20` `func _init() -> void`

### `scripts/tools/verify_levels_integrity.gd` (102 linhas · `extends SceneTree`)
- **Funções:**
  - `L8-L102` `func _init() -> void`

### `scripts/tools/water_tuner.gd` (288 linhas · `extends Node3D`)
- **Consts:** `WATER_MAT_PATH`, `VegetationGridScript`, `LevelJsonLoader`
- **Funções:**
  - `L51-L60` `func _ready() -> void`
  - `L62-L83` `func _load_island(lvl: int) -> void`
  - `L85-L135` `func _sync_ui_from_material() -> void`
  - `L137-L139` `func _update_coords_button() -> void`
  - `L141-L179` `func _connect_signals() -> void`
  - `L181-L183` `func _set_param(param_name: String, val: Variant) -> void`
  - `L185-L189` `func _on_btn_coords_toggle_pressed() -> void`
  - `L191-L202` `func _set_camera_mode(map_mode: bool) -> void`
  - `L204-L205` `func _on_btn_cam_toggle_pressed() -> void`
  - `L207-L212` `func _on_btn_level_toggle_pressed() -> void`
  - `L214-L217` `func _on_btn_copy_pressed() -> void`
  - `L219-L225` `func _on_btn_save_pressed() -> void`
  - `L227-L256` `func _generate_parameters_text() -> String`
  - `L258-L267` `func _show_toast(msg: String) -> void`
  - `L269-L288` `func _unhandled_key_input(event: InputEvent) -> void`

### `scripts/ui/cyber_nav_button.gd` (79 linhas · `class_name CyberNavButton` · `extends Button`)
- **Signals:** `nav_button_pressed(tab_id: int)`
- **Consts:** `COLOR_ACTIVE`, `COLOR_INACTIVE`, `SCALE_ACTIVE`, `SCALE_INACTIVE`, `TWEEN_DURATION`
- **Funções:**
  - `L38-L41` `func _notification(what: int) -> void`
  - `L43-L50` `func _ready() -> void`
  - `L52-L72` `func set_active(active: bool, animated: bool = true) -> void`
  - `L74-L79` `func _on_pressed() -> void`

### `scripts/ui/cyber_play_button.gd` (60 linhas · `class_name CyberPlayButton` · `extends Button`)
- **Consts:** `PRESS_SINK_OFFSET`
- **Funções:**
  - `L18-L26` `func _ready() -> void`
  - `L28-L30` `func set_level_text(new_text: String) -> void`
  - `L32-L34` `func set_level_number(lvl: int) -> void`
  - `L36-L43` `func _on_btn_down() -> void`
  - `L45-L54` `func _on_btn_up() -> void`
  - `L56-L60` `func _on_btn_pressed() -> void`

### `scripts/ui/cyber_resource_badge.gd` (80 linhas · `class_name CyberResourceBadge` · `extends Button`)
- **Signals:** `plus_pressed`, `badge_pressed`
- **Funções:**
  - `L37-L50` `func _ready() -> void`
  - `L52-L53` `func _pressed() -> void`
  - `L55-L57` `func set_value_text(new_text: String) -> void`
  - `L59-L64` `func _on_btn_down() -> void`
  - `L66-L72` `func _on_btn_up() -> void`
  - `L74-L80` `func _on_btn_pressed() -> void`

### `scripts/ui/cyber_toggle_button.gd` (61 linhas · `class_name CyberToggleButton` · `extends Button`)
- **Consts:** `PRESS_SINK_OFFSET`
- **Funções:**
  - `L18-L26` `func _ready() -> void`
  - `L28-L30` `func set_toggle_text(new_text: String) -> void`
  - `L32-L35` `func set_toggle_icon(tex: Texture2D) -> void`
  - `L37-L44` `func _on_btn_down() -> void`
  - `L46-L55` `func _on_btn_up() -> void`
  - `L57-L61` `func _on_btn_pressed() -> void`

### `scripts/ui/daily_bonus_modal.gd` (462 linhas · `class_name DailyBonusModal` · `extends Control`)
- **Signals:** `bonus_claimed(day_num: int, coins: int)`, `modal_closed`
- **Consts:** `TEX_CARD_BG`, `TEX_DAY_BG`, `TEX_BTN_CLAIM`, `TEX_ICON_COIN`, `TEX_ICON_HEART`, `TEX_ICON_GIFT`, `TEX_ICON_CLOSE_X`, `CARD_W`, `CARD_H`
- **Funções:**
  - `L35-L37` `func _notification(what: int) -> void`
  - `L39-L48` `func _ready() -> void`
  - `L50-L56` `func _process(delta: float) -> void`
  - `L58-L59` `func is_open() -> bool`
  - `L61-L66` `func _unhandled_input(event: InputEvent) -> void`
  - `L68-L91` `func open() -> void`
  - `L93-L118` `func close() -> void`
  - `L120-L242` `func _build_ui() -> void`
  - `L244-L352` `func _create_day_card(day_num: int, is_day7: bool) -> Dictionary`
  - `L354-L417` `func _refresh_ui() -> void`
  - `L419-L440` `func _update_claim_button_state() -> void`
  - `L442-L462` `func _on_claim_pressed() -> void`

### `scripts/ui/defeat_modal.gd` (569 linhas · `class_name DefeatModal` · `extends Control`)
- **Signals:** `retry_requested`, `extra_time_requested`, `repair_robot_requested`, `menu_requested`
- **Consts:** `TEX_BANNER_TITLE`, `TEX_BANNER_PROGRESS`, `TEX_BANNER_GOALS`, `TEX_BTN_MENU_N`, `TEX_BTN_MENU_P`, `TEX_BTN_EXTRA_N`, `TEX_BTN_EXTRA_P`, `TEX_BTN_RETRY_N`, `TEX_BTN_RETRY_P`, `TEX_ICON_STOPWATCH`, `TEX_ICON_ROBOT_BROKEN`, `TEX_ICON_ALERT` *(+9)*
- **Funções:**
  - `L68-L70` `func _notification(what: int) -> void`
  - `L73-L81` `func _ready() -> void`
  - `L85-L146` `func open(reason_or_progress: Variant = "time_up", progress_or_goals: Variant = 0.0, goals_or_extend: Variant = [], can_extend_opt: bool = true) -> void`
  - `L149-L165` `func close() -> void`
  - `L168-L402` `func _build_ui() -> void`
  - `L405-L429` `func _make_secondary_button(tex_n: Texture2D, tex_p: Texture2D, icon_tex: Texture2D, txt: String, font_size: int) -> TextureButton`
  - `L432-L439` `func _update_reason_visuals() -> void`
  - `L442-L449` `func _update_progress_bar_width(ratio: float) -> void`
  - `L452-L472` `func _populate_goals(goals_data: Variant) -> void`
  - `L475-L490` `func _add_goal_item(plant_type: String, current_val: int, target_val: int) -> void`
  - `L493-L502` `func _update_life_lost_badge() -> void`
  - `L505-L512` `func _retranslate_ui() -> void`
  - `L515-L523` `func _make_icon(tex: Texture2D, icon_size: Vector2) -> TextureRect`
  - `L526-L536` `func _make_label(txt: String, font_size: int, color: Color) -> Label`
  - `L539-L546` `func _on_retry_pressed() -> void`
  - `L549-L559` `func _on_extra_pressed() -> void`
  - `L562-L569` `func _on_menu_pressed() -> void`

### `scripts/ui/exit_modal.gd` (300 linhas · `class_name ExitModal` · `extends Control`)
- **Signals:** `cancel_requested`, `quit_requested`
- **Consts:** `TEX_CARD_BG`, `TEX_BTN_RESUME_N`, `TEX_BTN_RESUME_P`, `TEX_BTN_DANGER_N`, `TEX_BTN_DANGER_P`, `TEX_ICON_PLAY`, `TEX_ICON_ALERT`, `TEX_ICON_CLOSE_X`, `COL_WHITE`, `COL_CYAN_TITLE`, `COL_SUBTITLE`, `CARD_W` *(+1)*
- **Funções:**
  - `L39-L41` `func _notification(what: int) -> void`
  - `L43-L51` `func _ready() -> void`
  - `L53-L54` `func is_open() -> bool`
  - `L56-L61` `func _unhandled_input(event: InputEvent) -> void`
  - `L63-L84` `func open() -> void`
  - `L86-L109` `func close() -> void`
  - `L111-L119` `func _on_quit_pressed() -> void`
  - `L121-L215` `func _build_ui() -> void`
  - `L217-L266` `func _make_action_button(txt: String, icon_tex: Texture2D, icon_sz: Vector2, tex_n: Texture2D, tex_p: Texture2D) -> Button`
  - `L268-L276` `func _retranslate_ui() -> void`
  - `L278-L288` `func _make_label(txt: String, font_size: int, color: Color) -> Label`
  - `L290-L300` `func _on_backdrop_gui_input(event: InputEvent) -> void`

### `scripts/ui/floating_joystick.gd` (190 linhas · `extends Control`)
- **Signals:** `joystick_moved(direction: Vector2)`
- **Funções:**
  - `L19-L29` `func _ready() -> void`
  - `L31-L34` `func _notification(what: int) -> void`
  - `L36-L41` `func _on_game_state_changed(new_state: int) -> void`
  - `L43-L58` `func _input(event: InputEvent) -> void`
  - `L60-L71` `func _handle_touch(event: InputEventScreenTouch) -> void`
  - `L73-L76` `func _handle_drag(event: InputEventScreenDrag) -> void`
  - `L78-L90` `func _handle_mouse_button(event: InputEventMouseButton) -> void`
  - `L92-L95` `func _handle_mouse_motion(event: InputEventMouseMotion) -> void`
  - `L97-L113` `func _update_stick_position(current_pos: Vector2) -> void`
  - `L115-L120` `func _reset_joystick() -> void`
  - `L122-L181` `func _process(_delta: float) -> void`
  - `L183-L190` `func _draw() -> void`

### `scripts/ui/goal_icon_factory.gd` (272 linhas · `class_name GoalIconFactory` · `extends RefCounted`)
- **Consts:** `PlantDatabaseScript`, `OUTLINE_SHADER`, `TEX_ILLUS_GRASS_BASE`, `TEX_ILLUS_GRASS_BLADES`, `TEX_ILLUS_WHEAT`, `TEX_ILLUS_FLOWER_STEMS`, `TEX_ILLUS_FLOWER_PETALS`
- **Funções:**
  - `L26-L85` `static func _bake_category_outline(cat: String) -> Image`
  - `L88-L153` `static func get_baked_icon_texture(plant_type: String, with_outline: bool = true) -> Texture2D`
  - `L156-L165` `static func _get_outline_material() -> ShaderMaterial`
  - `L168-L247` `static func _get_composite_silhouette(_plant_type: String, cat: String) -> Texture2D`
  - `L250-L258` `static func _make_sprite_rect(tex: Texture2D, tint: Color) -> TextureRect`
  - `L263-L272` `static func build_goal_icon(plant_type: String, icon_size: float = 34.0, with_outline: bool = true) -> Control`

### `scripts/ui/hud.gd` (681 linhas · `extends Control`)
- **Consts:** `PlantDatabaseScript`, `ICON_PAUSE`, `ICON_COIN`, `BADGE_GOAL_BG`, `BADGE_GOAL_DONE_BG`, `TEX_ILLUS_GRASS_BASE`, `TEX_ILLUS_GRASS_BLADES`, `TEX_ILLUS_WHEAT`, `TEX_ILLUS_FLOWER_STEMS`, `TEX_ILLUS_FLOWER_PETALS`, `DEFEAT_EXTRA_TIME_SECONDS`
- **Funções:**
  - `L53-L133` `func _ready() -> void`
  - `L135-L140` `func _on_menu_pressed() -> void`
  - `L142-L145` `func _connect_button(btn: BaseButton, callback: Callable) -> void`
  - `L152-L169` `func _on_time_updated(time_left: float) -> void`
  - `L171-L189` `func _on_goal_updated(plant_type: String, remaining: int, target: int) -> void`
  - `L191-L289` `func _create_goal_card(plant_type: String, target: int) -> void`
  - `L291-L303` `func _on_goal_completed(plant_type: String) -> void`
  - `L306-L380` `func _on_goal_item_collected(goal_key: String, world_pos: Vector3) -> void`
  - `L382-L384` `func _on_coins_changed(new_amount: int) -> void`
  - `L386-L387` `func _on_pause_pressed() -> void`
  - `L389-L397` `func _on_game_paused(is_paused: bool) -> void`
  - `L399-L400` `func _on_resume_pressed() -> void`
  - `L402-L421` `func _on_restart_pressed() -> void`
  - `L423-L432` `func _on_next_level_pressed() -> void`
  - `L434-L516` `func _on_level_won(coins_earned: int, stars_earned: int = 1) -> void`
  - `L518-L526` `func _on_level_lost(reason: String) -> void`
  - `L529-L535` `func _on_extra_time_requested() -> void`
  - `L538-L545` `func _on_repair_robot_requested() -> void`
  - `L547-L551` `func _on_open_workshop_pressed() -> void`
  - `L553-L556` `func _on_close_workshop_pressed() -> void`
  - `L558-L562` `func _on_state_changed(new_state: int) -> void`
  - `L565-L569` `func _setup_workshop_buttons() -> void`
  - `L571-L574` `func _buy_upgrade(upgrade_name: String) -> void`
  - `L576-L593` `func _refresh_localized_ui() -> void`
  - `L595-L609` `func _update_workshop_display() -> void`
  - `L611-L622` `func _update_card(key: String, card: Control, title: String) -> void`
  - `L628-L637` `func _get_safe_area_top_margin() -> float`
  - `L639-L647` `func _apply_safe_area() -> void`
  - `L649-L653` `func _notification(what: int) -> void`
  - `L655-L658` `func _unhandled_input(event: InputEvent) -> void`
  - `L660-L681` `func _handle_back_request() -> void`

### `scripts/ui/map_level_card.gd` (362 linhas · `class_name MapLevelCard` · `extends PanelContainer`)
- **Consts:** `TEX_CARD_BG`, `TEX_FRAME_OBJ`, `TEX_STAR_FULL`, `TEX_STAR_EMPTY`, `TEX_ISLAND`, `TEX_CLOCK`, `TEX_LOCK`, `TEX_GOAL_BG`, `COL_WHITE`, `COL_SUB`, `COL_LOCKED`, `CARD_WIDTH` *(+4)*
- **Funções:**
  - `L50-L55` `func _notification(what: int) -> void`
  - `L57-L63` `func _ready() -> void`
  - `L66-L76` `func _make_label(txt: String, font_size: int, color: Color) -> Label`
  - `L79-L87` `func _make_icon(tex: Texture2D, icon_size: Vector2) -> TextureRect`
  - `L90-L101` `func _make_texture_style(tex: Texture2D, tex_margin: float, pad_l: float, pad_t: float, pad_r: float, pad_b: float) -> StyleBoxTexture`
  - `L104-L242` `func _build_ui() -> void`
  - `L245-L248` `func _is_unlocked(lvl: int) -> bool`
  - `L251-L253` `func _goal_rank(key: String) -> int`
  - `L257-L292` `func show_level(lvl: int, unlocked: bool) -> void`
  - `L296-L304` `func play_bump_animation(_direction: int = 1) -> void`
  - `L308-L316` `func play_boundary_bounce(_direction: int = 1) -> void`
  - `L319-L342` `func _rebuild_goals(goals: Dictionary) -> void`
  - `L345-L362` `func _make_goal_card(plant_type: String, amount: int, card_w: float) -> Control`

### `scripts/ui/pause_modal.gd` (515 linhas · `class_name PauseModal` · `extends Control`)
- **Signals:** `resume_requested`, `restart_requested`, `menu_requested`
- **Consts:** `TEX_CARD_BG`, `TEX_BTN_RESUME_N`, `TEX_BTN_RESUME_P`, `TEX_BTN_RESTART_N`, `TEX_BTN_RESTART_P`, `TEX_BTN_MENU_N`, `TEX_BTN_MENU_P`, `TEX_CARD_TOGGLE`, `TEX_TOGGLE_ON`, `TEX_TOGGLE_OFF`, `TEX_ICON_PAUSE`, `TEX_ICON_PLAY` *(+13)*
- **Funções:**
  - `L69-L71` `func _notification(what: int) -> void`
  - `L74-L83` `func _ready() -> void`
  - `L86-L91` `func _unhandled_input(event: InputEvent) -> void`
  - `L94-L113` `func open() -> void`
  - `L116-L134` `func close() -> void`
  - `L137-L259` `func _build_ui() -> void`
  - `L262-L312` `func _make_action_button(txt: String, icon_tex: Texture2D, icon_sz: Vector2, tex_n: Texture2D, tex_p: Texture2D) -> Button`
  - `L315-L376` `func _build_toggle_card(card_title: String, icon_tex: Texture2D, register_cb: Callable) -> Control`
  - `L379-L389` `func _make_label(txt: String, font_size: int, color: Color) -> Label`
  - `L392-L413` `func _sync_toggles_state() -> void`
  - `L416-L431` `func _retranslate_ui() -> void`
  - `L433-L438` `func _update_toggle_item(icon_rect: TextureRect, status_lbl: Label, is_on: bool) -> void`
  - `L441-L453` `func _on_backdrop_gui_input(event: InputEvent) -> void`
  - `L456-L458` `func _on_resume_pressed() -> void`
  - `L461-L465` `func _on_restart_pressed() -> void`
  - `L468-L473` `func _on_menu_pressed() -> void`
  - `L476-L487` `func _on_toggle_sfx_pressed() -> void`
  - `L490-L501` `func _on_toggle_music_pressed() -> void`
  - `L504-L515` `func _on_toggle_vib_pressed() -> void`

### `scripts/ui/settings_modal.gd` (499 linhas · `extends Control`)
- **Signals:** `modal_closed`
- **Consts:** `TEX_TOGGLE_ON`, `TEX_TOGGLE_OFF`
- **Funções:**
  - `L57-L88` `func _notification(what: int) -> void`
  - `L90-L161` `func _ready() -> void`
  - `L163-L164` `func is_open() -> bool`
  - `L166-L171` `func _unhandled_input(event: InputEvent) -> void`
  - `L173-L186` `func open_modal() -> void`
  - `L188-L200` `func close_modal() -> void`
  - `L202-L214` `func _on_backdrop_gui_input(event: InputEvent) -> void`
  - `L216-L235` `func _on_graphics_toggled() -> void`
  - `L237-L244` `func _on_music_toggled() -> void`
  - `L246-L253` `func _on_sfx_toggled() -> void`
  - `L255-L275` `func _on_vib_toggled() -> void`
  - `L277-L279` `func _on_android_vib_hint_pressed() -> void`
  - `L281-L290` `func _apply_switch_state(btn: BaseButton, state_lbl: Label, is_on: bool) -> void`
  - `L292-L314` `func _update_toggle_visuals() -> void`
  - `L316-L329` `func _is_android_haptic_feedback_enabled() -> bool`
  - `L331-L344` `func _open_android_sound_settings() -> void`
  - `L346-L354` `func _on_save_local_pressed() -> void`
  - `L356-L375` `func _on_reset_pressed() -> void`
  - `L377-L402` `func _init_language_styles() -> void`
  - `L404-L411` `func _apply_lang_button_style(btn: Button, is_active: bool) -> void`
  - `L413-L423` `func _update_language_buttons(active_locale: String) -> void`
  - `L425-L433` `func _set_language(new_locale: String) -> void`
  - `L435-L460` `func _update_all_localized_texts() -> void`
  - `L462-L463` `func _on_google_pressed() -> void`
  - `L465-L466` `func _on_fb_pressed() -> void`
  - `L468-L469` `func _on_support_pressed() -> void`
  - `L471-L487` `func _on_version_gui_input(event: InputEvent) -> void`
  - `L489-L499` `func _show_toast(msg: String) -> void`

---

## 2. Cenas e Vínculos (`scenes/`)

| Cena | Raiz | Script Principal | Subcenas Instanciadas |
| :--- | :--- | :--- | :--- |
| `scenes/cutter/blade_progress_bar.tscn` | `BladeProgressBar` (Node3D) | `res://scripts/cutter/blade_progress_bar.gd` | — |
| `scenes/cutter/cutter.tscn` | `Cutter` (CharacterBody3D) | `res://scripts/cutter/cutter.gd` (+ `res://scripts/cutter/robot_eyes.gd`) | `res://assets/models/grass_bot.glb`, `res://scenes/cutter/blade_progress_bar.tscn` |
| `scenes/editor/level_editor.tscn` | `LevelEditor` (Node3D) | `res://scripts/editor/level_editor.gd` (+ `res://scripts/editor/grid_overlay.gd`, `res://scripts/editor/editor_camera.gd`, `res://scripts/camera/isometric_camera.gd`, `res://scripts/effects/floating_coin_manager.gd`) | `res://scenes/level/water_ocean.tscn`, `res://scenes/editor/level_editor_ui.tscn` |
| `scenes/editor/level_editor_ui.tscn` | `LevelEditorUI` (Control) | `res://scripts/editor/level_editor_ui.gd` | — |
| `scenes/level/terrain.tscn` | `Terrain` (StaticBody3D) | — | — |
| `scenes/level/water_ocean.tscn` | `WaterOcean` (Node3D) | — | — |
| `scenes/main.tscn` | `Main` (Node3D) | `res://scripts/main.gd` (+ `res://scripts/level/level_controller.gd`, `res://scripts/camera/isometric_camera.gd`, `res://scripts/effects/floating_coin_manager.gd`) | `res://scenes/level/terrain.tscn`, `res://scenes/cutter/cutter.tscn`, `res://scenes/ui/floating_joystick.tscn`, `res://scenes/ui/hud.tscn` |
| `scenes/menu/bottom_nav_bar.tscn` | `BottomNavBar` (Control) | `res://scripts/menu/bottom_nav_bar.gd` | `res://scenes/ui/cyber_nav_button.tscn` |
| `scenes/menu/clouds_end_node.tscn` | `CloudsEndNode` (Node3D) | — | — |
| `scenes/menu/island_node.tscn` | `IslandNode` (Node3D) | `res://scripts/menu/island_node.gd` | — |
| `scenes/menu/main_menu.tscn` | `MainMenu` (Node3D) | `res://scripts/menu/main_menu.gd` (+ `res://scripts/menu/menu_camera.gd`) | `res://scenes/menu/menu_bot.tscn`, `res://scenes/menu/tabs/tab_garage.tscn`, `res://scenes/menu/tabs/tab_home.tscn`, `res://scenes/menu/tabs/tab_collection.tscn`, `res://scenes/menu/tabs/tab_store.tscn`, `res://scenes/ui/cyber_resource_badge.tscn`, `res://scenes/menu/bottom_nav_bar.tscn`, `res://scenes/ui/settings_modal.tscn`, `res://scenes/ui/exit_modal.tscn`, `res://scenes/ui/daily_bonus_modal.tscn` |
| `scenes/menu/menu_bot.tscn` | `MenuBot` (Node3D) | `res://scripts/menu/menu_bot.gd` (+ `res://scripts/cutter/robot_eyes.gd`) | `res://assets/models/grass_bot.glb` |
| `scenes/menu/tabs/tab_collection.tscn` | `TabCollection` (Control) | `res://scripts/menu/tabs/tab_collection.gd` | — |
| `scenes/menu/tabs/tab_garage.tscn` | `TabGarage` (Control) | `res://scripts/menu/tabs/tab_garage.gd` | — |
| `scenes/menu/tabs/tab_home.tscn` | `TabHome` (Control) | `res://scripts/menu/tabs/tab_home.gd` (+ `res://scripts/ui/cyber_play_button.gd`, `res://scripts/ui/cyber_toggle_button.gd`) | `res://scenes/ui/map_level_card.tscn` |
| `scenes/menu/tabs/tab_store.tscn` | `TabStore` (Control) | `res://scripts/menu/tabs/tab_store.gd` | — |
| `scenes/obstacles/rock.tscn` | `Rock` (StaticBody3D) | — | `res://assets/models/rock.glb` |
| `scenes/obstacles/rock_boulder.tscn` | `RockBoulder` (StaticBody3D) | — | `res://assets/models/rock_boulder.glb` |
| `scenes/obstacles/rock_moss.tscn` | `RockMoss` (StaticBody3D) | — | `res://assets/models/rock_moss.glb` |
| `scenes/obstacles/rock_moss_spire.tscn` | `RockMossSpire` (StaticBody3D) | — | `res://assets/models/rock_moss_spire.glb` |
| `scenes/obstacles/rock_sandstone.tscn` | `RockSandstone` (StaticBody3D) | — | `res://assets/models/rock_sandstone.glb` |
| `scenes/obstacles/rock_spire.tscn` | `RockSpire` (StaticBody3D) | — | `res://assets/models/rock_spire.glb` |
| `scenes/plants/flower_bed.tscn` | `FlowerBed` (Node3D) | `res://scripts/plants/plant.gd` | `res://assets/models/flower_08_bed.glb` |
| `scenes/plants/flower_daisy.tscn` | `FlowerDaisy` (Node3D) | `res://scripts/plants/plant.gd` | `res://assets/models/flower_03_daisy.glb` |
| `scenes/plants/flower_rose.tscn` | `FlowerRose` (Node3D) | `res://scripts/plants/plant.gd` | `res://assets/models/flower_02_rose.glb` |
| `scenes/plants/flower_sunflower.tscn` | `FlowerSunflower` (Node3D) | `res://scripts/plants/plant.gd` | `res://assets/models/flower_04_sunflower.glb` |
| `scenes/plants/flower_tuft.tscn` | `FlowerTuft` (Node3D) | `res://scripts/plants/plant.gd` | `res://assets/models/flower_01.glb` |
| `scenes/plants/flower_tulip.tscn` | `FlowerTulip` (Node3D) | `res://scripts/plants/plant.gd` | `res://assets/models/flower_07_tulip.glb` |
| `scenes/plants/grass_black.tscn` | `GrassBlack` (Node3D) | `res://scripts/plants/plant.gd` | `res://assets/models/grass_01.glb` |
| `scenes/plants/grass_blue.tscn` | `GrassBlue` (Node3D) | `res://scripts/plants/plant.gd` | `res://assets/models/grass_01.glb` |
| `scenes/plants/grass_green.tscn` | `GrassGreen` (Node3D) | `res://scripts/plants/plant.gd` | `res://assets/models/grass_01.glb` |
| `scenes/plants/grass_purple.tscn` | `GrassPurple` (Node3D) | `res://scripts/plants/plant.gd` | `res://assets/models/grass_01.glb` |
| `scenes/plants/grass_red.tscn` | `GrassRed` (Node3D) | `res://scripts/plants/plant.gd` | `res://assets/models/grass_01.glb` |
| `scenes/plants/grass_tuft.tscn` | `GrassTuft` (Node3D) | `res://scripts/plants/plant.gd` | `res://assets/models/grass_01.glb` |
| `scenes/plants/grass_white.tscn` | `GrassWhite` (Node3D) | `res://scripts/plants/plant.gd` | `res://assets/models/grass_01.glb` |
| `scenes/plants/grass_yellow.tscn` | `GrassYellow` (Node3D) | `res://scripts/plants/plant.gd` | `res://assets/models/grass_01.glb` |
| `scenes/plants/wheat_tuft.tscn` | `WheatTuft` (Node3D) | `res://scripts/plants/plant.gd` | `res://assets/models/wheat_01.glb` |
| `scenes/tools/capture_store_screenshots.tscn` | `CaptureStoreScreenshots` (Node) | `res://scripts/tools/capture_store_screenshots.gd` | — |
| `scenes/tools/icon_photo_studio.tscn` | `IconPhotoStudio` (Node3D) | `res://scripts/tools/take_icon_photo.gd` | `res://scenes/plants/grass_green.tscn`, `res://scenes/menu/menu_bot.tscn` |
| `scenes/tools/lighting_lab.tscn` | `LightingLab` (Node3D) | `res://scripts/tools/lighting_lab.gd` (+ `res://scripts/camera/isometric_camera.gd`) | — |
| `scenes/tools/perf_test.tscn` | `PerfTest` (Node) | `res://scripts/tools/perf_test.gd` | — |
| `scenes/tools/water_tuner.tscn` | `WaterTuner` (Node3D) | `res://scripts/tools/water_tuner.gd` | — |
| `scenes/ui/cyber_nav_button.tscn` | `CyberNavButton` (Button) | `res://scripts/ui/cyber_nav_button.gd` | — |
| `scenes/ui/cyber_resource_badge.tscn` | `CyberResourceBadge` (Button) | `res://scripts/ui/cyber_resource_badge.gd` | — |
| `scenes/ui/daily_bonus_modal.tscn` | `DailyBonusModal` (Control) | `res://scripts/ui/daily_bonus_modal.gd` | — |
| `scenes/ui/defeat_modal.tscn` | `DefeatModal` (Control) | `res://scripts/ui/defeat_modal.gd` | — |
| `scenes/ui/exit_modal.tscn` | `ExitModal` (Control) | `res://scripts/ui/exit_modal.gd` | — |
| `scenes/ui/floating_joystick.tscn` | `FloatingJoystick` (Control) | `res://scripts/ui/floating_joystick.gd` | — |
| `scenes/ui/hud.tscn` | `HUD` (Control) | `res://scripts/ui/hud.gd` | `res://scenes/ui/pause_modal.tscn`, `res://scenes/ui/defeat_modal.tscn` |
| `scenes/ui/map_level_card.tscn` | `MapLevelCard` (PanelContainer) | `res://scripts/ui/map_level_card.gd` | — |
| `scenes/ui/pause_modal.tscn` | `PauseModal` (Control) | `res://scripts/ui/pause_modal.gd` | — |
| `scenes/ui/settings_modal.tscn` | `SettingsModal` (Control) | `res://scripts/ui/settings_modal.gd` | — |
