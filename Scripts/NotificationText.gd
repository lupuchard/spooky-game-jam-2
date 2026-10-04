extends Label

var tween: Tween

func _ready():
	modulate = Color.TRANSPARENT

func show_text(new_text: String, duration: float):
	text = new_text
	if tween != null:
		tween.kill()
	modulate = Color.WHITE
	tween = create_tween()
	tween.tween_interval(duration)
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 2.0)

func hide_text():
	if tween != null:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 2.0)
