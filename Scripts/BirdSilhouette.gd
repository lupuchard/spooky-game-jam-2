extends Node2D

signal flyby_finished

const speed := 1000.0

@onready var hawk_sound := $HawkSound

var tween: Tween

func do_flyby(field: Field):
	var spawns = [field.bird_spawn1, field.bird_spawn2]
	if randi_range(0, 1) == 1: spawns.reverse()
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
