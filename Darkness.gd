extends ColorRect

@export var rain: ColorRect
@export var rain_ambience: AudioStreamPlayer

var day_color := Color(0.5, 0.2, 0.0, 0.0)
var twilight_color := Color(0.5, 0.2, 0.0, 0.3)
var night_color := Color(0.1, 0.0, 0.2, 0.6)

var raining := 0.0
var when_next_rain: float
var when_rain_end: float = INF

var rain_shader: ShaderMaterial
var rain_tween: Tween

func _ready():
	when_next_rain = random_time_until_rain()
	rain_shader = rain.material
	rain.hide()

func set_time(time: float):
	var modified_day_color = day_color.lerp(night_color, raining / 2.0)
	var modified_twilight_color = twilight_color.lerp(night_color, raining / 2.0)
	
	var time_of_day = fmod(time, 1.0)
	if time_of_day < 0.2:
		color = modified_day_color
	elif time_of_day < 0.25:
		color = modified_day_color.lerp(modified_twilight_color, (time_of_day - 0.2) * 20)
	elif time_of_day < 0.3:
		color = modified_twilight_color.lerp(night_color, (time_of_day - 0.25) * 20)
	elif time_of_day < 0.7:
		color = night_color
	elif time_of_day < 0.75:
		color = night_color.lerp(modified_twilight_color, (time_of_day - 0.7) * 20)
	elif time_of_day < 0.8:
		color = modified_twilight_color.lerp(modified_day_color, (time_of_day - 0.75) * 20)
	else:
		color = modified_day_color
	
	if time >= when_next_rain:
		if rain_tween != null:
			rain_tween.kill()
		rain.show()
		rain_ambience.volume_linear = 0.0
		rain_ambience.play()
		rain_shader.set_shader_parameter("shader_parameter/count", 0)
		rain_tween = create_tween()
		rain_tween.tween_property(self, "raining", 1.0, 1.0)
		rain_tween.parallel().tween_property(rain_shader, "shader_parameter/count", 150, 1.0)
		rain_tween.parallel().tween_property(rain_ambience, "volume_linear", 1.0, 1.0)
		when_rain_end = time + random_rain_duration()
		when_next_rain = INF
	elif time >= when_rain_end:
		if rain_tween != null:
			rain_tween.kill()
		rain_tween = create_tween()
		rain_tween.tween_property(self, "raining", 0.0, 1.0)
		rain_tween.parallel().tween_property(rain_shader, "shader_parameter/count", 0, 1.0)
		rain_tween.parallel().tween_property(rain_ambience, "volume_linear", 1.0, 0.0)
		rain_tween.finished.connect(func():
			rain.hide()
			rain_ambience.stop()
		)
		when_rain_end = INF
		when_next_rain = random_time_until_rain()

func random_time_until_rain():
	return randf_range(0.5, 2.5)

func random_rain_duration():
	return randf_range(0.5, 1.0)
