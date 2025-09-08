
extends CharacterBody2D

# Simple state machine for handling the player's many movement/combat modes.
enum State { NORMAL, DASHING, ATTACKING, HURT, DEAD }

# --- Tunable stats ---
@export var GRAVITY: float = 1800.0
@export var MAX_SPEED: float = 260.0
@export var ACCEL_GROUND: float = 3200.0
@export var ACCEL_AIR: float = 1800.0
@export var FRICTION_GROUND: float = 2800.0

@export var JUMP_SPEED: float = 560.0
@export var JUMP_CUTOFF: float = 0.45
@export var COYOTE_TIME: float = 0.12
@export var JUMP_BUFFER: float = 0.12

@export var DASH_SPEED: float = 620.0
@export var DASH_TIME: float = 0.16
@export var DASH_COOLDOWN: float = 0.35

@export var WALL_SLIDE_SPEED: float = 140.0
@export var WALL_JUMP_PUSH: float = 360.0
@export var WALL_JUMP_BOOST_Y: float = 560.0

@export var ATTACK_TIME: float = 0.18

# Combat stats
@export var MAX_HEALTH: int = 3
@export var ATTACK_DAMAGE: int = 1

@onready var sprite: Node2D = $Sprite
@onready var camera: Camera2D = $Camera2D
# Area used to deal damage when attacking.
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
# Area used to receive damage from other actors.
@onready var hurtbox: Area2D = $Hurtbox
# Handles current and maximum health.
@onready var health: Health = $Health
# Quick placeholder sprite shown during attacks.
@onready var attack_sprite: Sprite2D = $Hitbox/AttackSprite

var state: State = State.NORMAL
var facing_right := true

var _coyote: float = 0.0
var _jump_buf: float = 0.0
var _dash_t: float = 0.0
var _dash_cd: float = 0.0
var _attack_t: float = 0.0

func _ready() -> void:
        add_to_group("player")
        # Wire up combat related signals and initialise stats.
        health.connect("died", Callable(self, "_on_died"))
        hurtbox.connect("hurt", Callable(self, "_on_hurt"))
        health.max_health = MAX_HEALTH
        health.current = MAX_HEALTH
        health.emit_signal("health_changed", health.current, health.max_health)
        hitbox.damage = ATTACK_DAMAGE
        hitbox.monitoring = false
        hitbox_shape.disabled = true

func _physics_process(delta: float) -> void:
	_coyote = max(0.0, _coyote - delta)
	_jump_buf = max(0.0, _jump_buf - delta)
	_dash_t = max(0.0, _dash_t - delta)
	_dash_cd = max(0.0, _dash_cd - delta)
	_attack_t = max(0.0, _attack_t - delta)

	if is_on_floor():
		_coyote = COYOTE_TIME

        # Dispatch to the active state handler.
        match state:
		State.NORMAL:
			_state_normal(delta)
		State.DASHING:
			_state_dashing(delta)
		State.ATTACKING:
			_state_attacking(delta)
		State.HURT:
			_state_hurt(delta)
		State.DEAD:
			velocity = Vector2.ZERO

	move_and_slide()

func _state_normal(delta: float) -> void:
        # Standard movement: walking, jumping and initiating dash/attack.
        var input_dir := Input.get_axis("move_left", "move_right")
        var accel := ACCEL_GROUND if is_on_floor() else ACCEL_AIR

	if input_dir != 0.0:
		velocity.x = move_toward(velocity.x, input_dir * MAX_SPEED, accel * delta)
		facing_right = input_dir > 0.0
	else:
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0.0, FRICTION_GROUND * delta)

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		if velocity.y > 0.0:
			velocity.y = 0.0

	if not Input.is_action_pressed("jump") and velocity.y < 0.0:
		velocity.y = move_toward(velocity.y, 0.0, JUMP_SPEED * JUMP_CUTOFF)

	# Wall slide (simple): slow descent when holding toward a colliding wall
	var on_wall := is_on_wall()
	if on_wall and not is_on_floor() and input_dir != 0.0:
		velocity.y = min(velocity.y, WALL_SLIDE_SPEED)

	if _jump_buf > 0.0 and (_coyote > 0.0 or on_wall):
		if on_wall and not is_on_floor():
			var dir : float = -sign(input_dir) if input_dir != 0.0 else ( -1 if facing_right else 1 )
			velocity = Vector2(dir * WALL_JUMP_PUSH, -WALL_JUMP_BOOST_Y)
			facing_right = dir > 0
		else:
			velocity.y = -JUMP_SPEED
		_jump_buf = 0.0
		_coyote = 0.0

        if Input.is_action_just_pressed("dash") and _dash_cd <= 0.0:
                state = State.DASHING
		_dash_t = DASH_TIME
		_dash_cd = DASH_COOLDOWN
		var dir := Input.get_axis("move_left", "move_right")
		if dir == 0.0:
			dir = 1.0 if facing_right else -1.0
		velocity = Vector2(dir * DASH_SPEED, 0.0)
		return

        if Input.is_action_just_pressed("attack"):
                state = State.ATTACKING
                _attack_t = ATTACK_TIME
                _begin_attack_window()

func _state_dashing(delta: float) -> void:
        velocity.y = 0.0
        # Dash ends when timer runs out.
        if _dash_t <= 0.0:
                state = State.NORMAL
        if Input.is_action_just_pressed("jump"):
                _jump_buf = JUMP_BUFFER
        if Input.is_action_just_pressed("attack"):
                state = State.ATTACKING
                _attack_t = ATTACK_TIME
                _begin_attack_window()

func _state_attacking(delta: float) -> void:
        # Slight horizontal drift towards facing direction while in air
        # and fall normally under gravity.
        if not is_on_floor():
                velocity.y += GRAVITY * delta
        velocity.x = move_toward(velocity.x, (1 if facing_right else -1) * MAX_SPEED * 0.4, ACCEL_AIR * 0.5 * delta)
        # Attack window ends once timer is done.
        if _attack_t <= 0.0:
                _end_attack_window()
                state = State.NORMAL
        if Input.is_action_just_pressed("jump"):
                _jump_buf = JUMP_BUFFER

func _state_hurt(delta: float) -> void:
        # Knocked back; regain control once we land.
        velocity.y += GRAVITY * delta
        if is_on_floor():
                state = State.NORMAL

func _input(event: InputEvent) -> void:
        if event.is_action_pressed("jump"):
                _jump_buf = JUMP_BUFFER

func _begin_attack_window() -> void:
        # Enable the hitbox positioned in front of the player.
        hitbox.monitoring = true
        hitbox.monitorable = true
        hitbox_shape.disabled = false
        hitbox.position.x = 16.0 * (1 if facing_right else -1)
        hitbox.position.y = 0.0
        hitbox.owner_facing_right = facing_right
        attack_sprite.visible = true

func _end_attack_window() -> void:
        # Disable hitbox once attack is over.
        hitbox.monitoring = false
        hitbox.monitorable = false
        hitbox_shape.disabled = true
        attack_sprite.visible = false

func apply_damage(amount: int, kb: Vector2) -> void:
        if state == State.DEAD:
                return
        # Apply damage and knockback, entering the hurt state.
        health.damage(amount)
        velocity = kb
        state = State.HURT

func _on_hurt(damage: int, from_vec: Vector2) -> void:
        # Callback from hurtbox when another hitbox deals damage.
        apply_damage(damage, from_vec)

func _on_died() -> void:
        # Reset the scene on death for now.
        state = State.DEAD
        get_tree().reload_current_scene()
