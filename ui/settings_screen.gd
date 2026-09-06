extends Control

@onready var master: HSlider = %Master
@onready var sfx: HSlider = %Sfx
@onready var bgm: HSlider = %Bgm
@onready var mute: CheckBox = %Mute
@onready var nick: LineEdit = %Nick
@onready var pid: Label = %PlayerId
@onready var full: CheckBox = %Full
@onready var vsync: CheckBox = %Vsync
@onready var show_fps: CheckBox = %ShowFps
@onready var shake: CheckBox = %Shake
@onready var master_v: Label = %MasterVal
@onready var sfx_v: Label = %SfxVal
@onready var bgm_v: Label = %BgmVal

var _waiting: String = ""


func _ready() -> void:
	_setup_slider(master, Settings.master_db)
	_setup_slider(sfx, Settings.sfx_db)
	_setup_slider(bgm, Settings.bgm_db)
	mute.button_pressed = Settings.muted
	nick.text = Settings.nickname
	pid.text = Settings.player_id
	full.button_pressed = Settings.fullscreen
	vsync.button_pressed = Settings.vsync
	show_fps.button_pressed = Settings.show_fps
	shake.button_pressed = Settings.screen_shake
	_sync_vals()
	_refresh_binds()
	_show_page("audio")
	%TabAudio.pressed.connect(func () -> void: _show_page("audio"))
	%TabVideo.pressed.connect(func () -> void: _show_page("video"))
	%TabKeys.pressed.connect(func () -> void: _show_page("keys"))
	%TabAccount.pressed.connect(func () -> void: _show_page("account"))
	master.value_changed.connect(func (v: float) -> void:
		Settings.master_db = v
		Settings.apply()
		Settings.save_to_disk()
		_sync_vals()
	)
	sfx.value_changed.connect(func (v: float) -> void:
		Settings.sfx_db = v
		Settings.apply()
		Settings.save_to_disk()
		_sync_vals()
	)
	bgm.value_changed.connect(func (v: float) -> void:
		Settings.bgm_db = v
		Settings.apply()
		Settings.save_to_disk()
		_sync_vals()
	)
	mute.toggled.connect(func (on: bool) -> void:
		Settings.muted = on
		Settings.apply()
		Settings.save_to_disk()
	)
	full.toggled.connect(func (on: bool) -> void:
		Settings.fullscreen = on
		Settings.apply()
		Settings.save_to_disk()
	)
	vsync.toggled.connect(func (on: bool) -> void:
		Settings.vsync = on
		Settings.apply()
		Settings.save_to_disk()
	)
	show_fps.toggled.connect(func (on: bool) -> void:
		Settings.show_fps = on
		Settings.save_to_disk()
	)
	shake.toggled.connect(func (on: bool) -> void:
		Settings.screen_shake = on
		Settings.save_to_disk()
	)
	nick.text_changed.connect(func (t: String) -> void:
		Settings.nickname = t.strip_edges()
		Settings.save_to_disk()
	)
	%CopyId.pressed.connect(func () -> void:
		DisplayServer.clipboard_set(Settings.player_id)
		%CopyId.text = "已复制"
	)
	%ResetBoard.pressed.connect(func () -> void:
		Save.clear_local()
		%ResetBoard.text = "本地排行已清空"
	)
	if has_node("%PrivacyBtn"):
		%PrivacyBtn.pressed.connect(func () -> void: %PrivacyPanel.visible = true)
	if has_node("%PrivacyClose"):
		%PrivacyClose.pressed.connect(func () -> void: %PrivacyPanel.visible = false)
	if has_node("%DebugIap"):
		%DebugIap.button_pressed = Settings.debug_unlock_iap
		%DebugIap.toggled.connect(func (on: bool) -> void:
			Settings.debug_unlock_iap = on
			Settings.save_to_disk()
			if on:
				for id: StringName in Catalog.all_ids():
					var def: CharacterDef = Catalog.get_def(id)
					if def != null and def.currency == &"iap":
						Save.grant_iap(String(id))
		)
	if has_node("%WipeSave"):
		%WipeSave.pressed.connect(func () -> void:
			Save.wipe_progress()
			%WipeSave.text = "进度已清空"
		)
	if has_node("%GrantTestCoins"):
		%GrantTestCoins.pressed.connect(func () -> void:
			Save.add_coins(2400)
			%GrantTestCoins.text = "已加 2400（现 %d）" % Save.coins
		)
	%BindJump.pressed.connect(func () -> void: _listen("jump"))
	%BindDuck.pressed.connect(func () -> void: _listen("duck"))
	%BindPause.pressed.connect(func () -> void: _listen("pause"))
	%Back.pressed.connect(func () -> void: get_tree().change_scene_to_file("res://ui/home.tscn"))


func _show_page(which: String) -> void:
	%PageAudio.visible = which == "audio"
	%PageVideo.visible = which == "video"
	%PageKeys.visible = which == "keys"
	%PageAccount.visible = which == "account"
	%TabAudio.modulate = Color(1.15, 1.05, 0.55) if which == "audio" else Color.WHITE
	%TabVideo.modulate = Color(1.15, 1.05, 0.55) if which == "video" else Color.WHITE
	%TabKeys.modulate = Color(1.15, 1.05, 0.55) if which == "keys" else Color.WHITE
	%TabAccount.modulate = Color(1.15, 1.05, 0.55) if which == "account" else Color.WHITE


func _listen(action: String) -> void:
	_waiting = action
	%KeyHint.text = "按下新的按键…"


func _unhandled_input(event: InputEvent) -> void:
	if _waiting == "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k: InputEventKey = event as InputEventKey
		Settings.set_bind(_waiting, k.keycode)
		_waiting = ""
		%KeyHint.text = "已更新"
		_refresh_binds()
		get_viewport().set_input_as_handled()


func _refresh_binds() -> void:
	%BindJump.text = "跳跃    " + Settings.key_name(Settings.jump_key)
	%BindDuck.text = "下滑    " + Settings.key_name(Settings.duck_key)
	%BindPause.text = "暂停    " + Settings.key_name(Settings.pause_key)


func _setup_slider(s: HSlider, value: float) -> void:
	s.min_value = -24.0
	s.max_value = 6.0
	s.step = 1.0
	s.value = value


func _sync_vals() -> void:
	master_v.text = "%d dB" % int(master.value)
	sfx_v.text = "%d dB" % int(sfx.value)
	bgm_v.text = "%d dB" % int(bgm.value)
