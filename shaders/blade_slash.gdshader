shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

// Shader de Slash Procedural com Afinamento Dinâmico por Ponta de Lâmina
// 100% Analítico e Vetorial na GPU - Zero Texturas PNG para 60 FPS Mobile

uniform int blade_points : hint_range(1, 12) = 6;
uniform vec4 slash_color : source_color = vec4(1.0, 0.95, 0.65, 0.9);
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float slash_intensity : hint_range(0.0, 3.0) = 1.0;

uniform float tip_radius : hint_range(0.2, 1.0) = 0.79;
uniform float base_width : hint_range(0.01, 0.3) = 0.11;
uniform float arc_ratio : hint_range(0.1, 0.95) = 0.65;
uniform float angle_offset_deg : hint_range(-180.0, 180.0) = -90.0;
uniform float curve_inward : hint_range(0.0, 0.2) = 0.035;
uniform float taper_power : hint_range(0.5, 3.0) = 1.3;
uniform float fade_power : hint_range(0.5, 3.0) = 1.4;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float r = length(uv);

	float num_points = float(max(blade_points, 1));
	float sector = 6.28318530718 / num_points;
	float max_arc = sector * arc_ratio;

	// Ângulo polar contínuo
	float angle = atan(uv.y, uv.x);
	float offset_rad = radians(angle_offset_deg);

	// Distância angular atrás da ponta mais próxima (rastro de corte trailing)
	float rel_angle = mod(angle - offset_rad, 6.28318530718);
	if (rel_angle < 0.0) {
		rel_angle += 6.28318530718;
	}
	float t_angle = mod(rel_angle, sector);

	// Máscara angular: ativa apenas dentro do arco do rastro [0, max_arc]
	float arc_mask = smoothstep(max_arc, max_arc - 0.04, t_angle) * step(0.0, t_angle);

	// t vai de 0.0 (na ponta da lâmina) até 1.0 (no final da cauda do slash)
	float t = clamp(t_angle / max(max_arc, 0.0001), 0.0, 1.0);

	// Afinamento progressivo da largura: começa largo e afina até a ponta
	float current_width = max(base_width * pow(1.0 - t, taper_power), 0.002);

	// Linha central do arco (com encurvamento dinâmico sutil)
	float r_center = tip_radius - (curve_inward * t);

	// Perfil radial suave com antialiasing
	float dist = abs(r - r_center);
	float radial_alpha = smoothstep(current_width, current_width * 0.15, dist);

	// Núcleo cortante incandescente (fio de corte no centro da lâmina)
	float core_mask = smoothstep(current_width * 0.45, 0.0, dist) * pow(1.0 - t, 0.6);

	// Atenuação de transparência ao longo do arco (fade-out até a ponta)
	float trail_fade = pow(1.0 - t, fade_power);

	float final_alpha = radial_alpha * arc_mask * trail_fade * slash_intensity;

	vec3 final_color = mix(slash_color.rgb, core_color.rgb, core_mask * core_color.a);

	ALBEDO = final_color;
	ALPHA = clamp(final_alpha * slash_color.a, 0.0, 1.0);
}
