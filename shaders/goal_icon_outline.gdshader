shader_type canvas_item;
render_mode blend_mix;

// Shader de Contorno Externo Branco Puro para Ícones de Metas (Sticker Outline)
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 8.0) = 2.2;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	if (col.a > 0.08) {
		COLOR = col;
	} else {
		vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
		float max_a = 0.0;
		max_a = max(max_a, texture(TEXTURE, UV + vec2(0.0, -size.y)).a);
		max_a = max(max_a, texture(TEXTURE, UV + vec2(0.0, size.y)).a);
		max_a = max(max_a, texture(TEXTURE, UV + vec2(-size.x, 0.0)).a);
		max_a = max(max_a, texture(TEXTURE, UV + vec2(size.x, 0.0)).a);
		max_a = max(max_a, texture(TEXTURE, UV + vec2(-size.x, -size.y)).a);
		max_a = max(max_a, texture(TEXTURE, UV + vec2(size.x, -size.y)).a);
		max_a = max(max_a, texture(TEXTURE, UV + vec2(-size.x, size.y)).a);
		max_a = max(max_a, texture(TEXTURE, UV + vec2(size.x, size.y)).a);

		if (max_a > 0.08) {
			COLOR = vec4(outline_color.rgb, max_a * outline_color.a);
		} else {
			COLOR = vec4(0.0);
		}
	}
}
