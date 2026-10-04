class_name Exit
extends Area2D

signal exited

@export var entrance: Entrance

@onready var arrow := $Arrow
var hovering := false
var tween: Tween

func _enter_tree():
	add_to_group("exit")

func _ready():
	mouse_entered.connect(on_mouse_entered)
	mouse_exited.connect(on_mouse_exited)
	modulate = Color.LIGHT_GRAY

func on_mouse_entered():
	if hovering: return
	tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT).tween_property(arrow, "position", Vector2(-8, 0), 0.5)
	tween.set_ease(Tween.EASE_IN).tween_property(arrow, "position", Vector2.ZERO, 0.5)
	tween.set_loops()
	
	arrow.modulate = Color.WHITE
	hovering = true

func on_mouse_exited():
	if !hovering: return
	tween.kill()
	arrow.modulate = Color.LIGHT_GRAY
	arrow.position = Vector2.ZERO
	hovering = false

func enable():
	show()
	process_mode = Node.PROCESS_MODE_INHERIT
		
func disable():
	hide()
	process_mode = Node.PROCESS_MODE_DISABLED

func _input(event: InputEvent):
	if (
		hovering and event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	):
		get_viewport().set_input_as_handled()
		exited.emit()
