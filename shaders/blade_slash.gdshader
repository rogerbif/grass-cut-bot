shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

// Shader de Slash Procedural Afilado com Base Larga na Lâmina
// 100% Analítico e Vetorial na GPU - Zero Texturas PNG para 60 FPS Mobile

uniform int blade_points : hint_range(1, 12) = 6;
uniform vec4 slash_color : source_color = vec4(1.0, 0.95, 0.65, 0.9);
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float slash_intensity : hint_range(0.0, 3.0) = 1.0;

uniform float tip_radius : hint_range(0.4, 1.0) = 0.82;
uniform float inner_radius : hint_range(0.1, 0.7) = 0.38;
uniform float arc_ratio : hint_range(0.1, 0.95) = 0.65;
uniform float angle_offset_deg : hint_range(-180.0, 180.0) = -90.0;
uniform float edge_slant_deg : hint_range(-30.0, 30.0) = 8.0;
uniform float curve_inward : hint_range(0.0, 0.2) = 0.04;
uniform float inner_curve_power : hint_range(0.2, 3.0) = 0.75;
uniform float fade_power : hint_range(0.5, 3.0) = 1.3;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float r = length(uv);

	// Rejeição precoce se fora da faixa radial do efeito
	if (r < inner_radius - 0.05 || r > tip_radius + 0.06) {
		discard;
	}

	float num_points = float(max(blade_points, 1));
	float sector = 6.28318530718 / num_points;
	float max_arc = sector * arc_ratio;

	// Ângulo polar contínuo
	float angle = atan(uv.y, uv.x);
	float offset_rad = radians(angle_offset_deg);

	// Compensação de inclinação da lateral do dente da lâmina
	float radial_norm = clamp((r - inner_radius) / max(tip_radius - inner_radius, 0.001), 0.0, 1.0);
	float slant_rad = radians(edge_slant_deg) * (1.0 - radial_norm);

	// Distância angular atrás da borda da lâmina
	float rel_angle = mod(angle - (offset_rad + slant_rad), 6.28318530718);
	if (rel_angle < 0.0) {
		rel_angle += 6.28318530718;
	}
	float t_angle = mod(rel_angle, sector);

	// Máscara angular: ativa apenas dentro do arco do rastro [0, max_arc]
	float arc_mask = smoothstep(max_arc, max_arc - 0.05, t_angle) * step(0.0, t_angle);

	// t vai de 0.0 (na lateral da lâmina) até 1.0 (na ponta da cauda do slash)
	float t = clamp(t_angle / max(max_arc, 0.0001), 0.0, 1.0);

	// Limites radiais dinâmicos em função de t:
	// Em t = 0 (na lâmina): r_inner = inner_radius (largo), r_outer = tip_radius (muito largo)
	// Em t = 1 (na ponta do slash): r_inner encontra r_outer (afinando até espessura zero)
	float target_r = tip_radius - (curve_inward * t);
	float current_r_outer = target_r + 0.015;
	float current_r_inner = mix(inner_radius, target_r - 0.015, pow(t, inner_curve_power));

	// Se o fragmento estiver fora do envelope afilado
	float width = current_r_outer - current_r_inner;
	if (width <= 0.002 || r < current_r_inner || r > current_r_outer) {
		discard;
	}

	// Perfil radial suave com antialiasing nas duas bordas
	float r_center = 0.5 * (current_r_outer + current_r_inner);
	float half_w = 0.5 * width;
	float norm_dist = abs(r - r_center) / max(half_w, 0.001);
	float radial_alpha = smoothstep(1.0, 0.65, norm_dist);

	// Fio de corte incandescente na borda externa do ataque
	float outer_edge_dist = abs(r - current_r_outer);
	float core_mask = smoothstep(0.035, 0.0, outer_edge_dist) * pow(1.0 - t, 0.5);

	// Fade de transparência ao longo do arco (vai ficando transparente até a ponta)
	float trail_fade = pow(1.0 - t, fade_power);

	float final_alpha = radial_alpha * arc_mask * trail_fade * slash_intensity;

	vec3 final_color = mix(slash_color.rgb, core_color.rgb, core_mask * core_color.a);

	ALBEDO = final_color;
	ALPHA = clamp(final_alpha * slash_color.a, 0.0, 1.0);
}
