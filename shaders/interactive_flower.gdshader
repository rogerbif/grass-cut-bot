shader_type spatial;
render_mode cull_disabled, diffuse_toon;

// Posição e raio do cortador via Global Shader Parameters (Zero Overhead GDScript)
global uniform vec3 global_cutter_pos;
global uniform float global_cutter_interact_radius;

// Parâmetros de curvatura e interação
uniform float interact_power : hint_range(0.0, 2.0) = 0.22;
uniform float wind_speed : hint_range(0.0, 10.0) = 1.8;
uniform float wind_strength : hint_range(0.0, 1.0) = 0.08;

// Cores das pétalas e do miolo (Low Poly Matte)
uniform vec4 petal_color : source_color = vec4(1.0, 0.18, 0.65, 1.0);
uniform vec4 center_color : source_color = vec4(1.0, 0.85, 0.05, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.85;
uniform float specular : hint_range(0.0, 1.0) = 0.15;
uniform float vibrancy : hint_range(0.0, 1.0) = 0.18;

// Para nós individuais de flor que não utilizam MultiMeshInstance3D
instance uniform float instance_hit_stage : hint_range(0.0, 2.0) = 0.0;

void vertex() {
	// Determina o estágio de despetalação ativo (MultiMesh via INSTANCE_CUSTOM.r ou nó individual)
	float stage = max(INSTANCE_CUSTOM.r, instance_hit_stage);

	// Estágio 1 (Hit 1): Colapsa as 8 pétalas externas (marcadas com COLOR.r == 0.5)
	if (stage >= 0.95 && COLOR.r > 0.35 && COLOR.r < 0.75) {
		VERTEX = vec3(0.0);
	}

	// Estágio 2 (Hit 2): Colapsa as 8 pétalas internas (marcadas com COLOR.r == 1.0)
	if (stage >= 1.95 && COLOR.r > 0.85) {
		VERTEX = vec3(0.0);
	}

	// Converte para coordenadas globais de mundo
	vec3 world_vert = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Balanço pendular com o vento: flores balançam suavemente no topo
	float bend_factor = clamp(VERTEX.y / 1.1, 0.0, 1.0);
	bend_factor = bend_factor * bend_factor;

	float sway_x = sin(TIME * wind_speed + world_vert.x * 1.5 + world_vert.z * 1.2) * (wind_strength * bend_factor);
	float sway_z = cos(TIME * (wind_speed * 0.8) + world_vert.z * 1.8) * (wind_strength * 0.7 * bend_factor);

	VERTEX.x += sway_x;
	VERTEX.z += sway_z;
	VERTEX.y -= (abs(sway_x) + abs(sway_z)) * 0.15;

	// Interação com o cortador
	vec3 diff = world_vert - global_cutter_pos;
	float dist_sq = dot(diff, diff);
	float r_sq = global_cutter_interact_radius * global_cutter_interact_radius;
	if (dist_sq < r_sq) {
		vec3 direction = vec3(diff.x, 0.0, diff.z);
		float len = length(direction);
		vec3 dir_norm = (len > 0.001) ? (direction / len) : vec3(0.0, 0.0, 1.0);
		float dist = sqrt(dist_sq);
		float power = smoothstep(global_cutter_interact_radius, 0.0, dist);

		vec3 col_x = MODEL_MATRIX[0].xyz;
		vec3 col_z = MODEL_MATRIX[2].xyz;
		float inv_scale_sq = 1.0 / max(dot(col_x, col_x), 0.0001);

		vec3 model_dir = vec3(dot(dir_norm, col_x), 0.0, dot(dir_norm, col_z)) * inv_scale_sq;
		VERTEX += model_dir * (power * interact_power * bend_factor);
		VERTEX.y -= power * interact_power * 0.10 * bend_factor;
	}
}

void fragment() {
	// Se for miolo (COLOR.g > 0.5 assado no Blender), aplica center_color; senão petal_color
	vec3 base_col = (COLOR.g > 0.5) ? center_color.rgb : petal_color.rgb;
	ALBEDO = base_col;
	EMISSION = base_col * vibrancy;
	ROUGHNESS = roughness;
	SPECULAR = specular;
}
