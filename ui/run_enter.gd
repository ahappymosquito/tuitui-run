class_name RunEnter
extends Control

signal faded_out

## 大厅点开始后置位，进关遮罩用同一块不透明底，切场景才不会闪一下。
static var pending: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	_fill()


func _fill() -> void:
	if has_node("%Tip"):
		%Tip.text = Settings.run_guide_text()
	if has_node("%Title"):
		%Title.text = "马上开跑"
	if not has_node("%Poster"):
		return
	var def: CharacterDef = Catalog.equipped_def()
	if def != null and def.shop_portrait != null:
		%Poster.texture = def.shop_portrait
	else:
		%Poster.texture = load("res://assets/characters/player/player_idle.png") as Texture2D


func set_progress(p: float) -> void:
	if has_node("%Bar"):
		%Bar.value = clampf(p, 0.0, 1.0) * 100.0


func appear() -> void:
	_fill()
	visible = true
	modulate.a = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP


func fade_in(dur: float = 0.22) -> void:
	_fill()
	visible = true
	modulate.a = 0.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	var tw: Tween = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func fade_out(dur: float = 0.42) -> void:
	visible = true
	var tw: Tween = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(_after_out)


func _after_out() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	faded_out.emit()
