extends SceneTree


func _initialize() -> void:
	Engine.max_fps = RunnerConfig.MAX_FPS
	Engine.physics_ticks_per_second = RunnerConfig.PHYSICS_TICKS
	var cfg: RunnerConfig = RunnerConfig.new()
	var dist: float = 10000.0
	var coin_value: int = 10
	var rings: int = 2
	var score: int = int(dist * RunnerConfig.SCORE_DIST) + coin_value * RunnerConfig.SCORE_COIN + rings * RunnerConfig.SCORE_RING
	var expect: int = 400 + 120 + 160
	print("physics_ticks=", Engine.physics_ticks_per_second)
	print("max_fps=", Engine.max_fps)
	print("super_duration=", cfg.super_duration)
	print("sprint_lift=", cfg.sprint_lift)
	print("coin_worth=", RunnerConfig.COIN_GOLD, "/", RunnerConfig.COIN_SILVER, "/", RunnerConfig.COIN_COPPER)
	print("score_sample=", score, " expect=", expect)
	var ok: bool = Engine.physics_ticks_per_second == 60
	ok = ok and Engine.max_fps == 60
	ok = ok and is_equal_approx(cfg.super_duration, 15.0)
	ok = ok and is_equal_approx(cfg.sprint_lift, 150.0)
	ok = ok and score == expect
	ok = ok and is_equal_approx(RunnerConfig.SCORE_DIST, 0.04)
	ok = ok and RunnerConfig.SCORE_COIN == 12
	ok = ok and RunnerConfig.SCORE_RING == 80
	print("FREEZE_OK" if ok else "FREEZE_FAIL")
	quit()
