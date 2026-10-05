extends Sprite2D

@onready var sound1: AudioStreamPlayer = $JumpscareSound1
@onready var sound2: AudioStreamPlayer = $JumpscareSound2
var tween: Tween

func _ready():
	hide()

func scare():
	show()
	sound1.play()
	sound2.play()
	
	if tween != null:
		tween.kill()
	tween = create_tween()
	scale = Vector2(1.0, 1.1)
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.1, 1.0), 0.05)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.05)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.3)
	tween.finished.connect(hide)
