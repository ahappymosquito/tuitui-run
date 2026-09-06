extends Node

var _title_frames: int = 20


func _ready() -> void:
	Engine.max_fps = RunnerConfig.MAX_FPS
	Engine.physics_ticks_per_second = RunnerConfig.PHYSICS_TICKS
	Engine.physics_jitter_fix = 0.5
	get_tree().physics_interpolation = true
	GameVersion.apply_title()
	_ensure_buses()
	_start_bgm()
	set_process(true)
	call_deferred("_boot_window")
	_dump_boot_shot()


func _process(_delta: float) -> void:
	GameVersion.apply_title()
	_title_frames -= 1
	if _title_frames <= 0:
		set_process(false)


func _boot_window() -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	GameVersion.apply_title()
	# 启动后不要改 size/mode/position：部分驱动上第一帧呈现后再改窗口，会停在清屏灰。


func _dump_boot_shot() -> void:
	if OS.get_environment("TUITUI_SHOT") == "":
		return
	await get_tree().create_timer(0.9).timeout
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "D:/code/tuitui/tuitui_run/tools/shots/57_boot.png"
	img.save_png(path)
	print("boot_shot %s %dx%d title=%s" % [path, img.get_width(), img.get_height(), GameVersion.window_title()])


func _ensure_buses() -> void:
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		var idx: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, "SFX")
		AudioServer.set_bus_send(idx, "Master")
	if AudioServer.get_bus_index("BGM") == -1:
		AudioServer.add_bus()
		var idx2: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx2, "BGM")
		AudioServer.set_bus_send(idx2, "Master")


func _start_bgm() -> void:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.name = "BgmPlayer"
	player.bus = "BGM"
	var stream: AudioStream = null
	if ResourceLoader.exists("res://assets/bgm/utsukushiki_mono.ogg"):
		stream = load("res://assets/bgm/utsukushiki_mono.ogg") as AudioStream
	elif ResourceLoader.exists("res://assets/bgm/main.ogg"):
		stream = load("res://assets/bgm/main.ogg") as AudioStream
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	player.stream = stream
	add_child(player)
	player.play()
