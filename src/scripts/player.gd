class_name Player
extends CharacterBody3D
## João — controlador em terceira pessoa (protótipo greybox).
## Movimento relativo à câmera, corrida, salto com altura variável,
## coyote time e jump buffer.

@export_group("Movimento")
@export var walk_speed := 5.0
@export var sprint_speed := 9.0
@export var acceleration := 40.0
@export var deceleration := 50.0
## Fração da aceleração disponível no ar (0 = sem controle aéreo).
@export_range(0.0, 1.0) var air_control := 0.35
@export var turn_speed := 12.0

@export_group("Salto")
@export var jump_height := 2.2
## Tempo (s) até o ápice do salto. Gravidade e impulso são derivados disso.
@export var time_to_apex := 0.38
@export var fall_gravity_multiplier := 1.8
## Multiplica a velocidade vertical ao soltar o botão cedo (salto curto).
@export_range(0.0, 1.0) var jump_cut_multiplier := 0.45
@export var coyote_time := 0.12
@export var jump_buffer_time := 0.12
@export var max_fall_speed := 30.0

@export_group("Referências")
## Rig da câmera orbital; define o "para frente" do input.
@export var camera_rig: Node3D
## Nó com a malha do João; gira para a direção do movimento.
@export var visual: Node3D
## Se vazio, procura o primeiro AnimationPlayer dentro de `visual`.
@export var animation_player: AnimationPlayer

@export_group("Animação")
@export var idle_animation := &"idle"
@export var run_animation := &"run"
## Osso que carrega o deslocamento (root motion) nas animações do Mixamo.
@export var root_bone := &"Hips"
## Velocidade horizontal (m/s) a partir da qual o João passa de idle para corrida.
@export var move_threshold := 0.3
@export var blend_time := 0.2

const DEFAULT_KEYS := {
	&"move_forward": [KEY_W, KEY_UP],
	&"move_back": [KEY_S, KEY_DOWN],
	&"move_left": [KEY_A, KEY_LEFT],
	&"move_right": [KEY_D, KEY_RIGHT],
	&"jump": [KEY_SPACE],
	&"sprint": [KEY_SHIFT],
}

var _gravity: float
var _jump_velocity: float
var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
## Quantos m/s a animação de corrida percorre em ritmo 1.0 (medido do root motion).
var _run_anim_speed := 0.0


func _ready() -> void:
	add_to_group(&"player")
	_ensure_input_actions()
	_gravity = 2.0 * jump_height / (time_to_apex * time_to_apex)
	_jump_velocity = _gravity * time_to_apex
	_setup_animations()


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_apply_gravity(delta)
	_handle_jump()
	_apply_horizontal_movement(delta)
	move_and_slide()
	_rotate_visual(delta)
	_update_animation()


func _update_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer -= delta

	if Input.is_action_just_pressed(&"jump"):
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer -= delta


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	var g := _gravity
	if velocity.y < 0.0:
		g *= fall_gravity_multiplier
	velocity.y = maxf(velocity.y - g * delta, -max_fall_speed)


func _handle_jump() -> void:
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = _jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0

	if Input.is_action_just_released(&"jump") and velocity.y > 0.0:
		velocity.y *= jump_cut_multiplier


func _apply_horizontal_movement(delta: float) -> void:
	var input := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	var direction := _camera_relative(input)
	var speed := sprint_speed if Input.is_action_pressed(&"sprint") else walk_speed
	var target := direction * speed

	var rate := acceleration if direction != Vector3.ZERO else deceleration
	if not is_on_floor():
		rate *= air_control

	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(target, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


func _camera_relative(input: Vector2) -> Vector3:
	var cam_basis := global_basis
	if camera_rig:
		cam_basis = camera_rig.global_basis
	elif get_viewport().get_camera_3d():
		cam_basis = get_viewport().get_camera_3d().global_basis

	var forward := Vector3(-cam_basis.z.x, 0.0, -cam_basis.z.z).normalized()
	var right := Vector3(cam_basis.x.x, 0.0, cam_basis.x.z).normalized()
	# input.y é negativo para frente (W).
	return right * input.x - forward * input.y


func _rotate_visual(delta: float) -> void:
	if not visual:
		return
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	if flat.length_squared() < 0.01:
		return
	# Godot usa -Z como "frente".
	var target_yaw := atan2(-flat.x, -flat.z)
	visual.rotation.y = lerp_angle(visual.rotation.y, target_yaw, 1.0 - exp(-turn_speed * delta))


func _setup_animations() -> void:
	if not animation_player and visual:
		animation_player = visual.find_child("AnimationPlayer", true, false)
	if not animation_player:
		return
	for anim_name in [idle_animation, run_animation]:
		if not animation_player.has_animation(anim_name):
			push_warning("Animação '%s' não encontrada em %s" % [anim_name, animation_player.get_path()])
			continue
		var anim := animation_player.get_animation(anim_name)
		anim.loop_mode = Animation.LOOP_LINEAR
		var travelled := _make_in_place(anim)
		if anim_name == run_animation:
			_run_anim_speed = travelled / anim.length
	animation_player.play(idle_animation)


## Remove o deslocamento horizontal do osso raiz (o CharacterBody3D é quem move
## o João) e devolve a distância que a animação percorria em um ciclo.
## O recurso é compartilhado entre instâncias, então só é processado uma vez.
func _make_in_place(anim: Animation) -> float:
	if anim.has_meta(&"root_travel"):
		return anim.get_meta(&"root_travel")
	var travelled := _strip_root_motion(anim)
	anim.set_meta(&"root_travel", travelled)
	return travelled


func _strip_root_motion(anim: Animation) -> float:
	for track in anim.get_track_count():
		if anim.track_get_type(track) != Animation.TYPE_POSITION_3D:
			continue
		if anim.track_get_path(track).get_concatenated_subnames() != String(root_bone):
			continue
		var key_count := anim.track_get_key_count(track)
		if key_count == 0:
			return 0.0
		var start: Vector3 = anim.track_get_key_value(track, 0)
		var end: Vector3 = anim.track_get_key_value(track, key_count - 1)
		for key in key_count:
			var pos: Vector3 = anim.track_get_key_value(track, key)
			anim.track_set_key_value(track, key, Vector3(start.x, pos.y, start.z))
		return Vector2(end.x - start.x, end.z - start.z).length()
	return 0.0


func _update_animation() -> void:
	if not animation_player:
		return
	var speed := Vector2(velocity.x, velocity.z).length()
	if speed > move_threshold:
		if animation_player.current_animation != run_animation:
			animation_player.play(run_animation, blend_time)
		# Ajusta o ritmo das passadas à velocidade real para os pés não deslizarem.
		if _run_anim_speed > 0.0:
			animation_player.speed_scale = speed / _run_anim_speed
	else:
		if animation_player.current_animation != idle_animation:
			animation_player.play(idle_animation, blend_time)
		animation_player.speed_scale = 1.0


## Registra os binds padrão caso ainda não existam no Input Map do projeto,
## para a cena greybox rodar sem configuração manual.
static func _ensure_input_actions() -> void:
	for action: StringName in DEFAULT_KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: int in DEFAULT_KEYS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
