shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

// Shader de Onda de Choque (Shockwave Ring)
// Anel circular procedural com renderização aditiva e antialiasing analítico

uniform vec4 shock_color : source_color = vec4(1.0, 0.92, 0.45, 1.0);
uniform float inner_radius : hint_range(0.0, 1.0) = 0.72;
uniform float outer_radius : hint_range(0.0, 1.0) = 0.96;
uniform float edge_softness : hint_range(0.01, 0.3) = 0.06;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float r = length(uv);

	float ring = smoothstep(inner_radius - edge_softness, inner_radius + edge_softness, r) *
	             smoothstep(outer_radius + edge_softness, outer_radius - edge_softness, r);

	ALBEDO = shock_color.rgb;
	ALPHA = clamp(ring * alpha * shock_color.a, 0.0, 1.0);
}
