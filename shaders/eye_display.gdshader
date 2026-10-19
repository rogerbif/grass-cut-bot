shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D eye_atlas : filter_linear_mipmap;
uniform vec2 atlas_grid = vec2(2.0, 6.0);
uniform int expression_index : hint_range(0, 15) = 0;

uniform vec4 eye_color : source_color = vec4(0.17, 0.89, 1.0, 1.0);
uniform float emission_energy : hint_range(0.0, 5.0) = 1.85;

// Controle procedural de animação
uniform float blink : hint_range(0.0, 1.0) = 0.0;
uniform vec2 look_offset = vec2(0.0, 0.0);
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.0;

// Estética do display de LED
uniform vec4 background_color : source_color = vec4(0.015, 0.022, 0.035, 1.0);
uniform float scanline_density : hint_range(20.0, 400.0) = 160.0;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.25;

void fragment() {
	// 1. Aplica deslocamento do olhar (look_offset)
	vec2 uv = UV - look_offset;

	// 2. Aplica deformação do piscar (comprime suavemente no eixo Y em torno do centro 0.5)
	float scale_y = max(1.0 - blink * 0.98, 0.02);
	uv.y = (uv.y - 0.5) / scale_y + 0.5;

	// 3. Efeito de distorção de glitch quando ativado
	if (glitch_intensity > 0.0) {
		float jitter = (sin(uv.y * 80.0 + TIME * 30.0) * 0.04) * glitch_intensity;
		uv.x += jitter;
	}

	// 4. Mapeamento para a célula correta do Atlas
	int col = expression_index % int(atlas_grid.x);
	int row = expression_index / int(atlas_grid.x);

	vec4 tex = vec4(0.0);
	if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) {
		vec2 clamped_uv = clamp(uv, vec2(0.002), vec2(0.998));
		vec2 frame_uv = (clamped_uv + vec2(float(col), float(row))) / atlas_grid;
		tex = texture(eye_atlas, frame_uv);
	}

	// 5. Scanlines digitais do display
	float scanline = sin(UV.y * scanline_density * 3.14159) * 0.5 + 0.5;
	float scan_factor = 1.0 - (scanline * scanline_strength);

	// 6. Luminância e cor final
	float eye_mask = tex.a * max(tex.r, max(tex.g, tex.b));
	vec3 lit_eye = eye_color.rgb * emission_energy;
	vec3 screen_rgb = mix(background_color.rgb, lit_eye, eye_mask);
	screen_rgb *= scan_factor;

	// 7. Pulso de ruído elétrico durante glitch
	if (glitch_intensity > 0.0) {
		float noise = fract(sin(dot(UV + vec2(TIME * 15.0), vec2(12.9898, 78.233))) * 43758.5453);
		if (noise > 0.8) {
			screen_rgb += vec3(0.2, 0.02, 0.02);
		}
	}

	ALBEDO = screen_rgb;
}
