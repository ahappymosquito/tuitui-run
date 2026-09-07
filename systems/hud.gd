class_name HUD
extends CanvasLayer

signal restart_pressed
signal replay_pressed
signal resume_pressed
signal pause_pressed
signal enter_done

@onready var score_label: Label = %ScoreLabel
@onready var hi_label: Label = %HiLabel
@onready var coin_label: Label = %CoinLabel
@onready var hint_label: Label = %HintLabel
@onready var energy_bar: ProgressBar = %EnergyBar
@onready var energy_pct: Label = %EnergyPct
@onready var super_label: Label = %SuperLabel
@onready var over_root: Control = %GameOver
@onready var over_title: Label = %OverTitle
@onready var over_detail: Label = %OverDetail
@onready var over_score: Label = %OverScore
@onready var restart_button: TextureButton = %RestartButton
@onready var replay_button: Button = %ReplayButton
@onready var home_button: Button = %HomeButton
@onready var pause_root: Control = %PauseRoot
@onready var celebrate: Label = %Celebrate
@onready var fps_label: Label = %FpsLabel
@onready var super_enter_root: Control = %SuperEnter
@onready var enter_count: Label = %EnterCount
@onready var transit_art: TextureRect = %TransitArt

const TEX_TRANSIT_TUITUI: Texture2D = preload("res://assets/backgrounds/transit_tuitui.png")
const TEX_TRANSIT_CAO: Texture2D = preload("res://assets/backgrounds/transit_cao.png")

var _tick_to: int = 0
var _tick_shown: float = 0.0
var _ticking: bool = false
var _transit_t: float = 0.0
var _transit_dur: float = 1.8
var _transiting: bool = false
var _hint_tw: Tween


func _ready() -> void:
	restart_button.visible = false
	restart_button.pressed.connect(func () -> void: restart_pressed.emit())
	replay_button.pressed.connect(func () -> void: replay_pressed.emit())
	home_button.pressed.connect(func () -> void: restart_pressed.emit())
	%ResumeButton.pressed.connect(func () -> void: resume_pressed.emit())
	%PauseHomeButton.pressed.connect(func () -> void: restart_pressed.emit())
	if has_node("%PauseButton"):
		%PauseButton.pressed.connect(func () -> void: pause_pressed.emit())
	if has_node("%VersionLabel"):
		%VersionLabel.text = GameVersion.display()
	_style_energy()
	show_intro()


func _style_energy() -> void:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color(1.0, 0.72, 0.86, 0.95)
	box.corner_radius_top_left = 10
	box.corner_radius_top_right = 10
	box.corner_radius_bottom_right = 10
	box.corner_radius_bottom_left = 10
	energy_bar.add_theme_stylebox_override("fill", box)
	var bg: StyleBoxFlat = StyleBoxFlat.new()
	bg.bg_color = Color(0.18, 0.08, 0.14, 0.55)
	bg.corner_radius_top_left = 10
	bg.corner_radius_top_right = 10
	bg.corner_radius_bottom_right = 10
	bg.corner_radius_bottom_left = 10
	energy_bar.add_theme_stylebox_override("background", bg)


func _process(delta: float) -> void:
	fps_label.visible = Settings.show_fps
	if Settings.show_fps:
		fps_label.text = "%d FPS" % Engine.get_frames_per_second()
	if _transiting:
		_transit_t += delta
		var u: float = clampf(_transit_t / _transit_dur, 0.0, 1.0)
		var a: float
		if u < 0.28:
			a = u / 0.28
		elif u < 0.62:
			a = 1.0
		else:
			a = 1.0 - (u - 0.62) / 0.38
		transit_art.modulate.a = a
		transit_art.scale = Vector2.ONE * (1.0 + 0.08 * u)
		if u >= 1.0:
			_transiting = false
			super_enter_root.visible = false
			transit_art.modulate.a = 0.0
	if not _ticking:
		return
	var step: float = maxf(90.0, float(_tick_to) * 1.35) * delta
	_tick_shown = move_toward(_tick_shown, float(_tick_to), step)
	over_score.text = "%d" % int(_tick_shown)
	if is_equal_approx(_tick_shown, float(_tick_to)):
		_ticking = false


func set_score(score: int, hi: int, dist: int) -> void:
	score_label.text = "分数  %05d" % score
	hi_label.text = "最高  %05d" % hi
	coin_label.text = "距离  %d" % dist


func punch_pickup() -> void:
	score_label.pivot_offset = Vector2(score_label.size.x * 0.15, score_label.size.y * 0.5)
	var tw: Tween = create_tween()
	tw.tween_property(score_label, "scale", Vector2(1.08, 1.08), 0.06)
	tw.tween_property(score_label, "scale", Vector2.ONE, 0.12)
	energy_bar.modulate = Color(1.18, 1.10, 0.72, 1)
	var tw2: Tween = create_tween()
	tw2.tween_property(energy_bar, "modulate", Color.WHITE, 0.22)


func set_energy(value: float, mx: float) -> void:
	energy_bar.max_value = mx
	energy_bar.value = value
	var pct: int = int(round(value / maxf(mx, 1.0) * 100.0))
	energy_pct.text = "超级奖励  %d%%" % pct


func show_super(on: bool) -> void:
	super_label.visible = on
	if not on:
		super_enter_root.visible = false


func set_super_time(_left: float) -> void:
	super_enter_root.visible = false
	super_label.visible = true
	super_label.text = "超级时空"


func set_super_enter(_left: float) -> void:
	super_label.visible = true
	super_label.text = "超级时空"


func play_transit(entering: bool) -> void:
	super_enter_root.visible = true
	_transiting = true
	_transit_t = 0.0
	_transit_dur = 1.7 if entering else 1.1
	transit_art.texture = TEX_TRANSIT_TUITUI
	%EnterTitle.text = "坠入星云" if entering else "星云散开"
	%EnterCount.visible = false
	transit_art.modulate.a = 0.0
	transit_art.pivot_offset = transit_art.size * 0.5


func _set_pause_btn(on: bool) -> void:
	if has_node("%PauseButton"):
		%PauseButton.visible = on


func show_intro() -> void:
	over_root.visible = false
	pause_root.visible = false
	super_label.visible = false
	super_enter_root.visible = false
	_transiting = false
	_ticking = false
	hint_label.text = Settings.run_guide_text()
	hint_label.modulate.a = 1.0
	hint_label.visible = true
	_set_pause_btn(false)


func show_running() -> void:
	over_root.visible = false
	pause_root.visible = false
	_set_pause_btn(true)
	_fade_hint()


func cover_and_reveal() -> void:
	if not has_node("%RunEnter"):
		enter_done.emit()
		return
	var cover: RunEnter = %RunEnter as RunEnter
	cover.process_mode = Node.PROCESS_MODE_ALWAYS
	cover.appear()
	cover.set_progress(1.0)
	if not cover.faded_out.is_connected(_on_enter_faded):
		cover.faded_out.connect(_on_enter_faded)
	var tw: Tween = cover.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_interval(0.22)
	tw.tween_callback(func () -> void:
		if is_instance_valid(cover):
			cover.fade_out(0.38)
	)


func _on_enter_faded() -> void:
	enter_done.emit()


func _fade_hint() -> void:
	hint_label.text = Settings.run_guide_text()
	hint_label.visible = true
	hint_label.modulate.a = 1.0
	if _hint_tw != null:
		_hint_tw.kill()
	_hint_tw = create_tween()
	_hint_tw.tween_interval(2.6)
	_hint_tw.tween_property(hint_label, "modulate:a", 0.0, 0.4)
	_hint_tw.tween_callback(func () -> void:
		hint_label.visible = false
	)


func show_pause(on: bool) -> void:
	pause_root.visible = on
	_set_pause_btn(not on)


func show_game_over(total: int, is_best: bool, dist_score: int = 0, coin_score: int = 0, ring_score: int = 0, coins_gained: int = 0) -> void:
	over_root.visible = true
	hint_label.visible = false
	pause_root.visible = false
	_set_pause_btn(false)
	celebrate.visible = is_best
	%CelebrateArt.visible = is_best
	over_title.text = "新纪录！" if is_best else "本局结束"
	celebrate.text = "打破纪录！" if is_best else ""
	over_detail.visible = true
	over_detail.text = "距离 %d    金币 %d    星门 %d\n橘子币 +%d" % [dist_score, coin_score, ring_score, coins_gained]
	_tick_to = total
	_tick_shown = 0.0
	_ticking = true
	over_score.text = "0"
