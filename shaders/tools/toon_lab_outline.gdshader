shader_type spatial;
render_mode cull_front, unshaded;

uniform float outline_thickness : hint_range(0.0, 0.08) = 0.018;
uniform vec4 outline_color : source_color = vec4(0.08, 0.09, 0.12, 1.0);

void vertex() {
	// Expande os vértices ao longo da normal no espaço local
	VERTEX += NORMAL * outline_thickness;
}

void fragment() {
	ALBEDO = outline_color.rgb;
	ALPHA = outline_color.a;
}
