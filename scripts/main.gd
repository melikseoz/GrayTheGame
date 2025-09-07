
extends Node2D
const WORLD_SCENE := preload("res://scenes/World.tscn")

func _ready() -> void:
	_ensure_input_map()
	var world := WORLD_SCENE.instantiate()
	add_child(world)

func _ensure_input_map() -> void:
	var ev_a := InputEventKey.new(); ev_a.physical_keycode = KEY_A
	var ev_left := InputEventKey.new(); ev_left.physical_keycode = KEY_LEFT
	var ev_d := InputEventKey.new(); ev_d.physical_keycode = KEY_D
	var ev_right := InputEventKey.new(); ev_right.physical_keycode = KEY_RIGHT
	var ev_space := InputEventKey.new(); ev_space.physical_keycode = KEY_SPACE
	var ev_shift := InputEventKey.new(); ev_shift.physical_keycode = KEY_SHIFT
	var ev_j := InputEventKey.new(); ev_j.physical_keycode = KEY_J
	var ev_z := InputEventKey.new(); ev_z.physical_keycode = KEY_Z

	var map = {
		"move_left": [ev_a, ev_left],
		"move_right": [ev_d, ev_right],
		"jump": [ev_space],
		"dash": [ev_shift],
		"attack": [ev_j, ev_z],
	}
	for action in map.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for ev in map[action]:
			InputMap.action_add_event(action, ev)
