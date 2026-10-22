// Leaves, grass and flowers: alpha-cut cards, lit from both sides, swaying
// gently in the wind. gg_wind is 0 when the child chooses "Less motion".
shader_type spatial;
render_mode specular_disabled, cull_disabled, depth_draw_opaque;

#include "res://shaders/storybook_common.gdshaderinc"

uniform float sway = 0.0; // relative strength; 1.0 suits a tree canopy
uniform float alpha_cut = 0.5;
// Grass and small plants: light them like the ground they grow from (normals
// point up) and darken toward the root, so they melt into the ground colour.
uniform bool up_normals = false;
uniform float root_shade = 1.0;
global uniform float gg_wind;

varying float height_frac;
varying vec3 world_pos;

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_pos = world;
	// Sway grows with height above the plant's base, so trunks and roots stay put.
	float h = clamp((world.y - MODEL_MATRIX[3].y) / 4.0, 0.0, 1.0);
	height_frac = clamp((world.y - MODEL_MATRIX[3].y) / 0.45, 0.0, 1.0);
	float t = TIME * 1.2 + world.x * 0.35 + world.z * 0.27;
	vec3 push = vec3(sin(t) + 0.4 * sin(t * 2.3), 0.0, 0.6 * cos(t * 0.8)) * sway * gg_wind * h * h * 0.12;
	VERTEX += push / max(length(MODEL_MATRIX[0].xyz), 0.001);
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
	ALBEDO = grade(c.rgb) * mix(root_shade, 1.0, height_frac);
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut;
	if (up_normals) {
		NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	} else if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
}
