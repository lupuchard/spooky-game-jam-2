
shader_type canvas_item;

const float wind_speed_x = 0.001;
const float wind_speed_y = 0.0005;
const float wind_period1 = 2.0;
const float wind_strength1 = 0.1;
const float wind_period2 = 3.1;
const float wind_strength2 = 0.2;
const float wind_period3 = 0.72;
const float wind_strength3 = 0.02;

const float SIGHT_RANGE = 75.0;

uniform vec2 cursor_pos;
uniform float searching_factor;

void vertex() {
	UV = UV / 2.0 + INSTANCE_CUSTOM.yz;
	vec2 screen_pos = (CANVAS_MATRIX * MODEL_MATRIX * vec4(0, 0, 0, 1.0)).xy;

	float offset = TIME + screen_pos.x * wind_speed_x + screen_pos.y * wind_speed_y;
	float wind_skew = (
		sin(TIME / wind_period1) * wind_strength1
		+ sin(TIME / wind_period2) * wind_strength2
		+ sin(offset / wind_period3) * wind_strength3
	);
	
	vec2 disp = cursor_pos.xy - screen_pos.xy;
	float cursor_skew = 1.4 * max(1.0 - length(disp * vec2(1, 2)) / SIGHT_RANGE, 0.0);
	if (cursor_pos.x > screen_pos.x) {
		cursor_skew = -cursor_skew;
	}
	if (abs(disp.x) < (SIGHT_RANGE * 0.1)) {
		cursor_skew *= (abs(disp.x)) / (SIGHT_RANGE * 0.1);
	}
	
	float skew = wind_skew + cursor_skew * (searching_factor + 0.2);
	if (INSTANCE_CUSTOM.x < 0.0) {
		skew = skew * -1.0;
	}
	VERTEX.x += skew * (1.0 - UV.y);
}

void fragment() {
	vec2 disp = cursor_pos.xy - VERTEX.xy;
	float transparency = min(length(disp) / SIGHT_RANGE + (1.0 - searching_factor), 1.0);
	COLOR.a *= transparency * transparency;
}
