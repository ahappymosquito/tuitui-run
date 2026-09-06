class_name Player
extends CharacterBody2D

signal jumped
signal hit(point: Vector2)

enum State { RUN, JUMP, FALL, SLIDE, GLIDE, SPRINT, SUPER, DEAD }

@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var col_run: CollisionShape2D = %ColRun
@onready var col_slide: CollisionShape2D = %ColSlide

var config: RunnerConfig
var def: CharacterDef
var alive: bool = true
var started: bool = false
var invincible: bool = false
var has_shield: bool = false
var flying: bool = false
var jumps_used: int = 0
var start_sprint_sec: float = 0.0

var _state: State = State.RUN
var _sliding: bool = false
var _speed_drop: bool = false
var _flash: float = 0.0
var _coyote: float = 0.0
var _jump_buf: float = 0.0
var _max_jumps: int = 2
var _can_glide: bool = false
var _glide_scale: float = 0.35
var _base_scale: Vector2 = Vector2(0.22, 0.22)
var _was_air: bool = false
var _juice: Tween


func jump_limit() -> int:
	return _max_jumps


func setup(p_config: RunnerConfig) -> void:
	config = p_config
	_pin_x()
	position = Vector2(config.player_x, config.ground_y)
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	if not get_viewport().size_changed.is_connected(_pin_x):
		get_viewport().size_changed.connect(_pin_x)
	reset()


func _pin_x() -> void:
	if config == null:
		return
	var w: float = get_viewport_rect().size.x
	if w > 1.0:
		config.player_x = w * 0.22
	position.x = config.player_x


func _wants_slide() -> bool:
	return Input.is_action_pressed("slide") or Input.is_action_pressed("duck")


func apply_character(p_def: CharacterDef) -> void:
	def = p_def
	if def == null:
		return
	_max_jumps = def.max_jumps
	_can_glide = def.can_glide
	_glide_scale = def.glide_gravity_scale
	start_sprint_sec = def.start_sprint_sec
	if sprite != null:
		if def.sprite_frames != null:
			sprite.sprite_frames = def.sprite_frames
		sprite.offset = def.sprite_offset
		_base_scale = def.sprite_scale
		sprite.scale = _base_scale
	_set_hitbox(col_run, def.hitbox_run, Vector2(14, -def.hitbox_run.y * 0.5))
	_set_hitbox(col_slide, def.hitbox_slide, Vector2(22, -def.hitbox_slide.y * 0.5))
	modulate = Color.WHITE
	_play("idle")


func _set_hitbox(col: CollisionShape2D, size: Vector2, pos: Vector2) -> void:
	if col == null:
		return
	var src: RectangleShape2D = col.shape as RectangleShape2D
	var shape: RectangleShape2D
	if src == null:
		shape = RectangleShape2D.new()
	else:
		shape = src.duplicate() as RectangleShape2D
	shape.size = size
	col.shape = shape
	col.position = pos


func reset() -> void:
	alive = true
	started = false
	invincible = false
	flying = false
	_sliding = false
	_speed_drop = false
	jumps_used = 0
	_state = State.RUN
	_was_air = false
	_flash = 0.0
	_coyote = 0.0
	_jump_buf = 0.0
	velocity = Vector2.ZERO
	modulate = Color.WHITE
	rotation = 0.0
	position = Vector2(config.player_x, config.ground_y)
	_apply_slide(false)
	_play("idle")
	reset_physics_interpolation()


func begin_run() -> void:
	if not alive:
		return
	started = true
	if flying:
		_play("run")
		return
	_state = State.RUN
	_play("run")


func kill(point: Vector2) -> void:
	if not alive:
		return
	if invincible:
		return
	if has_shield:
		has_shield = false
		invincible = true
		_flash = 0.45
		var t: SceneTreeTimer = get_tree().create_timer(0.8)
		t.timeout.connect(func () -> void:
			invincible = false
			_flash = 0.0
			modulate = Color.WHITE
		)
		return
	alive = false
	_state = State.DEAD
	_speed_drop = false
	_apply_slide(false)
	velocity = Vector2(-80.0, -220.0)
	_play("dead")
	hit.emit(point)


func body_hitbox_center() -> Vector2:
	var col: CollisionShape2D = col_slide if _sliding else col_run
	return col.global_position


func set_flying(on: bool) -> void:
	flying = on
	if on:
		_state = State.SPRINT
		position.y = config.ground_y - config.sprint_lift
		velocity = Vector2.ZERO
		_apply_slide(false)
		_play("run")
		reset_physics_interpolation()
	elif velocity.y == 0.0:
		velocity.y = 120.0
		_state = State.FALL


func _physics_process(delta: float) -> void:
	if config == null:
		return
	if _flash > 0.0:
		_flash = maxf(_flash - delta, 0.0)
		if _flash <= 0.0:
			modulate = Color.WHITE
		else:
			var pulse: float = 0.55 + 0.45 * absf(sin(_flash * 24.0))
			modulate = Color(1.0, pulse, pulse, 1.0)
	if not alive:
		velocity.y += config.gravity * delta
		move_and_slide()
		position.x = clampf(position.x, 40.0, config.player_x)
		return

	position.x = config.player_x
	if flying:
		position.y = config.ground_y - config.sprint_lift
		velocity = Vector2.ZERO
		_coyote = 0.0
		_jump_buf = 0.0
		_play("run")
		move_and_slide()
		position.x = config.player_x
		return
	var want_slide: bool = _wants_slide()
	if Input.is_action_just_pressed("jump"):
		if not (want_slide and is_on_floor()):
			_jump_buf = config.jump_buffer

	if not is_on_floor():
		_coyote = maxf(_coyote - delta, 0.0)
		var g: float = config.gravity
		var gliding: bool = _can_glide and want_slide and jumps_used >= _max_jumps
		if gliding:
			g *= _glide_scale
			_state = State.GLIDE
		elif _speed_drop:
			g *= config.speed_drop_coeff
		velocity.y += g * delta
		if want_slide and velocity.y < 0.0 and not gliding:
			velocity.y = minf(velocity.y, config.drop_velocity)
			_speed_drop = true
		if velocity.y > 0.0 and not gliding:
			_state = State.FALL
			_play("fall")
		elif velocity.y <= 0.0 and _state != State.GLIDE:
			_state = State.JUMP
		_was_air = true
		if not started:
			started = true
	else:
		if _was_air and started and alive:
			_squash_land()
		_was_air = false
		_coyote = config.coyote_time
		_speed_drop = false
		jumps_used = 0
		if velocity.y > 0.0:
			velocity.y = 0.0
		_apply_slide(want_slide and started)
		if started and _sliding:
			_state = State.SLIDE
			_play("slide")
		elif started and not _sliding:
			_state = State.RUN
			_play("run")

	if _jump_buf > 0.0:
		_jump_buf = maxf(_jump_buf - delta, 0.0)
		_try_jump()

	move_and_slide()
	position.x = config.player_x


func _try_jump() -> void:
	if is_on_floor() and _wants_slide():
		return
	var grounded: bool = is_on_floor() or _coyote > 0.0
	if grounded:
		jumps_used = 0
	elif jumps_used >= _max_jumps:
		return
	if (not grounded) and jumps_used <= 0:
		return
	if jumps_used >= _max_jumps:
		return
	_apply_slide(false)
	velocity.y = config.jump_velocity
	jumps_used += 1
	_state = State.JUMP
	_speed_drop = false
	_coyote = 0.0
	_jump_buf = 0.0
	_play("jump")
	_squash_jump()
	if not started:
		started = true
	jumped.emit()


func _squash_jump() -> void:
	_squash_to(Vector2(_base_scale.x * 0.86, _base_scale.y * 1.18), 0.11)


func _squash_land() -> void:
	_squash_to(Vector2(_base_scale.x * 1.14, _base_scale.y * 0.78), 0.13)


func _squash_to(to: Vector2, dur: float) -> void:
	if sprite == null:
		return
	if _juice != null:
		_juice.kill()
	_juice = create_tween()
	_juice.set_trans(Tween.TRANS_BACK)
	_juice.set_ease(Tween.EASE_OUT)
	_juice.tween_property(sprite, "scale", to, dur * 0.38)
	_juice.tween_property(sprite, "scale", _base_scale, dur * 0.62)


func _apply_slide(value: bool) -> void:
	_sliding = value
	col_run.disabled = value
	col_slide.disabled = not value


func _play(anim: StringName) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	var use: StringName = anim
	if not sprite.sprite_frames.has_animation(use):
		if use == &"slide" and sprite.sprite_frames.has_animation(&"duck"):
			use = &"duck"
		else:
			return
	if sprite.animation == use:
		return
	sprite.play(use)
