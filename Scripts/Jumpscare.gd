extends Node2D

@onready var scare1: Sprite2D = $Jumpscare1
@onready var scare2: Sprite2D = $Jumpscare2
@onready var sound1: AudioStreamPlayer = $JumpscareSound1
@onready var sound2: AudioStreamPlayer = $JumpscareSound2
var tween: Tween

func _ready():
	scare1.hide()
	scare2.hide()

func survive_scare():
	sound1.play()
	animate_scare(scare2)

func death_scare():
	sound1.play()
	sound2.play()
	animate_scare(scare1)

func animate_scare(sprite: Sprite2D):
	if tween != null:
		tween.kill()
		scare1.hide()
		scare2.hide()
	sprite.show()
	tween = create_tween()
	scale = Vector2(1.0, 1.1)
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.1, 1.0), 0.05)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.05)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.3)
	tween.finished.connect(func(): sprite.hide())
