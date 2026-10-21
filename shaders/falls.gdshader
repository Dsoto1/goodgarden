// Falling water: bright streaks racing down a blue-white sheet, frothier at
// the lip and the base. Still under "Less motion".
shader_type spatial;
render_mode specular_disabled, cull_disabled;

#include "res://shaders/storybook_common.gdshaderinc"
#include "res://shaders/patterns.gdshaderinc"

uniform vec3 water : source_color = vec3(0.45, 0.7, 0.85);
uniform vec3 foam : source_color = vec3(0.95, 0.98, 1.0);
global uniform float gg_wind;

void fragment() {
	float t = TIME * 1.6 * max(gg_wind, 0.0);
	float streaks = p_noise(vec2(UV.x * 26.0, UV.y * 2.5 - t)) * 0.7 + p_noise(vec2(UV.x * 61.0, UV.y * 5.0 - t * 1.4)) * 0.3;
	float froth = smoothstep(0.75, 1.0, UV.y) + smoothstep(0.12, 0.0, UV.y) * 0.8;
	float white = clamp(smoothstep(0.45, 0.8, streaks) + froth, 0.0, 1.0);
	ALBEDO = grade(mix(water, foam, white));
	EMISSION = foam * white * 0.12;
}
