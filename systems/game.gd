class_name Game
extends Node2D

@onready var player: Player = %Player
@onready var spawner: ObstacleSpawner = %ObstacleSpawner
@onready var ground: GroundScroll = %GroundVisual
@onready var sky_night: Parallax2D = %SkyNight
@onready var sky_day: Parallax2D = %SkyDay
@onready var curtains: Parallax2D = %Curtains
@onready var clouds: Parallax2D = %Clouds
@onready var hud: HUD = %HUD
@onready var audio_jump: AudioStreamPlayer = %AudioJump
@onready var audio_hit: AudioStreamPlayer = %AudioHit
@onready var audio_score: AudioStreamPlayer = %AudioScore
@onready var impact: Sprite2D = %Impact
@onready var shockwave: Sprite2D = %Shockwave
@onready var super_sky: Sprite2D = %SuperSky

const TEX_BERRY_SKY: Texture2D = preload("res://assets/backgrounds/berry_sky.png")
const TEX_BERRY_GROUND: Texture2D = preload("res://assets/backgrounds/berry_ground.png")
var _tex_sky0: Texture2D
var _tex_ground0: Texture2D

var config: RunnerConfig = RunnerConfig.new()
var speed: float = 0.0
var distance: float = 0.0
var score: int = 0
var run_coins: int = 0
var energy: float = 0.0
var running: bool = false
var inverted: bool = false
var super_left: float = 0.0
var paused: bool = false
var _last_hundred: int = 0
var _impact_t: float = 0.0
var _magnet_t: float = 0.0
var _rain_t: float = 0.0
var _sprint_t: float = 0.0
var rings: int = 0
var coin_value: int = 0
var _pet_t: float = 0.0
var _super_arm: float = 0.0
var _run_t: float = 0.0
var _exit_grace: float = 0.0
var _run_gen: int = 0


func _ready() -> void:
	player.setup(config)
	player.apply_character(Catalog.equipped_def())
	spawner.setup(config, player)
	player.jumped.connect(_on_jumped)
	player.hit.connect(_on_hit)
	spawner.coin_picked.connect(_on_coin)
	spawner.ring_bonus.connect(_on_ring)
	hud.restart_pressed.connect(_back_home)
	hud.replay_pressed.connect(_replay)
	hud.resume_pressed.connect(_set_paused.bind(false))
	hud.pause_pressed.connect(_on_pause_button)
	hud.set_score(0, Save.best_score(), 0)
	hud.set_energy(0.0, config.energy_max)
	hud.show_intro()
	_tex_sky0 = sky_night.get_node("Sprite2D").texture
	_tex_ground0 = ground.texture
	_apply_world()
	_apply_invert(false)
	speed = 0.0
	_apply_loadout()
	_sync_scroll()
	impact.visible = false
	shockwave.visible = false
	super_sky.visible = false
	spawner.start()
	spawner.set_moving_speed(0.0)
	audio_jump.bus = "SFX"
	audio_hit.bus = "SFX"
	audio_score.bus = "SFX"
	if not hud.enter_done.is_connected(_kickoff_run):
		hud.enter_done.connect(_kickoff_run)
	if _is_headless() or not RunEnter.pending:
		_kickoff_run()
	else:
		RunEnter.pending = false
		player.set_physics_process(false)
		hud.cover_and_reveal()
		var failsafe: SceneTreeTimer = get_tree().create_timer(1.5)
		failsafe.timeout.connect(func () -> void:
			if not running and player.alive:
				_kickoff_run()
		)


func _apply_loadout() -> void:
	player.has_shield = false
	_magnet_t = 0.0
	match Economy.equipped:
		"shield":
			player.has_shield = true
		"magnet":
			_magnet_t = 8.0
	Economy.equipped = ""
	if player.start_sprint_sec > 0.0:
		_begin_sprint(player.start_sprint_sec)


func _physics_process(delta: float) -> void:
	if paused:
		return
	if _impact_t > 0.0:
		_impact_t -= delta
		impact.modulate.a = clampf(_impact_t / 0.35, 0.0, 1.0)
		impact.scale = Vector2.ONE * (0.12 + (0.35 - _impact_t) * 0.9)
		if _impact_t <= 0.0:
			impact.visible = false
	if not running:
		return
	_run_t += delta
	if energy >= config.energy_max and _super_arm <= 0.0 and super_left <= 0.0 and _run_t >= config.super_min_run and _exit_grace <= 0.0:
		_super_arm = config.super_enter
		player.invincible = true
		hud.show_super(true)
		hud.play_transit(true)
		hud.set_super_enter(_super_arm)
	if _super_arm > 0.0:
		_super_arm = maxf(_super_arm - delta, 0.0)
		player.invincible = true
		hud.show_super(true)
		hud.set_super_enter(_super_arm)
		if _super_arm <= 0.0:
			energy = 0.0
			hud.set_energy(energy, config.energy_max)
			_begin_super(config.super_duration)
	if _exit_grace > 0.0:
		_exit_grace = maxf(_exit_grace - delta, 0.0)
		player.invincible = true
		if _exit_grace <= 0.0 and super_left <= 0.0 and _super_arm <= 0.0:
			player.invincible = false
	if _sprint_t > 0.0:
		_sprint_t = maxf(_sprint_t - delta, 0.0)
		shockwave.visible = false
		if _sprint_t <= 0.0:
			player.set_flying(false)
			if super_left <= 0.0:
				player.invincible = false
			shockwave.visible = false
	if super_left > 0.0:
		super_left = maxf(super_left - delta, 0.0)
		hud.set_super_time(super_left)
		_rain_t -= delta
		if _rain_t <= 0.0:
			_rain_t = 2.4
			spawner.spawn_shape_coins()
		if super_left <= 0.0:
			_end_super()
	# 奖励关吸币（奖励币不充能量）。出关后只有道具磁铁才吸。
	spawner.magnet = super_left > 0.0 or (super_left <= 0.0 and (_magnet_t > 0.0 or _sprint_t > 0.0))
	if _magnet_t > 0.0:
		_magnet_t = maxf(_magnet_t - delta, 0.0)
	speed = minf(speed + config.acceleration * delta, config.speed_max)
	if _sprint_t > 0.0:
		speed = maxf(speed, config.speed_start * 1.45)
	var scroll: float = speed
	if _super_arm > 0.0:
		scroll = speed * 0.38
	elif super_left > 0.0:
		scroll = speed * 0.48
	distance += speed * delta
	score = int(distance * RunnerConfig.SCORE_DIST) + coin_value * RunnerConfig.SCORE_COIN + rings * RunnerConfig.SCORE_RING
	spawner.set_score(score)
	spawner.set_run_distance(distance)
	spawner.set_moving_speed(scroll)
	if score >= config.invert_score and not inverted:
		_apply_invert(true)
	var hundred: int = score / 100
	if hundred > _last_hundred:
		_last_hundred = hundred
		audio_score.play()
	hud.set_score(score, Save.best_score(), int(distance * 0.1))
	hud.set_energy(energy, config.energy_max)
	_sync_scroll_with(scroll)


func _is_headless() -> bool:
	return DisplayServer.get_name() == "headless"


func _kickoff_run() -> void:
	if running or not player.alive:
		return
	if hud.has_node("%RunEnter"):
		var cover: Control = hud.get_node("%RunEnter") as Control
		cover.visible = false
		cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cover.modulate.a = 0.0
	player.set_physics_process(true)
	running = true
	speed = config.speed_start
	player.begin_run()
	spawner.set_moving_speed(speed)
	_sync_scroll_with(speed)
	hud.show_running()
	if _sprint_t > 0.0:
		player.set_flying(true)
		player.invincible = true


func _begin_sprint(dur: float) -> void:
	_sprint_t = dur
	_magnet_t = maxf(_magnet_t, dur)
	player.invincible = true
	if running:
		player.set_flying(true)


func _on_pause_button() -> void:
	if running and player.alive:
		_set_paused(not paused)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and running and player.alive:
		_set_paused(not paused)
		get_viewport().set_input_as_handled()


func _set_paused(value: bool) -> void:
	paused = value
	hud.show_pause(value)
	player.set_physics_process(not value)
	spawner.set_physics_process(not value)
	if value:
		spawner.stop()
	elif running and player.alive:
		spawner.resume_run()


func _on_jumped() -> void:
	audio_jump.play()
	if not running:
		running = true
		speed = config.speed_start
		spawner.set_moving_speed(speed)
		hud.show_running()
		_sync_scroll_with(speed)
	if _sprint_t > 0.0:
		player.set_flying(true)
		player.invincible = true


func _on_hit(point: Vector2) -> void:
	if not running:
		return
	if player.alive:
		return
	running = false
	speed = 0.0
	spawner.stop()
	spawner.set_moving_speed(0.0)
	_sync_scroll_with(0.0)
	audio_hit.play()
	_show_impact(point)
	hud.set_score(score, Save.best_score(), int(distance * 0.1))
	var dist: int = int(distance)
	Economy.last_run_score = score
	Economy.last_run_coins = coin_value
	Economy.last_run_distance = dist
	Economy.grant(coin_value)
	Economy.last_was_best = Save.add_run(Settings.player_id, Settings.nickname, score, dist, coin_value)
	var gen: int = _run_gen
	Engine.time_scale = 0.16
	var t: SceneTreeTimer = get_tree().create_timer(config.hit_stop, true, false, true)
	t.timeout.connect(func () -> void:
		if _run_gen != gen:
			return
		Engine.time_scale = 1.0
		player.set_physics_process(false)
		get_tree().create_timer(0.28).timeout.connect(func () -> void:
			if _run_gen != gen:
				return
			_show_over()
		)
	)


func _show_over() -> void:
	var dist_score: int = int(distance * RunnerConfig.SCORE_DIST)
	var coin_pts: int = coin_value * RunnerConfig.SCORE_COIN
	var ring_pts: int = rings * RunnerConfig.SCORE_RING
	hud.show_game_over(score, Economy.last_was_best, dist_score, coin_pts, ring_pts, coin_value)


func _show_impact(point: Vector2) -> void:
	impact.global_position = point
	impact.visible = true
	impact.modulate.a = 1.0
	impact.scale = Vector2(0.12, 0.12)
	_impact_t = 0.4
	if Settings.screen_shake:
		var cam: Camera2D = get_viewport().get_camera_2d()
		if cam != null:
			cam.offset = Vector2(randf_range(-6.0, 6.0), randf_range(-4.0, 4.0))
			get_tree().create_timer(0.12).timeout.connect(func () -> void:
				if is_instance_valid(cam):
					cam.offset = Vector2.ZERO
			)


func _on_coin(coin: RunCoin) -> void:
	run_coins += 1
	coin_value += coin.worth
	audio_score.play()
	_pop_pickup(coin.global_position, "+%d" % coin.worth, Color(1.0, 0.86, 0.32, 1))
	hud.punch_pickup()
	if coin.fills_energy and super_left <= 0.0 and _super_arm <= 0.0:
		energy = minf(energy + config.energy_per_coin, config.energy_max)


func _on_ring() -> void:
	rings += 1
	score += RunnerConfig.SCORE_RING
	audio_score.play()
	if player != null:
		_pop_pickup(player.global_position + Vector2(24, -90), "星门 +80", Color(1.0, 0.72, 0.88, 1))
	hud.punch_pickup()


func _begin_super(dur: float) -> void:
	super_left = dur
	_rain_t = 0.05
	_pet_t = 0.0
	_sprint_t = 0.0
	_magnet_t = 0.0
	player.set_flying(false)
	player.invincible = true
	shockwave.visible = false
	spawner.magnet = true
	spawner.rest_mode = true
	spawner.clear_obstacles_keep_coins()
	spawner.spawn_shape_coins()
	super_sky.visible = true
	%PetA.visible = false
	%PetB.visible = false
	hud.show_super(true)
	hud.set_super_time(super_left)


func _end_super() -> void:
	super_left = 0.0
	super_sky.visible = false
	%PetA.visible = false
	%PetB.visible = false
	spawner.rest_mode = false
	spawner.magnet = false
	spawner.clear_obstacles_keep_coins()
	spawner.hold_spawn(config.super_spawn_hold)
	player.invincible = true
	_exit_grace = config.super_exit_grace
	hud.play_transit(false)
	hud.show_super(false)


func _replay() -> void:
	_reset_run()


func _reset_run() -> void:
	_run_gen += 1
	Engine.time_scale = 1.0
	paused = false
	running = false
	inverted = false
	speed = 0.0
	distance = 0.0
	score = 0
	run_coins = 0
	energy = 0.0
	super_left = 0.0
	rings = 0
	coin_value = 0
	_last_hundred = 0
	_impact_t = 0.0
	_magnet_t = 0.0
	_rain_t = 0.0
	_sprint_t = 0.0
	_pet_t = 0.0
	_super_arm = 0.0
	_run_t = 0.0
	_exit_grace = 0.0
	player.set_physics_process(true)
	player.invincible = false
	player.has_shield = false
	player.apply_character(Catalog.equipped_def())
	player.reset()
	impact.visible = false
	shockwave.visible = false
	super_sky.visible = false
	%PetA.visible = false
	%PetB.visible = false
	_apply_invert(false)
	_apply_world()
	hud.show_intro()
	hud.set_score(0, Save.best_score(), 0)
	hud.set_energy(0.0, config.energy_max)
	hud.show_super(false)
	hud.show_pause(false)
	spawner.magnet = false
	spawner.rest_mode = false
	spawner.start()
	spawner.set_moving_speed(0.0)
	_sync_scroll_with(0.0)
	_apply_loadout()
	_kickoff_run()


func _pop_pickup(pos: Vector2, text: String, color: Color) -> void:
	var lab: Label = Label.new()
	lab.text = text
	lab.z_index = 40
	lab.position = pos + Vector2(-18.0, -36.0)
	lab.add_theme_font_size_override("font_size", 18)
	lab.add_theme_color_override("font_color", color)
	lab.add_theme_color_override("font_outline_color", Color(0.12, 0.04, 0.08, 1))
	lab.add_theme_constant_override("outline_size", 6)
	add_child(lab)
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(lab, "position:y", lab.position.y - 46.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(lab, "modulate:a", 0.0, 0.42).set_delay(0.10)
	tw.chain().tween_callback(lab.queue_free)


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _sync_scroll() -> void:
	_sync_scroll_with(speed)


func _sync_scroll_with(scroll: float) -> void:
	ground.speed = scroll
	sky_night.autoscroll = Vector2(-scroll * 0.12, 0.0)
	sky_day.autoscroll = Vector2(-scroll * 0.12, 0.0)
	curtains.autoscroll = Vector2(-scroll * 0.35, 0.0)
	clouds.autoscroll = Vector2(-scroll * 0.22, 0.0)


func _apply_world() -> void:
	var sky_spr: Sprite2D = sky_night.get_node("Sprite2D") as Sprite2D
	sky_spr.texture = _tex_sky0
	sky_spr.scale = Vector2(0.75, 0.75)
	sky_night.repeat_size = Vector2(768.0, 0.0)
	ground.texture = _tex_ground0
	curtains.visible = true
	clouds.visible = true


func _apply_invert(value: bool) -> void:
	inverted = value
	sky_night.visible = not value
	sky_day.visible = value


func _back_home() -> void:
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://ui/home.tscn")
