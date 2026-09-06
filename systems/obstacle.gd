class_name Obstacle
extends Area2D

signal recycled(obstacle: Obstacle)
signal ring_cleared

## 悬挂矮障下沿离地高度。下滑盒 46，站立盒 86：64 让蹲着过去、跑着撞上。
const HANG_CLEAR: float = 64.0
## barrier.png 不透明区域大约占贴图上半 48%。
const BARRIER_OPAQUE_BOT: float = 0.48

enum Kind { BOOKS, CHEST, SHELF, STAR, RING, SPIKES, BARRIER, CLIFF }

@onready var sprite: Sprite2D = %Sprite2D
@onready var collision: CollisionShape2D = %CollisionShape2D

var kind: Kind = Kind.BOOKS
var half_width: float = 40.0
var pass_radius: float = 40.0
var _speed: float = 0.0
var _active: bool = false
var following_created: bool = false
var gap: float = 320.0
var frozen: bool = false
var ground_y: float = 600.0
var _flash_tw: Tween


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	body_entered.connect(_on_body_entered)


func configure(p_kind: Kind, tex: Texture2D, p_scale: float, p_ground_y: float, air_y: float) -> void:
	kind = p_kind
	ground_y = p_ground_y
	sprite.texture = tex
	sprite.scale = Vector2(p_scale, p_scale)
	var tex_size: Vector2 = tex.get_size() * p_scale
	half_width = tex_size.x * 0.5
	var hit: Vector2 = _tight_hit(p_kind, tex_size)
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = hit
	collision.shape = shape
	sprite.centered = true
	sprite.offset = Vector2.ZERO
	if p_kind == Kind.STAR:
		position.y = air_y
		sprite.position = Vector2.ZERO
		collision.position = Vector2.ZERO
	elif p_kind == Kind.RING:
		sprite.offset = Vector2.ZERO
		# 洞心对齐跳跃身体，支架坐在地面。
		position.y = p_ground_y - 158.0
		sprite.position = Vector2(0.0, 158.0 - tex_size.y * 0.5)
		collision.position = Vector2.ZERO
		pass_radius = maxf(tex_size.y * 0.22, 52.0)
	elif p_kind == Kind.BARRIER:
		position.y = p_ground_y
		var opaque_bot_local: float = tex_size.y * (BARRIER_OPAQUE_BOT - 0.5)
		sprite.position = Vector2(0.0, -HANG_CLEAR - opaque_bot_local)
		collision.position = Vector2(0.0, -(HANG_CLEAR + hit.y * 0.5))
	elif p_kind == Kind.CLIFF:
		half_width = 68.0
		position.y = p_ground_y
		sprite.position = Vector2(0.0, 28.0)
		collision.position = Vector2(0.0, -6.0)
		shape.size = Vector2(136.0, 40.0)
		collision.shape = shape
	else:
		position.y = p_ground_y
		sprite.position = Vector2(0.0, -tex_size.y * 0.5)
		collision.position = Vector2(0.0, -hit.y * 0.5 - 2.0)


func _tight_hit(p_kind: Kind, tex_size: Vector2) -> Vector2:
	match p_kind:
		Kind.BOOKS:
			return Vector2(tex_size.x * 0.42, tex_size.y * 0.52)
		Kind.CHEST:
			return Vector2(tex_size.x * 0.40, tex_size.y * 0.52)
		Kind.SHELF:
			return Vector2(tex_size.x * 0.42, tex_size.y * 0.70)
		Kind.STAR:
			return Vector2(tex_size.x * 0.34, tex_size.y * 0.34)
		Kind.SPIKES:
			return Vector2(tex_size.x * 0.58, tex_size.y * 0.42)
		Kind.BARRIER:
			return Vector2(tex_size.x * 0.70, tex_size.y * 0.34)
		Kind.RING:
			return Vector2(tex_size.x * 0.62, tex_size.y * 0.70)
		Kind.CLIFF:
			return Vector2(136.0, 40.0)
		_:
			return tex_size * 0.4


func set_speed(value: float) -> void:
	_speed = value


func spawn(x: float, speed: float, p_gap: float) -> void:
	visible = false
	position.x = x
	_speed = speed
	gap = p_gap
	_active = true
	frozen = false
	following_created = false
	reset_physics_interpolation()
	visible = true
	monitoring = true
	monitorable = true


func reset() -> void:
	_active = false
	frozen = false
	_speed = 0.0
	following_created = false
	visible = false
	monitoring = false
	modulate = Color.WHITE
	if _flash_tw != null:
		_flash_tw.kill()
		_flash_tw = null
	position = Vector2(-400.0, 0.0)


func right_edge() -> float:
	return position.x + half_width


func avoid_rect() -> Rect2:
	return visual_rect()


func visual_rect() -> Rect2:
	if sprite.texture == null:
		return Rect2(global_position, Vector2(48.0, 48.0))
	var sz: Vector2 = sprite.texture.get_size() * sprite.scale.abs()
	var center: Vector2 = sprite.global_position + sprite.offset * sprite.scale
	return Rect2(center - sz * 0.5, sz)


func hit_point(from: Vector2) -> Vector2:
	var shape: RectangleShape2D = collision.shape as RectangleShape2D
	if shape == null:
		return collision.global_position
	var half: Vector2 = shape.size * 0.5
	var c: Vector2 = collision.global_position
	return Vector2(clampf(from.x, c.x - half.x, c.x + half.x), clampf(from.y, c.y - half.y, c.y + half.y))


func _physics_process(delta: float) -> void:
	if not _active or frozen:
		return
	position.x -= _speed * delta
	if position.x < -280.0:
		_active = false
		recycled.emit(self)


func _on_body_entered(body: Node2D) -> void:
	if not _active:
		return
	if body is Player:
		var p: Player = body as Player
		if kind == Kind.RING:
			var dy: float = absf(p.body_hitbox_center().y - global_position.y)
			if dy < pass_radius:
				_flash_pass()
				ring_cleared.emit()
				monitoring = false
				return
		if kind == Kind.CLIFF:
			if p.position.y < ground_y - 42.0:
				return
		p.kill(hit_point(p.body_hitbox_center()))


func _flash_pass() -> void:
	if _flash_tw != null:
		_flash_tw.kill()
	modulate = Color(1.45, 1.28, 0.55, 1.0)
	_flash_tw = create_tween()
	_flash_tw.tween_property(self, "modulate", Color.WHITE, 0.22)
