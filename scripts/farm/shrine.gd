class_name Shrine
extends Area2D
## The old shrine, the goal of Layer 2. Interacting with it (F) asks Farm to restore it.

signal activated

@export var cursed_texture: Texture2D
@export var restored_texture: Texture2D

var restored := false:
	set(value):
		restored = value
		_update_look()

@onready var sprite: Sprite2D = $Sprite2D
@onready var light: PointLight2D = $Light


func _ready() -> void:
	_update_look()


func interact(_player: Player) -> void:
	activated.emit()


func _update_look() -> void:
	if not is_node_ready():
		return
	sprite.texture = restored_texture if restored else cursed_texture
	light.enabled = restored
