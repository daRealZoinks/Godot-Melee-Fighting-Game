extends PlayerState

@export_category("Movement")
@export var speed: float = 7.0
@export var acceleration: float = 50.0
@export var deceleration: float = 50.0

@export var air_control: float = 0.25
@export var air_break: float = 0

@export_category("Jump")
@export var jump_height: float = 1.5
@export var jump_buffer: float = 0.15
@export var coyote_time: float = 0.15
@export var gravity_scale: float = 1.5

@export var animation_player: AnimationPlayer
@export var check_for_enemy_hitbox: Area3D

var was_on_floor: bool

var look_input: Vector2
var move_input: Vector2

var jump_buffer_timer: SceneTreeTimer
var coyote_time_timer: SceneTreeTimer

func enter() -> void:
	pass

func exit() -> void:
	pass

func physics_process(delta: float) -> void:
	apply_gravity(delta)
	move(move_input, delta)
	handle_jump()
	was_on_floor = player.is_on_floor()

	player.move_and_slide()
	
	if was_on_floor and not player.is_on_floor():
		coyote_time_timer = get_tree().create_timer(coyote_time)

func apply_gravity(delta: float) -> void:
	if not player.is_on_floor():
		player.velocity += player.get_gravity() * gravity_scale * delta

func move(input: Vector2, delta: float) -> void:
	var direction = (player.transform.basis * Vector3(input.x, 0, input.y)).normalized()
	
	var target_delta = delta
	
	if direction != Vector3.ZERO:
		target_delta *= acceleration
		if not player.is_on_floor():
			target_delta *= air_control
	else:
		target_delta *= deceleration
		if not player.is_on_floor():
			target_delta *= air_break
	
	var new_velocity = player.velocity.move_toward(direction * speed, target_delta)
	new_velocity.y = player.velocity.y
	player.velocity = new_velocity

func handle_jump():
	if jump_buffer_timer and jump_buffer_timer.time_left > 0:
		if player.is_on_floor() or coyote_time_timer and coyote_time_timer.time_left > 0:
			player.velocity.y = sqrt(-2 * player.get_gravity().y * gravity_scale * jump_height)
			jump_buffer_timer = null
			coyote_time_timer = null

func unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.mouse_mode =Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	move_input = Input.get_vector("left", "right", "forward", "backward")

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = get_tree().create_timer(jump_buffer)
	
	if event.is_action_pressed("attack"):
		var damageable = damageable_in_hitbox()
		if damageable:
			get_parent().transition_to("AttackState", damageable)
		else:
			animation_player.play("attack_miss")

func damageable_in_hitbox() -> Node3D:
	var bodies: Array[Node3D] = check_for_enemy_hitbox.get_overlapping_bodies()
	bodies = bodies.filter(func(element): return element.find_child("Health") and element != player)
	
	var forward = -player.transform.basis.z
	bodies.sort_custom(func(a, b): 
		var angle_a = forward.angle_to((a.position - player.position).normalized())
		var angle_b = forward.angle_to((b.position - player.position).normalized())
		return angle_a < angle_b
	)

	if bodies.is_empty():
		return null
	else:
		return bodies[0]
