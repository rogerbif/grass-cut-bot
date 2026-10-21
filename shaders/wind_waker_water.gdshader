// Wind Waker Toon Water Shader (Godot 4 Spatial Port)
// Baseado na versão 2D de zeludtnecniv (GodotShaders) adaptada para Spatial 3D
shader_type spatial;
render_mode cull_back, diffuse_toon, specular_disabled;

uniform vec4 water_color : source_color = vec4(0.18, 0.65, 0.82, 1.0);
uniform vec4 water2_color : source_color = vec4(0.08, 0.52, 0.75, 1.0);
uniform vec4 foam_color : source_color = vec4(0.88, 0.98, 1.0, 1.0);

uniform float uv_scale : hint_range(0.01, 2.0) = 0.22;
uniform float distortion_speed : hint_range(0.0, 5.0) = 1.2;
uniform float distortion_strength : hint_range(0.0, 0.5) = 0.10;
uniform float foam_intensity : hint_range(0.0, 1.0) = 0.40;
uniform float roughness : hint_range(0.0, 1.0) = 0.88;

const float TWOPI = 6.283185307;
const float SIXPI = 18.84955592;

varying vec3 v_world_pos;

float circ(vec2 pos, vec2 c, float s) {
	c = abs(pos - c);
	c = min(c, 1.0 - c);
	return smoothstep(0.0, 0.002, sqrt(s) - sqrt(dot(c, c))) * -1.0;
}

float waterlayer(vec2 uv) {
	uv = mod(uv, 1.0);
	float ret = 1.0;
	ret += circ(uv, vec2(0.37378, 0.277169), 0.0268181);
	ret += circ(uv, vec2(0.0317477, 0.540372), 0.0193742);
	ret += circ(uv, vec2(0.430044, 0.882218), 0.0232337);
	ret += circ(uv, vec2(0.641033, 0.695106), 0.0117864);
	ret += circ(uv, vec2(0.0146398, 0.0791346), 0.0299458);
	ret += circ(uv, vec2(0.43871, 0.394445), 0.0289087);
	ret += circ(uv, vec2(0.909446, 0.878141), 0.028466);
	ret += circ(uv, vec2(0.310149, 0.686637), 0.0128496);
	ret += circ(uv, vec2(0.928617, 0.195986), 0.0152041);
	ret += circ(uv, vec2(0.0438506, 0.868153), 0.0268601);
	ret += circ(uv, vec2(0.308619, 0.194937), 0.00806102);
	ret += circ(uv, vec2(0.349922, 0.449714), 0.00928667);
	ret += circ(uv, vec2(0.0449556, 0.953415), 0.023126);
	ret += circ(uv, vec2(0.117761, 0.503309), 0.015949);
	ret += circ(uv, vec2(0.318217, 0.912258), 0.0247672);
	ret += circ(uv, vec2(0.187332, 0.575647), 0.0107297);
	return clamp(ret, 0.0, 1.0);
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = v_world_pos.xz * uv_scale;

	float t = TIME * distortion_speed * 0.1;
	vec2 uv1 = uv + vec2(sin(t + uv.y * TWOPI), cos(t + uv.x * TWOPI)) * distortion_strength;
	vec2 uv2 = uv - vec2(cos(t - uv.y * SIXPI), sin(t - uv.x * SIXPI)) * distortion_strength;

	float layer1 = waterlayer(uv1);
	float layer2 = waterlayer(uv2);

	vec4 final_color = mix(water_color, water2_color, layer1);
	final_color = mix(final_color, foam_color, (1.0 - layer2) * foam_intensity);

	ALBEDO = final_color.rgb;
	ROUGHNESS = roughness;
}
