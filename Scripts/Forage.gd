class_name Forage
extends Node2D

signal rabbit_entered
signal rabbit_exited

@export var restore_health: float = 0.0
@export var reduce_hunger: float = 0.0
@export var initial_spawn_time_minutes: float = 0.0
@export var respawn_time_minutes: float = 1.0
@export var base_sprite: Texture2D
@export var glow_sprite: Texture2D

@onready var instance: Area2D = $Instance
@onready var sprite: Sprite2D = $Instance/Sprite
@onready var spawn_area: Area2D = $Spawn

var available := false
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
	if !available:
		respawn_time_left -= minutes
		if respawn_time_left < 0.0:
			spawn()

func spawn():
	var spawn_position = Util.random_position_in_area(spawn_area)
	instance.global_position = spawn_position
	instance.show()
	available = true
	show()

func remove():
	hide()
	position = Vector2(1000, 1000)
	respawn_time_left = randf_range(0.0, respawn_time_minutes)
	available = false

func on_enter(area: Area2D):
	if area is RabbitSprite:
		rabbit_entered.emit()

func on_exit(area: Area2D):
	if area is RabbitSprite:
		rabbit_exited.emit()

func set_glow(glow: bool):
	sprite.texture = glow_sprite if glow else base_sprite
