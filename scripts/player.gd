
extends CharacterBody2D

enum State { NORMAL, DASHING, ATTACKING, HURT, DEAD }

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

@onready var sprite: Node2D = $Sprite
@onready var camera: Camera2D = $Camera2D
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var health: Health = $Health

var state: State = State.NORMAL
var facing_right := true

var _coyote: float = 0.0
var _jump_buf: float = 0.0
var _dash_t: float = 0.0
var _dash_cd: float = 0.0
var _attack_t: float = 0.0

func _ready() -> void:
	health.connect("died", Callable(self, "_on_died"))
	hurtbox.connect("hurt", Callable(self, "_on_hurt"))
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
	if _dash_t <= 0.0:
		state = State.NORMAL
	if Input.is_action_just_pressed("jump"):
		_jump_buf = JUMP_BUFFER
	if Input.is_action_just_pressed("attack"):
		state = State.ATTACKING
		_attack_t = ATTACK_TIME
		_begin_attack_window()

func _state_attacking(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = move_toward(velocity.x, (1 if facing_right else -1) * MAX_SPEED * 0.4, ACCEL_AIR * 0.5 * delta)
	if _attack_t <= 0.0:
		_end_attack_window()
		state = State.NORMAL
	if Input.is_action_just_pressed("jump"):
		_jump_buf = JUMP_BUFFER

func _state_hurt(delta: float) -> void:
	velocity.y += GRAVITY * delta
	if is_on_floor():
		state = State.NORMAL

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		_jump_buf = JUMP_BUFFER

func _begin_attack_window() -> void:
	hitbox.monitoring = true
	hitbox_shape.disabled = false
	hitbox.position.x = 16.0 * (1 if facing_right else -1)
	hitbox.position.y = 0.0
	hitbox.owner_facing_right = facing_right

func _end_attack_window() -> void:
	hitbox.monitoring = false
	hitbox_shape.disabled = true

func apply_damage(amount: int, kb: Vector2) -> void:
	if state == State.DEAD:
		return
	health.damage(amount)
	velocity = kb
	state = State.HURT

func _on_hurt(damage: int, from_vec: Vector2) -> void:
	apply_damage(damage, from_vec)

func _on_died() -> void:
	state = State.DEAD
	get_tree().reload_current_scene()
