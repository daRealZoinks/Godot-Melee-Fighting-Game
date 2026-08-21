extends Node
class_name StateMachine

@export var initial_state: PlayerState

var current_state: PlayerState
var states: Dictionary = {}
var target_body: Node3D

func _ready() -> void:
	await owner.ready
	
	for child in get_children():
		if child is PlayerState:
			states[child.name] = child
			child.player = owner as PlayerController
			
	if initial_state:
		current_state = initial_state
		current_state.enter()

func physics_process(delta: float) -> void:
	current_state.physics_process(delta)

func unhandled_input(event: InputEvent) -> void:
	current_state.unhandled_input(event)

func transition_to(target_state_name: String, body: Node3D = null) -> void:
	if not states.has(target_state_name):
		return
	
	target_body = body
	current_state.exit()
	current_state = states[target_state_name]
	current_state.enter()
