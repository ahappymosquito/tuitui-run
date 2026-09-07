class_name GameVersion
extends Object

## 每个打包版本只改这里，然后同步 project.godot / export_presets.cfg 的 version。
const STRING: String = "1.6.4"


static func display() -> String:
	return "v" + STRING


static func window_title() -> String:
	# 引擎 debug 包会自己在标题后加 (DEBUG)，这里不要再拼一次。
	return "Tuitui Run " + display()


static func apply_title() -> void:
	var t: String = window_title()
	DisplayServer.window_set_title(t)
	var loop: MainLoop = Engine.get_main_loop()
	if not (loop is SceneTree):
		return
	var st: SceneTree = loop as SceneTree
	if st.root != null:
		st.root.title = t
