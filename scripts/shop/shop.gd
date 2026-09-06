extends Control

const TEX_SKY: Texture2D = preload("res://assets/ui/lobby_clean.png")
const SFX_OK: AudioStream = preload("res://assets/sfx/score.wav")

var _status: Label
var _coins: Label
var _hint: Label
var _row: HBoxContainer
var _posters: Array[TextureRect] = []
var _bob_t: float = 0.0
var _sfx: AudioStreamPlayer
var _style_card: StyleBoxFlat
var _style_card_on: StyleBoxFlat
var _style_gold: StyleBoxFlat
var _style_gold_h: StyleBoxFlat
var _style_tab: StyleBoxFlat
var _style_tab_h: StyleBoxFlat


func _ready() -> void:
	_make_styles()
	_build()
	_refresh()
	Save.save_changed.connect(_refresh)


func _process(delta: float) -> void:
	_bob_t += delta
	var i: int = 0
	for poster: TextureRect in _posters:
		if poster.size.x > 1.0:
			poster.pivot_offset = poster.size * 0.5
		var wave: float = _bob_t * 1.7 + float(i) * 0.85
		poster.rotation = sin(wave) * 0.035
		var s: float = 1.0 + 0.018 * sin(_bob_t * 2.3 + float(i) * 0.6)
		poster.scale = Vector2(s, s)
		i += 1


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_go_home()
		get_viewport().set_input_as_handled()


func _make_styles() -> void:
	_style_card = _box(Color(0.08, 0.07, 0.12, 0.78), 22, Color(1, 1, 1, 0.14), 1, 16)
	_style_card_on = _box(Color(0.16, 0.12, 0.06, 0.88), 22, Color(1.0, 0.82, 0.32, 0.95), 3, 16)
	_style_gold = _box(Color(1, 0.78, 0.28, 1), 16, Color(0, 0, 0, 0), 0, 8)
	_style_gold_h = _box(Color(1, 0.86, 0.42, 1), 16, Color(0, 0, 0, 0), 0, 8)
	_style_tab = _box(Color(0.10, 0.09, 0.14, 0.86), 16, Color(1, 1, 1, 0.16), 1, 8)
	_style_tab_h = _box(Color(0.16, 0.14, 0.20, 0.92), 16, Color(1, 1, 1, 0.22), 1, 8)


func _box(bg: Color, radius: int, border: Color, bw: int, pad: int) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.set_border_width_all(bw)
	s.border_color = border
	s.set_content_margin_all(pad)
	return s


func _build() -> void:
	if not has_node("Sky"):
		var sky: TextureRect = TextureRect.new()
		sky.name = "Sky"
		sky.set_anchors_preset(Control.PRESET_FULL_RECT)
		sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sky.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		sky.texture = TEX_SKY
		add_child(sky)
		move_child(sky, 0)
	var wash: ColorRect = ColorRect.new()
	wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wash.color = Color(0.05, 0.03, 0.08, 0.28)
	add_child(wash)
	var top: ColorRect = ColorRect.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 64.0
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.color = Color(0.06, 0.05, 0.10, 0.38)
	add_child(top)
	var title: Label = Label.new()
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 10.0
	title.offset_bottom = 52.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.90, 0.94, 1))
	title.add_theme_color_override("font_outline_color", Color(0.10, 0.04, 0.12, 0.8))
	title.add_theme_constant_override("outline_size", 6)
	title.text = "角色商店"
	add_child(title)
	_hint = Label.new()
	_hint.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_hint.offset_top = 68.0
	_hint.offset_bottom = 96.0
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 16)
	_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.78))
	add_child(_hint)
	_coins = Label.new()
	_coins.name = "Coins"
	_coins.unique_name_in_owner = true
	_coins.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_coins.offset_top = 96.0
	_coins.offset_bottom = 128.0
	_coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coins.add_theme_font_size_override("font_size", 20)
	_coins.add_theme_color_override("font_color", Color(1, 0.86, 0.42, 1))
	_coins.add_theme_color_override("font_outline_color", Color(0.14, 0.06, 0.04, 0.85))
	_coins.add_theme_constant_override("outline_size", 4)
	add_child(_coins)
	_row = HBoxContainer.new()
	_row.name = "Row"
	_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	_row.offset_left = 40.0
	_row.offset_top = 140.0
	_row.offset_right = -40.0
	_row.offset_bottom = -96.0
	_row.add_theme_constant_override("separation", 22)
	add_child(_row)
	_status = Label.new()
	_status.name = "Status"
	_status.unique_name_in_owner = true
	_status.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_status.offset_top = -88.0
	_status.offset_bottom = -58.0
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 16)
	_status.add_theme_color_override("font_color", Color(1, 0.92, 0.78, 0.92))
	add_child(_status)
	var back: Button = Button.new()
	back.text = "返回大厅"
	back.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	back.offset_left = 480.0
	back.offset_right = -480.0
	back.offset_top = -48.0
	back.offset_bottom = -12.0
	_paint_tab(back)
	back.pressed.connect(_go_home)
	add_child(back)
	_sfx = AudioStreamPlayer.new()
	_sfx.bus = "SFX"
	_sfx.stream = SFX_OK
	add_child(_sfx)
	for id: StringName in Catalog.all_ids():
		var def: CharacterDef = Catalog.get_def(id)
		if def == null:
			continue
		_row.add_child(_make_card(def))


func _make_card(def: CharacterDef) -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.set_meta("char_id", String(def.id))
	card.add_theme_stylebox_override("panel", _style_card)
	var inner: VBoxContainer = VBoxContainer.new()
	inner.name = "Inner"
	inner.add_theme_constant_override("separation", 6)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(inner)
	var stage: Control = Control.new()
	stage.custom_minimum_size = Vector2(0, 250)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.clip_contents = true
	inner.add_child(stage)
	var poster: TextureRect = TextureRect.new()
	poster.name = "Poster"
	poster.set_anchors_preset(Control.PRESET_FULL_RECT)
	poster.offset_left = 4.0
	poster.offset_top = 4.0
	poster.offset_right = -4.0
	poster.offset_bottom = -4.0
	poster.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	poster.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	poster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	poster.texture = def.shop_portrait
	stage.add_child(poster)
	_posters.append(poster)
	var name_l: Label = Label.new()
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 22)
	name_l.add_theme_color_override("font_color", Color(1.0, 0.93, 0.88, 1))
	name_l.text = def.display_name
	inner.add_child(name_l)
	var blurb: Label = Label.new()
	blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	blurb.add_theme_font_size_override("font_size", 15)
	blurb.add_theme_color_override("font_color", Color(1.0, 0.82, 0.42, 0.95))
	blurb.text = def.skill_blurb
	inner.add_child(blurb)
	var ribbon: Label = Label.new()
	ribbon.name = "Ribbon"
	ribbon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ribbon.add_theme_font_size_override("font_size", 13)
	ribbon.add_theme_color_override("font_color", Color(1.0, 0.86, 0.45, 1))
	ribbon.text = ""
	inner.add_child(ribbon)
	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(0, 46)
	btn.name = "Action"
	btn.set_meta("char_id", String(def.id))
	btn.pressed.connect(_on_action.bind(String(def.id)))
	inner.add_child(btn)
	var id: String = String(def.id)
	card.mouse_entered.connect(func () -> void: _on_card_hover(id, true))
	card.mouse_exited.connect(func () -> void: _on_card_hover(id, false))
	return card


func _on_card_hover(id: String, on: bool) -> void:
	var card: Control = _card_of(id)
	if card == null:
		return
	if on and Save.equipped != id:
		card.modulate = Color(1.06, 1.04, 0.96)
		_punch(card, 1.02, 0.08)
	elif Save.equipped == id:
		card.modulate = Color(1.04, 1.02, 0.94)
	else:
		card.modulate = Color.WHITE


func _on_action(id: String) -> void:
	var def: CharacterDef = Catalog.get_def(StringName(id))
	if def == null:
		return
	if Save.is_owned(id):
		if Save.equipped == id:
			_status.text = def.display_name + " 已经在舞台上啦"
			_punch(_card_of(id), 1.03, 0.10)
			return
		if Save.equip(id):
			_status.text = "请到舞台 ～ " + def.display_name
			_ding()
			_punch(_card_of(id), 1.06, 0.12)
		else:
			_status.text = "未拥有，不能穿"
		_refresh()
		return
	if def.currency == &"coin":
		if Save.buy_with_coins(id):
			Save.equip(id)
			_status.text = "买下并穿上 " + def.display_name + "！"
			_ding()
			_punch(_card_of(id), 1.08, 0.14)
		else:
			_status.text = "橘子币不够（需要 %d）" % def.price
			_flash_coins()
		_refresh()
		return
	if Settings.debug_unlock_iap:
		Save.grant_iap(id)
		Save.equip(id)
		_status.text = "调试发货 " + def.display_name
		_ding()
		_punch(_card_of(id), 1.06, 0.12)
		_refresh()
		return
	_status.text = "内购未接通，可在设置里打开调试解锁"


func _refresh() -> void:
	_coins.text = "橘子币  %d" % Save.coins
	var eq: CharacterDef = Catalog.equipped_def()
	_hint.text = "舞台上是  " + (eq.display_name if eq != null else "推推")
	if _row == null:
		return
	for card_n: Node in _row.get_children():
		var card: PanelContainer = card_n as PanelContainer
		if card == null:
			continue
		var id: String = str(card.get_meta("char_id", ""))
		var def: CharacterDef = Catalog.get_def(StringName(id))
		var btn: Button = card.get_node_or_null("Inner/Action") as Button
		var ribbon: Label = card.get_node_or_null("Inner/Ribbon") as Label
		if btn == null or def == null:
			continue
		var on: bool = Save.equipped == id
		card.add_theme_stylebox_override("panel", _style_card_on if on else _style_card)
		card.modulate = Color(1.04, 1.02, 0.94) if on else Color.WHITE
		if ribbon != null:
			ribbon.visible = on
			ribbon.text = "正在舞台上" if on else ""
		if on:
			btn.text = "使用中"
			_paint_gold(btn)
		elif Save.is_owned(id):
			btn.text = "穿上"
			_paint_tab(btn)
		elif def.currency == &"coin":
			btn.text = "购买  %d" % def.price
			_paint_gold(btn)
		else:
			btn.text = "内购" if not Settings.debug_unlock_iap else "调试解锁"
			_paint_tab(btn)


func _card_of(id: String) -> Control:
	if _row == null:
		return null
	for card_n: Node in _row.get_children():
		if str(card_n.get_meta("char_id", "")) == id:
			return card_n as Control
	return null


func _paint_gold(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", _style_gold)
	btn.add_theme_stylebox_override("hover", _style_gold_h)
	btn.add_theme_stylebox_override("pressed", _style_gold)
	btn.add_theme_stylebox_override("focus", _style_gold)
	btn.add_theme_color_override("font_color", Color(0.16, 0.09, 0.02, 1))
	btn.add_theme_font_size_override("font_size", 18)


func _paint_tab(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", _style_tab)
	btn.add_theme_stylebox_override("hover", _style_tab_h)
	btn.add_theme_stylebox_override("pressed", _style_tab)
	btn.add_theme_stylebox_override("focus", _style_tab)
	btn.add_theme_color_override("font_color", Color(1, 0.94, 0.90, 1))
	btn.add_theme_font_size_override("font_size", 16)


func _punch(n: Control, amp: float, dur: float) -> void:
	if n == null:
		return
	n.pivot_offset = n.size * 0.5
	var tw: Tween = n.create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(n, "scale", Vector2(amp, amp), dur * 0.45)
	tw.tween_property(n, "scale", Vector2.ONE, dur * 0.55)


func _flash_coins() -> void:
	_coins.modulate = Color(1.0, 0.42, 0.38, 1)
	var tw: Tween = create_tween()
	tw.tween_property(_coins, "modulate", Color.WHITE, 0.38)


func _ding() -> void:
	if _sfx != null:
		_sfx.play()


func _go_home() -> void:
	get_tree().change_scene_to_file("res://ui/home.tscn")
