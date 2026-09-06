extends Control

var _t: float = 0.0
var _dur: float = 1.35
var _waiting_id: bool = false
@onready var bar: ProgressBar = %Bar
@onready var tip: Label = %Tip
@onready var poster: TextureRect = %Poster
@onready var id_panel: Control = %IdPanel


func _ready() -> void:
	id_panel.visible = false
	var tips: PackedStringArray = PackedStringArray([
		"%s跳，%s下滑。路就在金币上。" % [Settings.key_name(Settings.jump_key), Settings.key_name(Settings.duck_key)],
		"跟着弧线跳，路就在金币上。",
		"左滑右跳。矮障钻，高障跳，坑要跳过。",
		"超级时空是休息关，奖励币不再充能。",
	])
	if Settings.is_touch_play():
		tips[0] = "左滑右跳。跟着金币走。"
	tip.text = tips[randi() % tips.size()]
	_apply_poster()
	if has_node("%VersionLabel"):
		%VersionLabel.text = GameVersion.display()
	if has_node("%Title"):
		%Title.text = "Tuitui Run  %s" % GameVersion.display()
	%IdOk.pressed.connect(_commit_id)
	_maybe_dump_shot()


func _maybe_dump_shot() -> void:
	var path: String = OS.get_environment("TUITUI_SHOT")
	if path == "":
		return
	await get_tree().create_timer(0.85).timeout
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png(path)
	print("viewport_shot %s %dx%d" % [path, img.get_width(), img.get_height()])


func _apply_poster() -> void:
	var def: CharacterDef = Catalog.equipped_def()
	if def != null and def.shop_portrait != null:
		poster.texture = def.shop_portrait
	else:
		poster.texture = load("res://assets/characters/player/player_idle.png") as Texture2D


func _process(delta: float) -> void:
	if _waiting_id:
		return
	_t += delta
	bar.value = clampf(_t / _dur, 0.0, 1.0) * 100.0
	if _t >= _dur:
		_try_enter()


func _try_enter() -> void:
	if Settings.player_id != "":
		get_tree().change_scene_to_file("res://ui/home.tscn")
		return
	_waiting_id = true
	id_panel.visible = true


func _commit_id() -> void:
	var n: String = %IdEdit.text.strip_edges()
	if n.length() < 2:
		%IdEdit.placeholder_text = "至少两个字"
		return
	Settings.nickname = n
	var t: int = int(Time.get_unix_time_from_system())
	Settings.player_id = "%s_%d" % [n, t % 100000]
	Settings.save_to_disk()
	Save.nickname = n
	Save.player_id = Settings.player_id
	Save.persist()
	get_tree().change_scene_to_file("res://ui/home.tscn")
