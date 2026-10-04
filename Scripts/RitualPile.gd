class_name RitualPile
extends Node2D

@onready var items: Dictionary[String, Sprite2D] = {
	"paper": $Papers,
	"tinder": $Tinder,
	"sacrifice": $Sacrifice,
	"stone1": $Stone1,
	"stone2": $Stone2,
	"stone3": $Stone3,
	"stone4": $Stone4,
	"stone5": $Stone5,
}

func _ready():
	hide_everything()

func update(ritual_items_acquired: Array[Forage]):
	hide_everything()
	for item in ritual_items_acquired:
		var sprite = items.get(item.item_id)
		if sprite != null:
			sprite.show()

func hide_everything():
	for sprite in items.values():
		sprite.hide()
