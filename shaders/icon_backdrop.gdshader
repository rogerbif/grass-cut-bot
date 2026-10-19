shader_type spatial;
render_mode unshaded, cull_disabled;

// Shader de Fundo Gradiente e Halo Solar para Ícone de Jogo
uniform vec3 sun_color : source_color = vec3(0.70, 0.96, 1.0);
uniform vec3 sky_color : source_color = vec3(0.12, 0.62, 0.90);
uniform vec3 deep_blue : source_color = vec3(0.02, 0.28, 0.62);
uniform vec2 sun_center = vec2(0.50, 0.52);
uniform float sun_radius = 0.16;
uniform float sky_radius = 0.38;

void fragment() {
	float dist = distance(UV, sun_center);
	vec3 col = mix(sun_color, sky_color, smoothstep(0.0, sun_radius, dist));
	col = mix(col, deep_blue, smoothstep(sun_radius, sky_radius, dist));
	ALBEDO = col;
}
