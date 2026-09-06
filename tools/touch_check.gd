extends SceneTree


func _initialize() -> void:
	var has_slide: bool = InputMap.has_action("slide")
	var has_jump: bool = InputMap.has_action("jump")
	var mouse_on_jump: bool = false
	if has_jump:
		for ev: InputEvent in InputMap.action_get_events("jump"):
			if ev is InputEventMouseButton:
				mouse_on_jump = true
	var cfg: RunnerConfig = RunnerConfig.new()
	print("has_slide=", has_slide)
	print("has_jump=", has_jump)
	print("mouse_on_jump=", mouse_on_jump)
	print("physics_ticks=", Engine.physics_ticks_per_second)
	print("max_fps=", Engine.max_fps)
	print("super_duration=", cfg.super_duration)
	print("sprint_lift=", cfg.sprint_lift)
	var ok: bool = has_slide and has_jump and not mouse_on_jump
	ok = ok and Engine.physics_ticks_per_second == 60
	ok = ok and is_equal_approx(cfg.super_duration, 15.0)
	ok = ok and is_equal_approx(cfg.sprint_lift, 150.0)
	print("TOUCH_OK" if ok else "TOUCH_FAIL")
	quit()
