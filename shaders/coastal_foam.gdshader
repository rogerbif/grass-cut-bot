shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

uniform vec4 shore_foam_color : source_color = vec4(0.98, 1.0, 1.0, 0.96);
uniform vec4 ripple_foam_color : source_color = vec4(0.84, 0.97, 1.0, 0.78);
uniform float wave_speed : hint_range(0.5, 5.0) = 1.85;
uniform float wave_amp : hint_range(0.0, 0.10) = 0.028;

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = VERTEX;
	// Balanço suave de vai e vem acompanhando a normal radial da curva costeira
	float tide = sin(TIME * wave_speed + VERTEX.x * 1.1 + VERTEX.z * 1.1);
	float sway = tide * wave_amp * UV.y;
	VERTEX.x += NORMAL.x * sway;
	VERTEX.z += NORMAL.z * sway;
}

void fragment() {
	// UV.y = 0.0 (dentro da base da falésia) -> UV.y = 1.0 (borda externa na água)
	float d = clamp((UV.y - 0.08) / 0.92, 0.0, 1.0);

	// Fase espacial contínua ao longo do contorno da ilha para evitar costuras entre tiles
	float spatial_phase = (v_world_pos.x + v_world_pos.z) * 2.2 + (v_world_pos.x - v_world_pos.z) * 1.4;
	float wobble = sin(spatial_phase + TIME * wave_speed) * 0.035;
	float breathe = sin(TIME * wave_speed * 0.9 + (v_world_pos.x + v_world_pos.z) * 0.8) * 0.065;

	float dist = d + wobble;

	// Faixa 1: Espuma costeira principal minimalista (2D flat/stepped) colada à curva do terreno
	float shore_limit = 0.40 + breathe;
	float band_shore = 1.0 - smoothstep(shore_limit - 0.04, shore_limit + 0.04, dist);

	// Faixa 2: Anel de maré secundário paralelo à curva (vai e vem suave)
	float ring_center = 0.68 + breathe * 1.35;
	float ring_half_w = 0.065;
	float band_ripple = (1.0 - smoothstep(ring_half_w - 0.03, ring_half_w + 0.03, abs(dist - ring_center)))
		* (1.0 - smoothstep(0.82, 0.98, d));

	vec3 final_rgb = mix(ripple_foam_color.rgb, shore_foam_color.rgb, band_shore);
	float final_alpha = max(band_shore * shore_foam_color.a, band_ripple * ripple_foam_color.a);

	ALBEDO = final_rgb;
	ALPHA = final_alpha;
}

