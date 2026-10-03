extends Area2D

signal gottem

@export var target: RabbitSprite
@onready var sprite = $Sprite

var predator: PredatorInfo

func _ready():
	hide()
	area_entered.connect(on_area_entered)

func set_predator(new_predator: PredatorInfo):
	predator = new_predator
	sprite.texture = predator.sprite
	show()

func _process(delta: float):
	if predator == null: return
	global_position = global_position.move_toward(target.global_position, delta * predator.movement_speed)

func remove():
	hide()
	position = Vector2(10000, 10000)

func on_area_entered(area: Area2D):
	if area == target:
		gottem.emit()
