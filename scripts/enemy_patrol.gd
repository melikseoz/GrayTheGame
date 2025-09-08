
extends CharacterBody2D

@export var speed: float = 90.0
@export var contact_damage: int = 1
# Maximum health this enemy starts with.
@export var max_health: int = 2
var _gravity: float = 1800.0

# Cached child nodes.
@onready var health: Health = $Health
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox

func _ready() -> void:
        # Configure stats and connect combat callbacks.
        health.max_health = max_health
        health.current = max_health
        health.emit_signal("health_changed", health.current, health.max_health)
        health.connect("died", Callable(self, "_on_died"))
        hurtbox.connect("hurt", Callable(self, "_on_hurt"))
        hitbox.damage = contact_damage

func _physics_process(delta: float) -> void:
        # Continuously chase the player by moving toward their X position.
        var player = get_tree().get_first_node_in_group("player")
        if player:
                var dir = sign(player.global_position.x - global_position.x)
                velocity.x = dir * speed
                hitbox.owner_facing_right = dir >= 0
        else:
                velocity.x = 0.0

        # Basic gravity.
        if not is_on_floor():
                velocity.y += _gravity * delta
        else:
                velocity.y = 0.0

        move_and_slide()

func apply_damage(amount: int, kb: Vector2) -> void:
        # Allow other hitboxes to damage and knock back the enemy.
        health.damage(amount)
        velocity = kb

func _on_hurt(damage: int, from_vec: Vector2) -> void:
        # Forward hurtbox signal to our damage handler.
        apply_damage(damage, from_vec)

func _on_died() -> void:
        # Remove the enemy from the scene when health reaches zero.
        queue_free()
