shader_type canvas_item;
render_mode blend_mix;

// Shader de Contorno Duplo (Sticker Double Outline):
// 1px borda externa preta + 2px borda externa branca adicional
uniform vec4 inner_outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0); // Borda preta (1px)
uniform vec4 outer_outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Borda branca (2px)
uniform float inner_width : hint_range(0.0, 8.0) = 1.2; // ~1px preto
uniform float outer_width : hint_range(0.0, 8.0) = 3.6; // ~1px preto + 2px branco = 3.6

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	// Preserva e aplica a modulação cromática (COLOR / modulate) do CanvasItem
	vec4 modulated_col = vec4(col.rgb * COLOR.rgb, col.a * COLOR.a);

	if (col.a > 0.12) {
		COLOR = modulated_col;
	} else {
		vec2 p = TEXTURE_PIXEL_SIZE;
		float max_inner_a = 0.0;

		// 1. Amostragem da borda interna (1px - preta)
		vec2 in_step = p * inner_width;
		max_inner_a = max(max_inner_a, texture(TEXTURE, UV + vec2(0.0, -in_step.y)).a);
		max_inner_a = max(max_inner_a, texture(TEXTURE, UV + vec2(0.0, in_step.y)).a);
		max_inner_a = max(max_inner_a, texture(TEXTURE, UV + vec2(-in_step.x, 0.0)).a);
		max_inner_a = max(max_inner_a, texture(TEXTURE, UV + vec2(in_step.x, 0.0)).a);
		max_inner_a = max(max_inner_a, texture(TEXTURE, UV + vec2(-in_step.x, -in_step.y) * 0.7071).a);
		max_inner_a = max(max_inner_a, texture(TEXTURE, UV + vec2(in_step.x, -in_step.y) * 0.7071).a);
		max_inner_a = max(max_inner_a, texture(TEXTURE, UV + vec2(-in_step.x, in_step.y) * 0.7071).a);
		max_inner_a = max(max_inner_a, texture(TEXTURE, UV + vec2(in_step.x, in_step.y) * 0.7071).a);

		// Passo intermediário a 50% de inner_width para garantir preenchimento sem falhas
		max_inner_a = max(max_inner_a, texture(TEXTURE, UV + vec2(0.0, -in_step.y * 0.5)).a);
		max_inner_a = max(max_inner_a, texture(TEXTURE, UV + vec2(0.0, in_step.y * 0.5)).a);
		max_inner_a = max(max_inner_a, texture(TEXTURE, UV + vec2(-in_step.x * 0.5, 0.0)).a);
		max_inner_a = max(max_inner_a, texture(TEXTURE, UV + vec2(in_step.x * 0.5, 0.0)).a);

		if (max_inner_a > 0.12) {
			COLOR = vec4(inner_outline_color.rgb, inner_outline_color.a * min(max_inner_a * 2.0, 1.0));
		} else {
			// 2. Amostragem da borda externa (2px além da preta = raio outer_width)
			float max_outer_a = 0.0;
			vec2 mid_step = p * ((inner_width + outer_width) * 0.5);
			vec2 out_step = p * outer_width;

			// Raio intermediário (8 direções)
			max_outer_a = max(max_outer_a, texture(TEXTURE, UV + vec2(0.0, -mid_step.y)).a);
			max_outer_a = max(max_outer_a, texture(TEXTURE, UV + vec2(0.0, mid_step.y)).a);
			max_outer_a = max(max_outer_a, texture(TEXTURE, UV + vec2(-mid_step.x, 0.0)).a);
			max_outer_a = max(max_outer_a, texture(TEXTURE, UV + vec2(mid_step.x, 0.0)).a);
			max_outer_a = max(max_outer_a, texture(TEXTURE, UV + vec2(-mid_step.x, -mid_step.y) * 0.7071).a);
			max_outer_a = max(max_outer_a, texture(TEXTURE, UV + vec2(mid_step.x, -mid_step.y) * 0.7071).a);
			max_outer_a = max(max_outer_a, texture(TEXTURE, UV + vec2(-mid_step.x, mid_step.y) * 0.7071).a);
			max_outer_a = max(max_outer_a, texture(TEXTURE, UV + vec2(mid_step.x, mid_step.y) * 0.7071).a);

			// Raio externo máximo (16 direções circulares uniformes)
			for (int i = 0; i < 16; i++) {
				float angle = float(i) * 0.39269908; // 2.0 * PI / 16.0
				vec2 dir = vec2(cos(angle), sin(angle));
				max_outer_a = max(max_outer_a, texture(TEXTURE, UV + dir * out_step).a);
			}

			if (max_outer_a > 0.12) {
				COLOR = vec4(outer_outline_color.rgb, outer_outline_color.a * min(max_outer_a * 2.0, 1.0));
			} else {
				COLOR = vec4(0.0);
			}
		}
	}
}
