class_name Entrance
extends Area2D

signal entered

@export var rabbit: RabbitSprite
@export var unlock_state := 0
var rabbit_here := false
var enabled := false

@onready var dirt: Sprite2D = $Dirt
@onready var arrow: Sprite2D = $Arrow
@onready var rock: Sprite2D = $Rock

var exit: Node2D
var dangerous := false

func _enter_tree():
	add_to_group("entrance")

func _ready():
	arrow.hide()
	var arrow_tween = create_tween()
	arrow_tween.set_trans(Tween.TRANS_QUAD)
	arrow_tween.set_ease(Tween.EASE_OUT).tween_property(arrow, "position", Vector2(8, 0), 0.5)
	arrow_tween.set_ease(Tween.EASE_IN).tween_property(arrow, "position", Vector2.ZERO, 0.5)
	arrow_tween.set_loops()
	
	area_entered.connect(on_entered)
	area_exited.connect(on_exited)
	
	disable()

func enable():
	dirt.show()
	rock.hide()
	enabled = true

func disable():
	dirt.hide()
	rock.show()
	enabled = false

func on_entered(area: Area2D):
	if enabled && area == rabbit && !dangerous:
		arrow.show()
		rabbit_here = true

func on_exited(area: Area2D):
	if area == rabbit:
		arrow.hide()
		rabbit_here = false

func _input(event: InputEvent):
	if (
		enabled && rabbit_here and event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	):
		entered.emit()

func set_dangerous(new_dangerous: bool):
	dangerous = new_dangerous
	arrow.modulate = Color.DARK_RED if dangerous else Color.WHITE
