shader_type spatial;
render_mode cull_disabled;

// Posição e raio do cortador (atualizados pelo cortador no material compartilhado)
uniform vec3 cutter_pos = vec3(0.0);
uniform float cutter_interact_radius = 1.6;

// Parâmetros de curvatura e interação
uniform float interact_power : hint_range(0.0, 2.0) = 0.85;
uniform float wind_speed : hint_range(0.0, 10.0) = 2.0;
uniform float wind_strength : hint_range(0.0, 1.0) = 0.12;

// Gradiente de cor fosco Low Poly (base -> topo)
uniform vec4 color_base : source_color = vec4(0.12, 0.42, 0.16, 1.0);
uniform vec4 color_top : source_color = vec4(0.35, 0.78, 0.38, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.9;
uniform float specular : hint_range(0.0, 1.0) = 0.15;

void vertex() {
	// Converte para coordenadas globais de mundo
	vec3 world_vert = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Fator de altura: a base da planta fica firme no chão e a ponta se curva
	float height_factor = clamp(1.0 - UV.y, 0.0, 1.0);
	if (height_factor < 0.05 && VERTEX.y > 0.0) {
		height_factor = clamp(VERTEX.y / 0.6, 0.0, 1.0);
	}

	// Curvatura elástica não-linear: base ancorada e ponta arqueada
	float bend_factor = pow(height_factor, 1.8);

	// Identificação e parâmetros individuais de cada folha (via COLOR assado no Blender)
	float blade_phase = 0.0;
	float blade_angle = 0.0;
	float blade_freq = 1.0;

	// Verifica se a malha possui atributos de vertice assados
	bool has_baked_attr = !(COLOR.r > 0.999 && COLOR.g > 0.999 && COLOR.b > 0.999);
	if (has_baked_attr) {
		blade_phase = COLOR.r * 6.2831853;
		blade_angle = (COLOR.g - 0.5) * 6.2831853;
		blade_freq = mix(0.85, 1.15, COLOR.b);
	} else {
		// Fallback gracioso baseado na posição radial do vértice no tufo
		blade_angle = atan(VERTEX.z, VERTEX.x);
		blade_phase = fract(sin(floor((blade_angle + 3.14159) * 9.0) * 43758.5453)) * 6.2831853;
		blade_freq = 1.0;
	}

	// Vetores ortogonais no espaço do tufo para pender de um lado para o outro
	vec3 dir_fwd = vec3(cos(blade_angle), 0.0, sin(blade_angle));
	vec3 dir_side = vec3(-sin(blade_angle), 0.0, cos(blade_angle));

	// 1. Pender suavemente de um lado para o outro (oscilação lateral predominante)
	float sway_side = sin(TIME * (wind_speed * blade_freq) + blade_phase);

	// 2. Respiração suave para frente e para trás com frequência secundária
	float sway_fwd = cos(TIME * (wind_speed * blade_freq * 0.65) + blade_phase * 1.4) * 0.35;

	// Deslocamento pendular individual da folha
	vec3 leaf_sway = (dir_side * sway_side + dir_fwd * sway_fwd) * (wind_strength * bend_factor);

	// Brisa global sutil para coerência de campo
	vec3 global_breeze = vec3(sin(TIME * 0.7 + world_vert.x * 0.25), 0.0, cos(TIME * 0.5 + world_vert.z * 0.25)) * (wind_strength * 0.35 * bend_factor);
	vec3 model_breeze = mat3(inverse(MODEL_MATRIX)) * global_breeze;

	// Aplica balanço suave das folhas
	VERTEX += leaf_sway + model_breeze;

	// --- Interação com a lâmina do cortador ---
	vec3 direction = world_vert - cutter_pos;
	direction.y = 0.0;
	float len = length(direction);
	vec3 dir_norm = (len > 0.001) ? (direction / len) : vec3(0.0, 0.0, 1.0);

	float dist = distance(cutter_pos, world_vert);
	float power = smoothstep(cutter_interact_radius, 0.0, dist);

	vec3 model_dir = mat3(inverse(MODEL_MATRIX)) * dir_norm;
	VERTEX += model_dir * (power * interact_power * bend_factor);
	VERTEX.y -= power * interact_power * 0.14 * bend_factor;
}

void fragment() {
	float h = clamp(1.0 - UV.y, 0.0, 1.0);
	ALBEDO = mix(color_base.rgb, color_top.rgb, h);
	ROUGHNESS = roughness;
	SPECULAR = specular;
}
