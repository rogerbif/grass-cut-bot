/**
 * Toon Water Shader Oficial (Godot 4 Spatial)
 * Baseado na clássica implementação de Erik Roystan Ross e Heverton Gouveia.
 * Adaptado para coordenadas de mundo XZ, atenuação física Beer-Lambert e espuma de costa.
 */
shader_type spatial;
render_mode cull_back, diffuse_toon, specular_disabled;

const float SMOOTHSTEP_AA = 0.01;

uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D surfaceNoise : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D distortNoise : source_color, filter_linear_mipmap, repeat_enable;

uniform float beer_factor : hint_range(0.0, 5.0) = 1.40;

uniform float foam_distance : hint_range(0.01, 2.0) = 0.10;
uniform float foam_max_distance : hint_range(0.01, 2.0) = 0.72;
uniform float foam_min_distance : hint_range(0.01, 2.0) = 0.04;
uniform vec4 foam_color : source_color = vec4(0.88, 0.98, 1.0, 1.0);

uniform bool use_world_coords = true;
uniform float world_scale : hint_range(0.01, 10.0) = 0.28;
uniform vec2 surface_noise_tiling = vec2(1.0, 4.0);
uniform vec3 surface_noise_scroll = vec3(0.04, 0.04, 0.0);
uniform float surface_noise_cutoff : hint_range(0.0, 1.0) = 0.52;
uniform float surface_distortion_amount : hint_range(0.0, 1.0) = 0.34;

uniform vec4 _DepthGradientShallow : source_color = vec4(0.18, 0.65, 0.82, 1.0);
uniform vec4 _DepthGradientDeep : source_color = vec4(0.084, 0.52, 0.743, 1.0);
uniform float _DepthMaxDistance : hint_range(0.1, 10.0) = 1.0;
uniform float _DepthFactor : hint_range(0.1, 5.0) = 1.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.48;

varying vec2 noiseUV;
varying vec2 distortUV;
varying vec3 viewNormal;
varying vec3 v_world_pos;

vec4 alphaBlend(vec4 top, vec4 bottom) {
	vec3 color = (top.rgb * top.a) + (bottom.rgb * (1.0 - top.a));
	float alpha = top.a + bottom.a * (1.0 - top.a);
	return vec4(color, alpha);
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	viewNormal = (MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	noiseUV = use_world_coords ? (v_world_pos.xz * world_scale) : (UV * surface_noise_tiling);
	distortUV = use_world_coords ? (v_world_pos.xz * world_scale * 0.5) : UV;
}

void fragment() {
	float depth_raw = texture(depth_texture, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_raw);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	float water_depth_diff = max(linear_depth + VERTEX.z, 0.0);

	float depth = exp(-water_depth_diff * beer_factor);
	depth = 1.0 - clamp(depth, 0.0, 1.0);

	vec3 existingNormal = vec3(dFdx(depth), dFdy(depth), 0.0);
	float normalDot = clamp(dot(existingNormal, viewNormal), 0.0, 1.0);
	float foamDistance = mix(foam_max_distance, foam_min_distance, normalDot);

	float foamDepth = clamp(depth / max(foamDistance, 0.0001), 0.0, 1.0);
	float surfaceNoiseCutoff = foamDepth * surface_noise_cutoff;

	vec4 distortNoiseSample = texture(distortNoise, distortUV);
	vec2 distortAmount = (distortNoiseSample.xy * 2.0 - 1.0) * surface_distortion_amount;

	vec2 noise_uv = vec2(
		(noiseUV.x + TIME * surface_noise_scroll.x) + distortAmount.x,
		(noiseUV.y + TIME * surface_noise_scroll.y + distortAmount.y)
	);
	float surfaceNoiseSample = texture(surfaceNoise, noise_uv).r;
	float surfaceNoiseAmount = smoothstep(surfaceNoiseCutoff - SMOOTHSTEP_AA, surfaceNoiseCutoff + SMOOTHSTEP_AA, surfaceNoiseSample);

	float waterDepth = clamp(depth / max(_DepthMaxDistance, 0.0001), 0.0, 1.0) * _DepthFactor;
	vec4 waterColor = mix(_DepthGradientShallow, _DepthGradientDeep, waterDepth);

	vec4 surfaceNoiseColor = foam_color;
	surfaceNoiseColor.a *= surfaceNoiseAmount;
	vec4 final_color = alphaBlend(surfaceNoiseColor, waterColor);

	ALBEDO = final_color.rgb;
	ROUGHNESS = roughness;
}
