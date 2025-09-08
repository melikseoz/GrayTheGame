
extends Area2D
# Generic hitbox that can deal a specified amount of damage and
# knockback when overlapping a hurtbox.
@export var damage: int = 1             # Amount of health removed on hit
@export var knockback: Vector2 = Vector2(220.0, -180.0)  # Base knockback force
var owner_facing_right: bool = true     # Used to flip knockback horizontally

func _ready() -> void:
    # Hitboxes start disabled and are toggled on during attack frames.
    monitoring = false
    set_deferred("monitoring", false)

func get_damage_payload() -> Dictionary:
    # Hurtboxes call this to know what damage/knockback to apply.
    var dir := 1 if owner_facing_right else -1
    return {"damage": damage, "knockback": Vector2(knockback.x * dir, knockback.y)}
