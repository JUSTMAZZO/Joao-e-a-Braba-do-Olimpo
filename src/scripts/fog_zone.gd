class_name FogZone
extends Area3D
## Zona de Névoa (bullet time): enquanto o jogador está dentro, o
## Engine.time_scale transiciona para `slow_time_scale`. Suporta zonas
## sobrepostas — o tempo só volta ao normal ao sair da última.

signal bullet_time_started
signal bullet_time_ended

@export_range(0.05, 1.0) var slow_time_scale := 0.4
## Duração da transição em segundos reais (não afetada pelo time_scale).
@export var transition_time := 0.25
@export var player_group := &"player"

## Quantas zonas contêm o jogador agora (compartilhado entre instâncias).
static var _occupied_zones := 0
static var _tween: Tween

var _player_inside := false


func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _exit_tree() -> void:
	# Se a zona for removida com o jogador dentro, não deixa o jogo preso em câmera lenta.
	if _player_inside:
		_player_inside = false
		_occupied_zones = maxi(_occupied_zones - 1, 0)
		if _occupied_zones == 0:
			if _tween and _tween.is_valid():
				_tween.kill()
			Engine.time_scale = 1.0


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group(player_group):
		return
	_player_inside = true
	_occupied_zones += 1
	if _occupied_zones == 1:
		_blend_time_scale(slow_time_scale)
		bullet_time_started.emit()


func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group(player_group) or not _player_inside:
		return
	_player_inside = false
	_occupied_zones = maxi(_occupied_zones - 1, 0)
	if _occupied_zones == 0:
		_blend_time_scale(1.0)
		bullet_time_ended.emit()


func _blend_time_scale(to: float) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	# Requer Godot 4.3+: sem isso o próprio tween desaceleraria junto com o jogo.
	_tween = create_tween().set_ignore_time_scale(true)
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(_set_time_scale, Engine.time_scale, to, transition_time)


static func _set_time_scale(value: float) -> void:
	Engine.time_scale = value
