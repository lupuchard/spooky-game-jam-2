extends Label

var color_tween: Tween
var motion_tween: Tween
var starting_position: Vector2

func _ready():
	modulate = Color.TRANSPARENT
	starting_position = position

func show_text(new_text: String, duration: float):
	text = new_text
	
	if color_tween != null:
		color_tween.kill()
	modulate = Color.WHITE
	color_tween = create_tween()
	color_tween.tween_interval(duration)
	color_tween.tween_property(self, "modulate", Color.TRANSPARENT, 2.0)
	
	if motion_tween != null:
		motion_tween.kill()
	position = starting_position - Vector2(0.0, 20.0)
	motion_tween = create_tween()
	motion_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	motion_tween.tween_property(self, "position", starting_position, 0.5)
	

func hide_text():
	if color_tween != null:
		color_tween.kill()
	color_tween = create_tween()
	color_tween.tween_property(self, "modulate", Color.TRANSPARENT, 2.0)
