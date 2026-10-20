// Stylized, hand-painted-looking surface patterns computed in world space, so
// procedural pieces get texture and detail without photo textures (ART_DIRECTION:
// no noisy realism). Each returns a brightness multiplier around 1.0.

float p_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float p_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(p_hash(i), p_hash(i + vec2(1, 0)), u.x), mix(p_hash(i + vec2(0, 1)), p_hash(i + vec2(1, 1)), u.x), u.y);
}

// Picks 2D coordinates on the plane facing the surface (cheap triplanar).
// .xy = across/up on walls, ground plane on floors; z = 1 for floors/roof tops.
vec3 p_plane(vec3 wp, vec3 wn) {
	vec3 a = abs(wn);
	if (a.y > 0.7) {
		return vec3(wp.x, wp.z, 1.0);
	}
	return a.x > a.z ? vec3(wp.z, wp.y, 0.0) : vec3(wp.x, wp.y, 0.0);
}

float p_line(float v, float width) {
	float f = abs(fract(v) - 0.5);
	return smoothstep(0.5 - width, 0.5 - width * 0.4, f);
}

// Planks: boards ~22 cm wide with long grain and the odd darker board.
float pat_wood(vec3 wp, vec3 wn) {
	vec3 c = p_plane(wp, wn);
	vec2 uv = c.z > 0.5 ? c.xy : vec2(c.x, c.y);
	float board = floor(uv.y / 0.22);
	float seam = p_line(uv.y / 0.22, 0.06);
	float grain = p_noise(vec2(uv.x * 1.5, uv.y * 30.0 + board * 7.0));
	float tone = 0.9 + 0.14 * p_hash(vec2(board, 3.0));
	return tone * (0.92 + 0.12 * grain) * (1.0 - 0.32 * seam);
}

// Stone blocks with mortar and per-block colour variation.
float pat_stone(vec3 wp, vec3 wn) {
	vec3 c = p_plane(wp, wn);
	vec2 uv = c.xy / vec2(0.55, 0.3);
	float row = floor(uv.y);
	uv.x += mod(row, 2.0) * 0.5;
	vec2 cell = floor(uv);
	vec2 f = fract(uv);
	float edge = min(min(f.x, 1.0 - f.x) * 0.55, min(f.y, 1.0 - f.y));
	float mortar = 1.0 - smoothstep(0.02, 0.07, edge);
	float tone = 0.86 + 0.2 * p_hash(cell);
	return tone * (0.95 + 0.08 * p_noise(c.xy * 9.0)) * (1.0 - 0.38 * mortar);
}

// Roof shingles: overlapping rows with soft scalloped shadow at each lower edge.
float pat_shingles(vec3 wp, vec3 wn) {
	vec3 a = abs(wn);
	float across = a.x > a.z ? wp.z : wp.x;
	float rows = wp.y / 0.2;
	float row = floor(rows);
	float x = across / 0.3 + mod(row, 2.0) * 0.5;
	float col = floor(x);
	float fy = fract(rows);
	float scallop = 0.18 * (1.0 - pow(abs(fract(x) - 0.5) * 2.0, 2.0));
	float shade = smoothstep(0.0, 0.22 + scallop, fy);
	float tone = 0.88 + 0.16 * p_hash(vec2(col, row));
	return tone * mix(0.68, 1.0, shade);
}

// Thatch: dense straw streaks running down the slope, in bundled rows.
float pat_thatch(vec3 wp, vec3 wn) {
	vec3 a = abs(wn);
	float across = a.x > a.z ? wp.z : wp.x;
	float streak = p_noise(vec2(across * 22.0, wp.y * 2.0));
	float rows = smoothstep(0.0, 0.3, fract(wp.y / 0.35));
	return (0.82 + 0.26 * streak) * mix(0.8, 1.0, rows);
}

// Plaster: soft mottling, darker near the ground, a few bricks showing through.
float pat_plaster(vec3 wp, vec3 wn) {
	vec3 c = p_plane(wp, wn);
	float mottle = p_noise(c.xy * 1.6) * 0.6 + p_noise(c.xy * 6.0) * 0.4;
	float tone = 0.93 + 0.1 * mottle;
	vec2 uv = c.xy / vec2(0.24, 0.1);
	uv.x += mod(floor(uv.y), 2.0) * 0.5;
	vec2 cell = floor(uv);
	float patch = step(0.72, p_noise(c.xy * 0.9 + 4.0)) * step(0.4, p_hash(cell));
	vec2 f = fract(uv);
	float brick_edge = 1.0 - smoothstep(0.03, 0.1, min(min(f.x, 1.0 - f.x) * 0.4, min(f.y, 1.0 - f.y)));
	float brick = patch * (0.82 - 0.2 * brick_edge);
	float grime = mix(0.86, 1.0, smoothstep(0.0, 0.6, wp.y));
	return mix(tone, brick, patch * 0.85) * grime;
}

// Packed earth path: worn ruts, mottling, and scattered pebbles with shadows.
float pat_path(vec3 wp, vec3 wn) {
	vec2 p = wp.xz;
	float earth = 0.84 + 0.18 * p_noise(p * 1.8) + 0.08 * p_noise(p * 9.0);
	vec2 cell = floor(p * 4.0);
	vec2 f = fract(p * 4.0) - 0.5;
	vec2 jitter = vec2(p_hash(cell), p_hash(cell + 9.0)) - 0.5;
	vec2 d2 = f - jitter * 0.6;
	float d = length(d2);
	float has = step(0.5, p_hash(cell + 3.0));
	float pebble = (1.0 - smoothstep(0.09, 0.14, d)) * has;
	float shadow = (1.0 - smoothstep(0.1, 0.2, length(d2 - vec2(0.05, 0.05)))) * has * (1.0 - pebble);
	return earth * (1.0 + 0.22 * pebble) * (1.0 - 0.18 * shadow);
}

// Cobblestones: rounded stones with dark gaps and varied tones.
float pat_cobble(vec3 wp, vec3 wn) {
	vec2 p = wp.xz / 0.32;
	vec2 cell = floor(p);
	float best = 8.0;
	float second = 8.0;
	vec2 id = cell;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 c = cell + vec2(float(x), float(y));
			vec2 site = c + vec2(p_hash(c), p_hash(c + 5.0)) * 0.8 + 0.1;
			float d = length(p - site);
			if (d < best) {
				second = best;
				best = d;
				id = c;
			} else if (d < second) {
				second = d;
			}
		}
	}
	float gap = 1.0 - smoothstep(0.04, 0.12, second - best);
	float tone = 0.84 + 0.22 * p_hash(id + 2.0);
	float dome = 1.0 - 0.18 * smoothstep(0.2, 0.6, best);
	return tone * dome * (1.0 - 0.5 * gap);
}

// Garden soil: crumbly clods and dark specks.
float pat_soil(vec3 wp, vec3 wn) {
	vec2 p = wp.xz + wp.y;
	float clods = p_noise(p * 7.0);
	float specks = step(0.86, p_hash(floor(p * 28.0)));
	return (0.84 + 0.24 * clods) * (1.0 - 0.25 * specks);
}

// Cloth: a soft weave.
float pat_cloth(vec3 wp, vec3 wn) {
	vec3 c = p_plane(wp, wn);
	float weave = sin(c.x * 140.0) * sin(c.y * 140.0);
	return 0.97 + 0.04 * weave + 0.05 * p_noise(c.xy * 4.0);
}

float pattern_value(int pattern, vec3 wp, vec3 wn) {
	if (pattern == 1) return pat_wood(wp, wn);
	if (pattern == 2) return pat_stone(wp, wn);
	if (pattern == 3) return pat_shingles(wp, wn);
	if (pattern == 4) return pat_thatch(wp, wn);
	if (pattern == 5) return pat_plaster(wp, wn);
	if (pattern == 6) return pat_path(wp, wn);
	if (pattern == 7) return pat_soil(wp, wn);
	if (pattern == 8) return pat_cloth(wp, wn);
	if (pattern == 9) return pat_cobble(wp, wn);
	return 1.0;
}
