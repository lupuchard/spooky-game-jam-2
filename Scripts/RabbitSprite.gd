extends Area2D
class_name RabbitSprite

const CURSOR_SPEED := 150.0
const MIN_RUN_DIST := 10.0

const FORAGING_TRANSITION_SPEED = 3.0
const FORAGING_SLOWDOWN_FACTOR = 0.5

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var footstep_sound: AudioStreamPlayer2D = $FootstepSound
@onready var eat_sound: AudioStreamPlayer2D = $EatSound

var foraging := 0.0
var facing_right := true
var standing := true

func _ready():
	sprite.animation_looped.connect(func():
		if !standing:
			footstep_sound.play()
	)

func _process(delta: float):
	if Input.is_action_pressed("forage"):
		foraging += delta * FORAGING_TRANSITION_SPEED
	else:
		foraging -= delta * FORAGING_TRANSITION_SPEED
	foraging = clamp(foraging, 0.0, 1.0)
	sprite.speed_scale = 2.0 - foraging
	
	var mouse_pos := get_global_mouse_position() #get_viewport().get_mouse_position()
	var disp := mouse_pos - global_position
	var speed = CURSOR_SPEED * lerp(1.0, FORAGING_SLOWDOWN_FACTOR, foraging)
	if standing and disp.length_squared() < MIN_RUN_DIST * MIN_RUN_DIST:
		pass
	elif disp.length() < delta * speed:
		global_position = mouse_pos
		sprite.animation = "stand_right" if facing_right else "stand_left"
		standing = true
	else:
		global_position += disp.normalized() * delta * speed
		if disp.x < 0:
			facing_right = false
			sprite.animation = "run_left"
		else:
			facing_right = true
			sprite.animation = "run_right"
		if !sprite.is_playing():
			sprite.play()
		standing = false
	
	var camera_rect = get_canvas_transform().affine_inverse() * get_viewport_rect()
	global_position = global_position.clamp(camera_rect.position, camera_rect.end)
	
