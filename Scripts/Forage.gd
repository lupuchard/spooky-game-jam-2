class_name Forage
extends Node2D

signal rabbit_entered
signal rabbit_exited

enum Type {
	Food,
	RitualPaper,
	RitualSacrifice,
	RitualTinder,
	RitualStone,
	Chest,
	ChestKey
}

@export var type: Type = Type.Food
@export var item_id: String
@export var base_sprite: Texture2D
@export var glow_sprite: Texture2D
@export var sound: AudioStreamPlayer2D

@onready var instance: Area2D = $Instance
@onready var sprite: Sprite2D = $Instance/Sprite
@onready var spawn_area: Area2D = get_node_or_null("Spawn")

var available := false
var acquired := false

func _enter_tree():
	add_to_group("forage")

func _ready():
	instance.area_entered.connect(on_enter)
	instance.area_exited.connect(on_exit)
	remove()

func pass_time(_minutes: float):
	pass

func spawn():
	if available:
		return
		
	if spawn_area != null:
		instance.global_position = Util.random_position_in_area(spawn_area)
	instance.show()
	available = true
	show()

func remove():
	instance.hide()
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
	}

func load_save_state(state: Dictionary):
	instance.global_position.x = state.x
	instance.global_position.y = state.y
	available = state.available
	acquired = state.acquired
	instance.visible = available

	
