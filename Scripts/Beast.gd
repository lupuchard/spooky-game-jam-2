extends Area2D

@export var target: RabbitSprite

@onready var sprite = $Sprite

var predator: PredatorInfo

func _ready():
	hide()

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
