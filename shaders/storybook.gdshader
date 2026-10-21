// Opaque surfaces: buildings, furniture, props, characters, rocks.
// Procedural pieces add a painted surface pattern (shaders/patterns.gdshaderinc).
shader_type spatial;
render_mode specular_disabled, cull_back;

#include "res://shaders/storybook_common.gdshaderinc"
#include "res://shaders/patterns.gdshaderinc"

// 0 none, 1 wood, 2 stone, 3 shingles, 4 thatch, 5 plaster, 6 path, 7 soil, 8 cloth, 9 cobble, 10 awning stripes.
uniform int pattern = 0;
uniform float pattern_strength = 1.0;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
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
	EMISSION = emission_color;
}
