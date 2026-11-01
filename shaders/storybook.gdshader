// Opaque surfaces: buildings, furniture, props, characters, rocks.
// Procedural pieces add a painted surface pattern (shaders/patterns.gdshaderinc).
shader_type spatial;
render_mode specular_disabled, cull_back;

#include "res://shaders/storybook_common.gdshaderinc"
#include "res://shaders/patterns.gdshaderinc"

// 0 none, 1 wood, 2 stone, 3 shingles, 4 thatch, 5 plaster, 6 path, 7 soil, 8 cloth, 9 cobble, 10 awning stripes.
uniform int pattern = 0;
uniform float pattern_strength = 1.0;
// Grass and low plants (set by their grade): frosted all over on a frosty
// morning, rather than only on their flat tops.
uniform bool up_normals = false;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	if (see_through_cut(world_pos, FRAGCOORD.xy)) {
		discard;
	}
	vec4 c = albedo_color;
	if (use_texture) {
		c *= texture(albedo_texture, UV);
	}
	if (use_vertex_color) {
		c *= COLOR;
	}
	float detail = 1.0;
	if (pattern > 0) {
		detail = mix(1.0, pattern_value(pattern, world_pos, world_normal), pattern_strength);
	}
	ALBEDO = grade(c.rgb) * detail;
	if (pattern == 10) {
		// Market awning stripes: alternate the colour with cream.
		vec3 a = abs(world_normal);
		float across = a.x > a.z ? world_pos.z : world_pos.x;
		float stripe = step(0.5, fract(across / 0.5));
		ALBEDO = mix(grade(c.rgb), vec3(0.96, 0.93, 0.86), stripe);
	}
	if (up_normals && !snow_free(world_pos)) {
		ALBEDO = mix(ALBEDO, vec3(0.86, 0.91, 0.98), clamp(gg_snow * 2.2, 0.0, 0.9) * 0.8 * snow_cover);
	} else if (pattern != 6 && pattern != 7 && pattern != 9) {
		ALBEDO = mix(ALBEDO, SNOW, snow_amount(world_pos, world_normal));
	}
	EMISSION = emission_color;
}
