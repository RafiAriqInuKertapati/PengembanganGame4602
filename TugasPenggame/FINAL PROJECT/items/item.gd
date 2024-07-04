extends Area2D

class_name Item

signal picked_up(item_type)

enum ItemType {
	CHERRY,
	GEM
}

var textures: Dictionary = {
	ItemType.CHERRY: "res://assets/sprites/cherry.png",
	ItemType.GEM: "res://assets/sprites/gem.png"
}

var item_type: ItemType

func init(type: ItemType, _position: Vector2) -> void:
	item_type = type
	$Sprite2D.texture = load(textures[type])
	position = _position

func _on_body_entered(body: Node2D) -> void:
	picked_up.emit(item_type)
	queue_free()
