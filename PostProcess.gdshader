#pragma disable_preprocessor

shader_type canvas_item;

uniform float color_depth: hint_range(0, 32, 8) = 24;
uniform sampler2D dithering_pattern_texture: hint_default_white, repeat_enable, filter_nearest;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

const float noiseQuality = 250.0;
const float noiseIntensity = 0.001;
const float grainIntensity = 0.04;

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	vec3 base_color = texture(screen_texture, uv).rgb;
	vec2 dpt_size = vec2(textureSize(dithering_pattern_texture, 0));
	vec2 texture_size = vec2(textureSize(screen_texture, 0));
	vec3 dithering = texture(dithering_pattern_texture, UV * (texture_size / dpt_size)).rgb - 0.5;
	COLOR.rgb = round(base_color * color_depth + dithering) / color_depth;
	
	// Add noise distortion
    float uvY = uv.y * noiseQuality;
    uvY = float(int(uvY)) * (1.0 / noiseQuality);
    float noise = rand(vec2(TIME * 0.00001, uvY));
    uv.x += noise * noiseIntensity;
	
	// Add film grain
    float grain = rand(uv) * 2.0 - 1.0; // Range from -1 to 1
    COLOR.rgb += grainIntensity * grain;
}
