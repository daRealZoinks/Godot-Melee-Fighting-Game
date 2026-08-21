extends Node3D

@export_group("Shake Properties")
@export var max_offset: Vector3 = Vector3(0.5, 0.5, 0.2)
@export var max_rotation_deg: Vector3 = Vector3(3.0, 3.0, 5.0)

@export_group("Noise Settings")
@export var noise_speed: float = 30.0

var magnitude: float = 0.0

var _noise: FastNoiseLite = FastNoiseLite.new()
var _noise_time: float = 0.0
var _shake_tween: Tween
var _base_transform: Transform3D

func _ready() -> void:
	_base_transform = transform
	
	_noise.seed = randi()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

func _process(delta: float) -> void:
	if magnitude <= 0.0:
		transform = _base_transform
		return
		
	_noise_time += delta * noise_speed
	
	var nx := _noise.get_noise_2d(_noise_time, 0.0)
	var ny := _noise.get_noise_2d(_noise_time, 100.0)
	var nz := _noise.get_noise_2d(_noise_time, 200.0)
	var nr := _noise.get_noise_2d(_noise_time, 300.0)
	
	var factor := magnitude * magnitude
	
	var offset := Vector3(
		max_offset.x * nx * factor,
		max_offset.y * ny * factor,
		max_offset.z * nz * factor
	)
	
	var rot_x := deg_to_rad(max_rotation_deg.x) * nx * factor
	var rot_y := deg_to_rad(max_rotation_deg.y) * ny * factor
	var rot_z := deg_to_rad(max_rotation_deg.z) * nr * factor
	
	transform.origin = _base_transform.origin + offset
	transform.basis = _base_transform.basis * Basis.from_euler(Vector3(rot_x, rot_y, rot_z))

func add_shake(intensity: float, duration: float = 0.5) -> void:
	magnitude = max(magnitude, clampf(intensity, 0.0, 1.0))
	_noise.frequency = 1.0
	
	if _shake_tween and _shake_tween.is_running():
		_shake_tween.kill()
		
	_shake_tween = create_tween().set_parallel(true)
	_shake_tween.set_ease(Tween.EASE_OUT)
	_shake_tween.set_trans(Tween.TRANS_QUAD)
	_shake_tween.tween_property(self, "magnitude", 0.0, duration)
	_shake_tween.tween_property(_noise, "frequency", 0.0, duration)
