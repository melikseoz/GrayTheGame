extends CanvasLayer

@export var health_path: NodePath

@onready var bar: ProgressBar = $Bar
var health: Health

func _ready() -> void:
    if health_path != NodePath(""):
        health = get_node(health_path)
        if health:
            bar.max_value = health.max_health
            bar.value = health.current
            health.connect("health_changed", Callable(self, "_on_health_changed"))

func _on_health_changed(current: int, max_val: int) -> void:
    bar.max_value = max_val
    bar.value = current
