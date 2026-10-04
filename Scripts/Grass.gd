extends MultiMeshInstance2D

# todo: need to do 3d for depth check?

signal ate

enum GrassState {
	Full,
	Half,
	Low,
	Hover
}

const GRASS_SIZE := Vector2(30, -50)

const POS_VARIATION := Vector2(0.2, 0.2)
const SIZE_VARIATION := Vector2(0.05, 0.3)

const GRASSES := Vector2i(35, 30)

const EAT_RANGE := 30.0
const GRASS_HOVER := Vector2(0.5, 0)
const GRASS_FULL := Vector2(0, 0)
const GRASS_HALF := Vector2(0, 0.5)
const GRASS_LOW := Vector2(0.5, 0.5)
const GRASS_GROW_RATE := 0.002 # 0.01
const GRASS_UPDATE_FREQ := 10
const NOGRASS_RANGE := 30

@onready var bottom_grass: MultiMeshInstance2D = $BottomGrass

@export var rabbit: RabbitSprite
@export var nograss: Array[Node2D]

var can_eat := false

var grass_positions := PackedVector2Array()
var grass_indices := PackedInt32Array()
var grass_scales := PackedVector2Array()
var grass_growth := PackedFloat32Array()
var hovering := Vector2i(-1, -1)
var rate_mod := 1.0

var cur_i := 0

func _ready():
	multimesh.use_custom_data = true
	multimesh.use_colors = true
	multimesh.instance_count = GRASSES.x * GRASSES.y
	bottom_grass.multimesh = bottom_grass.multimesh.duplicate_deep()
	
	var window_size := get_viewport().get_visible_rect().size
	var stagger = false
	var positions: Array[Vector2] = []
	var indices: Array[int]
	for y in range(0, GRASSES.y):
		stagger = !stagger
		for x in range(0, GRASSES.x):
			var grass_pos := Vector2(x, y) / (Vector2(GRASSES) - Vector2.ONE) * window_size
			grass_pos += POS_VARIATION * GRASS_SIZE * rand_vect() * 0.6
			var grass_scale := (SIZE_VARIATION * rand_vect() + Vector2.ONE) * GRASS_SIZE
			if randi_range(0, 1) == 1:
				grass_scale.x = -grass_scale.x
			positions.push_back(grass_pos)
			grass_scales.push_back(grass_scale)
			grass_growth.push_back(1.0)
			indices.push_back(x + y * GRASSES.x)
	
	grass_positions = PackedVector2Array(positions)
	grass_indices = PackedInt32Array(indices)
	indices.sort_custom(sort_by_y)
	for i in range(0, indices.size()):
		grass_positions[indices[i]] = positions[i]
		grass_indices[i] = indices[i]
		if is_nograss(grass_positions[indices[i]]):
			grass_growth[indices[i]] = -1.0
			set_grass_state(indices[i], GrassState.Low)
	
	for i in range(0, grass_positions.size()):
		var trans = Transform2D(0.0, grass_scales[i], 0.0, grass_positions[i])
		multimesh.set_instance_transform_2d(i, trans)
		multimesh.set_instance_custom_data(i, Color(grass_scales[i].x, 0, 0))
		multimesh.set_instance_color(i, Color.WHITE)
		bottom_grass.multimesh.set_instance_transform_2d(i, trans)
		bottom_grass.multimesh.set_instance_color(i, Color.TRANSPARENT)
		update_grass_at_index(i)
		
func sort_by_y(a: int, b: int) -> bool:
	return grass_positions[a].y < grass_positions[b].y

func _process(delta: float):
	var shader = material as ShaderMaterial
	shader.set_shader_parameter("cursor_pos", rabbit_position())
	shader.set_shader_parameter("searching_factor", rabbit.foraging)
	update_hovering()
	
	cur_i += 1
	var i = cur_i % (grass_growth.size())
	if grass_growth[i] != -1.0:
		grass_growth[i] += delta * GRASS_GROW_RATE * rate_mod * grass_growth.size() * randf() * 2.0
	
func update_grass_at_index(i: int):
	if i == grass_index(hovering):
		pass
	elif grass_growth[i] < 0.5:
		set_grass_state(i, GrassState.Low)
	elif grass_growth[i] < 1.0:
		set_grass_state(i, GrassState.Half)
	else:
		set_grass_state(i, GrassState.Full)
	
func _input(event: InputEvent):
	if event.is_action_pressed("click") and Rect2i(Vector2.ZERO, GRASSES).has_point(hovering):
		var i = grass_indices[hovering.x + hovering.y * GRASSES.x]
		if grass_growth[i] >= 1.0:
			grass_growth[i] = 0.0
			set_grass_state(i, GrassState.Low)
			ate.emit()

func update_hovering():
	if rabbit.foraging or !can_eat:
		return set_hovering(Vector2i(-1, -1))
	
	var mouse_pos = get_viewport().get_mouse_position()
	if mouse_pos.distance_squared_to(rabbit_position()) < pow(EAT_RANGE, 2):
		var viewport_size = get_viewport_rect().size
		set_hovering(Vector2i((mouse_pos / viewport_size * (Vector2(GRASSES) - Vector2.ONE)).round()))
		
		#var now_hovering := 
		#if now_hovering != hovering and Rect2i(Vector2.ZERO, GRASSES).has_point(now_hovering):
		#	var i = now_hovering.x + now_hovering.y * GRASSES.x
		#	if grass_states[i] >= 1.0:
		#		multimesh.set_instance_custom_data(i, Color(grass_scales[i].x, GRASS_HOVER.x, GRASS_HOVER.y))
		#hovering = now_hovering
	else:
		set_hovering(Vector2i(-1, -1))

func rabbit_position() -> Vector2:
	return rabbit.global_position - global_position

func set_hovering(new_hovering: Vector2i):
	if new_hovering == hovering:
		return
	
	var hovering_i = grass_index(hovering)
	if hovering_i != -1 and grass_growth[hovering_i] >= 1.0:
		set_grass_state(hovering_i, GrassState.Full)
	
	var new_hovering_i = grass_index(new_hovering)
	if new_hovering_i != -1 and grass_growth[new_hovering_i] >= 1.0:
		set_grass_state(new_hovering_i, GrassState.Hover)
	
	hovering = new_hovering
	
func grass_index(pos: Vector2i) -> int:
	if Rect2i(Vector2.ZERO, GRASSES).has_point(pos):
		return grass_indices[pos.x + pos.y * GRASSES.x]
	else:
		return -1

func rand_vect() -> Vector2:
	return Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))

func set_grass_state(i: int, state: GrassState) -> void:
	var above: Color
	var below: Color
	match state:
		GrassState.Full:
			above = Color(grass_scales[i].x, GRASS_FULL.x, GRASS_FULL.y)
			below = Color.TRANSPARENT
		GrassState.Half:
			above = Color(grass_scales[i].x, GRASS_HALF.x, GRASS_HALF.y)
			below = Color.TRANSPARENT
		GrassState.Low:
			above = Color.TRANSPARENT
			below = Color(grass_scales[i].x, GRASS_LOW.x, GRASS_LOW.y)
		GrassState.Hover:
			above = Color(grass_scales[i].x, GRASS_HOVER.x, GRASS_HOVER.y)
			below = Color.TRANSPARENT
	set_multimesh_grass_state(multimesh, i, above)
	set_multimesh_grass_state(bottom_grass.multimesh, i, below)

func set_multimesh_grass_state(mesh: MultiMesh, i: int, custom_data: Color):
	if custom_data == Color.TRANSPARENT:
		mesh.set_instance_color(i, Color.TRANSPARENT)
	else:
		mesh.set_instance_color(i, Color.WHITE)
		mesh.set_instance_custom_data(i, custom_data)

	#for y in range(0, GRASSES_Y):
		#for x in range(0, GRASSES_X):
			#var idx = x + y * GRASSES_X
			#var grass_pos = grass_positions[idx]
			#var grass_scale = grass_scales[idx]
			#
			#var offset = time + grass_pos.x * wind_speed_x + grass_pos.y * wind_speed_y
			#var wind_skew = (
				#sin(time / wind_period1) * wind_strength1
				#+ sin(time / wind_period2) * wind_strength2
				#+ sin(offset / wind_period3) * wind_strength3
			#)
			#
			#disp = cursor_pos - grass_pos
			#var transparency = min(disp.length() / SIGHT_RANGE, 1.0)
			#
			#var cursor_skew = (PI * 0.3) * max(1.0 - (disp * Vector2(1, 2)).length() / SIGHT_RANGE, 0.0)
			#if cursor_pos.x > grass_pos.x:
				#cursor_skew = -cursor_skew
			#if abs(cursor_pos.x - grass_pos.x) < (SIGHT_RANGE * 0.1):
				#cursor_skew *= (abs(cursor_pos.x - grass_pos.x)) / (SIGHT_RANGE * 0.1)
			#
			#var trans = Transform2D(0.0, grass_scale, wind_skew + cursor_skew, grass_pos)
			#multimesh.set_instance_transform_2d(idx, trans)
			#multimesh.set_instance_color(idx, Color(1.0, 1.0, 1.0, transparency * transparency))

func is_nograss(pos: Vector2):
	for nograss_node in nograss:
		var nograss_position = nograss_node.global_position - global_position
		if nograss_position.distance_squared_to(pos) < NOGRASS_RANGE * NOGRASS_RANGE:
			return true
	return false

#func create_grass_mesh() -> ArrayMesh:
	#var vertices = PackedVector3Array()
	#for i in range(0, NUM_SPIKES):
		#vertices.push_back(Vector3(i * SPIKE_WIDTH, SPIKE_HEIGHT, 0))
		#vertices.push_back(Vector3(i * SPIKE_WIDTH + SPIKE_WIDTH / 2.0, 0, 0))
		#vertices.push_back(Vector3(i * SPIKE_WIDTH + SPIKE_WIDTH, SPIKE_HEIGHT, 0))
		#
	#var mesh = ArrayMesh.new()
	#var arrays = []
	#arrays.resize(Mesh.ARRAY_MAX)
	#arrays[Mesh.ARRAY_VERTEX] = vertices
	#
	#mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	#return mesh
