class_name RitualRequirementLabel
extends HBoxContainer

@export var text: String

@onready var label: Label = $Label
@onready var checkmark: TextureRect = $Checkmark

func set_quantity(amount: int, goal: int):
	label.text = "%s: %s/%s" % [text, amount, goal]
	if amount >= goal:
		modulate = Color.LAWN_GREEN
		checkmark.show()
	else:
		modulate = Color.WHITE
		checkmark.hide()
