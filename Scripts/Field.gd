class_name Field
extends Node2D

func _enter_tree() -> void:
	add_to_group("field")

@onready var grass = $Grass
@onready var beast_spawn = $BeastSpawn
@onready var bird_spawn1 = $BirdSpawn1
@onready var bird_spawn2 = $BirdSpawn2
