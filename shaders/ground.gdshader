// Valley ground: large soft patches of two greens with warm sunlit meadows,
// so the floor never reads as one flat colour.
shader_type spatial;
render_mode specular_disabled;

#include "res://shaders/storybook_common.gdshaderinc"

uniform vec3 grass_light : source_color = vec3(0.44, 0.65, 0.29);
uniform vec3 grass_deep : source_color = vec3(0.27, 0.48, 0.23);
uniform vec3 grass_warm : source_color = vec3(0.62, 0.68, 0.32);

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	float n = noise(p * 0.07) * 0.65 + noise(p * 0.21) * 0.35;
	vec3 c = mix(grass_light, grass_deep, smoothstep(0.38, 0.72, n));
	c = mix(c, grass_warm, smoothstep(0.62, 0.9, noise(p * 0.035 + 17.0)) * 0.55);
	c *= 0.94 + 0.06 * noise(p * 1.7);
	ALBEDO = grade(c);
}
