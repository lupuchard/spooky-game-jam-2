extends Node2D

signal flyby_finished

const speed := 1000.0

@export var spawn1: Area2D
@export var spawn2: Area2D

@onready var hawk_sound := $HawkSound

var tween: Tween

func do_flyby():
	var spawns = [spawn1, spawn2] if randi_range(0, 1) == 1 else [spawn2, spawn1]
	var from = Util.random_position_in_area(spawns[0])
	var to = Util.random_position_in_area(spawns[1])
	global_position = from
	look_at(to)
	
	if tween != null:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "global_position", to, from.distance_to(to) / speed)
	tween.finished.connect(on_finish_flyby)
	
	hawk_sound.play()
	show()
	
func on_finish_flyby():
	flyby_finished.emit()
	hide()
