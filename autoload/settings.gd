extends Node

const PATH: String = "user://settings.cfg"

var master_db: float = 0.0
var sfx_db: float = 0.0
var bgm_db: float = -8.0
var muted: bool = false
var fullscreen: bool = false
var vsync: bool = true
var show_fps: bool = false
var screen_shake: bool = true
var nickname: String = "推推"
var player_id: String = ""
var character_id: int = 0
var jump_key: int = KEY_SPACE
var duck_key: int = KEY_S
var pause_key: int = KEY_ESCAPE
var debug_unlock_iap: bool = false


func _ready() -> void:
	load_from_disk()
	apply()


func load_from_disk() -> void:
	var cf: ConfigFile = ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	master_db = float(cf.get_value("audio", "master_db", 0.0))
	sfx_db = float(cf.get_value("audio", "sfx_db", 0.0))
	bgm_db = float(cf.get_value("audio", "bgm_db", -8.0))
	muted = bool(cf.get_value("audio", "muted", false))
	fullscreen = bool(cf.get_value("display", "fullscreen", false))
	vsync = bool(cf.get_value("display", "vsync", true))
	show_fps = bool(cf.get_value("display", "show_fps", false))
	screen_shake = bool(cf.get_value("display", "screen_shake", true))
	nickname = str(cf.get_value("profile", "nickname", "推推"))
	player_id = str(cf.get_value("profile", "player_id", ""))
	character_id = int(cf.get_value("profile", "character_id", 0))
	if character_id > 1:
		character_id = 0
	if not FileAccess.file_exists("user://default_tuitui_142"):
		character_id = 0
		var mk: FileAccess = FileAccess.open("user://default_tuitui_142", FileAccess.WRITE)
		if mk != null:
			mk.store_string("1")
	jump_key = int(cf.get_value("input", "jump_key", KEY_SPACE))
	duck_key = int(cf.get_value("input", "duck_key", KEY_S))
	pause_key = int(cf.get_value("input", "pause_key", KEY_ESCAPE))
	debug_unlock_iap = bool(cf.get_value("debug", "unlock_iap", false))


func save_to_disk() -> void:
	var cf: ConfigFile = ConfigFile.new()
	cf.set_value("audio", "master_db", master_db)
	cf.set_value("audio", "sfx_db", sfx_db)
	cf.set_value("audio", "bgm_db", bgm_db)
	cf.set_value("audio", "muted", muted)
	cf.set_value("display", "fullscreen", fullscreen)
	cf.set_value("display", "vsync", vsync)
	cf.set_value("display", "show_fps", show_fps)
	cf.set_value("display", "screen_shake", screen_shake)
	cf.set_value("profile", "nickname", nickname)
	cf.set_value("profile", "player_id", player_id)
	cf.set_value("profile", "character_id", character_id)
	cf.set_value("input", "jump_key", jump_key)
	cf.set_value("input", "duck_key", duck_key)
	cf.set_value("input", "pause_key", pause_key)
	cf.set_value("debug", "unlock_iap", debug_unlock_iap)
	cf.save(PATH)


func apply() -> void:
	# 画面与物理都锁 60，避免高刷新率机器跳得更快、落地窗口不同。
	Engine.max_fps = RunnerConfig.MAX_FPS
	Engine.physics_ticks_per_second = RunnerConfig.PHYSICS_TICKS
	var master_idx: int = AudioServer.get_bus_index("Master")
	if muted:
		AudioServer.set_bus_volume_db(master_idx, -80.0)
	else:
		AudioServer.set_bus_volume_db(master_idx, master_db)
	var sfx_idx: int = AudioServer.get_bus_index("SFX")
	if sfx_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_idx, sfx_db)
	var bgm_idx: int = AudioServer.get_bus_index("BGM")
	if bgm_idx >= 0:
		AudioServer.set_bus_volume_db(bgm_idx, bgm_db)
	_apply_binds()
	call_deferred("_apply_display")


func _apply_display() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	GameVersion.apply_title()
	if OS.has_feature("editor"):
		return
	var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	var is_full: bool = mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if fullscreen and not is_full:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif (not fullscreen) and is_full:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func is_cao() -> bool:
	return false


func is_touch_play() -> bool:
	return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()


func run_guide_text() -> String:
	if is_touch_play():
		return "左滑  ·  右跳  ·  跟着金币走"
	return "%s跳  ·  %s下滑  ·  跟着金币走" % [key_name(jump_key), key_name(duck_key)]


func key_name(code: int) -> String:
	match code:
		KEY_SPACE:
			return "空格"
		KEY_ESCAPE:
			return "Esc"
		KEY_SHIFT:
			return "Shift"
		KEY_UP:
			return "上"
		KEY_DOWN:
			return "下"
		KEY_LEFT:
			return "左"
		KEY_RIGHT:
			return "右"
		_:
			var l: String = OS.get_keycode_string(code)
			return l if l != "" else str(code)


func set_bind(action: String, code: int) -> void:
	match action:
		"jump":
			jump_key = code
		"duck":
			duck_key = code
		"pause":
			pause_key = code
	_apply_binds()
	save_to_disk()


func _apply_binds() -> void:
	_bind_action("jump", jump_key)
	_bind_action("duck", duck_key)
	_bind_action("slide", duck_key)
	_bind_action("pause", pause_key)


func _bind_action(action: String, code: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	_add_key(action, code)
	if action == "jump":
		if code == KEY_SPACE:
			_add_key(action, KEY_UP)
			_add_key(action, KEY_W)
	elif (action == "duck" or action == "slide") and code == KEY_S:
		_add_key(action, KEY_DOWN)


func _add_key(action: String, code: int) -> void:
	var ev: InputEventKey = InputEventKey.new()
	ev.keycode = code as Key
	ev.physical_keycode = code as Key
	InputMap.action_add_event(action, ev)
