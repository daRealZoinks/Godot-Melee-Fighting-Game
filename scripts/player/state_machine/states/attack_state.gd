extends PlayerState









@export var neck: Node3D
@export var attack_sound_effect: AudioStreamPlayer
@export var area3D: Area3D
@export var cameraShake: Node3D

const TIME_TO_ATTACK: float = 0.15









@export var animation_player: AnimationPlayer
@export var combo_animations: Dictionary[String, float] = {"punch_right": 30, "punch_left": 30}
@export var finishing_animation: Dictionary[String, float] = {"heavy_finisher_right": 40}
@export var combo_reset_time: float = 0.8

var combo_index: int = 0
var input_buffered: bool = false

func enter() -> void:
	player.velocity = Vector3.ZERO
	execute_attack()

func execute_attack() -> void:
	input_buffered = false
	var animation_name = combo_animations.keys()[combo_index]
	animation_player.play(animation_name)

func exit() -> void:
	pass

func physics_process(_delta: float) -> void:
	pass

func unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		input_buffered = true

func get_into_position_for_attack() -> void:
	var enemy = (get_parent().target_body as Enemy)
	
	if enemy:
		var capsule_shape_3d: CapsuleShape3D = (enemy.collision_shape_3d.shape as CapsuleShape3D)

		var target_position = enemy.position - (enemy.position - Vector3(player.position.x, enemy.position.y, player.position.z)).normalized()
		var target_look_at = enemy.position + Vector3.UP * (capsule_shape_3d.height / 2 - capsule_shape_3d.radius)

		var tween = get_tree().create_tween().set_parallel(true)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(player, "position", target_position, TIME_TO_ATTACK)
		tween.tween_method(func(value): player.rotation.y = value, player.rotation.y, (player.transform.looking_at(Vector3(target_look_at.x, player.position.y, target_look_at.z))).basis.get_euler().y, TIME_TO_ATTACK)
		tween.tween_method(func(value): neck.rotation.x = value, neck.rotation.x, (neck.transform.looking_at(target_look_at)).basis.get_euler().x, TIME_TO_ATTACK)

func hit_enemy() -> void:
	if not get_parent().target_body:
		return
	
	var enemy_health = get_parent().target_body.find_child("Health") as Health
	
	if enemy_health:
		attack_sound_effect.play()
		
		if enemy_health.current_health < combo_animations["punch_right"]:
			get_parent().target_body.velocity = (get_parent().target_body.position - player.position) * 40 + Vector3.UP * 12
			cameraShake.add_shake(0.75, 1)
		else:
			cameraShake.add_shake(0.5, 0.35)
		
		enemy_health.take_damage(combo_animations["punch_right"], player.position)
	get_parent().target_body = null

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name in combo_animations:
		combo_index = (combo_index + 1) % combo_animations.size()
		if input_buffered:
			execute_attack()
		else:
			get_parent().transition_to("LocomotionState")
