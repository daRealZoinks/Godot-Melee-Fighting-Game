extends Node
class_name Health

signal health_changed(current_health: int, direction: Vector3)
signal died

@export var max_health: float = 100.0

@onready var current_health: float = max_health

var dead = false

func take_damage(amount: float, direction: Vector3) -> void:
	if current_health <= 0:
		return
	current_health = clamp(current_health - amount, 0, max_health)
	emit_signal("health_changed", current_health, direction)

	if current_health == 0:
		emit_signal("died")

func heal(amount: float) -> void:
	current_health = clamp(current_health + amount, 0, max_health)
	emit_signal("health_changed", current_health, null)

func _on_died() -> void:
	dead = true
