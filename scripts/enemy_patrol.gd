
extends CharacterBody2D

@export var speed: float = 90.0
@export var contact_damage: int = 1
var _gravity: float = 1800.0

@onready var health: Health = $Health
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox

func _ready() -> void:
        health.connect("died", Callable(self, "_on_died"))
        hurtbox.connect("hurt", Callable(self, "_on_hurt"))
        hitbox.damage = contact_damage

func _physics_process(delta: float) -> void:
        var player = get_tree().get_first_node_in_group("player")
        if player:
                var dir = sign(player.global_position.x - global_position.x)
                velocity.x = dir * speed
                hitbox.owner_facing_right = dir >= 0
        else:
                velocity.x = 0.0

        if not is_on_floor():
                velocity.y += _gravity * delta
        else:
                velocity.y = 0.0

        move_and_slide()

func apply_damage(amount: int, kb: Vector2) -> void:
        health.damage(amount)
        velocity = kb

func _on_hurt(damage: int, from_vec: Vector2) -> void:
        apply_damage(damage, from_vec)

func _on_died() -> void:
        queue_free()
