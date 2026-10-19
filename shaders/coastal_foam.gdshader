shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 foam_color : source_color = vec4(0.90, 0.98, 1.0, 0.92);
uniform vec4 foam_edge_color : source_color = vec4(0.55, 0.88, 0.98, 0.45);
uniform float wave_speed : hint_range(0.5, 5.0) = 2.2;
uniform float wave_amp : hint_range(0.01, 0.15) = 0.045;

void vertex() {
	// Sway back and forth along the outward normal (vai e vem do mar)
	// UV.y = 0.0 na base da falésia (ancorado), UV.y = 1.0 na ponta externa na água
	float wave = sin(TIME * wave_speed + VERTEX.x * 2.5 + VERTEX.z * 2.5) * 0.5 + 0.5;
	if (UV.y > 0.3) {
		VERTEX.x += NORMAL.x * wave * wave_amp * UV.y;
		VERTEX.z += NORMAL.z * wave * wave_amp * UV.y;
	}
	// Suave micro-oscilação vertical
	VERTEX.y += sin(TIME * wave_speed * 1.3 + VERTEX.x * 3.0 + VERTEX.z * 3.0) * 0.005;
}

void fragment() {
	float wave = sin(TIME * wave_speed + UV.x * 8.0) * 0.5 + 0.5;
	// Gradiente suave de espuma densa na falésia para dissolução na água
	float fade = smoothstep(1.0, 0.15, UV.y);
	vec4 col = mix(foam_edge_color, foam_color, fade);
	ALBEDO = col.rgb;
	ALPHA = col.a * fade * mix(0.78, 1.0, wave);
	ROUGHNESS = 0.35;
	SPECULAR = 0.2;
}
