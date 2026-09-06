class_name RunnerConfig
extends Resource

## 一段跳。障碍按角色身高对齐：站立约 100px，下滑约 36px。
## 施工说明书第 2.1 步冻结值。评分公式、60 tick、超级 15s、冲刺 150px 禁止改。

const PHYSICS_TICKS: int = 60
const MAX_FPS: int = 60
const SCORE_DIST: float = 0.04
const SCORE_COIN: int = 12
const SCORE_RING: int = 80
const SUPER_SEC: float = 15.0
const SPRINT_LIFT: float = 150.0
const COIN_GOLD: int = 5
const COIN_SILVER: int = 3
const COIN_COPPER: int = 1

@export var speed_start: float = 420.0
@export var speed_max: float = 860.0
@export var acceleration: float = 3.6
@export var gravity: float = 3200.0
@export var jump_velocity: float = -920.0
@export var drop_velocity: float = -480.0
@export var speed_drop_coeff: float = 3.0
@export var clear_time: float = 0.12
@export var coyote_time: float = 0.08
@export var jump_buffer: float = 0.10
@export var hit_stop: float = 0.10
@export var max_duplication: int = 2
@export var max_jumps: int = 1
@export var invert_score: int = 900
@export var score_coeff: float = 0.025
@export var coin_score: int = 8
@export var landing_pad: float = 72.0
@export var gap_extra: float = 1.04
@export var max_gap_coeff: float = 1.18
@export var ground_y: float = 600.0
@export var player_x: float = 168.0
@export var spawn_x: float = 1680.0
@export var first_spawn_x: float = 760.0
@export var coin_spacing: float = 40.0
## 30s 内约 40 段障碍。每段 3～4 枚能量币，收七成约 100 枚；每枚 +1 能量，满 100 大约 30s。
@export var energy_per_coin: float = 1.0
@export var energy_max: float = 100.0
@export var super_duration: float = SUPER_SEC
@export var sprint_lift: float = SPRINT_LIFT
@export var super_enter: float = 1.8
@export var super_min_run: float = 30.0
@export var super_exit_grace: float = 2.6
@export var super_spawn_hold: float = 3.4
