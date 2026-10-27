shader_type spatial;
// cull_disabled é essencial para preservar o volume foliar das 39 lâminas de face única (grass_01.glb)
// sem falhas de transparência e sem flickering ao balançar no vento.
render_mode cull_disabled;

// Posição e raio do cortador via Global Shader Parameters (Zero Overhead GDScript)
global uniform vec3 global_cutter_pos;
global uniform float global_cutter_interact_radius;

// Parâmetros de curvatura e interação
uniform float interact_power : hint_range(0.0, 2.0) = 0.29;
uniform float wind_speed : hint_range(0.0, 10.0) = 2.0;
uniform float wind_strength : hint_range(0.0, 1.0) = 0.12;

// Parâmetros Toon Shader Gradiente (Calibrados)
group_uniforms ToonGradiente;
uniform vec4 color_light : source_color = vec4(0.42, 0.88, 0.46, 1.0);
uniform vec4 color_base : source_color = vec4(0.12, 0.35, 0.18, 1.0);
uniform vec4 color_shadow : source_color = vec4(0.18, 0.48, 0.25, 1.0);
uniform float vertical_gradient_mix : hint_range(0.0, 1.0) = 0.81;

group_uniforms ToonRamp;
uniform float toon_ramp_offset : hint_range(0.0, 1.0) = 0.97;
uniform float toon_ramp_smoothness : hint_range(0.001, 1.0) = 1.00;
uniform vec3 toon_ramp_tinting : source_color = vec3(1.0, 1.0, 1.0);

group_uniforms RimLighting;
uniform bool use_rim = true;
uniform vec4 rim_color : source_color = vec4(0.85, 1.0, 0.65, 1.0);
uniform float rim_power : hint_range(0.1, 8.0) = 1.0;
uniform float rim_cutoff : hint_range(0.0, 1.0) = 0.45;
uniform float rim_smoothness : hint_range(0.001, 1.0) = 0.15;
uniform float rim_brightness : hint_range(0.0, 4.0) = 1.0;

group_uniforms Surface;
uniform float roughness : hint_range(0.0, 1.0) = 0.90;
uniform float specular : hint_range(0.0, 1.0) = 0.15;
uniform float vibrancy : hint_range(0.0, 1.0) = 0.0;

void vertex() {
	// Converte para coordenadas globais de mundo
	vec3 world_vert = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Altura normalizada da folha: 0.0 na raiz (UV.y = 0.0) até 1.0 na ponta (UV.y = 1.0)
	float h = clamp(UV.y, 0.0, 1.0);

	// A base da folha fica 100% estática, agindo rigorosamente como uma dobradiça/eixo na raiz.
	// Vértices abaixo de 6% de altura possuem deslocamento rigorosamente zero.
	float bend_factor = smoothstep(0.06, 1.0, h);
	// Curva quadrática não-linear: o movimento cresce em arco até o topo
	bend_factor = bend_factor * bend_factor;

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
		blade_angle = 0.0;
		blade_phase = world_vert.x * 1.7 + world_vert.z * 2.3;
		blade_freq = 1.0;
	}

	// Vetores ortogonais no espaço do tufo para pender de um lado para o outro
	vec3 dir_fwd = vec3(cos(blade_angle), 0.0, sin(blade_angle));
	vec3 dir_side = vec3(-sin(blade_angle), 0.0, cos(blade_angle));

	// 1. Pender suavemente de um lado para o outro (oscilação lateral predominante)
	float sway_side = sin(TIME * (wind_speed * blade_freq) + blade_phase);

	// 2. Respiração suave para frente e para trás com frequência secundária
	float sway_fwd = cos(TIME * (wind_speed * blade_freq * 0.65) + blade_phase * 1.4) * 0.35;

	// Deslocamento pendular individual da folha ancorado na base
	vec3 leaf_sway = (dir_side * sway_side + dir_fwd * sway_fwd) * (wind_strength * bend_factor);

	// Conversão rápida mundo -> modelo para vetores horizontais (sem inverse() por vértice)
	vec3 col_x = MODEL_MATRIX[0].xyz;
	vec3 col_z = MODEL_MATRIX[2].xyz;
	float inv_scale_sq = 1.0 / max(dot(col_x, col_x), 0.0001);

	// Brisa global sutil para coerência de campo
	vec3 global_breeze = vec3(sin(TIME * 0.7 + world_vert.x * 0.25), 0.0, cos(TIME * 0.5 + world_vert.z * 0.25)) * (wind_strength * 0.35 * bend_factor);
	vec3 model_breeze = vec3(dot(global_breeze, col_x), 0.0, dot(global_breeze, col_z)) * inv_scale_sq;

	// Aplica balanço suave das folhas
	VERTEX += leaf_sway + model_breeze;

	// Compensação de arco: ao inclinar horizontalmente em torno da base fixa, o topo desce ligeiramente em Y
	float sway_displacement = length(leaf_sway.xz);
	VERTEX.y -= sway_displacement * 0.22;

	// --- Interação com a lâmina do cortador (com early-out fora do raio via Global Uniforms) ---
	vec3 diff = world_vert - global_cutter_pos;
	float dist_sq = dot(diff, diff);
	float r_sq = global_cutter_interact_radius * global_cutter_interact_radius;
	if (dist_sq < r_sq) {
		vec3 direction = vec3(diff.x, 0.0, diff.z);
		float len = length(direction);
		vec3 dir_norm = (len > 0.001) ? (direction / len) : vec3(0.0, 0.0, 1.0);

		float dist = sqrt(dist_sq);
		float power = smoothstep(global_cutter_interact_radius, 0.0, dist);

		vec3 model_dir = vec3(dot(dir_norm, col_x), 0.0, dot(dir_norm, col_z)) * inv_scale_sq;
		VERTEX += model_dir * (power * interact_power * bend_factor);
		VERTEX.y -= power * interact_power * 0.14 * bend_factor;
	}
}

void fragment() {
	// Gradiente vertical de altura foliar (Base escura -> Topo iluminado)
	float h = clamp(UV.y, 0.0, 1.0);
	vec3 base_surface = mix(color_base.rgb, color_light.rgb, mix(1.0, h, vertical_gradient_mix));

	ALBEDO = base_surface;
	EMISSION = base_surface * vibrancy;
	ROUGHNESS = roughness;
	SPECULAR = specular;
}

void light() {
	// Cálculo do Toon Ramp Gradiente
	float NdotL = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	float half_smooth = max(toon_ramp_smoothness * 0.5, 0.001);
	float toon_ramp = smoothstep(toon_ramp_offset - half_smooth, toon_ramp_offset + half_smooth, NdotL * ATTENUATION);

	// Modulação direta entre a cor de sombra e a cor iluminada
	vec3 diffuse_light = mix(color_shadow.rgb, LIGHT_COLOR * toon_ramp_tinting, toon_ramp);
	DIFFUSE_LIGHT += diffuse_light * ATTENUATION;

	// Rim Lighting estilizado (silhueta brilhante suave restrita às pontas das folhas)
	if (use_rim) {
		float h_mask = clamp(UV.y, 0.0, 1.0);
		h_mask = h_mask * h_mask; // Apenas nas pontas superiores
		float NdotV = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		float rim = (1.0 - NdotV) * pow(max(NdotL, 0.001), rim_power * 0.5);
		float rim_half_smooth = max(rim_smoothness * 0.5, 0.001);
		float rim_ramp = smoothstep(rim_cutoff - rim_half_smooth, rim_cutoff + rim_half_smooth, rim);
		DIFFUSE_LIGHT += rim_color.rgb * rim_ramp * rim_brightness * h_mask * ATTENUATION;
	}
}
