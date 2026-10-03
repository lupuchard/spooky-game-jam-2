class_name Util
extends Node

static func random_position_in_area(area: Area2D) -> Vector2:
	var child_index = randi_range(0, area.get_child_count() - 1)
	var child = area.get_child(child_index)
	if child is CollisionShape2D:
		if child.shape is RectangleShape2D:
			if child.global_rotation != 0.0 || child.global_scale != Vector2.ONE:
				push_error("Spawn rect must not be rotated or scaled: %s" % child.get_path())
			return random_position_in_rectangle(child.shape, child.global_position)
		else:
			push_error("Spawn children must be valid shapes: %s" % area.get_path())
	return Vector2.ZERO


static func random_position_in_rectangle(rect: RectangleShape2D, position: Vector2) -> Vector2:
	var x = randf_range(0, rect.size.x)
	var y = randf_range(0, rect.size.y)
	return position + Vector2(x, y) - (rect.size / 2)
