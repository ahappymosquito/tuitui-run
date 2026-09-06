extends Control

const MAIN_PATH: String = "res://levels/main.tscn"

@onready var coins: Label = %Coins
@onready var status: Label = %Status
@onready var portrait: TextureRect = %Portrait

var _bob_t: float = 0.0
var _loading_run: bool = false
var _load_t: float = 0.0


func _ready() -> void:
	%StartButton.pressed.connect(_start_run)
	%SettingsButton.pressed.connect(func () -> void: get_tree().change_scene_to_file("res://ui/settings.tscn"))
	%RankButton.pressed.connect(func () -> void: get_tree().change_scene_to_file("res://ui/rank.tscn"))
	%None.pressed.connect(func () -> void: _equip(""))
	%Shield.pressed.connect(func () -> void: _equip("shield"))
	%Magnet.pressed.connect(func () -> void: _equip("magnet"))
	%TabChar.pressed.connect(func () -> void: get_tree().change_scene_to_file("res://scenes/shop.tscn"))
	_apply_character()
	_refresh()
	if has_node("%VersionLabel"):
		%VersionLabel.text = GameVersion.display()
	Save.save_changed.connect(_on_save)


func _process(delta: float) -> void:
	_bob_t += delta
	if portrait != null:
		if portrait.size.x > 1.0:
			portrait.pivot_offset = portrait.size * 0.5
		portrait.rotation = sin(_bob_t * 1.35) * 0.028
		var s: float = 1.0 + 0.016 * sin(_bob_t * 2.1)
		portrait.scale = Vector2(s, s)
	if has_node("%StartButton"):
		var btn: Button = %StartButton
		if btn.size.x > 1.0:
			btn.pivot_offset = btn.size * 0.5
		var bs: float = 1.0 + 0.028 * sin(_bob_t * 3.1)
		btn.scale = Vector2(bs, bs)
	if _loading_run:
		_poll_run_load(delta)


func _on_save() -> void:
	_apply_character()
	_refresh()


func _apply_character() -> void:
	portrait.visible = true
	var def: CharacterDef = Catalog.equipped_def()
	if def != null and def.shop_portrait != null:
		portrait.texture = def.shop_portrait


func _refresh() -> void:
	coins.text = "橘子币  %d" % Save.coins
	var eq: String = Economy.equipped
	status.text = "未携带开局道具" if eq == "" else ("已带：" + _label_of(eq))
	%IdLabel.text = "%s   ID %s" % [Settings.nickname, Settings.player_id]
	_mark(%None, eq == "")
	_mark(%Shield, eq == "shield")
	_mark(%Magnet, eq == "magnet")


func _mark(btn: Button, on: bool) -> void:
	btn.modulate = Color(1.12, 1.06, 0.72) if on else Color.WHITE


func _label_of(item: String) -> String:
	match item:
		"shield":
			return "保护罩 吸收一次伤害"
		"magnet":
			return "磁铁 8秒"
		_:
			return item


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_start_run()


func _start_run() -> void:
	if _loading_run:
		return
	_loading_run = true
	%StartButton.disabled = true
	RunEnter.pending = true
	var cover: RunEnter = %RunEnter as RunEnter
	cover.set_progress(0.12)
	cover.fade_in(0.16)
	_load_t = 0.0


func _poll_run_load(delta: float) -> void:
	_load_t += delta
	(%RunEnter as RunEnter).set_progress(clampf(_load_t / 0.65, 0.0, 1.0))
	if _load_t >= 0.65:
		_loading_run = false
		get_tree().change_scene_to_file(MAIN_PATH)


func _equip(item: String) -> void:
	if item == "":
		Economy.equipped = ""
		_refresh()
		return
	if not Economy.try_equip(item):
		status.text = "橘子币不够"
		return
	_refresh()
