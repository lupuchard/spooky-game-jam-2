class_name Forage
extends Node2D

signal rabbit_entered
signal rabbit_exited

enum Type {
	Food,
	RitualPaper,
	RitualSacrifice,
	RitualTinder,
	RitualStone
}

@export var restore_health: float = 0.0
@export var reduce_hunger: float = 0.0
@export var type: Type = Type.Food
@export var item_id: String

@export var initial_spawn_time_minutes: float = 0.0
@export var respawn_time_minutes: float = 1.0
@export var base_sprite: Texture2D
@export var glow_sprite: Texture2D
@export var sound: AudioStreamPlayer2D

@onready var instance: Area2D = $Instance
@onready var sprite: Sprite2D = $Instance/Sprite
@onready var spawn_area: Area2D = get_node_or_null("Spawn")

var available := false
var acquired := false
var respawn_time_left := 0.0

func _enter_tree():
	add_to_group("forage")

func _ready():
	instance.area_entered.connect(on_enter)
	instance.area_exited.connect(on_exit)
	respawn_time_left = initial_spawn_time_minutes
	
	if respawn_time_left == 0.0:
		spawn()
	else:
		remove()

func pass_time(minutes: float):
	if !available and respawn_time_left != -1.0:
		respawn_time_left -= minutes
		if respawn_time_left < 0.0:
			spawn()

func spawn():
	if spawn_area != null:
		instance.global_position = Util.random_position_in_area(spawn_area)
	instance.show()
	available = true
	show()

func remove():
	instance.hide()
	#position = Vector2(1000, 1000)
	if respawn_time_minutes != -1.0:
		respawn_time_left = randf_range(0.0, respawn_time_minutes)
	else:
		respawn_time_left = -1.0
	available = false

func on_enter(area: Area2D):
	if area is RabbitSprite and available:
		rabbit_entered.emit()

func on_exit(area: Area2D):
	if area is RabbitSprite:
		rabbit_exited.emit()

func set_glow(glow: bool):
	sprite.texture = glow_sprite if glow else base_sprite

func get_save_state() -> Dictionary:
	return {
		"id": item_id,
		"x": instance.global_position.x,
		"y": instance.global_position.y,
		"available": available,
		"acquired": acquired,
		"respawn_time_left": respawn_time_left
	}

func load_save_state(state: Dictionary):
	instance.global_position.x = state.x
	instance.global_position.y = state.y
	available = state.available
	acquired = state.acquired
	instance.visible = available
	respawn_time_left = state.respawn_time_left
	
