/**
 * Toon Water Shader Oficial Otimizado para Mobile (Godot 4 Spatial)
 * Desacoplado de depth_texture (elimina Depth Prepass e quebra de TBDR em mobile).
 * Cristas de ondas cel-shaded via ruído com scroll e distorção UV.
 * Espuma de costa gerada geometricamente pela malha CoastalFoamRibbon.
 */
shader_type spatial;
render_mode cull_back, diffuse_toon, specular_disabled;

const float SMOOTHSTEP_AA = 0.01;

uniform sampler2D surfaceNoise : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D distortNoise : source_color, filter_linear_mipmap, repeat_enable;

uniform vec4 foam_color : source_color = vec4(0.88, 0.98, 1.0, 1.0);

uniform bool use_world_coords = true;
uniform float world_scale : hint_range(0.01, 10.0) = 0.28;
uniform vec2 surface_noise_tiling = vec2(1.0, 4.0);
uniform vec3 surface_noise_scroll = vec3(0.04, 0.04, 0.0);
uniform float surface_noise_cutoff : hint_range(0.0, 1.0) = 0.52;
uniform float surface_distortion_amount : hint_range(0.0, 1.0) = 0.34;

uniform vec4 _DepthGradientShallow : source_color = vec4(0.18, 0.65, 0.82, 1.0);
uniform vec4 _DepthGradientDeep : source_color = vec4(0.084, 0.52, 0.743, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.48;

varying vec2 noiseUV;
varying vec2 distortUV;
varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	noiseUV = use_world_coords ? (v_world_pos.xz * world_scale) : (UV * surface_noise_tiling);
	distortUV = use_world_coords ? (v_world_pos.xz * world_scale * 0.5) : UV;
}

void fragment() {
	// 1. Amostra de ruído de distorção para mar agitado suave
	vec4 distortNoiseSample = texture(distortNoise, distortUV);
	vec2 distortAmount = (distortNoiseSample.xy * 2.0 - 1.0) * surface_distortion_amount;

	// 2. Amostra de cristas de ondas de superfície com deslocamento temporal
	vec2 noise_uv = vec2(
		(noiseUV.x + TIME * surface_noise_scroll.x) + distortAmount.x,
		(noiseUV.y + TIME * surface_noise_scroll.y + distortAmount.y)
	);
	float surfaceNoiseSample = texture(surfaceNoise, noise_uv).r;
	float surfaceNoiseAmount = smoothstep(surface_noise_cutoff - SMOOTHSTEP_AA, surface_noise_cutoff + SMOOTHSTEP_AA, surfaceNoiseSample);

	// 3. Cor da água: gradiente tropical suave modulado pelas ondulações de superfície
	vec4 waterColor = mix(_DepthGradientShallow, _DepthGradientDeep, surfaceNoiseSample * 0.45);

	// 4. Cristas de espuma branca em mar aberto
	vec4 final_color = mix(waterColor, foam_color, surfaceNoiseAmount * foam_color.a);

	ALBEDO = final_color.rgb;
	ROUGHNESS = roughness;
}
