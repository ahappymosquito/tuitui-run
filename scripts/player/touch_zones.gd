class_name TouchZones
extends CanvasLayer

## 左 40% 滑、右 60% 跳，热区高约底部 28%。触摸写入 InputMap jump / slide。
## 仅手机 / 触屏显示；PC 键盘仍走 InputMap，不盖舞台。

const SLIDE_WIDTH: float = 0.40
const ZONE_HEIGHT: float = 0.28
const MOUSE_PTR: int = -1

@onready var slide_zone: ColorRect = %SlideZone
@onready var jump_zone: ColorRect = %JumpZone
@onready var over_root: Control = %GameOver
@onready var pause_root: Control = %PauseRoot

var _slide_ids: Dictionary = {}
var _jump_ids: Dictionary = {}
var _slide_down: bool = false
var _jump_down: bool = false


func _ready() -> void:
	layer = 10
	if not InputMap.has_action("slide"):
		InputMap.add_action("slide")
	visible = _should_show()
	set_process_input(visible)
	_layout()
	get_viewport().size_changed.connect(_layout)


func _should_show() -> bool:
	return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()


func _layout() -> void:
	if slide_zone == null or jump_zone == null:
		return
	slide_zone.anchor_left = 0.0
	slide_zone.anchor_right = SLIDE_WIDTH
	slide_zone.anchor_top = 1.0 - ZONE_HEIGHT
	slide_zone.anchor_bottom = 1.0
	slide_zone.offset_left = 0.0
	slide_zone.offset_right = 0.0
	slide_zone.offset_top = 0.0
	slide_zone.offset_bottom = 0.0
	jump_zone.anchor_left = SLIDE_WIDTH
	jump_zone.anchor_right = 1.0
	jump_zone.anchor_top = 1.0 - ZONE_HEIGHT
	jump_zone.anchor_bottom = 1.0
	jump_zone.offset_left = 0.0
	jump_zone.offset_right = 0.0
	jump_zone.offset_top = 0.0
	jump_zone.offset_bottom = 0.0


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if _blocked():
		_clear_all()
		return
	if event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		_handle_ptr(st.index, st.pressed, st.position)
	elif event is InputEventScreenDrag:
		var sd: InputEventScreenDrag = event as InputEventScreenDrag
		_handle_ptr(sd.index, true, sd.position)
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		_handle_ptr(MOUSE_PTR, mb.pressed, mb.position)
	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		if _jump_ids.has(MOUSE_PTR) or _slide_ids.has(MOUSE_PTR):
			_handle_ptr(MOUSE_PTR, true, mm.position)


func _handle_ptr(id: int, pressed: bool, pos: Vector2) -> void:
	_slide_ids.erase(id)
	_jump_ids.erase(id)
	if pressed:
		var zone: StringName = _zone_at(pos)
		if zone == &"slide":
			_slide_ids[id] = true
		elif zone == &"jump":
			_jump_ids[id] = true
	_sync()


func _zone_at(pos: Vector2) -> StringName:
	var vr: Rect2 = get_viewport().get_visible_rect()
	if vr.size.x <= 1.0 or vr.size.y <= 1.0:
		return &""
	var local: Vector2 = pos - vr.position
	if local.y < vr.size.y * (1.0 - ZONE_HEIGHT):
		return &""
	if local.x < vr.size.x * SLIDE_WIDTH:
		return &"slide"
	if local.x <= vr.size.x:
		return &"jump"
	return &""


func _blocked() -> bool:
	if over_root != null and over_root.visible:
		return true
	if pause_root != null and pause_root.visible:
		return true
	return false


func _sync() -> void:
	var want_slide: bool = not _slide_ids.is_empty()
	var want_jump: bool = not _jump_ids.is_empty()
	if want_slide != _slide_down:
		_slide_down = want_slide
		if want_slide:
			Input.action_press("slide")
		else:
			Input.action_release("slide")
	if want_jump != _jump_down:
		_jump_down = want_jump
		if want_jump:
			Input.action_press("jump")
		else:
			Input.action_release("jump")


func _clear_all() -> void:
	_slide_ids.clear()
	_jump_ids.clear()
	_sync()


func _exit_tree() -> void:
	_clear_all()
