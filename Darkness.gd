extends ColorRect

var day_color = Color(0.5, 0.2, 0.0, 0.0)
var twilight_color = Color(0.5, 0.2, 0.0, 0.3)
var night_color = Color(0.1, 0.0, 0.2, 0.6)

func set_time_of_day(time_of_day: float):
	if time_of_day < 0.2:
		color = day_color
	elif time_of_day < 0.25:
		color = day_color.lerp(twilight_color, (time_of_day - 0.2) * 20)
	elif time_of_day < 0.3:
		color = twilight_color.lerp(night_color, (time_of_day - 0.25) * 20)
	elif time_of_day < 0.7:
		color = night_color
	elif time_of_day < 0.75:
		color = night_color.lerp(twilight_color, (time_of_day - 0.7) * 20)
	elif time_of_day < 0.8:
		color = twilight_color.lerp(day_color, (time_of_day - 0.75) * 20)
	else:
		color = day_color
