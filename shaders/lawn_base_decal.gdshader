shader_type spatial;
render_mode cull_back, unshaded, blend_mix;

// Decalque plano orgânico de solo verde sob os tufos
uniform sampler2D density_tex : hint_default_black, filter_linear;
uniform sampler2D cut_tex : hint_default_transparent, filter_linear;

uniform vec2 island_origin = vec2(0.0, 0.0);
uniform vec2 island_size = vec2(10.0, 10.0);
uniform vec4 lawn_color : source_color = vec4(0.20, 0.58, 0.25, 0.55);
uniform vec4 mowed_color : source_color = vec4(0.38, 0.76, 0.32, 0.40);

void vertex() {
	// Leve elevação Y (+0.005m) sobre o topo do bloco de terreno para evitar z-fighting
	VERTEX.y += 0.005;
}

void fragment() {
	// Converte coordenadas mundiais (XZ) para UV normalizado do mapa da ilha
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 uv = (world_pos.xz - island_origin) / max(island_size, vec2(0.001));

	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		discard;
	}

	// Amostra do campo com filtro bilinear contínuo
	vec4 d_sample = texture(density_tex, uv);
	// Bordas perfeitamente curvas e suaves via smoothstep
	float shape_alpha = smoothstep(0.18, 0.55, d_sample.a);

	if (shape_alpha <= 0.01) {
		discard;
	}

	// Amostra da trilha de corte (máscara onde a serra passou)
	float cut_trail = texture(cut_tex, uv).r;

	// Cor baseada no tipo vegetal amostrado misturada com tom de gramado
	vec3 base_col = mix(lawn_color.rgb, d_sample.rgb * 0.75, 0.45);
	// Onde foi cortado, ganha o tom mais claro de gramado aparado
	vec3 final_rgb = mix(base_col, mowed_color.rgb, cut_trail * 0.70);
	float final_alpha = shape_alpha * mix(lawn_color.a, mowed_color.a, cut_trail);

	ALBEDO = final_rgb;
	ALPHA = final_alpha;
}
