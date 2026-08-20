extends Node
class_name StateMachine

@export var initial_state: PlayerState

var current_state: PlayerState
var states: Dictionary = {}

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

func _unhandled_input(event: InputEvent) -> void:
	current_state.unhandled_input(event)

func transition_to(target_state_name: String) -> void:
	if not states.has(target_state_name):
		return
	
	current_state.exit()
	current_state = states[target_state_name]
	current_state.enter()
