extends Area2D

signal gottem

@export var target: RabbitSprite
@onready var sprite = $Sprite
@onready var path_follower: PathFollow2D

var predator: PredatorInfo
var path: Path2D
var exiting_burrow := false

func _ready():
	area_entered.connect(on_area_entered)
	
	path_follower = PathFollow2D.new()
	path_follower.loop = false
	add_child(path_follower)
	remove()

func set_predator(new_predator: PredatorInfo):
	predator = new_predator
	path = null
	exiting_burrow = false
	sprite.texture = predator.sprite

func _process(delta: float):
	if predator == null: return
	var distance = delta * predator.movement_speed
	if exiting_burrow: distance /= 1.5
	
	if path == null:
		global_position = global_position.move_toward(target.global_position, distance)
		sprite.flip_h = global_position.x < target.global_position.x
	elif !exiting_burrow:
		path_follower.progress += distance
		global_position = path_follower.global_position
		if path_follower.progress_ratio >= 1.0:
			gottem.emit()
	else:
		path_follower.progress -= distance
		global_position = path_follower.global_position
		if path_follower.progress_ratio <= 0.0:
			path = null

func remove():
	position = Vector2(10000, 10000)
	exiting_burrow = false
	path = null
	predator = null

func follow_into_burrow(exit: Exit):
	path = exit.path
	path_follower.reparent(path)
	path_follower.progress = 0.0

func follow_out_of_burrow(exit: Exit):
	path = exit.path
	path_follower.reparent(path)
	path_follower.progress_ratio = 1.0
	exiting_burrow = true

func on_area_entered(area: Area2D):
	if area == target:
		gottem.emit()
