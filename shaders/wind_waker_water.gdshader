// Wind Waker Toon Water Shader (No textures needed)
// Estilo The Legend of Zelda: The Wind Waker adaptado para Grass Cut Bot
shader_type spatial;
render_mode cull_back, diffuse_toon, specular_disabled;

uniform vec4 water_color : source_color = vec4(0.18, 0.65, 0.82, 1.0);
uniform vec4 deep_color : source_color = vec4(0.12, 0.48, 0.68, 1.0);
uniform vec4 foam_color : source_color = vec4(0.85, 0.98, 1.0, 1.0);

uniform float uv_scale : hint_range(0.01, 1.0) = 0.12;
uniform float wave_speed : hint_range(0.0, 5.0) = 0.8;
uniform float distortion_speed : hint_range(0.0, 5.0) = 0.5;
uniform float distortion_strength : hint_range(0.0, 1.0) = 0.08;
uniform float foam_threshold : hint_range(0.0, 1.0) = 0.62;
uniform float roughness : hint_range(0.0, 1.0) = 0.90;

varying vec3 v_world_pos;

float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 uv) {
	vec2 uv_index = floor(uv);
	vec2 uv_fract = fract(uv);

	float a = random(uv_index);
	float b = random(uv_index + vec2(1.0, 0.0));
	float c = random(uv_index + vec2(0.0, 1.0));
	float d = random(uv_index + vec2(1.0, 1.0));

	vec2 blur = smoothstep(0.0, 1.0, uv_fract);

	return mix(a, b, blur.x) + (c - a) * blur.y * (1.0 - blur.x) + (d - b) * blur.x * blur.y;
}

float fbm(vec2 uv) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 2.0;
	for (int i = 0; i < 3; i++) {
		value += amplitude * noise(uv * frequency);
		amplitude *= 0.5;
		frequency *= 2.0;
	}
	return value;
}

float circ(vec2 pos, vec2 c, float s) {
	c = abs(pos - c);
	c = min(c, 1.0 - c);
	return smoothstep(0.0, 0.002, sqrt(s) - sqrt(dot(c, c))) * -1.0;
}

float waterlayer(vec2 uv) {
	uv = mod(uv, 1.0);
	float ret = 1.0;
	ret += circ(uv, vec2(0.37378, 0.277169), 0.0268181);
	ret += circ(uv, vec2(0.0317477, 0.548483), 0.0118816);
	ret += circ(uv, vec2(0.817454, 0.73059), 0.0201502);
	ret += circ(uv, vec2(0.187425, 0.0772719), 0.0132338);
	ret += circ(uv, vec2(0.485121, 0.771966), 0.0163351);
	ret += circ(uv, vec2(0.793834, 0.210344), 0.0152417);
	ret += circ(uv, vec2(0.150654, 0.772583), 0.019794);
	ret += circ(uv, vec2(0.667239, 0.518602), 0.016333);
	ret += circ(uv, vec2(0.449767, 0.0768705), 0.0125868);
	return ret;
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = v_world_pos.xz * uv_scale;
	float t = TIME * wave_speed;

	vec2 distort = vec2(fbm(uv + t * 0.08), fbm(uv - t * 0.08));
	vec2 distorted_uv = uv + distort * distortion_strength * distortion_speed;

	float layer1 = waterlayer(distorted_uv + t * 0.04);
	float layer2 = waterlayer(distorted_uv * 1.4 - t * 0.06);

	float pattern = clamp(layer1 + layer2, 0.0, 1.0);

	vec4 col = mix(water_color, deep_color, pattern);
	float foam = step(foam_threshold, pattern);
	col = mix(col, foam_color, foam);

	ALBEDO = col.rgb;
	ROUGHNESS = roughness;
}
