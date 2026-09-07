class_name RunCoin
extends Area2D

signal collected(coin: RunCoin)
signal recycled(coin: RunCoin)

enum Metal { GOLD, SILVER, COPPER }
var metal: Metal = Metal.GOLD
var worth: int = RunnerConfig.COIN_GOLD
var fills_energy: bool = true

const TEX_GOLD: Texture2D = preload("res://assets/obstacles/coin.png")
const TEX_SILVER: Texture2D = preload("res://assets/obstacles/coin_silver.png")
const TEX_COPPER: Texture2D = preload("res://assets/obstacles/coin_copper.png")
const GOLD_FRAMES: Array[Texture2D] = [
	preload("res://assets/obstacles/coin_anim/0.png"),
	preload("res://assets/obstacles/coin_anim/1.png"),
	preload("res://assets/obstacles/coin_anim/2.png"),
	preload("res://assets/obstacles/coin_anim/3.png"),
	preload("res://assets/obstacles/coin_anim/4.png"),
]

@onready var sprite: Sprite2D = %Sprite2D

var _speed: float = 0.0
var _active: bool = false
var magnet: bool = false
var _player: Player = null
var _spin_t: float = 0.0


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	body_entered.connect(_on_body_entered)


func setup_player(p: Player) -> void:
	_player = p


func set_speed(value: float) -> void:
	_speed = value


func spawn(pos: Vector2, speed: float, p_metal: Metal = Metal.GOLD, p_energy: bool = true) -> void:
	metal = p_metal
	fills_energy = p_energy
	if sprite == null:
		sprite = %Sprite2D
	match metal:
		Metal.GOLD:
			sprite.texture = TEX_GOLD
		Metal.SILVER:
			sprite.texture = TEX_SILVER
		Metal.COPPER:
			sprite.texture = TEX_COPPER
	match metal:
		Metal.GOLD:
			worth = RunnerConfig.COIN_GOLD
		Metal.SILVER:
			worth = RunnerConfig.COIN_SILVER
		Metal.COPPER:
			worth = RunnerConfig.COIN_COPPER
	sprite.scale = Vector2(0.038, 0.038)
	visible = false
	global_position = pos
	_speed = speed
	_active = true
	_spin_t = randf() * 0.72
	reset_physics_interpolation()
	visible = true
	monitoring = true


func reset() -> void:
	_active = false
	magnet = false
	visible = false
	monitoring = false
	position = Vector2(-200.0, 0.0)


func _physics_process(delta: float) -> void:
	if not _active:
		return
	if sprite != null:
		_spin_t += delta
		var u: float = fmod(_spin_t / 0.72, 1.0)
		if u < 0.0:
			u += 1.0
		if metal == Metal.GOLD:
			var last: int = GOLD_FRAMES.size() - 1
			var ping: float = u * 2.0
			if ping > 1.0:
				ping = 2.0 - ping
			ping = ping * ping * (3.0 - 2.0 * ping)
			var idx: int = clampi(int(round(ping * float(last))), 0, last)
			sprite.texture = GOLD_FRAMES[idx]
		var wobble: float = 1.0 + 0.06 * sin(_spin_t * 7.2 + global_position.x * 0.02)
		sprite.scale = Vector2(0.038 * wobble, 0.038 * wobble)
		sprite.rotation = sin(_spin_t * 5.4 + global_position.x * 0.01) * 0.12
	if magnet and _player != null and _player.alive:
		var to_p: Vector2 = _player.body_hitbox_center() - global_position
		global_position += to_p.normalized() * 720.0 * delta
	else:
		position.x -= _speed * delta
	if position.x < -120.0:
		_active = false
		recycled.emit(self)


func _on_body_entered(body: Node2D) -> void:
	if not _active:
		return
	if body is Player:
		_active = false
		collected.emit(self)
