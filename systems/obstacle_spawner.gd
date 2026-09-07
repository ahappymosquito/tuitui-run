class_name ObstacleSpawner
extends Node2D

const TEX_BOOKS: Texture2D = preload("res://assets/obstacles/books.png")
const TEX_CHEST: Texture2D = preload("res://assets/obstacles/chest.png")
const TEX_SHELF: Texture2D = preload("res://assets/obstacles/shelf.png")
const TEX_STAR: Texture2D = preload("res://assets/obstacles/star.png")
const TEX_RING: Texture2D = preload("res://assets/obstacles/star_gate.png")
const TEX_SPIKES: Texture2D = preload("res://assets/obstacles/spikes.png")
const TEX_BARRIER: Texture2D = preload("res://assets/obstacles/barrier.png")
const TEX_CLIFF: Texture2D = preload("res://assets/obstacles/cliff.png")
const OBS_SCENE: PackedScene = preload("res://systems/obstacle.tscn")
const COIN_SCENE: PackedScene = preload("res://systems/coin.tscn")

signal coin_picked(coin: RunCoin)
signal ring_bonus

var config: RunnerConfig
var world_speed: float = 0.0
var magnet: bool = false
var rest_mode: bool = false
var _obs_pool: ObjectPool
var _coin_pool: ObjectPool
var _active: Array[Obstacle] = []
var _coins: Array[RunCoin] = []
var _elapsed: float = 0.0
var _running: bool = false
var _recent: Array[Obstacle.Kind] = []
var _score: int = 0
var _player: Player = null
var _shape_i: int = 0
var spawn_hold: float = 0.0
var _run_distance: float = 0.0
var _chunk_recent: PackedStringArray = PackedStringArray()
var _teach_i: int = 0
var TEACH_SEQ: PackedStringArray = PackedStringArray([
	"teach_flat", "teach_low_slide", "teach_high_jump",
	"teach_coin_arc", "teach_fire_ring", "teach_gap_double",
])
var TEACH_POOL: PackedStringArray = PackedStringArray([
	"teach_flat", "teach_low_slide", "teach_high_jump",
	"teach_coin_arc", "teach_fire_ring", "teach_gap_double",
])
var EASY_POOL: PackedStringArray = PackedStringArray([
	"teach_low_slide", "teach_high_jump", "teach_fire_ring", "mix_coin_side",
])
var MID_POOL: PackedStringArray = PackedStringArray([
	"mix_barrier_spikes", "mix_spikes_barrier", "mix_coin_side",
	"mix_ring_spikes", "mix_shelf",
])
var HARD_POOL: PackedStringArray = PackedStringArray([
	"mix_barrier_spikes", "mix_spikes_barrier", "mix_double_gap",
	"mix_hard_combo", "mix_books_chest", "teach_gap_double",
])


func setup(p_config: RunnerConfig, player: Player) -> void:
	config = p_config
	_player = player
	_obs_pool = ObjectPool.new(OBS_SCENE, self, 20)
	_coin_pool = ObjectPool.new(COIN_SCENE, self, 72)


func start() -> void:
	clear()
	world_speed = 0.0
	_elapsed = 0.0
	_running = true
	_score = 0
	rest_mode = false
	_shape_i = 0
	spawn_hold = 0.0
	_run_distance = 0.0
	_teach_i = 0
	_chunk_recent = PackedStringArray()
	_spawn_tutorial()


func stop() -> void:
	_running = false
	for obs: Obstacle in _active:
		obs.frozen = true
		obs.set_speed(0.0)
	for c: RunCoin in _coins:
		c.set_speed(0.0)


func resume_run() -> void:
	_running = true
	for obs: Obstacle in _active:
		obs.frozen = false


func set_score(value: int) -> void:
	_score = value


func set_run_distance(value: float) -> void:
	_run_distance = value


func run_meters() -> float:
	return _run_distance * 0.1


func chunk_pool_size() -> int:
	var ids: Dictionary = {}
	for n: String in TEACH_SEQ:
		ids[n] = true
	for n: String in TEACH_POOL:
		ids[n] = true
	for n: String in EASY_POOL:
		ids[n] = true
	for n: String in MID_POOL:
		ids[n] = true
	for n: String in HARD_POOL:
		ids[n] = true
	return ids.size()


func set_moving_speed(value: float) -> void:
	world_speed = value
	for obs: Obstacle in _active:
		obs.set_speed(value)
	for c: RunCoin in _coins:
		c.set_speed(value)


func clear() -> void:
	for obs: Obstacle in _active.duplicate():
		_recycle_obs(obs)
	for c: RunCoin in _coins.duplicate():
		_recycle_coin(c)
	_active.clear()
	_coins.clear()
	_recent.clear()


func clear_obstacles_keep_coins() -> void:
	for obs: Obstacle in _active.duplicate():
		_recycle_obs(obs)
	_active.clear()


func _physics_process(delta: float) -> void:
	if not _running or config == null:
		return
	_elapsed += delta
	if spawn_hold > 0.0:
		spawn_hold = maxf(spawn_hold - delta, 0.0)
	if rest_mode:
		for c: RunCoin in _coins:
			c.magnet = true
		return
	if world_speed <= 0.0:
		return
	if spawn_hold <= 0.0:
		_try_spawn()
	for c: RunCoin in _coins:
		c.magnet = magnet


func _spawn_tutorial() -> void:
	_emit_chunk("teach_flat", config.first_spawn_x)
	_mark_following_except_last()


func _mark_following_except_last() -> void:
	if _active.is_empty():
		return
	for i: int in range(_active.size() - 1):
		_active[i].following_created = true
	_active[_active.size() - 1].following_created = false


func _try_spawn() -> void:
	if _active.is_empty():
		_spawn_chunk(config.spawn_x)
		return
	var last: Obstacle = _active[_active.size() - 1]
	if last.following_created:
		return
	if last.right_edge() + last.gap < config.spawn_x:
		_spawn_chunk(config.spawn_x)
		last.following_created = true


func _spawn_chunk(origin_x: float) -> void:
	_emit_chunk(_pick_chunk_id(), origin_x)


func _pick_chunk_id() -> String:
	var meters: float = run_meters()
	var id: String = ""
	if _teach_i < TEACH_SEQ.size() and meters < 600.0:
		id = TEACH_SEQ[_teach_i]
		_teach_i += 1
	else:
		var pool: PackedStringArray
		if meters < 200.0:
			pool = PackedStringArray(["teach_flat", "teach_low_slide", "teach_high_jump"])
		elif meters < 360.0:
			pool = TEACH_POOL
		elif meters < 600.0:
			pool = _concat_pools(TEACH_POOL, EASY_POOL)
		elif meters < 1200.0:
			pool = _concat_pools(EASY_POOL, MID_POOL)
		else:
			pool = _concat_pools(MID_POOL, HARD_POOL)
		id = pool[randi() % pool.size()]
		var same: int = 0
		var i: int = _chunk_recent.size() - 1
		while i >= 0 and _chunk_recent[i] == id:
			same += 1
			i -= 1
		if same >= 2:
			for alt: String in pool:
				if alt != id:
					id = alt
					break
		if _is_gap(id) and _chunk_recent.size() > 0 and _is_gap(_chunk_recent[_chunk_recent.size() - 1]):
			id = "teach_flat"
	_chunk_recent.append(id)
	if _chunk_recent.size() > 8:
		_chunk_recent.remove_at(0)
	return id


func _concat_pools(a: PackedStringArray, b: PackedStringArray) -> PackedStringArray:
	var out: PackedStringArray = a.duplicate()
	out.append_array(b)
	return out


func _is_gap(id: String) -> bool:
	return id == "teach_gap_double" or id == "mix_double_gap"


func _emit_chunk(id: String, origin_x: float) -> void:
	var speed: float = _current_speed()
	var gap: float = _fair_gap(speed)
	var placed: Array[Obstacle] = []
	match id:
		"teach_flat":
			var none: Array[Obstacle] = []
			_spawn_jump_arc_coins(origin_x + speed * _apex_time(), speed, 7, none)
		"teach_low_slide":
			placed.append(_spawn_obstacle(Obstacle.Kind.BARRIER, speed, gap, origin_x))
		"teach_high_jump":
			placed.append(_spawn_obstacle(Obstacle.Kind.SHELF, speed, gap, origin_x))
		"teach_gap_double":
			placed.append(_spawn_obstacle(Obstacle.Kind.CLIFF, speed, gap * 1.05, origin_x))
		"teach_coin_arc":
			placed.append(_spawn_obstacle(Obstacle.Kind.BOOKS, speed, gap, origin_x))
		"teach_fire_ring":
			var ring0: Obstacle = _spawn_obstacle(Obstacle.Kind.RING, speed, gap, origin_x)
			if ring0 != null and not ring0.ring_cleared.is_connected(_on_ring):
				ring0.ring_cleared.connect(_on_ring)
			placed.append(ring0)
		"mix_barrier_spikes":
			var a: Obstacle = _spawn_obstacle(Obstacle.Kind.BARRIER, speed, gap, origin_x)
			if a != null:
				a.following_created = true
			placed.append(a)
			placed.append(_spawn_obstacle(Obstacle.Kind.SPIKES, speed, gap, origin_x + 260.0))
		"mix_spikes_barrier":
			var s: Obstacle = _spawn_obstacle(Obstacle.Kind.SPIKES, speed, gap, origin_x)
			if s != null:
				s.following_created = true
			placed.append(s)
			placed.append(_spawn_obstacle(Obstacle.Kind.BARRIER, speed, gap, origin_x + 250.0))
		"mix_double_gap":
			var c1: Obstacle = _spawn_obstacle(Obstacle.Kind.CLIFF, speed, gap * 1.15, origin_x)
			if c1 != null:
				c1.following_created = true
			placed.append(c1)
			placed.append(_spawn_obstacle(Obstacle.Kind.CLIFF, speed, gap * 1.15, origin_x + gap + 180.0))
		"mix_coin_side":
			placed.append(_spawn_obstacle(Obstacle.Kind.CHEST, speed, gap, origin_x))
		"mix_ring_spikes":
			var ring1: Obstacle = _spawn_obstacle(Obstacle.Kind.RING, speed, gap, origin_x)
			if ring1 != null:
				if not ring1.ring_cleared.is_connected(_on_ring):
					ring1.ring_cleared.connect(_on_ring)
				ring1.following_created = true
			placed.append(ring1)
			placed.append(_spawn_obstacle(Obstacle.Kind.SPIKES, speed, gap, origin_x + 280.0))
		"mix_shelf":
			placed.append(_spawn_obstacle(Obstacle.Kind.SHELF, speed, gap, origin_x))
		"mix_books_chest":
			var bks: Obstacle = _spawn_obstacle(Obstacle.Kind.BOOKS, speed, gap, origin_x)
			if bks != null:
				bks.following_created = true
			placed.append(bks)
			placed.append(_spawn_obstacle(Obstacle.Kind.CHEST, speed, gap, origin_x + 220.0))
		"mix_hard_combo":
			var sp: Obstacle = _spawn_obstacle(Obstacle.Kind.SPIKES, speed, gap, origin_x)
			if sp != null:
				sp.following_created = true
			placed.append(sp)
			var br: Obstacle = _spawn_obstacle(Obstacle.Kind.BARRIER, speed, gap, origin_x + 240.0)
			if br != null:
				br.following_created = true
			placed.append(br)
			placed.append(_spawn_obstacle(Obstacle.Kind.CLIFF, speed, gap * 1.1, origin_x + 520.0))
		_:
			placed.append(_spawn_obstacle(_pick_ground(), speed, gap, origin_x))
	if not placed.is_empty() and placed[0] != null:
		_spawn_lead_coins(placed[0], speed, placed)
		for i: int in range(1, placed.size()):
			_spawn_follow_coins(placed[i], speed, placed)


func _spawn_obstacle(kind: Obstacle.Kind, speed: float, gap: float, x: float = -1.0) -> Obstacle:
	var node: Node = _obs_pool.acquire()
	var obs: Obstacle = node as Obstacle
	if not obs.recycled.is_connected(_on_obs_recycled):
		obs.recycled.connect(_on_obs_recycled)
	var tex: Texture2D
	var scl: float
	var air_y: float = config.ground_y
	match kind:
		Obstacle.Kind.BOOKS:
			tex = TEX_BOOKS
			scl = 0.15
		Obstacle.Kind.CHEST:
			tex = TEX_CHEST
			scl = 0.11
		Obstacle.Kind.SHELF:
			tex = TEX_SHELF
			scl = 0.065
		Obstacle.Kind.STAR:
			tex = TEX_STAR
			scl = 0.11
			air_y = config.ground_y - 70.0
		Obstacle.Kind.RING:
			tex = TEX_RING
			scl = 0.28
		Obstacle.Kind.SPIKES:
			tex = TEX_SPIKES
			scl = 0.085
		Obstacle.Kind.BARRIER:
			tex = TEX_BARRIER
			scl = 0.12
		Obstacle.Kind.CLIFF:
			tex = TEX_CLIFF
			scl = 0.68
	obs.configure(kind, tex, scl, config.ground_y, air_y)
	var spawn_x: float = config.spawn_x if x < 0.0 else x
	obs.spawn(spawn_x, speed, gap)
	_active.append(obs)
	_recent.append(kind)
	if _recent.size() > 4:
		_recent.pop_front()
	return obs


func _spawn_lead_coins(lead: Obstacle, speed: float, blockers: Array[Obstacle]) -> void:
	_spawn_follow_coins(lead, speed, blockers)


func _spawn_follow_coins(obs: Obstacle, speed: float, blockers: Array[Obstacle]) -> void:
	if obs == null:
		return
	match obs.kind:
		Obstacle.Kind.RING:
			_spawn_ring_route(obs, speed)
		Obstacle.Kind.BARRIER:
			_spawn_duck_route(obs, speed)
		Obstacle.Kind.CLIFF:
			_spawn_jump_arc_coins(obs.position.x, speed, 7, blockers)
		_:
			_spawn_jump_arc_coins(obs.position.x, speed, 7, blockers)


func _spawn_ring_route(ring: Obstacle, speed: float) -> void:
	# 金币走同一条跳跃抛物线，顶点对准星门洞心。
	var none: Array[Obstacle] = []
	_spawn_jump_arc_coins(ring.position.x, speed, 7, none, ring.position.y)


func _spawn_duck_route(bar: Obstacle, speed: float) -> void:
	var y: float = config.ground_y - 24.0
	for i: int in 4:
		var x: float = bar.position.x - 54.0 + float(i) * 36.0
		_spawn_one_coin(Vector2(x, y), speed, RunCoin.Metal.GOLD, true)


func _apex_time() -> float:
	return absf(config.jump_velocity) / config.gravity


func _spawn_jump_arc_coins(peak_x: float, speed: float, count: int, blockers: Array[Obstacle], peak_y: float = -1.0) -> void:
	var origin_x: float = peak_x - speed * _apex_time()
	var pts: Array[Vector2] = _jump_arc(origin_x, speed)
	if peak_y > 0.0:
		pts = _align_arc_peak(pts, peak_y)
	if pts.size() < 4 or count < 2:
		return
	var a: int = maxi(int(float(pts.size()) / 10.0), 1)
	var b: int = pts.size() - a
	if b <= a:
		return
	var n: int = 0
	for i: int in count:
		var idx: int = a + int(round(float(b - a - 1) * float(i) / float(count - 1)))
		idx = clampi(idx, 0, pts.size() - 1)
		var p: Vector2 = pts[idx]
		if _blocked_visually(p, blockers):
			continue
		_spawn_one_coin(p, speed, RunCoin.Metal.GOLD, true)
		n += 1
	if n == 0 and not pts.is_empty():
		var mid: Vector2 = pts[int(float(pts.size()) * 0.5)]
		_spawn_one_coin(mid, speed, RunCoin.Metal.GOLD, true)


func _align_arc_peak(pts: Array[Vector2], peak_y: float) -> Array[Vector2]:
	if pts.is_empty():
		return pts
	var top: float = pts[0].y
	for p: Vector2 in pts:
		if p.y < top:
			top = p.y
	var d: float = peak_y - top
	var out: Array[Vector2] = []
	for p: Vector2 in pts:
		out.append(Vector2(p.x, p.y + d))
	return out


func _blocked_visually(p: Vector2, blockers: Array[Obstacle]) -> bool:
	for obs: Obstacle in blockers:
		if obs == null:
			continue
		if obs.kind == Obstacle.Kind.RING or obs.kind == Obstacle.Kind.BARRIER or obs.kind == Obstacle.Kind.CLIFF:
			continue
		if obs.visual_rect().grow(14.0).has_point(p):
			return true
	return false


func _jump_arc(origin_x: float, speed: float) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	var vy: float = config.jump_velocity
	var y: float = config.ground_y
	var x: float = origin_x
	var step: float = 1.0 / 60.0
	var airborne: bool = false
	var body: float = 40.0
	for _i: int in 90:
		x += speed * step
		vy += config.gravity * step
		y += vy * step
		if y < config.ground_y:
			airborne = true
		elif airborne:
			break
		if airborne:
			pts.append(Vector2(x, y - body))
	return pts


func _spawn_one_coin(pos: Vector2, speed: float, metal: RunCoin.Metal, energy: bool) -> void:
	var node: Node = _coin_pool.acquire()
	var coin: RunCoin = node as RunCoin
	coin.setup_player(_player)
	if not coin.collected.is_connected(_on_coin_collected):
		coin.collected.connect(_on_coin_collected)
	if not coin.recycled.is_connected(_on_coin_recycled):
		coin.recycled.connect(_on_coin_recycled)
	coin.spawn(pos, speed, metal, energy)
	_coins.append(coin)


func hold_spawn(seconds: float) -> void:
	spawn_hold = seconds


func spawn_shape_coins() -> void:
	var speed: float = maxf(_current_speed() * 0.38, 160.0)
	var cx: float = 780.0
	var cy: float = 508.0
	var kind: int = _shape_i % 4
	_shape_i += 1
	match kind:
		0:
			_shape_circle(cx, cy, speed)
		1:
			_shape_heart(cx, cy, speed)
		2:
			_shape_star(cx, cy, speed)
		_:
			_shape_moon(cx, cy, speed)


func _shape_circle(cx: float, cy: float, speed: float) -> void:
	for i: int in 12:
		var a: float = TAU * float(i) / 12.0
		_spawn_reward_coin(Vector2(cx + cos(a) * 78.0, cy + sin(a) * 38.0), speed, _metal_of(i))


func _shape_heart(cx: float, cy: float, speed: float) -> void:
	for i: int in 12:
		var t: float = TAU * float(i) / 12.0
		var x: float = 16.0 * pow(sin(t), 3.0)
		var y: float = 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
		_spawn_reward_coin(Vector2(cx + x * 4.0, cy - y * 3.2), speed, _metal_of(i))


func _shape_star(cx: float, cy: float, speed: float) -> void:
	for i: int in 10:
		var a: float = -PI * 0.5 + TAU * float(i) / 10.0
		var r: float = 70.0 if i % 2 == 0 else 32.0
		_spawn_reward_coin(Vector2(cx + cos(a) * r, cy + sin(a) * r * 0.42), speed, _metal_of(i))
	_spawn_reward_coin(Vector2(cx, cy), speed, RunCoin.Metal.GOLD)


func _shape_moon(cx: float, cy: float, speed: float) -> void:
	for i: int in 10:
		var a: float = -2.0 + 4.0 * float(i) / 9.0
		_spawn_reward_coin(Vector2(cx + cos(a) * 72.0, cy + sin(a) * 34.0), speed, _metal_of(i))
	for j: int in 4:
		_spawn_reward_coin(Vector2(cx + 24.0 + float(j) * 16.0, cy + 8.0), speed, RunCoin.Metal.SILVER)


func _spawn_reward_coin(pos: Vector2, speed: float, metal: RunCoin.Metal) -> void:
	pos.y = clampf(pos.y, 474.0, 552.0)
	_spawn_one_coin(pos, speed, metal, false)


func _metal_of(i: int) -> RunCoin.Metal:
	var m: int = i % 3
	if m == 0:
		return RunCoin.Metal.GOLD
	if m == 1:
		return RunCoin.Metal.SILVER
	return RunCoin.Metal.COPPER


func _fair_gap(speed: float) -> float:
	var hang: float = 2.0 * absf(config.jump_velocity) / config.gravity
	var min_clear: float = speed * hang * config.gap_extra + config.landing_pad
	return randf_range(min_clear, min_clear * config.max_gap_coeff)


func _pick_ground() -> Obstacle.Kind:
	var choices: Array[Obstacle.Kind] = [
		Obstacle.Kind.BOOKS, Obstacle.Kind.BOOKS, Obstacle.Kind.BOOKS,
		Obstacle.Kind.CHEST, Obstacle.Kind.CHEST,
		Obstacle.Kind.SHELF,
	]
	var kind: Obstacle.Kind = choices[randi() % choices.size()]
	if _recent.size() >= config.max_duplication:
		var same: bool = true
		for i: int in range(config.max_duplication):
			if _recent[_recent.size() - 1 - i] != kind:
				same = false
				break
		if same:
			for alt: Obstacle.Kind in choices:
				if alt != kind:
					return alt
	return kind


func _current_speed() -> float:
	if world_speed > 0.0:
		return world_speed
	return config.speed_start


func _on_obs_recycled(obs: Obstacle) -> void:
	_recycle_obs(obs)


func _recycle_obs(obs: Obstacle) -> void:
	_active.erase(obs)
	_obs_pool.release(obs)


func _on_ring() -> void:
	ring_bonus.emit()


func _on_coin_collected(coin: RunCoin) -> void:
	_coins.erase(coin)
	coin_picked.emit(coin)
	_coin_pool.release(coin)


func _on_coin_recycled(coin: RunCoin) -> void:
	_recycle_coin(coin)


func _recycle_coin(coin: RunCoin) -> void:
	_coins.erase(coin)
	_coin_pool.release(coin)
