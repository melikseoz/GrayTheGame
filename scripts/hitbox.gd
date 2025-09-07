
extends Area2D
@export var damage: int = 1
@export var knockback: Vector2 = Vector2(220.0, -180.0)
var owner_facing_right: bool = true

func _ready() -> void:
    monitoring = false
    set_deferred("monitoring", false)

func get_damage_payload() -> Dictionary:
    var dir := 1 if owner_facing_right else -1
    return {"damage": damage, "knockback": Vector2(knockback.x * dir, knockback.y)}
