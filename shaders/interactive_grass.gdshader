shader_type spatial;
render_mode cull_disabled;

// Posição e raio do cortador (atualizados pelo cortador no material compartilhado)
uniform vec3 cutter_pos = vec3(0.0);
uniform float cutter_interact_radius = 1.6;


// Parâmetros de curvatura e interação
uniform float interact_power : hint_range(0.0, 2.0) = 0.85;
uniform float wind_speed : hint_range(0.0, 10.0) = 2.5;
uniform float wind_strength : hint_range(0.0, 1.0) = 0.08;

// Gradiente de cor fosco Low Poly (base -> topo)
uniform vec4 color_base : source_color = vec4(0.12, 0.42, 0.16, 1.0);
uniform vec4 color_top : source_color = vec4(0.35, 0.78, 0.38, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.9;
uniform float specular : hint_range(0.0, 1.0) = 0.15;

void vertex() {
	// Converte para coordenadas globais de mundo
	vec3 world_vert = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Vetor horizontal de afastamento do cortador
	vec3 direction = world_vert - cutter_pos;
	direction.y = 0.0;
	float len = length(direction);
	vec3 dir_norm = (len > 0.001) ? (direction / len) : vec3(0.0, 0.0, 1.0);

	// Atenuação suave por distância radial
	float dist = distance(cutter_pos, world_vert);
	float power = smoothstep(cutter_interact_radius, 0.0, dist);

	// Fator de altura: a base da planta fica firme no chão e a ponta se curva
	float height_factor = clamp(1.0 - UV.y, 0.0, 1.0);
	if (height_factor < 0.05 && VERTEX.y > 0.0) {
		height_factor = clamp(VERTEX.y / 0.6, 0.0, 1.0);
	}

	// Curvatura elastica nao-linear: base ancorada e ponta arqueada
	float bend_factor = pow(height_factor, 1.6);

	// Converte direcao radial para o espaco de modelo e deforma o vertice
	vec3 model_dir = mat3(inverse(MODEL_MATRIX)) * dir_norm;
	VERTEX += model_dir * (power * interact_power * bend_factor);

	// Compressao/abaixamento elastico vertical na aproximacao da lamina
	VERTEX.y -= power * interact_power * 0.14 * bend_factor;

	// Balanco organico de vento em coordenadas globais com ondas cruzadas
	float wave_x = sin(TIME * wind_speed + world_vert.x * 2.0 + world_vert.z * 1.5);
	float wave_z = cos(TIME * (wind_speed * 0.8) + world_vert.x * 1.2 + world_vert.z * 2.2);
	vec3 world_wind = vec3(wave_x, 0.0, wave_z * 0.6) * (wind_strength * bend_factor);
	vec3 model_wind = mat3(inverse(MODEL_MATRIX)) * world_wind;
	VERTEX += model_wind;
}

void fragment() {
	float h = clamp(1.0 - UV.y, 0.0, 1.0);
	ALBEDO = mix(color_base.rgb, color_top.rgb, h);
	ROUGHNESS = roughness;
	SPECULAR = specular;
}
