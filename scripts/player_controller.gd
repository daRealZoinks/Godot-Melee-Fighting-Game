extends CharacterBody3D
class_name PlayerController

@export var state_machine: StateMachine
@export var mouse_look: MouseLook

func _input(event: InputEvent) -> void:
	mouse_look.input(event)
	
	if event.is_action_pressed("attack"):
		state_machine.transition_to("AttackState")

func _physics_process(delta: float) -> void:
	state_machine.physics_process(delta)
