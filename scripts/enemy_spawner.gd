extends Node3D

@export var max_enemy_amount: int = 10
@export var range_from_the_player: float = 10

@export var player: PlayerController

const ENEMY_SCENE = preload("res://scenes/prefabs/enemy.tscn")

var rng: RandomNumberGenerator

var enemies: Array[Enemy]

func _ready() -> void:
	rng = RandomNumberGenerator.new()

func _process(delta: float) -> void:
	while enemies.size() < max_enemy_amount:
		spawn_enemy(get_position_around_player())
	enemies = enemies.filter(func(element): return element)

func spawn_enemy(spawn_position: Vector3) -> void:
	var enemy_instance = ENEMY_SCENE.instantiate() as Enemy
	enemy_instance.position = spawn_position
	add_child(enemy_instance)
	enemies.append(enemy_instance)

func get_position_around_player() -> Vector3:
	var direction = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized() * range_from_the_player
	
	var spawn_position = player.position + Vector3(direction.x, 0, direction.y)
	
	spawn_position.y = 0.5
	
	return spawn_position
