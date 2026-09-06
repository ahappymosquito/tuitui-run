extends Control

@onready var local_col: VBoxContainer = %LocalCol
@onready var remote_col: VBoxContainer = %RemoteCol


func _ready() -> void:
	%Back.pressed.connect(func () -> void: get_tree().change_scene_to_file("res://ui/home.tscn"))
	Save.remote_updated.connect(_fill_remote)
	_fill_local()
	_fill_remote(Save.remote_top)
	Save.fetch_top()


func _fill_local() -> void:
	_fill(local_col, Save.load_board(), "还没有成绩")


func _fill_remote(rows: Array) -> void:
	_fill(remote_col, rows, "线上空榜")


func _fill(box: VBoxContainer, rows: Array, empty_text: String) -> void:
	for c: Node in box.get_children():
		c.queue_free()
	if rows.is_empty():
		var empty: Label = Label.new()
		empty.text = empty_text
		empty.modulate = Color(1, 1, 1, 0.55)
		box.add_child(empty)
		return
	var i: int = 1
	for row: Variant in rows:
		var bar: HBoxContainer = HBoxContainer.new()
		bar.custom_minimum_size = Vector2(0, 48)
		var rank: Label = Label.new()
		rank.custom_minimum_size = Vector2(48, 0)
		rank.text = "%02d" % i
		rank.add_theme_color_override("font_color", Color(0.95, 0.82, 0.42, 1) if i <= 3 else Color(1, 1, 1, 0.7))
		var nm: Label = Label.new()
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.text = str(row.get("name", "?"))
		var sc: Label = Label.new()
		sc.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		sc.custom_minimum_size = Vector2(120, 0)
		sc.text = "%d" % int(row.get("score", 0))
		sc.add_theme_color_override("font_color", Color(0.95, 0.86, 0.55, 1))
		bar.add_child(rank)
		bar.add_child(nm)
		bar.add_child(sc)
		box.add_child(bar)
		i += 1
		if i > 15:
			break
