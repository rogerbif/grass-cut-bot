shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

/* Teleport Effect Shader for Godot 4 Spatial
   Adapted from https://godotshaders.com/shader/teleport-effect/ (by pend00)
   Features procedural gradient noise, glowing beam edge, and bidirectional sweep. */

// Propriedades do material PBR preservadas da malha original
uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform bool use_texture = false;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.5;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy : hint_range(0.0, 10.0) = 0.0;

// Parâmetros do teleporte
// mode 0: Desaparece de cima para baixo (Teleport Out)
// mode 1: Aparece de baixo para cima (Teleport In)
uniform int mode : hint_range(0, 1) = 0;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float noise_density = 40.0;
uniform float beam_size : hint_range(0.01, 0.35) = 0.10;
uniform vec4 beam_color : source_color = vec4(0.0, 1.02, 1.2, 1.0);
uniform float beam_emission : hint_range(0.0, 10.0) = 4.0;

// Posição de mundo e dimensões do robô para cálculo de altura unificada
uniform float bot_world_y = 0.0;
uniform float bot_height = 1.35;
uniform float bot_y_offset = -0.32;

varying vec3 v_world_pos;

// Ruído de gradiente procedural do shader pend00
vec2 random(vec2 uv) {
	uv = vec2(dot(uv, vec2(127.1, 311.7)),
	          dot(uv, vec2(269.5, 183.3)));
	return -1.0 + 2.0 * fract(sin(uv) * 43758.5453123);
}

float noise(vec2 uv) {
	vec2 uv_index = floor(uv);
	vec2 uv_fract = fract(uv);
	vec2 blur = smoothstep(0.0, 1.0, uv_fract);
	return mix(
		mix(dot(random(uv_index + vec2(0.0, 0.0)), uv_fract - vec2(0.0, 0.0)),
		    dot(random(uv_index + vec2(1.0, 0.0)), uv_fract - vec2(1.0, 0.0)), blur.x),
		mix(dot(random(uv_index + vec2(0.0, 1.0)), uv_fract - vec2(0.0, 1.0)),
		    dot(random(uv_index + vec2(1.0, 1.0)), uv_fract - vec2(1.0, 1.0)), blur.x), blur.y
	) * 0.5 + 0.5;
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// 1. Altura normalizada unificada em coordenadas globais relativas à base do robô
	float bot_base = bot_world_y + bot_y_offset;
	float span = max(bot_height, 0.01);
	float h = clamp((v_world_pos.y - bot_base) / span, 0.0, 1.0);

	// 2. Ruído procedural amostrado pelas coordenadas espaciais
	vec2 noise_coord = vec2(v_world_pos.x * 2.5 + v_world_pos.z * 1.5, v_world_pos.y * 3.0) * noise_density * 0.05;
	float n = noise(noise_coord);

	// 3. Lógica bidirecional do feixe e descarte
	float extended_progress = progress * (1.0 + beam_size * 2.0) - beam_size;
	bool is_beam = false;

	if (mode == 0) {
		// DESAPARECENDO DE CIMA PARA BAIXO (Teleport Out)
		// Topo (h=1) dissolve primeiro, base (h=0) dissolve por último
		float coord = 1.0 - h;
		float val = coord + (n - 0.5) * 0.12;

		if (val < extended_progress - beam_size) {
			discard;
		} else if (val < extended_progress) {
			is_beam = true;
		}
	} else {
		// APARECENDO DE BAIXO PARA CIMA (Teleport In)
		// Base (h=0) materializa primeiro, topo (h=1) materializa por último
		float coord = h;
		float val = coord + (n - 0.5) * 0.12;

		if (val > extended_progress) {
			discard;
		} else if (val > extended_progress - beam_size) {
			is_beam = true;
		}
	}

	if (is_beam) {
		ALBEDO = beam_color.rgb;
		EMISSION = beam_color.rgb * beam_emission;
		ROUGHNESS = 0.2;
		METALLIC = 0.8;
	} else {
		// Renderização normal PBR se o fragmento não for descartado nem fizer parte do feixe
		vec4 base_col = albedo_color;
		if (use_texture) {
			base_col *= texture(albedo_texture, UV);
		}
		ALBEDO = base_col.rgb;
		METALLIC = metallic;
		ROUGHNESS = roughness;
		EMISSION = emission_color.rgb * emission_energy;
	}
}
