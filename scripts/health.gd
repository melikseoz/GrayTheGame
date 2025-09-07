
extends Node
class_name Health

signal died
signal health_changed(current: int, max: int)

@export var max_health: int = 3
var current: int

func _ready() -> void:
	current = max_health
	emit_signal("health_changed", current, max_health)

func damage(amount: int) -> void:
	current = max(0, current - amount)
	emit_signal("health_changed", current, max_health)
	if current <= 0:
		emit_signal("died")

func heal(amount: int) -> void:
	current = min(max_health, current + amount)
	emit_signal("health_changed", current, max_health)
