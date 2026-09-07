class_name TouchZones
extends CanvasLayer

## 天天酷跑式触控：左下滑、右跳跃。底部大热区 + 圆键标识。仅触屏/手机显示。

const SLIDE_WIDTH: float = 0.40
const ZONE_HEIGHT: float = 0.32
const MOUSE_PTR: int = -1
const TEX_SLIDE: Texture2D = preload("res://assets/ui/btn_slide.png")
const TEX_JUMP: Texture2D = preload("res://assets/ui/btn_jump.png")

@onready var slide_zone: ColorRect = %SlideZone
@onready var jump_zone: ColorRect = %JumpZone
@onready var over_root: Control = %GameOver
@onready var pause_root: Control = %PauseRoot

var _slide_ids: Dictionary = {}
var _jump_ids: Dictionary = {}
var _slide_down: bool = false
var _jump_down: bool = false
var _slide_pad: TextureRect
var _jump_pad: TextureRect
var _slide_cap: Label
var _jump_cap: Label
var _guide: Control
var _guide_lab: Label
var _guide_step: int = -1
var _guide_t: float = 0.0
var _bob: float = 0.0


func _ready() -> void:
	layer = 10
	if not InputMap.has_action("slide"):
		InputMap.add_action("slide")
	visible = _should_show()
	set_process_input(visible)
	set_process(visible)
	_hide_old_hints()
	_build_pads()
	_build_guide()
	_layout()
	get_viewport().size_changed.connect(_layout)
	if visible:
		_maybe_start_guide()


func _should_show() -> bool:
	return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()


func _hide_old_hints() -> void:
	if slide_zone != null:
		slide_zone.color = Color(0, 0, 0, 0)
		var h: Node = slide_zone.get_node_or_null("SlideHint")
		if h is CanvasItem:
			(h as CanvasItem).visible = false
	if jump_zone != null:
		jump_zone.color = Color(0, 0, 0, 0)
		var j: Node = jump_zone.get_node_or_null("JumpHint")
		if j is CanvasItem:
			(j as CanvasItem).visible = false


func _build_pads() -> void:
	_slide_pad = _make_pad(TEX_SLIDE, "SlidePad")
	_jump_pad = _make_pad(TEX_JUMP, "JumpPad")
	_slide_cap = _make_cap("下滑", "SlideCap")
	_jump_cap = _make_cap("跳跃", "JumpCap")
	add_child(_slide_pad)
	add_child(_jump_pad)
	add_child(_slide_cap)
	add_child(_jump_cap)


func _make_pad(tex: Texture2D, id: String) -> TextureRect:
	var pad: TextureRect = TextureRect.new()
	pad.name = id
	pad.texture = tex
	pad.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pad.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.pivot_offset = Vector2(80, 80)
	return pad


func _make_cap(text: String, id: String) -> Label:
	var lab: Label = Label.new()
	lab.name = id
	lab.text = text
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lab.add_theme_font_size_override("font_size", 22)
	lab.add_theme_color_override("font_color", Color(1.0, 0.94, 0.82, 0.95))
	lab.add_theme_color_override("font_outline_color", Color(0.12, 0.04, 0.08, 0.88))
	lab.add_theme_constant_override("outline_size", 7)
	return lab


func _build_guide() -> void:
	_guide = Control.new()
	_guide.name = "TouchGuide"
	_guide.set_anchors_preset(Control.PRESET_FULL_RECT)
	_guide.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_guide.visible = false
	var dim: ColorRect = ColorRect.new()
	dim.name = "Dim"
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.04, 0.02, 0.06, 0.38)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_guide_lab = Label.new()
	_guide_lab.name = "GuideText"
	_guide_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_guide_lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_guide_lab.add_theme_font_size_override("font_size", 28)
	_guide_lab.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88, 1.0))
	_guide_lab.add_theme_color_override("font_outline_color", Color(0.10, 0.04, 0.08, 0.92))
	_guide_lab.add_theme_constant_override("outline_size", 8)
	_guide_lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_guide.add_child(dim)
	_guide.add_child(_guide_lab)
	add_child(_guide)


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
	_layout_pads()


func _layout_pads() -> void:
	if _slide_pad == null or _jump_pad == null:
		return
	var vr: Vector2 = get_viewport().get_visible_rect().size
	var pad: float = clampf(minf(vr.x, vr.y) * 0.20, 118.0, 176.0)
	var m: float = 24.0
	var y: float = vr.y - pad - m - 36.0
	_slide_pad.size = Vector2(pad, pad)
	_slide_pad.position = Vector2(m + 8.0, y)
	_slide_pad.pivot_offset = Vector2(pad * 0.5, pad * 0.5)
	_jump_pad.size = Vector2(pad, pad)
	_jump_pad.position = Vector2(vr.x - pad - m - 8.0, y)
	_jump_pad.pivot_offset = Vector2(pad * 0.5, pad * 0.5)
	_slide_cap.size = Vector2(pad + 24.0, 32.0)
	_slide_cap.position = Vector2(_slide_pad.position.x - 12.0, _slide_pad.position.y + pad - 2.0)
	_jump_cap.size = Vector2(pad + 24.0, 32.0)
	_jump_cap.position = Vector2(_jump_pad.position.x - 12.0, _jump_pad.position.y + pad - 2.0)
	if _guide_lab != null:
		_guide_lab.size = Vector2(vr.x * 0.72, 96.0)
		_guide_lab.position = Vector2(vr.x * 0.14, vr.y * 0.38)


func _process(delta: float) -> void:
	if not visible:
		return
	_bob += delta
	_update_pad_look(delta)
	if _guide_step >= 0:
		_guide_t += delta
		if _guide_t >= 3.4:
			_advance_guide()


func _update_pad_look(_delta: float) -> void:
	if _slide_pad == null or _jump_pad == null:
		return
	var slide_s: float = 0.90 if _slide_down else 1.0 + 0.035 * sin(_bob * 2.5)
	var jump_s: float = 0.90 if _jump_down else 1.0 + 0.035 * sin(_bob * 2.5 + 1.1)
	if _guide_step == 0:
		jump_s = 1.08 + 0.07 * sin(_bob * 6.0)
	elif _guide_step == 1:
		slide_s = 1.08 + 0.07 * sin(_bob * 6.0)
	_slide_pad.scale = Vector2(slide_s, slide_s)
	_jump_pad.scale = Vector2(jump_s, jump_s)
	_slide_pad.modulate = Color(1.25, 1.18, 0.90, 1.0) if _slide_down else Color.WHITE
	_jump_pad.modulate = Color(1.25, 1.18, 0.90, 1.0) if _jump_down else Color.WHITE
	if _guide_step == 0:
		_jump_pad.modulate = Color(1.35, 1.22, 0.85, 1.0)
		_slide_pad.modulate = Color(0.55, 0.55, 0.58, 0.55)
	elif _guide_step == 1:
		_slide_pad.modulate = Color(1.35, 1.22, 0.85, 1.0)
		_jump_pad.modulate = Color(0.55, 0.55, 0.58, 0.55)


func _maybe_start_guide() -> void:
	if Save.touch_guide_done:
		return
	_guide_step = 0
	_guide_t = 0.0
	if _guide != null:
		_guide.visible = true
	_set_guide_text("右边 跳跃\n点金色上键，跳过障碍")


func _advance_guide() -> void:
	_guide_step += 1
	_guide_t = 0.0
	if _guide_step == 1:
		_set_guide_text("左边 下滑\n点金色下键，钻过矮障")
	elif _guide_step == 2:
		_set_guide_text("跟着金币走\n路就在弧线上")
	else:
		_finish_guide()


func _finish_guide() -> void:
	_guide_step = -1
	if _guide != null:
		_guide.visible = false
	if _slide_pad != null:
		_slide_pad.modulate = Color.WHITE
	if _jump_pad != null:
		_jump_pad.modulate = Color.WHITE
	if not Save.touch_guide_done:
		Save.touch_guide_done = true
		Save.persist()


func _set_guide_text(t: String) -> void:
	if _guide_lab != null:
		_guide_lab.text = t


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
	var was_slide: bool = _slide_ids.has(id)
	var was_jump: bool = _jump_ids.has(id)
	_slide_ids.erase(id)
	_jump_ids.erase(id)
	if pressed:
		var zone: StringName = _zone_at(pos)
		if zone == &"slide":
			_slide_ids[id] = true
			if _guide_step == 1 and not was_slide:
				_advance_guide()
		elif zone == &"jump":
			_jump_ids[id] = true
			if _guide_step == 0 and not was_jump:
				_advance_guide()
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
