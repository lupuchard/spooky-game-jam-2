shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;
uniform float pixel_resolution : hint_range(0.0001, 1.0) = 1.0;
uniform int color_steps : hint_range(2, 64) = 16;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.1;
uniform bool enable_dither = true;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.3;

uniform bool enable_vintage = true;  // 🔥 Toggle
uniform float vintage_strength : hint_range(0.0, 2.0) = 0.8;

float random(vec2 co) {
	return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float bayer_dither(vec2 pos) {
	int x = int(mod(pos.x, 4.0));
	int y = int(mod(pos.y, 4.0));
	int index = x + y * 4;

	float bayer[16] = float[](
		0.0, 8.0, 2.0, 10.0,
		12.0, 4.0, 14.0, 6.0,
		3.0, 11.0, 1.0, 9.0,
		15.0, 7.0, 13.0, 5.0
	);

	return bayer[index] / 16.0;
}

vec3 apply_black_vintage_edges(vec3 color, vec2 uv) {
	// Distance from screen center
	float dist = distance(uv, vec2(0.5));

	// Mask: only affects edges
	float edge_mask = smoothstep(0.4, 0.8, dist);

	// Blend edges to black
	color = mix(color, vec3(0.0), edge_mask * vintage_strength);

	return color;
}

void fragment() {
	vec3 color = texture(screen_texture, UV).rgb;
	float steps = float(color_steps);
	color = floor(color * steps + 0.5) / steps;
	

	float noise = (random(UV + TIME) - 0.5) * noise_strength;
	color += noise;

	if (enable_dither) {
		float threshold = bayer_dither(FRAGCOORD.xy);
		color += (dither_strength * (threshold - 0.5));
	}

	// ✅ Black vintage only on edges
	if (enable_vintage) {
		color = apply_black_vintage_edges(color, UV);
	}

	COLOR.rgb = clamp(color, 0.0, 1.0);
}
