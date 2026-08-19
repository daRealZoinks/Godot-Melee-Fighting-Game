extends CharacterBody3D

@export_category("Movement")
@export var speed: float = 7.0
@export var acceleration: float = 50.0
@export var deceleration: float = 50.0

@export var air_control: float = 0.25
@export var air_break: float = 0

@export_category("Jump")
@export var jump_height: float = 1.5
@export var jump_buffer: float = 0.15
@export var gravity_scale: float = 1.5

@export_category("Camera")
@export var mouse_sensitivity: float = 0.002
@export var controller_sensitivity: float = 3.0

@export var max_look_down: float = 80.0
@export var max_look_up: float = -80.0

@export_category("Attack")
@export var attack_damage: float = 30.0

@onready var neck := $Neck
@onready var animation_player := $AnimationPlayer
@onready var attack_sound_effect := $PunchWeak
@onready var area3D := $Neck/Area3D
@onready var camera3d := $Neck/Camera3D

var jump_buffer_counter: float
var look_input: Vector2
var move_input: Vector2

const time_to_attack = 0.15

var body: Node3D

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.mouse_mode =Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * mouse_sensitivity)
			neck.rotate_x(-event.relative.y * mouse_sensitivity)
			neck.rotation.x = clamp(
				neck.rotation.x,
				deg_to_rad(max_look_up),
				deg_to_rad(max_look_down)
			)

func _input(event: InputEvent) -> void:
	look_input = Input.get_vector("look_left", "look_right", "look_down", "look_up")
	move_input = Input.get_vector("left", "right", "forward", "backward")
	if Input.is_action_just_pressed("jump"):
		jump_buffer_counter = jump_buffer
	
	if event.is_action_pressed("attack"):
		animation_player.play("attack")
		get_closest_hittable_body()

func get_closest_hittable_body():
	var bodies: Array[Node3D] = area3D.get_overlapping_bodies()
	bodies = bodies.filter(func(element): return element.find_child("Health") and element != self)
	bodies.sort_custom(func(a, b): return position.distance_to(a.position) < position.distance_to(b.position))
	if bodies.is_empty():
		return
	
	body = bodies[0]
	
	var enemy = (body as Enemy)
	var capsule_shape_3d: CapsuleShape3D = (enemy.collision_shape_3d.shape as CapsuleShape3D)
	
	var target_position = body.position - (body.position - Vector3(position.x, body.position.y, position.z)).normalized()
	var target_look_at = body.position + Vector3.UP * (capsule_shape_3d.height / 2 - capsule_shape_3d.radius)
	
	get_into_position_for_attack(target_position, target_look_at)
	
func get_into_position_for_attack(target_position: Vector3, target_look_at: Vector3) -> void:
	velocity = Vector3.ZERO
	var tween = get_tree().create_tween().set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", target_position, time_to_attack)
	tween.tween_method(func(value): rotation.y = value, rotation.y, (transform.looking_at(Vector3(target_look_at.x, position.y, target_look_at.z))).basis.get_euler().y, time_to_attack)
	tween.tween_method(func(value): neck.rotation.x = value, neck.rotation.x, (neck.transform.looking_at(target_look_at)).basis.get_euler().x, time_to_attack)

func _process(delta: float) -> void:
	if look_input != Vector2.ZERO:
		rotate_y(-look_input.x * controller_sensitivity * delta)
		neck.rotate_x(look_input.y * controller_sensitivity * delta)
		neck.rotation.x = clamp(
			neck.rotation.x,
			deg_to_rad(max_look_up),
			deg_to_rad(max_look_down)
		)

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	update_jump_buffer_counter(delta)
	handle_jump()
	move(move_input, delta)
	move_and_slide()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * gravity_scale * delta

func update_jump_buffer_counter(delta: float) -> void:
	if jump_buffer_counter > 0:
		jump_buffer_counter -= delta

func handle_jump() -> void:
	if jump_buffer_counter > 0:
		if is_on_floor(): # add coyote time
			velocity.y = sqrt(-2 * get_gravity().y * gravity_scale * jump_height)

func move(input: Vector2, delta: float) -> void:
	var direction = (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	
	var target_delta = delta
	
	if direction != Vector3.ZERO:
		target_delta *= acceleration
		if !is_on_floor():
			target_delta *= air_control
	else:
		target_delta *= deceleration
		if !is_on_floor():
			target_delta *= air_break
	
	var new_velocity = velocity.move_toward(direction * speed, target_delta)
	new_velocity.y = velocity.y
	velocity = new_velocity

func hit_enemy() -> void:
	if not body:
		return
	
	var enemy_health = body.find_child("Health") as Health
	
	if enemy_health:
		attack_sound_effect.play()
		
		if enemy_health.current_health < attack_damage:
			body.velocity = (body.position - position) * 40 + Vector3.UP * 12
			camera3d.add_shake(0.75, 1)
		else:
			camera3d.add_shake(0.5, 0.35)
		
		enemy_health.take_damage(attack_damage, position)
		body = null
