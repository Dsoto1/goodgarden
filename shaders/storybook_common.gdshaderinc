// Shared "storybook" lighting for every surface in the world: a soft two-tone
// terminator, cool-tinted shade, and a faint rim light for clear silhouettes.
// Imported KayKit/Quaternius art and procedural pieces all use it, which is
// what makes them read as one world. Per-pack colour grading (saturation and
// tint) pulls each source's palette toward the shared one.

uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool use_texture = false;
uniform bool use_vertex_color = false;
uniform vec3 tint = vec3(1.0);
uniform float saturation = 1.0;
// 0 = crisp terminator (buildings); ~0.6 = light wraps around (foliage, cloth).
uniform float wrap = 0.0;
uniform float rim_strength = 0.12;
uniform vec3 emission_color : source_color = vec3(0.0);

global uniform vec3 gg_shadow_tint;
// Godot hands custom light() functions LIGHT_COLOR with a factor of PI folded
// in; gg_light_scale (1/PI) brings it back to the energy set on the light.
global uniform float gg_light_scale;

// See-through: the camera rig sets where the camera is (gg_view_from) and
// what it is framing (gg_view_to: the child, or the people talking). Anything
// standing close to the line between them, nearer the camera and above knee
// height, is cleared in a round hole with a soft stippled rim, so a
// washing line, tree or wall never hides the child. gg_see_through is 0 when
// the map renders the valley from above.
global uniform vec3 gg_view_from;
global uniform vec3 gg_view_to;
global uniform float gg_see_through;

bool see_through_cut(vec3 p, vec2 frag) {
	if (gg_see_through <= 0.0) {
		return false;
	}
	vec3 ab = gg_view_to - gg_view_from;
	float len2 = dot(ab, ab);
	if (len2 < 0.01) {
		return false;
	}
	float t = dot(p - gg_view_from, ab) / len2;
	// Never right in front of the lens, and never the child or what is beside them.
	if (t < 0.05 || t > 0.9 || p.y < gg_view_to.y - 1.1) {
		return false;
	}
	float d = distance(p, gg_view_from + ab * t);
	float radius = 1.25;
	if (d > radius) {
		return false;
	}
	// Clear in the middle, an even stipple (4x4 ordered dither) at the rim.
	float fade = smoothstep(radius, radius * 0.7, d) * gg_see_through;
	ivec2 q = ivec2(frag) % 4;
	int i = q.x + q.y * 4;
	float bayer[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return (bayer[i] + 0.5) / 16.0 < fade;
}

// Snow: in the winter weeks (gg_snow, 0 to 1, from the day) snow lies on
// every upward-facing surface out of doors: roofs, wall tops, tree crowns.
// Characters and animals opt out (snow_cover 0), and nothing indoors gets
// any: the four gg_snow_hole rects (x0, z0, x1, z1) are the interiors, below
// their ceilings.
uniform float snow_cover = 1.0;
global uniform float gg_snow;
global uniform vec4 gg_snow_hole_0;
global uniform vec4 gg_snow_hole_1;
global uniform vec4 gg_snow_hole_2;
global uniform vec4 gg_snow_hole_3;
const vec3 SNOW = vec3(0.84, 0.88, 0.95);

bool in_snow_hole(vec3 p, vec4 r) {
	return p.x > r.x && p.x < r.z && p.z > r.y && p.z < r.w && p.y < 3.2;
}

float snow_amount(vec3 p, vec3 world_normal) {
	if (gg_snow <= 0.0 || snow_cover <= 0.0) {
		return 0.0;
	}
	if (in_snow_hole(p, gg_snow_hole_0) || in_snow_hole(p, gg_snow_hole_1) || in_snow_hole(p, gg_snow_hole_2) || in_snow_hole(p, gg_snow_hole_3)) {
		return 0.0;
	}
	// A frost (low gg_snow) only whitens the flattest tops; deep snow covers more.
	float lie = smoothstep(mix(0.92, 0.45, gg_snow), mix(0.98, 0.75, gg_snow), world_normal.y);
	return lie * min(1.0, gg_snow * 1.15) * snow_cover;
}

vec3 grade(vec3 c) {
	float luma = dot(c, vec3(0.299, 0.587, 0.114));
	return mix(vec3(luma), c, saturation) * tint;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float diffuse = clamp((ndl + wrap) / (1.0 + wrap), 0.0, 1.0);
	float lit = smoothstep(0.02, 0.32, diffuse) * ATTENUATION;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0) * rim_strength * lit;
	DIFFUSE_LIGHT += LIGHT_COLOR * (lit + rim) * gg_light_scale;
	if (LIGHT_IS_DIRECTIONAL) {
		// Shade is never black: a cool sky fill, like watercolour shadows.
		DIFFUSE_LIGHT += LIGHT_COLOR * gg_shadow_tint * (1.0 - lit) * 0.22 * gg_light_scale;
	}
}
