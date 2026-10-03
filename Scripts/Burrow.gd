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

@onready var sleep_bunny1: AnimatedSprite2D = %SleepBunny1
@onready var dig_bunny1: AnimatedSprite2D= %DigBunny1

@onready var background := %BurrowBackground
@onready var shadow := %BurrowShadow

func _ready():
	set_state(0)
	dig_bunny1.hide()

func set_state(state: int):
	match state:
		0: set_burrow_texture(burrow1)
		1: set_burrow_texture(burrow2)
		2: set_burrow_texture(burrow3)
		3: set_burrow_texture(burrow4)
		4: set_burrow_texture(burrow5)

func set_burrow_texture(new_texture: Texture2D):
	background.texture = new_texture
	shadow.texture = new_texture

func get_sleep_bunny():
	return sleep_bunny1
	
func get_dig_bunny():
	return dig_bunny1

func set_rabbit_state(state: State):
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
