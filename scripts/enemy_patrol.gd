
extends CharacterBody2D

@export var speed: float = 90.0
@export var patrol_points: Array[NodePath] = []
@export var contact_damage: int = 1

var _target_index := 0
var _targets: Array[Vector2] = []
var _gravity: float = 1800.0

@onready var health: Health = $Health
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox

func _ready() -> void:
        for p in patrol_points:
                var n = get_node_or_null(p)
                if n:
                        _targets.append(n.global_position)
        health.connect("died", Callable(self, "_on_died"))
        hurtbox.connect("hurt", Callable(self, "_on_hurt"))
        hitbox.damage = contact_damage

func _physics_process(delta: float) -> void:
        if _targets.size() >= 1:
                var target = _targets[_target_index]
                var dir = sign(target.x - global_position.x)
                velocity.x = dir * speed
                if abs(target.x - global_position.x) < 4.0:
                        _target_index = (_target_index + 1) % _targets.size()

        if not is_on_floor():
                velocity.y += _gravity * delta
        else:
                velocity.y = 0.0

        var player = get_tree().get_first_node_in_group("player")
        if player:
                hitbox.owner_facing_right = player.global_position.x > global_position.x

        move_and_slide()

func apply_damage(amount: int, kb: Vector2) -> void:
        health.damage(amount)
        velocity = kb

func _on_hurt(damage: int, from_vec: Vector2) -> void:
        apply_damage(damage, from_vec)

func _on_died() -> void:
        queue_free()
