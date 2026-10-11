class_name Chest
extends Forage

enum Trinket {
	Dreamcatcher,
	Shoes,
}

@export var key: Forage
@export var contents: Trinket
@export var locked_text: String
@export var when_spawn: float

@onready var contents_sprite := $ContentsSprite
var time_passed := 0.0

func _ready():
	super()
	contents_sprite.hide()

func pass_time(minutes: float):
	super(minutes)
	
	if available || acquired:
		return
	
	time_passed += minutes
	if time_passed >= when_spawn:
		spawn()
	
func get_save_state() -> Dictionary:
	var state = super()
	state.time_passed = time_passed
	return state

func load_save_state(state: Dictionary):
	super(state)
	time_passed = state.time_passed

func show_open():
	contents_sprite.show()
	contents_sprite.position = instance.position
	var tween = create_tween()
	tween.tween_property(contents_sprite, "position", instance.position - Vector2(0.0, 20.0), 1.0)
	tween.finished.connect(func():
		contents_sprite.hide()
	)
