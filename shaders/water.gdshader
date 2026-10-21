// River water: calm colour with slow drifting light bands. Still under "Less motion".
shader_type spatial;
render_mode specular_disabled;

#include "res://shaders/storybook_common.gdshaderinc"

uniform vec3 deep : source_color = vec3(0.14, 0.36, 0.5);
uniform vec3 shallow : source_color = vec3(0.27, 0.53, 0.62);
global uniform float gg_wind;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float t = TIME * 0.35 * gg_wind;
	// Lighter water near the banks, deeper in the channel.
	float across = abs(fract((world_pos.z + 16.0) / 4.0) - 0.5) * 2.0;
	vec3 base = mix(deep, shallow, smoothstep(0.55, 1.0, across));
	// Slow ripple lines drifting downstream, broken up so they don't look ruled.
	float ripple = sin(world_pos.x * 3.4 - t * 3.0 + sin(world_pos.z * 4.1 + t) * 1.2);
	float breakup = smoothstep(0.2, 0.9, sin(world_pos.x * 0.53 + world_pos.z * 2.7 + t * 0.5) * 0.5 + 0.5);
	float lines = smoothstep(0.975, 0.998, ripple) * breakup;
	ALBEDO = grade(base + vec3(lines) * 0.1);
	EMISSION = vec3(lines) * 0.03;
}
