// The whole landscape: soft patches of two greens with warm sunlit meadows on
// the valley floor, darker forest-floor greens on the hills, rock on steep
// slopes and snow on the high peaks.
shader_type spatial;
render_mode specular_disabled;

#include "res://shaders/storybook_common.gdshaderinc"

uniform vec3 grass_light : source_color = vec3(0.38, 0.62, 0.22);
uniform vec3 grass_deep : source_color = vec3(0.21, 0.44, 0.17);
uniform vec3 grass_warm : source_color = vec3(0.6, 0.66, 0.24);
uniform vec3 forest_floor : source_color = vec3(0.16, 0.33, 0.14);
uniform vec3 rock : source_color = vec3(0.42, 0.44, 0.48);
uniform vec3 snow : source_color = vec3(0.95, 0.96, 1.0);
uniform vec3 sand : source_color = vec3(0.86, 0.77, 0.55);
uniform vec3 dirt : source_color = vec3(0.72, 0.58, 0.38);
// Roads out of the valley, as segments (a.xy, b.xy) in world x/z.
uniform vec4 roads[32];
uniform int road_count = 0;

varying vec3 world_pos;
varying vec3 world_normal;

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
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 p = world_pos.xz;
	float n = noise(p * 0.07) * 0.65 + noise(p * 0.21) * 0.35;
	vec3 c = mix(grass_light, grass_deep, smoothstep(0.38, 0.72, n));
	c = mix(c, grass_warm, smoothstep(0.62, 0.9, noise(p * 0.035 + 17.0)) * 0.55);
	c *= 0.94 + 0.06 * noise(p * 1.7);
	float h = world_pos.y;
	c = mix(c, forest_floor, smoothstep(2.0, 14.0, h) * 0.7);
	float steep = 1.0 - world_normal.y;
	c = mix(c, rock * (0.85 + 0.3 * noise(p * 0.3)), smoothstep(0.3, 0.6, steep) * smoothstep(3.0, 12.0, h) * (0.55 + 0.45 * noise(p * 0.09)));
	// Sandy shores where the land meets the sea and the lake.
	float shore = smoothstep(150.0, 172.0, p.x) + (1.0 - smoothstep(18.0, 24.0, distance(p, vec2(82.0, 46.0))));
	c = mix(c, sand * (0.92 + 0.12 * noise(p * 0.8)), clamp(shore, 0.0, 1.0) * smoothstep(1.6, 0.6, h));
	// Dirt roads, a little wavering, soft at the edges.
	float road = 1e6;
	for (int i = 0; i < road_count; i++) {
		vec2 a = roads[i].xy;
		vec2 b = roads[i].zw;
		vec2 ab = b - a;
		float t = clamp(dot(p - a, ab) / dot(ab, ab), 0.0, 1.0);
		road = min(road, distance(p, a + ab * t));
	}
	road += (noise(p * 0.25) - 0.5) * 1.2;
	c = mix(c, dirt * (0.9 + 0.15 * noise(p * 2.3)), 1.0 - smoothstep(1.0, 1.9, road));
	float snowline = 78.0 + 18.0 * noise(p * 0.02);
	c = mix(c, snow, smoothstep(snowline, snowline + 10.0, h) * smoothstep(0.75, 0.35, steep));
	ALBEDO = grade(c);
}
