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
