
extends Area2D
signal hurt(damage: int, from_vector: Vector2)

func _ready() -> void:
    monitoring = true
    connect("body_entered", Callable(self, "_on_body_entered"))
    connect("area_entered", Callable(self, "_on_area_entered"))

func _on_body_entered(body: Node) -> void:
    if body.has_method("get_damage_payload"):
        var data = body.get_damage_payload()
        emit_signal("hurt", data["damage"], data["knockback"])

func _on_area_entered(area: Area2D) -> void:
    if area.has_method("get_damage_payload"):
        var data = area.get_damage_payload()
        emit_signal("hurt", data["damage"], data["knockback"])
