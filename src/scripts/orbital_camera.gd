class_name OrbitalCamera
extends Node3D
## Câmera orbital em terceira pessoa.
## O rig fica no pivô (ombro do João) e orbita com o mouse; a Camera3D filha
## fica a `distance` metros para trás. Um sphere cast detecta geometria entre
## pivô e câmera, e a distância é amortecida para evitar saltos bruscos.
## A suavização usa tempo real, então continua responsiva na Zona de Névoa.

@export var target: Node3D
@export var target_offset := Vector3(0.0, 1.6, 0.0)

@export_group("Órbita")
@export var distance := 5.0
@export_range(-89.0, 0.0) var min_pitch_deg := -60.0
@export_range(0.0, 89.0) var max_pitch_deg := 35.0
@export var mouse_sensitivity := 0.0025
@export var invert_y := false

@export_group("Suavização")
@export var follow_smoothing := 12.0
## Velocidade ao aproximar por obstrução (rápida, para não atravessar paredes).
@export var zoom_in_speed := 18.0
## Velocidade ao voltar à distância padrão (lenta, para não "pular").
@export var zoom_out_speed := 4.0

@export_group("Colisão")
@export var collision_radius := 0.3
@export_flags_3d_physics var collision_mask := 1
@export var min_distance := 0.8

@onready var _camera: Camera3D = $Camera3D

var _yaw := 0.0
var _pitch := deg_to_rad(-15.0)
var _current_distance := 0.0
var _pivot := Vector3.ZERO
var _query := PhysicsShapeQueryParameters3D.new()


func _ready() -> void:
	top_level = true
	var sphere := SphereShape3D.new()
	sphere.radius = collision_radius
	_query.shape = sphere
	_query.collision_mask = collision_mask
	if target is CollisionObject3D:
		_query.exclude = [target.get_rid()]

	_current_distance = distance
	if target:
		_pivot = target.global_position + target_offset
		_yaw = target.global_rotation.y
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var y_sign := -1.0 if invert_y else 1.0
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity * y_sign
		_pitch = clampf(_pitch, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))
	elif event.is_action_pressed(&"ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# Roda no passo de física, em sincronia com o CharacterBody3D, para evitar jitter.
func _physics_process(delta: float) -> void:
	if not target:
		return
	var real_delta := delta / maxf(Engine.time_scale, 0.001)

	var follow_t := 1.0 - exp(-follow_smoothing * real_delta)
	_pivot = _pivot.lerp(target.global_position + target_offset, follow_t)
	global_transform = Transform3D(Basis.from_euler(Vector3(_pitch, _yaw, 0.0)), _pivot)

	var blocked_distance := _probe_distance()
	var speed := zoom_in_speed if blocked_distance < _current_distance else zoom_out_speed
	_current_distance = lerpf(_current_distance, blocked_distance, 1.0 - exp(-speed * real_delta))
	# Trava de segurança: a suavização nunca deixa a câmera afundar na parede.
	_current_distance = minf(_current_distance, blocked_distance + collision_radius * 0.5)

	_camera.position = Vector3(0.0, 0.0, _current_distance)


## Distância livre do pivô até a primeira geometria atrás da câmera.
func _probe_distance() -> float:
	var back := global_basis.z
	_query.transform = Transform3D(Basis.IDENTITY, _pivot)
	_query.motion = back * distance
	var result := get_world_3d().direct_space_state.cast_motion(_query)
	# cast_motion retorna [fração segura, fração insegura].
	return maxf(distance * result[0], min_distance)
