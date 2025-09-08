
extends Area2D

signal hurt(damage: int, from_vector: Vector2)

func _ready() -> void:
    # Listen for any overlapping physics bodies or areas so we can
    # forward their damage payload to the owning actor.
    monitoring = true
    connect("body_entered", Callable(self, "_on_body_entered"))
    connect("area_entered", Callable(self, "_on_area_entered"))

func _on_body_entered(body: Node) -> void:
    # Ignore our own parent so that a character never damages itself
    # via its own hitbox or body.
    if body == get_parent():
        return
    if body.has_method("get_damage_payload"):
        var data = body.get_damage_payload()
        emit_signal("hurt", data["damage"], data["knockback"])

func _on_area_entered(area: Area2D) -> void:
    # Areas belonging to the same parent are also ignored to prevent
    # self infliction when attacking to the left/right.
    if area.get_parent() == get_parent():
        return
    if area.has_method("get_damage_payload"):
        var data = area.get_damage_payload()
        emit_signal("hurt", data["damage"], data["knockback"])
