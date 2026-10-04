class_name Burrow
extends Sprite2D

enum State {
	Sitting,
	Sleeping,
	Digging
}

const burrow1: Texture2D = preload("res://Assets/dens/burrow1.png")
const burrow2: Texture2D = preload("res://Assets/dens/burrow2.png")
const burrow3: Texture2D = preload("res://Assets/dens/burrow3.png")
const burrow4: Texture2D = preload("res://Assets/dens/burrow4.png")
const burrow5: Texture2D = preload("res://Assets/dens/burrow5.png")
const burrow6: Texture2D = preload("res://Assets/dens/burrow6.png")

@onready var sleep_bunny1: AnimatedSprite2D = %SleepBunny1
@onready var sleep_bunny2: AnimatedSprite2D = %SleepBunny2
@onready var sleep_bunny3: AnimatedSprite2D = %SleepBunny3
@onready var dig_bunny1: AnimatedSprite2D = %DigBunny1
@onready var dig_bunny2: AnimatedSprite2D = %DigBunny2
@onready var ritual_pile1: RitualPile = %RitualPile1
@onready var ritual_pile2: RitualPile = %RitualPile2

@onready var background := %BurrowBackground
@onready var shadow := %BurrowShadow

var burrow_state := 0
var bunny_state := State.Sitting

func _ready() -> void:
	set_burrow_state(0)
	hide_all_bunnies()
	set_rabbit_state(bunny_state)

func set_burrow_state(state: int) -> void:
	burrow_state = state
	hide_all_bunnies()
	set_rabbit_state(bunny_state)
	match state:
		0: set_burrow_texture(burrow1)
		1: set_burrow_texture(burrow2)
		2: set_burrow_texture(burrow3)
		3: set_burrow_texture(burrow4)
		4, 5: set_burrow_texture(burrow5)
		6: set_burrow_texture(burrow6)

func hide_all_bunnies() -> void:
	sleep_bunny1.hide()
	sleep_bunny2.hide()
	sleep_bunny3.hide()
	dig_bunny1.hide()
	dig_bunny2.hide()
	ritual_pile1.hide()
	ritual_pile2.hide()

func set_burrow_texture(new_texture: Texture2D) -> void:
	background.texture = new_texture
	shadow.texture = new_texture

func get_sleep_bunny() -> AnimatedSprite2D:
	if burrow_state >= 6: return sleep_bunny3
	return sleep_bunny2 if burrow_state >= 4 else sleep_bunny1
	
func get_dig_bunny() -> AnimatedSprite2D:
	return dig_bunny1 if burrow_state == 0 else dig_bunny2

func get_ritual_pile() -> RitualPile:
	return ritual_pile2 if burrow_state >= 4 else ritual_pile1

func update_ritual_pile(ritual_items_acquired: Array[Forage]):
	if burrow_state > 4:
		get_ritual_pile().hide()
	else:
		get_ritual_pile().show()
		get_ritual_pile().update(ritual_items_acquired)

func set_rabbit_state(state: State) -> void:
	bunny_state = state
	var sleep_bunny = get_sleep_bunny()
	var dig_bunny = get_dig_bunny()
	if state == State.Sleeping:
		dig_bunny.hide()
		sleep_bunny.show()
		sleep_bunny.play("asleep")
	elif state == State.Digging:
		sleep_bunny.hide()
		dig_bunny.show()
		dig_bunny.play("dig")
	else:
		dig_bunny.hide()
		sleep_bunny.show()
		sleep_bunny.play("awake")
