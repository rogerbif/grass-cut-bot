shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

// Shader de Rastro da Lâmina em 3 Faixas Concêntricas (Estilo Referência)
// 100% Analítico e Vetorial na GPU - Zero Texturas PNG para 60 FPS Mobile

uniform int blade_points : hint_range(1, 12) = 6;
uniform vec4 slash_color : source_color = vec4(0.68, 0.98, 0.34, 0.92);
uniform vec4 core_color : source_color = vec4(0.86, 1.0, 0.52, 1.0);
uniform float slash_intensity : hint_range(0.0, 3.0) = 0.85;

uniform float tip_radius : hint_range(0.4, 1.0) = 0.81;
uniform float inner_radius : hint_range(0.05, 0.7) = 0.38;
uniform float arc_ratio : hint_range(0.1, 0.95) = 0.82;
uniform float angle_offset_deg : hint_range(-180.0, 180.0) = -90.0;
uniform float edge_slant_deg : hint_range(-30.0, 30.0) = 14.0;
uniform float curve_inward : hint_range(0.0, 0.2) = 0.02;
uniform float inner_curve_power : hint_range(0.2, 3.0) = 0.75;
uniform float fade_power : hint_range(0.5, 3.0) = 1.15;

float compute_band_mask(float r, float r_center, float half_width) {
	float d = abs(r - r_center);
	return smoothstep(half_width, half_width * 0.45, d);
}

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float r = length(uv);

	// Rejeição precoce se fora da faixa radial das 3 bandas
	if (r < inner_radius - 0.04 || r > tip_radius + 0.04) {
		discard;
	}

	float num_points = float(max(blade_points, 1));
	float sector = 6.28318530718 / num_points;
	float max_arc = sector * arc_ratio;

	// Ângulo polar contínuo
	float angle = atan(uv.y, uv.x);
	float offset_rad = radians(angle_offset_deg);

	// Compensação da inclinação da borda do dente da lâmina (os 3 traços ao longo da aresta)
	float radial_norm = clamp((r - inner_radius) / max(tip_radius - inner_radius, 0.001), 0.0, 1.0);
	float slant_rad = radians(edge_slant_deg) * (1.0 - radial_norm);

	// Distância angular atrás da borda da lâmina no sentido de giro
	float rel_angle = mod(angle - (offset_rad + slant_rad), 6.28318530718);
	if (rel_angle < 0.0) {
		rel_angle += 6.28318530718;
	}
	float t_angle = mod(rel_angle, sector);

	// t vai de 0.0 (junto à aresta do dente da lâmina) até 1.0 (final do arco)
	float t = clamp(t_angle / max(max_arc, 0.0001), 0.0, 1.0);
	float arc_mask = smoothstep(max_arc, max_arc * 0.82, t_angle) * step(0.0, t_angle);
	if (arc_mask <= 0.001) {
		discard;
	}

	// Leve espiral para dentro ao longo do rastro
	float spiral_shift = curve_inward * t;

	// --- 3 Faixas Concêntricas Alinhadas aos 3 Pontos da Lâmina ---
	// 1. Faixa Externa (Ponta da Lâmina - 1º traço): fina e longa
	float r1_center = (tip_radius - 0.032) - spiral_shift * 0.7;
	float r1_half_w = mix(0.026, 0.008, pow(t, inner_curve_power));
	float band_outer = compute_band_mask(r, r1_center, r1_half_w) * smoothstep(1.0, 0.72, t);

	// 2. Faixa Média (Meio da Lâmina - 2º traço): mais larga e brilhante
	float r2_center = mix(inner_radius, tip_radius, 0.60) - spiral_shift;
	float r2_half_w = mix(0.048, 0.014, pow(t, inner_curve_power));
	float band_mid = compute_band_mask(r, r2_center, r2_half_w) * smoothstep(0.96, 0.65, t);

	// 3. Faixa Interna (Base do Dente - 3º traço): arco interno compacto
	float r3_center = (inner_radius + 0.048) - spiral_shift * 1.1;
	float r3_half_w = mix(0.036, 0.010, pow(t, inner_curve_power));
	float band_inner = compute_band_mask(r, r3_center, r3_half_w) * smoothstep(0.86, 0.52, t);

	// Combinação das 3 faixas concêntricas bem definidas + halo suave no pé da lâmina
	float bands_combined = max(band_outer, max(band_mid, band_inner));
	float base_halo = smoothstep(inner_radius, inner_radius + 0.04, r) * smoothstep(tip_radius, tip_radius - 0.03, r) * pow(1.0 - t, 1.8) * 0.28;
	float radial_mask = clamp(bands_combined + base_halo, 0.0, 1.0);

	if (radial_mask <= 0.005) {
		discard;
	}

	// Atenuação suave ao longo do arco
	float trail_fade = pow(1.0 - t, fade_power);
	float final_alpha = radial_mask * arc_mask * trail_fade * clamp(slash_intensity, 0.0, 1.5);

	// Destaque luminoso amarelo-lima no centro de cada faixa e junto à borda da lâmina
	float highlight = bands_combined * mix(0.85, 0.25, t);
	vec3 final_color = mix(slash_color.rgb, core_color.rgb, clamp(highlight * core_color.a, 0.0, 1.0));

	ALBEDO = final_color;
	ALPHA = clamp(final_alpha * slash_color.a, 0.0, 1.0);
}
