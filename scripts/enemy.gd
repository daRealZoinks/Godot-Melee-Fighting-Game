extends CharacterBody3D

class_name Enemy

@export var speed: float = 3.0

@export var min_time_to_change_point = 1
@export var max_time_to_change_point = 5

@onready var collision_shape_3d := $CollisionShape3D
@onready var navigation_agent := $NavigationAgent3D
@onready var vine_boom_audio_file := $VineBoomSound
@onready var chicken_audio_file := $ChickenSound
@onready var health := $Health

@onready var player = $"../CharacterBody3D"

var hatch_audio_file = preload("res://scenes/prefabs/hatch.tscn")
var rng = RandomNumberGenerator.new()

var timer: SceneTreeTimer

func _ready() -> void:
	change_navigation_point()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		if not health.dead:
			var next_path_position = navigation_agent.get_next_path_position()
			if not navigation_agent.is_navigation_finished():
				look_at(Vector3(next_path_position.x, position.y, next_path_position.z))
			var direction = (next_path_position - position).normalized()
			velocity = direction * speed

	move_and_slide()

func change_navigation_point():
	timer = await get_tree().create_timer(rng.randf_range(min_time_to_change_point, max_time_to_change_point)).timeout
	navigation_agent.target_position = player.position + Vector3(rng.randf(), 0, rng.randf()).normalized() * 4

func _on_navigation_agent_3d_navigation_finished() -> void:
	change_navigation_point()

func _on_health_health_changed(current_health: int, direction: Vector3) -> void:
	if timer:
		timer.cancel_free()
	look_at(Vector3(direction.x, position.y, direction.z))
	
	if current_health > 0:
		vine_boom_audio_file.play()
	navigation_agent.target_position = position

func _on_health_died() -> void:
	chicken_audio_file.play()
	await get_tree().create_timer(3.0).timeout
	get_tree().current_scene.add_child(hatch_audio_file.instantiate())
	queue_free()
