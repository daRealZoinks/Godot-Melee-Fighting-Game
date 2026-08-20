extends Node3D
class_name MouseLook

@export var mouse_sensitivity: float = 0.002
@export var controller_sensitivity: float = 3.0

@export var max_look_down: float = 80.0
@export var max_look_up: float = -80.0

@export var player: PlayerController

var look_input: Vector2

func input(event: InputEvent) -> void:
	# mouse inputs
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			player.rotate_y(-event.relative.x * mouse_sensitivity)
			rotate_x(-event.relative.y * mouse_sensitivity)
			rotation.x = clamp(rotation.x, deg_to_rad(max_look_up), deg_to_rad(max_look_down))

	# controller inputs
	look_input = Input.get_vector("look_left", "look_right", "look_down", "look_up")

func _process(delta: float) -> void:
	if look_input != Vector2.ZERO:
		player.rotate_y(-look_input.x * controller_sensitivity * delta)
		rotate_x(look_input.y * controller_sensitivity * delta)
		rotation.x = clamp(
			rotation.x,
			deg_to_rad(max_look_up),
			deg_to_rad(max_look_down)
		)
