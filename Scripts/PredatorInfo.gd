class_name PredatorInfo
extends Node

enum Type {
	Beast,
	Bird,
	Weasel
}

func _enter_tree():
	add_to_group("predator_info")

@export var type: Type = Type.Beast
@export var min_day: float = 0.0
@export var max_day: float = 100.0
@export var spawn_weight: float = 1.0

@export var warning_time: float = 1.0
@export var movement_speed: float = 300.0
@export var damage: float = 1.0
@export var sprite: Texture2D
@export var entry_text: String
@export var exit_text: String
