shader_type spatial;
render_mode cull_disabled;

group_uniforms BaseColors;
uniform vec4 color_light : source_color = vec4(0.38, 0.82, 0.42, 1.0);
uniform vec4 color_base : source_color = vec4(0.12, 0.32, 0.16, 1.0);
uniform vec4 color_shadow : source_color = vec4(0.18, 0.45, 0.24, 1.0);
uniform float vertical_gradient_mix : hint_range(0.0, 1.0) = 0.50;
uniform float model_height_scale : hint_range(0.1, 5.0) = 1.0;

group_uniforms ToonRamp;
uniform float toon_ramp_offset : hint_range(0.0, 1.0) = 0.48;
uniform float toon_ramp_smoothness : hint_range(0.001, 1.0) = 0.10;
uniform vec3 toon_ramp_tinting : source_color = vec3(1.0, 1.0, 1.0);

group_uniforms RimLighting;
uniform bool use_rim = true;
uniform vec4 rim_color : source_color = vec4(0.85, 1.0, 0.65, 1.0);
uniform float rim_power : hint_range(0.1, 8.0) = 2.0;
uniform float rim_cutoff : hint_range(0.0, 1.0) = 0.45;
uniform float rim_smoothness : hint_range(0.001, 1.0) = 0.15;
uniform float rim_brightness : hint_range(0.0, 4.0) = 1.2;

group_uniforms Surface;
uniform float roughness : hint_range(0.0, 1.0) = 0.90;
uniform bool use_specular = false;
uniform float specular_size : hint_range(0.01, 0.3) = 0.06;

varying vec3 v_vertex_local;

void vertex() {
	v_vertex_local = VERTEX;
}

void fragment() {
	// Gradiente vertical de altura do tufo (Base escura da raiz até o topo iluminado)
	float height_t = clamp((v_vertex_local.y / model_height_scale) + 0.15, 0.0, 1.0);
	vec3 base_surface = mix(color_base.rgb, color_light.rgb, mix(1.0, height_t, vertical_gradient_mix));

	ALBEDO = base_surface;
	ROUGHNESS = roughness;
}

void light() {
	// Cálculo do Toon Ramp (estilo MinionsArt)
	float NdotL = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	float half_smooth = max(toon_ramp_smoothness * 0.5, 0.001);
	float toon_ramp = smoothstep(toon_ramp_offset - half_smooth, toon_ramp_offset + half_smooth, NdotL * ATTENUATION);

	// Modulação direta entre a cor de sombra escolhida e a cor iluminada
	vec3 diffuse_light = mix(color_shadow.rgb, LIGHT_COLOR * toon_ramp_tinting, toon_ramp);
	DIFFUSE_LIGHT += diffuse_light * ATTENUATION;

	// Rim Lighting (luz de silhueta nas bordas contra o sol)
	if (use_rim) {
		float NdotV = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		float rim = (1.0 - NdotV) * pow(max(NdotL, 0.001), rim_power * 0.5);
		float rim_half_smooth = max(rim_smoothness * 0.5, 0.001);
		float rim_ramp = smoothstep(rim_cutoff - rim_half_smooth, rim_cutoff + rim_half_smooth, rim);
		DIFFUSE_LIGHT += rim_color.rgb * rim_ramp * rim_brightness * ATTENUATION;
	}

	// Brilho especular toon opcional
	if (use_specular) {
		vec3 half_vec = normalize(VIEW + LIGHT);
		float NdotH = max(dot(NORMAL, half_vec), 0.0);
		float spec_power = pow(NdotH, 36.0);
		float spec_step = smoothstep(1.0 - specular_size - 0.01, 1.0 - specular_size + 0.01, spec_power);
		SPECULAR_LIGHT += LIGHT_COLOR * spec_step * 0.8;
	}
}
