
extends Node
class_name Health

# Emitted when health reaches zero.
signal died
# Emitted whenever health changes so UI can update.
signal health_changed(current: int, max: int)

@export var max_health: int = 3  # Maximum hit points
var current: int                  # Current hit points

func _ready() -> void:
        # Initialise to full health.
        current = max_health
        emit_signal("health_changed", current, max_health)

func damage(amount: int) -> void:
        # Reduce health and emit signals; trigger death if depleted.
        current = max(0, current - amount)
        emit_signal("health_changed", current, max_health)
        if current <= 0:
                emit_signal("died")

func heal(amount: int) -> void:
        # Increase health without exceeding maximum.
        current = min(max_health, current + amount)
        emit_signal("health_changed", current, max_health)
