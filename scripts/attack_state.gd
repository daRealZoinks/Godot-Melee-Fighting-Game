extends PlayerState

@export var animation_player: AnimationPlayer

@export var attack_damage: float = 30.0

@export var neck: Node3D
@export var attack_sound_effect: AudioStreamPlayer
@export var area3D: Area3D
@export var cameraShake: Node3D

const time_to_attack = 0.15

var body: Node3D

func enter() -> void:
	animation_player.play("attack")
	get_closest_hittable_body()

func exit() -> void:
	pass

func physics_process(_delta: float) -> void:
	player.move_and_slide()

func unhandled_input(_event: InputEvent) -> void:
	pass


func get_closest_hittable_body():
	var bodies: Array[Node3D] = area3D.get_overlapping_bodies()
	bodies = bodies.filter(func(element): return element.find_child("Health") and element != self)
	bodies.sort_custom(func(a, b): return player.position.distance_to(a.position) < player.position.distance_to(b.position))
	if bodies.is_empty():
		return
	
	body = bodies[0]
	
	var enemy = (body as Enemy)
	var capsule_shape_3d: CapsuleShape3D = (enemy.collision_shape_3d.shape as CapsuleShape3D)
	
	var target_position = body.position - (body.position - Vector3(player.position.x, body.position.y, player.position.z)).normalized()
	var target_look_at = body.position + Vector3.UP * (capsule_shape_3d.height / 2 - capsule_shape_3d.radius)
	
	get_into_position_for_attack(target_position, target_look_at)
	
func get_into_position_for_attack(target_position: Vector3, target_look_at: Vector3) -> void:
	player.velocity = Vector3.ZERO
	var tween = get_tree().create_tween().set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(player, "position", target_position, time_to_attack)
	tween.tween_method(func(value): player.rotation.y = value, player.rotation.y, (player.transform.looking_at(Vector3(target_look_at.x, player.position.y, target_look_at.z))).basis.get_euler().y, time_to_attack)
	tween.tween_method(func(value): neck.rotation.x = value, neck.rotation.x, (neck.transform.looking_at(target_look_at)).basis.get_euler().x, time_to_attack)


func hit_enemy() -> void:
	if not body:
		return
	
	var enemy_health = body.find_child("Health") as Health
	
	if enemy_health:
		attack_sound_effect.play()
		
		if enemy_health.current_health < attack_damage:
			body.velocity = (body.position - player.position) * 40 + Vector3.UP * 12
			cameraShake.add_shake(0.75, 1)
		else:
			cameraShake.add_shake(0.5, 0.35)
		
		enemy_health.take_damage(attack_damage, player.position)
		body = null


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "attack":
		(get_parent() as StateMachine).transition_to("LocomotionState")
