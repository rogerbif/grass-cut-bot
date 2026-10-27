shader_type spatial;
render_mode diffuse_toon, specular_toon;

uniform int toon_mode : hint_range(0, 4) = 0;
uniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform bool use_texture = false;
uniform float roughness : hint_range(0.0, 1.0) = 0.9;
uniform vec3 shadow_tint : source_color = vec3(0.28, 0.35, 0.6);
uniform bool toon_specular = false;
uniform float specular_size : hint_range(0.01, 0.3) = 0.06;
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.42;
uniform float midtone_threshold : hint_range(0.0, 1.0) = 0.72;

void fragment() {
	vec4 col = albedo;
	if (use_texture) {
		col *= texture(albedo_texture, UV);
	}
	ALBEDO = col.rgb;
	ROUGHNESS = roughness;
}

void light() {
	float NdotL = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	float att = NdotL * ATTENUATION;

	// Modo 0: PBR Suave Clássico (Fosco do jogo)
	if (toon_mode == 0) {
		DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * att;
	}
	// Modo 1: Godot Built-in Toon (degrau simples)
	else if (toon_mode == 1) {
		float step_val = smoothstep(0.28, 0.34, att);
		DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * mix(0.35, 1.0, step_val);
	}
	// Modo 2: Cel Shading 2-Tons (Anime Cut com transição afiada)
	else if (toon_mode == 2) {
		float step_val = smoothstep(shadow_threshold - 0.015, shadow_threshold + 0.015, att);
		DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * mix(0.28, 1.0, step_val);
	}
	// Modo 3: Cel Shading 3-Tons (Luz direta, meio-tom suave e sombra)
	else if (toon_mode == 3) {
		float shadow_step = smoothstep(shadow_threshold - 0.015, shadow_threshold + 0.015, att);
		float mid_step = smoothstep(midtone_threshold - 0.015, midtone_threshold + 0.015, att);
		float level = mix(0.28, mix(0.68, 1.0, mid_step), shadow_step);
		DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * level;
	}
	// Modo 4: Sombra Colorida Pastel (Ambient Stylized Tint)
	else if (toon_mode == 4) {
		float step_val = smoothstep(shadow_threshold - 0.015, shadow_threshold + 0.015, att);
		vec3 lit_color = LIGHT_COLOR;
		vec3 shaded_color = shadow_tint * LIGHT_COLOR * 1.4;
		vec3 final_light = mix(shaded_color, lit_color, step_val);
		DIFFUSE_LIGHT += ALBEDO * final_light;
	}

	// Destaque especular toon circular (opcional)
	if (toon_specular) {
		vec3 half_vec = normalize(VIEW + LIGHT);
		float NdotH = max(dot(NORMAL, half_vec), 0.0);
		float spec_power = pow(NdotH, 48.0);
		float spec_step = smoothstep(1.0 - specular_size - 0.02, 1.0 - specular_size + 0.02, spec_power);
		SPECULAR_LIGHT += LIGHT_COLOR * spec_step * 0.75;
	}
}
