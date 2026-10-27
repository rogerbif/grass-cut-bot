shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

// Shader de Slash Procedural Ultra-Leve (Opção A)
// 100% Analítico e Vetorial na GPU - Zero Texturas PNG para 60 FPS Mobile

uniform vec4 slash_color : source_color = vec4(1.0, 0.96, 0.70, 1.0);
uniform float slash_intensity : hint_range(0.0, 3.0) = 1.0;
uniform float inner_radius : hint_range(0.0, 1.0) = 0.55;
uniform float outer_radius : hint_range(0.0, 1.0) = 0.98;
uniform float edge_softness : hint_range(0.01, 0.5) = 0.08;
uniform float arc_length : hint_range(0.5, 6.28) = 3.6; // ~200 graus de arco de rastro

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float r = length(uv);

	// Anel radial delimitando a espessura da lâmina
	float ring = smoothstep(inner_radius, inner_radius + edge_softness, r) *
	             smoothstep(outer_radius, outer_radius - edge_softness, r);

	// Ângulo polar contínuo de 0 a 2*PI
	float angle = atan(uv.y, uv.x);
	float norm_angle = mod(angle + 3.14159265, 6.2831853);

	// Cauda angular em fade: ponta intensa e cauda com atenuação suave
	float arc_mask = smoothstep(0.0, arc_length * 0.15, norm_angle) *
	                 smoothstep(arc_length + 0.05, arc_length, norm_angle);
	float tail_fade = pow(clamp(norm_angle / max(arc_length, 0.001), 0.0, 1.0), 1.8);

	float final_alpha = ring * arc_mask * tail_fade * slash_intensity;

	ALBEDO = slash_color.rgb;
	ALPHA = clamp(final_alpha * slash_color.a, 0.0, 1.0);
}
