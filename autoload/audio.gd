extends Node

const CRASH_PATH: String = "user://crash.log"
const BOOT_FLAG: String = "user://session.lock"

var _title_frames: int = 20


func _ready() -> void:
	Engine.max_fps = RunnerConfig.MAX_FPS
	Engine.physics_ticks_per_second = RunnerConfig.PHYSICS_TICKS
	Engine.physics_jitter_fix = 0.5
	get_tree().physics_interpolation = true
	_recover_unclean_exit()
	_mark_session(true)
	GameVersion.apply_title()
	_ensure_buses()
	_start_bgm()
	set_process(true)
	call_deferred("_boot_window")


func _process(_delta: float) -> void:
	GameVersion.apply_title()
	_title_frames -= 1
	if _title_frames <= 0:
		set_process(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		_mark_session(false)


func _recover_unclean_exit() -> void:
	if not FileAccess.file_exists(BOOT_FLAG):
		return
	append_crash("unclean_exit previous session did not close")


func _mark_session(running: bool) -> void:
	if running:
		var f: FileAccess = FileAccess.open(BOOT_FLAG, FileAccess.WRITE)
		if f != null:
			f.store_string(Time.get_datetime_string_from_system(false, true))
	elif FileAccess.file_exists(BOOT_FLAG):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(BOOT_FLAG))


func append_crash(msg: String) -> void:
	var prev: String = ""
	if FileAccess.file_exists(CRASH_PATH):
		var rf: FileAccess = FileAccess.open(CRASH_PATH, FileAccess.READ)
		if rf != null:
			prev = rf.get_as_text()
	var wf: FileAccess = FileAccess.open(CRASH_PATH, FileAccess.WRITE)
	if wf == null:
		return
	var line: String = "%s  %s\n" % [Time.get_datetime_string_from_system(false, true), msg]
	wf.store_string(prev + line)


func _boot_window() -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	GameVersion.apply_title()
	# GL Compatibility：第一帧呈现后再改 size/mode/position，窗口会停在清屏灰。


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
